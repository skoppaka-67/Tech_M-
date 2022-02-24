from playwright.sync_api import Playwright, sync_playwright


def run(playwright: Playwright) -> None:
    browser = playwright.chromium.launch(headless=False)
    context = browser.new_context()

    # Open new page
    page = context.new_page()

    # Go to https://www.w3schools.com/html/
    page.goto("https://www.w3schools.com/html/")

    # Click text=HTML Editors
    page.click("text=HTML Editors")
    # assert page.url == "https://www.w3schools.com/html/html_editors.asp"

    # ---------------------
    context.close()
    browser.close()


with sync_playwright() as playwright:
    run(playwright)
