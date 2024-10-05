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
    await page.getByRole("textbox").fill("test goal");
    await page.getByRole("button", { name: "Add a goal" }).click();
    await page.getByRole("textbox").click();
    await page.getByRole("textbox").fill("test goal 2");
    await page.getByRole("button", { name: "Add a goal" }).click();
    await expect(page.getByText("test goal 2")).toBeVisible();
    await expect(page.getByText("test goal", { exact: true })).toBeVisible();
    await page
        .locator("li")
        .filter({ hasText: "test goal 2" })
        .getByTestId("goal-delete-action")
        .click();
    await expect(
        page.getByTestId("delete-note-dialog").locator("div").filter({
            hasText: "Are you sure you want to delete the goal test goal 2",
        })
    ).toBeVisible();
    await page.getByRole("button", { name: "Yes, delete" }).click();
    await expect(
        page.locator("li").filter({ hasText: "test goal 2" })
    ).not.toBeVisible();

    /** @type {Array<any>} */
    const storedItems = await page.evaluate(() => {
        let raw = window.localStorage.getItem("goals");
        return raw ? JSON.parse(raw) : [];
    });
    expect(storedItems.length).toEqual(1);

    // Delete the last goal on the page

    await page
        .locator("li")
        .filter({ hasText: "test goal" })
        .getByTestId("goal-delete-action")
        .click();
    await expect(
        page.getByTestId("delete-note-dialog").locator("div").filter({
            hasText: "Are you sure you want to delete the goal test goal",
        })
    ).toBeVisible();
    await page.getByRole("button", { name: "Yes, delete" }).click();
    await expect(
        page.locator("li").filter({ hasText: "test goal" })
    ).not.toBeVisible();

    /** @type {Array<any>} */
    const storedItems2 = await page.evaluate(() => {
        let raw = window.localStorage.getItem("goals");
        return raw ? JSON.parse(raw) : [];
    });
    expect(storedItems2.length).toEqual(0);
});

test("can track a goal", async ({ page }) => {
    await page.goto("/");

    await page.getByRole("textbox").click();
    await page.getByRole("textbox").fill("test goal");
    await page.getByRole("button", { name: "Add a goal" }).click();
    await page.getByText("test goal").hover();
    await page.getByRole("button", { name: "1", exact: true }).click();
    await page.getByTestId("goal-track-action").click();
    await page.getByTestId("track-goal-dialog").getByRole("textbox").click();
    await page
        .getByTestId("track-goal-dialog")
        .getByRole("textbox")
        .fill("this is a note");
    await page.getByRole("button", { name: "Commit" }).click();
    await expect(page.getByText("this is a note")).toBeVisible();

    /** @type {Array<any>} */
    const entries = await page.evaluate(() => {
        const data = JSON.parse(window.localStorage.getItem("goals") || "[]");
        return (data[0] || { trackingEntries: [] }).trackingEntries || [];
    });
    expect(entries.length).toEqual(1);
});

test("can add and remove notes", async ({ page }) => {
    await page.goto("/");

    await page.getByRole("textbox").click();
    await page.getByRole("textbox").fill("test goal");
    await page.getByRole("button", { name: "Add a goal" }).click();
    await expect(page.getByText("test goal")).toBeVisible();
    await page.getByText("test goal").hover();
    await page.getByRole("button", { name: "1", exact: true }).click();

    await page.getByTestId("goal-track-action").click();
    await page.getByTestId("track-goal-dialog").getByRole("textbox").click();
    await page
        .getByTestId("track-goal-dialog")
        .getByRole("textbox")
        .fill("Note 1");
    await page.getByRole("button", { name: "Commit" }).click();

    await page.getByTestId("goal-track-action").click();

    await expect(page.getByTestId("track-goal-dialog")).toBeVisible();

    await page.getByTestId("track-goal-dialog").getByRole("textbox").click();
    await page
        .getByTestId("track-goal-dialog")
        .getByRole("textbox")
        .fill("Note 2");
    await page.getByRole("button", { name: "Commit" }).click();

    await expect(page.getByText("Note 1")).toBeVisible();
    await expect(page.getByText("Note 2")).toBeVisible();

    /** @type {Array<any>} */
    const entries = await page.evaluate(() => {
        const data = JSON.parse(window.localStorage.getItem("goals") || "[]");
        return (data[0] || { trackingEntries: [] }).trackingEntries || [];
    });
    expect(entries.length).toEqual(2);

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

    /** @type {Array<any>} */
    const entries2 = await page.evaluate(() => {
        const data = JSON.parse(window.localStorage.getItem("goals") || "[]");
        return (data[0] || { trackingEntries: [] }).trackingEntries || [];
    });
    expect(entries2.length).toEqual(1);
});
