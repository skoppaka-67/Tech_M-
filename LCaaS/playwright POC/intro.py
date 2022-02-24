from playwright.sync_api import Playwright, sync_playwright
def run(playwright: Playwright) -> None:
    browser = playwright.chromium.launch(headless=False)
    context = browser.new_context()
    # Open new page
    page = context.new_page()
    # Go to https://www.google.com/
    page.goto("https://www.google.com/")
    # Click [aria-label="Search"]
    page.click("[aria-label=\"Search\"]")
    # Fill [aria-label="Search"]
    page.fill("[aria-label=\"Search\"]", "cypress")
    # Press Enter
    # with page.expect_navigation(url="https://www.google.com/search?q=cypress&source=hp&ei=HMBIYY3qFKaF4t4Prr-buA0&iflsig=ALs-wAMAAAAAYUjOLE-ZJjnacIMYTWAI7KkYO-rfDo90&oq=cypress&gs_lcp=Cgdnd3Mtd2l6EAMyCAgAEIAEELEDMgsILhCABBDHARCvATIICC4QgAQQsQMyCAgAEIAEELEDMggIABCABBCxAzILCAAQgAQQsQMQgwEyCAgAEIAEELEDMgUIABCABDIFCAAQgAQyBQgAEIAEOg4IABDqAhCPARCMAxDlAjoICAAQsQMQgwE6CAguELEDEIMBOgsILhCABBDHARDRAzoFCAAQsQM6CwguEIAEELEDEJMCULkeWOoqYJMtaAFwAHgAgAG7AYgBpAmSAQMwLjeYAQCgAQGwAQo&sclient=gws-wiz&ved=0ahUKEwiN6IGrhY7zAhWmgtgFHa7fBtcQ4dUDCAc&uact=5"):
    with page.expect_navigation():
        page.press("[aria-label=\"Search\"]", "Enter")
    # assert page.url == "https://www.google.com/search?q=cypress&source=hp&ei=HMBIYY3qFKaF4t4Prr-buA0&iflsig=ALs-wAMAAAAAYUjOLE-ZJjnacIMYTWAI7KkYO-rfDo90&oq=cypress&gs_lcp=Cgdnd3Mtd2l6EAMyCAgAEIAEELEDMgsILhCABBDHARCvATIICC4QgAQQsQMyCAgAEIAEELEDMggIABCABBCxAzILCAAQgAQQsQMQgwEyCAgAEIAEELEDMgUIABCABDIFCAAQgAQyBQgAEIAEOg4IABDqAhCPARCMAxDlAjoICAAQsQMQgwE6CAguELEDEIMBOgsILhCABBDHARDRAzoFCAAQsQM6CwguEIAEELEDEJMCULkeWOoqYJMtaAFwAHgAgAG7AYgBpAmSAQMwLjeYAQCgAQGwAQo&sclient=gws-wiz&ved=0ahUKEwiN6IGrhY7zAhWmgtgFHa7fBtcQ4dUDCAc&uact=5"
    # Click text=JavaScript End to End Testing Framework | cypress.io
    page.click("text=JavaScript End to End Testing Framework | cypress.io")
    # assert page.url == "https://www.cypress.io/"
    # ---------------------
    context.close()
    browser.close()
with sync_playwright() as playwright:
    run(playwright)
