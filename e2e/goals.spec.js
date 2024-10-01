// @ts-check
import { test, expect } from "@playwright/test";

test("can add a goal", async ({ page }) => {
    await page.goto("/");

    await page.getByRole("textbox").click();
    await page.getByRole("textbox").fill("My first goal");
    await page.getByRole("button", { name: "Add a goal" }).click();

    await expect(
        page.getByRole("main").getByRole("list").getByText("My first goal")
    ).toBeVisible();

    /** @type {Array<any>} */
    const storedItems = await page.evaluate(() => {
        let raw = window.localStorage.getItem("goals");
        return raw ? JSON.parse(raw) : [];
    });
    expect(storedItems.length).toBeGreaterThan(0);
});

test("can delete a goal", async ({ page }) => {
    await page.goto("/");

    await page.getByRole("textbox").click();
    await page.getByRole("textbox").fill("My goal");
    await page.getByRole("button", { name: "Add a goal" }).click();
    await page.getByTestId("goal-delete-action").click();
    await page
        .getByTestId("goal-deletion-dialog")
        .getByRole("button", { name: "Delete" })
        .click();
    await expect(page.getByText("Add your first goal")).toBeVisible();

    /** @type {Array<any>} */
    const storedItems = await page.evaluate(() => {
        let raw = window.localStorage.getItem("goals");
        return raw ? JSON.parse(raw) : [];
    });
    expect(storedItems.length).toEqual(0);
});

test("can track a goal", async ({ page }) => {
    await page.goto("/");

    await page.getByRole("textbox").click();
    await page.getByRole("textbox").fill("My first goal");
    await page.getByRole("button", { name: "Add a goal" }).click();
    await page.getByTestId("goal-track-action").click();
    await page.getByTestId("goal-tracking-dialog").getByRole("textbox").click();
    await page
        .getByTestId("goal-tracking-dialog")
        .getByRole("textbox")
        .fill("this is a test note");
    await page.getByRole("button", { name: "Commit" }).click();
    await expect(page.locator("button.bg-green-300")).toBeVisible();
});
