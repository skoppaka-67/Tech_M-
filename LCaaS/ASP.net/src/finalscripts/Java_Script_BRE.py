import config
from pymongo import MongoClient
import glob,os,copy
import re
import json
import csv
import sys
mongoClient = MongoClient('localhost', 27017)
db = mongoClient['asp4']
vb = config.codebase_information['VB']['folder_name']
code_location =config.codebase_information['code_location']

vb_path=code_location+'\\'+vb
metadata = []
Final_metadata = []
vb_metadata = []
parent_rule_id_list= []

def fetch_With(id, filename):
    sub_storage = []
    collect_flag = False
    if filename.lower().endswith(".vb"):
        filename = "\\".join(filename.split("\\")[:-1]) + "\\" + filename.split("\\")[-1].replace(".VB", "")
    with open(filename , 'r') as vb_file:
        for lines in vb_file.readlines():
            with_id = "With " + id
            # print(with_id)
            # if lines.__contains__(with_id):
            if re.search(with_id + "$", lines):
                collect_flag = True

            if lines.__contains__("End Sub"):
                if collect_flag == True:
                    sub_storage.append(lines)
                collect_flag = False

            if collect_flag:
                sub_storage.append(lines)

    return sub_storage


def fetch_sub(id, filename):
    storage = []

    fullsubstorage = []
    collect_flag = False
    if filename.lower().endswith(".vb"):
        filename = "\\".join(filename.split("\\")[:-1]) + "\\" + filename.split("\\")[-1].replace(".VB", "")
    with open(filename, 'r') as vb_file:
        file_handle = vb_file.readlines()
        for lines in reversed(file_handle):
            with_id = "With " + id
            if re.search(with_id + "$", lines):
                collect_flag = True
                continue
            if lines.__contains__("Private Sub"):
                if collect_flag == True:
                    fullsubstorage.append(lines)
                collect_flag = False
            if collect_flag:
                fullsubstorage.append(lines)

    storage = fullsubstorage + fetch_With(id, filename)

    return storage

def js_loader(filename):
    funtion_storage =[]

    funtion_storage_dict = {}
    collect_flag = False
    brace_count = 0
    if_counter = 0

    json_vlaue = {
        "lob":"",
        "filename": "",
        'function':"",
        'rules':''
    }
    with open(filename, 'r') as js_file:
        for line in js_file.readlines():
            if_flag = False
            if line.lower().strip().startswith("//") or line.split()==[]:
                continue
            if line.lower().strip().startswith("function") and not line.strip().endswith(';'):
                funtion_name = line.strip().replace("function", '').replace('{', "").split('(')[0]
                collect_flag = True
            if collect_flag == True and line.strip().startswith("if"):
                if_flag = True
                if_counter = if_counter + 1

                funtion_storage.append(str(if_counter) + ".)" + line.strip() )

            if collect_flag and not line.__contains__("function") and line.strip().split() != []:
                if if_flag:
                    if if_flag and line.__contains__("{"):
                        brace_count = brace_count + 1
                        continue

                    else:
                        continue

                funtion_storage.append(line.strip() )
            if line.strip().__contains__("{"):
                brace_count = brace_count + 1
            if line.strip().__contains__("}"):
                brace_count = brace_count - 1
            if brace_count == 0 and not line.__contains__("function") and line.strip().split() != [] and collect_flag :
                collect_flag = False
                funtion_storage_dict[funtion_name] = copy.deepcopy(funtion_storage)
                funtion_storage.clear()
                if_counter = 0

    for function_name, content in funtion_storage_dict.items():
        json_vlaue['filename'] = filename.split("\\")[-1].split('.')[0]
        json_vlaue['function'] = function_name.strip()
        json_vlaue['rules'] = content
        metadata.append(copy.deepcopy(json_vlaue))

        # print(json.dumps(metadata, indent=4))

    return None

