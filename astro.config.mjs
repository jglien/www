import { defineConfig } from "astro/config";
import astroAws from "@astro-aws/adapter";
import sitemap from "@astrojs/sitemap";
import tailwindcss from "@tailwindcss/vite";

// https://astro.build/config
export default defineConfig({
  output: "server",
  adapter: astroAws(),
  integrations: [sitemap()],
  vite: {
    plugins: [tailwindcss()],
  },
});
