import config
from pymongo import MongoClient
import glob, os
import re
import json
import csv
import sys
import time
import copy

start_time = time.time()

Version = " Not directly updating the Control ID in code behind DB"

Version2 = "Phase-2 Release -2 ,Includes the classification of IF condition"

''' 
Owwner  =Mothesh ,Kiran. 
Last Modified: 
Mothesh = 11/12/2020. 

1.Take the rules from the Rules report , which was captured as the part of the release -1.And further traced back to
 find the child rules in relase -2.  

'''
mongoClient = MongoClient('localhost', 27017)
db = mongoClient['asp3']
vb = config.codebase_information['VB']['folder_name']
code_location = config.codebase_information['code_location']

vb_path = code_location + '\\' + vb

output_json = {"section_id": "", "section_name": "", "CLAS_label": "", "comments": "", "screen_field": "",
               "CLAS_field": "", "type": "", "required": "", "for_control": "", "maximun_length": "",
               "allowkeys": "", "min-max": "", "tooltip": "", "enabled": "", "dropdown_value": "", "stored_value": "",
               "error_message": ""}
metadata = []

# Take the unique screen field from screen field db.

screen_fields_list = db.screen_data.distinct("ScreenField")
if db.drop_collection("rule_report"):
    print("deleted")


def main(filename, metadata):
    try:
        rule = 0
        section_flag = False
        section_name = ""
        sec_name = ""
        metadata = metadata
        filename = filename
        vb_source_list = []
        vb_source_list = code_behind_fun(filename)

        # code_behind_data = db.Code_behind_rules.find({"file_name": filename.split("\\")[-1].split('.')[0]})
        # code_behind_data_dup=[]

        # for k in code_behind_data:
        #     code_behind_data_dup.append(k)
        # code_behind_data_wihtout_cid=db.Code_behind_rules.find({"$and":[{"file_name":filename.split("\\")[-1].split('.')[0],"ScreenField":""}]})

        for control_id in screen_fields_list:

            code_behind_data = db.Code_behind_rules.find({"file_name": filename.split("\\")[-1].split('.')[0]})

            for data in code_behind_data:

                # if data["duplicate_flag"].split('.')[0] == "True":
                #     print(data["duplicate_flag"], control_id)
                #     continue

                if data["function_name"] == "Page_Load":
                    continue

                if data["ScreenField"] == control_id.strip():
                    if data["duplicate_flag"].split('.')[0] == "True":

                        Rule_line = db.rule_report.find_one({"$and": [{"file_name": filename.split("\\")[-1]}, {
                            "rule_id": data["duplicate_flag"].split('.')[-1]}]})
                        previous_control_id = Rule_line["ScreenField"] + "," + control_id
                        previous_control_id = previous_control_id.split(',')
                        previous_control_id = set(previous_control_id)
                        previous_control_id = list(previous_control_id)
                        db.rule_report.update_one({"_id": Rule_line["_id"]},
                                                  {"$set": {"ScreenField": ",".join(previous_control_id)}})

                        parent_rule_id_value = Rule_line["parent_rule_id"].split(',')[0] + '$|' + \
                                               Rule_line["parent_rule_id"].split(',')[0] + '[,].'

                        cursor_values = db.rule_report.find({"$and": [
                            {"parent_rule_id": {"$regex": parent_rule_id_value , "$options": "i"}},
                            {"file_name": filename.split("\\")[-1]}]})
                        for i in cursor_values:
                            db.rule_report.update_one({"_id": i["_id"]},
                                                      {"$set": {"ScreenField": ",".join(previous_control_id)}})
                        continue


                    previous_case_line = ""
                    nested_select_flag = False
                    main_select_counter = 0
                    global parent_rule_id
                    parent_rule_id = []

                    condition_split_list = spliting_of_condition_statement(data)

                    for condition_data_line_1 in condition_split_list:

                        if condition_data_line_1 == []:
                            continue

                        condition_data_line = condition_data_line_1[0]

                        if condition_data_line.upper().strip().startswith(
                                "IF") or condition_data_line.upper().strip().startswith("SELECT ") or \
                                condition_data_line.upper().strip().startswith(
                                    "CASE ") or condition_data_line.upper().strip().startswith("ELSEIF"):
                            rule = rule + 1

                            if (previous_case_line.upper().strip().startswith(
                                    "CASE ") and condition_data_line.upper().strip().startswith("CASE ")) or \
                                    ((not previous_case_line.upper().strip().startswith(
                                        "SELECT ") and condition_data_line.upper().strip().startswith("CASE "))):
                                parent_rule_id.pop()
                                previous_case_line = ""

                            if condition_data_line.upper().strip().startswith("CASE "):
                                previous_case_line = condition_data_line

                            if condition_data_line.upper().strip().startswith("SELECT "):
                                main_select_counter = main_select_counter + 1
                                previous_case_line = condition_data_line

                            if condition_data_line.upper().strip().startswith("ELSEIF"):
                                parent_rule_id.pop()
                            db.Code_behind_rules.update_one({"_id": data["_id"]},{"$set": {"duplicate_flag": "True." + control_id + ".rule-" + str(rule)}})


                            parent_rule_id.append("rule-" + str(rule))
                            db_screen_data = db.screen_data.find_one({"ScreenField": data["ScreenField"]})
                            data1 = {"function_name": data["function_name"], "ScreenField": data["ScreenField"],
                                     "SectionName": db_screen_data["SectionName"],
                                     "CLASLabel": db_screen_data["CLASLabel"], "rule_id": "rule-" + str(rule),
                                     "rule_statement": condition_data_line_1, "Rule_Relation": ",".join(parent_rule_id),
                                     "rule_description": "",
                                     "rule_type": "", "file_name": filename.split('\\')[-1], "lob": "",
                                     "dependent_control": "", "parent_rule_id": ",".join(parent_rule_id)}

                            db.rule_report.insert_one(data1)

                            global dup_data
                            dup_data = data1
                            global counter
                            counter = 0
                            global rule_id_data
                            rule_id_data = data1["rule_id"]
                            for j in condition_data_line_1:
                                # if j.__contains__("End If") or j.__contains__("End Select") or (j.strip().upper().startswith("CASE ") and  main_select_counter <= 1):
                                if j.__contains__("End If") or j.__contains__("End Select"):
                                    parent_rule_id.pop()
                                    previous_case_line = ""
                                    if j.__contains__("End Select"):
                                        parent_rule_id.pop()
                                        main_select_counter = main_select_counter - 1

                            if not (data1["parent_rule_id"].__contains__(',')):
                                back_trace_fun(
                                    data1)

                            if not (data1['rule_statement'][
                                        0].strip().upper().startswith('SELECT ') or data1['rule_statement'][
                                        0].strip().upper().startswith('CASE ')):
                                classification_of_if(data1)

                        else:
                            db_screen_data = db.screen_data.find_one({"ScreenField": data["ScreenField"]})
                            db.rule_report.insert_one(
                                {"function_name": data["function_name"], "ScreenField": data["ScreenField"],
                                 "SectionName": db_screen_data["SectionName"], "CLASLabel": db_screen_data["CLASLabel"],
                                 "rule_id": "", "rule_statement": condition_data_line_1,
                                 "Rule_Relation": ",".join(parent_rule_id), "rule_description": "",
                                 "rule_type": "", "file_name": filename.split('\\')[-1], "lob": "",
                                 "dependent_control": "", "parent_rule_id": ",".join(parent_rule_id)})
                            for j in condition_data_line_1:
                                if j.__contains__("End If") or (
                                        j.__contains__("End Select") and not main_select_counter > 1):
                                    if j.__contains__("End Select"):
                                        parent_rule_id.pop()
                                        main_select_counter = main_select_counter - 1
                                    parent_rule_id.pop()

                    # db.rule_report.insert_one(data)
                    # classification_of_if(data) # This function further track back and find the parent rules.
                elif data["ScreenField"] == "":
                    for line1 in data["rule_statement"]:
                        # if line1.strip().startswith("if ") or line1.strip().startswith("If ") or \
                        #           line1.strip().startswith("if(") or line1.strip().startswith("If(") or \
                        #     line1.strip().startswith("Case ") or line1.strip().startswith("Select "):
                        #     continue
                        control_id_dup = ' ' + control_id + '.'
                        if control_id_dup in line1:
                            if data["duplicate_flag"].split('.')[0] == "True":

                                Rule_line = db.rule_report.find_one({"$and": [{"file_name": filename.split("\\")[-1]}, {
                                    "rule_id": data["duplicate_flag"].split('.')[-1]}]})
                                previous_control_id = Rule_line["ScreenField"] + "," + control_id
                                previous_control_id = previous_control_id.split(',')
                                previous_control_id = set(previous_control_id)
                                previous_control_id = list(previous_control_id)
                                db.rule_report.update_one({"_id": Rule_line["_id"]},
                                                          {"$set": {"ScreenField": ",".join(previous_control_id)}})
                                parent_rule_id_value = Rule_line["parent_rule_id"].split(',')[0] + '$|' + Rule_line["parent_rule_id"].split(',')[0] + '[,].'


                                cursor_values = db.rule_report.find({"$and": [
                                    {"parent_rule_id": {"$regex": parent_rule_id_value ,
                                                        "$options": "i"}},
                                    {"file_name": filename.split("\\")[-1]}]})
                                for i in cursor_values:
                                    db.rule_report.update_one({"_id": i["_id"]},
                                                              {"$set": {"ScreenField": ",".join(previous_control_id)}})
                                continue


                            # rule=rule+1
                            # data.update(
                            #     {"ScreenField":control_id,"rule_id": "rule-" + str(rule), "Rule_Relation": "",
                            #      "rule_description": "",
                            #      "rule_type": "", "file_name": filename.split('\\')[-1],"lob":"","dependent_control":""})

                            previous_case_line = ""
                            nested_select_flag = False
                            main_select_counter = 0
                            parent_rule_id = []
                            condition_split_list = spliting_of_condition_statement(data)

                            for condition_data_line_1 in condition_split_list:

                                if condition_data_line_1 == []:
                                    continue

                                condition_data_line = condition_data_line_1[0]

                                if condition_data_line.upper().strip().startswith(
                                        "IF ") or condition_data_line.upper().strip().startswith("SELECT ") or \
                                        condition_data_line.upper().strip().startswith(
                                            "CASE ") or condition_data_line.upper().strip().startswith("ELSEIF "):
                                    rule = rule + 1

                                    if (previous_case_line.upper().strip().startswith(
                                            "CASE ") and condition_data_line.upper().strip().startswith("CASE ")) or \
                                            ((not previous_case_line.upper().strip().startswith(
                                                "SELECT ") and condition_data_line.upper().strip().startswith(
                                                "CASE "))):
                                        parent_rule_id.pop()
                                        previous_case_line = ""

                                    if condition_data_line.upper().strip().startswith("CASE "):
                                        previous_case_line = condition_data_line

                                    if condition_data_line.upper().strip().startswith("SELECT "):
                                        main_select_counter = main_select_counter + 1
                                        previous_case_line = condition_data_line

                                    if condition_data_line.upper().strip().startswith("ELSEIF"):
                                        parent_rule_id.pop()
                                    db.Code_behind_rules.update_one({"_id": data["_id"]}, {
                                        "$set": {"duplicate_flag": "True." + control_id + ".rule-" + str(rule)}})

                                    parent_rule_id.append("rule-" + str(rule))
                                    db_screen_data = db.screen_data.find_one({"ScreenField": control_id})
                                    data1 = {"function_name": data["function_name"], "ScreenField": control_id,
                                             "SectionName": db_screen_data["SectionName"],
                                             "CLASLabel": db_screen_data["CLASLabel"],
                                             "rule_id": "rule-" + str(rule), "rule_statement": condition_data_line_1,
                                             "Rule_Relation": ",".join(parent_rule_id), "rule_description": "",
                                             "rule_type": "", "file_name": filename.split('\\')[-1], "lob": "",
                                             "dependent_control": "", "parent_rule_id": ",".join(parent_rule_id)}

                                    dup_data = data1
                                    db.rule_report.insert_one(data1)

                                    counter = 0

                                    for j in condition_data_line_1:
                                        # if j.__contains__("End If") or j.__contains__("End Select") or (j.strip().upper().startswith("CASE ") and  main_select_counter <= 1):
                                        if j.__contains__("End If") or j.__contains__("End Select"):
                                            parent_rule_id.pop()
                                            previous_case_line = ""
                                            if j.__contains__("End Select"):
                                                parent_rule_id.pop()
                                                main_select_counter = main_select_counter - 1

                                    if not (data1["parent_rule_id"].__contains__(',')):
                                        back_trace_fun(
                                            data1)

                                    if not (data1['rule_statement'][
                                                0].strip().upper().startswith('SELECT ') or
                                            data1['rule_statement'][
                                                0].strip().upper().startswith('CASE ')):
                                        rule_id_data = data1["rule_id"]
                                        classification_of_if(data1)

                                    # classification_of_if(data1)

                                else:
                                    db_screen_data = db.screen_data.find_one({"ScreenField": control_id})
                                    db.rule_report.insert_one(
                                        {"function_name": data["function_name"], "ScreenField": control_id,
                                         "SectionName": db_screen_data["SectionName"],
                                         "CLASLabel": db_screen_data["CLASLabel"],
                                         "rule_id": "", "rule_statement": condition_data_line_1,
                                         "Rule_Relation": ",".join(parent_rule_id),
                                         "rule_description": "",
                                         "rule_type": "", "file_name": filename.split('\\')[-1], "lob": "",
                                         "dependent_control": "", "parent_rule_id": ",".join(parent_rule_id)})
                                    for j in condition_data_line_1:
                                        if j.__contains__("End If") or (
                                                j.__contains__("End Select") and not main_select_counter > 1):
                                            if j.__contains__("End Select"):
                                                parent_rule_id.pop()
                                                main_select_counter = main_select_counter - 1
                                            parent_rule_id.pop()

                            # metadata.append(data)
                            # db.rule_report.insert_one(data)
                            # classification_of_if(data)  # This function further track back and find the parent rules.
                            break

        # Writing the data from DB to Excel.

        out_data = []
        metadata_1 = db.rule_report.find({}, {"parent_rule_id": 0, "dependent_control": 0})
        for screen_data_1 in metadata_1:
            screen_data_1.pop("_id")
            screen_data_1.update({"rule_statement": " ".join(screen_data_1["rule_statement"])})
            out_data.append(screen_data_1)

        with open("rule_report" + '.csv', 'w', newline="") as output_file:
            Fields = ["rule_id", "file_name", "function_name", "ScreenField", "SectionName", "CLASLabel",
                      "rule_statement", "Rule_Relation", "rule_description", "rule_type", "lob", "dependent_control",
                      "parent_rule_id", "External_rule_id"]
            dict_writer = csv.DictWriter(output_file, fieldnames=Fields)
            dict_writer.writeheader()
            dict_writer.writerows(out_data)

        # if metadata!=[]:
        #     if db.drop_collection("rule_report"):
        #         print("deleted")
        #         for j in metadata:
        #             db.rule_report.insert_one(j)
        # if db.rule_report.insert_many(metadata):
        #
        #     print("inserted")

    except Exception as e:
        exc_type, exc_obj, exc_tb = sys.exc_info()
        fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
        print(exc_type, fname, exc_tb.tb_lineno)
        pass


