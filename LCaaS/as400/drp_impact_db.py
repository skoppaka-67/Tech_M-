from builtins import print

from flask import Flask, request, jsonify
from pymongo import MongoClient
from collections import OrderedDict
import json
import pytz
import datetime
import re
import traceback
from flask_cors import CORS
import timeit
import sys
import copy
import csv
from openpyxl import Workbook, load_workbook
import pandas as pd
#import plistlibs
#import config1

#sys.path.append(sys.argv[1])
# client = MongoClient(config1.database['mongo_endpoint_url'])
# db = client[config1.database['database_name']]

client = MongoClient('localhost', 27017)
db = client['as400']
mydict=dict(x="1",y="2")
print(mydict)


app = Flask(__name__)
CORS(app)
app.config['JSON_SORT_KEYS'] = False
# print(db.list_collection_names())

# Setting Application timezone
time_zone = 'Asia/Calcutta'
tz = pytz.timezone(time_zone)

# CONSTANTS
CROSS_REF_TYPE = 'Cross-Ref'
CRUD_TYPE = 'Crud'
MASTER_INV_TYPE = 'Master-Inventory'
MISSING_COMP_TYPE = 'Missing-Components'
ORPHAN_REPORT_TYPE = 'Orphan-Report'
PROG_FLOW_TYPE = 'Program-Flow'

