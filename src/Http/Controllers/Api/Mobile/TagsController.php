<?php

namespace Inovector\Mixpost\Http\Controllers\Api\Mobile;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Routing\Controller;
use Illuminate\Support\Facades\Validator;
use Inovector\Mixpost\Http\Resources\TagResource;
use Inovector\Mixpost\Models\Tag;

class TagsController extends Controller
{
    /**
     * Get all tags
     */
    public function index(): JsonResponse
    {
        $tags = Tag::forCurrentUser()
            ->orderBy('name')
            ->get();

        return response()->json(TagResource::collection($tags));
    }

    /**
     * Create a new tag
     */
    public function store(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'hex_color' => 'required|string|max:7',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        $tag = Tag::create([
            'user_id' => $request->user()->id,
            'name' => $request->name,
            'hex_color' => $request->hex_color,
        ]);

        return response()->json(new TagResource($tag), 201);
    }

    /**
     * Update a tag
     */
    public function update(Request $request, Tag $tag): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'hex_color' => 'required|string|max:7',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        $tag->update([
            'name' => $request->name,
            'hex_color' => $request->hex_color,
        ]);

        return response()->json(new TagResource($tag));
    }

    /**
     * Delete a tag
     */
    public function destroy(Tag $tag): JsonResponse
    {
        $tag->delete();

        return response()->json([
            'message' => 'Tag deleted successfully'
        ]);
    }
}