def Rule_assigniner(filename,i,js_function_list,rule_counter):
    output_json = {
         "Lob": "",
        "Event_type":"",
        'file_name': '',
        'feild_name': '',
        'function_name': '',
        'rules_statement': '',
        'type': '',
        'rule_description': '',
        'rule_id': '',
        'partent_rule_id': '',
        'rule_type': 'client side',
        'dependent_control': '',

    }


    js_function_name = i['Js_function'].split('=')[-1].replace(";", '').strip().split("(")[0]
    js_cursor = db.java_script_storage.find({"function": js_function_name}, {'_id': 0})
    for j in js_cursor:
        rule_counter = rule_counter+1
        js_rules = j['rules']
        output_json['Lob'] = i["Lob"]
        output_json['Event_type'] = i["Event_type"]
        output_json['file_name'] = filename.split("\\")[-1].split('.')[0]
        output_json['feild_name'] = i['Control_id']
        output_json['function_name'] = js_function_name
        output_json['rules_statement'] = "\n".join(js_rules)

        output_json['rule_id'] = "Rule"+'-'+str(rule_counter)
        for rules in js_rules:
            if rules.__contains__('notificationSection'):
                output_json['type'] = 'Notification Message'
            if rules.__contains__('.PageService'):
                output_json['type'] = 'Web Method'
                # rules.split(')')[1].split('.add')[0]

        Final_metadata.append(copy.deepcopy(output_json))

        for stmnts in js_rules:
            for function in js_function_list:
                if stmnts.__contains__(function):
                    js_cursor_child_fun = db.java_script_storage.find({"function": function}, {'_id': 0})
                    output_json['Lob'] = i["Lob"]
                    output_json['Event_type'] = i["Event_type"]
                    output_json['file_name'] = filename.split("\\")[-1].split('.')[0]
                    output_json['feild_name'] = i['Control_id']
                    output_json['function_name'] = function
                    rule_counter1 = rule_counter + 1
                    output_json['rule_id'] = "Rule"+'-'+str(rule_counter1)
                    output_json['partent_rule_id'] = "Rule"+'-'+str(rule_counter)
                    rule_counter = rule_counter1
                    for rules in js_rules:
                        if rules.__contains__('notificationSection'):
                            output_json['type'] = 'Notification Message'
                        if rules.__contains__('.PageService'):
                            output_json['type'] = 'Web Method'
                    for k in js_cursor_child_fun:
                        js_chaild_rules = k['rules']

                        output_json['rules_statement'] = "\n".join(js_chaild_rules)
                        Final_metadata.append(copy.deepcopy(output_json))
                parent_rule_id_list.append(output_json['rule_id'])
    return rule_counter


def codebehind_loader(filename,control_id):
    storage = fetch_sub(control_id,filename)
    if storage == []:
        storage = no_with_storage(control_id, filename)
    Multi_fun_flag = False
    onClick_event_list=['.Validators.Custom.ClientFunction', 'OnClick','OnClientBlur','OnClientChange','OnClientClick','OnClientFocus','OnClientMouseOut','OnClientMouseOver','OnCommand','OnControlValidation']
    json_vlaue = {
        "Lob": "",
        "Event_type"
        "Filename": "",
        'Control_id': "",
        'Js_function': '',
        'Multi_fun_flag':''
    }
    lob_name = "LobPF"
    for line in storage:
        for event in onClick_event_list:
            if line.__contains__(event):
                if line.split('=')[-1].strip().__contains__(";"):

                    Mulit_function_list = line.split('=')[-1].strip().replace('"', '').replace("'", "").split(";")
                    Multi_fun_flag = True
                    if Multi_fun_flag:
                        if Mulit_function_list[1]=='':
                            json_vlaue['Lob'] = lob_name
                            json_vlaue['Filename'] = filename.split("\\")[-1].split('.')[0] + ".js"
                            json_vlaue['Event_type'] = event
                            json_vlaue['Js_function'] = line.strip().replace('"', '').replace("'", "")
                            json_vlaue['Control_id'] = control_id
                            json_vlaue['Multi_fun_flag'] = "False"
                            vb_metadata.append(copy.deepcopy(json_vlaue))
                        else:
                            json_vlaue['Lob'] = lob_name
                            json_vlaue['Filename'] = filename.split("\\")[-1].split('.')[0]+ ".js"
                            json_vlaue['Event_type'] = event
                            json_vlaue['Js_function'] = Mulit_function_list
                            json_vlaue['Control_id'] = control_id
                            json_vlaue['Multi_fun_flag'] = 'True'
                            vb_metadata.append(copy.deepcopy(json_vlaue))

                else:
                    json_vlaue['Lob'] = lob_name
                    json_vlaue['Filename'] = filename.split("\\")[-1].split('.')[0]+ ".js"
                    json_vlaue['Event_type'] = event
                    json_vlaue['Js_function'] = line.strip().replace('"', '').replace("'", "")
                    json_vlaue['Control_id'] = control_id
                    json_vlaue['Multi_fun_flag'] = 'False'
                    vb_metadata.append(copy.deepcopy(json_vlaue))
    return None