def spliting_of_condition_statement(data):
    '''
     :param data: Json value
     :return:splits the if condition if it has nested conditions.
    '''

    try:
        if_counter = 0
        case_counter = 0
        if_list = []
        flag = False
        main_list = []
        for condition_line in data['rule_statement']:

            select_flag_regexx_1 = re.findall(r'^\s*select\s*case\s*.*', condition_line, re.IGNORECASE)

            end_select_regexx_1 = re.findall(r'^\s*end\s*select\s*', condition_line, re.IGNORECASE)

            case_regexx_1 = re.findall(r'^\s*case\s*.*', condition_line, re.IGNORECASE)

            if_regexx_1 = re.findall(r'^\s*\t*IF\s.*', condition_line, re.IGNORECASE)

            if1_regexx_1 = re.findall(r'^\s*\t*IF\s*[(].*', condition_line, re.IGNORECASE)

            end_if_regexx_1 = re.findall(r'^\s*\t*END\s*IF\s*', condition_line, re.IGNORECASE)

            else_if_regexx = re.findall(r'^\s*ElseIf\s*.*', condition_line, re.IGNORECASE)

            if else_if_regexx != []:

                if if_counter > 1:
                    main_list.append(if_list)
                    if_list = []

                if_counter = if_counter - 1

                # if if_counter == 0:
                #     main_list.append(if_list)
                #     flag = False

            if if_regexx_1 != [] or if1_regexx_1 != [] or select_flag_regexx_1 != [] or case_regexx_1 != [] or else_if_regexx != []:

                if_counter = if_counter + 1
                if if_counter > 1:
                    main_list.append(if_list)
                    if_list = []
                flag = True
                if case_regexx_1 != []:
                    case_counter = case_counter + 1
                    if not case_counter == 1:
                        if_counter = if_counter - 1

            if flag:
                if_list.append(condition_line)

            if end_if_regexx_1 != [] or end_select_regexx_1 != []:

                if if_counter > 1:
                    main_list.append(if_list)
                    if_list = []

                if_counter = if_counter - 1

                if if_counter == 0:
                    main_list.append(if_list)
                    flag = False

        return main_list
    except Exception as e:
        exc_type, exc_obj, exc_tb = sys.exc_info()
        fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
        print(exc_type, fname, exc_tb.tb_lineno)
        pass


def code_behind_fun(filename):
    try:
        '''
        :param filename:
    
        1.This function is used to create to Temporary collection in DB code_behind_rule and code_behind_rule_1.
        2.First the code_behind_rule collection will contains all the IF condition that are present in the code behind file along
        with the filename , function name and field_name.
        3.Second code_behind_rule_1 collection will have function name and its respective lines of code.Each function will create
        new row in collection.It is used in function track back.
        :return:
        Two collections with data in the required format.
        '''

        metadata = []

        metadata_1 = []

        if_flag = False

        select_flag = False

        if_counter = 0

        cid_name = ""

        function_name = ""

        dup_function_name = ""

        if_data_list = []
        select_data_list = []
        dup_flag = False
        full_data_list = []
        select_counter = 0

        # with open(filename + '.vb', 'r') as input_file:
        #    with open("temp_file.txt","a") as out_file:
        #     end_if_handled = single_line_if(input_file)
        #     for line in end_if_handled:
        #
        #         out_file.write(line)
        #    out_file.close()
        # input_file.close()

        # with open("temp_file"+'.txt', 'r') as input_file:
        with open(filename + '.vb', 'r') as input_file:
            end_if_handled = single_line_if(input_file)

            for line in end_if_handled:

                if line.strip() == "" or line.strip().startswith("'"):
                    continue

                # function_name_regexx=re.findall(r'^\s*PRIVATE\s*SUB\s*[A0-Z9]*[(][a0-z9]*[)]\s*.*',line,re.IGNORECASE)

                function_name_regexx = re.findall(r'^\s*PRIVATE\s*SUB\s*[A0-Z9_]*[(].*', line, re.IGNORECASE)

                function_name_2_regexx = re.findall(r'^\s*PROTECTED\s*SUB\s*[A0-Z9_]*[(].*', line, re.IGNORECASE)

                function_name_1_regexx = re.findall(r'^\s*\t*PUBLIC\s*SHARED\s*FUNCTION\s*[A0-Z9_]*[(].*', line,
                                                    re.IGNORECASE)

                function_name_3_regexx = re.findall(r'^\s*\t*PUBLIC\s*SUB\s*[A0-Z9_]*[(].*', line, re.IGNORECASE)

                function_name_4_regexx = re.findall(r'^\s*\t*PRIVATE\s*FUNCTION\s*[A0-Z9_]*[(].*', line, re.IGNORECASE)

                end_sub = re.findall(r'^\s*end\s*sub\s*', line, re.IGNORECASE)

                select_flag_regexx = re.findall(r'^\s*select\s*case\s*.*', line, re.IGNORECASE)

                end_select_regexx = re.findall(r'^\s*end\s*select\s*', line, re.IGNORECASE)

                case_regexx = re.findall(r'^\s*case\s*.*', line, re.IGNORECASE)

                end_function = re.findall(r'^\s*end\s*function', line, re.IGNORECASE)

                if_regexx = re.findall(r'^\s*\t*IF\s.*', line, re.IGNORECASE)

                if1_regexx = re.findall(r'^\s*\t*IF\s*[(].*', line, re.IGNORECASE)

                end_if_regexx = re.findall(r'^\s*\t*END\s*IF\s*', line, re.IGNORECASE)

                with_regexx = re.findall(r'^\s*With\s*.*', line, re.IGNORECASE)

                end_with_regexx = re.findall(r'^\s*\t*end\s*with\s*', line, re.IGNORECASE)

                if function_name_regexx != [] or function_name_3_regexx != [] or function_name_2_regexx != [] or function_name_4_regexx != []:

                    if function_name_3_regexx != []:
                        fun_value = function_name_3_regexx
                    elif function_name_regexx != []:
                        fun_value = function_name_regexx
                    elif function_name_2_regexx != []:
                        fun_value = function_name_2_regexx
                    elif function_name_4_regexx != []:
                        fun_value = function_name_4_regexx

                    function_name = fun_value[0].strip().split(' ')[2].split('(')[0]
                    cid_name = ""
                    if_data_list = []
                    dup_flag = True

                if function_name_1_regexx != []:
                    function_name = function_name_1_regexx[0].strip().split(' ')[3].split('(')[0]
                    cid_name = ""
                    if_data_list = []
                    dup_flag = True

                if dup_flag:
                    full_data_list.append(line.replace("\t", ""))

                if end_sub != [] or end_function != []:
                    metadata_1.append(
                        {"file_name": filename.split('\\')[-1].split('.')[0], "function_name": function_name,
                         "source_statement": full_data_list, "duplicate_flag": "false"})
                    dup_flag = False
                    full_data_list = []

                if with_regexx != []:
                    cid_name = with_regexx[0].strip().split(' ')[1]
                    # if cid_name.strip()=="stateinput":
                    #     cid_name=""
                if end_with_regexx != []:
                    cid_name = ""
                    # if_counter=0

                # if end_sub != []:
                #
                #     # if cid_name == "":
                #     #     for data in if_data_list:
                #     #         if data.strip().startswith('IF '):
                #     #             continue
                #     #         else:
                #     #             id_regexx = re.findall(r'^\s*[A0-Z9].*\..*\.Value\s*=\s*.*', data, re.IGNORECASE)
                #     #             if id_regexx != []:
                #     #                 direct_id_name = id_regexx[0].strip().split('.')[0]
                #     #                 cid_name = direct_id_name
                #
                #     if if_data_list != []:
                #         if_data_list="<br>".join(if_data_list)
                #
                #         metadata.append(
                #             {"funtion_name": function_name, "cid_name": cid_name, "source_statement": if_data_list})

                if select_flag_regexx != [] and if_data_list == []:
                    select_flag = True
                    select_counter = select_counter + 1

                if select_flag:
                    if not line.strip() == "":
                        select_data_list.append(line.replace("\t", ""))

                if end_select_regexx != [] and select_data_list != []:

                    select_counter = select_counter - 1

                    if select_counter == 0:
                        metadata.append(
                            {"function_name": function_name, "ScreenField": cid_name,
                             "rule_statement": select_data_list,
                             "file_name": filename.split('\\')[-1].split('.')[0], "duplicate_flag": "false"})
                        select_data_list = []
                        select_flag = False

                if (if1_regexx != [] or if_regexx != []) and select_data_list == []:
                    if_counter = if_counter + 1
                    if_flag = True

                if if_flag:

                    if not line.strip() == "":
                        if_data_list.append(line.replace("\t", ""))

                if end_if_regexx != [] and if_data_list != []:

                    if_counter = if_counter - 1  # Counter is introduced to capture the nested IF conditions.

                    if if_counter == 0:  # At the end of condition , appedning the captured data to global list named as metadata.
                        if_flag = False

                        metadata.append(
                            {"function_name": function_name, "ScreenField": cid_name, "rule_statement": if_data_list,
                             "file_name": filename.split('\\')[-1].split('.')[0], "duplicate_flag": "false"})
                        if_data_list = []

        if metadata_1 != []:
            if db.drop_collection("Code_behind_rules_1"):
                print("1deleted")
            if db.Code_behind_rules_1.insert_many(metadata_1):
                print("1inserted")

        if metadata != []:
            if db.drop_collection("Code_behind_rules"):
                print("1deleted")
            if db.Code_behind_rules.insert_many(metadata):
                print("1inserted")
        return metadata
    except Exception as e:
        exc_type, exc_obj, exc_tb = sys.exc_info()
        fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
        print(exc_type, fname, exc_tb.tb_lineno)
        pass


def classification_of_if(data):
    try:
        '''
        :param data: Input Json
        1.In this function ,each rules captured as part of phase-2 release -1 will be sent as input one by one in json format.
        2.Each IF statement may lies in more than one line.
        3.At first convert  multi line statement into single line statement for our conveinence.
        4.Then separate the single condition statement and multiple condition statement.
        5.In the multiple condition block , separate the multiple condition into a list using the connection keywords.
        6.After separating ,using the for loop sent each condition into another function by adding IF and then statement in front and back of the condition.
        :return:
        '''
        # global dup_data
        # dup_data = data

        if_line_flag = False
        if_statement_string = ""
        if_statement_list = []
        # global counter
        # counter=0

        # if not (data["parent_rule_id"].__contains__(',') or data['rule_statement'][0].strip().upper().startswith('SELECT ')):
        #     back_trace_fun(
        #         data)  # This function is used to trace back and find rules for all the if condition using their function name.

        # Making multi line if statement to single line IF.

        for line_2 in data["rule_statement"]:

            if (line_2.strip().startswith("If ") or line_2.strip().startswith("If(")) and (
                    line_2.strip().endswith(' Then') or line_2.strip().__contains__(' Then')) \
                    or line_2.strip().startswith("ElseIf "):
                if_statement_string = line_2.strip()
                break
            elif (line_2.strip().startswith("If ") or line_2.strip().startswith("If(")) or line_2.strip().startswith(
                    "ElseIf ") and not line_2.strip().endswith(' Then'):
                if_statement_list.append(line_2.strip())
                if_line_flag = True
            elif if_line_flag:
                if_statement_list.append(line_2.strip())
                if line_2.strip().endswith(" Then"):
                    if_statement_string = " ".join(if_statement_list)
                    if_line_flag = False
                    break

        # if_statement_string = if_statement_string.replace(' Then' , ' Then \n')
        # Segregation of IF.

        if if_statement_string.__contains__(" OrElse ") or if_statement_string.__contains__(
                " AndAlso ") or if_statement_string.__contains__(" Or ") \
                or if_statement_string.__contains__(" And "):

            if if_statement_string.strip().startswith("If "):
                if_statement = if_statement_string.replace('If ', '').replace(' Then',
                                                                              '')  # Delete the IF and Then statement in the if condition.
            elif if_statement_string.strip().startswith("ElseIf "):
                if_statement = if_statement_string.replace('ElseIf ', '').replace(' Then', '')

            if_equals_value = if_statement.split('.')[-1]

            if if_statement.strip().startswith('(') and if_statement.strip().endswith(')'):

                if if_equals_value.startswith("Equals") and if_equals_value.endswith('))'):

                    if_statement = if_statement[1:len(if_statement) - 1]

                elif if_equals_value.startswith("Equals") and if_equals_value.endswith(')'):

                    if_statement = if_statement[1:len(if_statement)]

                else:

                    if if_statement.strip().startswith('(') and if_statement.strip().endswith('))'):
                        if_statement = if_statement[1:len(if_statement) - 2]
                    else:
                        if_statement = if_statement[1:len(if_statement) - 1]

                    # If a single IF statement has multiple condition, we are spliting that using  'orelse,andalso,and,or' keywords.

            if_statement_1 = if_statement.split(' OrElse ')
            if_statement_2_list = []
            if_statement_3_list = []
            if_statement_4_list = []
            for k in if_statement_1:
                if_statement_2 = k.split(' AndAlso ')
                if len(if_statement_2) == 1:
                    if_statement_2_list.append(if_statement_2[0])
                elif len(if_statement_2) > 1:
                    for l in if_statement_2:
                        if_statement_2_list.append(l)

            for k in if_statement_2_list:
                if_statement_3 = k.split(' And ')
                if len(if_statement_3) == 1:
                    if_statement_3_list.append(if_statement_3[0])
                elif len(if_statement_3) > 1:
                    for l in if_statement_3:
                        if_statement_3_list.append(l)

            for k in if_statement_3_list:
                if_statement_4 = k.split(' Or ')
                if len(if_statement_4) == 1:
                    if_statement_4_list.append(if_statement_4[0])
                elif len(if_statement_4) > 1:
                    for l in if_statement_4:
                        if_statement_4_list.append(l)

            for statement in if_statement_4_list:

                if statement.strip().startswith('(String'):

                    statement = statement[1:]
                    if statement.strip().endswith(')))'):
                        statement = statement[0:-2]
                    elif statement.strip().endswith('))'):
                        statement = statement[0:-1]
                elif statement.strip().startswith('String'):
                    if statement.strip().endswith(')))'):
                        statement = statement[0:-2]
                    elif statement.strip().endswith('))'):
                        statement = statement[0:-1]
                elif statement.strip().startswith('(') and not statement.strip().startswith('(String'):
                    statement = statement[1:]
                    if statement.strip().endswith(')'):
                        statement = statement[0:-1]
                statement = 'If ' + statement + ' Then '

                if_function(statement, data)

        else:

            # if a condition statement has only one condition.

            if_statement_7 = if_statement_string.split('Then')[0]

            if_statement_7 = if_statement_7.replace('If ', '').replace(' Then', '')

            if if_statement_7.strip().startswith('(') and if_statement_7.strip().endswith(')'):

                if_statement_6 = 'If ' + if_statement_7[1:-1] + ' Then'

            else:

                if_statement_6 = if_statement_string

            if_function(if_statement_6, data)

    except Exception as e:
        exc_type, exc_obj, exc_tb = sys.exc_info()
        fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
        print(exc_type, fname, exc_tb.tb_lineno)
        pass


