// @ts-check
import { test, expect } from "@playwright/test";

test.use({
    storageState: {
        cookies: [],
        origins: [
            {
                origin: "http://localhost:5173",
                localStorage: [
                    {
                        name: "goals",
                        value: JSON.stringify([
                            {
                                goal: "Test goal",
                                trackingEntries: [],
                            },
                        ]),
                    },
                ],
            },
        ],
    },
});

test("can display goals restored from the local storage", async ({ page }) => {
    await page.goto("/");

    await expect(page.getByText("Test goal")).toBeVisible();
});
