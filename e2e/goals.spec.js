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

test("can add and remove notes", async ({ page }) => {
    await page.goto("/");

    await page.getByRole("textbox").click();
    await page.getByRole("textbox").fill("Test Goal 1");
    await page.getByRole("button", { name: "Add a goal" }).click();
    await expect(page.getByText("Test Goal")).toBeVisible();
    await page.getByRole("button", { name: "1", exact: true }).click();
    await page.getByTestId("goal-track-action").click();
    await page.getByTestId("goal-tracking-dialog").getByRole("textbox").click();
    await page
        .getByTestId("goal-tracking-dialog")
        .getByRole("textbox")
        .fill("Note 1");
    await page.getByRole("button", { name: "Commit" }).click();
    await page.getByTestId("goal-track-action").click();
    await page.getByTestId("goal-tracking-dialog").getByRole("textbox").click();
    await page
        .getByTestId("goal-tracking-dialog")
        .getByRole("textbox")
        .fill("Note 2");
    await page.getByRole("button", { name: "Commit" }).click();
    await expect(page.getByText("Note 1")).toBeVisible();
    await expect(page.getByText("Note 2")).toBeVisible();
    await page
        .getByTestId("goal-tracking-notes")
        .locator("div")
        .filter({ hasText: "Note 1" })
        .getByTestId("delete-note-btn")
        .click();
    await expect(page.getByText("Note 1")).not.toBeVisible();
    await expect(page.getByText("Note 2")).toBeVisible();
    await expect(
        page.getByTestId("goal-tracking-notes").getByRole("list")
    ).toContainText("Note 2");
});
