<script setup>
import {Link} from '@inertiajs/vue3';
import Logo from "@/Components/DataDisplay/Logo.vue"
import Footer from "@/Components/Layout/Footer.vue"
import Notifications from "@/Components/Util/Notifications.vue";
</script>
<template>
    <div class="flex flex-col min-h-screen bg-stone-500">
        <!-- Navigation Bar -->
        <nav class="bg-white border-b border-gray-200 shadow-sm">
            <div class="max-w-(--container-5xl) mx-auto px-4 sm:px-6 lg:px-8">
                <div class="flex justify-between items-center h-16">
                    <Link :href="route('mixpost.dashboard')" class="flex items-center">
                        <Logo class="h-10"/>
                    </Link>
                    <div class="flex items-center space-x-4">
                        <Link :href="route('mixpost.dashboard')" class="text-gray-600 hover:text-indigo-600 text-sm font-medium">
                            Dashboard
                        </Link>
                        <Link :href="route('mixpost.posts.index')" class="text-gray-600 hover:text-indigo-600 text-sm font-medium">
                            Posts
                        </Link>
                        <Link :href="route('mixpost.calendar')" class="text-gray-600 hover:text-indigo-600 text-sm font-medium">
                            Calendar
                        </Link>
                        <Link :href="route('mixpost.settings.index')" class="text-gray-600 hover:text-indigo-600 text-sm font-medium">
                            Settings
                        </Link>
                    </div>
                </div>
            </div>
        </nav>

        <!-- Main Content -->
        <main class="flex-grow row-py row-px overflow-y-auto" scroll-region>
            <div class="w-full max-w-(--container-5xl) mx-auto">
                <slot/>
            </div>
        </main>

        <!-- Footer -->
        <div class="bg-white border-t border-gray-200">
            <div class="max-w-(--container-5xl) mx-auto">
                <Footer/>
            </div>
        </div>

        <Notifications/>
    </div>
</template>
