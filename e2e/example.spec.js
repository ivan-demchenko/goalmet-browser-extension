// @ts-check
import { test, expect } from '@playwright/test';

test('can add a goal', async ({ page }) => {
  await page.goto('/');

  const goalInput = page.getByTestId("app-header").getByRole('textbox');
  await expect(goalInput).toBeVisible()
  
  const addGoalButton = page.getByTestId("app-header").getByRole('button');
  await expect(addGoalButton).toBeVisible()

  await goalInput.fill('My first goal');
  await addGoalButton.click();

  await expect(page.getByTestId('app-body').getByText('My first goal')).toBeVisible();
});
