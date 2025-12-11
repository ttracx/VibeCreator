<?php

namespace Inovector\Mixpost\Http\Controllers\Api\Mobile;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Routing\Controller;
use Inovector\Mixpost\Facades\SocialProviderManager;
use Inovector\Mixpost\Http\Resources\AccountResource;
use Inovector\Mixpost\Models\Account;

class AccountsController extends Controller
{
    /**
     * Get all connected accounts
     */
    public function index(): JsonResponse
    {
        $accounts = Account::forCurrentUser()
            ->with('media')
            ->latest()
            ->get();

        return response()->json(AccountResource::collection($accounts));
    }

    /**
     * Get OAuth URL for adding a new account
     */
    public function getOAuthUrl(string $provider): JsonResponse
    {
        try {
            $socialProvider = SocialProviderManager::connect($provider);
            $url = $socialProvider->getAuthUrl();

            return response()->json([
                'url' => $url,
                'state' => session('oauth_state'),
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Failed to generate OAuth URL',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Refresh account data
     */
    public function update(Account $account): JsonResponse
    {
        try {
            $socialProvider = SocialProviderManager::connect($account->provider, $account->values());

            // Update account data from provider
            $accountData = $socialProvider->getAccountData();

            if ($accountData) {
                $account->update([
                    'name' => $accountData['name'] ?? $account->name,
                    'username' => $accountData['username'] ?? $account->username,
                    'data' => array_merge($account->data ?? [], $accountData['data'] ?? []),
                ]);
            }

            $account->load('media');

            return response()->json(new AccountResource($account));
        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Failed to refresh account',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Delete an account
     */
    public function destroy(Account $account): JsonResponse
    {
        $account->delete();

        return response()->json([
            'message' => 'Account removed successfully'
        ]);
    }

    /**
     * Get account entities (pages, groups)
     */
    public function getEntities(string $provider): JsonResponse
    {
        try {
            $socialProvider = SocialProviderManager::connect($provider);
            $entities = $socialProvider->getEntities();

            return response()->json($entities);
        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Failed to get entities',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Store selected entities as accounts
     */
    public function storeEntities(Request $request, string $provider): JsonResponse
    {
        $entities = $request->get('entities', []);

        try {
            $socialProvider = SocialProviderManager::connect($provider);
            $accounts = $socialProvider->storeEntities($entities);

            return response()->json(AccountResource::collection($accounts));
        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Failed to store entities',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}
