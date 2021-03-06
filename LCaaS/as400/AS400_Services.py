from flask import Flask, request, jsonify
from pymongo import MongoClient
import json
import pytz
import datetime
import re
import traceback
from flask_cors import CORS
import timeit
import sys
import copy
from openpyxl import Workbook, load_workbook
import pandas as pd
import operator

import config1
import time

#sys.path.append(sys.argv[1])
# client = MongoClient(config1.database['mongo_endpoint_url'])
# db = client[config1.database['database_name']]

client = MongoClient('localhost', 27017)
db = client['Werner']


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
    return jsonify({"you have sent the data ":data})


@app.route('/api/v1/deadparalist', methods=['GET'])
def deadparalist():
   datavalue={}
   datavalue["data"]=[]

   try:
    headers=["component_name","component_type","dead_para_list","dead_para_count","no_of_dead_lines"]
    cursor = db.master_inventory_report.find({"type":{"$ne":"metadata"},"component_type":"RPG","dead_para_count":{"$gt":0}},{"component_name":1,"component_type":1,"dead_para_list":1,"dead_para_count":1,"no_of_dead_lines":1,"_id":0})
    metadata= db.master_inventory_report.find_one({"type":"metadata"},{"_id":0})

    datavalue["headers"]=headers
    for record in cursor:
        datavalue["data"].append(record)

   except:
       print("")
   return jsonify(datavalue)

@app.route('/api/v1/breOld', methods=['GET'])
def breReport():
   datavalue={}
   datavalue["data"]=[]
   try:
    header=["rule_id", "para_name", "rule","rule_category"]
    cursor = db.bre_rules_report.find({"type":{"$ne":"metadata"}},{"_id":0})
    metadata= db.bre_rules_report.find_one({"type":"metadata"},{"_id":0})
    datavalue["headers"]=header
    for record in cursor:
        datavalue["data"].append(record)
   except:
       print("")
   return jsonify(datavalue)


@app.route('/api/v1/bre', methods=['GET'])
def bre():
   datavalue={}
   datavalue["data"]=[]

   try:
    option = request.args.get('option')
    header=["fragment_Id", "para_name", "source_statements","rule_category","statement_group","parent_rule_id"]
    option=option.split('.')
    option=option[0]


    cursor = db.bre_rules_report.find({"pgm_name": option}, {"_id": 0}).sort("_id",1).sort("_id",1)

    datavalue["headers"]= header
    for record in cursor:
        datavalue["data"].append(record)
   except:
       print("")
   return jsonify(datavalue)

#
# @app.route('/api/v1/bre_2', methods=['GET'])
# def bre2():
#    datavalue={}
#    datavalue["data"]=[]
#
#    try:
#     option = request.args.get('option')
#     header=["pgm_name", "para_name", "source_statements","Rule",'rule_relation']
#     option=option.split('.')
#     option=option[0]
#     cursor = db.bre_report2.find({"pgm_name":option},{"_id":0})
#
#     datavalue["headers"]=header
#
#     for record in cursor:
#
#         datavalue["data"].append(record)
#
#    except:
#        print("")
#    return jsonify(datavalue)


@app.route('/api/v1/bre_2', methods=['GET'])
def bre_2():
   datavalue={}
   datavalue["data"]=[]

   try:
    option = request.args.get('option')
    header=["pgm_name", "para_name", "source_statements","rule_description","rule_category", "Rule","rule_relation"]
    option=option.split('.')
    option=option[0]
    cursor = db.bre_report2.find({"pgm_name":option},{"_id":0})

    datavalue["headers"]=header

    for record in cursor:

        datavalue["data"].append(record)

   except:
       print("")
   return jsonify(datavalue)


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




@app.route('/api/v1/glossary', methods=['GET'])
def glossary():

        data_object = {}
        data_object['data'] = []
        try:
            cursor = db.glossary.find({'type': {"$ne": "metadata"}}, {'_id': 0})
            metadata = db.glossary.find_one({"type": "metadata"}, {'_id': 0})
            data_object['headers'] = metadata['headers']
            for document in cursor:
                data_object['data'].append(document)
        except Exception as e:
            print('')
        return jsonify(data_object)


# datavalue={}
   # datavalue["data"]=[]
   #
   # try:
   #  option = request.args.get('option')
   #  #print(option)
   #  header=["component_name", "Variable", "Bussiness_Meaning"]
   #  option=option.split('.')
   #  option=option[0]
   #  cursor = db.glossary.find({"component_name":option},{"_id":0})
   #
   #  datavalue["headers"]=header
   #
   #
   #
   #  for record in cursor:
   #
   #      datavalue["data"].append(record)
   #
   # except:
   #     print("")
   # return jsonify(datavalue)

@app.route('/api/v1/uploadglossary', methods=['GET','POST'])
def uploadglossary():

        file = request.get_data()
        str_file = file.decode("utf-8")
        temp_file=list(eval(str_file))

        # temp_file = str_file.split("}")
        # print((temp_file + "}"))

        option = temp_file[0]['component_name']


        for json_dict in temp_file:
            #cursor = db.glossary.find({"component_name": json_dict["component_name"], "Variable": json_dict["Variable"]})

            if (json_dict.__contains__('Business_Meaning')):

                pass
            else:
                json_dict['Business_Meaning'] = ''

            try:

                db.glossary.update({"component_name": json_dict["component_name"],"Variable":json_dict["Variable"]},{"$set":{
                               "Business_Meaning":json_dict["Business_Meaning"]}})
            except:
                return jsonify("failure")

            continue

        return jsonify("success")


@app.route('/api/v1/updateVarDef', methods=['GET'])
def updateVarDef():
    import def_update
    #time.sleep(2)
    def_update.main()

    return jsonify("success")





@app.route('/api/v1/procFlowChart', methods=['GET'])
def procFlowChart():

    para_name = request.args.get('para_name')
    component_name = request.args.get('component_name')
    try:
        flowchart_metadata = db.para_flowchart_data.find_one(
            {"$and": [{"component_name": component_name}, {"para_name": para_name}]},{'_id': 0})

        if flowchart_metadata is None:

            return jsonify({"status":"unavailable"})
        else:
            flowchart_metadata['status'] = "available"
            return jsonify(flowchart_metadata)

    except Exception as e:
        return jsonify({"error":str(e)})

@app.route('/api/v1/procFlowChart', methods=['POST'])
def procFlowChartPOST():

    para_name = request.args.get('para_name')
    component_name = request.args.get('component_name')
    try:
        flowchart_metadata = db.para_flowchart_data.find_one(
            {"$and": [{"component_name": component_name}, {"para_name": para_name}]},{'_id': 0})
        #print(flowchart_metadata, para_name, component_name)
        if flowchart_metadata is None:

            return jsonify({"status":"unavailable"})
        else:
            flowchart_metadata['status'] = "available"
            return jsonify(flowchart_metadata)

    except Exception as e:
        return jsonify({"error":str(e)})



@app.route('/api/v1/procFlowChart_RD', methods=['GET'])
def procFlowChart_RD():

    para_name = request.args.get('para_name')
    component_name = request.args.get('component_name')
    try:
        flowchart_metadata = db.translated_flowchart.find_one(
            {"$and": [{"component_name": component_name}, {"para_name": para_name}]},{'_id': 0})

        if flowchart_metadata is None:

            return jsonify({"status":"unavailable"})
        else:
            flowchart_metadata['status'] = "available"
            return jsonify(flowchart_metadata)

    except Exception as e:
        return jsonify({"error":str(e)})

@app.route('/api/v1/procFlowChart_RD', methods=['POST'])
def procFlowChartPOST_RD():

    para_name = request.args.get('para_name')
    component_name = request.args.get('component_name')
    try:
        flowchart_metadata = db.translated_flowchart.find_one(
            {"$and": [{"component_name": component_name}, {"para_name": para_name}]},{'_id': 0})
        #print(flowchart_metadata, para_name, component_name)
        if flowchart_metadata is None:

            return jsonify({"status":"unavailable"})
        else:
            flowchart_metadata['status'] = "available"
            return jsonify(flowchart_metadata)

    except Exception as e:
        return jsonify({"error":str(e)})



@app.route('/api/v1/componentCode', methods=['GET'])
def getCode():
    component_name = request.args.get('component_name')
    component_type = request.args.get('component_type')
    #print(component_name)
    #print(component_type)
    #if component_type!='scr':
    component_type = request.args.get('component_type').upper()

    #Check if component name has an extension.
    if not re.match('.*[.].*', component_name.strip()):
       # print(component_name)

        #Component does not have extension,
        master_component_types = {'COBOL': 'RPG', 'CL':'CL','RPG':'RPG'} #This line to be copied from the script
        #Search for component extension via lookup and
        if component_type in master_component_types:
            component_name = component_name.strip() +'.'+master_component_types[component_type]
            #print(component_name)
    if component_type=="BMS":
        start = timeit.default_timer()
        cursy = db.codebase.find_one({"$and": [{'component_name': component_name+".DSPF"}, {'component_type': "DSPF"}]},
                                     {"_id": 0})
        end = timeit.default_timer()
        # cursy['completed_in']=end-start
        return jsonify(cursy)
    else:
        component_type="RPG"

    start = timeit.default_timer()
    cursy = db.codebase.find_one({"$and":[{'component_name': component_name},{'component_type': component_type}]},{"_id":0})
    end = timeit.default_timer()
    #cursy['completed_in']=end-start
    return jsonify(cursy)



