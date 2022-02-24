import pytest
# import config
from pymongo import MongoClient
import glob,os,copy
import re
import json
import csv
import sys
import time


start_time = time.time()

mongoClient = MongoClient('localhost', 27017)
db = mongoClient['asp1']




def Function_processer(function_name,dup_data):
    try:
        rule_statements = {}
        test_data= []
        # test_data.append(dup_data)
        output_json_value = {}
        function_name = function_name.split('(')[0]
        rule_statements = Rule_Extractor(function_name)
        count = 0
        for key , value in rule_statements.items():

            if rule_statements[key] != []:
                print("key=", key)
                for rules in value:
                    count = count + 1
                    output_json_value["lob"] = dup_data["lob"]
                    output_json_value["file_name"] = dup_data["file_name"]
                    output_json_value["function_name"] = key
                    output_json_value["field_name"] = dup_data["field_name"]
                    output_json_value["rule_statement"] = " \n ".join(rules)
                    output_json_value["rule_description"] = dup_data["rule_description"]
                    output_json_value["parent_rule_id"] = dup_data["rule_id"]
                    output_json_value["rule_id"] = dup_data["rule_id"] + "."+str(count)
                    output_json_value["dependent_control"] = dup_data["dependent_control"]
                    output_json_value["rule_type"] = dup_data["rule_type"]

                    # db.rule_report.insert_one(copy.deepcopy(output_json_value))
                    test_data.append(copy.deepcopy(output_json_value))
        print(json.dumps(output_json_value,indent=4))
        return output_json_value
    except Exception as e:
        exc_type, exc_obj, exc_tb = sys.exc_info()
        fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
        print(exc_type, fname, exc_tb.tb_lineno)


def Rule_Extractor(function_name):
    rule_statements = {}
    cursor = db.Code_behind_rules_1.find_one({"function_name" :function_name},{'_id':0})
    function_list = tuple(db.Code_behind_rules_1.distinct("function_name"))
    called_fun_list=[]

    for line in  cursor['source_statement'][1:]: #Start reading from Second line in the list

        #below shoret circuit expression is used to search for internal function calls.
        matches = [x for x in function_list if x in line]
        if matches != []:
            called_fun_list.append("".join(matches))


    if called_fun_list == []:
        rule_statements[function_name] =  if_to_end_if_lines(function_name)
    else:
        for i in called_fun_list:
            rule_statements[i] = if_to_end_if_lines(i)



    return rule_statements


def if_to_end_if_lines(function_name):
    collect_flag = False
    storage=[]
    rules_storage_list = []
    if_counter = 0
    cursor = db.Code_behind_rules_1.find_one({"function_name": function_name}, {'_id': 0})
    for line in cursor['source_statement'][1:]:
        if line.lower().strip().startswith("if"):
            collect_flag = True
            if_counter = if_counter+1
        if collect_flag:
            storage.append(line.strip())
        if line.lower().strip().startswith("end if"):
            if_counter = if_counter-1
            if if_counter ==0:
                collect_flag = False
                rules_storage_list.append(copy.deepcopy(storage))
                storage.clear()


    return rules_storage_list

def test_output():

    function_name = 'setchkCpPfPersPropAgrdInd() Then"'

    dup_data ={

    "function_name" : "setchkCpPfNwlBltAgrdBldgInd",
    "field_name" : "chkCpPfNwlBltAgrdBldgInd",
    "rule_statement" : [
        "                If setchkCpPfPersPropAgrdInd() Then\n",
        "                    .OnClientClick = \"chkCpPfNwlBltAgrdBldgInd_onclick();\"\n",
        "                Else\n",
        "                    .OnClientClick = \"disableTextbox('lbltxtCpPfNwlBltAgrdBldgLmt','chkCpPfNwlBltAgrdBldgInd','txtCpPfNwlBltAgrdBldgLmt');\"\n",
        "                End If\n"
    ],
    "file_name" : "CPPropertyInput.aspx",
    "rule_id" : "rule-3",
    "parent_rule_id" : "",
    "rule_description" : "",
    "rule_type" : "server_side",
    "lob" : "",
    "dependent_control" : ""
}
    assert Function_processer(function_name,dup_data) == {

            "lob": "",
            "file_name": "CPPropertyInput.aspx",
            "function_name": "setchkCpPfPersPropAgrdInd",
            "field_name": "chkCpPfNwlBltAgrdBldgInd",
            "rule_statement": "If _bNewCopCov Then .OnClientClick = \"chkCpPfPersPropAgrdInd_onclick();\" \n Else \n .OnClientClick = \"disableTextbox('lbltxtCpPfPersPropAgrdLmt','chkCpPfPersPropAgrdInd','txtCpPfPersPropAgrdLmt');\" \n End If",
            "rule_description": "",
            "parent_rule_id": "rule-3",
            "rule_id": "rule-3.1",
            "dependent_control": "",
            "rule_type": "server_side"
        }

# if __name__ == '__main__':
#     test_output()