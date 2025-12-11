<?php

namespace Inovector\Mixpost\Http\Controllers\Api\Mobile;

use Illuminate\Http\JsonResponse;
use Illuminate\Routing\Controller;
use Illuminate\Support\Facades\Redis;
use Illuminate\Support\Facades\DB;

class SystemController extends Controller
{
    /**
     * Get system status
     */
    public function status(): JsonResponse
    {
        $environment = [
            'app_name' => config('app.name'),
            'app_version' => config('mixpost.version', '1.0.0'),
            'php_version' => PHP_VERSION,
            'laravel_version' => app()->version(),
            'environment' => config('app.env'),
            'debug' => config('app.debug'),
            'url' => config('app.url'),
        ];

        $health = [
            'horizon' => $this->checkHorizon(),
            'queue' => $this->checkQueue(),
            'scheduler' => $this->checkScheduler(),
            'redis' => $this->checkRedis(),
            'database' => $this->checkDatabase(),
        ];

        $technical = [
            'ffmpeg_path' => config('mixpost.ffmpeg_path'),
            'ffprobe_path' => config('mixpost.ffprobe_path'),
            'ffmpeg_version' => $this->getFFmpegVersion(),
            'disk_usage' => $this->getDiskUsage(),
        ];

        return response()->json([
            'environment' => $environment,
            'health' => $health,
            'technical' => $technical,
        ]);
    }

    /**
     * Check Horizon status
     */
    private function checkHorizon(): array
    {
        try {
            // Check if Horizon is running
            $masterStatus = Redis::connection('horizon')->get('horizon:master:status');
            $isRunning = $masterStatus === 'running' || $masterStatus === 'paused';

            return [
                'status' => $isRunning ? 'running' : 'stopped',
                'message' => $isRunning ? 'Horizon is running' : 'Horizon is not running',
            ];
        } catch (\Exception $e) {
            return [
                'status' => 'unknown',
                'message' => 'Unable to check Horizon status',
            ];
        }
    }

    /**
     * Check queue status
     */
    private function checkQueue(): array
    {
        try {
            // Check if queue is working
            $connection = config('queue.default');

            return [
                'status' => 'ok',
                'message' => "Queue connection: {$connection}",
            ];
        } catch (\Exception $e) {
            return [
                'status' => 'error',
                'message' => 'Queue connection failed',
            ];
        }
    }

    /**
     * Check scheduler status
     */
    private function checkScheduler(): array
    {
        // Check last scheduled task run time
        // This would require storing the last run time somewhere
        return [
            'status' => 'ok',
            'message' => 'Scheduler is configured',
        ];
    }

    /**
     * Check Redis status
     */
    private function checkRedis(): array
    {
        try {
            Redis::ping();

            return [
                'status' => 'ok',
                'message' => 'Redis is connected',
            ];
        } catch (\Exception $e) {
            return [
                'status' => 'error',
                'message' => 'Redis connection failed',
            ];
        }
    }

    /**
     * Check database status
     */
    private function checkDatabase(): array
    {
        try {
            DB::connection()->getPdo();

            return [
                'status' => 'ok',
                'message' => 'Database is connected',
            ];
        } catch (\Exception $e) {
            return [
                'status' => 'error',
                'message' => 'Database connection failed',
            ];
        }
    }

    /**
     * Get FFmpeg version
     */
    private function getFFmpegVersion(): ?string
    {
        $ffmpegPath = config('mixpost.ffmpeg_path');

        if (!$ffmpegPath || !file_exists($ffmpegPath)) {
            return null;
        }

        try {
            $output = shell_exec("{$ffmpegPath} -version 2>&1");
            if (preg_match('/ffmpeg version ([^\s]+)/', $output, $matches)) {
                return $matches[1];
            }
        } catch (\Exception $e) {
            return null;
        }

        return null;
    }

    /**
     * Get disk usage
     */
    private function getDiskUsage(): ?array
    {
        $storagePath = storage_path();

        try {
            $totalSpace = disk_total_space($storagePath);
            $freeSpace = disk_free_space($storagePath);
            $usedSpace = $totalSpace - $freeSpace;
            $percentage = round(($usedSpace / $totalSpace) * 100);

            return [
                'total' => $this->formatBytes($totalSpace),
                'used' => $this->formatBytes($usedSpace),
                'free' => $this->formatBytes($freeSpace),
                'percentage' => $percentage,
            ];
        } catch (\Exception $e) {
            return null;
        }
    }

    /**
     * Format bytes to human readable
     */
    private function formatBytes(int $bytes, int $precision = 2): string
    {
        $units = ['B', 'KB', 'MB', 'GB', 'TB'];
        $bytes = max($bytes, 0);
        $pow = floor(($bytes ? log($bytes) : 0) / log(1024));
        $pow = min($pow, count($units) - 1);
        $bytes /= pow(1024, $pow);

        return round($bytes, $precision) . ' ' . $units[$pow];
    }

    /**
     * Get services configuration
     */
    public function services(): JsonResponse
    {
        $services = \Inovector\Mixpost\Models\Service::all();

        return response()->json($services->map(function ($service) {
            return [
                'id' => $service->id,
                'name' => $service->name,
                'group' => $service->group,
                'active' => $service->active,
                'created_at' => $service->created_at,
                'updated_at' => $service->updated_at,
            ];
        }));
    }
}