@app.route('/api/v1/generate/orphanReport', methods=['GET'])
def generateOrphanReport():
    # Fetch all unique items from Master  Inv.
    master_inv_list = db.master_inventory_report.distinct("component_name")

    # Fetch all the items in X-Reference called components
    cross_reference = db.cross_reference_report.distinct("called_name")

    # TEST VARIABLES
    # master_inv_list = ['A','B','C','D','F']
    # cross_reference = ['X','Y','Z','D','F','C']

    orphan_list = set(master_inv_list) - set(cross_reference)

    missing_list = set(cross_reference) - set(master_inv_list)

    print('Orphan list:', orphan_list, 'Missing list:', missing_list)

    # Fetch Orphan TYPE from X-Ref

    PARAMS = {"$or": []}
    for ite in orphan_list:
        PARAMS['$or'].append({"component_name": ite})

    cursor = db.master_inventory_report.find(PARAMS, {'_id': 0})

    for row in cursor:
        print(row)

    return jsonify({"elements": db.master_inventory_report.distinct("called_name")})

# @app.route('/api/v1/updateApplicationNames', methods=['GET'])
# def updateApplicationNames():
#     try:
#         UpdateApplicationNames.updateMasterInventoryAPPNAME()
#         UpdateApplicationNames.updateCrossReferenceAPPNAME_CALLING()
#         UpdateApplicationNames.updateCrossReferenceAPPNAME_CALLED()
#         UpdateApplicationNames.save()
#         return jsonify({"success":"yeah"})
#     except Exception as e:
#         return jsonify({"failure":""+str(e)})

@app.route('/api/v1/chartsAPI', methods=['GET'])
def chartsAPI():

    #List of all applications present in master inventory
    APPLICATIONS_MASTER_LIST = []

    OUTPUT_DATA = {'techstack_vs_component_count': {},
                   'technical_debt': {},
                   'orphan_stats': {},
                   'app_tech_loc': {},
                   'largest_applications': {},
                   'largest_applications_dead_code': {},
                   'rules_distribution':{}
                   }

    try:
        time_largest_apps_start=timeit.default_timer()
        #Processing the list of largest applications
        applications_test = db.master_inventory_report.distinct("application",{ "application" : { "$nin" : ["", None] } })
        print('List of all applications',applications_test)

        ################################################
        # Fetching all the applications and their LOC  #
        ################################################
        cursor = db.master_inventory_report.aggregate(
            [{"$match":{ "application" : { "$nin" : ["", None] } }},{"$group": {"_id": {"application": "$application"}, "count": {"$sum": "$Loc"}}}])
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
            OUTPUT_DATA['largest_applications_dead_code'].append({"application_name": element[0], "no_of_dead_lines": element[1]})

        # Shortening largest_applications to display only top N largest applications
        OUTPUT_DATA['largest_applications_dead_code'] = OUTPUT_DATA['largest_applications_dead_code'][:5]

        #Sorting the largest_applications field
        sorted_by_value = sorted(OUTPUT_DATA['largest_applications'].items(), key=lambda kv: kv[1])
        print(sorted_by_value.reverse())
        OUTPUT_DATA['largest_applications'] = []
        for element in sorted_by_value:
            OUTPUT_DATA['largest_applications'].append({"application_name":element[0],"loc":element[1]})
        #Shortening largest_applications to display only top N largest applications
        OUTPUT_DATA['largest_applications'] =  OUTPUT_DATA['largest_applications'][:5]

        # Processing the tech stack  vs loc data
        COMPONENT_TYPES = db.master_inventory_report.distinct("component_type",{ "component_type" : { "$nin" : ["", "null"] } })
        print('Tech Components',COMPONENT_TYPES)
        for TYPE in COMPONENT_TYPES:
            loc = 0
            try:
                #cursor = db.master_inventory_report.aggregate(
                #    [{"$match": {"component_type": TYPE}}, {"$group": {"_id": "null", "count": {"$sum": "$Loc"}}}])
                #for row in cursor:
                #    loc = row['count']
                #    print(TYPE,loc)
                #OUTPUT_DATA['techstack_vs_loc'][TYPE] = loc
                
                component_count = db.master_inventory_report.count_documents({"component_type": TYPE})
                OUTPUT_DATA['techstack_vs_component_count'][TYPE] = component_count
            except Exception as e:
                print('Error while fetching Tech stack vs LOC:  ' + str(e) )
                print(traceback.format_exc())
        time_largest_apps_stop = timeit.default_timer()
        print('Largest application LOC and DLOC counting took ',(time_largest_apps_stop-time_largest_apps_start),'(s)')


        # Processing the orphan vs total components
        time_orphan_report_start = timeit.default_timer()
        try:
            OUTPUT_DATA['orphan_stats']['total_no_components'] = db.master_inventory_report.count_documents({}) -1
            OUTPUT_DATA['orphan_stats']['orphan_components'] = db.orphan_report.count_documents({}) -1
            OUTPUT_DATA['orphan_stats']['active_components'] = OUTPUT_DATA['orphan_stats']['total_no_components'] - OUTPUT_DATA['orphan_stats']['orphan_components']

        except Exception as e:
            print('Error while fetching orphan stats:  ' + str(e))
            print(traceback.format_exc())

        time_orphan_report_stop = timeit.default_timer()
        print('Orphan report took ',(time_orphan_report_stop - time_orphan_report_start),'(s)')



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
        print('Technical debt took ', (time_technical_debt_stop - time_technical_debt_start), '(s)')


        #Fetch all the list of Applications
        app_list = applications_test
        sorted(APPLICATIONS_MASTER_LIST)
        print('Should be sorted..',APPLICATIONS_MASTER_LIST)
        APPLICATIONS_MASTER_LIST =copy.deepcopy(sorted(APPLICATIONS_MASTER_LIST))
        #Processing application vs tech stack vs LOC
        time_app_tech_loc_start = timeit.default_timer()
        for TYPE in COMPONENT_TYPES:
            OUTPUT_DATA['app_tech_loc'][TYPE]={}
            for app in app_list:
                OUTPUT_DATA['app_tech_loc'][TYPE][app]=0
            for APP in APPLICATIONS_MASTER_LIST[:10]:
                loc = 0
                try:
                    cursor = db.master_inventory_report.aggregate(
                        [{"$match": {"$and": [{"application":APP},{"component_type":TYPE}]}}, {"$group": {"_id": "null", "count": {"$sum": "$Loc"}}}])
                    for row in cursor:
                        loc = row['count']
                        OUTPUT_DATA['app_tech_loc'][TYPE][APP] = loc
                except Exception as e:
                    print('Error while fetching Tech stack vs LOC:  ' + str(e))
                    print(traceback.format_exc())
        time_app_tech_loc_stop = timeit.default_timer()
        print('App tech loc took ', (time_technical_debt_stop - time_technical_debt_start), '(s)')
        
        
        #Processing the rule categories
        LIST_OF_RULE_CATEGORIES = db.bre_rules_report.distinct("rule_category",
                                                              {"rule_category": {"$nin": ["", "null"]}})

        for each_rule in LIST_OF_RULE_CATEGORIES:
            count = db.bre_rules_report.count_documents({"rule_category":each_rule}) -1
            OUTPUT_DATA['rules_distribution'][each_rule] = count
        
        
        return jsonify(OUTPUT_DATA)


    except Exception as e:
        print(str(e))
        print(traceback.format_exc())
        return jsonify({"status": "failure", "reason": "error: " + str(e)})


@app.route('/api/v1/cyclomaticComplexity', methods=['GET', 'POST'])
def cycComplex():
    applications = {}
    application = []
    orphan_data1 = []
    cursor = db.master_inventory_report.find({"component_type": "RPG"})
    for document in cursor:
        orphan_data1.append(document)

    for items in orphan_data1:
        application.append(items['application'])
    print(application)

    meta_data = []
    for i in range(0, len(application)):
        if application[i] not in application[i + 1:]:
            meta_data.append(application[i])
    print("meta_data",meta_data)

    data={}
    data_list =[]
    final = {}
    for i in meta_data:
        count=0
        for j in orphan_data1:
            if i==j['application']:
                #print
                # print("cyck",j['cyclomatic_complexity'])
                if(j['cyclomatic_complexity']!=''):
                    count=count+int(j['cyclomatic_complexity'])
                #print('count',count)
        data[i] = count
        data_list.append({"application_name": i, "cyclomatic_complexity": count})
    a=sorted(data_list, key=operator.itemgetter('cyclomatic_complexity'))
    pb= copy.deepcopy(reversed(a))

    mylist=[]
    for all in pb:
        mylist.append(all)
    #print('abcd',mylist)
    #print(pb)
    final["cyclomatic_complexity"]=mylist
    #print('final', final)

    #print('data',data)

    sorted_d={k: v for k, v in sorted(final.items(), key=lambda item: item[0])}
    print('sorted_d',sorted_d)

    # sorted_d = sorted(data.items(), key=operator.itemgetter(0))
    # print(sorted_d)
    todict = {}
    # for i in range(0, len(sorted_d), 2):
    #     todict[sorted_d[i]] = sorted_d[i + 1]
    # print('todict', todict)
    # sorted_d['a']=1
    # sorted_d['b']=2
    # sorted_d['c']=3
    # sorted_d['d']=4
    # sorted_d['e']=5
    # sorted_d['f']=6
    # print(sorted_d)
    first10pairs = {k: sorted_d[k] for k in sorted(sorted_d.keys())[:10]}
    print(first10pairs)

    return jsonify(first10pairs)


