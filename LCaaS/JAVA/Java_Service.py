# after adding phase 3 changes
from flask import Flask, request, jsonify
from pymongo import MongoClient
from collections import ChainMap
import json
import pytz
import datetime
import re
import traceback
from flask_cors import CORS
import timeit
import sys
import copy
import operator
from openpyxl import Workbook, load_workbook
import pandas as pd
# import config

para_name_list = []

# import time
# from jinja2 import Environment, FileSystemLoader
# import pythoncom
# import os,win32com
# import win32com.client as win32
# import csv
# from docxtpl import DocxTemplate
# from docx imporCompList
client = MongoClient('localhost', 27017)
db = client['java']

componentcollection = "componenttype"
col2 = client['java'][componentcollection]
cursor = list(col2.find({'type': {"$ne": "metadata"}},
                        {"component_name": 1, "component_type": 1, "application": 1, "_id": 0}))

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


def Remove(duplicate):
    final_list = []
    for list_iter in duplicate:
        if list_iter not in final_list:
            final_list.append(list_iter)
    return final_list


def jsonVerify(input_data):
    try:
        input_data = json.loads(input_data.decode('utf-8'))
        return True, input_data
    except Exception as e:
        print('Error :' + str(e))
        return False, jsonify({"status": "failure", "reason": "INVALID JSON format string found in response body"})


@app.route('/api/v1/startAnalysis', methods=['POST'])
def startAnalysis():
    data = json.loads(request.data)
    print(request.data)
    return jsonify({"you have sent the data ": data})


@app.route('/api/v1/procedureAppList', methods=['GET'])
def procedureAppList():
    appln_name_set = set()
    try:
        list_of_programs = db.master_inventory_report.distinct("application")

        for appln in list_of_programs:
            if appln != None:
                appln_name_set.add(appln)
        return jsonify({"application_list": sorted(list(appln_name_set))})
    except Exception as e:
        print('Error:', str(e))
        return jsonify({"status": "failure", "reason": "Error: " + str(e)})


@app.route('/api/v1/procedureFlowCompList', methods=['GET'])
def procedureFlowCompList():
    option = request.args.get('option')
    flag = request.args.get('flag')
    comp_name_set = set()
    # flag="ppf"
    if flag=="ppf":
        component_list = list(db.procedure_flow_table.find({'type': {"$ne": "metadata"}},
                                                              {'_id': 0, "component_name": 1}))
        component_list = [item['component_name'] for item in component_list]
    elif flag=="bre":
        component_list = list(db.rule_report.find({'type': {"$ne": "metadata"}},
                                                              {'_id': 0, "pgm_name": 1}))
        component_list = [item['pgm_name'] for item in component_list]

    if option is not None:
        application_name = option
        try:
            response = db.master_inventory_report.find({"application": application_name})
            # , "component_type":{"$in":["SERVLET","JAVA_CLASS","INTERFACE","DATA_ACCESS_OBJECT"]}
            # ,"JAVA_CLASS","INTERFACE","DATA_ACCESS_OBJECT"
            if response is None:
                return jsonify({"response": "No such key"})
            else:
                for appln in response:

                    if appln["component_name"] in component_list:
                        comp_name_set.add(appln["component_name"])
                        print(comp_name_set, application_name)
                return jsonify({"component_list": sorted(list(comp_name_set)), "application_name": application_name})
        except Exception as e:
            print("Error", str(e))
            return jsonify({"status": "failure", "reason": "Error: " + str(e)})

@app.route('/api/v1/getEventList', methods=["GET"])
def geteventlist():
    option = request.args.get('option')
    try:
        event_list = []
        response = db.procedure_flow_table.find({"component_name": option})
        for data in response:
            event_list.append(data["event_name"])
        return jsonify({"eventList": event_list})
    except Exception as e:
        print(e)


@app.route('/api/v1/procFlowChart', methods=['GET'])
def procFlowChart():
    para_name = request.args.get('para_name')
    component_name = request.args.get('component_name')
    print(component_name)
    try:
        flowchart_metadata = db.para_flowchart_data.find_one(
            {"$and": [{"component_name": component_name}, {"para_name": para_name}]}, {'_id': 0})

        if flowchart_metadata is None:

            return jsonify({"status": "unavailable"})
        else:
            flowchart_metadata['status'] = "available"
            return jsonify(flowchart_metadata)

    except Exception as e:
        return jsonify({"error": str(e)})


@app.route('/api/v1/procFlowChart', methods=['POST'])
def procFlowChartPOST():
    para_name = request.args.get('para_name')
    component_name = request.args.get('component_name')
    para_name_list.append(para_name)

    try:
        if para_name.__contains__("(") and para_name.__contains__("JAVA_SERVER_PAGE"):
            flowchart_metadata = None

        elif para_name.__contains__("["):
            flowchart_metadata = db.para_flowchart_data.find_one(
                {"$and": [{"component_name": para_name.split("[")[1][:-1]},
                          {"para_name": para_name.split("[")[0].strip()}]}, {'_id': 0})
        else:
            flowchart_metadata = db.para_flowchart_data.find_one({"$and": [{"component_name": component_name},
                                                                           {"para_name": para_name}]}, {'_id': 0})

        if flowchart_metadata is None:
            print("sunld not happen ", flowchart_metadata)
            return jsonify({"status": "unavailable"})
        else:
            flowchart_metadata['status'] = "available"
            print("this shuld happen", flowchart_metadata)
            return jsonify(flowchart_metadata)

    except Exception as e:
        return jsonify({"error": str(e)})


@app.route('/api/v1/componentCode', methods=['GET'])
def getCode():
    component_name = request.args.get('component_name')
    component_type = request.args.get('component_type')
    component_line = request.args.get('line')

    if para_name_list != []:
        para_name = para_name_list.pop()
    else:
        para_name = ''

    """
    Change Sepecific to VB instance to add identify the component name and redirection to external component on click 
    """

    # if para_name.__contains__("("):
    #     component_name = para_name.split("(")[1].split(")")[0]
    # else:
    #     component_name = component_name

    if not re.match('\S+\.\S+', component_name.strip()):
        # Component does not have extension,
        master_component_types = {'VB_FORM': 'frm', 'VB_CLASS': 'cls', 'USER_CONTROL': 'ctl', 'REPORT': 'Dsr',
                                  'MODULE': 'bas'}  # This line to be copied from the script
        # Search for component extension via lookup and
        if component_type in master_component_types:
            component_name = component_name.strip() + '.' + master_component_types[component_type]

    start = timeit.default_timer()
    print(component_name)
    cursy = db.codebase.find_one({'component_name': component_name},
                                 {"_id": 0})
    end = timeit.default_timer()
    if component_line != None:
        replaced_lines = ""
        for k in cursy["codeString"].split("<br>"):
            if k.__contains__(component_line):
                print("here")
                replaced_lines = replaced_lines + '<span id=ExpCanvasScroll>' + component_line + '<br>' + "</span>"
            else:
                replaced_lines = replaced_lines + k + "<br>"
        cursy["codeString"] = replaced_lines
    cursy['completed_in'] = end - start
    return jsonify(cursy)


@app.route('/api/v1/generate/orphanReport', methods=['GET'])
def generateOrphanReport():
    master_inv_list = db.master_inventory_report.distinct("component_name")
    cross_reference = db.cross_reference_report.distinct("called_name")
    orphan_list = set(master_inv_list) - set(cross_reference)
    missing_list = set(cross_reference) - set(master_inv_list)
    print('Orphan list:', orphan_list, 'Missing list:', missing_list)

    PARAMS = {"$or": []}
    for ite in orphan_list:
        PARAMS['$or'].append({"component_name": ite})
    cursor = db.master_inventory_report.find(PARAMS, {'_id': 0})
    for row in cursor:
        print(row)

    return jsonify({"elements": db.master_inventory_report.distinct("called_name")})


@app.route('/api/v1/cyclomaticComplexity', methods=['GET', 'POST'])
def cycComplex():
    application = []
    orphan_data1 = []
    # cursor = db.master_inventory_report.find({"$or":[{"component_type": "VB_FORM"},
    #                                                  {"component_type": "VB_CLASS"},
    #                                                  {"component_type": "USER_CONTROL"},
    #                                                  {"component_type": "REPORT"},
    #                                                  {"component_type": "MODULE"}]})
    cursor = db.master_inventory_report.find({'type': {"$ne": "metadata"}})

    for document in cursor:
        orphan_data1.append(document)
    for items in orphan_data1:
        application.append(items['application'])
    print(application)

    meta_data = []
    for i in range(0, len(application)):
        if application[i] not in application[i + 1:]:
            meta_data.append(application[i])
    print("meta_data", meta_data)

    data = {}
    data_list = []
    final = {}
    for i in meta_data:
        count = 0
        for j in orphan_data1:
            if i == j['application']:
                # print
                # print("cyck",j['cyclomatic_complexity'])
                if (j['cyclomatic_complexity'] != ''):
                    count = count + int(j['cyclomatic_complexity'])
                # print('count',count)
        data[i] = count
        data_list.append({"application_name": i, "cyclomatic_complexity": count})
    a = sorted(data_list, key=operator.itemgetter('cyclomatic_complexity'))
    pb = copy.deepcopy(reversed(a))

    mylist = []
    for all in pb:
        mylist.append(all)
    # print('abcd',mylist)
    # print(pb)
    final["cyclomatic_complexity"] = mylist
    # print('final', final)

    # print('data',data)

    sorted_d = {k: v for k, v in sorted(final.items(), key=lambda item: item[0])}
    print('sorted_d', sorted_d)

    todict = {}

    first10pairs = {k: sorted_d[k] for k in sorted(sorted_d.keys())[:10]}
    print(first10pairs)

    return jsonify(first10pairs)


@app.route('/api/v1/inboundOutbound', methods=['GET', 'POST'])
def inbboundOutbound():
    orphan_data1 = []
    calling_name = []
    cursor = db.cross_reference_report.find({"type": {"$ne": "metadata"}}, {"_id": 0})
    for document in cursor:
        orphan_data1.append(document)

    for inb in orphan_data1:
        try:
            # print(inb)
            calling_name.append(inb['calling_app_name'])
        except KeyError as e:
            pass

    meta_data = []
    for i in range(0, len(calling_name)):
        if calling_name[i] not in calling_name[i + 1:]:
            meta_data.append(calling_name[i])
    # print("meta_data", meta_data)

    called_name = []
    for inb in orphan_data1:
        try:
            # print(inb)
            called_name.append(inb['called_app_name'])
        except Exception as e:
            # inb['called_app_name'] = ""
            pass
    # print((called_name))

    meta_data1 = []
    for i in range(0, len(called_name)):
        if called_name[i] not in called_name[i + 1:]:
            meta_data1.append(called_name[i])

    inbound_dict = {}
    for a in meta_data:
        inbound_list = []
        for b in orphan_data1:
            try:
                if a == b['calling_app_name']:
                    if b['called_app_name'] not in inbound_list:
                        inbound_list.append(b['called_app_name'])
            except Exception as e:
                print("")
        # print('list', inbound_list)
        inbound_dict[a] = len(inbound_list)
    # print('inbond', inbound_dict)
    sorted_d = {k: v for k, v in sorted(inbound_dict.items(), key=lambda item: item[0])}
    first10pairs_inbound = {k: sorted_d[k] for k in sorted(sorted_d.keys())[:10] if (k != '')}
    ordered_dict_inbound = dict(sorted(first10pairs_inbound.items(), key=operator.itemgetter(1), reverse=True))

    outbound_dict = {}
    for p in meta_data1:
        outbound_list = []
        for q in orphan_data1:

            try:
                if p == q['called_app_name']:
                    # print('a', q['called_app_name'])
                    if q['calling_app_name'] not in outbound_list:
                        outbound_list.append(q['calling_app_name'])
            except Exception as e:
                print("")
        # print('list', outbound_list)
        outbound_dict[p] = len(outbound_list)
    # print('outbound', outbound_dict)
    sorted_data = {key1: value1 for key1, value1 in sorted(outbound_dict.items(), key=lambda item: item[0])}
    first10pairs_outbound = {key1: sorted_data[key1] for key1 in sorted(sorted_data.keys())[:10] if key1 != ''}
    ordered_dict_outbound = dict(sorted(first10pairs_outbound.items(), key=operator.itemgetter(1), reverse=True))
    whole_key = []
    for k in ordered_dict_inbound.keys():
        whole_key.append(k)
    for k in ordered_dict_outbound.keys():
        whole_key.append(k)
    in_key = list(ordered_dict_inbound.keys())
    out_key = list(ordered_dict_outbound.keys())
    for key in whole_key:
        if (key not in in_key):
            # print(key)
            ordered_dict_inbound[key] = 0
        if (key not in out_key):
            ordered_dict_outbound[key] = 0

    in_data = []
    out_data = []
    dic = {}
    dic1 = {}
    for k, k1 in zip(sorted(ordered_dict_outbound.keys()), sorted(ordered_dict_inbound.keys())):
        dic[k1] = ordered_dict_inbound[k1]
        dic1[k] = ordered_dict_outbound[k]

    in_data.append(dic)
    out_data.append(dic1)

    return jsonify({"inboundOutbound": {"inbound": in_data, "outbound": out_data}})


@app.route('/api/v1/dashboard', methods=['GET'])
def dashboard():
    response_var = {"dash_no_of_components": 0,
                    "dash_total_loc": 0, "dash_dead_lines_count": 0, "dash_total_number_of_tables": 0,
                    "dash_number_of_orphan_components": 0,
                    "dash_number_of_missing_components": 0}

    try:
        # Calculating total number of components
        response_var['dash_no_of_components'] = db.master_inventory_report.count_documents(
            {'type': {"$ne": "metadata"}})

        total_loc = db.master_inventory_report.aggregate(
            [{"$match": {}}, {"$group": {"_id": "null", "count": {"$sum": "$Loc"}}}])
        for ite in total_loc:
            response_var['dash_total_loc'] = ite['count']

        deadline_count = db.master_inventory_report.aggregate(
            [{"$match": {}}, {"$group": {"_id": "null", "count": {"$sum": "$no_of_dead_lines"}}}])
        for ite in deadline_count:
            response_var['dash_dead_lines_count'] = ite['count']

        # Fetching all distinct tables from teh CRUD_REPORT
        response_var['dash_total_number_of_tables'] = len(db.crud_report.distinct("Table"))

        # Calculating total number of orphan components
        response_var['dash_number_of_orphan_components'] = db.orphan_report.count_documents(
            {'type': {"$ne": "metadata"}})

        # Calculating total number of  missing components

        response_var['dash_number_of_missing_components'] = db.missing_components_report.count_documents(
            {'type': {"$ne": "metadata"}})

        return jsonify(response_var)

    except Exception as e:
        return jsonify({"status": "failure", "reason": "Error: " + str(e)})


