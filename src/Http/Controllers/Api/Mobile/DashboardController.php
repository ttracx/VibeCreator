<?php

namespace Inovector\Mixpost\Http\Controllers\Api\Mobile;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Routing\Controller;
use Inovector\Mixpost\Enums\PostStatus;
use Inovector\Mixpost\Http\Resources\AccountResource;
use Inovector\Mixpost\Http\Resources\PostResource;
use Inovector\Mixpost\Models\Account;
use Inovector\Mixpost\Models\Post;

class DashboardController extends Controller
{
    /**
     * Get dashboard data with statistics
     */
    public function __invoke(Request $request): JsonResponse
    {
        $user = $request->user();

        // Get accounts
        $accounts = Account::forCurrentUser()->latest()->get();

        // Get post counts
        $scheduledCount = Post::forCurrentUser()
            ->where('status', PostStatus::SCHEDULED)
            ->count();

        $publishedCount = Post::forCurrentUser()
            ->where('status', PostStatus::PUBLISHED)
            ->count();

        $failedCount = Post::forCurrentUser()
            ->where('status', PostStatus::FAILED)
            ->count();

        // Get recent posts
        $recentPosts = Post::forCurrentUser()
            ->with(['accounts', 'versions.media', 'tags'])
            ->latest()
            ->take(5)
            ->get();

        return response()->json([
            'accounts' => AccountResource::collection($accounts),
            'recent_posts' => PostResource::collection($recentPosts),
            'scheduled_count' => $scheduledCount,
            'published_count' => $publishedCount,
            'failed_count' => $failedCount,
        ]);
    }
}
