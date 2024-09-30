import path from "node:path";
import { defineConfig } from "vite";
import elmPlugin from "vite-plugin-elm";
import { viteStaticCopy } from "vite-plugin-static-copy";
import zipPack from "vite-plugin-zip-pack";
import manifest from "./manifest.json";

declare global {
    const __TARGET__: "production" | "development";
}

const getBaseConfig = (target: typeof __TARGET__) => ({
    base: "./",
    define: {
        __TARGET__: JSON.stringify(target),
    },
    plugins: [
        elmPlugin(),
        viteStaticCopy({
            targets: [
                { src: "./images/*.png", dest: "images/" },
                { src: "./manifest.json", dest: "." },
            ],
        }),
        zipPack({
            inDir: path.resolve(__dirname, "dist"),
            outDir: path.resolve(__dirname, "builds"),
            outFileName: `goalmet_${manifest.version}.zip`,
        }),
    ],
});

export default defineConfig((ctx) => {
    if (ctx.mode === "production" || ctx.mode === "development") {
        return getBaseConfig(ctx.mode);
    } else {
        throw new Error(
            `Unknown build mode: ${ctx.mode}. Known values: "production" | "development"`
        );
    }
});
