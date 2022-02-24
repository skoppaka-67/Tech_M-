
#clors added code

import asyncio , os,glob
from pyppeteer import launch
from pymongo import MongoClient

from PIL import Image
client = MongoClient('localhost', 27017)
db = client['C#']
col = db.para_flowchart_data

path = r"C:\Users\KS00561356\PycharmProjects\LCaaS\screecapt\flowchart"
op_folder_path = r"C:\Users\KS00561356\PycharmProjects\LCaaS\screecapt\flowchart\cap"

def creat_HTML():


    cursor = db.para_flowchart_data.find({"type": {"$ne": "metadata"}}, {"_id": 0})
    for doc in cursor:
        # print(doc)
        f = open(doc["component_name"]+"-"+doc["para_name"].replace("/","-")+".html", "w")
        # f.write('<div style="background-color:black; color:green;">'+"\n"+"\t"+doc["codeString"]+"\n"+'</div>')
        f.write("""
        <script src="http://cdnjs.cloudflare.com/ajax/libs/raphael/2.3.0/raphael.min.js"></script>
        <script src="http://flowchart.js.org/flowchart-latest.js"></script>
        <div id="diagram"></div>
            <script>
                var diagram = flowchart.parse(`"""+doc["option"]+"""`);
                diagram.drawSVG('diagram');diagram.drawSVG('diagram',"""+"""{
                              'x': 0,
                              'y': 0,
                              'line-width': 3,
                              'line-length': 50,
                              'text-margin': 10,
                              'font-size': 14,
                              'font-color': 'black',
                              'line-color': 'black',
                              'element-color': 'black',
                              'fill': 'white',
                              'yes-text': 'yes',
                              'no-text': 'no',
                              'arrow-end': 'block',
                              'scale': 1,
                              'symbols': {
                                'start': {
                                  'font-color': 'black',
                                  'element-color': 'black',
                                  'fill': 'yellow'
                                },
                                'end':{
                                  'class': 'end-element'
                                }
                              },
                              'flowstate' : {
                                'past' : { 'fill' : '#99cc00', 'font-size' : 12},
                                'current' : {'fill' : 'yellow', 'font-color' : 'red', 'font-weight' : 'bold'},
                                'future' : { 'fill' : '#FFFF99'},
                                'request' : { 'fill' : 'blue'},
                                'invalid': {'fill' : '#444444'},
                                'approved' : { 'fill' : '#00ccff', 'font-size' : 12, 'yes-text' : 'yes', 'no-text' : 'no' },
                                'rejected' : { 'fill' : '#ff471a', 'font-size' : 12, 'yes-text' : 'yes', 'no-text' : 'no' }
                              }
                            }"""+""");
            </script>
            
        """)
        print("1.HTML FILE CREATED FOR ----->",doc["component_name"]+"-"+doc["para_name"].replace("/","-"))
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
        print("2.Capturing Flowchart for ------->",file.split("\\")[-1])
        await page.goto(file)
        await page.screenshot({'path': op_folder_path+'\\'+file.split("\\")[-1].replace(".html","")+'.png','fullPage': 'true'})
        # image1 = Image.open(file.split("\\")[-1].replace(".html","")+'.png')
        #
        # im1 = image1.convert('RGB')
        #
        # imagelist = []
        #
        # im1.save( file.split("\\")[-1].replace(".html","")+'.pdf', save_all=True, append_images=imagelist)
        #
        # print("3.PDF Created...")
        print("3.File Removed",file.split("\\")[-1])
        os.remove(file)
    await browser.close()






# creat_HTML()
asyncio.get_event_loop().run_until_complete(main())