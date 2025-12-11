<?php

namespace Inovector\Mixpost\Http\Controllers\Api\Mobile;

use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Routing\Controller;
use Inovector\Mixpost\Http\Resources\AccountResource;
use Inovector\Mixpost\Models\Account;
use Inovector\Mixpost\Models\Audience;
use Inovector\Mixpost\Models\Metric;

class ReportsController extends Controller
{
    /**
     * Get reports for an account
     */
    public function __invoke(Request $request): JsonResponse
    {
        $accountId = $request->get('account_id');
        $period = $request->get('period', 30);

        if (!$accountId) {
            return response()->json([
                'message' => 'Account ID is required'
            ], 422);
        }

        $account = Account::forCurrentUser()->find($accountId);

        if (!$account) {
            return response()->json([
                'message' => 'Account not found'
            ], 404);
        }

        $startDate = Carbon::now()->subDays($period);
        $endDate = Carbon::now();

        // Get metrics
        $metrics = Metric::where('account_id', $account->id)
            ->whereBetween('date', [$startDate, $endDate])
            ->orderBy('date')
            ->get()
            ->map(function ($metric) {
                return [
                    'id' => $metric->id,
                    'account_id' => $metric->account_id,
                    'date' => $metric->date->format('Y-m-d'),
                    'data' => $metric->data,
                ];
            });

        // Get audience history
        $audienceHistory = Audience::where('account_id', $account->id)
            ->whereBetween('date', [$startDate, $endDate])
            ->orderBy('date')
            ->get()
            ->map(function ($audience) {
                return [
                    'date' => $audience->date->format('Y-m-d'),
                    'count' => $audience->total,
                ];
            });

        // Calculate summary
        $currentAudience = $audienceHistory->last()?->count ?? 0;
        $previousAudience = $audienceHistory->first()?->count ?? 0;
        $audienceChange = $currentAudience - $previousAudience;
        $audienceChangePercentage = $previousAudience > 0
            ? round(($audienceChange / $previousAudience) * 100, 2)
            : 0;

        $totalImpressions = $metrics->sum(fn($m) => $m['data']['impressions'] ?? 0);
        $totalReach = $metrics->sum(fn($m) => $m['data']['reach'] ?? 0);
        $totalEngagement = $metrics->sum(fn($m) => $m['data']['engagement'] ?? 0);
        $totalPosts = $metrics->sum(fn($m) => $m['data']['posts'] ?? 0);

        return response()->json([
            'account' => new AccountResource($account),
            'metrics' => $metrics,
            'summary' => [
                'total_posts' => $totalPosts,
                'total_impressions' => $totalImpressions,
                'total_reach' => $totalReach,
                'total_engagement' => $totalEngagement,
                'average_engagement' => $metrics->count() > 0
                    ? round($totalEngagement / $metrics->count(), 2)
                    : 0,
                'follower_growth' => $audienceChange,
                'follower_growth_percentage' => $audienceChangePercentage,
            ],
            'audience' => [
                'current' => $currentAudience,
                'previous' => $previousAudience,
                'change' => $audienceChange,
                'change_percentage' => $audienceChangePercentage,
                'history' => $audienceHistory,
            ],
        ]);
    }
}
