import json

from pymongo import MongoClient
import copy
import pandas as pd
import numpy as np
hostname = 'localhost'
database_name = 'CRST_FULLDB'
port = 27017
client = MongoClient(hostname, port)
db = client[database_name]
name=""
op_path = "D:\\WORK\\Excel_op\\"
def sub_main(name,type,call_list):
    component_name = name
    component_type = type
    connections_1 = db.cross_reference_report.find(
        {"$and": [{"component_name": component_name.split(".")[0]}, {"component_type": component_type}]}, {'_id': 0})
    connections_2=copy.deepcopy(connections_1)
    call_list.extend([x["called_name"] for x in connections_1 ])
    for k in connections_2:
       sub_main(k["called_name"],"COBOL",call_list)
    return call_list

def call_chainer():
    call_data = []

    # master_data=db.master_inventory_report.find({"component_type" : "NATURAL-PROGRAM"},{"_id":0})
    master_data=db.master_inventory_report.find({"component_name" : "VREVV201.cbl"},{"_id":0})
    for json_data in master_data:
        call_list=[]
        call_data=[]
        name=json_data["component_name"]
        type="COBOL"
        call_list.append(name)
        call_data=sub_main(name,type,call_list)

        print(json.dumps(call_data,indent=4))


        with pd.ExcelWriter(op_path+call_data[0]+'.xlsx') as writer1:
            for pgm_name in call_data:
                bre_json_objects = get_bre_data_in_list(pgm_name+".")
                if bre_json_objects ==[]:
                    continue
                print("Processing for--->",pgm_name)
                dct = {
                    "Seq": [x for x in range(1,len(bre_json_objects)+1)],
                    "Process": "",
                    "Details": bre_json_objects,
                    "Notes":""
                }
                df_1 = pd.DataFrame(dct)
                bre_json_objects.clear()
                df_1.to_excel(writer1, sheet_name=pgm_name, index=False)




def get_bre_data_in_list(pgm_name):
    bre_json_objects = []
    BRE_CONN = db.bre_rules_report.find(
        {"pgm_name": pgm_name}, {'_id': 0})

    for data in BRE_CONN:
        bre_json_objects.append(data["source_statements"].replace("<br>",""))
    return bre_json_objects


call_chainer()



