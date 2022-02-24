import xlrd,datetime
from pymongo import MongoClient
import pytz
SCRIPT_VERSION = "Keyword DB load"
time_zone = 'Asia/Calcutta'
tz = pytz.timezone(time_zone)

mongoClient = MongoClient('localhost', 27017)
db1 = mongoClient['Vbconfig']
db2 = mongoClient['Jsconfig']
Metadata=[]
Metadata_js = []

loc = ("VB.NET_Keywords.xlsx")
loc1 = ("JS_Keywords.xlsx")

wb = xlrd.open_workbook(loc)
sheet = wb.sheet_by_index(0)
sheet.cell_value(0, 0)

wb_js = xlrd.open_workbook(loc1)
sheet_js = wb_js.sheet_by_index(0)
sheet_js.cell_value(0, 0)

for i in range(1,sheet.nrows):
    d = {
        "keyword": "",
        "Meaning": ""
    }
    # print(sheet.row_values(i)[1],sheet.row_values(i)[2])
    d["keyword"] = sheet.row_values(i)[1]
    d["Meaning"] = sheet.row_values(i)[2]
    Metadata.append(d)
print(Metadata)

for i in range(1,sheet_js.nrows):
    d = {
        "keyword": "",
        "Meaning": ""
    }
    # print(sheet.row_values(i)[1],sheet.row_values(i)[2])
    d["keyword"] = sheet_js.row_values(i)[1]
    d["Meaning"] = sheet_js.row_values(i)[2]
    Metadata_js.append(d)
print(Metadata_js)

try:
    db1.keyword_lookup.remove()
    db1.keyword_lookup_js.remove()


except Exception as e:

    print('Error:' + str(e))

try:

    db1.keyword_lookup.insert_many(Metadata)
    db1.keyword_lookup_js.insert_many(Metadata_js)

    # updating the timestamp based on which report is called
    current_time = datetime.datetime.now(tz=tz).strftime("%A, %d. %B %Y %I:%M%p")
    if db1.keyword_lookup.update_one({"type": "metadata"}, {"$set": {"last_updated_on": current_time,
                                                                 "time_zone": time_zone,
                                                                 # "headers":["component_name","component_type"],
                                                                 "script_version": SCRIPT_VERSION
                                                                 }}, upsert=True).acknowledged:
        print('update sucess VB')

    if db1.keyword_lookup_js.update_one({"type": "metadata"}, {"$set": {"last_updated_on": current_time,
                                                                 "time_zone": time_zone,
                                                                 # "headers":["component_name","component_type"],
                                                                 "script_version": SCRIPT_VERSION
                                                                 }}, upsert=True).acknowledged:
        print('update sucess JS')

except Exception as e:
    print('Error:' + str(e))