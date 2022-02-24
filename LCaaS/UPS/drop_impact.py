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
db = client['IMS']
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
@app.route('/api/v1/json', methods=['Get'])
def Diff():
    # list_1 = [
    #           #{'unique_id': '001', 'key1': 'AAA', 'key2': 'BBB', 'key3': 'EEE'},
    #           {'unique_id': '001', 'key1': 'AAA', 'key2': 'CCC', 'key3': 'FFF'},
    #           {'unique_id': '002', 'key1': 'AAA', 'key2': 'CCC', 'key3': 'FFF'}]
    #
    # list_2 = [{'unique_id': '001', 'key1': 'AAA', 'key2': 'CCC', 'key3': 'FFF'},
    #           {'unique_id': '002', 'key1': 'AAA', 'key2': 'CCC', 'key3': 'FFF'},
    #           {'unique_id': '003', 'key1': 'AAA', 'key2': 'BBB', 'key3': 'EEE'},
    #           {'unique_id': '004', 'key1': 'AAA', 'key2': 'BBB', 'key3': 'EEE'}]



    list_1=[{'CHARACTER_SET_NAME': 'big5', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'big5', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'dec8', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'dec8', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'cp850', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'cp850', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'hp8', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'hp8', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'koi8r', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'koi8r', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'latin1', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'latin1', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'latin1', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'latin1', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'latin1', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'latin1', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'latin1', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'latin2', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'latin2', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'latin2', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'latin2', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'swe7', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'swe7', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'ascii', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'ascii', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'ujis', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'ujis', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'sjis', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'sjis', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'hebrew', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'hebrew', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'tis620', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'euckr', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'euckr', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'koi8u', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'koi8u', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'gb2312', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'gb2312', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'greek', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'greek', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'cp1250', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'cp1250', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'cp1250', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'cp1250', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'gbk', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'gbk', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'latin5', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'latin5', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'armscii8', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'armscii8', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'utf8', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'utf8', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'utf8', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'ucs2', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'ucs2', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'ucs2', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'cp866', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'cp866', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'keybcs2', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'keybcs2', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'macce', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'macce', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'macroman', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'macroman', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'cp852', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'cp852', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'latin7', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'latin7', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'latin7', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'latin7', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'utf8mb4', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'utf8mb4', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'cp1251', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'cp1251', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'cp1251', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'cp1251', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'cp1251', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'utf16', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'utf16', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'utf16le', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'utf16le', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'cp1256', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'cp1256', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'cp1257', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'cp1257', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'cp1257', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'utf32', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'utf32', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'binary', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'geostd8', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'geostd8', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'cp932', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'cp932', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'eucjpms', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'eucjpms', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'gb18030', 'SORTLEN': 1}]


    list_2=[{'CHARACTER_SET_NAME': 'armscii8', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'armscii8', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'ascii', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'ascii', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'big5', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'big5', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'binary', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'cp1250', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'cp1250', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'cp1250', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'cp1250', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'cp1251', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'cp1251', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'cp1251', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'cp1251', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'cp1251', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'cp1256', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'cp1256', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'cp1257', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'cp1257', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'cp1257', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'cp850', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'cp850', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'cp852', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'cp852', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'cp866', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'cp866', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'cp932', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'cp932', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'dec8', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'dec8', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'eucjpms', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'eucjpms', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'euckr', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'euckr', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'gb18030', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'gb2312', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'gb2312', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'gbk', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'gbk', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'geostd8', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'geostd8', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'greek', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'greek', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'hebrew', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'hebrew', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'hp8', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'hp8', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'keybcs2', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'keybcs2', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'koi8r', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'koi8r', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'koi8u', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'koi8u', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'latin1', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'latin1', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'latin1', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'latin1', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'latin1', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'latin1', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'latin1', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'latin2', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'latin2', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'latin2', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'latin2', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'latin5', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'latin5', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'latin7', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'latin7', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'latin7', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'latin7', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'macce', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'macce', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'macroman', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'macroman', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'sjis', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'sjis', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'swe7', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'swe7', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'tis620', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'ucs2', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'ucs2', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'ucs2', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'ujis', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'ujis', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'utf16', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'utf16', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'utf16le', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'utf16le', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'utf32', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'utf32', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'utf8', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'utf8', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'utf8', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'utf8', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'utf8mb4', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'utf8mb4', 'SORTLEN': 1}, {'CHARACTER_SET_NAME': 'utf8mb4', 'SORTLEN': 1}]

    mainlist=[list_1,list_2]
    #print(mainlist[0])


    if len(mainlist[0]) == len(mainlist[1]) and all(x in mainlist[1] for x in mainlist[0]):
        print("PASS")
        return "PASSED"

    non_matching = []
    matching = []
    if len(mainlist[0]) != len(mainlist[1]):
        print("diff length scenario")
        for y in mainlist[0]:
            if y not in mainlist[1]:
                non_matching.append(y)
                # print("extra value", y)
            if y in mainlist[1]:
                # print("matched")
                matching.append(y)
        output=dict(non_matching=non_matching,matching=matching)
        print(output)
        return {"length": "Different","matching":matching,"non_matching":non_matching}


    if len(mainlist[0]) == len(mainlist[1]):
        print("same length scenario")
        for y in mainlist[0]:
            if y not in mainlist[1]:
                #print("matched")
                non_matching.append(y)
            if y in mainlist[1]:
                matching.append(y)
        output=dict(non_matching=non_matching,matching=matching)
        print(output)
        return {"length": "Same Length","matching":matching,"non_matching":non_matching}

        # print("non_matching",non_matching)
        # print("matching",matching)

