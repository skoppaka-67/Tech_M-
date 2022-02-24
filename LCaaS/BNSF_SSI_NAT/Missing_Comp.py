# SCRIPT VERSION
SCRIPT_VERSION = 'Missing Component Report v0.1'
# IMPORTS
from pymongo import MongoClient
import pytz
import datetime
from bson.objectid import ObjectId
import timeit
import config
import json,os,sys
# import config1
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
# client = MongoClient(config1.database['mongo_endpoint_url'])
# db = client[config1.database['database_name']]
#client = MongoClient('localhost', 27017)
#db = client['BNSF_NAT_POC']
client = MongoClient(config.database['hostname'], config.database['port'])
db = client[config.database['database_name']]

f = open('D:\\bnsf\\BNSF_NAT\\one_click\\errors.txt', 'a')
# f.seek(0)
# f.truncate()

# Setting Application timezone
time_zone = 'Asia/Calcutta'
tz = pytz.timezone(time_zone)

# Ignored Types list
ignored_types_list = ['File', 'Utility','DDM']

# Start timer
start = timeit.default_timer()

# Fetch all unique items from Master Inv.
distinctIdCode = {"$group": {"_id": {"component_name": "$component_name", "component_type": "$component_type"}}}
res = db.master_inventory_report.aggregate([distinctIdCode])
master_inv_set = set()
master_inv_set_with_exten = set()
for ite in res:
    if ite['_id'] != {}:
        # print(ite['_id'])
        # master_inv_set.add((ite['_id']['component_name']))
        if ite['_id']['component_type'] not in ignored_types_list:
            if ite['_id']['component_type'] == "LDA" or ite['_id']['component_type'] == "PDA":
                master_inv_set.add(ite['_id']['component_name'].split(".")[0])
                master_inv_set_with_exten.add(ite['_id']['component_name'])
            else:
                master_inv_set.add(ite['_id']['component_name'])

# Fetch all the items in X-Reference called components
distinctIdCode = {"$group": {"_id": {"called_name": "$called_name", "called_type": "$called_type"}}}
res = db.cross_reference_report.aggregate([distinctIdCode])

cross_ref_set = set()
cross_ref_set_with_extension = set()

for ite in res:
    if ite['_id'] != {}:

        # # print(ite['_id'])
        # if ite['_id']['called_type'] not in ignored_types_list:
        #     cross_ref_set.add(ite['_id']['called_name'])

        if ite['_id']['called_type'] not in ignored_types_list:
            if ite['_id']['called_type'] == "LDA" or ite['_id']['called_type'] == "PDA":
                cross_ref_set.add(ite['_id']['called_name'].split(".")[0])
                cross_ref_set_with_extension.add(ite['_id']['called_name'])
            else:
                cross_ref_set.add(ite['_id']['called_name'])
    # print(x)
#master_inv_set=list(master_inv_set).split()[0]

missing_list = set(cross_ref_set) - set(master_inv_set)

# print(len(cross_ref_set),cross_ref_set)
# print(len(master_inv_set), master_inv_set)
# print(missing_list, len(missing_list))

# print('These are the missing components ')

for ite in missing_list:
    try:
        if not ite.__contains__("."):
            # print(ite)
            OUTPUT_DATA.append({"component_name": ite,"component_type": "LDA/PDA",'application':'Unknown'})
        else:
            name_and_type = ite.split(".")
            compnent_type = name_and_type[1]
            if compnent_type == "NAT":
                compnent_type = "NATURAL-PROGRAM"
            if compnent_type == "CPY":
                compnent_type = "COPYBOOK"
            OUTPUT_DATA.append({"component_name": ite,"component_type": compnent_type,'application':'Unknown'})


    except Exception as e:
        from datetime import datetime
        exc_type, exc_obj, exc_tb = sys.exc_info()
        fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
        print(exc_type, fname, exc_tb.tb_lineno)
        f.write(str(datetime.now()))
        f.write('\n' + str(exc_type) + '\n' + fname + '\n' + str(
            exc_tb.tb_lineno) + '\n' + '***********************************' + '\n')
        pass
# print(master_inv_set_with_exten)
# print(cross_ref_set_with_extension)
#print(json.dumps(OUTPUT_DATA,indent=4))
# Delete already existing data
try:
    db.missing_components_report.delete_many({})

except Exception as e:
    from datetime import datetime
    exc_type, exc_obj, exc_tb = sys.exc_info()
    fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
    print(exc_type, fname, exc_tb.tb_lineno)
    f.write(str(datetime.now()))
    f.write('\n' + str(exc_type) + '\n' + fname + '\n' + str(exc_tb.tb_lineno) + '\n' + '***********************************' + '\n')
    pass

# Insert into DB
try:
    current_time = datetime.datetime.now(tz=tz).strftime("%A, %d. %B %Y %I:%M%p")
    if db.missing_components_report.update_one({"type": "metadata"}, {"$set": {"last_updated_on": current_time,
                                                                               "time_zone": time_zone,
                                                                               "headers": ["component_name", "component_type","application"],

                                                                               "script_version": SCRIPT_VERSION
                                                                               }}, upsert=True).acknowledged:
        #print('update metda sucess')
        pass
    if db.missing_components_report.insert_many(OUTPUT_DATA):
        #print('update sucess')
        pass


except Exception as e:
    from datetime import datetime
    exc_type, exc_obj, exc_tb = sys.exc_info()
    fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
    print(exc_type, fname, exc_tb.tb_lineno)
    f.write(str(datetime.now()))
    f.write('\n' + str(exc_type) + '\n' + fname + '\n' + str(exc_tb.tb_lineno) + '\n' + '***********************************' + '\n')
    pass
#
# # Stop program timer
# stop = timeit.default_timer()
# print('Total execution time: ', stop - start)
f.close()
