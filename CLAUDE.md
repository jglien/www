# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
pnpm dev          # start dev server (http://localhost:4321)
pnpm build        # build for production
pnpm preview      # preview production build
pnpm lint         # run ESLint
pnpm lint-fix     # run ESLint with auto-fix
pnpm deploy       # build and run tofu apply (requires AWS + OpenTofu)
```

## Architecture

Personal website built with **Astro v6**, **Tailwind CSS v4**, deployed to AWS via OpenTofu.

**Styling**: Tailwind v4 is integrated via `@tailwindcss/vite` (a Vite plugin), not the old `@astrojs/tailwind` integration. CSS config lives in `src/styles/global.css` using `@import "tailwindcss"`, `@theme`, and `@plugin` directives. The `@tailwindcss/typography` plugin is loaded via `@plugin "@tailwindcss/typography"` in the CSS file. The custom sans-serif font (Arimo Nerd Font, used for the location ligature icon in the hero) is declared with `--font-sans` in `@theme`.

**Pages & content**: Pages live in `src/pages/`. Blog posts are `.md` files in `src/pages/posts/` with frontmatter (`title`, `description`, `date`) and `layout: ../../layouts/MdLayout.astro`. The blog index (`src/pages/blog.astro`) loads posts with `import.meta.glob` (not `Astro.glob`, which was removed in Astro v5).

**Layouts**: `BaseLayout.astro` wraps all pages (includes `BaseHead` for meta/CSS and `Navbar`). `MdLayout.astro` wraps blog posts and applies Tailwind Typography prose styles; it intentionally overrides the font to `system-ui`.

**Site data**: Contact links are defined in `src/constants.ts` and rendered in `Hero.astro`.

**Linting**: ESLint v10 flat config in `eslint.config.mjs`. Enforces `semi`, `plugin:astro/recommended`, and `@typescript-eslint/recommended` for `.ts` files.