def variable_back_trace_fun(if_statement_string, data):
    try:
        '''
        :param data: Input Json
        1.In this function ,each rules captured as part of phase-2 release -1 will be sent as input one by one in json format.
        2.Each IF statement may lies in more than one line.
        3.At first convert  multi line statement into single line statement for our conveinence.
        4.Then separate the single condition statement and multiple condition statement.
        5.In the multiple condition block , separate the multiple condition into a list using the connection keywords.
        6.After separating ,using the for loop sent each condition into another function by adding IF and then statement in front and back of the condition.
        :return:
        '''
        # global dup_data
        # dup_data = data
        if_line_flag = False
        # if_statement_string = ""
        if_statement_list = []
        # global counter
        # counter=0

        # if not (data["parent_rule_id"].__contains__(',') or data['rule_statement'][0].strip().upper().startswith('SELECT ')):
        #     back_trace_fun(
        #         data)  # This function is used to trace back and find rules for all the if condition using their function name.

        # Making multi line if statement to single line IF.

        # Segregation of IF.

        if if_statement_string.__contains__(" OrElse ") or if_statement_string.__contains__(
                " AndAlso ") or if_statement_string.__contains__(" Or ") \
                or if_statement_string.__contains__(" And "):

            if if_statement_string.strip().startswith("If "):
                if_statement = if_statement_string.replace('If ', '').replace(' Then',
                                                                              '')  # Delete the IF and Then statement in the if condition.
            elif if_statement_string.strip().startswith("ElseIf "):
                if_statement = if_statement_string.replace('ElseIf ', '').replace(' Then', '')

            if_equals_value = if_statement.split('.')[-1]

            if if_statement.strip().startswith('(') and if_statement.strip().endswith(')'):

                if if_equals_value.startswith("Equals") and if_equals_value.endswith('))'):

                    if_statement = if_statement[1:len(if_statement) - 1]

                elif if_equals_value.startswith("Equals") and if_equals_value.endswith(')'):

                    if_statement = if_statement[1:len(if_statement)]

                else:

                    if_statement = if_statement[1:len(if_statement) - 2]

                    # If a single IF statement has multiple condition, we are spliting that using  'orelse,andalso,and,or' keywords.

            if_statement_1 = if_statement.split(' OrElse ')
            if_statement_2_list = []
            if_statement_3_list = []
            if_statement_4_list = []
            for k in if_statement_1:
                if_statement_2 = k.split(' AndAlso ')
                if len(if_statement_2) == 1:
                    if_statement_2_list.append(if_statement_2[0])
                elif len(if_statement_2) > 1:
                    for l in if_statement_2:
                        if_statement_2_list.append(l)

            for k in if_statement_2_list:
                if_statement_3 = k.split(' And ')
                if len(if_statement_3) == 1:
                    if_statement_3_list.append(if_statement_3[0])
                elif len(if_statement_3) > 1:
                    for l in if_statement_3:
                        if_statement_3_list.append(l)

            for k in if_statement_3_list:
                if_statement_4 = k.split(' Or ')
                if len(if_statement_4) == 1:
                    if_statement_4_list.append(if_statement_4[0])
                elif len(if_statement_4) > 1:
                    for l in if_statement_4:
                        if_statement_4_list.append(l)

            for statement in if_statement_4_list:

                if statement.strip().startswith('(String'):

                    statement = statement[1:]
                    if statement.strip().endswith(')))'):
                        statement = statement[0:-2]
                    elif statement.strip().endswith('))'):
                        statement = statement[0:-1]
                elif statement.strip().startswith('String'):
                    if statement.strip().endswith(')))'):
                        statement = statement[0:-2]
                    elif statement.strip().endswith('))'):
                        statement = statement[0:-1]
                elif statement.strip().startswith('(') and not statement.strip().startswith('(String'):
                    statement = statement[1:]
                    if statement.strip().endswith(')'):
                        statement = statement[0:-1]
                statement = 'If ' + statement + ' Then '

                if_function(statement, data)

        else:

            # if a condition statement has only one condition.

            if_statement_7 = if_statement_string.replace('If ', '').replace(' Then', '')

            if if_statement_7.strip().startswith('(') and if_statement_7.strip().endswith(')'):

                if_statement_6 = 'If ' + if_statement_7[1:-1] + ' Then'

            else:
                if_statement_6 = if_statement_string

            if_function(if_statement_6, data)

    except Exception as e:
        exc_type, exc_obj, exc_tb = sys.exc_info()
        fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
        print(exc_type, fname, exc_tb.tb_lineno)
        pass


def left_variable_back_trace_fun(if_statement_string, data):
    try:
        '''
        :param data: Input Json
        1.In this function ,each rules captured as part of phase-2 release -1 will be sent as input one by one in json format.
        2.Each IF statement may lies in more than one line.
        3.At first convert  multi line statement into single line statement for our conveinence.
        4.Then separate the single condition statement and multiple condition statement.
        5.In the multiple condition block , separate the multiple condition into a list using the connection keywords.
        6.After separating ,using the for loop sent each condition into another function by adding IF and then statement in front and back of the condition.
        :return:
        '''
        # global dup_data
        # dup_data = data
        if_line_flag = False
        # if_statement_string = ""
        if_statement_list = []
        # global counter
        # counter=0

        # if not (data["parent_rule_id"].__contains__(',') or data['rule_statement'][0].strip().upper().startswith('SELECT ')):
        #     back_trace_fun(
        #         data)  # This function is used to trace back and find rules for all the if condition using their function name.

        # Making multi line if statement to single line IF.

        # Segregation of IF.

        if if_statement_string.__contains__(" OrElse ") or if_statement_string.__contains__(
                " AndAlso ") or if_statement_string.__contains__(" Or ") \
                or if_statement_string.__contains__(" And "):

            if if_statement_string.strip().startswith("If "):
                if_statement = if_statement_string.replace('If ', '').replace(' Then',
                                                                              '')  # Delete the IF and Then statement in the if condition.
            elif if_statement_string.strip().startswith("ElseIf "):
                if_statement = if_statement_string.replace('ElseIf ', '').replace(' Then', '')

            if_equals_value = if_statement.split('.')[-1]

            if if_statement.strip().startswith('(') and if_statement.strip().endswith(')'):

                if if_equals_value.startswith("Equals") and if_equals_value.endswith('))'):

                    if_statement = if_statement[1:len(if_statement) - 1]

                elif if_equals_value.startswith("Equals") and if_equals_value.endswith(')'):

                    if_statement = if_statement[1:len(if_statement)]

                else:

                    if_statement = if_statement[1:len(if_statement) - 2]

                    # If a single IF statement has multiple condition, we are spliting that using  'orelse,andalso,and,or' keywords.

            if_statement_1 = if_statement.split(' OrElse ')
            if_statement_2_list = []
            if_statement_3_list = []
            if_statement_4_list = []
            for k in if_statement_1:

                if_statement_2 = k.split(' AndAlso ')
                if len(if_statement_2) == 1:
                    if_statement_2_list.append(if_statement_2[0])
                elif len(if_statement_2) > 1:
                    for l in if_statement_2:
                        if_statement_2_list.append(l)

            for k in if_statement_2_list:
                if_statement_3 = k.split(' And ')
                if len(if_statement_3) == 1:
                    if_statement_3_list.append(if_statement_3[0])
                elif len(if_statement_3) > 1:
                    for l in if_statement_3:
                        if_statement_3_list.append(l)

            for k in if_statement_3_list:

                if_statement_4 = k.split(' Or ')
                if len(if_statement_4) == 1:

                    if_statement_4_list.append(if_statement_4[0])
                elif len(if_statement_4) > 1:
                    for l in if_statement_4:
                        if_statement_4_list.append(l)

            for statement in if_statement_4_list:

                if statement.strip().startswith('(String'):

                    statement = statement[1:]
                    if statement.strip().endswith(')))'):
                        statement = statement[0:-2]
                    elif statement.strip().endswith('))'):
                        statement = statement[0:-1]
                elif statement.strip().startswith('String'):
                    if statement.strip().endswith(')))'):
                        statement = statement[0:-2]
                    elif statement.strip().endswith('))'):
                        statement = statement[0:-1]
                elif statement.strip().startswith('(') and not statement.strip().startswith('(String'):
                    statement = statement[1:]
                    if statement.strip().endswith(')'):
                        statement = statement[0:-1]
                statement = 'If ' + statement + ' Then '

                left_if_function(statement, data)

        else:

            # if a condition statement has only one condition.

            if_statement_7 = if_statement_string.replace('If ', '').replace(' Then', '')

            if if_statement_7.strip().startswith('(') and if_statement_7.strip().endswith(')'):

                if_statement_6 = 'If ' + if_statement_7[1:-1] + ' Then'

            else:
                if_statement_6 = if_statement_string

            left_if_function(if_statement_6, data)

    except Exception as e:
        exc_type, exc_obj, exc_tb = sys.exc_info()
        fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
        print(exc_type, fname, exc_tb.tb_lineno)
        pass


def if_function(if_statement_string, json_data):
    try:
        '''
         :param if_statement_string: Only condition lines.
         :param data: release-1 Json
         :return: Type of the condition
         1.This function is used to find the type of the condition. The input of the function will be condition statement.
         2.IF the condition statement startwith string keyword ,then the condition line is splited with ','.And the second
         index is taken as input.
         3.IF the second index startswith double quotes then it is a direct if pattern.FOr direct pattern no further process
         is needed.
         4.IF it does not startwith quotes then it can be possibly of variable or function pattern.For there the variable
         function is called for further process.
         5.In the else statement, if the condition has  any operators , then using the operator the condition is splitted.
         and same second index is taken.
         for that also if it startws with quotes then it is remains untouched considering it as direct if patter.
         6.If not send that condition to further processing.
         7.IF the input does not  falls under any of the two condition above, then considering than condition as variable or
         function pattern.
         and sending that condition to further processing.
        '''

        boolean_list = ["TRU", "FALS", "FALSE)", "TRUE)", "TRUE", "FALSE", '"Y"', '"N"']

        if_value = if_statement_string.replace('If ', '').replace(' Then', '')

        if if_value.strip().__contains__(" HashSet") and if_value.strip().__contains__("Contains"):
            db.rule_report.update_one({"_id": dup_data["_id"]}, {"$set": {"rule_type": "direct_rule"}})

        elif if_value.strip().__contains__(".Attributes"):
            db.rule_report.update_one({"_id": dup_data["_id"]}, {"$set": {"rule_type": "direct_rule"}})

        elif if_value.strip().startswith('String.') or if_value.__contains__(' String.'):

            if if_value.__contains__(','):
                if_value_1 = if_value.split(',')[1].strip()
                if if_value_1.startswith('"') or if_value_1.startswith("'"):
                    db.rule_report.update_one({"_id": dup_data["_id"]}, {"$set": {"rule_type": "direct_rule"}})
                    pass

                else:
                    # variable function has to be called.
                    db.rule_report.update_one({"_id": dup_data["_id"]},
                                              {"$set": {"rule_type": "variable_type_rule"}})
                    variable_if_fun(if_value.split(',')[1].split('.')[0])  # sending only the variable

            elif (if_value.__contains__(".Input(") or if_value.__contains__(".Fields(")):

                if if_value.__contains__(".Input("):
                    if if_value.split(".Input")[1].split('.')[0][1:-1].startswith('"'):
                        None
                    else:

                        variable_if_fun(if_value.split(".Input")[1].split('.')[0][1:-1])

                elif if_value.__contains__(".Fields("):
                    if if_value.split(".Fields")[1].split('.')[0][1:-1].startswith('"'):

                        None
                    else:

                        variable_if_fun(if_value.split(".Fields")[1].split('.')[0][1:-1])

            elif if_value.__contains__(".Equals("):  # Direct
                # LHS
                if_value_data = if_value.split(".Equals")[1]
                if if_value_data.strip().startswith('(') and if_value_data.strip().endswith(')'):
                    if_value_data = if_value_data[1:-1]
                    if not if_value_data.upper() in boolean_list and not if_value_data.strip().startswith('"'):
                        db.rule_report.update_one({"_id": dup_data["_id"]},
                                                  {"$set": {"rule_type": "variable_type_rule"}})

                        variable_if_fun(if_value_data.strip())

                # RHS
                if_value_data = if_value.split(".Equals")[0].split('String.')[1].split('(')[1][:-1]
                if not if_value_data.upper() in boolean_list and not if_value_data.strip().startswith('"'):
                    db.rule_report.update_one({"_id": dup_data["_id"]},
                                              {"$set": {"rule_type": "variable_type_rule"}})

                    variable_if_fun(if_value_data.strip())

            else:
                # for Right hand side check ,we are leaving this if conditon by considering as direct.
                db.rule_report.update_one({"_id": dup_data["_id"]}, {"$set": {"rule_type": "direct_rule"}})


        elif if_value.__contains__('=') or if_value.__contains__('>') or if_value.__contains__('<'):

            number_list = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
            if if_value.__contains__('='):
                if_value_2 = if_value.split('=')[1].replace('>', '').replace('<', '')

                if if_value_2.strip().startswith('"'):
                    None
                elif if_value_2.strip().endswith(')') and not if_value_2.strip().__contains__('('):
                    if_value_2 = if_value_2.strip()[:-1]

                left_if_value_2 = if_value.split('=')[0].replace('>', '').replace('<', '')

                if not left_if_value_2.upper() in boolean_list:
                    left_if_function("If " + left_if_value_2 + " Then", json_data)

            elif if_value.__contains__('>'):
                if_value_2 = if_value.split('>')[1].replace('<', '').replace('=', '')
                # left_if_value_2 = if_value.split('=')[0].replace('<', '').replace('=', '')

                if if_value_2.strip().startswith('"'):
                    None
                elif if_value_2.strip().endswith(')') and not if_value_2.strip().__contains__('('):
                    if_value_2 = if_value_2.strip()[:-1]

                left_if_value_2 = if_value.split('>')[0].replace('=', '').replace('<', '')

                if not left_if_value_2.upper() in boolean_list:
                    left_if_function("If " + left_if_value_2 + " Then", json_data)

                # left_if_function("If " + left_if_value_2 + " Then",json_data)

            elif if_value.__contains__('<'):
                if_value_2 = if_value.split('<')[1].replace('>', '').replace('=', '')
                left_if_value_2 = if_value.split('<')[0].replace('>', '').replace('=', '')
                if if_value_2.strip().startswith('"'):
                    None
                elif if_value_2.strip().endswith(')') and not if_value_2.strip().__contains__('('):
                    if_value_2 = if_value_2.strip()[:-1]

                left_if_value_2 = if_value.split('<')[0].replace('>', '').replace('=', '')

                if not left_if_value_2.upper() in boolean_list:
                    left_if_function("If " + left_if_value_2 + " Then", json_data)

            if if_value_2.strip().upper() in boolean_list or if_value_2.strip().startswith('"') or \
                    any(if_value_2.strip()[0] in s for s in number_list):

                db.rule_report.update_one({"_id": dup_data["_id"]}, {"$set": {"rule_type": "direct_rule"}})
                # Direct if pattern need not to capture anything.

            else:

                # Need to call or check for variable pattern IF.

                # if (if_value_2.__contains__(".Input(") or if_value_2.__contains__(".Fields(")):
                #
                #     if if_value_2.__contains__(".Input("):
                #         if if_value_2.split(".Input")[1].split('.')[0][1:-1].startswith('"'):
                #             None
                #         else:
                #
                #             variable_if_fun(if_value_2.split(".Input")[1].split('.')[0][1:-1])
                #
                #     elif if_value_2.__contains__(".Fields("):
                #         if single_if_statement.split(".Fields")[1].split('.')[0][1:-1].startswith('"'):
                #
                #             None
                #         else:
                #
                #             variable_if_fun(single_if_statement.split(".Fields")[1].split('.')[0][1:-1])

                if not if_value_2.strip().__contains__('(') and not if_value_2.strip().__contains__('.'):
                    variable_if_fun(if_value_2.strip())

                elif if_value_2.split('.')[0].__contains__('('):
                    # db.rule_report.update_one({"_id": dup_data["_id"]},
                    #                           {"$set": {"rule_type": "variable_type_rule"}})

                    variable_if_fun(if_value_2.split('.')[0])

                elif if_value_2.split('.')[1].__contains__('('):

                    # db.rule_report.update_one({"_id": dup_data["_id"]},
                    #                           {"$set": {"rule_type": "variable_type_rule"}})
                    variable_if_fun(if_value_2.split('.')[1])

                elif if_value_2.split('.')[2].__contains__('('):

                    # db.rule_report.update_one({"_id": dup_data["_id"]},
                    #                           {"$set": {"rule_type": "variable_type_rule"}})
                    variable_if_fun(if_value_2.split('.')[2])


        else:

            # It contains only single variable ,it can be divided into function or variable.

            single_if_statement = if_statement_string.replace('If ', '').replace(' Then', '').strip()

            if (single_if_statement.__contains__(".Input(") or single_if_statement.__contains__(".Fields(")) and \
                    single_if_statement.__contains__(".Equals("):

                if_statement_input_value = single_if_statement.split(".Equals")[1].split(")")[0].replace('(', '')

                # call LHS

                left_if_function("If " + single_if_statement.split(".Equals")[0] + " Then", json_data)

                if if_statement_input_value.strip().startswith('"') or (
                        if_statement_input_value.upper() in boolean_list):

                    db.rule_report.update_one({"_id": dup_data["_id"]},
                                              {"$set": {"rule_type": "direct_rule"}})

                else:

                    if if_statement_input_value.__contains__('.'):
                        if_statement_input_value = if_statement_input_value.split('.')[1]
                    db.rule_report.update_one({"_id": dup_data["_id"]},
                                              {"$set": {"rule_type": "variable_type_rule"}})
                    variable_if_fun(if_statement_input_value)

            elif single_if_statement.__contains__(".Equals("):

                if_statement_input_value_1 = single_if_statement.split(".Equals")[1]

                if if_statement_input_value_1.startswith('(') and if_statement_input_value_1.endswith(')'):
                    if_statement_input_value_1 = if_statement_input_value_1[1:-1]

                left_if_statement_input_value_1 = single_if_statement.split(".Equals")[0]

                # RHS

                if if_statement_input_value_1.startswith('(') and if_statement_input_value_1.endswith(')'):
                    if if_statement_input_value_1[:-1].endswith(')') and not if_statement_input_value_1[
                                                                             1:-1].__contains__('('):
                        if_statement_input_value_1 = if_statement_input_value_1[1:-2]
                    elif if_statement_input_value_1.__contains__('.'):
                        if_statement_input_value_1 = if_statement_input_value_1[1:-1]
                    elif if_statement_input_value_1.startswith('(') and if_statement_input_value_1.endswith(
                            ')') and not if_statement_input_value_1.__contains__('.)'):
                        variable_if_fun(if_statement_input_value_1[1:-1])

                    if if_statement_input_value_1.upper() in boolean_list or if_statement_input_value_1.strip().startswith(
                            '"'):
                        db.rule_report.update_one({"_id": dup_data["_id"]},
                                                  {"$set": {"rule_type": "direct_rule"}})
                    else:

                        db.rule_report.update_one({"_id": dup_data["_id"]},
                                                  {"$set": {"rule_type": "variable_type_rule"}})
                        variable_if_fun(if_statement_input_value_1)

                elif if_statement_input_value_1.startswith('(') and not if_statement_input_value_1.strip().endswith(
                        ')'):

                    if_statement_input_value_1 = if_statement_input_value_1[1:]

                    if if_statement_input_value_1.upper() in boolean_list or if_statement_input_value_1.strip().startswith(
                            '"'):

                        db.rule_report.update_one({"_id": dup_data["_id"]},
                                                  {"$set": {"rule_type": "direct_rule"}})
                    else:

                        db.rule_report.update_one({"_id": dup_data["_id"]},
                                                  {"$set": {"rule_type": "variable_type_rule"}})
                        variable_if_fun(if_statement_input_value_1)
                    # db.rule_report.update_one({"_id": dup_data["_id"]},
                    #                         {"$set": {"rule_type": "direct_rule"}})

                elif not if_statement_input_value_1.startswith('(') and not if_statement_input_value_1.endswith(')'):

                    if if_statement_input_value_1.upper() in boolean_list or if_statement_input_value_1.strip().startswith(
                            '"'):
                        db.rule_report.update_one({"_id": dup_data["_id"]},
                                                  {"$set": {"rule_type": "direct_rule"}})
                    else:
                        db.rule_report.update_one({"_id": dup_data["_id"]},
                                                  {"$set": {"rule_type": "variable_type_rule"}})

                        variable_if_fun(if_statement_input_value_1)

                # LHS

                if left_if_statement_input_value_1.__contains__('.'):

                    left_if_function("If " + left_if_statement_input_value_1.split('.')[0] + " Then", json_data)

                elif not left_if_statement_input_value_1.startswith(
                        '(') and not left_if_statement_input_value_1.endswith(')'):

                    if left_if_statement_input_value_1.upper() in boolean_list or left_if_statement_input_value_1.strip().startswith(
                            '"'):
                        db.rule_report.update_one({"_id": dup_data["_id"]},
                                                  {"$set": {"rule_type": "direct_rule"}})
                    else:
                        db.rule_report.update_one({"_id": dup_data["_id"]},
                                                  {"$set": {"rule_type": "variable_type_rule"}})

                        variable_if_fun(left_if_statement_input_value_1)

                elif not left_if_statement_input_value_1.strip().startswith(
                        '(') and left_if_statement_input_value_1.strip().endswith(')'):

                    if left_if_statement_input_value_1.strip().endswith('))'):
                        left_if_statement_input_value_1 = left_if_statement_input_value_1[:-2]
                    else:
                        left_if_statement_input_value_1 = left_if_statement_input_value_1[:-1]

                    if left_if_statement_input_value_1.upper() in boolean_list or left_if_statement_input_value_1.strip().startswith(
                            '"'):

                        db.rule_report.update_one({"_id": dup_data["_id"]},
                                                  {"$set": {"rule_type": "direct_rule"}})
                    else:

                        db.rule_report.update_one({"_id": dup_data["_id"]},
                                                  {"$set": {"rule_type": "variable_type_rule"}})
                        variable_if_fun(left_if_statement_input_value_1)

                elif left_if_statement_input_value_1.startswith(
                        '(') and not left_if_statement_input_value_1.strip().endswith(')'):

                    left_if_statement_input_value_1 = left_if_statement_input_value_1[1:]

                    if left_if_statement_input_value_1.upper() in boolean_list or left_if_statement_input_value_1.strip().startswith(
                            '"'):

                        db.rule_report.update_one({"_id": dup_data["_id"]},
                                                  {"$set": {"rule_type": "direct_rule"}})
                    else:

                        db.rule_report.update_one({"_id": dup_data["_id"]},
                                                  {"$set": {"rule_type": "variable_type_rule"}})
                        variable_if_fun(left_if_statement_input_value_1)

            elif (single_if_statement.__contains__(".Input(") or single_if_statement.__contains__(".Fields(")):

                if single_if_statement.__contains__(".Input("):
                    if single_if_statement.split(".Input")[1].split('.')[0][1:-1].startswith('"'):
                        None
                    else:

                        variable_if_fun(single_if_statement.split(".Input")[1].split('.')[0][1:-1])

                elif single_if_statement.__contains__(".Fields("):
                    if single_if_statement.split(".Fields")[1].split('.')[0][1:-1].startswith('"'):

                        None
                    else:

                        variable_if_fun(single_if_statement.split(".Fields")[1].split('.')[0][1:-1])

            elif single_if_statement.__contains__('.'):

                if single_if_statement.split('.')[0].__contains__('(') and single_if_statement.split('.')[
                    0].__contains__(')'):

                    db.rule_report.update_one({"_id": dup_data["_id"]},
                                              {"$set": {"rule_type": "variable_type_rule"}})

                    variable_if_fun(single_if_statement.split('.')[0].strip())
                elif single_if_statement.split('.')[1].__contains__('(') and single_if_statement.split('.')[
                    1].__contains__(')'):

                    db.rule_report.update_one({"_id": dup_data["_id"]},
                                              {"$set": {"rule_type": "variable_type_rule"}})

                    variable_if_fun(single_if_statement.split('.')[1].strip())


                else:

                    if single_if_statement.split('.')[1].upper() == "CHECKED":
                        db.rule_report.update_one({"_id": dup_data["_id"]},
                                                  {"$set": {"rule_type": "direct_rule"}})
                    else:
                        db.rule_report.update_one({"_id": dup_data["_id"]},
                                                  {"$set": {"rule_type": "variable_type_rule"}})
                        # variable_if_fun(single_if_statement.split('.')[1].strip())
                        if single_if_statement.split('.')[1].strip().upper() == 'TEXT':

                            variable_if_fun(single_if_statement.split('.')[0].strip())
                        elif single_if_statement.split('.')[1].strip().upper() == 'VALUE':
                            left_variable_if_fun(single_if_statement.split('.')[0].strip())
                        else:

                            variable_if_fun(single_if_statement.split('.')[1].strip())

                        # print("checked pattern")

            else:

                db.rule_report.update_one({"_id": dup_data["_id"]},
                                          {"$set": {"rule_type": "variable_type_rule"}})

                if single_if_statement.split('.')[0].strip().startswith('(') and not single_if_statement.split('.')[
                    0].strip().endswith(')'):
                    variable_if_fun(single_if_statement.split('.')[0].strip()[1:])
                else:
                    variable_if_fun(single_if_statement.split('.')[0].strip())

        var_statescan_finder(json_data)
        # Function_processer(json_data)

    except Exception as e:
        exc_type, exc_obj, exc_tb = sys.exc_info()
        fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
        print(exc_type, fname, exc_tb.tb_lineno)
        pass