@app.route('/api/v1/datamodel', methods=['GET'])
def dataModel():
    # @app.route('/api/v1/masterInventory', methods=['GET'])
    # def masterInventory():
    data_object = {}
    data_object['data'] = []
    try:
        cursor = db.table.find({'type': {"$ne": "metadata"}}, {'_id': 0})
        metadata = db.table.find_one({"type": "metadata"}, {'_id': 0})
        data_object['headers'] = metadata['headers']
        for document in cursor:
            data_object['data'].append(document)
    except Exception as e:
        print('')
    return jsonify(data_object)


@app.route('/api/v1/crossReferenceApplication', methods=['GET'])
def crossReference():
    data_object = {}
    data_object['data'] = []

    data_object['displayed_count'] = 0
    try:
        search_filter = request.args.get('searchFilter')
        override_filter = request.args.get('overrideFilter')
        appname = request.args.get('option')
        if appname == "All":
            # Fetch the total record count
            data_object['total_record_count'] = db.cross_reference_report.count_documents({}) - 1

            # Filter override to download export entire dump to CSV/Excel
            if override_filter == 'yes':
                # Query all cross reference data
                cursor = db.cross_reference_report.find({'type': {"$ne": "metadata"}}, {'_id': 0})
                # Query to fetch header details
                metadata = db.cross_reference_report.find_one({"type": "metadata"}, {'_id': 0})
                # Hotfix to not diplay the file name
                data_object['headers'] = metadata['headers']
                # Pandas code to convert cursor to a dict
                dfDataset = pd.DataFrame.from_records(cursor)
                resultdf = dfDataset[dfDataset.apply(lambda x: x.str.contains(search_filter, na=False)).any(axis=1)]
                data_object['data'] = resultdf.fillna("").to_dict('records')
                data_object['displayed_count'] = data_object['total_record_count']
                return jsonify(data_object)
            else:

                if search_filter:
                    # Query all cross reference data
                    cursor = db.cross_reference_report.find({'type': {"$ne": "metadata"}}, {'_id': 0})
                    # Query to fetch header details
                    metadata = db.cross_reference_report.find_one({"type": "metadata"}, {'_id': 0})
                    data_object['headers'] = metadata['headers']
                    dfDataset = pd.DataFrame.from_records(cursor)
                    resultdf = dfDataset[dfDataset.apply(lambda x: x.str.contains(search_filter, na=False)).any(axis=1)]
                    # #print('Result count', resultdf['component_name'].count())
                    data_object['displayed_count'] = int(resultdf['component_name'].count())
                    data_object['data'] = resultdf.fillna("").to_dict('records')
                    return jsonify(data_object)

                else:
                    # If there is no filter criteria, limit to 1000 records
                    # Query all cross reference data
                    cursor = db.cross_reference_report.find({'type': {"$ne": "metadata"}}, {'_id': 0}).limit(
                        CROSS_REFERENCE_LIMIT)
                    # Query to fetch header details
                    metadata = db.cross_reference_report.find_one({"type": "metadata"}, {'_id': 0})
                    data_object['headers'] = metadata['headers']

                    # Pandas code for cursor to dictionary convertion
                    dfDataset = pd.DataFrame.from_records(cursor)
                    data_object['displayed_count'] = data_object['total_record_count']
                    data_object['data'] = dfDataset.fillna("").to_dict('records')
                    return jsonify(data_object)

        else:
            # Fetch the total record count
            data_object['total_record_count'] = db.cross_reference_report.count_documents({}) - 1

            # Filter override to download export entire dump to CSV/Excel
            if override_filter == 'yes':
                # Query all cross reference data
                cursor = db.cross_reference_report.find({"calling_app_name": appname}, {'_id': 0})
                # Query to fetch header details
                metadata = db.cross_reference_report.find_one({"type": "metadata"}, {'_id': 0})
                # Hotfix to not diplay the file name
                data_object['headers'] = metadata['headers']
                # Pandas code to convert cursor to a dict
                dfDataset = pd.DataFrame.from_records(cursor)
                resultdf = dfDataset[dfDataset.apply(lambda x: x.str.contains(search_filter, na=False)).any(axis=1)]
                data_object['data'] = resultdf.fillna("").to_dict('records')
                data_object['displayed_count'] = data_object['total_record_count']
                return jsonify(data_object)
            else:

                if search_filter:
                    # Query all cross reference data
                    cursor = db.cross_reference_report.find({"calling_app_name": appname}, {'_id': 0})
                    # Query to fetch header details
                    metadata = db.cross_reference_report.find_one({"type": "metadata"}, {'_id': 0})
                    data_object['headers'] = metadata['headers']
                    dfDataset = pd.DataFrame.from_records(cursor)
                    resultdf = dfDataset[dfDataset.apply(lambda x: x.str.contains(search_filter, na=False)).any(axis=1)]
                    # #print('Result count', resultdf['component_name'].count())
                    data_object['displayed_count'] = int(resultdf['component_name'].count())
                    data_object['data'] = resultdf.fillna("").to_dict('records')
                    return jsonify(data_object)

                else:
                    # If there is no filter criteria, limit to 1000 records
                    # Query all cross reference data
                    cursor = db.cross_reference_report.find({"calling_app_name": appname}, {'_id': 0}).limit(
                        CROSS_REFERENCE_LIMIT)
                    # Query to fetch header details
                    metadata = db.cross_reference_report.find_one({"type": "metadata"}, {'_id': 0})
                    data_object['headers'] = metadata['headers']

                    # Pandas code for cursor to dictionary convertion
                    dfDataset = pd.DataFrame.from_records(cursor)
                    data_object['displayed_count'] = db.cross_reference_report.find(
                        {"calling_app_name": appname}).count()
                    data_object['data'] = dfDataset.fillna("").to_dict('records')
                    return jsonify(data_object)




    except Exception as e:
        # print('Error: ' + str(e))
        # print('Error on line {}'.format(sys.exc_info()[-1].tb_lineno))
        return 'FAIL' + str(e)


@app.route('/api/v1/sumvarImpact', methods=['GET'])
def sumvarImpact():
    data_object = {}
    data_object['data'] = []

    data_object1 = {}
    data_object1['displayed_count'] = []
    data_object1["sumval_list"] = []
    data_object1['data'] = []
    data_object1['headers'] = ["component_name", "component_type", "count"]
    pgm_name_list = []
    pgm_name_list = []
    my_dict = []
    sum_value = 0
    temp_json = {
        "component_name": "",
        "component_type": "",
        "count": ""
    }

    data_object['displayed_count'] = 0
    try:
        search_filter = request.args.get('searchFilter')

        data_object['total_record_count'] = db.varimpactcodebase.count_documents({}) - 1
        data_object1['total_record_count'] = data_object['total_record_count']

        if search_filter:
            cursor = db.varimpactcodebase.find({'type': {"$ne": "metadata"}}, {'_id': 0})
            # Query to fetch header details
            metadata = db.varimpactcodebase.find_one({"type": "metadata"}, {'_id': 0})
            data_object['headers'] = metadata['headers']
            dfDataset = pd.DataFrame.from_records(cursor)
            resultdf = dfDataset[dfDataset.apply(lambda x: x.str.contains(search_filter, case=False)).any(axis=1)]
            # print('Result count', resultdf['component_name'].count())
            # with pd.option_context('display.max_rows', None, 'display.max_columns',
            #                        None):  # more options can be specified also
            #     print(resultdf)
            # print(resultdf)
            data_object['displayed_count'] = int(resultdf['component_name'].count())

            data_object['data'] = resultdf.fillna("").to_dict('records')

            for i in data_object['data']:
                pgm_name_list.append(i["component_name"])
            my_dict = {i: pgm_name_list.count(i) for i in pgm_name_list}

            for k, v in my_dict.items():
                # temp_comp= []
                temp_json['component_name'] = k
                temp_json['count'] = v
                # temp_comp = temp_json['component_name'].split(".")
                temp_json['component_type'] = \
                [item["component_type"] for item in cursor if item["component_name"] == k][0]

                # if temp_comp[1].upper() == "CBL":
                #     temp_json['component_type'] = "Cobol"

                # if temp_comp[1].upper() == "JCL":
                #     temp_json['component_type'] = "JCL"

                # if temp_comp[1].upper() == "CPY":
                #     temp_json['component_type'] = "COPYBOOK"

                # if temp_comp[1].upper() == "PROC":
                #     temp_json['component_type'] = "PROC"

                # if temp_comp[1].upper() == "SYSIN":
                #     temp_json['component_type'] = "SYSIN"

                # if temp_comp[1].upper() == "FRM":
                #     temp_json['component_type'] = "VB_FORM"
                # if temp_comp[1].upper() == "CLS":
                #     temp_json['component_type'] = "VB_CLASS"
                # if temp_comp[1].upper() == "CTL":
                #     temp_json['component_type'] = "USER_CONTROL"
                # if temp_comp[1].upper() == "DSR":
                #     temp_json['component_type'] = "REPORT"
                # if temp_comp[1].upper() == "BAS":
                #     temp_json['component_type'] = "MODULE"

                data_object1["data"].append(copy.deepcopy(temp_json))
                data_object1["sumval_list"].append(v)

            data_object1['displayed_count'] = sum(data_object1["sumval_list"])
            # print(data_object1)
            return jsonify(data_object1)



    except Exception as e:
        print('Error: ' + str(e))
        print('Error on line {}'.format(sys.exc_info()[-1].tb_lineno))
        return 'FAIL' + str(e)


@app.route('/api/v1/varImpact', methods=['GET'])
def varImpact():
    data_object = {}
    data_object['data'] = []

    data_object['displayed_count'] = 0
    try:
        search_filter = request.args.get('searchFilter')
        override_filter = request.args.get('overrideFilter')
        exact_match_filter = request.args.get('exactmatchFilter')

        print(search_filter)
        print(override_filter)

        # Fetch the total record count
        data_object['total_record_count'] = db.varimpactcodebase.count_documents({}) - 1

        if override_filter == 'yes':
            # Query all cross reference data
            cursor = db.varimpactcodebase.find({"sourcestatements": {'$regex': search_filter}}, {'_id': 0})
            # Query to fetch header details
            for i in cursor:
                data_object['data'].append(i)
            metadata = db.varimpactcodebase.find_one({"type": "metadata"}, {'_id': 0})
            data_object['headers'] = metadata['headers']

            # Pandas code for cursor to dictionary convertion
            # dfDataset = pd.DataFrame.from_records(cursor)
            data_object['displayed_count'] = len(data_object['data'])
            # data_object['data'] = dfDataset.fillna("").to_dict('records')
            # print(data_object)
            return jsonify(data_object)
        else:

            if search_filter:

                if exact_match_filter == "yes":
                    cursor = db.varimpactcodebase.find({"sourcestatements": {'$regex': " " + search_filter + " "}},
                                                       {'_id': 0})

                    for i in cursor:
                        data_object['data'].append(i)
                    metadata = db.varimpactcodebase.find_one({"type": "metadata"}, {'_id': 0})
                    data_object['headers'] = metadata['headers']

                    # Pandas code for cursor to dictionary convertion
                    # dfDataset = pd.DataFrame.from_records(cursor)
                    data_object['displayed_count'] = len(data_object['data'])
                    # data_object['data'] = dfDataset.fillna("").to_dict('records')
                    # print(data_object)
                    return jsonify(data_object)
                else:

                    # Query all cross reference data
                    cursor = db.varimpactcodebase.find({"sourcestatements": {'$regex': search_filter}}, {'_id': 0})
                    for i in cursor:
                        data_object['data'].append(i)
                    metadata = db.varimpactcodebase.find_one({"type": "metadata"}, {'_id': 0})
                    data_object['headers'] = metadata['headers']

                    # Pandas code for cursor to dictionary convertion
                    # dfDataset = pd.DataFrame.from_records(cursor)
                    data_object['displayed_count'] = len(data_object['data'])
                    # data_object['data'] = dfDataset.fillna("").to_dict('records')
                    # print(data_object)
                    return jsonify(data_object)

            else:
                # If there is no filter criteria, limit to 1000 records
                # Query all cross reference data
                cursor = db.varimpactcodebase.find({"sourcestatements": {'$regex': search_filter}}, {'_id': 0}).limit(
                    CROSS_REFERENCE_LIMIT)
                # Query to fetch header details
                for i in cursor:
                    data_object['data'].append(i)
                metadata = db.varimpactcodebase.find_one({"type": "metadata"}, {'_id': 0})
                data_object['headers'] = metadata['headers']

                # Pandas code for cursor to dictionary convertion
                # dfDataset = pd.DataFrame.from_records(cursor)
                data_object['displayed_count'] = len(data_object['data'])
                # data_object['data'] = dfDataset.fillna("").to_dict('records')
                # print(data_object)
                return jsonify(data_object)

    except Exception as e:
        print('Error: ' + str(e))
        print('Error on line {}'.format(sys.exc_info()[-1].tb_lineno))
        return 'FAIL' + str(e)


@app.route('/api/v1/CRUD', methods=['GET'])
def CRUD():
    data_object = {}
    data_object['data'] = []
    appname = request.args.get('option')
    try:
        if appname == "All":
            cursor = db.crud_report.find({'type': {"$ne": "metadata"}}, {'_id': 0})
            metadata = db.crud_report.find_one({"type": "metadata"}, {'_id': 0})
            data_object['headers'] = metadata['headers']
            for document in cursor:
                data_object['data'].append(document)

        else:
            cursor = db.crud_report.find({"calling_app_name": appname}, {'_id': 0})
            metadata = db.crud_report.find_one({"type": "metadata"}, {'_id': 0})
            data_object['headers'] = metadata['headers']
            for document in cursor:
                data_object['data'].append(document)
        print(data_object)
    except Exception as e:
        print(e)
    return jsonify(data_object)


