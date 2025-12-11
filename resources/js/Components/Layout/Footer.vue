<script setup>
const currentYear = new Date().getFullYear();
const appName = 'VibeCreator';
</script>

<template>
    <footer class="text-center text-xs text-gray-500 py-4">
        © {{ currentYear }} {{ appName }} powered by
        <a href="https://vibecaas.com" target="_blank" class="hover:underline hover:text-indigo-600">VibeCaaS.com</a>
        a division of
        <a href="https://neuralquantum.ai" target="_blank" class="hover:underline hover:text-indigo-600">NeuralQuantum.ai</a> LLC. All rights reserved.
    </footer>
</template>