def left_if_function(if_statement_string, json_data):
    try:
        '''
         :param if_statement_string: Only condition lines.
         :param data: release-1 Json
         :return: Type of the condition
         1.This function is used to find the type of the condition. The input of the function will be condition statement.
         2.IF the condition statement startwith string keyword ,then the condition line is splited with ','.And the second
         index is taken as input.
         3.IF the second index startswith double quotes then it is a direct if pattern.FOr direct pattern no further process
         is needed.
         4.IF it does not startwith quotes then it can be possibly of variable or function pattern.For there the variable
         function is called for further process.
         5.In the else statement, if the condition has  any operators , then using the operator the condition is splitted.
         and same second index is taken.
         for that also if it startws with quotes then it is remains untouched considering it as direct if patter.
         6.If not send that condition to further processing.
         7.IF the input does not  falls under any of the two condition above, then considering than condition as variable or
         function pattern.
         and sending that condition to further processing.
        '''
        boolean_list = ["TRU", "FALS", "FALSE)", "TRUE)", "TRUE", "FALSE", '"Y"', '"N"']

        if_value = if_statement_string.replace('If ', '').replace(' Then', '')

        if if_value.strip().__contains__(" HashSet") and if_value.strip().__contains__("Contains"):
            db.rule_report.update_one({"_id": dup_data["_id"]}, {"$set": {"rule_type": "direct_rule"}})

        elif if_value.strip().__contains__(".Attributes"):
            db.rule_report.update_one({"_id": dup_data["_id"]}, {"$set": {"rule_type": "direct_rule"}})

        elif if_value.strip().startswith('String.') or if_value.__contains__(' String.'):

            if if_value.__contains__(','):
                if_value_1 = if_value.split(',')[1].strip()
                if if_value_1.startswith('"') or if_value_1.startswith("'"):
                    db.rule_report.update_one({"_id": dup_data["_id"]}, {"$set": {"rule_type": "direct_rule"}})
                    pass

                else:
                    # variable function has to be called.
                    db.rule_report.update_one({"_id": dup_data["_id"]},
                                              {"$set": {"rule_type": "variable_type_rule"}})
                    left_variable_if_fun(if_value.split(',')[1].split('.')[0])  # sending only the variable

            else:  # for Right hand side check ,we are leaving this if conditon by considering as direct.

                # Direct
                db.rule_report.update_one({"_id": dup_data["_id"]}, {"$set": {"rule_type": "direct_rule"}})


        elif if_value.__contains__('=') or if_value.__contains__('>') or if_value.__contains__('<'):

            number_list = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
            if if_value.__contains__('='):
                if_value_2 = if_value.split('=')[1].replace('>', '').replace('<', '')
                left_if_value_2 = if_value.split('=')[0].replace('>', '').replace('<', '')

                # if_function("If "+left_if_value_2+" Then",json_data)

            elif if_value.__contains__('>'):
                if_value_2 = if_value.split('>')[1].replace('<', '').replace('=', '')
                left_if_value_2 = if_value.split('>')[0].replace('<', '').replace('=', '')

                # if_function("If " + left_if_value_2 + " Then",json_data)

            elif if_value.__contains__('<'):
                if_value_2 = if_value.split('<')[1].replace('>', '').replace('=', '')
                left_if_value_2 = if_value.split('<')[0].replace('>', '').replace('=', '')

                # if_function("If " + left_if_value_2 + " Then",json_data)

            if if_value_2.strip().upper() in boolean_list or if_value_2.strip().startswith('"') or \
                    any(if_value_2.strip()[0] in s for s in number_list):

                db.rule_report.update_one({"_id": dup_data["_id"]}, {"$set": {"rule_type": "direct_rule"}})
                # Direct if pattern need not to capture anything.

            else:
                # Need to call or check for variable pattern IF.

                if if_value_2.split('.')[0].__contains__('('):
                    # db.rule_report.update_one({"_id": dup_data["_id"]},
                    #                           {"$set": {"rule_type": "variable_type_rule"}})

                    left_variable_if_fun(if_value_2.split('.')[0])

                elif if_value_2.split('.')[1].__contains__('('):

                    # db.rule_report.update_one({"_id": dup_data["_id"]},
                    #                           {"$set": {"rule_type": "variable_type_rule"}})
                    left_variable_if_fun(if_value_2.split('.')[1])

                elif if_value_2.split('.')[2].__contains__('('):

                    # db.rule_report.update_one({"_id": dup_data["_id"]},
                    #                           {"$set": {"rule_type": "variable_type_rule"}})
                    left_variable_if_fun(if_value_2.split('.')[2])


        else:

            # It contains only single variable ,it can be divided into function or variable.

            single_if_statement = if_statement_string.replace('If ', '').replace(' Then', '').strip()

            if (single_if_statement.__contains__(".Input(") or single_if_statement.__contains__(".Fields(")) and \
                    single_if_statement.__contains__(".Equals("):

                if_statement_input_value = single_if_statement.split(".Equals")[1].split(")")[0].replace('(', '')

                if if_statement_input_value.strip().startswith('"') or (
                        if_statement_input_value.upper() in boolean_list):

                    db.rule_report.update_one({"_id": dup_data["_id"]},
                                              {"$set": {"rule_type": "direct_rule"}})

                else:
                    if if_statement_input_value.__contains__('.'):
                        if_statement_input_value = if_statement_input_value.split('.')[1]
                    db.rule_report.update_one({"_id": dup_data["_id"]},
                                              {"$set": {"rule_type": "variable_type_rule"}})
                    left_variable_if_fun(if_statement_input_value)

            elif single_if_statement.__contains__(".Equals("):

                if_statement_input_value_1 = single_if_statement.split(".Equals")[1]

                if if_statement_input_value_1.startswith('(') and if_statement_input_value_1.endswith(')'):
                    if if_statement_input_value_1[:-1].endswith(')') and not if_statement_input_value_1[
                                                                             1:-1].__contains__('('):
                        if_statement_input_value_1 = if_statement_input_value_1[1:-2]
                    else:
                        if_statement_input_value_1 = if_statement_input_value_1[1:-1]

                    if if_statement_input_value_1.upper() in boolean_list or if_statement_input_value_1.strip().startswith(
                            '"'):
                        db.rule_report.update_one({"_id": dup_data["_id"]},
                                                  {"$set": {"rule_type": "direct_rule"}})
                    else:

                        db.rule_report.update_one({"_id": dup_data["_id"]},
                                                  {"$set": {"rule_type": "variable_type_rule"}})
                        left_variable_if_fun(if_statement_input_value_1)

                elif if_statement_input_value_1.startswith('(') and not if_statement_input_value_1.strip().endswith(
                        ')'):

                    if_statement_input_value_1 = if_statement_input_value_1[1:]

                    if if_statement_input_value_1.upper() in boolean_list or if_statement_input_value_1.strip().startswith(
                            '"'):
                        db.rule_report.update_one({"_id": dup_data["_id"]},
                                                  {"$set": {"rule_type": "direct_rule"}})
                    else:

                        db.rule_report.update_one({"_id": dup_data["_id"]},
                                                  {"$set": {"rule_type": "variable_type_rule"}})
                        left_variable_if_fun(if_statement_input_value_1)
                    # db.rule_report.update_one({"_id": dup_data["_id"]},
                    #                         {"$set": {"rule_type": "direct_rule"}})


            elif (single_if_statement.__contains__(".Input(") or single_if_statement.__contains__(".Fields(")):

                if single_if_statement.__contains__(".Input("):
                    if single_if_statement.split(".Input")[1].split('.')[0][1:-1].startswith('"'):
                        None
                    else:
                        left_variable_if_fun(single_if_statement.split(".Input")[1].split('.')[0][1:-1])

                elif single_if_statement.__contains__(".Fields("):
                    if single_if_statement.split(".Fields")[1].split('.')[0][1:-1].startswith('"'):

                        None
                    else:

                        left_variable_if_fun(single_if_statement.split(".Fields")[1].split('.')[0][1:-1])

            elif single_if_statement.__contains__('.'):

                if single_if_statement.split('.')[0].__contains__('(') and single_if_statement.split('.')[
                    0].__contains__(')'):

                    db.rule_report.update_one({"_id": dup_data["_id"]},
                                              {"$set": {"rule_type": "variable_type_rule"}})
                    left_variable_if_fun(single_if_statement.split('.')[0].strip())
                elif single_if_statement.split('.')[1].__contains__('(') and single_if_statement.split('.')[
                    1].__contains__(')'):

                    db.rule_report.update_one({"_id": dup_data["_id"]},
                                              {"$set": {"rule_type": "variable_type_rule"}})
                    left_variable_if_fun(single_if_statement.split('.')[1].strip())


                else:

                    if single_if_statement.split('.')[1].upper() == "CHECKED":
                        db.rule_report.update_one({"_id": dup_data["_id"]},
                                                  {"$set": {"rule_type": "direct_rule"}})
                    else:
                        db.rule_report.update_one({"_id": dup_data["_id"]},
                                                  {"$set": {"rule_type": "variable_type_rule"}})
                        # variable_if_fun(single_if_statement.split('.')[1].strip())
                        if single_if_statement.split('.')[1].strip().upper() == 'TEXT':
                            left_variable_if_fun(single_if_statement.split('.')[0].strip())
                        elif single_if_statement.split('.')[1].strip().upper() == 'VALUE':
                            left_variable_if_fun(single_if_statement.split('.')[0].strip())
                        else:
                            left_variable_if_fun(single_if_statement.split('.')[1].strip())

                        # print("checked pattern")
            else:

                db.rule_report.update_one({"_id": dup_data["_id"]},
                                          {"$set": {"rule_type": "variable_type_rule"}})

                left_variable_if_fun(single_if_statement.split('.')[0].strip())

    except Exception as e:
        exc_type, exc_obj, exc_tb = sys.exc_info()
        fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
        print(exc_type, fname, exc_tb.tb_lineno)
        pass