@app.route('/api/v1/update/crossReference/JCL', methods=['POST'])
def updateCrossReferenceJCL():
    # get data from POST request body
    data = request.data

    # JSON document for db upload
    db_data = {}
    # JCL Report headers extracted from the 'data' field
    x_jcl_report_header_list = []

    # check if the text is json
    JsonVerified, verification_payload = jsonVerify(data)
    if JsonVerified:
        db_data = verification_payload
    else:
        return verification_payload

    # Must have a key "data"
    try:

        keys = list(db_data.keys())
        print('parent keys', keys)

        if 'data' in keys:
            # fetching headers
            x_jcl_report_header_list = db_data['headers']
            print('JCL Report header list', x_jcl_report_header_list)
            # Adding header field to db_data
            db_data['headers'] = x_jcl_report_header_list

            if len(db_data['data']) == 0:
                return jsonify({"status": "failure", "reason": "data field is empty"})
            else:
                # Delete all COBOl associated records in the table
                previousDeleted = False
                try:
                    if db.cross_reference_report.delete_many(
                            {"$or": [{"component_type": "JCL"}, {"component_type": "SYSIN"}]}).acknowledged:
                        print('Deleted all the JCL and SYSIN components from the previous x-reference report')
                        previousDeleted = True
                    else:
                        print('Something went wrong')
                        return jsonify({"status": "failed",
                                        "reason": "unable to delete from database. Please check in with your Administrator"})
                except Exception as e:
                    return jsonify({"status": "failed", "reason": str(e)})

                # Update the database with the content from HTTP request body

                if previousDeleted:

                    try:

                        db.cross_reference_report.insert_many(db_data['data'])
                        # updating the timestamp based on which report is called
                        current_time = datetime.datetime.now(tz=tz).strftime("%A, %d. %B %Y %I:%M%p")
                        # Setting the time so that we know when each of the JCL and COBOLs were run

                        # db.cross_reference_report.insert_one({"type":"metadata", "JCL":{"last_updated_on":ct},"COBOL":{"last_updated_on":ct}})

                        if db.cross_reference_report.count_documents({"type": "metadata"}) > 0:
                            print('meta happen o naw', db.cross_reference_report.update_one({"type": "metadata"},
                                                                                            {"$set": {
                                                                                                "JCL.last_updated_on": current_time,
                                                                                                "JCL.time_zone": time_zone,
                                                                                                "headers": db_data[
                                                                                                    'headers']}},
                                                                                            upsert=True).acknowledged)
                        else:
                            db.cross_reference_report.insert_one(
                                {"type": "metadata", "JCL": {"last_updated_on": current_time, "time_zone": time_zone}})

                        print(current_time)

                        return jsonify({"status": "success", "reason": "Successfully inserted data and "})
                    except Exception as e:
                        print('Error' + str(e))
                        return jsonify({"status": "failed", "reason": str(e)})

    except Exception as e:
        print('Error: ' + str(e))
        print('Error on line {}'.format(sys.exc_info()[-1].tb_lineno))
        return jsonify({"status": "failure", "reason": "Response json not in the required format"})


@app.route('/api/v1/update/crossReference/COBOL', methods=['POST'])
def updateCrossReferenceCOBOL():
    # get data from POST request body
    data = request.data

    # JSON document for db upload
    db_data = {}
    # COBOL Report headers extracted from the 'data' field
    x_COBOL_report_header_list = []

    # check if the text is json
    JsonVerified, verification_payload = jsonVerify(data)
    if JsonVerified:
        db_data = verification_payload
    else:
        return verification_payload

    # Must have a key "data"
    try:
        keys = list(db_data.keys())
        print('parent keys', keys)

        if 'data' in keys:
            # fetching headers
            x_COBOL_report_header_list = db_data['headers']
            print('COBOL Report header list', x_COBOL_report_header_list)
            # Adding header field to db_data
            db_data['headers'] = x_COBOL_report_header_list

            if len(db_data['data']) == 0:
                return jsonify({"status": "failure", "reason": "data field is empty"})
            else:
                # Delete all COBOl associated records in the table
                previousDeleted = False
                try:
                    if db.cross_reference_report.delete_many(
                            {"$or": [{"component_type": "VB_FORM"}]}).acknowledged:
                        print('Deleted all the COBOL components from the x-reference report')
                        previousDeleted = True
                    else:
                        print('Something went wrong')
                        return jsonify({"status": "failed",
                                        "reason": "unable to delete from database. Please check in with your Administrator"})
                except Exception as e:
                    return jsonify({"status": "failed", "reason": str(e)})

                # Update the database with the content from HTTP request body

                if previousDeleted:

                    try:

                        db.cross_reference_report.insert_many(db_data['data'])
                        # updating the timestamp based on which report is called
                        current_time = datetime.datetime.now(tz=tz).strftime("%A, %d. %B %Y %I:%M%p")
                        # Setting the time so that we know when each of the JCL and COBOLs were run

                        # db.cross_reference_report.insert_one({"type":"metadata", "JCL":{"last_updated_on":ct},"COBOL":{"last_updated_on":ct}})

                        if db.cross_reference_report.count_documents({"type": "metadata"}) > 0:
                            print('meta happen o naw', db.cross_reference_report.update_one({"type": "metadata"},
                                                                                            {"$set": {
                                                                                                "COBOL.last_updated_on": current_time,
                                                                                                "COBOL.time_zone": time_zone,
                                                                                                "headers": x_COBOL_report_header_list
                                                                                            }},
                                                                                            upsert=True).acknowledged)
                        else:
                            db.cross_reference_report.insert_one(
                                {"type": "metadata",
                                 "VB_FORM": {"last_updated_on": current_time, "time_zone": time_zone},
                                 "headers": x_COBOL_report_header_list})

                        print(current_time)

                        return jsonify({"status": "success", "reason": "Successfully inserted data and "})
                    except Exception as e:
                        print('Error' + str(e))
                        return jsonify({"status": "failed", "reason": str(e)})

    except Exception as e:
        print('Error: ' + str(e))
        return jsonify({"status": "failure", "reason": "Response json not in the required format"})


@app.route('/api/v1/update/CRUD', methods=['POST'])
def updateCRUD():
    data = request.data
    # JSON document for db upload
    db_data = {}
    # CRUD Report headers extracted from the 'data' field
    x_CRUD_report_header_list = []

    # check if it is json
    JsonVerified, verification_payload = jsonVerify(data)
    if JsonVerified:
        db_data = verification_payload
    else:
        return verification_payload

    # Must have a key "data"
    try:
        keys = list(db_data.keys())
        print('parent keys', keys)

        if 'data' in keys:
            # fetching headers
            x_CRUD_report_header_list = db_data['headers']
            print('CRUD Report header list', x_CRUD_report_header_list)
            # Adding header field to db_data
            db_data['headers'] = x_CRUD_report_header_list

            if len(db_data['data']) == 0:
                return jsonify({"status": "failure", "reason": "data field is empty"})
            else:
                # Delete all existing rows (Nuking all data from the old database)
                previousDeleted = False
                try:
                    # print('crd remove operation', db.crud_report.remove({}))
                    if db.crud_report.remove({}):  # Mongodb syntax to delete all records
                        print('Deleted all the CRUD components from the report')
                        previousDeleted = True
                    else:
                        print('Something went wrong')
                        return jsonify(
                            {"status": "failed",
                             "reason": "unable to delete from database. Please check in with your Administrator"})

                except Exception as e:
                    return jsonify({"status": "failed", "reason": str(e)})
                if previousDeleted:
                    print('Entering the insert block')
                    try:

                        db.crud_report.insert_many(db_data['data'])
                        print('it has happened')
                        # updating the timestamp based on which report is called
                        current_time = datetime.datetime.now(tz=tz).strftime("%A, %d. %B %Y %I:%M%p")
                        # Setting the time so that we know when each of the JCL and COBOLs were run

                        # db.cross_reference_report.insert_one({"type":"metadata", "JCL":{"last_updated_on":ct},"COBOL":{"last_updated_on":ct}})

                        if db.crud_report.count_documents({"type": "metadata"}) > 0:
                            print('meta happen o naw', db.crud_report.update_one({"type": "metadata"},
                                                                                 {"$set": {
                                                                                     "last_updated_on": current_time,
                                                                                     "time_zone": time_zone,
                                                                                     "headers": x_CRUD_report_header_list
                                                                                 }},
                                                                                 upsert=True).acknowledged)
                        else:
                            db.crud_report.insert_one(
                                {"type": "metadata", "last_updated_on": current_time, "time_zone": time_zone,
                                 "headers": x_CRUD_report_header_list})

                        print(current_time)
                        return jsonify({"status": "success", "reason": "Successfully inserted data yay. "})
                    except Exception as e:
                        print('Error' + str(e))
                        return jsonify({"status": "failed", "reason": str(e)})

    except Exception as e:
        print('Error: ' + str(e))
        return jsonify({"status": "failure", "reason": "Response json not in the required format"})


@app.route('/api/v1/update/procedureFlow', methods=['POST'])
def updateProcedureFlow():
    # get data from POST request body
    data = request.data
    # print(data)
    # JSON document for db upload
    db_data = []
    # Payload
    payload = {}
    # List of all cobol programs that have been processed
    program_list = []
    # check if the text is json
    JsonVerified, verification_payload = jsonVerify(data)
    if JsonVerified:
        payload = verification_payload
    else:
        return verification_payload
    # Must have a key "data"
    try:
        keys = list(payload.keys())
        if 'data' in keys:
            # Getting a list of all programs
            program_list = list(payload['data'].keys())
            for program in program_list:
                # creating skeleton for program
                for event in payload['data'][program]:
                    temp = {"component_name": " ",
                            "event_name": "",
                            "nodes": [],
                            "links": []
                            }
                    # print(program)
                    # print(event)
                    temp['component_name'] = program
                    temp["event_name"] = event
                    node_set = set()
                    link_set = set()
                    for pgm_name_1 in payload['data'][program][event]:
                        # print("ffffff",pgm_name_1)

                        for pgm_name in pgm_name_1:
                            from_node = pgm_name['from']
                            to_node = pgm_name['to']
                            # extfile = pgm_name['file']
                            if pgm_name['name'] == "External":
                                node_set.add('p_' + from_node)
                                node_set.add('p_' + to_node)
                                # temp['links'].append({"source":'p_'+from_node,"target":'p_'+to_node})
                                link_set.add(json.dumps({"source": 'p_' + from_node, "target": 'p_' + to_node,
                                                         "label": "External_Program"}))
                            else:
                                node_set.add('p_' + from_node)
                                node_set.add('p_' + to_node)
                                # temp['links'].append({"source":'p_'+from_node,"target":'p_'+to_node})
                                link_set.add(json.dumps({"source": 'p_' + from_node, "target": 'p_' + to_node}))
                            # print(json.dumps({"source":'p_'+from_node,"target":'p_'+to_node}))
                        # print("temp",temp)
                    for item in link_set:
                        temp['links'].append(json.loads(item))

                    # Adding single node data.
                    if pgm_name_1 == []:
                        temp['nodes'].append({"id": "p_" + event, "label": event})
                    # ite variable to increment position variable

                    ite = 1
                    for item in node_set:
                        # temp['nodes'].append({"id":item,"label":item[2:],"position":"x"+str(ite)})
                        tempdict = {}
                        tempdict["id"] = item
                        for linkdict in pgm_name_1:
                            # print(linkdict["to"],item)
                            # print(True)
                            if linkdict["to"] == item[2:] and linkdict["name"] == "External":
                                tempdict["label"] = item[2:] + "(" + linkdict["file"] + ")"
                                # print(tempdict)
                                # print(linkdict["file"])
                            else:
                                tempdict["label"] = item[2:]

                        temp['nodes'].append(tempdict.copy())
                        ite = ite + 1

                    db_data.append(copy.deepcopy(temp))
                    temp.clear()
                    # print(db_data)

            try:
                # print('Remove operation', db.procedure_flow_table.remove({}))
                if db.procedure_flow_table.delete_many({}):  # Mongodb syntax to delete all records
                    # print('Deleted all the data from previous runs')
                    previousDeleted = True
                else:
                    # print('Something went wrong')
                    return jsonify(
                        {"status": "failed",
                         "reason": "unable to delete from database. Please check in with your Administrator"})

            except Exception as e:
                return jsonify({"status": "failed", "reason": str(e)})

            if previousDeleted:
                # print('Entering the insert block')
                try:
                    db.procedure_flow_table.insert_many(db_data)
                    # print('it has happened')
                    # updating the timestamp based on which report is called
                    current_time = datetime.datetime.now(tz=tz).strftime("%A, %d. %B %Y %I:%M%p")
                    # Setting the time so that we know when each of the JCL and COBOLs were run

                    # db.cross_reference_report.insert_one({"type":"metadata", "JCL":{"last_updated_on":ct},"COBOL":{"last_updated_on":ct}})

                    if db.procedure_flow_table.count_documents({"type": "metadata"}) > 0:
                        print('meta happen o naw', db.crud_report.update_one({"type": "metadata"},
                                                                             {"$set": {
                                                                                 "last_updated_on": current_time,
                                                                                 "time_zone": time_zone,
                                                                             }},
                                                                             upsert=True).acknowledged)
                    else:
                        db.procedure_flow_table.insert_one(
                            {"type": "metadata", "last_updated_on": current_time, "time_zone": time_zone})

                    # print(current_time)
                    return jsonify({"status": "success", "reason": "Successfully inserted data yay. "})
                except Exception as e:
                    # print('Error' + str(e))
                    return jsonify({"status": "failed", "reason": str(e)})
            return jsonify(db_data)

    except Exception as e:
        # print('Error: ' + str(e))
        # print('Error on line {}'.format(sys.exc_info()[-1].tb_lineno))
        return jsonify({"status": "failure", "reason": "Response json not in the required format"})