def no_with_storage(id,filename):
    sub_storage = []

    # if filename.lower().endswith(".vb"):
    #     filename = "\\".join(filename.split("\\")[:-1]) + "\\" + filename.split("\\")[-1].replace(".VB", "")
    with open(filename, 'r') as vb_file:
        for lines in vb_file.readlines():
            if lines.__contains__(id+"."):
                sub_storage.append(lines)
    return sub_storage


def main():
    filename = ''
    for filename in glob.glob(os.path.join(vb_path,'*.js')):
        filename = filename

        js_loader(filename)

    control_id_list = db.screen_data.distinct("ScreenField")

    for control_id in control_id_list:
        codebehind_loader(filename.replace('.js', '.aspx.vb'), control_id)

    if metadata != []:
        if db.drop_collection("java_script_storage"):
            print("js DB deleted")

        if db.java_script_storage.insert_many(metadata):
            print("js DB inserted")
    if vb_metadata != []:
        if db.drop_collection("vb_script_storage"):
            print("VB DB deleted")

        if db.vb_script_storage.insert_many(vb_metadata):
            print("VB DB inserted")
    js_function_list = db.java_script_storage.distinct("function")
    cursor = db.vb_script_storage.find({'type': {"$ne": "metadata"}}, {'_id': 0})
    rule_counter = 0
    for i in cursor:

        # print(count)


        if i['Multi_fun_flag'] == 'False':

            rule_counter = Rule_assigniner(filename,i,js_function_list,rule_counter)

        else:
            js_function_name_list = i['js_function'].split('=')[-1].split(";")
            for fun in js_function_name_list:
                rule_counter = Rule_assigniner(filename, fun, js_function_list,rule_counter)



    print(json.dumps(Final_metadata, indent=4))
    if Final_metadata != []:
        if db.drop_collection("Bussiness_Rules"):
            print("Bussiness_Rules DB deleted")

        if db.Bussiness_Rules.insert_many(Final_metadata):
            print("Bussiness_Rules DB inserted")

    metadata1 = db.Bussiness_Rules.find({}, {"_id": 0,"file_name" : 1, "feild_name" : 1,"function_name" : 1,"rules_statement" : 1,"type" : 1,"rule_description" : 1,"rule_id" : 1,
        "partent_rule_id" : 1,"rule_type" : 1,"dependent_control" : 1})
    out_data = []

    for screen_data in metadata1:
        out_data.append(screen_data)

    with open("Bussiness_Rules" + '.csv', 'w', newline="") as output_file:
        Fields = ["file_name" , "feild_name","function_name" ,"rules_statement" ,"type" ,"rule_description" ,"rule_id" ,
        "partent_rule_id","rule_type" ,"dependent_control" ]
        dict_writer = csv.DictWriter(output_file, fieldnames=Fields)
        dict_writer.writeheader()
        dict_writer.writerows(out_data)

main()