def variable_if_fun(if_statement_string):
    '''
    :param if_statement_string: condition line.
    :return: Required output
    1.The input of this fucntion will falls under only variable or function pattern.
    2.check whether the condition line contains any open and close brackets, if it has then take the name before the
    bracket.And search that string has any variable assignment or not.IF it has variable assigned ,then capture that line and
    additionally check whether the assignment line is present in the condition or not .
    3.If it is inside the condition ,then capture that rule also and insert into collection in a new row.
    4.If it does not have the assignment line,then consider it as fucntion call.
    5.If the line does not have any brackets , then consider it as variable pattern and do the same process and capture
    rules.
    '''
    flag_value = False
    if if_statement_string.__contains__('(') and if_statement_string.__contains__(')'):  # checking for function.

        name_val_var = if_statement_string.split("(")[0]

        if name_val_var == "":
            name_val_var = if_statement_string.split("(")[1]

        if name_val_var.__contains__('.'):
            name_val_var = name_val_var.split('.')[1]

        variable_flag = False

        with open(filename + '.vb', 'r') as vb_file:
            for lines in vb_file.readlines():
                if lines.strip().startswith("'") or lines.strip() == "":
                    continue
                if lines.split("=")[0].__contains__(name_val_var.strip()) and lines.__contains__("="):
                    variable_flag = True
                    break
        vb_file.close()
        if variable_flag:
            flag_value = same_func(if_statement_string)
            if not flag_value:
                # print(if_statement_string, dup_data)
                recursive_function(if_statement_string, dup_data["function_name"])
        else:

            Function_processer(dup_data)
            # Call fucntion
    else:
        if not if_statement_string.strip() == "":

            flag_value = same_func(if_statement_string)
            # print(if_statement_string)
            # print(flag_value)
            if not flag_value:
                class_flag = recursive_function(if_statement_string, dup_data["function_name"])
                if not class_flag:
                    fun_var = '^\s*\t*PRIVATE\s*SUB\s*[A0-Z9_].*\s*[(].*[)]*'
                    fun_var_1 = '^\s*\t*PUBLIC\s*SHARED\s*FUNCTION\s*[A0-Z9_]\s*.*[(].*[)]*'
                    fun_var_2 = '^\s*\t*PROTECTED\s*SUB\s*[A0-Z9_]\s*.*[(].*[)]*'
                    with open(filename + '.vb', 'r') as vb_file_2:
                        dup_data_rule = dup_data["rule_statement"]
                        for lines in vb_file_2.readlines():
                            if lines.strip().startswith("'") or lines.strip() == "":
                                continue

                            fun_regexx_1 = re.findall(fun_var, lines, re.IGNORECASE)
                            fun_regexx_2 = re.findall(fun_var_1, lines, re.IGNORECASE)
                            fun_regexx_3 = re.findall(fun_var_2, lines, re.IGNORECASE)

                            if fun_regexx_1 != [] or fun_regexx_2 != [] or fun_regexx_3 != []:
                                break

                            lines_variable = ' ' + lines.split("=")[0].strip() + ' '
                            if lines_variable.__contains__(
                                    ' ' + if_statement_string.split('(')[0].strip() + ' ') and lines.__contains__("="):
                                dup_data_rule.insert(0, 'Class_Variable:' + lines)
                                db.rule_report.update_one({"_id": dup_data["_id"]},
                                                          {"$set": {"rule_statement": dup_data_rule,
                                                                    "rule_type": "variable_type_rule"}})


def left_variable_if_fun(if_statement_string):
    '''
    :param if_statement_string: condition line.
    :return: Required output
    1.The input of this fucntion will falls under only variable or function pattern.
    2.check whether the condition line contains any open and close brackets, if it has then take the name before the
    bracket.And search that string has any variable assignment or not.IF it has variable assigned ,then capture that line and
    additionally check whether the assignment line is present in the condition or not .
    3.If it is inside the condition ,then capture that rule also and insert into collection in a new row.
    4.If it does not have the assignment line,then consider it as fucntion call.
    5.If the line does not have any brackets , then consider it as variable pattern and do the same process and capture
    rules.
    '''

    flag_value1 = False

    if if_statement_string.__contains__('(') and if_statement_string.__contains__(')'):  # checking for function.

        name_val_var = if_statement_string.split("(")[0]

        if name_val_var.strip() == "":
            name_val_var = if_statement_string.split("(")[1]

        if name_val_var.__contains__('.'):
            name_val_var = name_val_var.split('.')[1]
        variable_flag = False

        with open(filename + '.vb', 'r') as vb_file:
            for lines in vb_file.readlines():
                if lines.strip().startswith("'") or lines.strip() == "":
                    continue
                if lines.split("=")[0].__contains__(name_val_var.strip()) and lines.__contains__(
                        "=") and not lines.upper().strip("IF "):
                    variable_flag = True
                    break
        vb_file.close()
        if variable_flag:
            flag_value1 = left_same_func(if_statement_string)
            if not flag_value1:
                left_recursive_function(if_statement_string, dup_data["function_name"])
        else:

            Function_processer(dup_data)
            # Call fucntion
    else:
        flag_value1 = left_same_func(if_statement_string)

        if not flag_value1:
            # left_recursive_function(if_statement_string, dup_data["function_name"])
            class_flag = left_recursive_function(if_statement_string, dup_data["function_name"])
            if not class_flag:
                with open(filename + '.vb', 'r') as vb_file_2:
                    fun_var = '^\s*\t*PRIVATE\s*SUB\s*[A0-Z9_].*\s*[(].*[)]*'
                    fun_var_1 = '^\s*\t*PUBLIC\s*SHARED\s*FUNCTION\s*[A0-Z9_]\s*.*[(].*[)]*'
                    fun_var_2 = '^\s*\t*PROTECTED\s*SUB\s*[A0-Z9_]\s*.*[(].*[)]*'
                    dup_data_rule = dup_data["rule_statement"]
                    for lines in vb_file_2.readlines():
                        if lines.strip().startswith("'") or lines.strip() == "":
                            continue
                        fun_regexx_1 = re.findall(fun_var, lines, re.IGNORECASE)
                        fun_regexx_2 = re.findall(fun_var_1, lines, re.IGNORECASE)
                        fun_regexx_3 = re.findall(fun_var_2, lines, re.IGNORECASE)

                        if fun_regexx_1 != [] or fun_regexx_2 != [] or fun_regexx_3 != []:
                            break

                        lines_variable = ' ' + lines.split("=")[0].strip() + ' '
                        if lines_variable.__contains__(
                                ' ' + if_statement_string.split('(')[0].strip() + ' ') and lines.__contains__("="):
                            dup_data_rule.insert(0, 'Class_Variable:' + lines)
                            db.rule_report.update_one({"_id": dup_data["_id"]},
                                                      {"$set": {"rule_statement": dup_data_rule,
                                                                "rule_type": "variable_type_rule"}})


def same_func(if_statement_string):
    try:

        inside_flag = False
        recursive_flag = False
        boolean_list = ['ANDALSO', 'ORELSE', 'OR', 'AND', "THEN"]

        name_val_var = if_statement_string.strip().split("(")[0].strip()

        if name_val_var == "":
            name_val_var = if_statement_string.strip().split("(")[1].strip()

        if name_val_var.__contains__('.'):
            name_val_var = name_val_var.split('.')[1].strip()
        if not name_val_var.startswith(" "):
            name_val_var = ' ' + name_val_var

        if_cursor = db.Code_behind_rules_1.find_one(
            {"$and": [{"file_name": dup_data["file_name"].split('.')[0]},
                      {"function_name": dup_data["function_name"]}]})

        if_cursor_1 = db.Code_behind_rules.find_one(
            {"$and": [{"file_name": dup_data["file_name"].split('.')[0]},
                      {"function_name": dup_data["function_name"]}]})

        if if_cursor_1 != []:
            for data_2 in if_cursor_1["rule_statement"]:

                if data_2.split("=")[0].__contains__(name_val_var) and data_2.__contains__(
                        "=") and not data_2.strip().startswith('If ') and not data_2.strip().split()[
                                                                                  -1].upper() in boolean_list:
                    inside_flag = True

                    recursive_flag = True
                    global counter
                    counter = counter + 1
                    db_screen_data = db.screen_data.find_one({"ScreenField": dup_data["ScreenField"]})
                    db.rule_report.insert_one(
                        {
                            "function_name": dup_data["function_name"],
                            "ScreenField": dup_data["ScreenField"],
                            "CLASLabel": db_screen_data["CLASLabel"],
                            "SectionName": db_screen_data["SectionName"]
                            , "rule_statement": if_cursor_1['rule_statement'],
                            "file_name": dup_data["file_name"],
                            "rule_id": dup_data["rule_id"] + '.' + str(counter),
                            "Rule_Relation": dup_data["rule_id"],
                            "rule_description": "",
                            "rule_type": "",
                            "lob": dup_data["lob"],
                            "parent_rule_id": "",
                            "dependent_control": ""})
                    break

        if not inside_flag:

            conjunction_keyword_list = ["ANDALSO", "ORELSE", "OR", "AND"]
            multi_line_flag = False
            multi_line_list = []
            if_line_flag = False
            for data_1 in if_cursor["source_statement"]:
                if data_1.strip() == "" or data_1.strip().startswith("'"):
                    continue
                if not name_val_var.startswith(' '):
                    name_val_var = ' ' + name_val_var
                if data_1.split("=")[0].__contains__(name_val_var) and data_1.__contains__(
                        "=") and not data_1.strip().startswith('If '):

                    if data_1.split()[-1] == "_":
                        if data_1.split()[-2].upper() in conjunction_keyword_list:
                            multi_line_flag = True
                    elif data_1.split()[-1].upper() in conjunction_keyword_list:
                        multi_line_flag = True
                    if not multi_line_flag:
                        dup_data_rule = dup_data["rule_statement"]
                        dup_data_rule.insert(0, dup_data["function_name"] + '():' + data_1)
                        db.rule_report.update_one({"_id": dup_data["_id"]}, {"$set": {"rule_statement": dup_data_rule}})
                        recursive_flag = True
                        break
                if multi_line_flag:
                    multi_line_list.append(data_1.replace("\n", ""))
                if data_1.strip().startswith('If '):
                    if_line_flag = True
                if data_1.split()[-1] == "_":
                    if data_1.split()[-2].upper() in conjunction_keyword_list and multi_line_flag:
                        multi_line_flag = True
                elif data_1.split()[-1].upper() in conjunction_keyword_list and not if_line_flag and multi_line_flag:

                    multi_line_flag = True
                else:
                    multi_line_flag = False

                if data_1.strip().split()[-1] == 'Then':
                    if_line_flag = False

            if multi_line_list != []:

                dup_data_rule = dup_data["rule_statement"]
                if any(item in ' '.join(multi_line_list).split() for item in ['AndAlso', 'OrElse', 'Or', 'And']):
                    if ' '.join(multi_line_list).__contains__('='):
                        multi_line_list_value = ' '.join(multi_line_list)[' '.join(multi_line_list).index('=') + 1:]
                    else:
                        multi_line_list_value = ' '.join(multi_line_list)

                    variable_back_trace_fun(" If " + multi_line_list_value + ' Then', dup_data)
                dup_data_rule.insert(0, dup_data["function_name"] + '():' + " ".join(multi_line_list) + '\n')
                db.rule_report.update_one({"_id": dup_data["_id"]}, {"$set": {"rule_statement": dup_data_rule}})
                recursive_flag = True

        return recursive_flag


    except Exception as e:
        exc_type, exc_obj, exc_tb = sys.exc_info()
        fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
        print(exc_type, fname, exc_tb.tb_lineno)
        pass


def left_same_func(if_statement_string):
    try:
        inside_flag = False
        recursive_flag = False
        boolean_list = ['ANDALSO', 'ORELSE', 'OR', 'AND', 'THEN']
        name_val_var = if_statement_string.split("(")[0].strip()

        if name_val_var.__contains__('.'):
            name_val_var = name_val_var.split('.')[1].strip()

        if not name_val_var.startswith(' '):
            name_val_var = ' ' + name_val_var
        if_cursor = db.Code_behind_rules_1.find_one(
            {"$and": [{"file_name": dup_data["file_name"].split('.')[0]},
                      {"function_name": dup_data["function_name"]}]})

        if_cursor_1 = db.Code_behind_rules.find_one(
            {"$and": [{"file_name": dup_data["file_name"].split('.')[0]},
                      {"function_name": dup_data["function_name"]}]})

        if if_cursor_1 != []:
            for data_2 in if_cursor_1["rule_statement"]:

                if data_2.split("=")[0].__contains__(name_val_var) and data_2.__contains__(
                        "=") and not data_2.strip().startswith('If '):
                    inside_flag = True
                    recursive_flag = True
                    global counter
                    counter = counter + 1
                    db_screen_data = db.screen_data.find_one({"ScreenField": dup_data["ScreenField"]})
                    db.rule_report.insert_one(
                        {
                            "function_name": dup_data["function_name"],
                            "ScreenField": dup_data["ScreenField"],
                            "CLASLabel": db_screen_data["CLASLabel"],
                            "SectionName": db_screen_data["SectionName"]
                            , "rule_statement": if_cursor_1['rule_statement'],
                            "file_name": dup_data["file_name"],
                            "rule_id": dup_data["rule_id"] + '.' + str(counter),
                            "Rule_Relation": dup_data["rule_id"],
                            "rule_description": "",
                            "rule_type": "",
                            "lob": dup_data["lob"],
                            "parent_rule_id": "",
                            "dependent_control": ""})
                    break
        if not inside_flag:

            conjunction_keyword_list = ["ANDALSO", "ORELSE", "OR", "AND"]
            multi_line_flag = False
            if_line_flag = False
            left_multi_line_list = []
            for data_1 in if_cursor["source_statement"]:
                if data_1.strip() == "" or data_1.strip().startswith("'"):
                    continue
                if data_1.split("=")[0].__contains__(name_val_var) and data_1.__contains__(
                        "=") and not data_1.strip().startswith('If ') and not data_1.strip().split()[
                                                                                  -1].upper() in boolean_list:

                    if data_1.split()[-1] == "_":
                        if data_1.split()[-2].upper() in conjunction_keyword_list:
                            multi_line_flag = True
                    elif data_1.split()[-1].upper() in conjunction_keyword_list:
                        multi_line_flag = True

                    if not multi_line_flag:
                        dup_data_rule = dup_data["rule_statement"]
                        dup_data_rule.insert(0, dup_data["function_name"] + '():' + data_1)
                        db.rule_report.update_one({"_id": dup_data["_id"]}, {"$set": {"rule_statement": dup_data_rule}})
                        recursive_flag = True
                        break

                if multi_line_flag:
                    left_multi_line_list.append(data_1.replace("\n", ""))

                if data_1.strip().startswith('If '):
                    if_line_flag = True

                if data_1.split()[-1] == "_" and not if_line_flag and multi_line_flag:
                    if data_1.split()[-2].upper() in conjunction_keyword_list:
                        multi_line_flag = True
                elif data_1.split()[-1].upper() in conjunction_keyword_list and not if_line_flag and multi_line_flag:
                    multi_line_flag = True
                else:
                    multi_line_flag = False

                if data_1.strip().split()[-1] == 'Then':
                    if_line_flag = False

            if left_multi_line_list != []:

                dup_data_rule = dup_data["rule_statement"]
                if any(item in ' '.join(left_multi_line_list).split() for item in ['AndAlso', 'OrElse', 'Or', 'And']):
                    if ' '.join(left_multi_line_list).__contains__('='):
                        multi_line_list_value = ' '.join(left_multi_line_list)[
                                                ' '.join(left_multi_line_list).index('=') + 1:]
                    else:
                        multi_line_list_value = ' '.join(left_multi_line_list)
                    left_variable_back_trace_fun(" If " + multi_line_list_value + ' Then', dup_data)

                dup_data_rule.insert(0, dup_data["function_name"] + '():' + " ".join(left_multi_line_list) + '\n')
                db.rule_report.update_one({"_id": dup_data["_id"]}, {"$set": {"rule_statement": dup_data_rule}})
                recursive_flag = True

        return recursive_flag


    except Exception as e:
        exc_type, exc_obj, exc_tb = sys.exc_info()
        fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
        print(exc_type, fname, exc_tb.tb_lineno)
        pass


