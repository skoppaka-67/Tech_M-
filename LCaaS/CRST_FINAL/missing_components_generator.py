#SCRIPT VERSION
SCRIPT_VERSION = 'Missing Component Report v0.1'
#IMPORTS
from pymongo import MongoClient
import pytz
import datetime
from bson.objectid import ObjectId
import timeit
import config_crst
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

#MongoDB Information
client = MongoClient(config_crst.database['hostname'], config_crst.database['port'])
db = client[config_crst.database['database_name']]

# Setting Application timezone
time_zone = 'Asia/Calcutta'
tz = pytz.timezone(time_zone)

#Ignored Types list
ignored_types_list = ['Utility','JCL','FILE','TDQ','TSQ','INCLUDE','TRAN']

#Start timer
start = timeit.default_timer()

# Fetch all unique items from Master Inv.
distinctIdCode = { "$group": { "_id": { "component_name": "$component_name", "component_type": "$component_type" } } }
res = db.master_inventory_report.aggregate([distinctIdCode])
# print("Master_res:",res)

master_inv_set = set()

for ite in res:
    if ite['_id']!= {}:
        # print(ite['_id'])
        component_name1 = ite['_id']['component_name']
        # print(component_name1)
        component_extension = component_name1.split(".")[1]
        if component_extension == "sysin":
            # print("SUccess")
            master_inv_set.add(component_name1[:-6] + ' ' + ite['_id']['component_type'])
        else:
            master_inv_set.add(component_name1[:-4]+' '+ite['_id']['component_type'])
print(master_inv_set)

# Fetch all the items in X-Reference called components
#distinctIdCode = { "$group": { "_id": { "component_name": "$component_name", "component_type": "$component_type" } } }
# distinctIdCode = { "$group": { "_id": { "called_name": "$called_name", "called_type": "$called_type" } } }
# res = db.cross_reference_report.aggregate([distinctIdCode])
# #res = db.cross_reference_report.aggregate([distinctIdCode])
#
# cross_ref_set = set()
# check_types_list = []
# for ite in res:
#     if ite['_id'] != {}:
#         # print(ite['_id'])
#         print("Check:",ite['called_type'])
#         if ite['called_type'] not in ignored_types_list:
#             if ite['called_name'].__contains__(".PARMLIB("):
#
#                 print()
#                 sysin_parmlib_name = ite['called_name'].split("PARMLIB")[1].strip("(").strip(")")
#                 cross_ref_set.add(sysin_parmlib_name+' '+"SYSIN")
#                 print("PARMLIB:",sysin_parmlib_name)
#             if ite['comments'].__contains__(".PARMLIB("):
#                 sysin_comments_name = ite['comments'].split("PARMLIB")[1].strip("(").strip(")")
#                 cross_ref_set.add(sysin_comments_name+' '+"SYSIN")
#                 print("Comments:",sysin_comments_name)
#             cross_ref_set.add(ite['called_name']+' '+ite['called_type'].upper())
# # print(ite['_id']['called_type'])
# print(cross_ref_set)

cross_reference = db.cross_reference_report.find({"$or": [{'type': {"$ne": "metadata"}}]})

cross_ref_set = set()

# ignored_types_list=['JCL']
for ite in cross_reference:
    if ite['_id'] != {}:
        # print(ite['_id'])
        if ite['called_type'] not in ignored_types_list:
            if ite['called_type'] == "File":
                if ite['called_name'].__contains__(".PARMLIB("):

                    # print()
                    sysin_parmlib_name = ite['called_name'].split("PARMLIB")[1].strip("(").strip(")")
                    cross_ref_set.add(sysin_parmlib_name+' '+"SYSIN")
                    # print("PARMLIB:",sysin_parmlib_name)
                if ite['comments'].__contains__(".PARMLIB("):
                    sysin_comments_name = ite['comments'].split("PARMLIB")[1].strip("(").strip(")")
                    cross_ref_set.add(sysin_comments_name+' '+"SYSIN")
                    # print("Comments:",sysin_comments_name)
                else:
                    continue
            if ite['called_type'] == "SYSTSIN":
                if ite['called_name'].__contains__(".PARMLIB("):
                    print("SYSTSIN:",ite['called_name'])
                    sysin_parmlib_name = ite['called_name'].split("PARMLIB")[1].strip("(").strip(")")
                    cross_ref_set.add(sysin_parmlib_name + ' ' + "SYSIN")
                    print("PARMLIB:", sysin_parmlib_name)
                if ite['comments'].__contains__(".PARMLIB("):
                    sysin_comments_name = ite['comments'].split("PARMLIB")[1].strip("(").strip(")")
                    cross_ref_set.add(sysin_comments_name + ' ' + "SYSIN")
                    print("Comments:", sysin_comments_name)
                else:
                    continue

            cross_ref_set.add(ite['called_name']+' '+ite['called_type'].upper())

print(cross_ref_set)


missing_list = set(cross_ref_set) - set(master_inv_set)
print(missing_list)

# print('These are the missing components ')
for ite in missing_list:
    name_and_type = ite.split()
    OUTPUT_DATA.append({"component_name": name_and_type[0], "component_type": name_and_type[1]})


#Delete already existing data
try:
    db.missing_components_report.delete_many({})
except Exception as e:
    print('Error while deleting missing components report:'+str(e))

#Insert into DB
try:
    current_time = datetime.datetime.now(tz=tz).strftime("%A, %d. %B %Y %I:%M%p")
    if db.missing_components_report.update_one({"type": "metadata"}, {"$set": {"last_updated_on": current_time,
                                                                   "time_zone": time_zone,
                                                                   "headers": ["component_name", "component_type"],
                                                                    "script_version":SCRIPT_VERSION
                                                                   }}, upsert=True).acknowledged:
        print('update sucess')
    db.missing_components_report.insert_many(OUTPUT_DATA)
except Exception as e:
    print('Error while inserting into missing components:'+str(e))

#Stop program timer
stop = timeit.default_timer()
print('Total execution time: ',stop-start)

