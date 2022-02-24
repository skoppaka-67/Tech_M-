#SCRIPT VERSION
SCRIPT_VERSION = 'orpahn Component Report v0.1'
#IMPORTS
from pymongo import MongoClient
import pytz
import datetime
from bson.objectid import ObjectId
import timeit
# import config
OUTPUT_DATA = []

'''
########################### EXCEL CONFIGURATION #################################
# Specify the folder where the workbook is present
file_location = "E:\\Work\\Work\\Automation\\Projects\\Mainframe Static Code Analyser\\Naga Inputs\\Sample_Code\\"
# Specify the file name
file_name = "orphan Components.xlsx"
# Specify the sheet name that contains the data
sheet_name = "Sheet1"

# Excel Initialization
wb = load_workbook(file_location + file_name, data_only=True)
sh = wb[sheet_name]
'''

#MongoDB Information
client = MongoClient('localhost', 27017)
db = client['plsql']

# Setting Application timezone
time_zone = 'Asia/Calcutta'
tz = pytz.timezone(time_zone)

#Ignored Types list
ignored_types_list = ['File','Utility','Procedure']

#Start timer
start = timeit.default_timer()

# Fetch all unique items from Master Inv.
distinctIdCode = { "$group": { "_id": { "component_name": "$component_name", "component_type": "$component_type" } } }
res = db.master_inventory_report.aggregate([distinctIdCode])

master_inv_set = set()

for ite in res:
    if ite['_id']!= {}:
        #print(ite['_id'])
        if ite['_id']['component_type'] not in ignored_types_list:
            master_inv_set.add(ite['_id']['component_name']+' '+ite['_id']['component_type'])


# Fetch all the items in X-Reference called components
distinctIdCode = { "$group": { "_id": { "called_name": "$called_name", "called_type": "$called_type" } } }
res = db.cross_reference_report.aggregate([distinctIdCode])

cross_ref_set = set()

for ite in res:
    if ite['_id'] != {}:
        #print(ite['_id'])
        if ite['_id']['called_type'] not in ignored_types_list:
            cross_ref_set.add(ite['_id']['called_name']+' '+ite['_id']['called_type'])


orphan_list = set(master_inv_set) - set(cross_ref_set)

# print('These are the orphan components ')
for ite in orphan_list:
    name_and_type = ite.split()
    OUTPUT_DATA.append({"component_name": name_and_type[0], "component_type": ite[len(name_and_type[0])+1:]})


#Delete already existing data
try:
    db.orphan_report.delete_many({})
except Exception as e:
    print('Error while deleting orphan components report:'+str(e))

#Insert into DB
try:
    current_time = datetime.datetime.now(tz=tz).strftime("%A, %d. %B %Y %I:%M%p")
    if db.orphan_report.update_one({"type": "metadata"}, {"$set": {"last_updated_on": current_time,
                                                                   "time_zone": time_zone,
                                                                   "headers": ["component_name", "component_type"],
                                                                    "script_version":SCRIPT_VERSION
                                                                   }}, upsert=True).acknowledged:
        print('update metda sucess')
    if db.orphan_report.insert_many(OUTPUT_DATA):
        print('update sucess')

except Exception as e:
    print('Error while inserting into orphan components:'+str(e))

#Stop program timer
stop = timeit.default_timer()
print('Total execution time: ',stop-start)

