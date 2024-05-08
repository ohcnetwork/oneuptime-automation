require('dotenv').config();
const puppeteer = require('puppeteer');
const fs = require('fs');
const csv = require('csv-parser');

(async () => {
  const browser = await puppeteer.launch({ headless: false, defaultViewport: { width: 1920, height: 1080 }, args: ['--start-maximized'] });
  const page = await browser.newPage();

  try {
    // Navigate to the login page
    await page.goto(`https://oneuptime.${process.env.DOMAIN}/accounts/`, { waitUntil: 'networkidle0' });

    // Wait for email input field and enter email
    await page.waitForSelector('input[type="email"]');
    await page.type('input[type="email"]', process.env.ADMIN_EMAIL);

    // Wait for password input field and enter password
    await page.waitForSelector('input[type="password"]');
    await page.type('input[type="password"]', process.env.ADMIN_PASSWORD);

    // Click the login button
    await Promise.all([
      page.waitForNavigation({ waitUntil: 'networkidle0' }),
      page.click('#login-form-submit-button')
    ]);

    // Read monitors data from CSV file
    const monitors = [];
    await new Promise((resolve, reject) => {
      fs.createReadStream(process.env.MONITOR_CSV_FILE)
        .pipe(csv())
        .on('data', (row) => {
          monitors.push(row);
        })
        .on('end', resolve)
        .on('error', reject);
    });

    for (const monitor of monitors) {
      await page.goto(`https://oneuptime.${process.env.DOMAIN}/dashboard/${process.env.PROJECT_ID}/monitors`, { waitUntil: 'networkidle0' });

      // Click the button to add a monitor
      await page.click('button[data-testid="card-button"]');

      // Enter monitor name
      await page.waitForSelector('input[placeholder="Monitor Name"]');
      await page.focus('input[placeholder="Monitor Name"]');
      await page.keyboard.sendCharacter(monitor.name);

      // Enter monitor description
      await page.waitForSelector('textarea[placeholder="Description"]');
      await page.focus('textarea[placeholder="Description"]');
      await page.keyboard.sendCharacter(monitor.description);

      // Focus on the "Monitor Type" field
      await page.keyboard.press('Tab');

      // Enter "ap" and press Enter to select the "API" option
      await page.type('input[role="combobox"]', 'ap');
      await page.keyboard.press('Enter');

      // Click the "Next" button
      await page.waitForSelector('button[data-testid="modal-footer-submit-button"]');
      await page.click('button[data-testid="modal-footer-submit-button"]');

      // Enter monitor URL
      await page.waitForSelector('input[type="text"].block.w-full.rounded-md.border.border-gray-300');
      await page.focus('input[type="text"].block.w-full.rounded-md.border.border-gray-300');
      await page.keyboard.sendCharacter(monitor.url);

      // Click the "Next" button to proceed to the next page
      await page.click('button[data-testid="modal-footer-submit-button"]');

      // Focus on the "Monitoring Interval" field
      await page.keyboard.press('Tab');

      // Type "m" to select the "Monitoring Interval" option
      await page.type('input[role="combobox"]', 'm');
      await page.keyboard.press('Enter');

      // Submit the form
      await page.waitForSelector('button[type="submit"]');
      await page.click('button[type="submit"]');
    }

    console.log('Monitors added successfully.');
  } catch (error) {
    console.error('An error occurred:', error);
  } finally {
    await browser.close();
  }
})();
