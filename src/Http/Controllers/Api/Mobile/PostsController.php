<?php

namespace Inovector\Mixpost\Http\Controllers\Api\Mobile;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Routing\Controller;
use Illuminate\Support\Facades\Validator;
use Inovector\Mixpost\Actions\Post\CreatePost;
use Inovector\Mixpost\Actions\Post\UpdatePost;
use Inovector\Mixpost\Concerns\UsesUserModel;
use Inovector\Mixpost\Enums\PostStatus;
use Inovector\Mixpost\Http\Resources\PostResource;
use Inovector\Mixpost\Models\Post;
use Inovector\Mixpost\Models\Tag;

class PostsController extends Controller
{
    use UsesUserModel;

    /**
     * Get paginated list of posts
     */
    public function index(Request $request): JsonResponse
    {
        $query = Post::forCurrentUser()
            ->with(['accounts', 'versions.media', 'tags']);

        // Filter by status
        if ($request->has('status') && $request->status !== null) {
            $query->where('status', $request->status);
        }

        // Filter by tag
        if ($request->has('tag_id')) {
            $query->whereHas('tags', function ($q) use ($request) {
                $q->where('tag_id', $request->tag_id);
            });
        }

        // Filter by account
        if ($request->has('account_id')) {
            $query->whereHas('accounts', function ($q) use ($request) {
                $q->where('account_id', $request->account_id);
            });
        }

        // Search by keyword
        if ($request->has('keyword') && !empty($request->keyword)) {
            $keyword = $request->keyword;
            $query->whereHas('versions', function ($q) use ($keyword) {
                $q->where('content', 'like', "%{$keyword}%");
            });
        }

        // Order and paginate
        $posts = $query->latest()
            ->paginate($request->get('per_page', 20));

        return response()->json([
            'data' => PostResource::collection($posts),
            'meta' => [
                'current_page' => $posts->currentPage(),
                'from' => $posts->firstItem(),
                'last_page' => $posts->lastPage(),
                'per_page' => $posts->perPage(),
                'to' => $posts->lastItem(),
                'total' => $posts->total(),
            ],
            'links' => [
                'first' => $posts->url(1),
                'last' => $posts->url($posts->lastPage()),
                'prev' => $posts->previousPageUrl(),
                'next' => $posts->nextPageUrl(),
            ]
        ]);
    }

    /**
     * Get single post
     */
    public function show(Post $post): JsonResponse
    {
        $post->load(['accounts', 'versions.media', 'tags']);

        return response()->json(new PostResource($post));
    }

    /**
     * Create a new post
     */
    public function store(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'accounts' => 'required|array|min:1',
            'accounts.*' => 'integer|exists:mixpost_accounts,id',
            'versions' => 'required|array|min:1',
            'versions.*.account_id' => 'required|integer',
            'versions.*.content' => 'required|array',
            'versions.*.media' => 'array',
            'tags' => 'array',
            'tags.*' => 'integer|exists:mixpost_tags,id',
            'date' => 'nullable|date_format:Y-m-d',
            'time' => 'nullable|date_format:H:i',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        $createPost = new CreatePost();
        $post = $createPost->handle($request->user(), $request->all());

        $post->load(['accounts', 'versions.media', 'tags']);

        return response()->json(new PostResource($post), 201);
    }

    /**
     * Update a post
     */
    public function update(Request $request, Post $post): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'accounts' => 'required|array|min:1',
            'accounts.*' => 'integer|exists:mixpost_accounts,id',
            'versions' => 'required|array|min:1',
            'versions.*.account_id' => 'required|integer',
            'versions.*.content' => 'required|array',
            'versions.*.media' => 'array',
            'tags' => 'array',
            'tags.*' => 'integer|exists:mixpost_tags,id',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        $updatePost = new UpdatePost();
        $post = $updatePost->handle($post, $request->all());

        $post->load(['accounts', 'versions.media', 'tags']);

        return response()->json(new PostResource($post));
    }

    /**
     * Delete a post
     */
    public function destroy(Post $post): JsonResponse
    {
        $post->delete();

        return response()->json([
            'message' => 'Post deleted successfully'
        ]);
    }

    /**
     * Delete multiple posts
     */
    public function bulkDestroy(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'posts' => 'required|array|min:1',
            'posts.*' => 'integer|exists:mixpost_posts,id',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        Post::forCurrentUser()
            ->whereIn('id', $request->posts)
            ->delete();

        return response()->json([
            'message' => 'Posts deleted successfully'
        ]);
    }

    /**
     * Schedule a post
     */
    public function schedule(Request $request, Post $post): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'scheduled_at' => 'required|date',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        $post->update([
            'status' => PostStatus::SCHEDULED,
            'scheduled_at' => $request->scheduled_at,
        ]);

        $post->load(['accounts', 'versions.media', 'tags']);

        return response()->json(new PostResource($post));
    }

    /**
     * Duplicate a post
     */
    public function duplicate(Post $post): JsonResponse
    {
        $newPost = $post->replicate();
        $newPost->status = PostStatus::DRAFT;
        $newPost->scheduled_at = null;
        $newPost->published_at = null;
        $newPost->save();

        // Copy relationships
        $newPost->accounts()->attach($post->accounts->pluck('id'));
        $newPost->tags()->attach($post->tags->pluck('id'));

        // Copy versions
        foreach ($post->versions as $version) {
            $newVersion = $version->replicate();
            $newVersion->post_id = $newPost->id;
            $newVersion->save();

            // Copy media relationships
            if ($version->media) {
                $newVersion->media()->attach($version->media->pluck('id'));
            }
        }

        $newPost->load(['accounts', 'versions.media', 'tags']);

        return response()->json(new PostResource($newPost), 201);
    }
}
