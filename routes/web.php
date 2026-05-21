<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\HealthController;

// Health check endpoint — no auth, no CSRF, no session
Route::get('/health', [HealthController::class, 'check'])->withoutMiddleware(['web']);

Route::get('/login', [AuthController::class, 'showLogin'])->name('login');
Route::post('/login', [AuthController::class, 'login'])->name('login.post');
Route::post('/logout', [AuthController::class, 'logout'])->name('logout');

require __DIR__.'/compliance.php';
require __DIR__.'/batch-processing.php';
require __DIR__.'/data-input.php';

Route::get('/', function () {
    return redirect('/compliance/dashboard');
});
