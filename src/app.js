import { Elm } from "./Main.elm";

const localStorage = {
    read: async function readLocalStorage(key) {
        const raw = window.localStorage.getItem(key);
        if (!raw) {
            return { [key]: null };
        }
        try {
            return { [key]: JSON.parse(raw) };
        } catch (_) {
            return { [key]: null };
        }
    },
    write: async function writeLocalStorage(key, value) {
        window.localStorage.setItem(key, JSON.stringify(value));
    },
};

const chromeStorage = {
    read: async function readChromeStorage(key) {
        return chrome.storage.local.get([key]);
    },
    write: async function writeChromeStorage(key, value) {
        return chrome.storage.local.set({ [key]: value });
    },
};

async function main(storage) {
    const data = await storage.read("goals").catch((err) => console.error(err));

    const app = Elm.Main.init({
        node: document.getElementById("app"),
        flags: {
            command: "initial-goals",
            payload: data.goals,
        },
    });

    app.ports.sendRPC.subscribe((rpc) => {
        if (rpc.command === "save-goals") {
            storage
                .write("goals", rpc.payload)
                .catch((err) => console.error(err));
        }
    });
}

const storage = __TARGET__ === "production" ? chromeStorage : localStorage;

main(storage).catch((err) => console.error(err));