def recursive_function(if_statement_string, fun_name):
    try:

        fun_var = '^\s*\t*PRIVATE\s*SUB\s*[A0-Z9_].*\s*[(].*[)]*'
        fun_var_1 = '^\s*\t*PUBLIC\s*SHARED\s*FUNCTION\s*[A0-Z9_]\s*.*[(].*[)]*'
        fun_var_2 = '^\s*\t*PUBLIC\s*SUB\s*[A0-Z9_].*\s*[(].*[)]*'
        fun_name_regexx = '^\s*\t*' + fun_name + '\s*[(].*[)]*'
        lines_flag = False
        assign_data_flag = False
        assignment_line = ""
        varaible_flag = False
        conjunction_keyword_list = ["ANDALSO", "ORELSE", "OR", "AND"]
        multi_line_flag = False
        multi_line_list_1 = []
        multi_line_list = []

        with open(filename + '.vb', 'r') as vb_file:
            for lines in reversed(vb_file.readlines()):
                if lines.strip().startswith("'") or lines.strip() == "":
                    continue

                function_name_regexx = re.search(fun_var, lines, re.IGNORECASE)

                function_name_1_regexx = re.search(fun_var_1, lines,
                                                   re.IGNORECASE)
                function_name_2_regexx = re.search(fun_var_2, lines, re.IGNORECASE)

                function_call_regexx = re.search(fun_name_regexx, lines, re.IGNORECASE)

                if function_call_regexx != None:
                    lines_flag = True

                if lines_flag:

                    lines_variable = ' ' + lines.split("=")[0].strip() + ' '

                    if lines_variable.__contains__(
                            ' ' + if_statement_string.split('(')[0].strip() + ' ') and lines.__contains__("="):

                        if lines.split()[-1] == "_":
                            if lines.split()[-2].upper() in conjunction_keyword_list:
                                multi_line_flag = True
                                multi_line_list.append(lines)
                                continue
                        elif lines.split()[-1].upper() in conjunction_keyword_list:
                            multi_line_flag = True
                            multi_line_list.append(lines)
                        if multi_line_flag:
                            multi_line_list_1 = []
                            multi_line_flag_1 = False
                            # Above function reading in reverese order ,so same logic repeated here to get the multiple lines.
                            with open(filename + '.vb', 'r') as vb_file_1:
                                for lines_1 in vb_file_1.readlines():
                                    if lines_1.strip().startswith("'") or lines_1.strip() == "":
                                        continue
                                    if lines == lines_1 or multi_line_flag_1:

                                        if lines_1.split()[-1] == "_":
                                            if lines_1.split()[-2].upper() in conjunction_keyword_list:
                                                multi_line_flag_1 = True
                                                multi_line_list_1.append(lines_1.replace('\n', ''))
                                                continue
                                        elif lines_1.split()[-1].upper() in conjunction_keyword_list:
                                            multi_line_flag_1 = True
                                            multi_line_list_1.append(lines_1.replace('\n', ''))
                                            continue
                                        else:
                                            multi_line_list_1.append(lines_1.replace('\n', ''))
                                            multi_line_flag_1 = False

                            vb_file_1.close()
                        if multi_line_list_1 != []:
                            assignment_line = " ".join(multi_line_list_1)
                        else:
                            assignment_line = lines
                            multi_line_list_1.append(lines)
                        assign_data_flag = True

                    else:

                        fun_regexx = re.findall(r'^\s*PRIVATE\s*SUB\s*[A0-Z9_]*[(].*[)]', lines, re.IGNORECASE)

                        fun_regexx_1 = re.findall(r'^\s*\t*PUBLIC\s*SHARED\s*FUNCTION\s*[A0-Z9_]*[(].*', lines,
                                                  re.IGNORECASE)

                        if fun_regexx != [] or fun_regexx_1 != []:

                            if fun_regexx != []:
                                fun_value_1 = lines.split()[2].split('(')[0].strip()

                            elif fun_regexx_1 != []:
                                fun_value_1 = lines.split()[3].split('(')[0].strip()

                            if assign_data_flag or fun_value_1.upper() == 'SETUPPAGEPRESENTATION':
                                if_cursor = db.Code_behind_rules.find({"$and": [
                                    {"file_name": dup_data["file_name"].split('.')[0]},
                                    {"function_name": fun_value_1.strip()}]})
                                rule_flag = False
                                rule_data = ""
                                for db_data in if_cursor:
                                    for rule_line in db_data['rule_statement']:
                                        rule_variable = rule_line.split("=")[0].strip() + ' '
                                        if rule_variable.__contains__(
                                                ' ' + if_statement_string.split('(')[
                                                    0] + ' ') and rule_line.__contains__("="):
                                            rule_flag = True
                                            rule_data = db_data
                                            global counter
                                            counter = counter + 1
                                            db.rule_report.update_one({"_id": dup_data["_id"]},
                                                                      {"$set": {"rule_type": "variable_type_rule"}})

                                            db_screen_data = db.screen_data.find_one(
                                                {"ScreenField": dup_data["ScreenField"]})
                                            db.rule_report.insert_one(
                                                {
                                                    "function_name": fun_value_1,
                                                    "ScreenField": dup_data["ScreenField"],
                                                    "SectionName": db_screen_data["SectionName"],
                                                    "CLASLabel": db_screen_data["CLASLabel"]
                                                    , "rule_statement": db_data['rule_statement'],
                                                    "file_name": dup_data["file_name"],
                                                    # "rule_id": dup_data["rule_id"]+'.'+str(counter),
                                                    "rule_id": rule_id_data + '.' + str(counter),
                                                    "Rule_Relation": rule_id_data,
                                                    "rule_description": "",
                                                    "rule_type": "variable_type_rule",
                                                    "lob": dup_data["lob"],
                                                    "dependent_control": "",
                                                    "parent_rule_id": ""})

                                            break

                                varaible_flag = False
                                if not rule_flag:
                                    # from here check for page_load and update the value
                                    if assignment_line == "":
                                        inside_flag = False
                                        assignmanet_flag = False
                                        if_cursor = db.Code_behind_rules_1.find({"$and": [
                                            {"file_name": dup_data["file_name"].split('.')[0]},
                                            {"function_name": "Page_Load"}]})
                                        for db_data in if_cursor:
                                            for rule_line in db_data['source_statement']:
                                                rule_variable = rule_line.split("=")[0].strip() + ' '
                                                if rule_variable.__contains__(
                                                        if_statement_string.split('(')[
                                                            0].strip() + ' ') and rule_line.__contains__("="):
                                                    assignmanet_flag = True
                                                    assignment_line_1 = rule_line
                                                    if_cursor1 = db.Code_behind_rules.find({"$and": [
                                                        {"file_name": dup_data["file_name"].split('.')[0]},
                                                        {"function_name": "Page_Load"}]})
                                                    for db_data in if_cursor1:
                                                        for rule_line in db_data['rule_statement']:
                                                            rule_variable = rule_line.split("=")[0].strip() + ' '
                                                            if rule_variable.__contains__(
                                                                    ' ' + if_statement_string.split('(')[
                                                                        0].strip() + ' ') and rule_line.__contains__(
                                                                "="):
                                                                inside_flag = True

                                                                counter = counter + 1
                                                                db.rule_report.update_one({"_id": dup_data["_id"]},
                                                                                          {"$set": {
                                                                                              "rule_type": "variable_type_rule"}})

                                                                db_screen_data = db.screen_data.find_one(
                                                                    {"ScreenField": dup_data["ScreenField"]})
                                                                varaible_flag = True
                                                                db.rule_report.insert_one(
                                                                    {
                                                                        "function_name": "Page_Load",
                                                                        "ScreenField": dup_data["ScreenField"],
                                                                        "SectionName":
                                                                            db_screen_data[
                                                                                "SectionName"],
                                                                        "CLASLabel":
                                                                            db_screen_data[
                                                                                "CLASLabel"]
                                                                        , "rule_statement": db_data['rule_statement'],
                                                                        "file_name": dup_data["file_name"],
                                                                        "rule_id": dup_data["rule_id"] + '.' + str(
                                                                            counter),
                                                                        "Rule_Relation": dup_data["rule_id"],
                                                                        "rule_description": "",
                                                                        "rule_type": "variable_type_rule",
                                                                        "lob": dup_data["lob"],
                                                                        "parent_rule_id": "",
                                                                        "dependent_control": ""
                                                                    })
                                                                break
                                        if assignmanet_flag and not inside_flag:
                                            dup_data_rule = dup_data["rule_statement"]
                                            dup_data_rule.insert(0,
                                                                 "Page_Load():" + assignment_line_1.replace('\n', ''))
                                            db.rule_report.update_one({"_id": dup_data["_id"]}, {
                                                "$set": [{"rule_statement": dup_data_rule},
                                                         {"rule_type": "variable_type_rule"}]}, upsert=True)

                                    else:

                                        dup_data_rule = dup_data["rule_statement"]
                                        if any(item in assignment_line.split() for item in
                                               ['AndAlso', 'OrElse', 'Or', 'And']):
                                            if ' '.join(multi_line_list_1).__contains__('='):
                                                multi_line_list_value_1 = ' '.join(multi_line_list_1)[
                                                                          ' '.join(multi_line_list_1).index('=') + 1:]
                                            else:
                                                multi_line_list_value_1 = ' '.join(multi_line_list_1)

                                            variable_back_trace_fun(" If " + multi_line_list_value_1 + ' Then',
                                                                    dup_data)

                                        dup_data_rule.insert(0,
                                                             fun_value_1.strip() + '():' + " ".join(multi_line_list_1))
                                        varaible_flag = True
                                        db.rule_report.update_one({"_id": dup_data["_id"]},
                                                                  {"$set": {"rule_statement": dup_data_rule,
                                                                            "rule_type": "variable_type_rule"}})

                                break

                if (
                        function_name_regexx != None or function_name_1_regexx != None or function_name_2_regexx != None) and lines_flag:
                    lines_flag = False

                    function_name_regexx_1 = re.findall(r'^\s*PRIVATE\s*SUB\s*[A0-Z9_]*[(].*[)]', lines, re.IGNORECASE)

                    function_name_1_regexx_2 = re.findall(r'^\s*\t*PUBLIC\s*SHARED\s*FUNCTION\s*[A0-Z9_]*[(].*', lines,
                                                          re.IGNORECASE)

                    function_name_1_regexx_3 = re.findall(r'^\s*\t*PUBLIC\s*SUB\s*[A0-Z9_]*[(].*', lines,
                                                          re.IGNORECASE)

                    if function_name_regexx_1 != [] or function_name_1_regexx_3 != []:

                        fun_value = lines.split()[2].split('(')[0].strip()

                    elif function_name_1_regexx_2 != []:
                        fun_value = lines.split()[3].split('(')[0].strip()

                    vb_file.close()

                    recursive_function(if_statement_string, fun_value)

        return varaible_flag




    except Exception as e:
        exc_type, exc_obj, exc_tb = sys.exc_info()
        fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
        print(exc_type, fname, exc_tb.tb_lineno)
        pass