@app.route('/api/v1/controlflow', methods=['GET'])
def controlflow():
    response = {}
    response['component_name'] = request.args.get('component_name')
    response['component_type'] = request.args.get('component_type')
    response['nodes'] = []
    response['links'] = []

    if response['component_name'][0] == "$":  # HOT FIX FOR & response
        response['component_name'] = "&" + response['component_name'][1:]
    if response['component_name'][1] == "$":  # HOT FIX FOR & response
        response['component_name'] = "&" + response['component_name'][2:]

    def Remove(duplicate):
        final_list = []
        for list_iter in duplicate:
            if list_iter not in final_list:
                final_list.append(list_iter)
        return final_list

    def db_link(input_name, input_type):
        connections = db.cross_reference_report.find({"$or": [
            {"$and": [{"component_name": input_name}, {"component_type": input_type}]},
            {"$and": [{"called_name": input_name}, {"called_type": input_type}]}]}, {'_id': 0})
        return connections

    def db_link2(input_name, input_type):
        connections = db.crud_report.find({"component_name": input_name})

        return connections

    def accmode_aliases(Acc_mode):

        Acc_mode = i['access_mode']

        Acc_mode_list = Acc_mode.split(",")

        # for i in Acc_mode_list:
        if Acc_mode_list[0].strip() == "SHR":
            Acc_mode = "Read"
            return Acc_mode

        elif Acc_mode_list[0].strip() == "OLD":
            Acc_mode = "Read/Write"
            return Acc_mode
        elif Acc_mode_list[0].strip() == "NEW" or (Acc_mode_list[0].strip() == "" and len(Acc_mode_list) > 1):
            Acc_mode = "Write"
            return Acc_mode
        else:
            Acc_mode = Acc_mode_list[0].strip()
            return Acc_mode

    response['nodes'] = []
    response['links'] = []
    component_name = []
    component_type = []

    # component_name.append("AP725JBR")
    # component_type.append("JCL")

    try:
        connections = db_link(response['component_name'], response['component_type'])
        for i in connections:

            if i["called_type"].lower() != "utility":

                response["nodes"].append({"id": "p_" + i["component_name"] + "(" + i["component_type"] + ")",
                                          "label": i["component_name"] + "(" + i["component_type"] + ")"})
                response["nodes"].append({"id": "p_" + i["called_name"] + "(" + i["called_type"] + ")",
                                          "label": i["called_name"] + "(" + i["called_type"] + ")"})
                if i["component_name"] == response['component_name']:  # inputcomponent
                    if i["called_type"].lower() == "file":
                        response["links"].append({"label": accmode_aliases(i["access_mode"]),
                                                  "source": "p_" + i["component_name"] + "(" + i[
                                                      "component_type"] + ")",
                                                  "target": "p_" + i["called_name"] + "(" + i["called_type"] + ")"})

                    else:
                        response["links"].append({"label": "called",
                                                  "source": "p_" + i["component_name"] + "(" + i[
                                                      "component_type"] + ")",
                                                  "target": "p_" + i["called_name"] + "(" + i["called_type"] + ")"})

                    response["nodes"].append({"id": "p_" + i["called_name"] + "(" + i["called_type"] + ")",
                                              "label": i["called_name"] + "(" + i["called_type"] + ")"})
                else:

                    if i["called_type"].lower() == "file":
                        response["links"].append({"label": accmode_aliases(i["access_mode"]),
                                                  "source": "p_" + i["component_name"] + "(" + i[
                                                      "component_type"] + ")",
                                                  "target": "p_" + i["called_name"] + "(" + i["called_type"] + ")"})


                    else:
                        response["links"].append({"label": "calling",
                                                  "source": "p_" + i["component_name"] + "(" + i[
                                                      "component_type"] + ")",
                                                  "target": "p_" + i["called_name"] + "(" + i["called_type"] + ")"})

        table_connections = db_link2(response['component_name'], response['component_type'])

        for i in table_connections:

            if i["component_name"] == response['component_name']:  # inputcomponent:
                print("insed")
                response["nodes"].append({"id": "p_" + i["Table"],
                                          "label": i["Table"] + "(" + "Table" + ")"})
                response["links"].append({"label": i["CRUD"],
                                          "source": "p_" + i["component_name"] + "(" + i["component_type"] + ")",
                                          "target": "p_" + i["Table"]})

        response["links"] = Remove(response["links"])
        response["nodes"] = Remove(response["nodes"])

        return jsonify(response)
    except Exception as e:
        print(e)


@app.route('/api/v1/spiderDetails', methods=['GET'])
def spiderDetails():
    spider_details = set()
    response = {}
    response['component_name'] = ''
    response['component_type'] = ''
    response['nodes'] = []
    response['links'] = []
    '''
    Query for spider details
    -> All rows where the component name is either in called or calling
    -> Based on where the component name is -> Tag the relationship line as either Parent or Child
    -> In the label name of the child nodes must append the component_type in paranthesis as well
    -> two nodes A -> X can have both relationships parent/child
    '''

    try:
        response['component_name'] = request.args.get('component_name')
        response['component_type'] = request.args.get('component_type')
        response['nodes'] = []
        response['links'] = []
        if response['component_name'][0] == "$":  # HOT FIX FOR & response
            response['component_name'] = "&" + response['component_name'][1:]
        if response['component_name'][1] == "$":  # HOT FIX FOR & response
            response['component_name'] = "&" + response['component_name'][2:]

        name_type_map = {response['component_name']: response['component_type']}
        # Adding the first node of the chart
        nodes = {response['component_name']}
        print(response['component_name'])
        if response['component_name'] is not None:
            try:
                connections = db.cross_reference_report.find({"$or": [{"$and": [
                    {"component_name": response['component_name']}, {"component_type": response['component_type']}]}, {
                                                                          "$and": [{"called_name": response[
                                                                              'component_name']}, {
                                                                                       "called_type": response[
                                                                                           'component_type']}]}]},
                                                             {'_id': 0})
                # connections  = db.cross_reference_report.find({"$and": [{"$or":[{"component_name":response['component_name']},{"called_name":response['component_name']}]},{"component"}]},{'_id': 0})
                print('count', connections.count())

                if connections.count() > 0:
                    for connection in connections:
                        if connection['called_name'].strip() != '':
                            # If the CALLING component's name is same as option
                            if connection['component_name'] == response['component_name']:
                                response['links'].append({"source": "p_" + connection['component_name'],
                                                          "target": "p_" + connection['called_name'],
                                                          "label": "C"})
                                name_type_map[connection['called_name']] = connection['called_type']
                                nodes.add(connection['called_name'])
                            # If the CALLED component's name is same as option
                            else:

                                response['links'].append({"source": "p_" + connection['called_name'],
                                                          "target": "p_" + connection['component_name'],
                                                          "label": "P"})
                                name_type_map[connection['component_name']] = connection['component_type']

                                nodes.add(connection['component_name'])
                    for node in nodes:
                        response['nodes'].append({"id": "p_" + node, "label": node + ' (' + name_type_map[node] + ')'})
                else:
                    return jsonify({"error": "the component name" + response['component_name'] + " does not exist."})
                return jsonify(response)
            except Exception as e:
                return jsonify({"error": str(e)})
        return jsonify({"error": "The request parameters are either incorrect or missing"})
    except Exception as e:
        return jsonify({"error": str(e)})


@app.route('/api/v1/procedureFlowList', methods=['GET'])
def procedureFlowList():
    pgm_name_set = set()
    try:
        list_of_programs = db.procedure_flow_table.distinct("component_name")
        for pgm in list_of_programs:
            pgm_name_set.add(pgm)
        print(pgm_name_set)
        return jsonify({"program_list": sorted(list(pgm_name_set))})
    except Exception as e:
        print('Error:', str(e))
        return jsonify({"status": "failure", "reason": "Error: " + str(e)})


@app.route('/api/v1/procedureFlow', methods=['GET'])
def procedureFlow():
    try:
        option = request.args.get('option')
        event = request.args.get('event')
        flag = "no"
        if option is not None:
            if flag == "no":
                # ge the program name to return
                program_name = option

                try:
                    # cursor = db.cross_reference_report.find({'type': {"$ne": "metadata"}}, {'_id': 0})

                    response = db.procedure_flow_table.find_one(
                        {"$and": [{"component_name": program_name, "event_name": event}]}, {'_id': 0})
                    # print(response)
                    if response is None:
                        return jsonify({"response": "No such key"})
                    else:
                        # print(response)
                        return jsonify(response)
                except Exception as e:
                    print("Error", str(e))
                    return jsonify({"status": "failure", "reason": "Error: " + str(e)})
            if flag == "yes":
                program_name = option

                try:
                    # cursor = db.cross_reference_report.find({'type': {"$ne": "metadata"}}, {/api/v1/comment_line_report'_id': 0})

                    response = db.procedure_flow_table_EC.find_one({"component_name": program_name}, {'_id': 0})

                    if response is None:
                        return jsonify({"response": "No such key"})
                    else:
                        # print(response)
                        return jsonify(response)
                except Exception as e:
                    print("Error", str(e))
                    return jsonify({"status": "failure", "reason": "Error: " + str(e)})

    except Exception as e:
        print("Error", str(e))
        return jsonify({"status": "failure", "reason": "Error: " + str(e)})


@app.route('/api/v1/augment/masterInventory', methods=['POST'])
def augmentMasterInventory():
    try:
        # check if the text is json
        JsonVerified, verification_payload = jsonVerify(request.data)
        if JsonVerified:
            payload = verification_payload
        else:
            return verification_payload

        keys = list(payload.keys())
        for ite in keys:
            row = payload[ite]
            if db.master_inventory_report.update_one({"component_name": ite + '.cbl'}, {
                "$set": {"dead_para_count": row['dead_para_count'], "dead_para_list": row['dead_para_list'],
                         "no_of_dead_lines": row['total_dead_lines'],
                         'total_para_count': row['total_para_count']}}).acknowledged:
                print('updated', ite)
            else:
                print('not updated')

        return jsonify({"yo": "yo"})

    except Exception as e:
        print("error" + str(e))
        return jsonify({"status": "failure", "reason": "Error: " + str(e)})


@app.route('/api/v1/augment/cycloMetric', methods=['POST'])
def augmentcycloMetric():
    try:
        # check if the text is json
        JsonVerified, verification_payload = jsonVerify(request.data)
        if JsonVerified:
            payload = verification_payload
        else:
            return verification_payload

        keys = list(payload.keys())
        for ite in keys:
            row = payload[ite]
            # print(row[ite])
            if db.master_inventory_report.update_one({"component_name": ite}, {
                "$set": {"cyclomatic_complexity": row}}).acknowledged:
                print('updated', ite)
            else:
                print('not updated')

        return jsonify({"yo": "yo"})

    except Exception as e:
        print('Error: ' + str(e))
        print('Error on line {}'.format(sys.exc_info()[-1].tb_lineno))
        return jsonify({"status": "failure", "reason": "Response json not in the required format"})


@app.route('/api/v1/update/masterInventory', methods=['POST'])
def updateMasterInventory():
    data = request.data
    # JSON document for db upload
    db_data = {}
    # masterInventory headers extracted from the 'data' field
    x_master_Inventory_header_list = []

    # check if it is json
    JsonVerified, verification_payload = jsonVerify(data)
    if JsonVerified:
        db_data = verification_payload
    else:
        return verification_payload

        # Must have a key "data"
    try:
        keys = list(db_data.keys())
        print('parent keys', keys)

        if 'data' in keys:
            # fetching headers
            x_master_Inventory_header_list = list(db_data['headers'])
            print('Master Inventory header list', x_master_Inventory_header_list)
            # Adding header field to db_data
            db_data['headers'] = x_master_Inventory_header_list
            print('Headers', x_master_Inventory_header_list)
            if len(db_data['data']) == 0:
                return jsonify({"status": "failure", "reason": "data field is empty"})
            else:
                # Delete all existing rows (Nuking all data from the old database)
                previousDeleted = False
                try:
                    print('mInventory remove operation', db.master_inventory_report.remove({}))
                    if db.master_inventory_report.remove({}):  # Mongodb syntax to delete all records
                        print('Deleted all the Master Inventory components from the report')
                        previousDeleted = True
                    else:
                        print('Something went wrong')
                        return jsonify(
                            {"status": "failed",
                             "reason": "unable to delete from database. Please check in with your Administrator"})

                except Exception as e:
                    return jsonify({"status": "failed", "reason": str(e)})
                if previousDeleted:

                    try:

                        db.master_inventory_report.insert_many(db_data['data'])
                        # updating the timestamp based on which report is called
                        current_time = datetime.datetime.now(tz=tz).strftime("%A, %d. %B %Y %I:%M%p")
                        # Setting the time so that we know when each of the JCL and COBOLs were run

                        # db.cross_reference_report.insert_one({"type":"metadata", "JCL":{"last_updated_on":ct},"COBOL":{"last_updated_on":ct}})

                        if db.master_inventory_report.count_documents({"type": "metadata"}) > 0:
                            print('meta happen o naw', db.master_inventory_report.update_one({"type": "metadata"},
                                                                                             {"$set": {
                                                                                                 "last_updated_on": current_time,
                                                                                                 "time_zone": time_zone,
                                                                                                 "headers": x_master_Inventory_header_list
                                                                                             }},
                                                                                             upsert=True).acknowledged)
                        else:
                            db.master_inventory_report.insert_one(
                                {"type": "metadata", "last_updated_on": current_time, "time_zone": time_zone,
                                 "headers": x_master_Inventory_header_list})

                        print(current_time)
                        return jsonify({"status": "success", "reason": "Successfully inserted data. "})
                    except Exception as e:
                        print('Error' + str(e))
                        return jsonify({"status": "failed", "reason": str(e)})


    except Exception as e:
        print('Error: ' + str(e))
        return jsonify({"status": "failure", "reason": "Response json not in the required format"})


@app.route('/api/v1/update/orphanReport', methods=['POST'])
def updateOrphanReport():
    data = request.data
    # check if it is json
    try:
        data = json.loads(data)
    except Exception as e:
        print('Error ' + str(e))
        return jsonify('{"status":failure","reason":"Request body is not valid JSON"}')
    # Must have only 1 key, ie "data"
    if list(data.keys())[0] == 'data':
        # code to insert data into database
        status = db.config.XYZ_COMPANY_METADATA.update({"type": ORPHAN_REPORT_TYPE}, {"$set": data})
        return jsonify(str(status))
    else:
        return jsonify('{"status":"failure","reason":"JSON data is not of the required format."}')