@app.route('/api/v1/getDropImp', methods=['Get'])
def getDropImp():
    #cursor = db.drop_impact.find(drop)

    data_object = {}
    data_object['data'] = []
    try:
        cursor = db.drop_impact.find({'type': {"$ne": "metadata"}}, {'_id': 0})
        metadata = db.drop_impact.find_one({"type": "metadata"}, {'_id': 0})
        data_object['headers'] = metadata['headers']
        for document in cursor:
            data_object['data'].append(document)
    except Exception as e:
        print('')

    return data_object

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

    extn = dict(COBOL='cbl', PROC='proc', COPYBOOK='cpy', SYSIN='sysin')
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
    #     dict_writer.writerows(drop_impact_final)

    return jsonify(meta_data)

@app.route('/api/v1/insertDropImpact', methods=['Get'])
def insertDrop():
    drop=[
  {
    "drop_impact_name": "SC700PRM",
    "drop_impact_type": "COPYBOOK",
    "orphan_component_name": [
      "GL659P00.cbl"
    ]
  },
  {
    "drop_impact_name": "SC700LNK",
    "drop_impact_type": "COPYBOOK",
    "orphan_component_name": [
      "GL659P00.cbl"
    ]
  },
  {
    "drop_impact_name": "SC700M00",
    "drop_impact_type": "COBOL",
    "orphan_component_name": [
      "GL659P00.cbl"
    ]
  },
  {
    "drop_impact_name": "SC700ERR",
    "drop_impact_type": "COPYBOOK",
    "orphan_component_name": [
      "GL659P00.cbl"
    ]
  },
  {
    "drop_impact_name": "CBLTDLI",
    "drop_impact_type": "COBOL",
    "orphan_component_name": [
      "GL659P00.cbl"
    ]
  },
  {
    "drop_impact_name": "GL375EXT",
    "drop_impact_type": "COPYBOOK",
    "orphan_component_name": [
      "GL375P00.cbl"
    ]
  },
  {
    "drop_impact_name": "GL375MSK",
    "drop_impact_type": "COPYBOOK",
    "orphan_component_name": [
      "GL375P00.cbl"
    ]
  },
  {
    "drop_impact_name": "GLCTLCD",
    "drop_impact_type": "COPYBOOK",
    "orphan_component_name": [
      "GL375P00.cbl"
    ]
  },
  {
    "drop_impact_name": "CHCDUMP",
    "drop_impact_type": "COBOL",
    "orphan_component_name": [
      "AP540TPD.cpy",
      "GL375P00.cbl"
    ]
  },
  {
    "drop_impact_name": "DSNTIAR",
    "drop_impact_type": "COBOL",
    "orphan_component_name": [
      "AP678P00.cbl"
    ]
  },
  {
    "drop_impact_name": "FEFC101",
    "drop_impact_type": "COPYBOOK",
    "orphan_component_name": [
      "WR007P00.cbl"
    ]
  },
  {
    "drop_impact_name": "WR008D05",
    "drop_impact_type": "COPYBOOK",
    "orphan_component_name": [
      "WR010P00.cbl",
      "WR008P00.cbl",
      "WR009P00.cbl"
    ]
  },
  {
    "drop_impact_name": "WR009D10",
    "drop_impact_type": "COPYBOOK",
    "orphan_component_name": [
      "WR009P00.cbl"
    ]
  },
  {
    "drop_impact_name": "WR009D12",
    "drop_impact_type": "COPYBOOK",
    "orphan_component_name": [
      "WR009P00.cbl"
    ]
  },
  {
    "drop_impact_name": "WR009D15",
    "drop_impact_type": "COPYBOOK",
    "orphan_component_name": [
      "WR009P00.cbl"
    ]
  },
  {
    "drop_impact_name": "WR009D17",
    "drop_impact_type": "COPYBOOK",
    "orphan_component_name": [
      "WR009P00.cbl"
    ]
  },
  {
    "drop_impact_name": "WR009D20",
    "drop_impact_type": "COPYBOOK",
    "orphan_component_name": [
      "WR009P00.cbl"
    ]
  },
  {
    "drop_impact_name": "TSOSQLWS",
    "drop_impact_type": "COPYBOOK",
    "orphan_component_name": [
      "WR010P00.cbl",
      "WR006P00.cbl",
      "WR007P00.cbl",
      "WR008P00.cbl",
      "WR009P00.cbl"
    ]
  },
  {
    "drop_impact_name": "TSOSQLLG",
    "drop_impact_type": "COPYBOOK",
    "orphan_component_name": [
      "WR010P00.cbl",
      "WR006P00.cbl",
      "WR007P00.cbl",
      "WR008P00.cbl",
      "WR009P00.cbl"
    ]
  },
  {
    "drop_impact_name": "SAAW017",
    "drop_impact_type": "COPYBOOK",
    "orphan_component_name": [
      "SAMPLE1.cbl",
      "CBLDB2.cbl"
    ]
  },
  {
    "drop_impact_name": "SAAW016",
    "drop_impact_type": "COBOL",
    "orphan_component_name": [
      "SAMPLE1.cbl",
      "CBLDB2.cbl"
    ]
  },
  {
    "drop_impact_name": "SAAW017",
    "drop_impact_type": "COBOL",
    "orphan_component_name": [
      "SAMPLE1.cbl",
      "CBLDB2.cbl"
    ]
  }
]

    cursor = db.drop_impact.insert_many(drop)
    return "data inserted"

@app.errorhandler(404)
def page_not_found(e):
#    return jsonify({"status":"failure","reason":"This route does not exist"})
    return "This route does not exists"

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0',port=5004)