@app.route('/api/v1/businessConnectedRules', methods=['GET', 'POST'])
def buisnessConnected():
    orphan_data1 = []
    application = []
    cursor = db.master_inventory_report.find({"component_type": "RPG"})
    for document in cursor:
        orphan_data1.append(document)

    for items in orphan_data1:
        application.append(items['application'])
    #print(application)

    meta_data = []
    for i in range(0, len(application)):
        if application[i] not in application[i + 1:]:
            meta_data.append(application[i])
    #print("meta_data",meta_data)


    app_pgm={}
    for apps in meta_data:
        #print(apps)
        pgm = []
        for vals in orphan_data1:
            if apps==vals['application']:
                program = vals['component_name']
                sep = '.'
                text = program.split(sep, 1)[0]
                pgm.append(text)
                #print(pgm)
        app_pgm[apps]=pgm
        #print(app_pgm)



    bre_data = []
    cursor1 = db.bre_rules_report.find({"type":{"$ne":"metadata"}},{"_id":0})
    for document in cursor1:
        bre_data.append(document)
    #print('all',bre_data)

    buisiness = {}
    connected_buisiness = {}
    final_data = {}
    for key1, val in app_pgm.items():
        br_count = 0
        cbr_count = 0
        for each in val:
            query = db.bre_rules_report.find({'$and' : [{"pgm_name" : each}, {"rule_category" : "Business Rule"}]}).count()
            query1 = db.bre_rules_report.find({'$and' : [{"pgm_name" : each}, {"rule_category" : "Connected Business Rule"}]}).count()
            br_count = br_count+query
            cbr_count = cbr_count+query1
        #print('final_key',count,key1)
        buisiness[key1]=br_count
        connected_buisiness[key1]=cbr_count
        final_data[key1] = br_count+cbr_count
    #print('buisiness_connected',buisiness_connected)
    sorted_dict = dict( sorted(final_data.items(), key=operator.itemgetter(1),reverse=True))
    print('sorted_dict',sorted_dict)
    sorted_d = {k: v for k, v in sorted(buisiness.items(), key=lambda item: item[0])}
    sorted_data = {k: v for k, v in sorted(connected_buisiness.items(), key=lambda item: item[0])}
    sorted_final = {k: v for k, v in sorted(final_data.items(), key=lambda item: item[0])}
    first10pairs_buisiness = {k: sorted_d[k] for k in sorted(sorted_d.keys())[:10]}
    first10pairs_buisiness_connected = {k: sorted_data[k] for k in sorted(sorted_data.keys())[:10]}
    first10pairs_final = {k: sorted_dict[k] for k in sorted(sorted_dict.keys())[:10]}
    ordered_dict=dict( sorted(first10pairs_final.items(), key=operator.itemgetter(1),reverse=True))

    #return jsonify({"businessConnectedRules":{"Business Rule" : first10pairs_buisiness, "Connected Business Rule" : first10pairs_buisiness_connected}})
    return jsonify({"businessConnectedRules":{"Business Rule" : ordered_dict}})

#
# @app.route('/api/v1/inboundOutbound', methods=['GET', 'POST'])
# def inbboundOutbound():
#         orphan_data1 = []
#         calling_name=[]
#         cursor = db.cross_reference_report.find({"type":{"$ne":"metadata"}},{"_id":0})
#         for document in cursor:
#             orphan_data1.append(document)
#
#         for inb in orphan_data1:
#             try:
#                 calling_name.append(inb['calling_app_name'])
#             except:
#                 print('error')
#         #print("1",calling_name)
#
#
#         meta_data = []
#         for i in range(0, len(calling_name)):
#             if calling_name[i] not in calling_name[i + 1:]:
#                 meta_data.append(calling_name[i])
#         print("meta_data",meta_data)
#
#         called_name=[]
#         for inb in orphan_data1:
#             try:
#                 #print(inb)
#                 called_name.append(inb['called_app_name'])
#             except Exception as e:
#                 #inb['called_app_name'] = ""
#                 pass
#         print((called_name))
#
#         meta_data1 = []
#         for i in range(0, len(called_name)):
#             if called_name[i] not in called_name[i + 1:]:
#                 meta_data1.append(called_name[i])
#         #print("meta_data1",meta_data1)
#
#
#         # inbound_dict={}
#         # for i in meta_data:
#         #     try:
#         #         inbound_list = []
#         #         query=db.cross_reference_report.find({"$and":[{"calling_app_name" : i} ]})
#         #         for j in query:
#         #             # if i==j['called_app_name']:
#         #             #     print(" ")
#         #             # elif j['called_app_name'].upper() not in inbound_list:
#         #             #print("gjh", inbound_list)
#         #             inbound_list.append(j['called_app_name'].upper())
#         #             #print("hi", len(inbound_list))
#         #
#         #         print("hi",len(inbound_list))
#         #         inbound_dict[i]=len(inbound_list)
#         #
#         #     except KeyError as e:
#         #         j['called_app_name'] = ""
#         #         print("except")
#         #         pass
#         # #print(inbound_dict)
#         # sorted_d = {k: v for k, v in sorted(inbound_dict.items(), key=lambda item: item[0])}
#         # first10pairs_inbound = {k: sorted_d[k] for k in sorted(sorted_d.keys())[:10]}
#
#         inbound_dict = {}
#         for a in meta_data:
#             inbound_list = []
#             for b in orphan_data1:
#                 try:
#                     if a == b['calling_app_name']:
#                         if b['called_app_name'] not in inbound_list:
#                             inbound_list.append(b['called_app_name'])
#                 except Exception as e:
#                     print("")
#             print('list',inbound_list)
#             inbound_dict[a]=len(inbound_list)
#         print('inbond',inbound_dict)
#         sorted_d = {k: v for k, v in sorted(inbound_dict.items(), key=lambda item: item[0])}
#         first10pairs_inbound = {k: sorted_d[k] for k in sorted(sorted_d.keys())[:10]}
#         ordered_dict_inbound = dict(sorted(first10pairs_inbound.items(), key=operator.itemgetter(1), reverse=True))
#
#
#
#         outbound_dict = {}
#         for p in meta_data1:
#             outbound_list = []
#             for q in orphan_data1:
#
#                 try:
#                     if p == q['called_app_name']:
#                         print('a', q['called_app_name'])
#                         if q['calling_app_name'] not in outbound_list:
#                             outbound_list.append(q['calling_app_name'])
#                 except Exception as e:
#                     print("")
#             print('list',outbound_list)
#             outbound_dict[p]=len(outbound_list)
#         print('outbound',outbound_dict)
#         sorted_data = {key1: value1 for key1, value1 in sorted(outbound_dict.items(), key=lambda item: item[0])}
#         first10pairs_outbound = {key1: sorted_data[key1] for key1 in sorted(sorted_data.keys())[:10]}
#         ordered_dict_outbound = dict(sorted(first10pairs_outbound.items(), key=operator.itemgetter(1), reverse=True))
#
#         # outbound_dict = {}
#         # for a in meta_data1:
#         #     try:
#         #         outbound_list = []
#         #         query1 = db.cross_reference_report.find({"called_app_name": a})
#         #         for b in query1:
#         #             # if a==b['calling_app_name']:
#         #             #     print(" ")
#         #             # elif b['calling_app_name'].upper() not in outbound_list:
#         #             outbound_list.append(b['calling_app_name'].upper())
#         #         outbound_dict[a] = len(outbound_list)
#         #     except Exception as e:
#         #         #b['calling_app_name'] = ""
#         #         pass
#         # #print(outbound_dict)
#         # sorted_data = {k: v for k, v in sorted(outbound_dict.items(), key=lambda item: item[0])}
#         # first10pairs_outbound = {k: sorted_data[k] for k in sorted(sorted_data.keys())[:10]}
#
#         return jsonify({"inboundOutbound":{"inbound": ordered_dict_inbound, "outbound": ordered_dict_outbound}})



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
        except KeyError as e :
            pass

            # print(inb)
    # print("1",calling_name)

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
    # print("meta_data1",meta_data1)

    # inbound_dict={}
    # for i in meta_data:
    #     try:
    #         inbound_list = []
    #         query=db.cross_reference_report.find({"$and":[{"calling_app_name" : i} ]})
    #         for j in query:
    #             # if i==j['called_app_name']:
    #             #     print(" ")
    #             # elif j['called_app_name'].upper() not in inbound_list:
    #             #print("gjh", inbound_list)
    #             inbound_list.append(j['called_app_name'].upper())
    #             #print("hi", len(inbound_list))
    #
    #         print("hi",len(inbound_list))
    #         inbound_dict[i]=len(inbound_list)
    #
    #     except KeyError as e:
    #         j['called_app_name'] = ""
    #         print("except")
    #         pass
    # #print(inbound_dict)
    # sorted_d = {k: v for k, v in sorted(inbound_dict.items(), key=lambda item: item[0])}
    # first10pairs_inbound = {k: sorted_d[k] for k in sorted(sorted_d.keys())[:10]}

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
    first10pairs_inbound = {k: sorted_d[k] for k in sorted(sorted_d.keys())[:10] if(k!='')}
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
    first10pairs_outbound = {key1: sorted_data[key1] for key1 in sorted(sorted_data.keys())[:10] if key1!=''}
    ordered_dict_outbound = dict(sorted(first10pairs_outbound.items(), key=operator.itemgetter(1), reverse=True))
    whole_key=[]
    for k in ordered_dict_inbound.keys():
        whole_key.append(k)
    for k in ordered_dict_outbound.keys():
        whole_key.append(k)
    in_key=list(ordered_dict_inbound.keys())
    out_key= list(ordered_dict_outbound.keys())
    for key in whole_key:
        if(key not in in_key):
            # print(key)
            ordered_dict_inbound[key]=0
        if(key not in out_key):
            ordered_dict_outbound[key]= 0
        # print(k,v)

    # print("outbound",ordered_dict_outbound)

    # outbound_dict = {}
    # for a in meta_data1:
    #     try:
    #         outbound_list = []
    #         query1 = db.cross_reference_report.find({"called_app_name": a})
    #         for b in query1:
    #             # if a==b['calling_app_name']:
    #             #     print(" ")
    #             # elif b['calling_app_name'].upper() not in outbound_list:
    #             outbound_list.append(b['calling_app_name'].upper())
    #         outbound_dict[a] = len(outbound_list)
    #     except Exception as e:
    #         #b['calling_app_name'] = ""
    #         pass
    # #print(outbound_dict)
    # sorted_data = {k: v for k, v in sorted(outbound_dict.items(), key=lambda item: item[0])}
    # first10pairs_outbound = {k: sorted_data[k] for k in sorted(sorted_data.keys())[:10]}
    # d={}
    in_data=[]
    out_data=[]
    dic={}
    dic1={}
    for k,k1 in zip(sorted(ordered_dict_outbound.keys()),sorted(ordered_dict_inbound.keys())):
        dic[k1]=ordered_dict_inbound[k1]
        dic1[k]=ordered_dict_outbound[k]

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
        response_var['dash_no_of_components'] = db.master_inventory_report.count_documents({'type': {"$ne": "metadata"}})

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
        response_var['dash_number_of_orphan_components'] = db.orphan_report.count_documents({'type': {"$ne": "metadata"}})

        # Calculating total number of  missing components

        response_var['dash_number_of_missing_components'] = db.missing_components_report.count_documents({'type': {"$ne": "metadata"}})

        return jsonify(response_var)

    except Exception as e:
        return jsonify({"status": "failure", "reason": "Error: " + str(e)})

