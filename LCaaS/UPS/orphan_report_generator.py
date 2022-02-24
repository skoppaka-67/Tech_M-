#SCRIPT VERSION
SCRIPT_VERSION = 'Orphan Report v0.1'
from pymongo import MongoClient
import pytz
import datetime
import config
import timeit
start = timeit.default_timer()
client = MongoClient(config.database['hostname'], config.database['port'])
db = client[config.database['database_name']]

master_set = set()
crossref_called_set = set()

# Fetch all unique items from Master  Inv.
#master_inv_list = db.master_inventory_report.find({'type':{"$ne": "metadata"}})

#Put all the master_inv and type details into a combination
distinctIdCode = { "$group": { "_id": { "component_name": "$component_name", "component_type": "$component_type" } } }
res = db.master_inventory_report.aggregate([distinctIdCode])

master_inv_set = set()

for ite in res:
    if ite['_id']!= {}:
        #print(ite['_id'])
        component_name1=ite['_id']['component_name']
        #print(component_name1)
        if component_name1.__contains__('.sysin')  :
           master_inv_set.add(component_name1[:-6]+' '+ite['_id']['component_type'])
        else:
            master_inv_set.add(component_name1[:-4] + ' ' + ite['_id']['component_type'])

print(master_inv_set)
        # Fetch all the items in X-Reference called components
"""
cross_reference = db.cross_reference_report.find({"$or": [{'component_type': {"$ne": "FILE"}},
                                                          {'component_type': {"$ne": "FTP Utility"}},
                                                          {'component_type': {"$ne": "Sort Utility"}},
                                                            {'component_type': {"$ne": "Mail Utility"}},
                                                          ]})

"""

cross_reference = db.cross_reference_report.find({"$or": [{'type': {"$ne": "metadata"}}]})

cross_ref_set = set()

ignored_types_list=['JCL']
for ite in cross_reference:
    if ite['_id'] != {}:
        # print(ite['_id'])
        if ite['called_type'] not in ignored_types_list:
            if ite['called_name'].__contains__(".PARMLIB("):

                print()
                sysin_parmlib_name = ite['called_name'].split("PARMLIB")[1].strip("(").strip(")")
                cross_ref_set.add(sysin_parmlib_name+' '+"SYSIN")
                print("PARMLIB:",sysin_parmlib_name)
            if ite['comments'].__contains__(".PARMLIB("):
                sysin_comments_name = ite['comments'].split("PARMLIB")[1].strip("(").strip(")")
                cross_ref_set.add(sysin_comments_name+' '+"SYSIN")
                print("Comments:",sysin_comments_name)
            cross_ref_set.add(ite['called_name']+' '+ite['called_type'].upper())

print(cross_ref_set)
orphan_list = set(master_inv_set) - set(cross_ref_set)


# Setting Application timezone
time_zone = 'Asia/Calcutta'
tz = pytz.timezone(time_zone)

OUTPUT_DATA=[]
print('These are the orphan components ')
for ite in orphan_list:
    name_and_type = ite.split()
    if name_and_type[1].lower()!='jcl':
         OUTPUT_DATA.append({"component_name": name_and_type[0], "component_type": name_and_type[1]})


#Delete already existing data
try:
    db.orphan_report.delete_many({})
except Exception as e:
    print('Error while deleting missing components report:'+str(e))

#Insert into DB
try:
    current_time = datetime.datetime.now(tz=tz).strftime("%A, %d. %B %Y %I:%M%p")
    if db.orphan_report.update_one({"type": "metadata"}, {"$set": {"last_updated_on": current_time,
                                                                   "time_zone": time_zone,
                                                                   "headers": ["component_name", "component_type"],
                                                                    "script_version":SCRIPT_VERSION
                                                                   }}, upsert=True).acknowledged:
        print('update sucess')
    db.orphan_report.insert_many(OUTPUT_DATA)
except Exception as e:
    print('Error while inserting into missing components:'+str(e))

#Stop program timer
stop = timeit.default_timer()
print('Total execution time: ',stop-start)

"""
print(orphan_list)
OUTPUT_DATA = []
PARAMS = {"$or": [],"$and":[]}
for ite in orphan_list:
    PARAMS['$or'].append({"component_name":ite})

#Making sure JCLs dont show up in final report
PARAMS['$and'].append({'component_type': {"$ne": "JCL"}})

try:
    #Fetch all the records of orphans
    cursor = db.master_inventory_report.find(PARAMS, {'_id': 0,'component_name':1,'component_type':1})
except Exception as e:
    print('Error:'+str(e))

#Generate the orphan report, to be uploaded to db
for row in cursor:
    OUTPUT_DATA.append(row)
    print('orphan',row)

# #Delete already existing data
# try:
#     db.orphan_report.delete_many({'type': {"$ne": "metadata"}})
# except Exception as e:
#     print('Error:'+str(e))
#
# #Insert into DB
# try:
#
#     db.orphan_report.insert_many(OUTPUT_DATA)
#     # updating the timestamp based on which report is called
#     current_time = datetime.datetime.now(tz=tz).strftime("%A, %d. %B %Y %I:%M%p")
#     if db.orphan_report.update_one({"type": "metadata"},{"$set": {"last_updated_on": current_time,
#                                                                "time_zone": time_zone,
#                                                                "headers":["component_name","component_type"],
#                                                                 "script_version": SCRIPT_VERSION
#                                                             }},upsert=True).acknowledged:
#        print('update sucess')
# except Exception as e:
#     print('Error:'+str(e))
#
"""