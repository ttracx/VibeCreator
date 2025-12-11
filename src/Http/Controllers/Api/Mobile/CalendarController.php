<?php

namespace Inovector\Mixpost\Http\Controllers\Api\Mobile;

use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Routing\Controller;
use Inovector\Mixpost\Enums\PostStatus;
use Inovector\Mixpost\Models\Post;

class CalendarController extends Controller
{
    /**
     * Get calendar data for a date range
     */
    public function __invoke(Request $request): JsonResponse
    {
        $date = $request->get('date', now()->format('Y-m-d'));
        $type = $request->get('type', 'month');

        $currentDate = Carbon::parse($date);

        // Calculate date range based on view type
        if ($type === 'week') {
            $startDate = $currentDate->copy()->startOfWeek();
            $endDate = $currentDate->copy()->endOfWeek();
        } else {
            $startDate = $currentDate->copy()->startOfMonth()->subDays(7);
            $endDate = $currentDate->copy()->endOfMonth()->addDays(7);
        }

        // Query posts
        $query = Post::forCurrentUser()
            ->with(['accounts', 'tags'])
            ->whereNotNull('scheduled_at')
            ->where(function ($q) use ($startDate, $endDate) {
                $q->whereBetween('scheduled_at', [$startDate, $endDate])
                  ->orWhereBetween('published_at', [$startDate, $endDate]);
            });

        // Filter by account
        if ($request->has('account_id')) {
            $query->whereHas('accounts', function ($q) use ($request) {
                $q->where('account_id', $request->account_id);
            });
        }

        // Filter by tag
        if ($request->has('tag_id')) {
            $query->whereHas('tags', function ($q) use ($request) {
                $q->where('tag_id', $request->tag_id);
            });
        }

        $posts = $query->orderBy('scheduled_at')
            ->get()
            ->map(function ($post) {
                $content = null;
                if ($post->versions && $post->versions->first()) {
                    $versionContent = $post->versions->first()->content;
                    if (is_array($versionContent) && isset($versionContent[0]['value'])) {
                        $content = $versionContent[0]['value'];
                    }
                }

                return [
                    'id' => $post->id,
                    'status' => $post->status->value,
                    'scheduled_at' => $post->scheduled_at?->toIso8601String(),
                    'published_at' => $post->published_at?->toIso8601String(),
                    'content' => $content,
                    'accounts' => $post->accounts->map(function ($account) {
                        return [
                            'id' => $account->id,
                            'name' => $account->name,
                            'provider' => $account->provider,
                            'image' => $account->media?->url,
                        ];
                    }),
                    'tags' => $post->tags->map(function ($tag) {
                        return [
                            'id' => $tag->id,
                            'name' => $tag->name,
                            'hex_color' => $tag->hex_color,
                        ];
                    }),
                ];
            });

        return response()->json([
            'posts' => $posts,
            'period' => [
                'start' => $startDate->format('Y-m-d'),
                'end' => $endDate->format('Y-m-d'),
                'type' => $type,
            ]
        ]);
    }
}