adit= {
   "app_tech_loc":{
      "CopyBook":{
         "DISTRICT PROCESSING":119,
         "ACCOUNTS RECEIVABLE":72,
         "GENERAL LEDGER":219,
         "ACCOUNTS PAYABLE":961,
         "COMMISSIONS":0,
         "MISCELLANEOUS":208,
         "FIXED ASSETS":0,
         "MACRO":115
      },
      "Cobol":{
         "DISTRICT PROCESSING":0,
         "ACCOUNTS RECEIVABLE":278,
         "GENERAL LEDGER":1131,
         "ACCOUNTS PAYABLE":5313,
         "COMMISSIONS":789,
         "MISCELLANEOUS":0,
         "FIXED ASSETS":1481,
         "MACRO":235
      },
      "JCL":{
         "DISTRICT PROCESSING":0,
         "ACCOUNTS RECEIVABLE":44,
         "GENERAL LEDGER":0,
         "ACCOUNTS PAYABLE":117,
         "COMMISSIONS":123,
         "MISCELLANEOUS":0,
         "FIXED ASSETS":121,
         "MACRO":0
      },
      "Proc":{
         "DISTRICT PROCESSING":0,
         "ACCOUNTS RECEIVABLE":0,
         "GENERAL LEDGER":0,
         "ACCOUNTS PAYABLE":419,
         "COMMISSIONS":0,
         "MISCELLANEOUS":0,
         "FIXED ASSETS":0,
         "MACRO":0
      }
   }
}


@app.route('/api/v1/adityan', methods=['GET'])
def adi():
    return jsonify(adit)


@app.route('/api/v1/masterInventory', methods=['GET'])
def masterInventory():
    data_object = {}
    data_object['data'] = []
    try:
        cursor = db.master_inventory_report.find({'type': {"$ne": "metadata"}}, {'_id': 0})
        metadata = db.master_inventory_report.find_one({"type": "metadata"}, {'_id': 0})
        data_object['headers'] = metadata['headers']
        for document in cursor:
            data_object['data'].append(document)
    except Exception as e:
        print('')
    return jsonify(data_object)

'''
@app.route('/api/v1/crossReference', methods=['GET'])
def crossReference():
    data_object = {}
    data_object['data'] = []
    try:
        search_filter = request.args.get('searchFilter')

        start = timeit.default_timer()
        cursor = db.cross_reference_report.find({'type': {"$ne": "metadata"}}, {'_id': 0})
        metadata = db.cross_reference_report.find_one({"type": "metadata"}, {'_id': 0})
        data_object['headers'] = metadata['headers'][1:]
        # for document in cursor:
        #     del document['file_name']
        #     data_object['data'].append(document)

        if search_filter:
            dfDataset = pd.DataFrame.from_records(cursor)
            resultdf = dfDataset[dfDataset.apply(lambda x: x.str.contains(search_filter, na=False)).any(axis=1)]
            data_object['data'] = resultdf.fillna("").to_dict('records')

        else:
            dfDataset = pd.DataFrame.from_records(cursor)
            data_object['data'] = dfDataset.fillna("").to_dict('records')


        end = timeit.default_timer()
        print('total time', start-end,'seconds')
    except Exception as e:
        print('')
    return jsonify(data_object)
'''


'''If something goes wrong for 27th Jun demo use this for XREF
@app.route('/api/v1/crossReference', methods=['GET'])
def crossReference():
    data_object = {}
    data_object['data'] = []
    try:
        search_filter = request.args.get('searchFilter')
        override_filter = request.args.get('overrideFilter')

        #Filter override to download export entire dump to CSV/Excel
        if override_filter == 'yes':
            #Query all cross reference data
            cursor = db.cross_reference_report.find({'type': {"$ne": "metadata"}}, {'_id': 0})
            #Query to fetch header details
            metadata = db.cross_reference_report.find_one({"type": "metadata"}, {'_id': 0})
            #Hotfix to not diplay the file name
            data_object['headers'] = metadata['headers'][1:]
            #Pandas code to convert cursor to a dict
            dfDataset = pd.DataFrame.from_records(cursor)
            resultdf = dfDataset[dfDataset.apply(lambda x: x.str.contains(search_filter, na=False)).any(axis=1)]
            data_object['data'] = resultdf.fillna("").to_dict('records')
            return jsonify(data_object)
        else:

            if search_filter:
                # Query all cross reference data
                cursor = db.cross_reference_report.find({'type': {"$ne": "metadata"}}, {'_id': 0})
                # Query to fetch header details
                metadata = db.cross_reference_report.find_one({"type": "metadata"}, {'_id': 0})
                data_object['headers'] = metadata['headers'][1:]
                dfDataset = pd.DataFrame.from_records(cursor)
                resultdf = dfDataset[dfDataset.apply(lambda x: x.str.contains(search_filter, na=False)).any(axis=1)]
                data_object['data'] = resultdf.fillna("").to_dict('records')
                return jsonify(data_object)

            else:
                #If there is no filter criteria, limit to 1000 records
                # Query all cross reference data
                cursor = db.cross_reference_report.find({'type': {"$ne": "metadata"}}, {'_id': 0}).limit(CROSS_REFERENCE_LIMIT)
                # Query to fetch header details
                metadata = db.cross_reference_report.find_one({"type": "metadata"}, {'_id': 0})
                data_object['headers'] = metadata['headers'][1:]

                #Pandas code for cursor to dictionary convertion
                dfDataset = pd.DataFrame.from_records(cursor)
                data_object['data'] = dfDataset.fillna("").to_dict('records')
                return jsonify(data_object)
    except Exception as e:
        print('Error: ' + str(e))
        print('Error on line {}'.format(sys.exc_info()[-1].tb_lineno))
        return 'FAIL'+str(e)
'''

@app.route('/api/v1/crossReference', methods=['GET'])
def crossReference():
    data_object = {}
    data_object['data'] = []

    data_object['displayed_count'] = 0
    try:
        search_filter = request.args.get('searchFilter')
        override_filter = request.args.get('overrideFilter')

        #Fetch the total record count
        data_object['total_record_count'] = db.cross_reference_report.count_documents({})-1


        #Filter override to download export entire dump to CSV/Excel
        if override_filter == 'yes':
            #Query all cross reference data
            cursor = db.cross_reference_report.find({'type': {"$ne": "metadata"}}, {'_id': 0})
            #Query to fetch header details
            metadata = db.cross_reference_report.find_one({"type": "metadata"}, {'_id': 0})
            #Hotfix to not diplay the file name
            data_object['headers'] = metadata['headers']
            #Pandas code to convert cursor to a dict
            dfDataset = pd.DataFrame.from_records(cursor)
            resultdf = dfDataset[dfDataset.apply(lambda x: x.str.contains(search_filter, na=False)).any(axis=1)]
            data_object['data'] = resultdf.fillna("").to_dict('records')
            data_object['displayed_count']=data_object['total_record_count']
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
                #print('Result count', resultdf['component_name'].count())
                data_object['displayed_count']=int(resultdf['component_name'].count())
                data_object['data'] = resultdf.fillna("").to_dict('records')
                return jsonify(data_object)

            else:
                #If there is no filter criteria, limit to 1000 records
                # Query all cross reference data
                cursor = db.cross_reference_report.find({'type': {"$ne": "metadata"}}, {'_id': 0}).limit(CROSS_REFERENCE_LIMIT)
                # Query to fetch header details
                metadata = db.cross_reference_report.find_one({"type": "metadata"}, {'_id': 0})
                data_object['headers'] = metadata['headers']

                #Pandas code for cursor to dictionary convertion
                dfDataset = pd.DataFrame.from_records(cursor)
                data_object['displayed_count'] = int(dfDataset['component_name'].count())
                data_object['data'] = dfDataset.fillna("").to_dict('records')
                return jsonify(data_object)
    except Exception as e:
        print('Error: ' + str(e))
        print('Error on line {}'.format(sys.exc_info()[-1].tb_lineno))
        return 'FAIL'+str(e)