def left_recursive_function(if_statement_string, fun_name):
    try:

        fun_var = '^\s*\t*PRIVATE\s*SUB\s*[A0-Z9_].*\s*[(].*[)]*'
        fun_var_1 = '^\s*\t*PUBLIC\s*SHARED\s*FUNCTION\s*[A0-Z9_]\s*.*[(].*[)]*'
        fun_name_regexx = '^\s*\t*' + fun_name + '\s*[(].*[)]*'
        lines_flag = False
        assign_data_flag = False
        assignment_line = ""
        varaible_flag = False
        conjunction_keyword_list = ["ANDALSO", "ORELSE", "OR", "AND"]
        multi_line_flag = False
        multi_line_list_1 = []
        multi_line_list = []

        with open(filename + '.vb', 'r') as vb_file:
            for lines in reversed(vb_file.readlines()):
                if lines.strip().startswith("'") or lines.strip() == "":
                    continue

                function_name_regexx = re.search(fun_var, lines, re.IGNORECASE)

                function_name_1_regexx = re.search(fun_var_1, lines,
                                                   re.IGNORECASE)

                function_call_regexx = re.search(fun_name_regexx, lines, re.IGNORECASE)

                if function_call_regexx != None:
                    lines_flag = True

                if lines_flag:
                    lines_variable = ' ' + lines.split("=")[0].strip() + ' '

                    if lines_variable.__contains__(
                            ' ' + if_statement_string.split('(')[0].strip() + ' ') and lines.__contains__("="):

                        if lines.split()[-1] == "_":
                            if lines.split()[-2].upper() in conjunction_keyword_list:
                                multi_line_flag = True
                                multi_line_list.append(lines)
                                continue
                        elif lines.split()[-1].upper() in conjunction_keyword_list:
                            multi_line_flag = True
                            multi_line_list.append(lines)
                        if multi_line_flag:
                            multi_line_list_1 = []
                            multi_line_flag_1 = False
                            # Above function reading in reverese order ,so same logic repeated here to get the multiple lines.
                            with open(filename + '.vb', 'r') as vb_file_1:
                                for lines_1 in vb_file_1.readlines():
                                    if lines_1.strip().startswith("'") or lines_1.strip() == "":
                                        continue
                                    if lines == lines_1 or multi_line_flag_1:

                                        if lines_1.split()[-1] == "_":
                                            if lines_1.split()[-2].upper() in conjunction_keyword_list:
                                                multi_line_flag_1 = True
                                                multi_line_list_1.append(lines_1.replace('\n', ''))
                                                continue
                                        elif lines_1.split()[-1].upper() in conjunction_keyword_list:
                                            multi_line_flag_1 = True
                                            multi_line_list_1.append(lines_1.replace('\n', ''))
                                            continue
                                        else:
                                            multi_line_list_1.append(lines_1.replace('\n', ''))
                                            multi_line_flag_1 = False

                            vb_file_1.close()
                        if multi_line_list_1 != []:
                            assignment_line = " ".join(multi_line_list_1)
                        else:
                            assignment_line = lines
                            multi_line_list_1.append(lines)
                        assign_data_flag = True


                    else:

                        fun_regexx = re.findall(r'^\s*PRIVATE\s*SUB\s*[A0-Z9_]*[(].*[)]', lines, re.IGNORECASE)

                        fun_regexx_1 = re.findall(r'^\s*\t*PUBLIC\s*SHARED\s*FUNCTION\s*[A0-Z9_]*[(].*', lines,
                                                  re.IGNORECASE)

                        if fun_regexx != [] or fun_regexx_1 != []:

                            if fun_regexx != []:
                                fun_value_1 = lines.split()[2].split('(')[0].strip()

                            elif fun_regexx_1 != []:
                                fun_value_1 = lines.split()[3].split('(')[0].strip()

                            if assign_data_flag or fun_value_1.upper() == 'SETUPPAGEPRESENTATION':
                                if_cursor = db.Code_behind_rules.find({"$and": [
                                    {"file_name": dup_data["file_name"].split('.')[0]},
                                    {"function_name": fun_value_1.strip()}]})
                                rule_flag = False
                                rule_data = ""
                                for db_data in if_cursor:
                                    for rule_line in db_data['rule_statement']:
                                        rule_variable = rule_line.split("=")[0].strip() + ' '
                                        if rule_variable.__contains__(
                                                ' ' + if_statement_string.split('(')[
                                                    0].strip() + ' ') and rule_line.__contains__("="):
                                            rule_flag = True
                                            rule_data = db_data
                                            global counter
                                            counter = counter + 1
                                            db.rule_report.update_one({"_id": dup_data["_id"]},
                                                                      {"$set": {"rule_type": "variable_type_rule"}})

                                            db_screen_data = db.screen_data.find_one(
                                                {"ScreenField": dup_data["ScreenField"]})
                                            db.rule_report.insert_one(
                                                {
                                                    "function_name": fun_value_1,
                                                    "ScreenField": dup_data["ScreenField"],
                                                    "SectionName": db_screen_data["SectionName"],
                                                    "CLASLabel": db_screen_data["CLASLabel"]
                                                    , "rule_statement": db_data['rule_statement'],
                                                    "file_name": dup_data["file_name"],
                                                    # "rule_id": dup_data["rule_id"]+'.'+str(counter),
                                                    "rule_id": rule_id_data + '.' + str(counter),
                                                    "Rule_Relation": rule_id_data,
                                                    "rule_description": "",
                                                    "rule_type": "variable_type_rule",
                                                    "lob": dup_data["lob"],
                                                    "dependent_control": "",
                                                    "parent_rule_id": ""})

                                            break

                                varaible_flag = False
                                if not rule_flag:
                                    # from here check for page_load and update the value
                                    if assignment_line == "":
                                        inside_flag = False
                                        assignmanet_flag = False
                                        if_cursor = db.Code_behind_rules_1.find({"$and": [
                                            {"file_name": dup_data["file_name"].split('.')[0]},
                                            {"function_name": "Page_Load"}]})
                                        for db_data in if_cursor:
                                            for rule_line in db_data['source_statement']:
                                                rule_variable = rule_line.split("=")[0].strip() + ' '
                                                if rule_variable.__contains__(
                                                        if_statement_string.split('(')[
                                                            0].strip() + ' ') and rule_line.__contains__("="):

                                                    assignmanet_flag = True
                                                    assignment_line_1 = rule_line
                                                    if_cursor1 = db.Code_behind_rules.find({"$and": [
                                                        {"file_name": dup_data["file_name"].split('.')[0]},
                                                        {"function_name": "Page_Load"}]})
                                                    for db_data in if_cursor1:
                                                        for rule_line in db_data['rule_statement']:
                                                            rule_variable = rule_line.split("=")[0].strip() + ' '
                                                            if rule_variable.__contains__(
                                                                    ' ' + if_statement_string.split('(')[
                                                                        0].strip() + ' ') and rule_line.__contains__(
                                                                "="):
                                                                inside_flag = True

                                                                counter = counter + 1
                                                                db.rule_report.update_one({"_id": dup_data["_id"]},
                                                                                          {"$set": {
                                                                                              "rule_type": "variable_type_rule"}})
                                                                varaible_flag = True
                                                                db_screen_data = db.screen_data.find_one(
                                                                    {"ScreenField": dup_data["ScreenField"]})
                                                                db.rule_report.insert_one(
                                                                    {
                                                                        "function_name": "Page_Load",
                                                                        "ScreenField": dup_data["ScreenField"],
                                                                        "SectionName":
                                                                            db_screen_data[
                                                                                "SectionName"],
                                                                        "CLASLabel":
                                                                            db_screen_data[
                                                                                "CLASLabel"]
                                                                        , "rule_statement": db_data['rule_statement'],
                                                                        "file_name": dup_data["file_name"],
                                                                        "rule_id": dup_data["rule_id"] + '.' + str(
                                                                            counter),
                                                                        "Rule_Relation": dup_data["rule_id"],
                                                                        "rule_description": "",
                                                                        "rule_type": "variable_type_rule",
                                                                        "lob": dup_data["lob"],
                                                                        "parent_rule_id": "",
                                                                        "dependent_control": ""
                                                                    })
                                                                break
                                        if assignmanet_flag and not inside_flag:
                                            dup_data_rule = dup_data["rule_statement"]
                                            dup_data_rule.insert(0,
                                                                 "Page_Load():" + assignment_line_1.replace('\n', ''))
                                            db.rule_report.update_one({"_id": dup_data["_id"]}, {
                                                "$set": [{"rule_statement": dup_data_rule},
                                                         {"rule_type": "variable_type_rule"}]})

                                    else:
                                        dup_data_rule = dup_data["rule_statement"]

                                        if any(item in assignment_line.split() for item in
                                               ['AndAlso', 'OrElse', 'Or', 'And']):

                                            if ' '.join(multi_line_list_1).__contains__('='):
                                                multi_line_list_value_1 = ' '.join(multi_line_list_1)[
                                                                          ' '.join(multi_line_list_1).index('=') + 1:]
                                            else:
                                                multi_line_list_value_1 = ' '.join(multi_line_list_1)

                                            left_variable_back_trace_fun(" If " + multi_line_list_value_1 + ' Then',
                                                                         dup_data)

                                        dup_data_rule.insert(0,
                                                             fun_value_1.strip() + '():' + " ".join(multi_line_list_1))

                                        varaible_flag = True
                                        db.rule_report.update_one({"_id": dup_data["_id"]},
                                                                  {"$set": {"rule_statement": dup_data_rule,
                                                                            "rule_type": "variable_type_rule"}})

                                break

                if (function_name_regexx != None or function_name_1_regexx != None) and lines_flag:
                    lines_flag = False

                    function_name_regexx_1 = re.findall(r'^\s*PRIVATE\s*SUB\s*[A0-Z9_]*[(].*[)]', lines, re.IGNORECASE)

                    function_name_1_regexx_2 = re.findall(r'^\s*\t*PUBLIC\s*SHARED\s*FUNCTION\s*[A0-Z9_]*[(].*', lines,
                                                          re.IGNORECASE)

                    if function_name_regexx_1 != []:

                        fun_value = lines.split()[2].split('(')[0].strip()

                    elif function_name_1_regexx_2 != []:
                        fun_value = lines.split()[3].split('(')[0].strip()

                    vb_file.close()

                    left_recursive_function(if_statement_string, fun_value)

        return varaible_flag

    except Exception as e:
        exc_type, exc_obj, exc_tb = sys.exc_info()
        fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
        print(exc_type, fname, exc_tb.tb_lineno)
        pass


def back_trace_fun(data):
    '''
      :param data: Input json from Release -1.
      :return: Rules inside the function call.
      1.It is a recursive function. The input for this function is the function name of the rules.
      2.We have to take the function name and check whether this fucntion is called from any of the other function or not.
      3.If it is called then check whether the function call is happening under any  condition .IF it is under the condition then
      capture the condition and put it in DB. If it has multiple condition then capture all the rules.
      4.Again take the function name from where it is called and trace back to find the rules.Repeat the same process until
      the function reaches the setuppagepresentation() function.
      5.Repeat this for all condition and find the intermediate rules.
    '''

    try:

        dup1_data = data

        function_flag = False

        function_name = data["function_name"] + '\s*[(].*'

        full_function_data = db.Code_behind_rules_1.find({"file_name": data["file_name"].split('.')[0]})

        rules_lines = db.Code_behind_rules.find({"file_name": data["file_name"].split('.')[0]})

        # Trace Backing the function name using recursive function.

        for lines in full_function_data:

            for in_line in lines["source_statement"]:

                if (in_line.strip().startswith("Private ") and in_line.__contains__(" Sub ")) or (
                        in_line.strip().startswith("Public ") and in_line.__contains__(" Shared ") and
                        in_line.__contains__(" Function ")) or (
                        in_line.strip().startswith("Private ") and in_line.__contains__(" Function ")) or (
                        in_line.strip().startswith("Public ") and in_line.__contains__(
                    " Sub ")) or in_line.strip().upper().startswith("IF") or in_line.strip().upper().startswith(
                    "CASE ") or \
                        in_line.strip().startswith("SELECT "):
                    continue

                function_name_regexx = re.findall(function_name, in_line, re.IGNORECASE)

                # if if1_regexx!=[] or if_regexx!=[]:
                #
                #     back_track_if_flag=True
                #     back_track_if_counter=back_track_if_counter+1
                #
                # elif back_track_if_flag:
                #     if_data_list.append(in_line)
                #
                # elif end_if_regexx!=[]:
                #
                #     back_track_if_counter=back_track_if_counter-1
                #     if back_track_if_counter==0:
                #        back_track_if_flag=False

                if function_name_regexx != []:

                    # checking if this function is called within any rules or not.

                    for rec_data in rules_lines:
                        for k in rec_data["rule_statement"]:
                            if (k.strip().startswith("Private ") and k.__contains__(" Sub ")) or (
                                    k.strip().startswith("Private ") and k.__contains__(" Function ")) or (
                                    k.strip().startswith("Public ") and k.__contains__(" Shared ") and
                                    k.__contains__(" Function ")) or (
                                    k.strip().startswith("Public ") and k.__contains__(
                                " Sub ")) or k.strip().upper().startswith(
                                "IF") or k.strip().upper().startswith("CASE ") or \
                                    k.strip().startswith("SELECT "):
                                continue
                            function_name_regexx_1 = re.findall(function_name, k, re.IGNORECASE)
                            if function_name_regexx_1 != []:
                                global counter
                                counter = counter + 1
                                function_flag = True
                                db_screen_data = db.screen_data.find_one(
                                    {"ScreenField": dup_data["ScreenField"]})
                                db.rule_report.insert_one({"function_name": rec_data["function_name"],
                                                           "ScreenField": dup_data["ScreenField"],
                                                           "SectionName": db_screen_data["SectionName"],
                                                           "CLASLabel": db_screen_data["CLASLabel"]
                                                              , "rule_statement": rec_data["rule_statement"],
                                                           "file_name": dup_data["file_name"],
                                                           "rule_id": dup_data["rule_id"] + '.' + str(counter),
                                                           "Rule_Relation": dup_data["rule_id"],
                                                           "rule_description": "",
                                                           "rule_type": "Function_Invocation_Rule",
                                                           "lob": dup_data["lob"],
                                                           "dependent_control": ""
                                                           })
                    if not function_flag:
                        db_screen_data = db.screen_data.find_one(
                            {"ScreenField": dup_data["ScreenField"]})
                        db.rule_report.insert_one({"function_name": "",
                                                   "ScreenField": dup_data["ScreenField"],
                                                   "SectionName": db_screen_data["SectionName"],
                                                   "CLASLabel": db_screen_data["CLASLabel"],
                                                   "rule_statement": [data["function_name"] + '()'],
                                                   "file_name": dup_data["file_name"],
                                                   "rule_id": "",
                                                   "Rule_Relation": dup_data["rule_id"],
                                                   "rule_description": "",
                                                   "rule_type": "",
                                                   "lob": dup_data["lob"],
                                                   "dependent_control": ""
                                                   })

                    # calling the same function until setup page presentation.

                    if lines["function_name"].upper() == "SETUPPAGEPRESENTATION" or lines[
                        "function_name"].upper() == "SAVEPAGEDATA" \
                            or lines["function_name"].upper() == "SAVEDATA":
                        break

                    back_trace_fun(lines)

    except Exception as e:
        exc_type, exc_obj, exc_tb = sys.exc_info()
        fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
        print(exc_type, fname, exc_tb.tb_lineno)


function_list = tuple(db.Code_behind_rules_1.distinct("function_name"))
Rule_Buffer = []


def state_scan_values(function_name=None, linelist=None):
    brace_counter = 0
    state_scan_line = ""
    test_list = []
    found_flag = False
    cursor = {}
    if function_name != None:
        cursor = db.Code_behind_rules_1.find_one({"function_name": function_name}, {'_id': 0})
    else:
        cursor['source_statement'] = linelist

    for line in cursor['source_statement']:
        if line.lower().__contains__("statescan.") or found_flag:
            found_flag = True
            for i in line.strip():
                if i == "(":
                    brace_counter = brace_counter + 1
                if i == ')':
                    brace_counter = brace_counter - 1

            state_scan_line = state_scan_line + line.strip()

        if brace_counter == 0 and not line.lower().__contains__("statescan."):
            found_flag = False
    print(state_scan_line)

    Lob_code = state_scan_line.split("=")[1].split(".isRuleApplicable(")[1].split(",")[0]
    State = state_scan_line.split("=")[1].split(".isRuleApplicable(")[1].split(",")[1]
    Rule = state_scan_line.split("=")[1].split(".isRuleApplicable(")[1].split(",")[-1].replace(")", "")
    for line1 in cursor['source_statement']:
        ''' if state code is assigned to a variable inside the function '''
        if line1.__contains__(State + " ="):
            State = line1.split("=")[-1].strip()

    return Lob_code, State, Rule


def var_statescan_finder(dup_data):
    for line in dup_data['rule_statement']:
        if line.__contains__("Lob_Code :"):
            break
        if line.lower().__contains__("statescan."):
            Lob_code, State, Rule = state_scan_values(None, dup_data['rule_statement'])
            state_scan_line = "Lob_Code : " + Lob_code + "," + "State : " + State + "," + " Rule :" + Rule + ","
            dup_data['rule_statement'].insert(0, state_scan_line)
            new_list = copy.deepcopy(dup_data['rule_statement'])
            db.rule_report.update_one({"_id": dup_data["_id"]},
                                      {"$set": {
                                          "rule_statement": new_list}})
            break


def Function_processer(dup_data):
    print(dup_data)
    object_fun = False
    global counter
    no_rule_flag = True

    parentruleid_list = []

    external_fun_cur = db.master_rules.distinct("function_name", (
        {"Function_Type": "PS", "file_name": dup_data["file_name"].split(".")[0]}))

    external_fun_set = [x for x in external_fun_cur]
    try:

        for line in dup_data['rule_statement']:
            if line.__contains__("Lob_Code :"):
                break

            if line.lower().__contains__("statescan."):
                Lob_code, State, Rule = state_scan_values(None, dup_data['rule_statement'])
                state_scan_line = "Lob_Code : " + Lob_code + "," + "State : " + State + "," + " Rule :" + Rule + ","
                dup_data['rule_statement'].insert(0, state_scan_line)
                new_list = copy.deepcopy(dup_data['rule_statement'])
                db.rule_report.update_one({"_id": dup_data["_id"]},
                                          {"$set": {
                                              "rule_statement": new_list}})
                break

        ref_var_list = fetchimport_var(dup_data['file_name'])
        ref_file_name_list = fetch_vbfilename(dup_data['lob'])

        for line in dup_data['rule_statement']:



            matches1 = [x for x in ref_var_list if " "+x in line]
            if matches1 != []:
                matches1 = list(dict.fromkeys(matches1))
                for match in matches1:
                    counter = counter + 1
                    object_fun = True
                    calling_function_name = line.split(match)[1].split("(")[0]
                    No_of_perams, param_list = fetch_parametres_count(dup_data['rule_statement'], calling_function_name)
                    """Include No of parameters  in the DB constraint """
                    cursor1 = db.master_rules_report.find(
                        {"Function_name": calling_function_name, "Code_Link_Flag" : "TRUE","No_of_parameters":No_of_perams}, {'_id': 0})

                    for i in cursor1:
                        parentruleid_list.append(i['Rule_id'])
                        # print(calling_function_name)
                    dup_data["External_rule_id"] = ",".join(parentruleid_list)
                    db.rule_report.update_one({"_id": dup_data["_id"]},
                                              {"$set": {"rule_type": "function_type_rule"}})

                    db.rule_report.update_one({"_id": dup_data["_id"]},
                                              {"$set": {"External_rule_id": ",".join(parentruleid_list)}})

                    """filename.function name handling """
                break
            matches2 = [x for x in ref_file_name_list if x in line]
            if matches2 != []:
                for match in matches2:
                    # print("filen", line)
                    object_fun = True
                    counter = counter + 1
                    calling_function_name = match
                    No_of_perams, param_list = fetch_parametres_count(dup_data['rule_statement'], calling_function_name)
                    cursor1 = db.master_rules_report.find(
                        {"Function_name": calling_function_name}, {'_id': 0})

                    for i in cursor1:
                        parentruleid_list.append(i['Rule_id'])
                    dup_data["External_rule_id"] = ",".join(parentruleid_list)

                    db.rule_report.update_one({"_id": dup_data["_id"]},
                                              {"$set": {"rule_type": "function_type_rule"}})
                    db.rule_report.update_one({"_id": dup_data["_id"]},
                                              {"$set": {"External_rule_id": ",".join(parentruleid_list)}})
            if object_fun == False:
                matches3 = [x for x in external_fun_set if x in line]
                if matches3 != []:
                    for match in matches3:
                        counter = counter + 1
                        calling_function_name = match

                        No_of_perams, param_list = fetch_parametres_count(dup_data['rule_statement'],
                                                                          calling_function_name)
                        """inculde noparams var as constrain """
                        cursor1 = db.master_rules_report.find({"Function_name": calling_function_name, "Function_Type": "PBS",
                                                        }, {'_id': 0})

                        for i in cursor1:
                            # print(i["No of Parameters"])

                            parentruleid_list.append(i['Rule_id'])


                        dup_data["External_rule_id"] = ",".join(parentruleid_list)

                        db.rule_report.update_one({"_id": dup_data["_id"]},
                                                  {"$set": {"rule_type": "function_type_rule"}})
                        db.rule_report.update_one({"_id": dup_data["_id"]},
                                                  {"$set": {"External_rule_id": ",".join(parentruleid_list)}})
                    break
            matches = [x for x in function_list if x in line]

            if matches != []:

                for match in matches:

                    calling_function_name = match

                    No_of_perams, param_list = fetch_parametres_count(dup_data['rule_statement'], calling_function_name)
                    db.rule_report.update_one({"_id": dup_data["_id"]},
                                              {"$set": {"rule_type": "function_type_rule"}})

                    """Update json with no of parameters                     

                     """

                    # print(line)

                    cursor = db.Code_behind_rules_1.find_one({"function_name": "".join(matches)}, {'_id': 0})

                    for line in cursor['source_statement']:
                        Rule_Buffer.append(line)
                        if line.strip().lower().startswith("if"):
                            no_rule_flag = False
                    rule_extractor("".join(matches))



    except Exception as e:
        exc_type, exc_obj, exc_tb = sys.exc_info()
        fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
        print(exc_type, fname, exc_tb.tb_lineno)


