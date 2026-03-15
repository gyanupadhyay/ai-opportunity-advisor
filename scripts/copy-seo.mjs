#!/usr/bin/env node
/**
 * Copies sitemap.xml and robots.txt from frontend/web to frontend/build/jaspr
 * so they are always included in Firebase Hosting deploy.
 * Run after `jaspr build` and before `firebase deploy --only hosting`.
 */
import { copyFileSync, existsSync, mkdirSync } from "fs";
import { dirname, join } from "path";
import { fileURLToPath } from "url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const webDir = join(root, "frontend", "web");
const buildDir = join(root, "frontend", "build", "jaspr");

if (!existsSync(buildDir)) {
  console.error("Run 'cd frontend && jaspr build' first so frontend/build/jaspr exists.");
  process.exit(1);
}

for (const name of ["sitemap.xml", "robots.txt"]) {
  const src = join(webDir, name);
  const dest = join(buildDir, name);
  if (existsSync(src)) {
    copyFileSync(src, dest);
    console.log("Copied", name, "to build output.");
  }
}