CROSS_REFERENCE_LIMIT = 2000
x=3
@app.route('/api/v1/dropImp', methods=['Get'])
def func1():
    # orphan_data1 = [{'component_name': 'AP540P00', 'component_type': 'COBOL'},
    #                 {'component_name': 'AP678P00', 'component_type': 'COBOL'},
    #                 {'component_name': 'AP541P00', 'component_type': 'COBOL'}]
    #
    # xref_data1 = [
    #     {'component_name': 'AP540P00', 'component_type': 'COBOL', "called_name": "Fetch1", "called_type": "COBOL"},
    #     {'component_name': 'AP541P00', 'component_type': 'COBOL', "called_name": "Fetch1", "called_type": "COBOL"},
    #     {'component_name': 'AP540P00', 'component_type': 'COBOL', "called_name": "Fetch", "called_type": "COBOL"},
    #     {'component_name': 'AP678P00', 'component_type': 'COBOL', "called_name": "Fetch1", "called_type": "COPYBOOK"},
    #     {'component_name': 'AP678P00', 'component_type': 'COBOL', "called_name": "Fetch1", "called_type": "COBOL"},
    #     {'component_name': 'AP676P00', 'component_type': 'COBOL', "called_name": "Fetch1", "called_type": "FILE"},
    #     {'component_name': 'AP679P00', 'component_type': 'COBOL', "called_name": "Fetch1", "called_type": "PROC"},
    #     {'component_name': 'AP677P00', 'component_type': 'COBOL', "called_name": "Fetch1", "called_type": "PROGRAM"}]

    # orphan_data1 = [{'component_name': 'AP540P00', 'component_type': 'COPYBOOK'},
    #                 {'component_name': 'AP678P00', 'component_type': 'COBOL'},
    #                 {'component_name': 'AP678P00', 'component_type': 'PROC'}]
    #
    # xref_data1 = [
    #     {'component_name': 'AP540P00', 'component_type': 'COPYBOOK', "called_name": "Fetch1", "called_type": "COBOL"},
    #     {'component_name': 'AP541P00', 'component_type': 'COPYBOOK', "called_name": "S.P.LINK", "called_type": "File"},
    #     {'component_name': 'AP540P00', 'component_type': 'COBOL', "called_name": "ICEGENER", "called_type": "COBOL"},
    #     {'component_name': 'AP678P00', 'component_type': 'PROC', "called_name": "Fetch1", "called_type": "COPYBOOK"},
    #     {'component_name': 'AP678P00', 'component_type': 'COBOL', "called_name": "Fetch1", "called_type": "COBOL"},
    #     {'component_name': 'AP676P00', 'component_type': 'SYSIN', "called_name": "Fetch1", "called_type": "FILE"},
    #     {'component_name': 'AP679P00', 'component_type': 'SYSIN', "called_name": "RSPB0120", "called_type": "PROC"},
    #     {'component_name': 'AP677P00', 'component_type': 'PROC', "called_name": "SORT", "called_type": "PROGRAM"}]

    # orphan_data1 = [{'component_name': 'AP540P00', 'component_type': 'COBOL'},
    #                 {'component_name': 'AP541P00', 'component_type': 'COBOL'}]
    #
    # xref_data1 = [
    #     {'component_name': 'AP540P00', 'component_type': 'COBOL', "called_name": "Fetch1", "called_type": "COBOL"},
    #     {'component_name': 'AP541P00', 'component_type': 'COBOL', "called_name": "Fetch1", "called_type": "COBOL"},
    #     {'component_name': 'AP540P00', 'component_type': 'COBOL', "called_name": "Fetch", "called_type": "COBOL"},
    #     {'component_name': 'AP678P00', 'component_type': 'COBOL', "called_name": "Fetch1", "called_type": "COPYBOOK"},
    #     {'component_name': 'AP678P00', 'component_type': 'COBOL', "called_name": "Fetch1", "called_type": "COBOL"},
    #     {'component_name': 'AP676P00', 'component_type': 'COBOL', "called_name": "Fetch1", "called_type": "FILE"},
    #     {'component_name': 'AP679P00', 'component_type': 'COBOL', "called_name": "Fetch1", "called_type": "PROC"},
    #     {'component_name': 'AP677P00', 'component_type': 'COBOL', "called_name": "Fetch1", "called_type": "PROGRAM"}]

    # orphan_data1 = [{'component_name': 'AP540P00', 'component_type': 'COBOL'},
    #                 {'component_name': 'AP676P00', 'component_type': 'COBOL'},
    #                 {'component_name': 'AP541P00', 'component_type': 'COBOL'}]
    #
    # xref_data1 = [
    #     {'component_name': 'AP540P00', 'component_type': 'COBOL', "called_name": "Fetch1", "called_type": "COBOL"},
    #     {'component_name': 'AP541P00', 'component_type': 'COBOL', "called_name": "Fetch1", "called_type": "COBOL"},
    #     {'component_name': 'AP540P00', 'component_type': 'COBOL', "called_name": "Fetch", "called_type": "COBOL"},
    #     {'component_name': 'AP678P00', 'component_type': 'COBOL', "called_name": "Fetch1", "called_type": "COPYBOOK"},
    #     {'component_name': 'AP678P00', 'component_type': 'COBOL', "called_name": "Fetch1", "called_type": "COBOL"},
    #     {'component_name': 'AP676P00', 'component_type': 'COBOL', "called_name": "Fetch1", "called_type": "FILE"},
    #     {'component_name': 'AP679P00', 'component_type': 'COBOL', "called_name": "Fetch1", "called_type": "PROC"},
    #     {'component_name': 'AP677P00', 'component_type': 'COBOL', "called_name": "Fetch1", "called_type": "PROGRAM"}]

    """ find orphan data from db and storing it in orphan_data1[]   """
    orphan_data1 = []
    cursor = db.orphan_report.find({'type': {"$ne": "metadata"}}, {'_id': 0})
    for document in cursor:
        orphan_data1.append(document)
    #print("ORPHAN LIST", end='')
    #print(orphan_data1)


    """ find xref data from db and storing it in xref_data1[]"""
    xref_data1 = []
    # cursor1 = db.cross_reference_report.find({"$and":[{"type": {"$ne": "metadata"}},
    #     #                                                   {"called_type": {"$ne": "Utility"}}, {'_id': 0}]})
    cursor1 = db.cross_reference_report.find({"$and": [{"called_type": {"$ne": "Utility"}},
                                                       {"type": {"$ne": "metadata"}}]})

    for document in cursor1:
        xref_data1.append(document)
    #print("xref", len(xref_data1))

    """  finding matching datas from xref and orphan with called name and type """
    new_orphan = []
    for a in orphan_data1:
        for b in xref_data1:
            if a["component_name"] == b["component_name"] and a["component_type"] == b["component_type"]:
                new_orphan.append(b)
    # print("new_orphan", new_orphan)
    # print("new orphan", len(new_orphan))

    xr_list = []
    for o in xref_data1:
        flag = False
        for xr in orphan_data1:

            if o["component_name"] == xr["component_name"] and \
                    o["component_type"] == xr["component_type"]:
                flag = True
                break

        if not flag:
            xr_list.append(o)
    # print("xr_list", xr_list)
    # print("xr list", len(xr_list))

    drop_impact = []
    for i in new_orphan:
       # print("i", i)
        flag = False
        for y in xr_list:
           # print("y", y)

            if i["called_name"] == y["called_name"] and \
                    i["called_type"] == y["called_type"]:
                flag = True
                break

        if not flag:
            drop_impact.append(i)
    # print("xr_list", xr_list)
    # print("drop_impact", drop_impact)
    # print("drop_impact", len(drop_impact))

    extn = dict(RPG='RPG', CL='CL', COPYBOOK='cpy', SYSIN='sysin')
    drop_impact_final = []
    var = ""
    for drop in drop_impact:
        drop_impact_name=drop["called_name"]
        drop_impact_type=drop["called_type"]
        for ext in extn:
            #print(ext)
            if drop["component_type"] == ext:
                var = drop["component_name"]+"."+extn[ext]
                drop_dict = dict(drop_impact_name=drop_impact_name, drop_impact_type=drop_impact_type, orphan_component_name=var)
                drop_impact_final.append(drop_dict)
    #print("drop_impact_final", drop_impact_final)

    #di_without_duplicate=list(OrderedDict.fromkeys(drop_impact_final))
    setof = set()
    new_di_list = []
    for d in drop_impact_final:
        t = tuple(d.items())
        if t not in setof:
            setof.add(t)
            new_di_list.append(d)

    print(drop_impact_final)


    # drop_repeat=[]
    # for repeat in range(len(drop_impact_final)):
    #     print(drop_impact_final[repeat]["drop_impact_name"])
    #     if drop_impact_final[repeat]["drop_impact_name"] not in drop_impact_final[repeat+1]["drop_impact_name"] and :
    #         drop_repeat.append(drop_impact_final[repeat])

    drop_impact_temp = copy.deepcopy(new_di_list)
    #temp_dict={}

    final_di_list=[]
    for rep in new_di_list:
        temp_list = []
        print(rep["drop_impact_name"], rep["drop_impact_type"])
        for cpy in drop_impact_temp:
            print(cpy["drop_impact_name"], cpy["drop_impact_type"])
            if rep["drop_impact_name"] == cpy["drop_impact_name"] and rep["drop_impact_type"] == cpy["drop_impact_type"]:
                temp_list.append(cpy["orphan_component_name"])
                temp_dict = dict(drop_impact_name=cpy["drop_impact_name"],
                               drop_impact_type=cpy["drop_impact_type"], orphan_component_name=temp_list)
                final_di_list.append(temp_dict)

    print("final_di_list", str(final_di_list))

    meta_data = []
    for i in range(0, len(final_di_list)):
        if final_di_list[i] not in final_di_list[i + 1:]:
            meta_data.append(final_di_list[i])
    print("meta_data",meta_data)



    # keys = meta_data[0].keys()
    # with open('drop.csv', 'w') as output_file:
    #     dict_writer = csv.DictWriter(output_file, keys)
    #     dict_writer.writeheader()
    #     dict_writer.writerows(meta_data)
    #
    #     keys1 = xref_data1[0].keys()
    #     with open('xref3.csv', 'w') as output_file:
    #         dict_writer = csv.DictWriter(output_file, keys1)
    #         dict_writer.writeheader()
    #         dict_writer.writerows(xref_data1)
    #
    # keys2 = drop_impact_final[0].keys()
    # with open('drop_impact_final3.csv', 'w') as output_file:
    #     dict_writer = csv.DictWriter(output_file, keys2)
    #     dict_writer.writeheader()
    #     dict_writer.writerows(drop_impact_final)s

    db.drop_impact.insert_many(meta_data)
    print("Succes")

func1()