def rule_extractor(fun_name):
    output_json_value = {}

    global counter
    test_data = []
    temp_list = []
    fun_name_list = []
    fun_name_list.append(fun_name)
    parent_if = False
    fun_flag = False

    try:


        for index, line in enumerate(Rule_Buffer, 0):

            # if line.__contains__(fun_name):
            #     continue

            if (line.lower().__contains__("end sub") or  line.lower().__contains__("end function"))and len(fun_name_list) >= 2:

                fun_name_list.pop()
                fun_name = fun_name_list[-1]
                fun_flag = False
                no_rule = [x for x in temp_list if x.strip().lower().startswith("if")]
                if no_rule == []:
                    counter = counter + 1

                    output_json_value["lob"] = dup_data["lob"]
                    output_json_value["file_name"] = dup_data["file_name"]
                    output_json_value["function_name"] = fun_name
                    output_json_value["ScreenField"] = dup_data['ScreenField']
                    output_json_value["CLASLabel"] = dup_data['CLASLabel']
                    output_json_value["rule_statement"] = temp_list
                    output_json_value["rule_description"] = dup_data["rule_description"]
                    output_json_value["parent_rule_id"] = dup_data["rule_id"]
                    output_json_value["rule_id"] = ""
                    output_json_value["dependent_control"] = dup_data["dependent_control"]
                    output_json_value["rule_type"] = "function_type_rule"
                    output_json_value["Rule_Relation"] = dup_data["Rule_Relation"]

                    db.rule_report.insert_one(copy.deepcopy(output_json_value))
                    temp_list.clear()
                    output_json_value.clear()




            if line.lower().__contains__("end if"):
                parent_if = False

            if line.strip().lower().startswith("if") and parent_if == False:
                parent_if = True


                counter = counter + 1
                if counter == 219:
                    print(counter)

                output_json_value["lob"] = dup_data["lob"]
                output_json_value["file_name"] = dup_data["file_name"]
                output_json_value["function_name"] = fun_name
                output_json_value["ScreenField"] = dup_data['ScreenField']
                output_json_value["CLASLabel"] = dup_data['CLASLabel']
                output_json_value["rule_statement"] = if_to_end_if_collecter(Rule_Buffer, line, index)
                output_json_value["rule_description"] = dup_data["rule_description"]
                output_json_value["parent_rule_id"] = dup_data["rule_id"]
                output_json_value["rule_id"] = dup_data["rule_id"] + "." + str(counter)
                output_json_value["dependent_control"] = dup_data["dependent_control"]
                output_json_value["rule_type"] = "function_type_rule"
                output_json_value["Rule_Relation"] = dup_data["Rule_Relation"]




                db.rule_report.insert_one(copy.deepcopy(output_json_value))

                test_data.append(copy.deepcopy(output_json_value))
                output_json_value.clear()
            matches = [x for x in function_list if x in line and not line.__contains__(fun_name)]
            if matches != [] and "".join(matches) != fun_name:
                append_resurcive_buff("".join(matches), index)
                fun_name_list.append("".join(matches))
                fun_name = fun_name_list[-1]
                parent_if = False

            if (line.lower().__contains__("sub") or  line.lower().__contains__("function")) and ( line.lower().__contains__("public") or line.lower().__contains__("private")):
                temp_list.clear()
                fun_flag = True
            if fun_flag:
                temp_list.append(line)




        Rule_Buffer.clear()
    except Exception as e:
        exc_type, exc_obj, exc_tb = sys.exc_info()
        fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
        print(exc_type, fname, exc_tb.tb_lineno)


def calling_fun_parms_count(line, fun):
    params_count = len(line.split(fun)[1].split("(")[1].split(")")[0].split(","))

    return params_count


def append_resurcive_buff(fun, index):
    output_json_value={}
    temp_list =[]
    global counter
    try:
        cursor = db.Code_behind_rules_1.find_one({"function_name": fun}, {'_id': 0})
        # no_rule = [x for x in cursor["source_statement"] if x.strip().lower().startswith("if")]
        # temp_list.append(fun)
        #
        # if no_rule == []:
        #     counter = counter+1
        #
        #     output_json_value["lob"] = dup_data["lob"]
        #     output_json_value["file_name"] = dup_data["file_name"]
        #     output_json_value["function_name"] = fun
        #     output_json_value["ScreenField"] = dup_data['ScreenField']
        #     output_json_value["CLASLabel"] = dup_data['CLASLabel']
        #     output_json_value["rule_statement"] = temp_list
        #     output_json_value["rule_description"] = dup_data["rule_description"]
        #     output_json_value["parent_rule_id"] = dup_data["rule_id"]
        #     output_json_value["rule_id"] = dup_data["rule_id"]+ "." + str(counter)
        #     output_json_value["dependent_control"] = dup_data["dependent_control"]
        #     output_json_value["rule_type"] = "function_type_rule"
        #     output_json_value["Rule_Relation"] = dup_data["Rule_Relation"]
        #
        #     db.rule_report.insert_one(copy.deepcopy(output_json_value))
        #     temp_list.clear()
        #     output_json_value.clear()
        #
        #

        for li in cursor["source_statement"]:
            index = index + 1
            Rule_Buffer.insert(index, li)


    except Exception as e:
        exc_type, exc_obj, exc_tb = sys.exc_info()
        fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
        print(exc_type, fname, exc_tb.tb_lineno,fun)


def fetch_parametres_count(fun_lines_list, calling_fun_name):
    line_collector_variable = ''
    line_collector_flag = False

    for line in fun_lines_list:

        if line_collector_flag:
            if line.rstrip().endswith(")"):
                line_collector_variable = line_collector_variable + '\n' + line
                parameters_list = line_collector_variable.replace(")", "").replace("\n", "").split(",")
                parameters_count = len(parameters_list)
                return parameters_count, parameters_list

            else:
                line_collector_variable = line_collector_variable + '\n' + line
                continue

        if line.__contains__(calling_fun_name):
            if line.rstrip().endswith(")") or line.__contains__(")"):
                para_name_collection = line.split("(")
                para_name_list = para_name_collection[0].split()
                parameters_list = para_name_collection[1].split(")")[0].replace("\n", "").split(",")
                if parameters_list == [""]:
                    parameters_count = 0
                else:
                    parameters_count = len(parameters_list)
                para_name = para_name_list[-1]
                return parameters_count, parameters_list
            else:
                # para_name_collection = line.split("(")
                # para_name_list = para_name_collection[1]
                line_collector_variable = line.split("(")[1] + '\n'
                # para_name = para_name_list[-1]
                line_collector_flag = True
                continue
    return "", ""


def if_to_end_if_collecter(lines_list, line, index):
    try:
        if_counterer = 0
        collect_flag = False
        storage = []
        if_flag = False
        level_list = []
        Lob_code, State, Rule = "", "", ""
        state_scan_line = ""

        if index == 2721:
            print(lines_list[index:])

        for ln in lines_list[index:]:
            level_list.append(ln)
            if ln == line:
                if_counterer = 0
                collect_flag = True
                if_flag = True
            if if_flag and ln.lower().strip().startswith("if"):
                if_counterer = if_counterer + 1
            if collect_flag:
                storage.append(ln)
            if ln.lower().strip().startswith("end if"):
                if_counterer = if_counterer - 1
                if if_counterer == 0:
                    break

        for i in level_list:

            if i.lower().__contains__("statescan."):
                Lob_code, State, Rule = state_scan_values(None, level_list)
                state_scan_line = "Lob_Code : " + Lob_code + "," + "State : " + State + "," + " Rule :" + Rule

        # level_list.append(storage)

        storage.insert(0, state_scan_line)
        return storage
    except Exception as e:
        exc_type, exc_obj, exc_tb = sys.exc_info()
        fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
        print(exc_type, fname, exc_tb.tb_lineno)


def get_var_app_shared(filename):
    ref_var_list = []
    with open(code_location + "\\WebApplications\\" + filename + '.vb', 'r') as vb_file:
        for lines in vb_file.readlines():
            if lines.upper().__contains__("AS") and (
                    lines.strip().lower().startswith("private") or lines.strip().lower().startswith("dim")):
                if lines.split()[2].upper() == "AS":
                    line_list = lines.split()
                    if (line_list[0].lower() == "private" or line_list[0].lower() == "dim") and lines.__contains__(
                            ".ApplicationShared"):
                        ref_var_list.append(line_list[1])

    return ref_var_list


def fetchimport_var(filename):
    ref_var_list = []
    with open(code_location + "\\WebApplications\\" + filename + '.vb', 'r') as vb_file:
        for lines in vb_file.readlines():
            if lines.upper().__contains__("AS") and (
                    lines.__contains__(".Lob") or lines.__contains__(" Lob") or lines.__contains__(
                " BusinessServices.")) and (
                    lines.strip().lower().startswith("private") or lines.strip().lower().startswith("dim")):
                if lines.split()[2].upper() == "AS":
                    line_list = lines.split()
                    if line_list[0].lower() == "private" or line_list[0].lower() == "dim":
                        ref_var_list.append(line_list[1] + ".")

    return tuple(ref_var_list)


def fetch_vbfilename(lob):
    lob = 'LobPF'
    ref_file_name_list = []
    # print(code_location)
    import os
    file_list = os.listdir(code_location + "\\ApplicationAssembles\\" + lob + '\\' + lob + ".BusinessRules")
    # print(file_list)
    for i in file_list:
        ref_file_name_list.append(i.split(".")[0] + ".")

    return tuple(ref_file_name_list)


def single_line_if(input_file):
    try:
        process_list = []
        rare_if_collecting_flag = False
        if_collecting_flag = False
        main_if_index = ""
        end_if_index = 0
        Then_flag = False

        ''' The below for loop is used to append all lines in the process list
            There are certain scenarios in which If does not have End If
            Below for loop is used to add End If's to Standalone If's which doesnot have If's'''

        for append_lines in input_file.readlines():
            then_index = ""
            then_line = ""
            balance_append_line = ""
            if append_lines.strip() == "":
                continue
            if append_lines.lstrip().startswith("'"):
                continue

            if rare_if_collecting_flag:
                if append_lines.casefold().__contains__("then"):
                    if not append_lines.rstrip().casefold().endswith("then"):
                        # print("Waited till the line containing then meetsup")
                        # process_list.append(append_lines)
                        then_index = append_lines.casefold().find("then")
                        then_line = append_lines[:then_index + 4]
                        balance_append_line = append_lines[then_index + 5:]
                        process_list.append(then_line)
                        process_list.append("\n" + balance_append_line)
                        rare_if_collecting_flag = False
                        if_collecting_flag = True
                        continue
                    else:
                        process_list.append(append_lines)
                        rare_if_collecting_flag = False
                        continue

                else:
                    process_list.append(append_lines)
                    continue

            if if_collecting_flag:

                if append_lines[main_if_index] != " " and not re.search('.* end if.*', append_lines,
                                                                        re.IGNORECASE) and not re.search('.* elseif.*',
                                                                                                         append_lines,
                                                                                                         re.IGNORECASE) and not re.search(
                        '.* else .*', append_lines, re.IGNORECASE):

                    if append_lines.casefold().__contains__("end sub") or append_lines.casefold().__contains__(
                            "end function"):
                        # process_list.append(append_lines)
                        process_list.append('\n' + " End If\n")
                        process_list.append(append_lines)
                        if_collecting_flag = False
                        continue
                    elif re.search('^\s*If\s.*', append_lines, re.IGNORECASE):
                        process_list.append('\n' + " End If\n")
                        if_collecting_flag = False
                    elif re.search('^\s*elseif\s.*', append_lines, re.IGNORECASE):
                        process_list.append(append_lines)
                        continue
                    elif re.search('^\s*else\s.*', append_lines, re.IGNORECASE):
                        process_list.append(append_lines)
                        continue
                    else:
                        process_list.append('\n' + " End If\n")
                        process_list.append(append_lines)
                        if_collecting_flag = False
                        continue

                elif append_lines[main_if_index] != " ":

                    if append_lines.strip().lower().__contains__("end if"):
                        end_if_index = append_lines.lower().index("end if")
                    elif append_lines.strip().lower().__contains__("elseif "):
                        end_if_index = append_lines.lower().index("elseif ")
                    elif append_lines.strip().lower().__contains__("else "):
                        end_if_index = append_lines.lower().index("else ")
                    if main_if_index > end_if_index:
                        process_list.append('\n' + " End If\n")
                        process_list.append(append_lines)
                        if_collecting_flag = False
                        continue
                    elif main_if_index == end_if_index:
                        process_list.append(append_lines)
                        if_collecting_flag = False
                        continue
                    else:
                        process_list.append(append_lines)
                        continue
                elif append_lines.casefold().__contains__("end sub") or append_lines.casefold().__contains__(
                        "end function"):
                    process_list.append('\n' + " End If\n")
                    process_list.append(append_lines)
                    if_collecting_flag = False
                    continue
                else:
                    process_list.append(append_lines)
                    continue

            if re.search('^\s*If.*', append_lines, re.IGNORECASE):
                if append_lines.rstrip().casefold().endswith("then"):
                    process_list.append(append_lines)
                    continue
                if not append_lines.casefold().__contains__("then"):
                    main_if_index = append_lines.index("If ")
                    process_list.append(append_lines)
                    rare_if_collecting_flag = True
                    continue
                if append_lines.casefold().__contains__("then"):
                    if not append_lines.rstrip().casefold().endswith("then"):
                        main_if_index = append_lines.index("If ")
                        # process_list.append(append_lines)
                        then_index = append_lines.casefold().find("then")
                        then_line = append_lines[:then_index + 4]
                        balance_append_line = append_lines[then_index + 5:]
                        process_list.append(then_line)
                        process_list.append("\n" + balance_append_line)
                        if_collecting_flag = True
                        continue
                else:
                    process_list.append(append_lines)
                    continue
            else:
                process_list.append(append_lines)
                continue

        return process_list
    except Exception as e:
        exc_type, exc_obj, exc_tb = sys.exc_info()
        fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
        print(exc_type, fname, exc_tb.tb_lineno)


for filename in glob.glob(os.path.join(vb_path, '*.aspx')):
    print(filename, vb_path)
    metadata = []
    main(filename, metadata)
