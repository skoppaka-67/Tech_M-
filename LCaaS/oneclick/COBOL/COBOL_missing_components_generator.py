# SCRIPT VERSION
SCRIPT_VERSION = 'Missing Component Report v0.1'
# IMPORTS
from pymongo import MongoClient
import pytz
import datetime
from bson.objectid import ObjectId
import timeit
import config

OUTPUT_DATA = []

'''
########################### EXCEL CONFIGURATION #################################
# Specify the folder where the workbook is present
file_location = "E:\\Work\\Work\\Automation\\Projects\\Mainframe Static Code Analyser\\Naga Inputs\\Sample_Code\\"
# Specify the file name
file_name = "Missing Components.xlsx"
# Specify the sheet name that contains the data
sheet_name = "Sheet1"

# Excel Initialization
wb = load_workbook(file_location + file_name, data_only=True)
sh = wb[sheet_name]
'''

# MongoDB Information
# client = MongoClient(config.database['hostname'], config.database['port'])
# db = client[config.database['database_name']]
# db = client["COBOL_NEW"]
# Setting Application timezone
time_zone = 'Asia/Calcutta'
tz = pytz.timezone(time_zone)
client = MongoClient(config.database_COBOL['hostname'], config.database_COBOL['port'])
db = client[config.database_COBOL['database_name']]

# Ignored Types list
ignored_types_list = ['FILE', 'Utility', 'JCL']

# Start timer
start = timeit.default_timer()

# Fetch all unique items from Master Inv.
distinctIdCode = {"$group": {"_id": {"component_name": "$component_name", "component_type": "$component_type"}}}
res = db.master_inventory_report.aggregate([distinctIdCode])

master_inv_set = []

for ite in res:
    if ite['_id'] != {}:

        component_name1 = ite['_id']['component_name']
        if ite['_id']['component_type'] == 'DCLGEN':

            master_inv_set.append(component_name1[:-7] + ' ' + ite['_id']['component_type'])
        elif ite['_id']['component_type'] == 'PROC':
            master_inv_set.append(component_name1[:-5] + ' ' + ite['_id']['component_type'])
        else:
            master_inv_set.append(component_name1[:-4] + ' ' + ite['_id']['component_type'])

# Fetch all the items in X-Reference called components
# distinctIdCode = { "$group": { "_id": { "component_name": "$component_name", "component_type": "$component_type" } } }
distinctIdCode = {"$group": {"_id": {"called_name": "$called_name", "called_type": "$called_type"}}}
res = db.cross_reference_report.aggregate([distinctIdCode])
# res = db.cross_reference_report.aggregate([distinctIdCode])

cross_ref_set = []

for ite in res:
    if ite['_id'] != {}:
        #print(ite['_id'])
        if ite['_id']['called_type'] not in ignored_types_list:
            cross_ref_set.append(ite['_id']['called_name'] + ' ' + ite['_id']['called_type'])


cross_ref_set = set(cross_ref_set)
master_inv_set = set(master_inv_set)
missing_list = set(cross_ref_set) - set(master_inv_set)

#print('These are the missing components ')
for ite in missing_list:
    name_and_type = ite.split()
    OUTPUT_DATA.append({"component_name": name_and_type[0], "component_type": name_and_type[1]})

# Delete already existing data
try:
    db.missing_components_report.delete_many({})
except Exception as e:
    print('Error while deleting missing components report:' + str(e))

# Insert into DB
try:
    current_time = datetime.datetime.now(tz=tz).strftime("%A, %d. %B %Y %I:%M%p")
    if db.missing_components_report.update_one({"type": "metadata"}, {"$set": {"last_updated_on": current_time,
                                                                               "time_zone": time_zone,
                                                                               "headers": ["component_name",
                                                                                           "component_type"],
                                                                               "script_version": SCRIPT_VERSION
                                                                               }}, upsert=True).acknowledged:
        #print('update sucess')
        pass
    # OUTPUT_DATA=[item for item in OUTPUT_DATA if item['component_type']!='FILE']
    db.missing_components_report.insert_many(OUTPUT_DATA)
except Exception as e:
    pass
    # print('Error while inserting into missing components:' + str(e))

# Stop program timer
stop = timeit.default_timer()
#print('Total execution time: ', stop - start)
