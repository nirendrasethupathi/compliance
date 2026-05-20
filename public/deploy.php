<?php

/**
 * deploy.php — Browser-triggered deployment for Hostinger shared hosting.
 *
 * Access via:
 *   https://yourdomain.com/deploy.php?token=compliance2026          → migrate only
 *   https://yourdomain.com/deploy.php?token=compliance2026&seed=1   → migrate + seed
 *   https://yourdomain.com/deploy.php?token=compliance2026&fresh=1  → drop all tables, migrate fresh + seed
 *
 * No SSH, no shell_exec, no proc_open required.
 */

// ─── Security token ───────────────────────────────────────────────────────────
define('DEPLOY_TOKEN', 'compliance2026');

if (empty($_GET['token']) || $_GET['token'] !== DEPLOY_TOKEN) {
    http_response_code(403);
    die('403 Forbidden — invalid or missing token.');
}

// ─── Increase limits for long-running migrations ──────────────────────────────
ini_set('max_execution_time', 300);
ini_set('memory_limit', '256M');

// ─── Output buffering so we stream progress to browser ───────────────────────
@ob_implicit_flush(true);
@ob_end_flush();
header('Content-Type: text/html; charset=utf-8');
header('X-Accel-Buffering: no'); // disable nginx buffering on Hostinger

echo '<!DOCTYPE html><html><head><meta charset="utf-8">
<title>Deploy</title>
<style>
  body { background:#0d1117; color:#c9d1d9; font-family:monospace; padding:24px; }
  .ok  { color:#3fb950; }
  .err { color:#f85149; }
  .info{ color:#58a6ff; }
  pre  { margin:0; white-space:pre-wrap; word-break:break-all; }
</style></head><body><pre>';

function out(string $msg, string $type = 'ok'): void
{
    echo "<span class=\"{$type}\">" . htmlspecialchars($msg) . "</span>\n";
    flush();
}

// ─── Bootstrap Laravel ────────────────────────────────────────────────────────
$projectRoot = dirname(__DIR__);

out("▶ Bootstrapping Laravel from: {$projectRoot}", 'info');

require $projectRoot . '/vendor/autoload.php';

/** @var \Illuminate\Foundation\Application $app */
$app = require $projectRoot . '/bootstrap/app.php';

// Boot the full application kernel so all service providers are registered
$kernel = $app->make(\Illuminate\Contracts\Http\Kernel::class);
$request = \Illuminate\Http\Request::capture();
$kernel->handle($request); // boots providers, registers DB, etc.

out('✔ Laravel booted successfully.', 'ok');

// ─── Verify DB connection ─────────────────────────────────────────────────────
out('▶ Testing database connection...', 'info');
try {
    \Illuminate\Support\Facades\DB::connection()->getPdo();
    $dbName = \Illuminate\Support\Facades\DB::connection()->getDatabaseName();
    out("✔ Connected to database: {$dbName}", 'ok');
} catch (\Exception $e) {
    out('✘ DB connection failed: ' . $e->getMessage(), 'err');
    echo '</pre></body></html>';
    exit(1);
}

// ─── Resolve the migrator ─────────────────────────────────────────────────────
/** @var \Illuminate\Database\Migrations\Migrator $migrator */
$migrator = $app->make('migrator');
$migrationPath = $projectRoot . '/database/migrations';

// ─── Fresh (drop + re-migrate) ────────────────────────────────────────────────
if (!empty($_GET['fresh']) && $_GET['fresh'] === '1') {
    out('▶ Running migrate:fresh — dropping all tables...', 'info');
    try {
        // Drop all tables via schema builder
        $schema = \Illuminate\Support\Facades\Schema::getConnection();
        $schema->getSchemaBuilder()->dropAllTables();
        out('✔ All tables dropped.', 'ok');
    } catch (\Exception $e) {
        out('✘ Drop tables failed: ' . $e->getMessage(), 'err');
    }
}

// ─── Run migrations ───────────────────────────────────────────────────────────
out('▶ Running migrations...', 'info');

// Ensure the migrations table exists
$migrator->getRepository()->createRepository();

try {
    $migrated = $migrator->run([$migrationPath], ['pretend' => false, 'step' => false]);

    if (empty($migrated)) {
        out('✔ Nothing to migrate — all migrations already ran.', 'ok');
    } else {
        foreach ($migrated as $file) {
            out('  ✔ Migrated: ' . basename($file), 'ok');
        }
        out('✔ Migrations complete.', 'ok');
    }
} catch (\Exception $e) {
    out('✘ Migration failed: ' . $e->getMessage(), 'err');
    out($e->getTraceAsString(), 'err');
    echo '</pre></body></html>';
    exit(1);
}

// ─── Run seeders ──────────────────────────────────────────────────────────────
if (!empty($_GET['seed']) && $_GET['seed'] === '1') {
    out('▶ Running database seeders...', 'info');
    try {
        $seeder = $app->make(\Database\Seeders\DatabaseSeeder::class);
        $seeder->setContainer($app)->setCommand(null)->__invoke();
        out('✔ Seeding complete.', 'ok');
    } catch (\Exception $e) {
        out('✘ Seeding failed: ' . $e->getMessage(), 'err');
        out($e->getTraceAsString(), 'err');
    }
}

// ─── Clear & rebuild caches ───────────────────────────────────────────────────
out('▶ Clearing caches...', 'info');
try {
    \Illuminate\Support\Facades\Artisan::call('config:clear');
    out('  ✔ Config cache cleared.', 'ok');
    \Illuminate\Support\Facades\Artisan::call('route:clear');
    out('  ✔ Route cache cleared.', 'ok');
    \Illuminate\Support\Facades\Artisan::call('view:clear');
    out('  ✔ View cache cleared.', 'ok');
} catch (\Exception $e) {
    out('  ⚠ Cache clear warning: ' . $e->getMessage(), 'err');
}

// ─── Fix storage permissions ──────────────────────────────────────────────────
out('▶ Setting storage permissions...', 'info');
foreach (['/storage', '/bootstrap/cache'] as $dir) {
    if (is_dir($projectRoot . $dir)) {
        @chmod($projectRoot . $dir, 0755);
        out("  ✔ chmod 755 {$dir}", 'ok');
    }
}

// ─── Create storage symlink if missing ───────────────────────────────────────
if (!file_exists($projectRoot . '/public/storage')) {
    try {
        \Illuminate\Support\Facades\Artisan::call('storage:link');
        out('✔ Storage symlink created.', 'ok');
    } catch (\Exception $e) {
        out('⚠ Storage link warning: ' . $e->getMessage(), 'err');
    }
}

// ─── Done ─────────────────────────────────────────────────────────────────────
out('', 'ok');
out('════════════════════════════════════════', 'info');
out('✅  Deployment completed successfully!', 'ok');
out('════════════════════════════════════════', 'info');

echo '</pre></body></html>';
