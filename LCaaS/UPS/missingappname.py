#SCRIPT VERSION
SCRIPT_VERSION = 'Missing Component Report v0.1'
#IMPORTS
from pymongo import MongoClient
import pytz
import datetime
from bson.objectid import ObjectId
import timeit
# import config
# import config1
OUTPUT_DATA = []

mongoClient = MongoClient('localhost', 27017)
db = mongoClient['UPS_FINAL']

time_zone = 'Asia/Calcutta'
tz = pytz.timezone(time_zone)


#Start timer
start = timeit.default_timer()
missing_comp_name = db.missing_components_report.distinct("component_name")


for ite in missing_comp_name:
        res = db.cross_reference_report.find({"called_name" : ite})
        if res  :
            try:
                if res[0]["called_app_name"] == "Unknown":
                    db.missing_components_report.update_one({"application": "Unknown"},
                                   {"$set": {
                                       "application": res[0]["calling_app_name"]+"(Parent)"}})

                else:
                    db.missing_components_report.update_one({"application": "Unknown"},
                                                       {"$set": {
                                                           "application": res[0]["called_app_name"]}}) #this components are not missing
            except IndexError as e:
                print(ite)


print("Done")

# master_inv_set = set()
#
# for ite in res:
#     if ite['_id']!= {}:
#         #print(ite['_id'])
#         master_inv_set.add(ite['_id']['component_name']+' '+ite['_id']['component_type'])
#
#
# # Fetch all the items in X-Reference called components
# distinctIdCode = { "$group": { "_id": { "called_name": "$called_name", "called_type": "$called_type" } } }
# res = db.cross_reference_report.aggregate([distinctIdCode])
