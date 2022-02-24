from playwright.sync_api import Playwright, sync_playwright


def run(playwright: Playwright) -> None:
    browser = playwright.chromium.launch(headless=False)
    context = browser.new_context()

    # Open new page
    page = context.new_page()

    # Go to https://testingbot.com/
    page.goto("https://testingbot.com/")

    # Click text=Automated App Testing
    page.click("text=Automated App Testing")
    # assert page.url == "https://testingbot.com/mobile/realdevicetesting"

    # Click text=Pricing
    page.click("text=Pricing")
    # assert page.url == "https://testingbot.com/pricing"

    # Click text=Enterprise
    page.click("text=Enterprise")
    # assert page.url == "https://testingbot.com/enterprise"

    # Close page
    page.close()

    # ---------------------
    context.close()
    browser.close()


with sync_playwright() as playwright:
    run(playwright)