@app.route('/api/v1/callchain', methods=['GET'])
def callchain():
    source_child = []
    source_parent = []
    spider_details = set()
    response = {}
    response['component_name'] = ''
    response['component_type'] = ''
    response['nodes'] = []
    response['links'] = []

    '''
    Query for spider details
    -> All rows where the component name is either in called or calling
    -> Based on where the component name is -> Tag the relationship line as either Parent or Child
    -> In the label name of the child nodes must append the component_type in paranthesis as well
    -> two nodes A -> X can have both relationships parent/child
    '''

    def input_value(c_name, c_type):  # VFM0002C-name COPYBOOK-type
        response['component_name'] = c_name
        response['component_type'] = c_type
        # Adding the first node of the chart
        return response['component_name'], response['component_type']

    def db_link(input_name, input_type):
        connections = db.cross_reference_report.find({"$or": [
            {"$and": [{"component_name": input_name}, {"component_type": input_type}]},
            {"$and": [{"called_name": input_name}, {"called_type": input_type}]}]}, {'_id': 0})
        return connections

    def child_link(called_name, component_type):
        response['links'].append({"source": "p_" + called_name,
                                  "target": "p_" + component_type,
                                  "label": "C"})
        return response['links']

    def parent_link(called_name, component_type):
        response['links'].append({"source": "p_" + called_name,
                                  "target": "p_" + component_type,
                                  "label": "P"})
        return response['links']

    response['nodes'] = []
    response['links'] = []
    component_name = []
    component_type = []
    temp = []
    component_name1 = request.args.get("component_name")
    component_name1 = component_name1.replace("$", "&")
    component_name.append(component_name1)
    component_type.append(request.args.get("component_type"))
    parent_child = request.args.get("level")
    # print(component_name1,component_type,parent_child)
    try:
        for c_name, c_type in zip(component_name, component_type):
            input_name, input_type = input_value(c_name, c_type)
            # print("input", input_name, input_type)
            nodes = {input_name}
            name_type_map = {input_name: input_type}
            if input_name is not None:
                connections = db_link(input_name, input_type)
                # print(connections.count())
                if connections.count() > 0:
                    # connections.count()=connections.count-1
                    flag = 1
                    for connection in connections:
                        if connection['called_name'].strip() != '':
                            if connection['component_name'].strip() == input_name:
                                if parent_child == "child":
                                    if connection['called_type'].lower() != 'file' and connection[
                                        'called_type'].lower() != 'workbook' and connection[
                                        'called_name'] not in component_name:
                                        component_name.append(connection['called_name'])
                                        component_type.append(connection['called_type'])
                                        child_output = child_link(connection['component_name'],
                                                                  connection['called_name'])
                                        name_type_map[connection['called_name']] = connection['called_type']
                                        if connection['called_name'] not in nodes:
                                            nodes.add(connection['called_name'])
                                            flag = 0
                            else:
                                if (parent_child == "parent"):
                                    parent_output = parent_link(connection['called_name'], connection['component_name'])
                                    # print(parent_output)
                                    if connection['component_name'] not in component_name:
                                        component_name.append(connection['component_name'])
                                        component_type.append(connection['component_type'])
                                        # print("parent")
                                        # print(component_name)
                                        name_type_map[connection['component_name']] = connection['component_type']
                                        if connection['component_name'] not in nodes:
                                            nodes.add(connection['component_name'])
                                            flag = 0

                    if flag == 0:
                        for node in nodes:
                            # print(nodes)
                            if (node not in temp):
                                # print(temp)
                                temp.append(node)
                                response['nodes'].append({"id": "p_" + node,
                                                          "label": node + '(' + name_type_map[node] + ')'})

                    # print(response)

        # print(response)
        return jsonify(response)

    except Exception as e:
        return jsonify({"error": str(e)})


@app.errorhandler(404)
def page_not_found(e):
    #    return jsonify({"status":"failure","reason":"This route does not exist"})
    return "This route does not exists"


@app.route('/api/v1/glossary', methods=['GET'])
def glossary():
    data_object = {}
    data_object['data'] = []

    data_object['displayed_count'] = 0
    try:
        search_filter = request.args.get('searchFilter')
        override_filter = request.args.get('overrideFilter')
        # print(override_filter)
        # Fetch the total record count
        data_object['total_record_count'] = db.glossary.count_documents({}) - 1

        # Filter override to download export entire dump to CSV/Excel
        if override_filter == 'yes':

            cursor = db.glossary.find({'type': {"$ne": "metadata"}}, {'_id': 0})
            # Query to fetch header details
            metadata = db.glossary.find_one({"type": "metadata"}, {'_id': 0})
            data_object['headers'] = metadata['headers']

            # Pandas code for cursor to dictionary convertion
            dfDataset = pd.DataFrame.from_records(cursor)
            # print(dfDataset)
            # data_object['displayed_count'] = int(dfDataset['component_name'].count())
            data_object['displayed_count'] = db.glossary.find({'type': {"$ne": "metadata"}}, {'_id': 0}).count()
            # data_object['displayed_count'] =
            data_object['data'] = dfDataset.fillna("").to_dict('records')

            return jsonify(data_object)
        else:

            if search_filter:
                # Query all cross reference data
                cursor = db.glossary.find({'type': {"$ne": "metadata"}}, {'_id': 0})
                # Query to fetch header details
                metadata = db.glossary.find_one({"type": "metadata"}, {'_id': 0})
                data_object['headers'] = metadata['headers']
                dfDataset = pd.DataFrame.from_records(cursor)
                resultdf = dfDataset[dfDataset.apply(lambda x: x.str.contains(search_filter, na=False)).any(axis=1)]
                ##print('Result count', resultdf['component_name'].count())
                # data_object['displayed_count']=int(resultdf['component_name'].count())
                data_object['displayed_count'] = db.glossary.find({'type': {"$ne": "metadata"}}, {'_id': 0}).count()
                # data_object['displayed_count'] = CROSS_REFERENCE_LIMIT
                data_object['data'] = resultdf.fillna("").to_dict('records')

                return jsonify(data_object)

            else:
                # If there is no filter criteria, limit to 1000 records
                # Query all cross reference data
                cursor = db.glossary.find({'type': {"$ne": "metadata"}}, {'_id': 0}).limit(CROSS_REFERENCE_LIMIT)
                # Query to fetch header details
                metadata = db.glossary.find_one({"type": "metadata"}, {'_id': 0})
                data_object['headers'] = metadata['headers']

                # Pandas code for cursor to dictionary convertion
                dfDataset = pd.DataFrame.from_records(cursor)
                # data_object['displayed_count'] = int(dfDataset['component_name'].count())
                data_object['displayed_count'] = db.glossary.find({'type': {"$ne": "metadata"}}, {'_id': 0}).count()
                data_object['data'] = dfDataset.fillna("").to_dict('records')
                return jsonify(data_object)
    except Exception as e:
        # print('Error: ' + str(e))
        # print('Error on line {}'.format(sys.exc_info()[-1].tb_lineno))
        return 'FAIL' + str(e)


@app.route('/api/v1/uploadglossary', methods=['GET', 'POST'])
def uploadglossary():
    file = request.get_data()
    str_file = file.decode("utf-8")
    temp_file = list(eval(str_file))

    # temp_file = str_file.split("}")
    # print((temp_file + "}"))

    option = temp_file[0]['component_name']

    for json_dict in temp_file:
        # cursor = db.glossary.find({"component_name": json_dict["component_name"], "Variable": json_dict["Variable"]})

        if (json_dict.__contains__('Business_Meaning')):

            pass
        else:
            json_dict['Business_Meaning'] = ''

        try:

            db.glossary.update({"component_name": json_dict["component_name"], "Variable": json_dict["Variable"]},
                               {"$set": {
                                   "Business_Meaning": json_dict["Business_Meaning"]}})
        except:
            return jsonify("failure")

        continue

    return jsonify("success")


@app.route('/api/v1/updateVarDef', methods=['GET'])
def updateVarDef():
    import def_update
    # time.sleep(2)
    def_update.main()

    return jsonify("success")


@app.route('/api/v1/updateBRE', methods=['GET'])
def updateBRE():
    try:
        fragment_id = request.args.get('fragment_id')
        rule_description = request.args.get('rule_description').replace("HASH", "#")
        rule_category = request.args.get('rule_category')

        if db.bre_report2.update_one({"fragment_id": fragment_id}, {
            "$set": {
                'rule_category': rule_category,
                'rule_description': rule_description

            }}).acknowledged:
            print('updated')
        else:
            print('not updated')

        return jsonify({"yo": "yo"})

    except Exception as e:
        print("error" + str(e))
        return jsonify({"status": "failure", "reason": "Error: " + str(e)})


@app.route("/api/v1/comment_lines")
def comment_lines():
    # db=client['COBOL']
    name = request.args.get("component_name")
    type = request.args.get("component_type")
    # print(name)
    cursor = db.cobol_output.find({"component_name": name, "component_type": type})
    json_format = ""
    for cursor1 in cursor:
        json_format = {"component_name": cursor1["component_name"],
                       "component_type": cursor1["component_type"],
                       "commented_lines": cursor1["codeString"]}
        out = {"data": json_format}
        print(out)
    return jsonify(json_format)


@app.route("/api/v1/screen_simulation")
def screen_simulation():
    name = request.args.get("component_name")
    appname = request.args.get("application")
    cursor = db.screen_simulation.find({"component_name": name, "application": appname})
    json_format = ""
    for cursor1 in cursor:
        json_format = {"component_name": cursor1["component_name"], "application": cursor1["application"],
                       "simulation": cursor1["simulation"]}
        out = {"data": json_format}
        print(out)
    return jsonify(json_format)


@app.route('/api/v1/cicsxrefApp', methods=['GET'])
def cicsxrefApp():
    data_object = {}
    data_object['data'] = []

    data_object['displayed_count'] = 0
    try:
        search_filter = request.args.get('searchFilter')
        override_filter = request.args.get('overrideFilter')
        appname = request.args.get('option')
        if appname == "All":
            # Fetch the total record count
            data_object['total_record_count'] = db.cicsxref.count_documents({}) - 1

            # Filter override to download export entire dump to CSV/Excel
            if override_filter == 'yes':
                # Query all cross reference data
                cursor = db.cicsxref.find({'type': {"$ne": "metadata"}}, {'_id': 0})
                # Query to fetch header details
                metadata = db.cicsxref.find_one({"type": "metadata"}, {'_id': 0})
                # Hotfix to not diplay the file name
                data_object['headers'] = metadata['headers']
                # Pandas code to convert cursor to a dict
                dfDataset = pd.DataFrame.from_records(cursor)
                resultdf = dfDataset[dfDataset.apply(lambda x: x.str.contains(search_filter, na=False)).any(axis=1)]
                data_object['data'] = resultdf.fillna("").to_dict('records')
                data_object['displayed_count'] = data_object['total_record_count']
                return jsonify(data_object)
            else:

                if search_filter:
                    # Query all cross reference data
                    cursor = db.cicsxref.find({'type': {"$ne": "metadata"}}, {'_id': 0})
                    # Query to fetch header details
                    metadata = db.cicsxref.find_one({"type": "metadata"}, {'_id': 0})
                    data_object['headers'] = metadata['headers']
                    dfDataset = pd.DataFrame.from_records(cursor)
                    resultdf = dfDataset[dfDataset.apply(lambda x: x.str.contains(search_filter, na=False)).any(axis=1)]
                    # #print('Result count', resultdf['component_name'].count())
                    data_object['displayed_count'] = int(resultdf['component_name'].count())
                    data_object['data'] = resultdf.fillna("").to_dict('records')
                    return jsonify(data_object)

                else:
                    # If there is no filter criteria, limit to 1000 records
                    # Query all cross reference data
                    cursor = db.cicsxref.find({'type': {"$ne": "metadata"}}, {'_id': 0}).limit(
                        CROSS_REFERENCE_LIMIT)
                    # Query to fetch header details
                    metadata = db.cicsxref.find_one({"type": "metadata"}, {'_id': 0})
                    data_object['headers'] = metadata['headers']

                    # Pandas code for cursor to dictionary convertion
                    dfDataset = pd.DataFrame.from_records(cursor)
                    data_object['displayed_count'] = data_object['total_record_count']
                    data_object['data'] = dfDataset.fillna("").to_dict('records')
                    return jsonify(data_object)

        else:
            # Fetch the total record count
            # data_object['total_record_count'] = db.cicsxref.count_documents({}) - 1

            # Filter override to download export entire dump to CSV/Excel
            if override_filter == 'yes':
                # Query all cross reference data
                cursor = db.cicsxref.find({"calling_app_name": appname}, {'_id': 0})
                # Query to fetch header details
                metadata = db.cicsxref.find_one({"type": "metadata"}, {'_id': 0})
                # Hotfix to not diplay the file name
                data_object['headers'] = metadata['headers']
                # Pandas code to convert cursor to a dict
                dfDataset = pd.DataFrame.from_records(cursor)
                resultdf = dfDataset[dfDataset.apply(lambda x: x.str.contains(search_filter, na=False)).any(axis=1)]
                data_object['data'] = resultdf.fillna("").to_dict('records')
                data_object['displayed_count'] = data_object['total_record_count']
                return jsonify(data_object)
            else:

                if search_filter:
                    # Query all cross reference data
                    cursor = db.cicsxref.find({"calling_app_name": appname}, {'_id': 0})
                    # Query to fetch header details
                    metadata = db.cicsxref.find_one({"type": "metadata"}, {'_id': 0})
                    data_object['headers'] = metadata['headers']
                    dfDataset = pd.DataFrame.from_records(cursor)
                    resultdf = dfDataset[dfDataset.apply(lambda x: x.str.contains(search_filter, na=False)).any(axis=1)]
                    # #print('Result count', resultdf['component_name'].count())
                    data_object['displayed_count'] = int(resultdf['component_name'].count())
                    data_object['data'] = resultdf.fillna("").to_dict('records')
                    return jsonify(data_object)

                else:
                    # If there is no filter criteria, limit to 1000 records
                    # Query all cross reference data
                    cursor = db.cicsxref.find({"calling_app_name": appname}, {'_id': 0}).limit(
                        CROSS_REFERENCE_LIMIT)
                    # Query to fetch header details
                    metadata = db.cicsxref.find_one({"type": "metadata"}, {'_id': 0})
                    data_object['headers'] = metadata['headers']

                    # Pandas code for cursor to dictionary convertion
                    dfDataset = pd.DataFrame.from_records(cursor)
                    data_object['displayed_count'] = db.cicsxref.find({"calling_app_name": appname}).count()
                    data_object['data'] = dfDataset.fillna("").to_dict('records')
                    return jsonify(data_object)




    except Exception as e:
        # print('Error: ' + str(e))
        # print('Error on line {}'.format(sys.exc_info()[-1].tb_lineno))
        return 'FAIL' + str(e)


