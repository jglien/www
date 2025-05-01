import { defineConfig } from "astro/config";
import aws from "astro-sst";
import tailwind from "@astrojs/tailwind";
import image from "@astrojs/image";
import sitemap from "@astrojs/sitemap";

// https://astro.build/config
export default defineConfig({
  output: "server",
  adapter: aws(),
  integrations: [tailwind(), image(), sitemap()],
});