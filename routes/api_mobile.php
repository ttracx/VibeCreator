<?php

use Illuminate\Support\Facades\Route;
use Inovector\Mixpost\Http\Controllers\Api\Mobile\AuthController;
use Inovector\Mixpost\Http\Controllers\Api\Mobile\DashboardController;
use Inovector\Mixpost\Http\Controllers\Api\Mobile\PostsController;
use Inovector\Mixpost\Http\Controllers\Api\Mobile\CalendarController;
use Inovector\Mixpost\Http\Controllers\Api\Mobile\AccountsController;
use Inovector\Mixpost\Http\Controllers\Api\Mobile\MediaController;
use Inovector\Mixpost\Http\Controllers\Api\Mobile\TagsController;
use Inovector\Mixpost\Http\Controllers\Api\Mobile\SettingsController;
use Inovector\Mixpost\Http\Controllers\Api\Mobile\ReportsController;
use Inovector\Mixpost\Http\Controllers\Api\Mobile\SystemController;

/*
|--------------------------------------------------------------------------
| Mobile API Routes
|--------------------------------------------------------------------------
|
| These routes provide a RESTful API for the VibeCreator iOS and macOS
| applications. All routes require authentication via Laravel Sanctum.
|
*/

// Public routes (no authentication required)
Route::prefix('api/mobile')->group(function () {
    Route::post('/login', [AuthController::class, 'login']);
    Route::post('/register', [AuthController::class, 'register']);
});

// Protected routes (authentication required)
Route::prefix('api/mobile')->middleware(['auth:sanctum'])->group(function () {
    // Authentication
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::post('/refresh', [AuthController::class, 'refresh']);

    // Profile
    Route::get('/profile', [AuthController::class, 'profile']);
    Route::put('/profile', [AuthController::class, 'updateProfile']);
    Route::put('/profile/password', [AuthController::class, 'updatePassword']);

    // Dashboard
    Route::get('/dashboard', DashboardController::class);

    // Reports
    Route::get('/reports', ReportsController::class);

    // Posts
    Route::get('/posts', [PostsController::class, 'index']);
    Route::post('/posts', [PostsController::class, 'store']);
    Route::get('/posts/{post}', [PostsController::class, 'show']);
    Route::put('/posts/{post}', [PostsController::class, 'update']);
    Route::delete('/posts/{post}', [PostsController::class, 'destroy']);
    Route::delete('/posts', [PostsController::class, 'bulkDestroy']);
    Route::post('/posts/{post}/schedule', [PostsController::class, 'schedule']);
    Route::post('/posts/{post}/duplicate', [PostsController::class, 'duplicate']);

    // Calendar
    Route::get('/calendar', CalendarController::class);

    // Accounts
    Route::get('/accounts', [AccountsController::class, 'index']);
    Route::get('/accounts/add/{provider}', [AccountsController::class, 'getOAuthUrl']);
    Route::put('/accounts/{account}', [AccountsController::class, 'update']);
    Route::delete('/accounts/{account}', [AccountsController::class, 'destroy']);
    Route::get('/accounts/entities/{provider}', [AccountsController::class, 'getEntities']);
    Route::post('/accounts/entities/{provider}', [AccountsController::class, 'storeEntities']);

    // Media
    Route::get('/media/uploads', [MediaController::class, 'uploads']);
    Route::get('/media/stock', [MediaController::class, 'searchStock']);
    Route::get('/media/gifs', [MediaController::class, 'searchGifs']);
    Route::post('/media/upload', [MediaController::class, 'upload']);
    Route::post('/media/download', [MediaController::class, 'downloadExternal']);
    Route::delete('/media', [MediaController::class, 'destroy']);

    // Tags
    Route::get('/tags', [TagsController::class, 'index']);
    Route::post('/tags', [TagsController::class, 'store']);
    Route::put('/tags/{tag}', [TagsController::class, 'update']);
    Route::delete('/tags/{tag}', [TagsController::class, 'destroy']);

    // Settings
    Route::get('/settings', [SettingsController::class, 'index']);
    Route::put('/settings', [SettingsController::class, 'update']);

    // System
    Route::get('/system/status', [SystemController::class, 'status']);
    Route::get('/services', [SystemController::class, 'services']);
});
