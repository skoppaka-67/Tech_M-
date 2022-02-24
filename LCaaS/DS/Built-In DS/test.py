from selenium import webdriver

driver = webdriver.Chrome('C:/Webdriver/chromedriver.exe')
driver.get("https://www.globalsqa.com/angularJs-protractor/BankingProject/#/customer")

html = driver.find_element_by_xpath("//*")
print(html.find_element_by_tag_name("div").get_attribute('class'))

# for i in range(10,20000):
#     un = driver.find_element_by_xpath("//*")
#     print(un)

# f = open("demofile2.html", "w")
# f.write(str(html))
# f.close()
#
# # HTML from `<html>`
# html = driver.execute_script("return document.documentElement.outerHTML;")
# print(html)
#
# # HTML from `<body>`
# html = driver.execute_script("return document.body.innerHTML;")
# print(html)
# #
#
# HTML from element with some JavaScript
# element = driver.find_element_by_css_selector("#hireme")
# html = driver.execute_script("return arguments[0].outerHTML;", element)
# print(html)
#
# # HTML from element with `get_attribute`
# element = driver.find_element_by_css_selector("#hireme")
# html = element.get_attribute('outerHTML')