@app.route('/api/v1/cicsrule', methods=['GET'])
def cicsrule():
    data_object = {}
    data_object['data'] = []
    try:
        option = request.args.get('option')
        header = ["program_name", "map_name", "application", "field_name", "validation_rule"]
        option = option.split('.')
        option = option[0]
        # cursor = db.cics_rule_report.find({"program_name": option}, {"_id": 0}).sort('_id')
        cursor = db.cics_rule_report.find({"map_name": option}, {"_id": 0}).sort('_id')
        # #cursor = db.cics_rule_report.find({'type': {"$ne": "metadata"}}, {'_id': 0})
        # metadata = db.cics_rule_report.find_one({"type": "metadata"}, {'_id': 0})
        data_object['headers'] = header
        for document in cursor:
            # del document['file_name']
            data_object['data'].append(document)
    except Exception as e:
        print('')
    return jsonify(data_object)


@app.route('/api/v1/cicsfield', methods=['GET'])
def cicsfield():
    data_object = {}
    data_object['data'] = []
    apname = request.args.get('option')
    filename = request.args.get('selectedName')
    #    apname = "ANONYMOUS"
    #    filename = "BookDetails.aspx"
    print("checking", apname, filename)
    if apname == "All":
        try:
            cursor = db.screenfields.find({"filename": filename}, {"_id": 0})
            metadata = db.screenfields.find_one({"type": "metadata"}, {'_id': 0})
            data_object['headers'] = metadata['headers']
            for document in cursor:
                data_object['data'].append(document)
        except Exception as e:
            print(e)
        return jsonify(data_object)
    else:
        try:
            cursor = db.screenfields.find({"application": apname, "filename": filename}, {"_id": 0})
            metadata = db.screenfields.find_one({"type": "metadata"}, {'_id': 0})
            data_object['headers'] = metadata['headers']
            print(metadata['headers'])
            for document in cursor:
                data_object['data'].append(document)
        except Exception as e:
            print(e)
        return jsonify(data_object)


@app.route('/api/v1/procedureFlowMapList', methods=['GET'])
def procedureMapCompList():
    option = request.args.get('option')
    comp_name_set = set()
    if option is not None:
        application_name = option
        try:
            response = db.master_inventory_report.find({"application": application_name, "component_type": "BMS"})
            if response is None:
                return jsonify({"response": "No such key"})
            else:
                for appln in response:
                    comp_name_set.add(appln["component_name"])
                return jsonify({"component_list": sorted(list(comp_name_set)), "application_name": application_name})
        except Exception as e:
            print("Error", str(e))
            return jsonify({"status": "failure", "reason": "Error: " + str(e)})


@app.route('/api/v1/ruleCategoryList')
def breruledd():
    try:
        bre_list = db.bre_rules_report.distinct("rule_category")
        out_bre = list(filter(None, bre_list))
    except Exception as e:
        print(e)
        pass
    return jsonify({"rule_category_list": out_bre})


@app.route('/api/v1/ruleCategory')
def brerule():
    data_object = {}
    data_object['data'] = []
    data_object['displayed_count'] = 0
    try:
        option = request.args.get('option')
        search_filter = request.args.get('searchFilter')
        override_filter = request.args.get('overrideFilter')
        # #print(override_filter)

        # Fetch the total record count
        data_object['total_record_count'] = db.bre_rules_report.count_documents({}) - 1
        # #print("total record count", data_object['total_record_count'])

        # Filter override to download export entire dump to CSV/Excel
        if override_filter == 'yes':
            # print("going inside")
            # Query all cross reference data
            cursor = db.bre_rules_report.find({"rule_category": option}, {'_id': 0})
            # Query to fetch header details
            metadata = db.bre_rules_report.find_one({"type": "metadata"}, {'_id': 0})
            # Hotfix to not diplay the file name
            data_object['headers'] = metadata['headers'][1:]
            # Pandas code to convert cursor to a dict
            dfDataset = pd.DataFrame.from_records(cursor)
            resultdf = dfDataset[dfDataset.apply(lambda x: x.str.contains(search_filter, na=False)).any(axis=1)]
            data_object['data'] = resultdf.fillna("").to_dict('records')
            data_object['displayed_count'] = db.bre_rules_report.find({"rule_category": option}).count()
            # print("display count", data_object['displayed_count'])
            return jsonify(data_object)
        else:

            if search_filter:
                # Query all cross reference data
                # cursor = db.bre_rules_report.find({'type': {"$ne": "metadata"}}, {'_id': 0})
                cursor = db.bre_rules_report.find({'$and': [{'type': {"$ne": "metadata"}}, {"rule_category": option}]},
                                                  {'_id': 0})
                # Query to fetch header details
                metadata = db.bre_rules_report.find_one({"type": "metadata"}, {'_id': 0})
                data_object['headers'] = metadata['headers'][1:]
                # print(data_object['headers'])
                dfDataset = pd.DataFrame.from_records(cursor)
                resultdf = dfDataset[dfDataset.apply(lambda x: x.str.contains(search_filter, na=False)).any(axis=1)]
                # #print('Result count', resultdf['component_name'].count())
                data_object['displayed_count'] = int(dfDataset['pgm_name'].count())
                data_object['data'] = resultdf.fillna("").to_dict('records')
                # print("count", data_object['displayed_count'])
                return jsonify(data_object)

            else:
                # If there is no filter criteria, limit to 1000 records
                # Query all cross reference data
                cursor = db.bre_rules_report.find({"rule_category": option}, {'_id': 0}).limit(
                    CROSS_REFERENCE_LIMIT)
                # Query to fetch header details
                metadata = db.bre_rules_report.find_one({"type": "metadata"}, {'_id': 0})
                data_object['headers'] = metadata['headers'][1:]
                # print(data_object['headers'])
                # Pandas code for cursor to dictionary convertion
                dfDataset = pd.DataFrame.from_records(cursor)
                resultdf = dfDataset[dfDataset.apply(lambda x: x.str.contains(option, na=False)).any(axis=1)]
                # #print('Result count', resultdf['component_name'].count())
                data_object['displayed_count'] = db.bre_rules_report.find({"rule_category": option}).count()
                data_object['data'] = resultdf.fillna("").to_dict('records')
                # print("count", data_object['displayed_count'])
                return jsonify(data_object)
    except Exception as e:
        # print('Error: ' + str(e))
        # print('Error on line {}'.format(sys.exc_info()[-1].tb_lineno))
        return 'FAIL' + str(e)


@app.route('/api/v1/sankeyDetails', methods=['GET'])
def inout():
    inout = request.args.get('integration')
    cname = request.args.get('application_name')
    # print(inout)
    # print(cname)
    connections = db.cross_reference_report.find({"type": {'$ne': 'metadata'}})
    calling_list = []
    called_list = []
    d = {}
    metadata = []
    for connection in connections:
        try:
            calling_list.append(connection['calling_app_name'])
            called_list.append(connection['calling_app_name'] + connection['called_app_name'])

        # print(calling_list)
        # print(called_list)
        except KeyError as e:
            print(e)
        di = {}
        out_list = []
    for key in list(set(calling_list)):
        if (inout == 'inbound'):
            out_list = []
        for val in called_list:
            # print(val, cname)
            if (inout == 'inbound' and val[len(key):] == cname):
                if (val[:len(key)] == key):
                    out_list.append(val[len(key):])
            elif (inout == 'outbound' and key[:len(key)] == cname):
                if (val[:len(key)] == key):
                    out_list.append(val[len(key):])
                    # print(key[:len(key)])
        if (inout == 'inbound'):
            di[key] = out_list
    di[cname] = out_list
    # print(di)
    out_val = []
    for k, v in di.items():
        for li in list(set(v)):
            if k != li:
                count = list(v).count(li)
                # print(k,li,count)
                out_val.append([k, li, count])
    # print(out_val)
    return jsonify(out_val)


@app.route("/api/v1/codeString")
def codeString():
    mapName = request.args.get("map_name")
    if not "." in mapName:
        mapName = mapName.split("(")[0]+".jsp"
    print("mapName", mapName)
    connections = db.screen_simulation.find({"type": {"$ne": "metadata"}})
    for connection in connections:
        if (connection["component_name"] == mapName):
            d = {"codeString": connection['codeString']}
            return jsonify(d)


@app.route('/api/v1/orphanReport', methods=['GET'])
def orphanReport():
    data_object = {}
    data_object['data'] = []
    appname = request.args.get('option')
    if appname != "All":
        try:
            cursor = db.orphan_report.find({"application": appname}, {'_id': 0})
            metadata = db.orphan_report.find_one({"type": "metadata"}, {'_id': 0})
            data_object['headers'] = metadata['headers']
            for document in cursor:
                data_object['data'].append(document)
        except Exception as e:
            print('')
        return jsonify(data_object)
    else:
        try:
            cursor = db.orphan_report.find({'type': {"$ne": "metadata"}}, {'_id': 0})
            metadata = db.orphan_report.find_one({"type": "metadata"}, {'_id': 0})
            data_object['headers'] = metadata['headers']
            for document in cursor:
                data_object['data'].append(document)
        except Exception as e:
            print('')
        return jsonify(data_object)


@app.route('/api/v1/missingComponents', methods=['GET'])
def missingComponents():
    # #print('yoyoyoyoyo')
    data_object = {}
    data_object['data'] = []
    appname = request.args.get('option')
    if appname == "All":
        try:
            cursor = db.missing_components_report.find({'type': {"$ne": "metadata"}}, {'_id': 0})
            metadata = db.missing_components_report.find_one({"type": "metadata"}, {'_id': 0})
            data_object['headers'] = metadata['headers']
            # #print(cursor)
            for document in cursor:
                data_object['data'].append(document)
                # #print(document)
        except Exception as e:
            return jsonify({"error": str(e)})
        return jsonify(data_object)
    else:
        try:
            cursor = db.missing_components_report.find({"application": appname}, {'_id': 0})
            metadata = db.missing_components_report.find_one({"type": "metadata"}, {'_id': 0})
            data_object['headers'] = metadata['headers']
            # #print(cursor)
            for document in cursor:
                data_object['data'].append(document)
                # #print(document)
        except Exception as e:
            return jsonify({"error": str(e)})
        return jsonify(data_object)


@app.route('/api/v1/spiderTypes', methods=['GET'])
def spiderTypes():
    apname = request.args.get('application_name')
    try:
        distinct_types = set()
        if apname == "All":
            component_types = db.cross_reference_report.distinct("component_type")
            called_types = db.cross_reference_report.distinct("called_type")
            for item in component_types:
                distinct_types.add(item)
            for item in called_types:
                distinct_types.add(item)
            return jsonify(sorted(list(distinct_types)))
        else:
            component_types = db.cross_reference_report.distinct("component_type", {"calling_app_name": apname})
            called_types = db.cross_reference_report.distinct("called_type", {"calling_app_name": apname})
            for item in component_types:
                distinct_types.add(item)
            for item in called_types:
                distinct_types.add(item)
            return jsonify(sorted(list(distinct_types)))

    except Exception as e:
        # print("Error:", str(e))
        return jsonify({"error": str(e)})


@app.route('/api/v1/spiderList', methods=['GET'])
def spiderList():
    try:
        apname = request.args.get('application_name')
        option = request.args.get('option')
        print(option, apname)
        distinct_elements = set()
        if apname == "All":
            if option is not None:
                calling_names = db.cross_reference_report.distinct("component_name", {"component_type": option})
                called_names = db.cross_reference_report.distinct("called_name", {"called_type": option})
                for item in called_names:
                    distinct_elements.add(item)
                for item in calling_names:
                    distinct_elements.add(item)
                return jsonify(sorted(list(distinct_elements)))
            else:
                return jsonify({"error": "No option provided"})

        else:
            if option is not None:
                calling_names = db.cross_reference_report.distinct("component_name", {"component_type": option,
                                                                                      "calling_app_name": apname})
                called_names = db.cross_reference_report.distinct("called_name",
                                                                  {"called_type": option, "calling_app_name": apname})
                for item in called_names:
                    distinct_elements.add(item)
                for item in calling_names:
                    distinct_elements.add(item)
                return jsonify(sorted(list(distinct_elements)))
            else:
                return jsonify({"error": "No option provided"})

    except Exception as e:
        return jsonify({"error": str(e)})


@app.route('/api/v1/spiderFilterList')
def spiderFilterList():
    connections = db.cross_reference_report.find({"type": {"$ne": "metadata"}})
    connections1 = db.missing_component_report.find({"type": {"$ne": "metadata"}})
    not_to_list = []
    for connection in connections1:
        not_to_list.append((connection['component_name']))
    # print(connections.count())
    response = {}
    try:
        response['component_name'] = request.args.get('component_name')
        response['component_type'] = request.args.get('component_type')
        response['nodes'] = []
        response['links'] = []
        if response['component_name'][0] == "$":  # HOT FIX FOR & response
            response['component_name'] = "&" + response['component_name'][1:]
        if response['component_name'][1] == "$":  # HOT FIX FOR & response
            response['component_name'] = "&" + response['component_name'][2:]

        name_type_map = {response['component_name']: response['component_type']}
        # Adding the first node of the chart
        nodes = {response['component_type']}
        uni_list = []
        # print(response['component_name'])
        if response['component_name'] is not None:
            try:
                connections = db.cross_reference_report.find({"$or": [{"$and": [
                    {"component_name": response['component_name']},
                    {"component_type": response['component_type']}]}, {
                    "$and": [{"called_name": response[
                        'component_name']}, {
                                 "called_type": response[
                                     'component_type']}]}]},
                    {'_id': 0})
                # connections  = db.cross_reference_report.find({"$and": [{"$or":[{"component_name":response['component_name']},{"called_name":response['component_name']}]},{"component"}]},{'_id': 0})
                # print('count', connections.count())

                if connections.count() > 0:
                    for connection in connections:
                        if connection['called_name'].strip() != '' and connection['component_name'] not in not_to_list:
                            # If the CALLING component's name is same as option
                            if connection['component_name'] == response['component_name']:
                                uni_list.append(str(connection['called_type']).upper())
                            # If the CALLED component's name is same as option
                            else:
                                uni_list.append(str(connection['component_type']).upper())

                uni_list = list(set(uni_list))
                uni_list.insert(0, "All")
                return jsonify(uni_list)
            except Exception as e:
                return jsonify({"error": str(e)})
        return jsonify({"error": "The request parameters are either incorrect or missing"})
    except Exception as e:
        pass
    return jsonify(uni_list)


