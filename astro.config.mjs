import { defineConfig } from "astro/config";
import aws from "astro-sst";
import sitemap from "@astrojs/sitemap";
import tailwindcss from "@tailwindcss/vite";

// https://astro.build/config
export default defineConfig({
  output: "server",
  adapter: aws(),
  integrations: [sitemap()],
  vite: {
    plugins: [tailwindcss()],
  },
});
