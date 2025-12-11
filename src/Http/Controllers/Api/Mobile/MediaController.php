<?php

namespace Inovector\Mixpost\Http\Controllers\Api\Mobile;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Routing\Controller;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;
use Inovector\Mixpost\Http\Resources\MediaResource;
use Inovector\Mixpost\Models\Media;
use Inovector\Mixpost\Integrations\Unsplash\Unsplash;

class MediaController extends Controller
{
    /**
     * Get paginated uploads
     */
    public function uploads(Request $request): JsonResponse
    {
        $media = Media::forCurrentUser()
            ->latest()
            ->paginate($request->get('per_page', 20));

        return response()->json([
            'data' => MediaResource::collection($media),
            'meta' => [
                'current_page' => $media->currentPage(),
                'last_page' => $media->lastPage(),
                'per_page' => $media->perPage(),
                'total' => $media->total(),
            ]
        ]);
    }

    /**
     * Search stock photos (Unsplash)
     */
    public function searchStock(Request $request): JsonResponse
    {
        $keyword = $request->get('keyword', '');
        $page = $request->get('page', 1);

        if (empty($keyword)) {
            $keyword = config('mixpost.external_media_terms')[array_rand(config('mixpost.external_media_terms'))];
        }

        try {
            $unsplash = new Unsplash();
            $results = $unsplash->search($keyword, $page);

            return response()->json([
                'data' => collect($results['results'] ?? [])->map(function ($photo) {
                    return [
                        'id' => $photo['id'],
                        'url' => $photo['urls']['regular'],
                        'thumb' => $photo['urls']['thumb'],
                        'download' => $photo['links']['download_location'],
                        'author' => $photo['user']['name'],
                        'author_url' => $photo['user']['links']['html'],
                    ];
                }),
                'meta' => [
                    'page' => $page,
                    'total_pages' => $results['total_pages'] ?? 1,
                ]
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'data' => [],
                'meta' => ['page' => 1, 'total_pages' => 0],
                'error' => $e->getMessage()
            ]);
        }
    }

    /**
     * Search GIFs (Tenor)
     */
    public function searchGifs(Request $request): JsonResponse
    {
        $keyword = $request->get('keyword', '');
        $pos = $request->get('pos', '');

        if (empty($keyword)) {
            return response()->json([
                'data' => [],
                'next' => null
            ]);
        }

        try {
            // Tenor API integration
            $apiKey = config('services.tenor.key');
            $url = "https://tenor.googleapis.com/v2/search?q=" . urlencode($keyword) . "&key={$apiKey}&limit=20";

            if ($pos) {
                $url .= "&pos={$pos}";
            }

            $response = file_get_contents($url);
            $data = json_decode($response, true);

            return response()->json([
                'data' => collect($data['results'] ?? [])->map(function ($gif) {
                    return [
                        'id' => $gif['id'],
                        'url' => $gif['media_formats']['gif']['url'] ?? '',
                        'preview' => $gif['media_formats']['tinygif']['url'] ?? '',
                        'title' => $gif['title'] ?? '',
                    ];
                }),
                'next' => $data['next'] ?? null
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'data' => [],
                'next' => null,
                'error' => $e->getMessage()
            ]);
        }
    }

    /**
     * Upload media file
     */
    public function upload(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'file' => 'required|file|max:' . config('mixpost.max_file_size.video', 204800),
        ]);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        $file = $request->file('file');
        $disk = config('mixpost.disk', 'public');

        $path = $file->store('mixpost-media', $disk);

        $media = Media::create([
            'user_id' => $request->user()->id,
            'name' => $file->getClientOriginalName(),
            'mime_type' => $file->getMimeType(),
            'disk' => $disk,
            'path' => $path,
            'size' => $file->getSize(),
            'size_readable' => $this->humanFileSize($file->getSize()),
        ]);

        return response()->json(new MediaResource($media), 201);
    }

    /**
     * Download external media to library
     */
    public function downloadExternal(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'url' => 'required|url',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            $url = $request->url;
            $contents = file_get_contents($url);

            // Get file info
            $urlParts = parse_url($url);
            $filename = basename($urlParts['path']);
            $extension = pathinfo($filename, PATHINFO_EXTENSION) ?: 'jpg';
            $filename = uniqid() . '.' . $extension;

            $disk = config('mixpost.disk', 'public');
            $path = 'mixpost-media/' . $filename;

            Storage::disk($disk)->put($path, $contents);

            $mimeType = Storage::disk($disk)->mimeType($path);
            $size = Storage::disk($disk)->size($path);

            $media = Media::create([
                'user_id' => $request->user()->id,
                'name' => $filename,
                'mime_type' => $mimeType,
                'disk' => $disk,
                'path' => $path,
                'size' => $size,
                'size_readable' => $this->humanFileSize($size),
            ]);

            return response()->json(new MediaResource($media), 201);
        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Failed to download media',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Delete media
     */
    public function destroy(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'media' => 'required|array|min:1',
            'media.*' => 'integer|exists:mixpost_media,id',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        $mediaItems = Media::forCurrentUser()
            ->whereIn('id', $request->media)
            ->get();

        foreach ($mediaItems as $media) {
            // Delete file from storage
            if ($media->disk && $media->path) {
                Storage::disk($media->disk)->delete($media->path);
            }

            $media->delete();
        }

        return response()->json([
            'message' => 'Media deleted successfully'
        ]);
    }

    /**
     * Convert bytes to human readable format
     */
    private function humanFileSize(int $bytes, int $decimals = 2): string
    {
        $size = ['B', 'KB', 'MB', 'GB', 'TB'];
        $factor = floor((strlen($bytes) - 1) / 3);
        return sprintf("%.{$decimals}f", $bytes / pow(1024, $factor)) . ' ' . $size[$factor];
    }
}