@app.route('/api/v1/spiderFilterDetails', methods=['GET'])
def spiderFilterDetails():
    spider_details = set()
    response = {}
    response['component_name'] = ''
    response['component_type'] = ''
    response['option'] = ''
    response['nodes'] = []
    response['links'] = []
    '''
    Query for spider details
    -> All rows where the component name is either in called or calling
    -> Based on where the component name is -> Tag the relationship line as either Parent or Child
    -> In the label name of the child nodes must append the component_type in paranthesis as well
    -> two nodes A -> X can have both relationships parent/child
    '''

    try:
        response['component_name'] = request.args.get('component_name')
        response['component_type'] = [item["component_type"] for item in cursor if item["component_name"] == response['component_name']][0]
        # response['component_type'] = request.args.get('component_type')
        response['option'] = request.args.get('filter')
        # print("OPTION", response['option'])
        response['nodes'] = []
        response['links'] = []
        if response['component_name'].__contains__("HASH"):  # HOT FIX FOR & response
            response['component_name'] = response['component_name'].replace("HASH", "#")
        # if response['component_name'][1] == "$":  # HOT FIX FOR & response
        #     response['component_name'] = "&" + response['component_name'][2:]

        name_type_map = {response['component_name']: response['component_type']}
        # Adding the first node of the chart
        nodes = {response['component_name']}
        # print(response['component_name'])
        if response['component_name'] is not None:
            try:
                connections = db.cross_reference_report.find({"$or": [{"$and": [
                    {"component_name": response['component_name']}, {"component_type": response['component_type']}]},
                    # {"$and": [{"called_name": response['component_name']}, {"called_type": response['component_type']},{"comments": {"$ne": "inline"}}]}]},
                    {"$and": [
                        {"called_name": response['component_name']},
                        {"called_type": response['component_type']},
                        {"comments": {"$ne": "inline"}}]}]},
                    {'_id': 0})
                # connections  = db.cross_reference_report.find({"$and": [{"$or":[{"component_name":response['component_name']},{"called_name":response['component_name']}]},{"component"}]},{'_id': 0})
                # print('count', connections.count())

                if connections.count() > 0:
                    for connection in connections:
                        # print(connection['component_name'])
                        if connection['called_name'].strip() != '':
                            # If the CALLING component's name is same as option
                            if connection['component_name'] == response['component_name']:
                                if (str(connection['called_type']).upper() == str(response['option']).upper()):
                                    if (connection['component_name'] != connection['called_name']):
                                        response['links'].append({"source": "p_" + connection['component_name'],
                                                                  "target": "p_" + connection['called_name'],
                                                                  "label": "C"})
                                    name_type_map[connection['called_name']] = connection['called_type']
                                    nodes.add(connection['called_name'])
                                if (response['option'] == "All"):
                                    if (connection['component_name'] != connection['called_name']):
                                        response['links'].append({"source": "p_" + connection['component_name'],
                                                                  "target": "p_" + connection['called_name'],
                                                                  "label": "C"})
                                    name_type_map[connection['called_name']] = connection['called_type']
                                    nodes.add(connection['called_name'])
                            # If the CALLED component's name is same as option
                            else:
                                if (str(connection['component_type']).upper() == str(response['option'])):
                                    if (connection['component_name'] != connection['called_name']):
                                        response['links'].append({"source": "p_" + connection['called_name'],
                                                                  "target": "p_" + connection['component_name'],
                                                                  "label": "P"})
                                    name_type_map[connection['component_name']] = connection['component_type']

                                    nodes.add(connection['component_name'])
                                elif (response['option'] == "All"):
                                    if (connection['component_name'] != connection['called_name']):
                                        response['links'].append({"source": "p_" + connection['called_name'],
                                                                  "target": "p_" + connection['component_name'],
                                                                  "label": "P"})
                                    name_type_map[connection['component_name']] = connection['component_type']

                                    nodes.add(connection['component_name'])

                    for node in nodes:
                        response['nodes'].append({"id": "p_" + node, "label": node + ' (' + name_type_map[node] + ')'})
                else:
                    return jsonify({"error": "the component name" + response['component_name'] + " does not exist."})
                return jsonify(response)
            except Exception as e:
                return jsonify({"error": str(e)})
        return jsonify({"error": "The request parameters are either incorrect or missing"})
    except Exception as e:
        pass
    return jsonify({"error": str(e)})


@app.route('/api/v1/getDropImp', methods=['Get'])
def getDropImp():
    # cursor = db.drop_impact.find(drop)
    data_object = {}
    data_object['data'] = []
    apname = request.args.get('option')
    if apname == "All":
        try:
            cursor = db.drop_impact.find({'type': {"$ne": "metadata"}}, {'_id': 0})
            metadata = db.drop_impact.find_one({"type": "metadata"}, {'_id': 0})
            data_object['headers'] = metadata['headers']
            for document in cursor:
                data_object['data'].append(document)
        except Exception as e:
            print('')
        return jsonify(data_object)
    else:
        try:
            cursor = db.drop_impact.find({"application": apname}, {'_id': 0})
            metadata = db.drop_impact.find_one({"type": "metadata"}, {'_id': 0})
            data_object['headers'] = metadata['headers']
            for document in cursor:
                data_object['data'].append(document)
        except Exception as e:
            print('')

        return jsonify(data_object)


@app.route("/api/v1/comment_line_report", methods=['Get'])
def comment_line_report():
    # db = client['COBOL']/api/v1/getDropImp?
    output_list = []
    apname = request.args.get('option')
    # print(cursors.count())
    # print(cursors)
    if apname == "All":
        cursors = db.cobol_output.find({'type': {"$ne": "metadata"}})
        for cursor in cursors:
            json_format = {"component_name": cursor["component_name"], "component_type": cursor["component_type"],
                           "application": cursor["application"]}
            if (json_format not in output_list):
                output_list.append(json_format)
        output_json = {"data": output_list, "headers": ["component_name", "component_type", "application"]}
        print(output_json)
        return jsonify(output_json)
    else:
        cursors = db.cobol_output.find({"application": apname})
        for cursor in cursors:
            json_format = {"component_name": cursor["component_name"], "component_type": cursor["component_type"],
                           "application": cursor["application"]}
            # print(json_format)
            if (json_format not in output_list):
                output_list.append(json_format)
        output_json = {"data": output_list, "headers": ["component_name", "component_type", "application"]}
        return jsonify(output_json)


@app.route('/api/v1/deadparalist', methods=['GET'])
def deadparalist():
    datavalue = {}
    datavalue["data"] = []
    appname = request.args.get('option')
    if appname == "All":
        try:
            headers = ["component_name", "component_type", "application", "dead_para_list", "dead_para_count",
                       "no_of_dead_lines"]
            cursor = db.master_inventory_report.find(
                {"type": {"$ne": "metadata"}, "$or": [{"component_type": "SERVLET"}, {"component_type": "JAVA_CLASS"},
                                                      {"component_type": "INTERFACE"},
                                                      {"component_type": "DATA_ACCESS_OBJECT"}],
                 "dead_para_count": {"$gt": 0}},
                {"component_name": 1, "component_type": 1, "application": appname, "dead_para_list": 1,
                 "dead_para_count": 1, "no_of_dead_lines": 1, "_id": 0})
            metadata = db.master_inventory_report.find_one({"type": "metadata"}, {"_id": 0})
            datavalue["headers"] = headers
            for record in cursor:
                datavalue["data"].append(record)
        except:
            print("")
        return jsonify(datavalue)
    else:
        try:
            headers = ["component_name", "component_type", "application", "dead_para_list", "dead_para_count",
                       "no_of_dead_lines"]
            cursor = db.master_inventory_report.find(
                {"type": {"$ne": "metadata"}, "$or": [{"component_type": "SERVLET"}, {"component_type": "JAVA_CLASS"},
                                                      {"component_type": "INTERFACE"},
                                                      {"component_type": "DATA_ACCESS_OBJECT"}], "application": appname,
                 "dead_para_count": {"$gt": 0}},
                {"component_name": 1, "component_type": 1, "application": appname, "dead_para_list": 1,
                 "dead_para_count": 1,
                 "no_of_dead_lines": 1, "_id": 0})
            metadata = db.master_inventory_report.find_one({"type": "metadata"}, {"_id": 0})
            datavalue["headers"] = headers
            for record in cursor:
                datavalue["data"].append(record)
        except:
            print("")
        return jsonify(datavalue)


@app.route('/api/v1/applicationList', methods=['GET'])
def applicationList():
    appln_name_set = set()
    try:
        list_of_programs = db.master_inventory_report.distinct("application")
        # list_of_programs = db.screenfields.distinct("application")
        for appln in list_of_programs:
            if appln != None:
                appln_name_set.add(appln)
        applist = sorted(list(appln_name_set))
        applist.insert(0, "All")
        return jsonify({"application_list": applist})
    except Exception as e:
        print('Error:', str(e))
        return jsonify({"status": "failure", "reason": "Error: " + str(e)})


@app.route('/api/v1/MissingAppList', methods=['GET'])
def MissingAppList():
    appln_name_set = set()
    applist = []
    try:
        list_of_programs = db.missing_components_report.distinct("application")

        for appln in list_of_programs:
            if appln != None:
                appln_name_set.add(appln)

        applist = sorted(list(appln_name_set))
        applist.insert(0, "All")
        return jsonify({"application_list": applist})
    except Exception as e:
        print('Error:', str(e))
        return jsonify({"status": "failure", "reason": "Error: " + str(e)})


@app.route('/api/v1/dropAppList', methods=['GET'])
def dropAppList():
    appln_name_set = set()
    try:
        list_of_programs = db.drop_impact.distinct("application")

        for appln in list_of_programs:
            if appln != None:
                appln_name_set.add(appln)

        applist = sorted(list(appln_name_set))
        applist.insert(0, "All")
        return jsonify({"application_list": applist})
    except Exception as e:
        print('Error:', str(e))
        return jsonify({"status": "failure", "reason": "Error: " + str(e)})


@app.route('/api/v1/masterInventory', methods=['GET'])
def masterInventory():
    data_object = {}
    data_object['data'] = []
    appname = request.args.get("option")
    if appname == "All":
        try:
            cursor = db.master_inventory_report.find({'type': {"$ne": "metadata"}}, {'_id': 0})
            metadata = db.master_inventory_report.find_one({"type": "metadata"}, {'_id': 0})
            data_object['headers'] = metadata['headers']
            for document in cursor:
                data_object['data'].append(document)
        except Exception as e:
            print('')
        return jsonify(data_object)
    else:
        try:
            cursor = db.master_inventory_report.find({"application": appname}, {'_id': 0})
            metadata = db.master_inventory_report.find_one({"type": "metadata"}, {'_id': 0})
            data_object['headers'] = metadata['headers']
            for document in cursor:
                data_object['data'].append(document)
        except Exception as e:
            print('')
        return jsonify(data_object)


@app.route('/api/v1/bre_2', methods=['GET'])
def bre_2():
    datavalue = {}
    datavalue["data"] = []
    header = ["pgm_name", "para_name", "source_statements", "rule_description", "rule_category", "Rule",
              "rule_relation"]
    option = request.args.get('option')

    try:
        if option == "":
            datavalue["headers"] = header
            return jsonify(datavalue)
        else:
            #            option = option.split('.')
            #            option = option[0]
            # print(option)
            cursor = db.rule_report.find({"pgm_name": option}, {"_id": 0}).sort('_id')
            datavalue["headers"] = header
            for record in cursor:
                if record["para_name"].lower().__contains__("section."):
                    record['para_name'] = record['para_name'].lower().replace("section.", "").upper()

                datavalue["data"].append(record)
            # print(datavalue)
    except:
        print("")
    return jsonify(datavalue)


@app.route('/api/v1/bre', methods=['GET'])
def bre():
    datavalue = {}
    datavalue["data"] = []
    option = request.args.get('option')
    header = ["fragment_Id", "para_name", "source_statements", "rule_category", "statement_group", "parent_rule_id"]
    try:
        if option == "":
            datavalue["headers"] = header
            return jsonify(datavalue)
        else:
            option = option.split('.')
            option = option[0]
            cursor = db.bre_rules_report.find({"pgm_name": option + '.'}, {"_id": 0}).sort('_id')
            datavalue["headers"] = header
            for record in cursor:
                datavalue["data"].append(record)
            return jsonify(datavalue)
    except:
        print("")


