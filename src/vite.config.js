import { defineConfig } from 'vite';
import laravel from 'laravel-vite-plugin';

export default defineConfig({
    plugins: [
        laravel({
            input: ['resources/js/app.jsx',
                'resources/css/app.css',
            ],
            refresh: true,
        }),
    ],
    server: {
        host: '0.0.0.0',  // Expose Vite to the Docker network
        port: 5178,
        strictPort: true,
        hmr: {
            host:'localhost',
            port:5178// Make sure Laravel uses the same hostname
        },
    }
});
