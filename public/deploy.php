<?php
/**
 * Web-based deployment webhook for shared hosting environments.
 * Trigger: GET /deploy.php?token=<DEPLOY_SECRET>
 * Optional: &seed=1 to run seeders, &fresh=1 to migrate:fresh (DESTRUCTIVE)
 *
 * Set DEPLOY_SECRET in .env — never hardcode it here.
 */

$projectRoot = dirname(__DIR__);

// Load .env manually (no framework bootstrap)
$envFile = $projectRoot . '/.env';
$envVars = [];
if (file_exists($envFile)) {
    foreach (file($envFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) as $line) {
        if (str_starts_with(trim($line), '#') || !str_contains($line, '=')) continue;
        [$k, $v] = explode('=', $line, 2);
        $envVars[trim($k)] = trim($v, " \t\n\r\0\x0B\"'");
    }
}

$secret = $envVars['DEPLOY_SECRET'] ?? 'compliance2026-change-me';

// Auth check
if (!isset($_GET['token']) || !hash_equals($secret, $_GET['token'])) {
    http_response_code(403);
    header('Content-Type: application/json');
    echo json_encode(['status' => 'error', 'message' => 'Unauthorized']);
    exit;
}

$runSeed  = isset($_GET['seed'])  && $_GET['seed']  === '1';
$runFresh = isset($_GET['fresh']) && $_GET['fresh'] === '1';
$steps    = [];
$errors   = [];

function run(string $cmd, string $cwd, array &$steps, array &$errors): bool
{
    $descriptors = [1 => ['pipe', 'w'], 2 => ['pipe', 'w']];
    $process = proc_open($cmd, $descriptors, $pipes, $cwd);
    if (!is_resource($process)) {
        $errors[] = "Failed to start: $cmd";
        return false;
    }
    $stdout = trim(stream_get_contents($pipes[1]));
    $stderr = trim(stream_get_contents($pipes[2]));
    fclose($pipes[1]);
    fclose($pipes[2]);
    $code = proc_close($process);

    $steps[] = [
        'cmd'    => $cmd,
        'stdout' => $stdout,
        'stderr' => $stderr ?: null,
        'code'   => $code,
        'ok'     => $code === 0,
    ];

    if ($code !== 0) {
        $errors[] = "Exit $code: $cmd";
        return false;
    }
    return true;
}

$php = PHP_BINARY;

// 1. Clear bootstrap cache files
foreach (['config.php','routes-v7.php','services.php','packages.php'] as $f) {
    @unlink($projectRoot . '/bootstrap/cache/' . $f);
}
$steps[] = ['cmd' => 'rm bootstrap/cache/*.php', 'ok' => true];

// 2. Ensure Telescope disabled
$envContent = file_get_contents($envFile);
if (preg_match('/^TELESCOPE_ENABLED=/m', $envContent)) {
    $envContent = preg_replace('/^TELESCOPE_ENABLED=.*/m', 'TELESCOPE_ENABLED=false', $envContent);
} else {
    $envContent .= "\nTELESCOPE_ENABLED=false\n";
}
file_put_contents($envFile, $envContent);
$steps[] = ['cmd' => 'set TELESCOPE_ENABLED=false', 'ok' => true];

// 3. Clear artisan caches
run("$php artisan config:clear",  $projectRoot, $steps, $errors);
run("$php artisan cache:clear",   $projectRoot, $steps, $errors);
run("$php artisan route:clear",   $projectRoot, $steps, $errors);
run("$php artisan view:clear",    $projectRoot, $steps, $errors);

// 4. Composer install
run("$php composer.phar install --no-dev --optimize-autoloader --no-interaction 2>&1 || composer install --no-dev --optimize-autoloader --no-interaction",
    $projectRoot, $steps, $errors);

// 5. Migrations
$migrateCmd = $runFresh
    ? "$php artisan migrate:fresh --force"
    : "$php artisan migrate --force";
run($migrateCmd, $projectRoot, $steps, $errors);

// 6. Seeders
if ($runSeed || empty($errors)) {
    // Check if seeding is needed
    try {
        $pdo = new PDO(
            "mysql:host={$envVars['DB_HOST']};port={$envVars['DB_PORT']};dbname={$envVars['DB_DATABASE']};charset=utf8mb4",
            $envVars['DB_USERNAME'], $envVars['DB_PASSWORD']
        );
        $count = $pdo->query('SELECT COUNT(*) FROM compliance_forms_master')->fetchColumn();
        if ($runSeed || $count == 0) {
            run("$php artisan db:seed --force", $projectRoot, $steps, $errors);
        } else {
            $steps[] = ['cmd' => 'db:seed', 'stdout' => "Skipped — $count forms already seeded", 'ok' => true];
        }
    } catch (PDOException $e) {
        $errors[] = 'Seed check failed: ' . $e->getMessage();
    }
}

// 7. Storage symlink
if (!file_exists($projectRoot . '/public/storage')) {
    run("$php artisan storage:link", $projectRoot, $steps, $errors);
} else {
    $steps[] = ['cmd' => 'storage:link', 'stdout' => 'Already exists', 'ok' => true];
}

// 8. Optimize
run("$php artisan config:cache", $projectRoot, $steps, $errors);
run("$php artisan route:cache",  $projectRoot, $steps, $errors);
run("$php artisan view:cache",   $projectRoot, $steps, $errors);

// 9. Permissions
@chmod($projectRoot . '/storage', 0755);
@chmod($projectRoot . '/bootstrap/cache', 0755);
$steps[] = ['cmd' => 'chmod storage bootstrap/cache', 'ok' => true];

// Response
$status = empty($errors) ? 'success' : 'partial';
header('Content-Type: application/json');
echo json_encode([
    'status'  => $status,
    'errors'  => $errors,
    'steps'   => $steps,
    'time'    => date('Y-m-d H:i:s'),
], JSON_PRETTY_PRINT);
