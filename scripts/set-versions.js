import * as fs from "node:fs";
import * as path from "node:path";

const dirName = import.meta.dirname;

function setManifestVersion(version) {
    console.log(`Setting manifest version: ${version}`);

    const filePath = path.resolve(dirName, "..", "manifest.json");
    const raw = fs.readFileSync(filePath, { encoding: "utf-8" });

    const json = JSON.parse(raw);
    json.version = version;

    fs.writeFileSync(filePath, JSON.stringify(json, null, 2), {
        encoding: "utf-8",
    });
}

const version = process.argv[2];

if (!version) {
    throw new Error("Version is missing to set in the Manifest");
}

setManifestVersion(version);
