
'''no need as of now we can use dist and webservice'''

import xlrd,datetime
from pymongo import MongoClient
import pytz
from xlsxwriter import Workbook

SCRIPT_VERSION = "Keyword DB load"
time_zone = 'Asia/Calcutta'
tz = pytz.timezone(time_zone)


mongoClient = MongoClient('localhost', 27017)
db1 = mongoClient['asp4']

Metadata=[]
Metadata_js = []

loc = ("glossary_Vb.xlsx")
loc1 = ("1glossary_js.xlsx")

wb = xlrd.open_workbook(loc)
sheet = wb.sheet_by_index(0)
sheet.cell_value(0, 0)

wb_js = xlrd.open_workbook(loc1)
sheet_js = wb_js.sheet_by_index(0)
sheet_js.cell_value(0, 0)

for i in range(1,sheet.nrows):
    d = {
        "File_name":"",
        "Variable": "",
        "Business_Meaning": ""
    }
    # print(sheet.row_values(i)[1],sheet.row_values(i)[2])
    d['File_name'] = sheet.row_values(i)[0]
    d["Variable"] = sheet.row_values(i)[1]
    d["Business_Meaning"] = sheet.row_values(i)[2]
    Metadata.append(d)
print(Metadata)
# #
for i in range(1,sheet_js.nrows):
    d1 = {
        "File_name": "",
        "Variable": "",
        "Business_Meaning": ""
    }
    # print(sheet.row_values(i)[1],sheet.row_values(i)[2])
    d1['File_name'] = sheet_js.row_values(i)[0]
    d1["Variable"] = sheet_js.row_values(i)[1]
    d1["Business_Meaning"] = sheet_js.row_values(i)[2]
    Metadata_js.append(d1)
print(Metadata_js)

try:
    db1.glossary.remove()
    db1.glossary_js.remove()


except Exception as e:

    print('Error:' + str(e))

try:

    db1.glossary.insert_many(Metadata)
    db1.glossary_js.insert_many(Metadata_js)

    # updating the timestamp based on which report is called
    current_time = datetime.datetime.now(tz=tz).strftime("%A, %d. %B %Y %I:%M%p")
    if db1.glossary.update_one({"type": "metadata"}, {"$set": {"last_updated_on": current_time,
                                                                 "time_zone": time_zone,
                                                                 # "headers":["component_name","component_type"],
                                                                 "script_version": SCRIPT_VERSION
                                                                 }}, upsert=True).acknowledged:
        print('update sucess VB')

    if db1.glossary_js.update_one({"type": "metadata"}, {"$set": {"last_updated_on": current_time,
                                                                 "time_zone": time_zone,
                                                                 # "headers":["component_name","component_type"],
                                                                 "script_version": SCRIPT_VERSION
                                                                 }}, upsert=True).acknowledged:
        print('update sucess JS')

except Exception as e:
    print('Error:' + str(e))

