import config
from pymongo import MongoClient
import glob,os,copy
import re
import json
import csv
import sys
mongoClient = MongoClient('localhost', 27017)
db = mongoClient['asp']
vb = config.codebase_information['VB']['folder_name']
code_location =config.codebase_information['code_location']

vb_path=code_location+'\\'+vb
#habdle now with case
output_json = {
    "File_Name": "",
    "Feild_Name": "",
    "Function_Name": "",
    "Rules_Statement": "",
    "Type": "",
    "Rule_Description": "",
    "Rule_ID": "",
    "Partent_Rule_ID": "",
    "Rule_Type": "",
    "Dependent_Control": ""
}

out_data=[]
metadata=[]
def Remove(duplicate):
    final_list = []
    for list_iter in duplicate:
        if list_iter not in final_list:
            final_list.append(list_iter)
    return final_list




def fetch_With(id, filename):
    sub_storage = []
    collect_flag = False
    if filename.lower().endswith(".vb"):
        filename = "\\".join(filename.split("\\")[:-1]) + "\\" + filename.split("\\")[-1].replace(".VB", "")
    with open(filename + '.vb', 'r') as vb_file:
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
    with open(filename + '.vb', 'r') as vb_file:
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
def Bussiness_Rule_Extractor(id,filename):
    local_metadata = []

    onClick_event_list=['OnClick','OnClientBlur','OnClientChange','OnClientClick','OnClientFocus','OnClientMouseOut','OnClientMouseOver','OnCommand','OnControlValidation']

    storage = fetch_sub(id,filename)

    try:
        for  event in onClick_event_list:
            for line in storage:
                if line.__contains__(event):
                    # print(line)
                    if line.split('=')[-1].strip().__contains__(";"):
                        Mulit_function_list = line.split('=')[-1].strip().replace('"','').replace("'","").split(";")
                        for function in Mulit_function_list:
                            if function.strip() =="" or function.strip()==" ":
                                continue

                            fetch_Rules(function, filename, id)




                    else:

                        fetch_Rules(line.split('=')[-1].strip().strip().replace('"','').replace("'",""), filename,id)



    except Exception as e :
        exc_type, exc_obj, exc_tb = sys.exc_info()
        fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
        print(exc_type, fname, exc_tb.tb_lineno)
        pass


def fetch_Rules(function,filename,id):

    collect_flag =False
    funtion_storage = []
    Rules_storage = []
    js_file_name = filename.replace("aspx",'js')
    # print(function)
    brace_count=0
    with open(js_file_name, 'r') as js_file:
        for line in js_file.readlines():
            if line.__contains__(function) and line.lower().__contains__("function"):
               collect_flag = True
            if collect_flag:
               funtion_storage.append(line.strip())
            if line.__contains__("{"):
               brace_count=brace_count+1
            if line.__contains__("}"):
               brace_count=brace_count-1
            if brace_count == 0 and not (line.__contains__(function)):
               collect_flag = False
        if funtion_storage !=[]:
            for line in funtion_storage:
                if line.lower().strip().startswith("if") :
                    collect_flag = True
                if collect_flag:
                    Rules_storage.append(line.strip()+'\n')
                if line.__contains__("{"):
                    brace_count = brace_count + 1
                if line.__contains__("}"):
                    brace_count = brace_count - 1
                if brace_count == 0 and not (line.lower().strip().startswith("if")):
                    collect_flag = False
                if line.__contains__("(") and line.__contains__(")") and line.__contains__(";") and not (line.__contains__(".find") or line.__contains__(".add") or  line.__contains__("CLAS")):
                    inner_function = line.replace(';',"")
                    fetch_Rules(inner_function,filename,id,)
                #need to change

        output_json["File_Name"] = filename.split("\\")[-1]
        output_json['Feild_Name'] = id
        output_json["Function_Name"] = function

        output_json["Rules_Statement"] = Rules_storage
        metadata.append(copy.deepcopy(output_json))




    return output_json



def main(filename,metadata):

      try:
        section_flag=False
        metadata=metadata
        filename=filename
        with open(filename,'r') as input_file:
            for line in input_file.readlines():

                if line.strip()=="":
                    continue

                expand_regexx=re.findall(r'^\s*<\s*.*\s*:\s*ExpandCollapsePanel\s.*',line,re.IGNORECASE)
                end_expand_regexx=re.findall(r'^\s*<\s*/\s*.*\s*:\s*ExpandCollapsePanel\s*',line,re.IGNORECASE)
                stack_regxx=re.findall(r'^\s*<\s*.*\s*:\s*StackingPanel\s.*',line,re.IGNORECASE)
                ens_stack_regexx=re.findall(r'^\s*<\s*/\s*.*\s*:\s*StackingPanel\s*',line,re.IGNORECASE)

                if (line.__contains__(" ExpandCollapsePanel ") and expand_regexx!=[]) or (line.__contains__(" StackingPanel ") and stack_regxx!=[]):
                    section_flag=True
                    continue

                if end_expand_regexx!=[] or ens_stack_regexx!=[] :
                    section_flag=False

                if section_flag:
                    control_regexx=re.findall(r'^\s*<\s*[aA-zZ].*\s*:\s*.*\s*id\s*=\s*.*',line,re.IGNORECASE)
                    if control_regexx!=[]:

                            control_name=control_regexx[0].split(":")[1].split()[0]
                            ignore_list=["StackingPanelItem","ExpandCollapsePanelItem"]
                            data_regexx = re.findall('\s*.*\s*id\s*=\s*"\s*[aA-zZ]*"', line, re.IGNORECASE)

                            if control_name in ignore_list:
                                continue

                            if data_regexx != []:

                                control_Lable_name = data_regexx[0].split("id")[1].replace('"', '').replace("=","")
                                Bussiness_Rule_Extractor(control_Lable_name,filename)

        for screen_data in metadata:
            out_data.append(screen_data)

        with open("bussiness_rules" + '.csv', 'w', newline="") as output_file:
            Fields = ["File_Name",
    "Feild_Name",
    "Function_Name",
    "Rules_Statement",
    "Type" ,
    "Rule_Description" ,
    "Rule_ID",
    "Partent_Rule_ID" ,
    "Rule_Type" ,
    "Dependent_Control" ]
            dict_writer = csv.DictWriter(output_file, fieldnames=Fields)
            dict_writer.writeheader()
            dict_writer.writerows(out_data)

        print(json.dumps(metadata,indent=4))
        if metadata!=[]:
            if db.drop_collection("Bussiness_Rules"):
                print("deleted")

            if db.Bussiness_Rules.insert_many(metadata):
                print("inserted")






      except Exception as e:
          exc_type, exc_obj, exc_tb = sys.exc_info()
          fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
          print(exc_type, fname, exc_tb.tb_lineno)

          pass

for filename in glob.glob(os.path.join(vb_path,'*.aspx')):
    metadata=[]
    main(filename,metadata)
