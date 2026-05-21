<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Cache;

class HealthController extends Controller
{
    public function check(): JsonResponse
    {
        $checks = [
            'status'   => 'ok',
            'database' => $this->checkDatabase(),
            'cache'    => $this->checkCache(),
            'queues'   => $this->checkQueues(),
            'storage'  => $this->checkStorage(),
            'forms'    => $this->checkForms(),
        ];

        $allOk = collect($checks)->except('status')->every(fn($v) => $v === 'ok');
        $checks['status'] = $allOk ? 'ok' : 'degraded';

        return response()->json($checks, $allOk ? 200 : 503);
    }

    private function checkDatabase(): string
    {
        try {
            DB::connection()->getPdo();
            DB::table('migrations')->count();
            return 'ok';
        } catch (\Throwable $e) {
            return 'error: ' . $e->getMessage();
        }
    }

    private function checkCache(): string
    {
        try {
            $key = 'health_check_' . time();
            Cache::put($key, 'ok', 10);
            $val = Cache::get($key);
            Cache::forget($key);
            return $val === 'ok' ? 'ok' : 'read-write mismatch';
        } catch (\Throwable $e) {
            return 'error: ' . $e->getMessage();
        }
    }

    private function checkQueues(): string
    {
        try {
            $pending = DB::table('jobs')->count();
            $failed  = DB::table('failed_jobs')->count();
            return "ok (pending:{$pending} failed:{$failed})";
        } catch (\Throwable $e) {
            return 'error: ' . $e->getMessage();
        }
    }

    private function checkStorage(): string
    {
        $path = storage_path('logs');
        return is_writable($path) ? 'ok' : 'not writable';
    }

    private function checkForms(): string
    {
        try {
            $count = DB::table('compliance_forms_master')->count();
            return $count > 0 ? "ok ({$count} forms)" : 'empty — run db:seed';
        } catch (\Throwable $e) {
            return 'error: ' . $e->getMessage();
        }
    }
}