@app.route('/api/v1/chartsAPI', methods=['GET'])
def chartsAPI():
    # List of all applications present in master inventory
    APPLICATIONS_MASTER_LIST = []

    OUTPUT_DATA = {'techstack_vs_component_count': {},
                   'technical_debt': {},
                   'orphan_stats': {},
                   'app_tech_loc': {},
                   'largest_applications': {},
                   'largest_applications_dead_code': {},
                   'rules_distribution': {}
                   }

    try:
        time_largest_apps_start = timeit.default_timer()
        # Processing the list of largest applications
        applications_test = db.master_inventory_report.distinct("application", {"application": {"$nin": ["", None]}})
        # #print('List of all applications', applications_test)

        ################################################
        # Fetching all the applications and their LOC  #
        ################################################
        cursor = db.master_inventory_report.aggregate(
            [{"$match": {"application": {"$nin": ["", None]}}},
             {"$group": {"_id": {"application": "$application"}, "count": {"$sum": "$Loc"}}}])
        for ite in cursor:
            OUTPUT_DATA['largest_applications'][ite['_id']['application']] = ite['count']

        ####################################################
        # Fetching all the applications and their DEAD LOC #
        ####################################################
        cursor = db.master_inventory_report.aggregate(
            [{"$match": {"application": {"$nin": ["", None]}}},
             {"$group": {"_id": {"application": "$application"}, "count": {"$sum": "$no_of_dead_lines"}}}])
        for ite in cursor:
            OUTPUT_DATA['largest_applications_dead_code'][ite['_id']['application']] = ite['count']

        # Sorting the largest_applications field
        sorted_by_value = sorted(OUTPUT_DATA['largest_applications_dead_code'].items(), key=lambda kv: kv[1])
        print(sorted_by_value.reverse())
        OUTPUT_DATA['largest_applications_dead_code'] = []
        for element in sorted_by_value:
            APPLICATIONS_MASTER_LIST.append(element[0])
            OUTPUT_DATA['largest_applications_dead_code'].append(
                {"application_name": element[0], "no_of_dead_lines": element[1]})

        # Shortening largest_applications to display only top N largest applications
        OUTPUT_DATA['largest_applications_dead_code'] = OUTPUT_DATA['largest_applications_dead_code'][:5]

        # Sorting the largest_applications field
        sorted_by_value = sorted(OUTPUT_DATA['largest_applications'].items(), key=lambda kv: kv[1])
        print(sorted_by_value.reverse())
        OUTPUT_DATA['largest_applications'] = []
        for element in sorted_by_value:
            OUTPUT_DATA['largest_applications'].append({"application_name": element[0], "loc": element[1]})
        # Shortening largest_applications to display only top N largest applications
        OUTPUT_DATA['largest_applications'] = OUTPUT_DATA['largest_applications'][:5]

        # Processing the tech stack  vs loc data
        COMPONENT_TYPES = db.master_inventory_report.distinct("component_type",
                                                              {"component_type": {"$nin": ["", "null"]}})
        # #print('Tech Components', COMPONENT_TYPES)
        for TYPE in COMPONENT_TYPES:
            loc = 0
            try:
                # cursor = db.master_inventory_report.aggregate(
                #    [{"$match": {"component_type": TYPE}}, {"$group": {"_id": "null", "count": {"$sum": "$Loc"}}}])
                # for row in cursor:
                #    loc = row['count']
                #    #print(TYPE,loc)
                # OUTPUT_DATA['techstack_vs_loc'][TYPE] = loc

                component_count = db.master_inventory_report.count_documents({"component_type": TYPE})
                OUTPUT_DATA['techstack_vs_component_count'][TYPE] = component_count
            except Exception as e:
                print('Error while fetching Tech stack vs LOC:  ' + str(e))
                print(traceback.format_exc())
        time_largest_apps_stop = timeit.default_timer()
        print('Largest application LOC and DLOC counting took ', (time_largest_apps_stop - time_largest_apps_start),
              '(s)')

        # Processing the orphan vs total components
        time_orphan_report_start = timeit.default_timer()
        try:
            OUTPUT_DATA['orphan_stats']['total_no_components'] = db.master_inventory_report.count_documents({}) - 1
            OUTPUT_DATA['orphan_stats']['orphan_components'] = db.orphan_report.count_documents({}) - 1
            OUTPUT_DATA['orphan_stats']['active_components'] = OUTPUT_DATA['orphan_stats']['total_no_components'] - \
                                                               OUTPUT_DATA['orphan_stats']['orphan_components']

        except Exception as e:
            print('Error while fetching orphan stats:  ' + str(e))
            # print(traceback.format_exc())

        time_orphan_report_stop = timeit.default_timer()
        # print('Orphan report took ', (time_orphan_report_stop - time_orphan_report_start), '(s)')

        # Processing technical debts
        time_technical_debt_start = timeit.default_timer()
        total_loc = db.master_inventory_report.aggregate(
            [{"$match": {}}, {"$group": {"_id": "null", "count": {"$sum": "$Loc"}}}])
        for row in total_loc:
            total_loc = row['count']
        total_dead_loc = db.master_inventory_report.aggregate(
            [{"$match": {}}, {"$group": {"_id": "null", "count": {"$sum": "$no_of_dead_lines"}}}])
        for row in total_dead_loc:
            total_dead_loc = row['count']
        total_active_loc = total_loc - total_dead_loc

        OUTPUT_DATA['technical_debt']['total_loc'] = total_loc
        OUTPUT_DATA['technical_debt']['total_dead_loc'] = int(total_dead_loc)
        OUTPUT_DATA['technical_debt']['total_active_loc'] = int(total_active_loc)
        time_technical_debt_stop = timeit.default_timer()
        # print('Technical debt took ', (time_technical_debt_stop - time_technical_debt_start), '(s)')

        # Fetch all the list of Applications
        app_list = applications_test
        sorted(APPLICATIONS_MASTER_LIST)
        # #print('Should be sorted..', APPLICATIONS_MASTER_LIST)
        APPLICATIONS_MASTER_LIST = copy.deepcopy(sorted(APPLICATIONS_MASTER_LIST))
        # Processing application vs tech stack vs LOC
        time_app_tech_loc_start = timeit.default_timer()
        for TYPE in COMPONENT_TYPES:
            OUTPUT_DATA['app_tech_loc'][TYPE] = {}
            for app in app_list:
                OUTPUT_DATA['app_tech_loc'][TYPE][app] = 0
            for APP in APPLICATIONS_MASTER_LIST[:14]:
                loc = 0
                try:
                    cursor = db.master_inventory_report.aggregate(
                        [{"$match": {"$and": [{"application": APP}, {"component_type": TYPE}]}},
                         {"$group": {"_id": "null", "count": {"$sum": "$Loc"}}}])
                    for row in cursor:
                        loc = row['count']
                        OUTPUT_DATA['app_tech_loc'][TYPE][APP] = loc
                except Exception as e:
                    print('Error while fetching Tech stack vs LOC:  ' + str(e))
                    # print(traceback.format_exc())
        time_app_tech_loc_stop = timeit.default_timer()
        # print('App tech loc took ', (time_technical_debt_stop - time_technical_debt_start), '(s)')

        # Processing the rule categories
        # LIST_OF_RULE_CATEGORIES = db.bre_rules_report.distinct("rule_category",
        #                                                        {"rule_category": {"$nin": ["", "null"]}})
        #
        # for each_rule in LIST_OF_RULE_CATEGORIES:
        #     count = db.bre_rules_report.count_documents({"rule_category": each_rule}) - 1
        #     OUTPUT_DATA['rules_distribution'][each_rule] = count
        # a = list(db.bre_rules_report.aggregate([
        #     {"$group": {
        #         "_id": {"$toLower": "$rule_category"},
        #         "count": {"$sum": 1}
        #     }},
        #     {"$group": {
        #         "_id": "null",
        #         "counts": {
        #             "$push": {"k": "$_id", "v": "$count"}
        #         }
        #     }},
        #     {"$replaceRoot": {
        #         "newRoot": {"$arrayToObject": "$counts"}
        #     }}
        # ]))
        # # print("new_data", a)
        # b = (dict(ChainMap(*a)))
        # OUTPUT_DATA['rules_distribution'] = b
        return jsonify(OUTPUT_DATA)




    except Exception as e:
        print(str(e))
        # print(traceback.format_exc())
        return jsonify({"status": "failure", "reason": "error: " + str(e)})


@app.route('/api/v1/rulesChartAPI', methods=['GET', 'POST'])
def rulesChartAPI():
    OUTPUT_DATA = {'rules_distribution': {}}

    a = list(db.rule_report.aggregate([
        {"$group": {
            "_id": {"$toLower": "$rule_category"},
            "count": {"$sum": 1}
        }},
        {"$group": {
            "_id": "null",
            "counts": {
                "$push": {"k": "$_id", "v": "$count"}
            }
        }},
        {"$replaceRoot": {
            "newRoot": {"$arrayToObject": "$counts"}
        }}
    ]))
    # print("new_data", a)
    b = (dict(ChainMap(*a)))
    OUTPUT_DATA['rules_distribution'] = b
    return jsonify(OUTPUT_DATA)


@app.route('/api/v1/businessConnectedRules', methods=['GET', 'POST'])
def buisnessConnected():
    b = list(db.rule_report.aggregate([
        {"$match": {"$or": [{"rule_category": "Business Rule"}, {"rule_category": "Connected Business Rule"}]}},
        {"$group": {
            "_id": {"$toLower": "$application"},
            "count": {"$sum": 1}
        }},
        {"$group": {
            "_id": "null",
            "counts": {
                "$push": {"k": "$_id", "v": "$count"}
            }
        }},
        {"$replaceRoot": {
            "newRoot": {"$arrayToObject": "$counts"}
        }}
    ]))
    c = (dict(ChainMap(*b)))
    final_data = c
    print(final_data)
    return jsonify({"businessConnectedRules": {"Business Rule": final_data}})


@app.route('/api/v1/nameList', methods=['GET'])
def nameList():
    selectedApplication = request.args.get('selectedApplication')
    flag = request.args.get('flag')
    flag = "def"
    if flag == "def":
        if selectedApplication == "All":
            cursor = db.screenfields.find({'type': {"$ne": "metadata"}}, {"filename": 1, '_id': 0})
            output = []
            for document in cursor:
                output.append(document["filename"])
            output = list(set(output))
            return jsonify({'name_list': output})
        else:
            cursor = db.screenfields.find({'type': {"$ne": "metadata"},"application": selectedApplication}, {"filename": 1, '_id': 0})
            output = []
            for document in cursor:
                output.append(document["filename"])
            output = list(set(output))
            return jsonify({'name_list': output})
    elif flag == "val":
        if selectedApplication == "All":
            cursor = db.validation_report.find({'type': {"$ne": "metadata"}}, {"filename": 1, '_id': 0})
            output = []
            for document in cursor:
                output.append(document["filename"])
            output = list(set(output))
            return jsonify({'name_list': output})
        else:
            cursor = db.validation_report.find({'type': {"$ne": "metadata"},"application": selectedApplication}, {"filename": 1, '_id': 0})
            output = []
            for document in cursor:
                output.append(document["filename"])
            output = list(set(output))
            return jsonify({'name_list': output})
        
@app.route('/api/v1/procFlowChart_RD', methods=['GET', 'POST'])
def procFlowChart_RD():
    global para_name
    para_name = request.args.get('para_name')
    component_name = request.args.get('component_name')
    print(component_name)
    try:
        if para_name.__contains__("["):
            flowchart_metadata = db.para_flowchart_data.find_one(
                {"$and": [{"component_name": para_name.split("[")[1][:-1]}, {"para_name": para_name.split("[")[0]}]},
                {'_id': 0})

        elif para_name.__contains__("(JAVA_SERVER_PAGE)"):
            flowchart_metadata = None

        # if para_name.__contains__("("):
        #     flowchart_metadata = db.translated_flowchart.find_one(
        #         {"$and": [{"component_name": para_name.split("(")[1][:-1]}, {"para_name": para_name.split("(")[0]}]},
        #         {'_id': 0})

        else:
            print(component_name)
            flowchart_metadata = db.translated_flowchart.find_one(
                {"$and": [{"component_name": component_name}, {"para_name": para_name}]},
                {'_id': 0})

        # flowchart_metadata = db.translated_flowchart.find_one(
        #     {"$and": [{"component_name": component_name+".vb"}, {"para_name": para_name}]},{'_id': 0})

        if flowchart_metadata is None:

            return jsonify({"status": "unavailable"})
        else:
            flowchart_metadata['status'] = "available"
            return jsonify(flowchart_metadata)

    except Exception as e:
        print(e)
        return jsonify({"error": str(e)})


@app.route('/api/v1/expandedcomponentCode', methods=['GET'])
def expandedgetCode():
    component_name = request.args.get('component_name')
    component_type = request.args.get('component_type')
    component_line = request.args.get('line')
    # print("Hi",type(component_line))
    print(para_name_list)
    if para_name_list != []:
        para_name = para_name_list.pop()
    else:
        para_name = component_name

    # para_name = para_name_list[-1]
    # print(component_name,component_type)
    if para_name.__contains__("(JAVA_SERVER_PAGE)"):
        component_name = para_name.split("(")[0] + ".jsp"
    else:
        component_name = para_name.split("[")[1].split("]")[0]

    start = timeit.default_timer()

    cursy = db.codebase.find_one({'component_name': component_name},
                                 {"_id": 0})
    end = timeit.default_timer()
    if component_line != None:
        replaced_lines = ""
        for k in cursy["codeString"].split("<br>"):
            if k.__contains__(component_line.split("[")[0]):
                print("here")
                replaced_lines = replaced_lines + '<span id=ExpCanvasScroll>' + component_line.split("[")[0] + '<br>' + "</span>"
            else:
                replaced_lines = replaced_lines + k + "<br>"
        cursy["codeString"] = replaced_lines
    cursy['completed_in'] = end - start
    para_name_list.clear()
    return jsonify(cursy)


@app.route('/api/v1/validationreport', methods=['GET'])
def validationreport():
    data_object = {}
    data_object['data'] = []
    apname = request.args.get('option')
    print(apname)
    filename = request.args.get('selectedName')
    print(filename)
    if apname == "All":
        try:
            cursor = db.validation_report.find({"filename": filename},
                                               {"_id": 0})
            metadata = db.validation_report.find_one({"type": "metadata"}, {'_id': 0})
            data_object['headers'] = metadata['headers']
            # print("cursor",cursor)
            for document in cursor:
                # print(document)
                data_object['data'].append(document)
            # print(data_object)
        except Exception as e:
            print(e)
        return jsonify(data_object)
    else:
        try:
            cursor = db.validation_report.find({"application": apname, "filename": filename},
                                               {"_id": 0})

            metadata = db.validation_report.find_one({"type": "metadata"}, {'_id': 0})
            data_object['headers'] = metadata['headers']
            # print("cursor",cursor)
            for document in cursor:
                # print(document)
                # del document['file_name']
                data_object['data'].append(document)
            # print(data_object)
        except Exception as e:
            print(e)
        return jsonify(data_object)


@app.route("/api/v1/usernameValidation", methods=["post"])
def usernameValidation():
    user = request.get_data()
    value = user.decode('utf-8')
    print("username", user, value)
    # value=(value)
    value = eval(value)
    print(value, type(value))
    username = value["username"]
    password = value["password"]

    outDict = {}
    if (username == "admin" and password == "admin1"):
        outDict['cred'] = "1"
    elif (username == "lcaasadmin" and password == "lcaasadmin1"):
        outDict['cred'] = "2"
    elif (username == "demouser" and password == "demouser1"):
        outDict['cred'] = "3"
    elif (username == "geuser" and password == "geuser1"):
        outDict['cred'] = "5"
    elif (username == "UPRRADMIN" and password == "UPRRPASS"):
        outDict['cred'] = "4"
    elif username.strip() == '' and not password.strip() == '':
        outDict['cred'] = "userempty"
    elif password.strip() == '' and not username.strip() == '':
        outDict['cred'] = "passwordempty"
    elif username.strip() == '' and password.strip() == '':
        outDict['cred'] = "userpassempty"
    else:
        outDict['cred'] = "user&passincorrect"

    return outDict


if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5026)
