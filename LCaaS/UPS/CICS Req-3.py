

import xlrd,os,copy,re,glob,xlsxwriter,openpyxl
from pymongo import MongoClient
import time,datetime ,pytz
import timeit
import pandas as pd
import config
import csv

Current_Division_Name=""
time_zone = 'Asia/Calcutta'
tz = pytz.timezone(time_zone)
client = MongoClient('localhost',27017)
db = client['GE_CICS']
METADATA=[]
data_object = {}
data_object['data'] = []
cursor = db.cross_reference_report.find({"$and":[{'component_type':"COBOL"},{'called_type':{"$in":['MAP', 'COBOL','TRAN', 'TSQ','TDQ','FILE']}}]},{'_id': 0})
metadata1 = db.cross_reference_report.find_one({"type": "metadata"}, {'_id': 0})
master_pgm=[]
master=db.master_inventory_report.find({"comments":"Online Screen"})
for master_data in master:
    master_pgm.append(master_data["component_name"][:-4])
for document in cursor:
    if document["component_name"] in master_pgm:
        METADATA.append(document)
if METADATA==[]:
    None
else:
    keys = METADATA[0].keys()
    with open('CICS2-X-ref.csv', 'w') as output_file:
        dict_writer = csv.DictWriter(output_file, keys)
        dict_writer.writeheader()
        dict_writer.writerows(METADATA)

# return jsonify(data_object)