@app.route('/api/v1/CRUD', methods=['GET'])
def CRUD():
    data_object = {}
    data_object['data'] = []
    try:
        cursor = db.crud_report.find({'type': {"$ne": "metadata"}}, {'_id': 0})
        metadata = db.crud_report.find_one({"type": "metadata"}, {'_id': 0})
        data_object['headers'] = metadata['headers']
        for document in cursor:
            data_object['data'].append(document)
    except Exception as e:
        print('')
    return jsonify(data_object)


@app.route('/api/v1/orphanReport', methods=['GET'])
def orphanReport():
    data_object = {}
    data_object['data'] = []
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
    #print('yoyoyoyoyo')
    data_object = {}
    data_object['data'] = []
    try:
        cursor = db.missing_components_report.find({'type': {"$ne": "metadata"}}, {'_id': 0})
        metadata = db.missing_components_report.find_one({"type": "metadata"}, {'_id': 0})
        data_object['headers'] = metadata['headers']
        #print(cursor)
        for document in cursor:
            data_object['data'].append(document)
            #print(document)
    except Exception as e:
        return jsonify({"error":str(e)})
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
                                                                                                "JCL.time_zone": time_zone,"headers":db_data['headers']}},
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
                            {"$or": [{"component_type": "COBOL"}]}).acknowledged:
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
                                {"type": "metadata", "COBOL": {"last_updated_on": current_time, "time_zone": time_zone},
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
                    #print('crd remove operation', db.crud_report.remove({}))
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

    # JSON document for db upload
    db_data = []

    #Payload
    payload = {}

    #List of all cobol programs that have been processed
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
        #print('parent keys', keys)

        if 'data' in keys:
            #Getting a list of all programs
            program_list = list(payload['data'].keys())
            for program in program_list:
                #creating skeleton for program
                temp ={"component_name": "",
                 "nodes": [],
                 "links": []
                 }

                temp['component_name'] = program
                node_set= set()
                link_set = set()
                #print('fruit ',payload['data'][program])
                for pgm_name  in payload['data'][program]:
                    #print(pgm_name)
                    from_node = pgm_name['from']
                    to_node = pgm_name['to']
                    if pgm_name['Name'] == "External_Program":

                        node_set.add('p_' + from_node)
                        node_set.add('p_' + to_node)
                        # temp['links'].append({"source":'p_'+from_node,"target":'p_'+to_node})
                        link_set.add(json.dumps(
                            {"source": 'p_' + from_node, "target": 'p_' + to_node, "label": 'External_Program'}))

                    else:
                        node_set.add('p_' + from_node)
                        node_set.add('p_' + to_node)
                        # temp['links'].append({"source":'p_'+from_node,"target":'p_'+to_node})
                        link_set.add(json.dumps({"source": 'p_' + from_node, "target": 'p_' + to_node}))

                    # node_set.add('p_'+from_node)
                    # node_set.add('p_'+to_node)
                    # #temp['links'].append({"source":'p_'+from_node,"target":'p_'+to_node})
                    # link_set.add(json.dumps({"source":'p_'+from_node,"target":'p_'+to_node}))
                    # #print(json.dumps({"source":'p_'+from_node,"target":'p_'+to_node}))
                
                #print(link_set)
                for item in link_set:
                    temp['links'].append(json.loads(item))


                #ite variable to increment position variable
                ite = 1
                for item in node_set:
                    #temp['nodes'].append({"id":item,"label":item[2:],"position":"x"+str(ite)})
                    temp['nodes'].append({"id":item,"label":item[2:]})
                    ite=ite+1


                db_data.append(temp)
            #print(db_data)

            previousDeleted = False
            try:
                #print('Remove operation', db.procedure_flow_table.remove({}))
                if db.procedure_flow_table.delete_many({}):  # Mongodb syntax to delete all records
                    print('Deleted all the data from previous runs')
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

                    db.procedure_flow_table.insert_many(db_data)
                    print('it has happened')
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

                    print(current_time)
                    return jsonify({"status": "success", "reason": "Successfully inserted data yay. "})
                except Exception as e:
                    print('Error' + str(e))
                    return jsonify({"status": "failed", "reason": str(e)})
            return jsonify(db_data)

    except Exception as e:
        print('Error: ' + str(e))
        print('Error on line {}'.format(sys.exc_info()[-1].tb_lineno))
        return jsonify({"status": "failure", "reason": "Response json not in the required format"})




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
        response['component_name']  = request.args.get('component_name')
        response['component_type']  = request.args.get('component_type')
        response['nodes'] = []
        response['links'] = []
        test_list = []
        name_type_map = {response['component_name'] :response['component_type']}
        #Adding the first node of the chart
        nodes = {response['component_name']}
        print(response['component_name'])
        if response['component_name'] is not None:
            try:
                connections  = db.cross_reference_report.find({"$or":[{"$and":[{"component_name":response['component_name'] },{"component_type":response['component_type']}]},{"$and":[{"called_name":response['component_name'] },{"called_type":response['component_type']}]}]},{'_id': 0})
                #connections  = db.cross_reference_report.find({"$and": [{"$or":[{"component_name":response['component_name']},{"called_name":response['component_name']}]},{"component"}]},{'_id': 0})
                print('count',connections.count())


                if connections.count() > 0:
                    for connection in connections:
                        if connection['called_name'].strip()!='':
                            #If the CALLING component's name is same as option

                            if connection['component_name'] == response['component_name']:

                                if connection['component_name'] != connection['called_name']:
                                    response['links'].append({"source": "p_" + connection['component_name'],
                                                              "target": "p_" + connection['called_name'], "label": "C"})
                                    test_list.append({"source": "p_" + connection['component_name'],
                                                              "target": "p_" + connection['called_name'], "label": "C"})

                                # findDup = {}
                                    name_type_map[connection['called_name']]=connection['called_type']
                                    nodes.add(connection['called_name'])
                            # If the CALLED component's name is same as option
                            else:
                                # for iDict in response['links']:
                                #     for v in iDict.values():
                                #         if v['source'] != findDup['source'] and v['target'] != findDup['target'] and v['label'] != findDup['label']:
                                #             print('new val')
                                if connection['component_name'] != connection['called_name']:
                                    response['links'].append({"source": "p_" + connection['called_name'],
                                                              "target": "p_" + connection['component_name'], "label": "P"})
                                    test_list.append({"source": "p_" + connection['called_name'],
                                                              "target": "p_" + connection['component_name'], "label": "P"})

                                #         else:
                                #             print('dup')
                                # findDup = {}
                                    name_type_map[connection['component_name']] = connection['component_type']
                                    nodes.add(connection['component_name'])
                    for node in nodes:
                        response['nodes'].append({"id":"p_"+node,"label":node+' ('+name_type_map[node]+')'})
                else:
                    return jsonify({"error":"the component name"+response['component_name']+" does not exist."})
                res_list=[]
                for i in range(len(response['links'])):
                    if test_list[i] not in test_list[i + 1:]:
                        res_list.append(test_list[i])
                response['links'] = res_list
                # print(res_list)
                return jsonify(response)
            except Exception as e:
                return jsonify({"error": str(e)})
        return jsonify({"error": "The request parameters are either incorrect or missing"})
    except Exception as e:
        return jsonify({"error":str(e)})


@app.route('/api/v1/spiderFilterList')
def spiderFilterList():
        connections = db.cross_reference_report.find({"type": {"$ne": "metadata"}})
        connections1=db.missing_component_report.find({"type":{"$ne":"metadata"}})
        not_to_list=[]
        for connection in connections1:
            not_to_list.append((connection['component_name']))
        print(connections.count())
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
            print(response['component_name'])
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
                    print('count', connections.count())

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
    response['option']= ''
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
        response['option']= request.args.get('filter')
        print("OPTION",response['option'])
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
                connections = db.cross_reference_report.find({"$or": [{"$and": [{"component_name": response['component_name']}, {"component_type": response['component_type']}]},
                                                                      # {"$and": [{"called_name": response['component_name']}, {"called_type": response['component_type']},{"comments": {"$ne": "inline"}}]}]},
                                                             {"$and": [{"called_name": response['component_name']},
                                                                       {"called_type": response['component_type']},
                                                                       {"comments": {"$ne": "inline"}}]}]},
                                                                      {'_id': 0})
                # connections  = db.cross_reference_report.find({"$and": [{"$or":[{"component_name":response['component_name']},{"called_name":response['component_name']}]},{"component"}]},{'_id': 0})
                print('count', connections.count())

                if connections.count() > 0:
                    for connection in connections:
                        print(connection['component_name'])
                        if connection['called_name'].strip() != '':
                            # If the CALLING component's name is same as option
                            if connection['component_name'] == response['component_name']:
                                if (str(connection['called_type']).upper() == str(response['option']).upper()):
                                    if(connection['component_name']!=connection['called_name']):
                                        response['links'].append({"source": "p_" + connection['component_name'],
                                                                  "target": "p_" + connection['called_name'],
                                                                  "label": "C"})
                                    name_type_map[connection['called_name']] = connection['called_type']
                                    nodes.add(connection['called_name'])
                                if(response['option']=="All"):
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
                        # elif(str(response['option'])=="All"):
                        #     if connection['called_name'].strip() != '':
                        #         # If the CALLING component's name is same as option
                        #         if connection['component_name'] == response['component_name']:
                        #             response['links'].append({"source": "p_" + connection['component_name'],
                        #                                       "target": "p_" + connection['called_name'],
                        #                                       "label": "C"})
                        #             name_type_map[connection['called_name']] = connection['called_type']
                        #             nodes.add(connection['called_name'])
                        #         # If the CALLED component's name is same as option
                        #         else:
                        #             response['links'].append({"source": "p_" + connection['called_name'],
                        #                                       "target": "p_" + connection['component_name'],
                        #                                       "label": "P"})
                        #             name_type_map[connection['component_name']] = connection['component_type']
                        #
                        #             nodes.add(connection['component_name'])
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


@app.route('/api/v1/spiderTypes', methods=['GET'])
def spiderTypes():
    try:
        distinct_types = set()
        component_types= db.cross_reference_report.distinct("component_type")
        called_types= db.cross_reference_report.distinct("called_type")
        for item in component_types:
            distinct_types.add(item)
        for item in called_types:
            distinct_types.add(item)
        return jsonify(sorted(list(distinct_types)))
    except Exception as e:
        print("Error:",str(e))
        return jsonify({"error":str(e)})



@app.route('/api/v1/spiderList', methods=['GET'])
def spiderList():
    spider_elements = set()
    try:
        option  = request.args.get('option')
        distinct_elements = set()
        #if option is not None:
        if option is not None:
            calling_names = db.cross_reference_report.distinct("component_name",{"component_type":option})
            called_names = db.cross_reference_report.distinct("called_name",{"called_type":option})

            print('calling',calling_names,'called',called_names)
            for item in called_names:
                distinct_elements.add(item)
            for item in calling_names:
                distinct_elements.add(item)
            return jsonify(sorted(list(distinct_elements)))
        else:
            return jsonify({"error":"No option provided"})

        # # for element in distinct_elements:
        # return jsonify({type:distinct_elements})

    except Exception as e:
        return jsonify({"error":str(e)})



@app.route('/api/v1/procedureFlowList', methods=['GET'])
def procedureFlowList():
    pgm_name_set = set()
    try:
        list_of_programs = db.procedure_flow_table.distinct("component_name")
        for pgm in list_of_programs:
            pgm_name_set.add(pgm)
        #print(pgm_name_set)
        return jsonify({"program_list":sorted(list(pgm_name_set))})
    except Exception as e:
        print('Error:',str(e))
        return jsonify({"status":"failure","reason":"Error: "+str(e)})



@app.route('/api/v1/procedureFlow', methods=['GET'])
def procedureFlow():

    try:

        option  = request.args.get('option')
        flag = request.args.get('flag')
        if option is not None:
            if flag == "no":
                #ge the program name to return
                program_name = option

                try:
                    # cursor = db.cross_reference_report.find({'type': {"$ne": "metadata"}}, {'_id': 0})

                    response =  db.procedure_flow_table.find_one({"component_name":program_name}, {'_id': 0})


                    if response is None:
                        return jsonify({"response":"No such key"})
                    else:
                        print(response)
                        return jsonify(response)
                except Exception as e:
                    print("Error",str(e))
                    return jsonify({"status": "failure", "reason": "Error: " + str(e)})
            if flag == "yes":
                program_name = option

                try:
                    # cursor = db.cross_reference_report.find({'type': {"$ne": "metadata"}}, {'_id': 0})

                    response = db.procedure_flow_table_EC.find_one({"component_name": program_name}, {'_id': 0})

                    if response is None:
                        return jsonify({"response": "No such key"})
                    else:
                        print(response)
                        return jsonify(response)
                except Exception as e:
                    print("Error", str(e))
                    return jsonify({"status": "failure", "reason": "Error: " + str(e)})

    except Exception as e:
        print("Error", str(e))
        return jsonify({"status": "failure", "reason": "Error: " + str(e)})



# @app.route('/api/v1/procedureFlow', methods=['GET'])
# def procedureFlow():
#
#     try:
#
#         option  = request.args.get('option')
#         if option is not None:
#             #ge the program name to return
#             program_name = option
#
#             try:
#                 response =  db.procedure_flow_table.find_one({"component_name":program_name}, {'_id': 0})
#                 if response is None:
#                     return jsonify({"response":"No such key"})
#                 else:
#                     return jsonify(response)
#             except Exception as e:
#                 print("Error",str(e))
#                 return jsonify({"status": "failure", "reason": "Error: " + str(e)})
#
#     except Exception as e:
#         print("Error", str(e))
#         return jsonify({"status": "failure", "reason": "Error: " + str(e)})


@app.route('/api/v1/augment/masterInventory', methods=['POST'])
def augmentMasterInventory():
    try:
        # check if the text is json
        JsonVerified, verification_payload = jsonVerify(request.data)
        if JsonVerified:
            payload = verification_payload
        else:
            return verification_payload

        keys =  list(payload.keys())
        for ite in keys:
            row = payload[ite]
            if db.master_inventory_report.update_one({"component_name":ite}, {
                "$set":{"dead_para_count": row['dead_para_count'], "dead_para_list": row['dead_para_list'], "no_of_dead_lines": row['total_dead_lines'], 'total_para_count': row['total_para_count']}}).acknowledged:
                print('updated',ite)
            else:
                print('not updated')

        return jsonify({"yo":"yo"})

    except Exception as e:
        print("error"+str(e))
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
            #print(row[ite])
            if db.master_inventory_report.update_one({"component_name":ite}, {
                "$set":{"cyclomatic_complexity": row}}).acknowledged:
                print('updated',ite)
            else:
                print('not updated')

        return jsonify({"yo":"yo"})

    except Exception as e:
        print('Error: ' + str(e))
        print('Error on line {}'.format(sys.exc_info()[-1].tb_lineno))
        return jsonify({"status": "failure", "reason": "Response json not in the required format"})


@app.route('/api/v1/update/masterInventory', methods=['POST'])
def updateMasterInventory():
    data = request.data
    # JSON document for db upload
    print(data)
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
            print('Headers',x_master_Inventory_header_list)
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



@app.route("/api/v1/createUser", methods=['POST'])
def create_user():
    user_id = request.args.get("user_id")
    pwd = request.args.get("user_password")
    new_user = dict()
    new_user['user_id'] = user_id
    new_user['pwd'] = pwd
    db.user.insert(new_user)
    return '{ "userCreateStatus" : "success" }'


@app.route("/api/v1/validateUser", methods=['POST'])
def validate_user():
    user_id = request.args.get("user_id")
    pwd = request.args.get("user_password")
    is_found = db.user.find({'user_id': user_id})
    if is_found.count() == 1:
        if is_found[0]['pwd'] == pwd:
            return '{ "validUser": "true" }'
        else:
            return '{ "validUser": "false" }'
    else:
        return '{"validUser": "User doesn\'t exist"}'


@app.route("/api/v1/userExists", methods=['POST'])
def user_exists():
    user_id = request.args.get("user_id")
    is_found = db.user.find({'user_id': user_id})
    if is_found.count() >= 1:
        return '{ "userExists": "true" }'
    else:
        return '{"userExists": "User doesn\'t exist"}'






@app.route('/api/v1/procedureAppList', methods=['GET'])
def procedureAppList():
    appln_name_set = set()
    try:
        list_of_programs = db.master_inventory_report.distinct("application")
        for appln in list_of_programs:
            appln_name_set.add(appln)
        return jsonify({"application_list":sorted(list(appln_name_set))})
    except Exception as e:
        print('Error:',str(e))
        return jsonify({"status":"failure","reason":"Error: "+str(e)})


@app.route('/api/v1/procedureFlowCompList', methods=['GET'])
def procedureFlowCompList():
    option = request.args.get('option')
    comp_name_set = set()
    if option is not None:
        application_name = option
        try:
            # response = db.master_inventory_report.find({"application": application_name, "component_type":"RPG"})
            response = db.master_inventory_report.find({"application": application_name, "component_type":"RPGLE"})#werner specific

                # ???component_type???: ???COBOL??? for GE
            if response is None:
                return jsonify({"response": "No such key"})
            else:
                for appln in response:
                    comp_name_set.add(appln["component_name"] + "." + appln["component_type"])
                return jsonify({"component_list": sorted(list(comp_name_set)), "application_name": application_name})
        except Exception as e:
            print("Error", str(e))
            return jsonify({"status": "failure", "reason": "Error: " + str(e)})


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
    dup_response= set()

    '''
    Query for spider details
    -> All rows where the component name is either in called or calling
    -> Based on where the component name is -> Tag the relationship line as either Parent or Child
    -> In the label name of the child nodes must append the component_type in paranthesis as well
    -> two nodes A -> X can have both relationships parent/child
    '''
    def Remove(duplicate):
        final_list = []
        # for list_iter in duplicate:
        #     if list_iter not in final_list:
        #         final_list.append(list_iter)

        for list_iter in range(len(duplicate)):
            if duplicate[list_iter] not in duplicate[list_iter + 1:]:
                final_list.append(duplicate[list_iter])

        return final_list
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

    def child_link(called_name, component_type, i):
        if i["called_type"] == "Prototype procedure":
            response["nodes"].append({"id": "p_" + i["component_name"],
                                      "label": i["component_name"] + "(" + i["component_type"] + ")"})
            response["nodes"].append(
                {"id": "pp_" + i["called_name"], "label": i["called_name"] + "(" + i["called_type"] + ")"})

            response["links"].append({"label": "called",
                                      "source": "p_" + i["component_name"],
                                      "target": "pp_" + i["called_name"]})

        if i["called_type"] == "Bound procedure":
            response["nodes"].append({"id": "p_" + i["component_name"],
                                      "label": i["component_name"] + "(" + i["component_type"] + ")"})
            response["nodes"].append(
                {"id": "bp_" + i["called_name"], "label": i["called_name"] + "(" + i["called_type"] + ")"})

            response["links"].append({"label": "called",
                                      "source": "p_" + i["component_name"],
                                      "target": "bp_" + i["called_name"]})
        if i["called_type"] == "Procedure":
            response["nodes"].append({"id": "p_" + i["component_name"],
                                      "label": i["component_name"] + "(" + i["component_type"] + ")"})
            response["nodes"].append(
                {"id": "p_" + i["called_name"], "label": i["called_name"] + "(" + i["called_type"] + ")"})

            response["links"].append({"label": "called",
                                      "source": "p_" + i["component_name"],
                                      "target": "p_" + i["called_name"]})
        else:
            response['links'].append({"source": "p_" + called_name,
                                      "target": "p_" + component_type,
                                      "label": "C"})
        return response['links']

    def parent_link(called_name, component_type, i):
        if i["called_type"] == "Prototype procedure":
            response["nodes"].append({"id": "p_" + i["component_name"],
                                      "label": i["component_name"] + "(" + i["component_type"] + ")"})
            response["nodes"].append(
                {"id": "pp_" + i["called_name"], "label": i["called_name"] + "(" + i["called_type"] + ")"})

            response["links"].append({"label": "called",
                                      "source": "p_" + i["component_name"],
                                      "target": "pp_" + i["called_name"]})

        if i["called_type"] == "Bound procedure":
            response["nodes"].append({"id": "p_" + i["component_name"],
                                      "label": i["component_name"] + "(" + i["component_type"] + ")"})
            response["nodes"].append(
                {"id": "bp_" + i["called_name"], "label": i["called_name"] + "(" + i["called_type"] + ")"})

            response["links"].append({"label": "called",
                                      "source": "p_" + i["component_name"],
                                      "target": "bp_" + i["called_name"]})
        if i["called_type"] == "Procedure":
            response["nodes"].append({"id": "p_" + i["component_name"],
                                      "label": i["component_name"] + "(" + i["component_type"] + ")"})
            response["nodes"].append(
                {"id": "p_" + i["called_name"], "label": i["called_name"] + "(" + i["called_type"] + ")"})

            response["links"].append({"label": "called",
                                      "source": "p_" + i["component_name"],
                                      "target": "p_" + i["called_name"]})
        else:
            response['links'].append({"source": "p_" + called_name,
                                      "target": "p_" + component_type,
                                      "label": "P"})
        return response['links']

    response['nodes'] = []
    response['links'] = []
    component_name = []
    component_type = []
    temp = []
    component_name1=request.args.get("component_name")
    component_name1= component_name1.replace("$","&")
    component_name.append(component_name1)
    component_type.append(request.args.get("component_type"))
    # component_name.append("AP544P00")
    # component_type.append("COBOL")
    parent_child = request.args.get("level")
    try:
        for c_name, c_type in zip(component_name, component_type):
            input_name, input_type = input_value(c_name, c_type)
            print("input", input_name, input_type)
            nodes = {input_name}
            name_type_map = {input_name: input_type}
            if input_name is not None:
                connections = db_link(input_name, input_type)
                # print(connections.count())
                if connections.count() > 0:
                    flag = 1
                    for connection in connections:
                        if connection['called_name'].strip() != '':
                            # If the CALLING component's name is same as option

                            if connection['component_name'].strip() == input_name:
                                if parent_child == "child":
                                    if connection['called_type'].lower() != 'file' or  connection['called_type'].lower() != 'workbook':
                                        component_name.append(connection['called_name'])
                                        component_type.append(connection['called_type'])
                                        child_output = child_link(connection['component_name'],
                                                                  connection['called_name'], connection)
                                        name_type_map[connection['called_name']] = connection['called_type']
                                        if connection['called_name'] not in nodes:
                                            nodes.add(connection['called_name'])
                                            flag = 0
                            else:
                                if (parent_child == "parent"):
                                    parent_output = parent_link(connection['called_name'], connection['component_name'], connection)
                                    # print(parent_output)
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
                            if (node not in temp):
                                temp.append(node)
                                response['nodes'].append(
                                    {"id": "p_" + node, "label": node + '(' + name_type_map[node] + ')'})


        response['nodes'] = Remove(response['nodes'])

        return jsonify(response)

    except Exception as e:
        return jsonify({"error": str(e)})

@app.route('/api/v1/controlflow', methods=['GET'])
def controlflow():

    response = {}
    response['component_name'] =request.args.get('component_name')
    response['component_type'] = request.args.get('component_type')
    response['nodes'] = []
    response['links'] = []

    if response['component_name'][0]=="$":#HOT FIX FOR & response
        response['component_name'] = "&" + response['component_name'][1:]
    if response['component_name'][1]=="$":#HOT FIX FOR & response
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
        connections = db.crud_report.find({"component_name" : input_name})
        return connections

    def accmode_aliases(Acc_mode):

        Acc_mode = i['access_mode']

        Acc_mode_list = Acc_mode.split(",")

        # for i in Acc_mode_list:
        if Acc_mode_list[0].strip() == "SHR":
            Acc_mode = "Read"
            return Acc_mode

        if Acc_mode_list[0].strip() == "OLD":
            Acc_mode = "Read/Write"
            return Acc_mode
        if Acc_mode_list[0].strip() == "NEW" or (Acc_mode_list[0].strip() == "" and len(Acc_mode_list) > 1):
            Acc_mode = "Write"
            return Acc_mode





    response['nodes'] = []
    response['links'] = []
    component_name = []
    component_type = []

    # component_name.append("AP725JBR")
    # component_type.append("JCL")


    try:
            connections = db_link(response['component_name'],response['component_type'])
            for i in connections:

             if i["called_type"]!="FILE":

                if  i["called_type"] !=("Prototype procedure" or "Bound procedure" or "Procedure"):
                    response["nodes"].append({"id":"p_"+i["component_name"],"label": i["component_name"]+"(" + i["component_type"] + ")"  })
                    response["nodes"].append({"id": "p_" + i["called_name"], "label": i["called_name"] + "(" + i["called_type"] + ")"})
                    if i["component_name"] == response['component_name']: #inputcomponent
                        # if i["called_type"].lower() == "file":
                        #     response["links"].append({"label": accmode_aliases(i["access_mode"]) ,
                        #                               "source": "p_" + i["component_name"],
                        #                               "target": "p_" + i["called_name"]})
                        #
                        # else:
                        response["links"].append({"label":"called",
                                                  "source":"p_"+i["component_name"],
                                                  "target":"p_"+i["called_name"]})

                        response["nodes"].append({"id":"p_"+i["called_name"],"label": i["called_name"]+"(" + i["called_type"] + ")"  })
                    else:

                        # if i["called_type"].lower() == "file":
                        #     response["links"].append({"label": accmode_aliases(i["access_mode"]),
                        #                               "source": "p_" + i["component_name"],
                        #                               "target": "p_" + i["called_name"]})


                        # else:
                            response["links"].append({"label": "calling",
                                                  "source": "p_"+i["component_name"],
                                                  "target": "p_"+i["called_name"]})
                elif  i["called_type"] ==("Prototype procedure" or "Bound procedure" or "Procedure"):

                    if i["called_type"] =="Prototype procedure":
                        response["nodes"].append({"id": "p_" + i["component_name"],
                                                  "label": i["component_name"] + "(" + i["component_type"] + ")"})
                        response["nodes"].append(
                            {"id": "pp_" + i["called_name"], "label": i["called_name"] + "(" + i["called_type"] + ")"})

                        response["links"].append({"label": "called",
                                                  "source": "p_" + i["component_name"],
                                                  "target": "pp_" + i["called_name"]})

                    if i["called_type"] =="Bound procedure":
                        response["nodes"].append({"id": "p_" + i["component_name"],
                                                  "label": i["component_name"] + "(" + i["component_type"] + ")"})
                        response["nodes"].append(
                            {"id": "bp_" + i["called_name"], "label": i["called_name"] + "(" + i["called_type"] + ")"})

                        response["links"].append({"label": "called",
                                                  "source": "p_" + i["component_name"],
                                                  "target": "bp_" + i["called_name"]})
                    if i["called_type"] == "Procedure":
                        response["nodes"].append({"id": "p_" + i["component_name"],
                                                  "label": i["component_name"] + "(" + i["component_type"] + ")"})
                        response["nodes"].append(
                            {"id": "p_" + i["called_name"], "label": i["called_name"] + "(" + i["called_type"] + ")"})

                        response["links"].append({"label": "called",
                                                  "source": "p_" + i["component_name"],
                                                  "target": "p_" + i["called_name"]})


            table_connections = db_link2(response['component_name'],response['component_type'])

            for i in table_connections:
                if i["component_name"] == response['component_name']:  # inputcomponent:
                    response["nodes"].append({"id": "t_" + i["Table"],"label": i["Table"] + "(" + "Table" + ")"})

                    response["links"].append({"label": i["CRUD"],
                                              "source": "p_" + i["component_name"],
                                              "target": "t_" + i["Table"]})





            response["links"] = Remove(response["links"])
            response["nodes"] = Remove(response["nodes"])

            print(json.dumps(response,indent=4))
            return jsonify(response)
    except Exception as e:
        print(e)


@app.route('/api/v1/updateBRE', methods=['GET'])
def updateBRE():
    try:
        # check if the text is json
        # JsonVerified, verification_payload = jsonVerify(request.args.get)
        fragment_id = request.args.get('fragment_id')
        pgm_name = request.args.get('pgm_name')
        para_name = request.args.get('para_name')
        source_statements = request.args.get('source_statements')
        rule_description = request.args.get('rule_description')
        rule_category = request.args.get('rule_category')
        Rule = request.args.get('Rule')
        rule_relation = request.args.get('rule_relation')

        #fragment_id, pgm_name, para_name, source_statements, rule_description, rule_category, Rule, rule_relation
        # if JsonVerified:
        #     payload = verification_payload
        # else:
        #     return verification_payload

        if db.bre_report2.update_one({"fragment_id": fragment_id}, {
            "$set": {"pgm_name": pgm_name,
                     "para_name":para_name,
                     "source_statements": source_statements,
                     'rule_category': rule_category,
                     'rule_description':rule_description,
                     'Rule' : Rule,
                     "rule_relation" : rule_relation  }}).acknowledged:
            print('updated' )
        else:
            print('not updated')

        return jsonify({"yo": "yo"})

    except Exception as e:
        print("error" + str(e))
        return jsonify({"status": "failure", "reason": "Error: " + str(e)})
#
# @app.route('/api/v1/ruleCategoryList')
# def breruledd():
#
#     try:
#         connections=db.bre_report2.find()[1:]
#         bre_list=[]
#         for connection in connections:
#             if((connection['rule_category'].strip()!='')):
#                 bre_list.append(connection['rule_category'].strip())
#         out_bre=list(set(bre_list))
#     except Exception as e:
#         out_bre = ''
#         print(e)
#         pass
#
#     return jsonify({"rule_category_list":out_bre})
#
# @app.route('/api/v1/ruleCategory')
# def brerule():
#     bre_connection=request.args.get('option')
#     search_filter=request.args.get('searchFilter')
#     override_filter=request.args.get('overrideFilter ')
#     print(bre_connection)
#     if(override_filter=='yes'):
#         connections=db.bre_report2.find()[1:].limit(CROSS_REFERENCE_LIMIT)
#     else:
#         connections = db.bre_report2.find()[1:]
#     out_list=[]
#     for connection in connections:
#         # print(connection['rule_category'], bre_connection)
#         if(connection['rule_category']==bre_connection):
#             if (search_filter != '' and len(search_filter)>=3):
#                 if(connection['pgm_name'].find(search_filter)>0 or connection['para_name'].find(search_filter)>0 or connection['source_statements'].find(search_filter)>0 or connection['rule_category'].find(search_filter)>0 or connection['Rule'].find(search_filter)>0 or connection['rule_relation'].find(search_filter)>0 or connection['rule_description'].find(search_filter)>0):
#                     out_list.append({'pgm_name': connection['pgm_name'], 'para_name':connection['para_name'], "source_statements":connection["source_statements"], "rule_category":connection["rule_category"], "Rule":connection["Rule"], "rule_relation":connection["rule_relation"], "rule_description":connection["rule_description"]})
#             else:
#                 out_list.append({'pgm_name': connection['pgm_name'], 'para_name':connection['para_name'], "source_statements":connection["source_statements"], "rule_category":connection["rule_category"], "Rule":connection["Rule"], "rule_relation":connection["rule_relation"], "rule_description":connection["rule_description"]})
#
#     json_format={
#         'data': out_list,
#         'headers': ["pgm_name","para_name","source_statements", "rule_category", "Rule", "rule_relation", "rule_description"]
#
#     }
#     return jsonify(json_format)



@app.route('/api/v1/ruleCategoryList')
def breruledd():
    # out_bre = ''
    try:
        connections=db.bre_rules_report.find()[1:]
        bre_list=[]

        for connection in connections:
            if((connection['rule_category'].strip()!='')):
                bre_list.append(connection['rule_category'].strip())
            # print("bre_list",bre_list)
            out_bre=list(set(bre_list))
            # print("Outbre",out_bre)
    except Exception as e:
        # out_bre = ''
        print(e)
        pass

    return jsonify({"rule_category_list":out_bre})

@app.route('/api/v1/ruleCategory')
def brerule():
    bre_connection=request.args.get('option')
    search_filter=request.args.get('searchFilter')
    override_filter=request.args.get('overrideFilter')
    # print(bre_connection)
    # print(search_filter)
    if(override_filter=='yes'):
        connections=db.bre_rules_report.find({"type":{"$ne":"metadata"}})[1:]
    else:
        connections = db.bre_rules_report.find()[1:].limit(CROSS_REFERENCE_LIMIT)
    out_list=[]
    for connection in connections:
        # print(connection['rule_category'], bre_connection)
        try:
            if(connection['rule_category']==bre_connection):
                if (search_filter != '' ):
                    if(len(search_filter)>=3):
                        if(connection['pgm_name'].find(search_filter)>0 or connection['para_name'].find(search_filter)>0 or connection['source_statements'].find(search_filter)>0 or connection['rule_category'].find(search_filter)>0 or connection['fragment_Id'].find(search_filter)>0 or connection['parent_rule_id'].find(search_filter)>0 or connection['business_documentation'].find(search_filter)>0 or connection['statement_group'].find(search_filter)>0):
                            out_list.append({'pgm_name': connection['pgm_name'],"fragment_Id":connection['fragment_Id'], 'para_name':connection['para_name'], "source_statements":connection["source_statements"], "rule_category":connection["rule_category"], "statement_group":connection["statement_group"], "parent_rule_id":connection["parent_rule_id"], "business_documentation":connection["business_documentation"]})
                else:
                    out_list.append({'pgm_name': connection['pgm_name'],"fragment_Id":connection['fragment_Id'], 'para_name':connection['para_name'], "source_statements":connection["source_statements"], "rule_category":connection["rule_category"], "statement_group":connection["statement_group"], "parent_rule_id":connection["parent_rule_id"], "business_documentation":connection["business_documentation"]})

        except KeyError as e:
            pass

        # print(connection)
        json_format={
            'data': out_list,
            'headers': ["pgm_name","para_name","source_statements", "statement_group","rule_category", "fragment_Id", "parent_rule_id", "business_documentation"]

        }
    return jsonify(json_format)





@app.errorhandler(404)
def page_not_found(e):
#    return jsonify({"status":"failure","reason":"This route does not exist"})
    return "This route does not exists"



@app.route('/api/v1/sankeyDetails', methods=['GET'])
def inout():
    inout=request.args.get('integration')
    cname=request.args.get('application_name')
    # print(inout)
    # print(cname)

    connections=db.cross_reference_report.find({"type":{'$ne':'metadata'}})
    calling_list=[]
    called_list=[]
    d={}
    metadata=[]
    for connection in connections:
        try:
            calling_list.append(connection['calling_app_name'])
            called_list.append(connection['calling_app_name']+connection['called_app_name'])

        # print(calling_list)
        # print(called_list)
        except KeyError as e :
            print(e)
        di={}
        out_list=[]
    for key in list(set(calling_list)):
        if(inout=='inbound'):
            out_list=[]
        for val in called_list:
            # print(val, cname)
            if(inout=='inbound' and val[len(key):]==cname):
                if(val[:len(key)]==key):
                   out_list.append(val[len(key):])
            elif(inout=='outbound' and key[:len(key)]==cname):
                if (val[:len(key)] == key):
                    out_list.append(val[len(key):])
                    # print(key[:len(key)])

        if(inout=='inbound'):
            di[key]=out_list
    di[cname]=out_list

    # print(di)
    out_val=[]
    for k, v in di.items():
        for li in list(set(v)):
            if k!=li:
               count=list(v).count(li)
               # print(k,li,count)
               out_val.append([k,li,count])

    # print(out_val)
    return jsonify(out_val)



@app.route('/api/v1/cicsfield', methods=['GET'])
def cicsfield():
    data_object = {}
    data_object['data'] = []
    try:
        cursor = db.cics_field.find({'type': {"$ne": "metadata"}}, {'_id': 0})
        metadata = db.cics_field.find_one({"type": "metadata"}, {'_id': 0})
        data_object['headers'] = metadata['headers']
        for document in cursor:
            # print(document)
            if len(document) > 3:
                data_object['data'].append(document)
        # print(data_object)
    except KeyError as e:
        print(e)
        pass

    # print(data_object)
    return jsonify(data_object)

@app.route("/api/v1/comment_lines")
def comment_lines():

    name = request.args.get("component_name")
    type = request.args.get("component_type")
    #print(name)
    cursor = db.cobol_output.find({"component_name": name, "component_type": type})
    json_format = ""
    for cursor1 in cursor:
        json_format = {"component_name": cursor1["component_name"], "component_type": cursor1["component_type"],
                       "commented_lines": cursor1["codeString"]}
        out={"data":json_format}
        # print(out)
    return jsonify(json_format)


@app.route("/api/v1/comment_line_report")
def comment_line_report():
    output_list = []
    cursors = db.cobol_output.find()
    print(cursors.count())
    print(cursors)
    for cursor in cursors:
        json_format = {"component_name": cursor["component_name"], "component_type": cursor["component_type"]}
        print(json_format)
        if (json_format not in output_list):
            output_list.append(json_format)
    output_json = {"data": output_list, "headers": ["component_name", "component_type"]}
    return jsonify(output_json)

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

@app.route("/api/v1/codeString")
def codeString():
    mapName= request.args.get("map_name")
    print(mapName)
    connections=db.codeString.find({"type":{"$ne":"metadata"}})
    for connection in connections:
        if(connection["MAP_NAME"]==mapName):

            d={"codeString": connection['codeString']}
            return jsonify(d)



if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0',port=5004)
