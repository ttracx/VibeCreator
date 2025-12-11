<?php

namespace Inovector\Mixpost\Http\Controllers\Api\Mobile;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Routing\Controller;
use Illuminate\Support\Facades\Validator;
use Inovector\Mixpost\Facades\Settings;

class SettingsController extends Controller
{
    /**
     * Get current settings
     */
    public function index(): JsonResponse
    {
        return response()->json([
            'timezone' => Settings::get('timezone', 'UTC'),
            'time_format' => Settings::get('time_format', 24),
            'week_starts_on' => Settings::get('week_starts_on', 1),
            'admin_email' => Settings::get('admin_email', ''),
        ]);
    }

    /**
     * Update settings
     */
    public function update(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'timezone' => 'required|string|timezone',
            'time_format' => 'required|integer|in:12,24',
            'week_starts_on' => 'required|integer|in:0,1',
            'admin_email' => 'nullable|email',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        Settings::put('timezone', $request->timezone);
        Settings::put('time_format', $request->time_format);
        Settings::put('week_starts_on', $request->week_starts_on);

        if ($request->has('admin_email')) {
            Settings::put('admin_email', $request->admin_email);
        }

        return response()->json([
            'timezone' => Settings::get('timezone'),
            'time_format' => Settings::get('time_format'),
            'week_starts_on' => Settings::get('week_starts_on'),
            'admin_email' => Settings::get('admin_email'),
        ]);
    }
}
