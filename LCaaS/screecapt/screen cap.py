import asyncio , os,glob
from pyppeteer import launch
from pymongo import MongoClient

client = MongoClient('localhost', 27017)
db = client['BNSF_NAT_POC_2']
col = db.codeString


path = r"C:\Users\KS00561356\PycharmProjects\LCaaS\screecapt"

def creat_HTML():
    cursor = db.codeString.find({"type": {"$ne": "metadata"}}, {"_id": 0})
    for doc in cursor:
        print(doc)
        f = open(doc["MAP_NAME"]+".html", "w")
        f.write('<div style="background-color:black; color:green;">'+"\n"+"\t"+doc["codeString"]+"\n"+'</div>')
        f.close()

def get_files():
    filenames_list = []
    for filename1 in glob.glob(os.path.join(path, '*.html')):
        filenames_list.append(filename1)
    # return ["D:\Lcaas_imp\WebApplications\LobPF\PFPolicyInput.aspx.vb"]

    return filenames_list

async def main():
    browser = await launch()
    page = await browser.newPage()
    for file in get_files():
        await page.goto(file)
        await page.screenshot({'path': file.split("\\")[-1].split(".")[0]+'.png'})
    await browser.close()


creat_HTML()
asyncio.get_event_loop().run_until_complete(main())