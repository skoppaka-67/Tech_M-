import config
from pymongo import MongoClient
import glob,os
import re
import json
import csv
import sys
import time
import copy

start_time = time.time()

Version=" Not directly updating the Control ID in code behind DB"

Version2="Phase-2 Release -2 ,Includes the classification of IF condition"

''' 
Owwner  =Mothesh ,Kiran. 
Last Modified: 
Mothesh = 23/9/2020. 
 
1.Take the rules from the Rules report , which was captured as the part of the release -1.And further traced back to
 find the child rules in relase -2.  

'''
mongoClient = MongoClient('localhost', 27017)
db = mongoClient['asp4']
vb = config.codebase_information['VB']['folder_name']
code_location =config.codebase_information['code_location']

vb_path=code_location+'\\'+vb

output_json={"section_id":"","section_name":"","CLAS_label":"","comments":"","screen_field":"","CLAS_field":"","type":"","required":"","for_control":"","maximun_length":"",
             "allowkeys":"","min-max":"","tooltip":"","enabled":"","dropdown_value":"","stored_value":"","error_message":""}
metadata=[]

# Take the unique screen field from screen field db.

screen_fields_list=db.screen_data.distinct("ScreenField")

if db.drop_collection("rule_report"):
  print("deleted")

def main(filename,metadata):


      try:
        rule=0
        section_flag=False
        section_name=""
        sec_name=""
        metadata=metadata
        filename=filename
        vb_source_list=[]
        vb_source_list=code_behind_fun(filename)


        code_behind_data = db.Code_behind_rules.find({"file_name": filename.split("\\")[-1].split('.')[0]},{'_id':0})
        code_behind_data_dup=[]


        for k in code_behind_data:

            code_behind_data_dup.append(k)
        #code_behind_data_wihtout_cid=db.Code_behind_rules.find({"$and":[{"file_name":filename.split("\\")[-1].split('.')[0],"field_name":""}]})

        for control_id in screen_fields_list:

            for data in code_behind_data_dup:

                if data["field_name"] == control_id.strip():


                    previous_case_line=""
                    nested_select_flag=False
                    main_select_counter=0
                    global  parent_rule_id
                    parent_rule_id=[]

                    condition_split_list=spliting_of_condition_statement(data)

                    for condition_data_line_1 in condition_split_list:

                        if condition_data_line_1==[]:
                            continue

                        condition_data_line = condition_data_line_1[0]


                        if condition_data_line.upper().strip().startswith("IF") or condition_data_line.upper().strip().startswith("SELECT ") or \
                                condition_data_line.upper().strip().startswith("CASE ") or condition_data_line.upper().strip().startswith("ELSEIF"):
                            rule=rule+1



                            if (previous_case_line.upper().strip().startswith("CASE ") and condition_data_line.upper().strip().startswith("CASE "))  or    \
                                        (( not previous_case_line.upper().strip().startswith("SELECT ") and condition_data_line.upper().strip().startswith("CASE ")))    :
                                parent_rule_id.pop()
                                previous_case_line=""

                            if  condition_data_line.upper().strip().startswith("CASE "):
                                previous_case_line=condition_data_line


                            if condition_data_line.upper().strip().startswith("SELECT "):
                                main_select_counter=main_select_counter+1
                                previous_case_line=condition_data_line

                            if  condition_data_line.upper().strip().startswith("ELSEIF"):
                                parent_rule_id.pop()

                            parent_rule_id.append("rule-" + str(rule))
                            data1={"function_name":data["function_name"],"field_name":data["field_name"],"rule_id": "rule-" + str(rule),"rule_statement":condition_data_line_1, "External_rule_id":"","Rule_Relation": ",".join(parent_rule_id), "rule_description": "",
                                 "rule_type": "", "file_name": filename.split('\\')[-1],"lob":"","dependent_control":"","parent_rule_id":",".join(parent_rule_id)}

                            db.rule_report.insert_one(data1)

                            global dup_data
                            dup_data = data1
                            global counter
                            counter=0
                            global rule_id_data
                            rule_id_data=data1["rule_id"]

                            for j in condition_data_line_1:
                               #if j.__contains__("End If") or j.__contains__("End Select") or (j.strip().upper().startswith("CASE ") and  main_select_counter <= 1):
                               if j.__contains__("End If") or j.__contains__("End Select"):
                                   parent_rule_id.pop()
                                   previous_case_line=""
                                   if j.__contains__("End Select") :
                                      parent_rule_id.pop()
                                      main_select_counter=main_select_counter-1

                            if not (data1["parent_rule_id"].__contains__(',') ):
                                # or data1['rule_statement'][
                                #     0].strip().upper().startswith('SELECT ')


                                back_trace_fun(
                                    data1)

                            if not (data1['rule_statement'][
                                0].strip().upper().startswith('SELECT ') or data1['rule_statement'][
                                0].strip().upper().startswith('CASE ')):
                                classification_of_if(data1)

                        else:

                            db.rule_report.insert_one(
                                {"function_name":data["function_name"],"field_name":data["field_name"],"rule_id": "","rule_statement":condition_data_line_1, "Rule_Relation": ",".join(parent_rule_id), "rule_description": "",
                                 "rule_type": "", "file_name": filename.split('\\')[-1], "lob": "",
                                 "dependent_control": "","parent_rule_id":",".join(parent_rule_id)})
                            for j in condition_data_line_1:
                                if j.__contains__("End If") or( j.__contains__("End Select")and not main_select_counter >1):
                                      if j.__contains__("End Select"):
                                          parent_rule_id.pop()
                                          main_select_counter=main_select_counter-1
                                      parent_rule_id.pop()

                    #db.rule_report.insert_one(data)
                    #classification_of_if(data) # This function further track back and find the parent rules.
                elif data["field_name"]=="":
                    # print(data)

                    for line1 in data["rule_statement"]:
                        # if line1.strip().startswith("if ") or line1.strip().startswith("If ") or \
                        #           line1.strip().startswith("if(") or line1.strip().startswith("If(") or \
                        #     line1.strip().startswith("Case ") or line1.strip().startswith("Select "):
                        #     continue
                        control_id_dup=' '+control_id+'.'
                        if control_id_dup in line1:

                            # rule=rule+1
                            # data.update(
                            #     {"field_name":control_id,"rule_id": "rule-" + str(rule), "Rule_Relation": "",
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
                                        "IF") or condition_data_line.upper().strip().startswith("SELECT ") or \
                                        condition_data_line.upper().strip().startswith("CASE ") or condition_data_line.upper().strip().startswith("ELSEIF"):
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

                                    parent_rule_id.append("rule-" + str(rule))
                                    data1 = {"function_name": data["function_name"], "field_name": control_id,
                                             "rule_id": "rule-" + str(rule), "rule_statement": condition_data_line_1,
                                             "Rule_Relation": ",".join(parent_rule_id), "rule_description": "",
                                             "rule_type": "", "file_name": filename.split('\\')[-1], "lob": "",
                                             "dependent_control": "", "parent_rule_id": ",".join(parent_rule_id)}

                                    dup_data = data1
                                    db.rule_report.insert_one(data1)

                                    counter=0

                                    for j in condition_data_line_1:
                                        # if j.__contains__("End If") or j.__contains__("End Select") or (j.strip().upper().startswith("CASE ") and  main_select_counter <= 1):
                                        if j.__contains__("End If") or j.__contains__("End Select"):
                                            parent_rule_id.pop()
                                            previous_case_line = ""
                                            if j.__contains__("End Select"):
                                                parent_rule_id.pop()
                                                main_select_counter = main_select_counter - 1

                                    if not (data1["parent_rule_id"].__contains__(',')):
                                        # or data1['rule_statement'][
                                        #     0].strip().upper().startswith('SELECT ')

                                        back_trace_fun(
                                            data1)

                                    if not (data1['rule_statement'][
                                                0].strip().upper().startswith('SELECT ') or
                                            data1['rule_statement'][
                                                0].strip().upper().startswith('CASE ')):

                                        rule_id_data=data1["rule_id"]
                                        classification_of_if(data1)


                                    #classification_of_if(data1)

                                else:

                                    db.rule_report.insert_one(
                                        {"function_name": data["function_name"], "field_name": control_id,
                                         "rule_id": "", "rule_statement": condition_data_line_1, "Rule_Relation": ",".join(parent_rule_id),
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


                            #metadata.append(data)
                            #db.rule_report.insert_one(data)
                            #classification_of_if(data)  # This function further track back and find the parent rules.
                            break


        # Writing the data from DB to Excel.

        out_data=[]
        metadata_1=db.rule_report.find({},{"parent_rule_id":0,"dependent_control":0})
        for screen_data_1 in metadata_1:
            screen_data_1.pop("_id")
            screen_data_1.update({"rule_statement":" ".join(screen_data_1["rule_statement"])})
            out_data.append(screen_data_1)


        with open("rule_report" + '.csv', 'w', newline="") as output_file:
            Fields = ["rule_id","file_name","function_name","field_name","External_rule_id","rule_statement","Rule_Relation","rule_description","rule_type","lob"]
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



# def section_name_fun(filename,section_name):
#     try:
#         section_value_flag=False
#         section_name_2=""
#         with open(filename + '.vb', 'r') as vb_file:
#             section_name_1='set'+section_name+'\s*\(\)'
#
#             for lines in vb_file.readlines():
#
#                 if lines.strip()=="":
#                     continue
#                 section_value=re.search(section_name_1,lines)
#                 section_end_sub=re.findall(r'^\s*end\s*sub\s*',lines,re.IGNORECASE)
#                 if section_value:
#                     section_value_flag=True
#                 if section_end_sub!=[]:
#                     section_value_flag=False
#                 if section_value_flag:
#                     section_name_2=re.findall(r'^\s*.*\.PrimaryTitleText\s*=\s*".*"',lines,re.IGNORECASE)
#                     if section_name_2!=[]:
#                         section_name_2=section_name_2[0].split("=")[1].replace('"','')
#                         break
#             vb_file.close()
#         if section_name_2=="":
#             with open(filename + '.vb', 'r') as vb_file:
#                 section_name_1 = '\s*With\s*'+ section_name
#                 for lines in vb_file.readlines():
#                     if lines.strip() == "":
#                         continue
#                     section_value = re.search(section_name_1, lines)
#                     section_end_sub = re.findall(r'^\s*end\s*sub\s*', lines, re.IGNORECASE)
#                     if section_value:
#                         section_value_flag = True
#                     if section_end_sub != []:
#                         section_value_flag = False
#                     if section_value_flag:
#                         section_name_2 = re.findall(r'^\s*.*\.PrimaryTitleText\s*=\s*".*"', lines,re.IGNORECASE)
#                         if section_name_2 != []:
#                             section_name_2 = section_name_2[0].split("=")[1].replace('"', '')
#                             break
#             vb_file.close()
#         if section_name_2=="":
#             with open(filename + '.vb', 'r') as vb_file:
#                 section_name_1 = '\s*'+section_name+'\.PrimaryTitleText\s*=\s*".*"'
#                 for lines in vb_file.readlines():
#                     if lines.strip() == "":
#                         continue
#                     section_value = re.search(section_name_1, lines)
#                     if section_value:
#                         section_name_2 = re.findall(r'^\s*.*\.PrimaryTitleText\s*=\s*".*"', lines,re.IGNORECASE)
#                         if section_name_2 != []:
#                             section_name_2 = section_name_2[0].split("=")[1].replace('"', '')
#                             break
#
#         vb_file.close()
#         return section_name_2
#
#     except Exception as e:
#         print(e)
#
# def label_name_fun(filename,label_name):
#     try:
#         section_value_flag = False
#         for_control_value=""
#         label_name_2=""
#         label_name_3=""
#
#         with open(filename + '.vb', 'r') as vb_file:
#             label_name_1 = 'set' + label_name + '\s*\(\)'
#             for lines in vb_file.readlines():
#                 if lines.strip()=="":
#                     continue
#                 label_value = re.search(label_name_1, lines)
#                 label_end_sub = re.findall(r'^\s*end\s*sub\s*', lines, re.IGNORECASE)
#                 if label_value:
#                     section_value_flag = True
#                 if label_end_sub != []:
#                     section_value_flag = False
#                 if section_value_flag:
#                     label_name_2 = re.findall(r'^\s*.*\.Text\s*=\s*".*"', lines,re.IGNORECASE)
#                     for_control_regexx=re.findall(r'\s*.*\.ForControl\s*=\s*.*',lines,re.IGNORECASE)
#                     if label_name_2 != []:
#                         label_name_3 = label_name_2[0].split("=")[1].replace('"', '')
#                     if for_control_regexx!=[]:
#                         for_control_value = for_control_regexx[0].split("=")[1].replace('"', '')
#             vb_file.close()
#
#
#         if label_name_3=="" and for_control_value=="":
#             with open(filename + '.vb', 'r') as vb_file:
#                 label_name_1 = '\s*With\s*' + label_name
#                 for lines in vb_file.readlines():
#                     if lines.strip() == "":
#                         continue
#                     label_value = re.search(label_name_1, lines)
#                     label_end_sub = re.findall(r'^\s*end\s*sub\s*', lines, re.IGNORECASE)
#                     if label_value:
#                         section_value_flag = True
#                     if label_end_sub != []:
#                         section_value_flag = False
#                     if section_value_flag:
#                         label_name_2 = re.findall(r'^\s*.*\.Text\s*=\s*".*"', lines,re.IGNORECASE)
#                         for_control_regexx = re.findall(r'\s*.*\.ForControl\s*=\s*.*', lines,re.IGNORECASE)
#                         if label_name_2 != []:
#                             label_name_3 = label_name_2[0].split("=")[1].replace('"', '')
#                         if for_control_regexx != []:
#                             for_control_value = for_control_regexx[0].split("=")[1].replace('"', '')
#
#                     if for_control_value !="" and label_name_3!="":
#                         break
#                 vb_file.close()
#
#         if label_name_3=="" and for_control_value=="":
#             with open(filename + '.vb', 'r') as vb_file:
#                 label_name_1 = '\s*'+ label_name+'\.ForControl\s*=\s*".*"'
#                 for_control_reg='\s*'+label_name+'\.Text\s*=\s*".*"'
#                 for lines in vb_file.readlines():
#                     if lines.strip() == "":
#                         continue
#                     label_name_2 = re.search(label_name_1, lines)
#                     for_control_reg=re.search(for_control_reg,lines)
#                     if label_name_2:
#                         label_name_2 = re.findall(r'^\s*.*\.Text\s*=\s*".*"', lines,re.IGNORECASE)
#                         if label_name_2!=[]:
#                             label_name_3 = label_name_2[0].split("=")[1].replace('"', '')
#                     if for_control_reg:
#                         for_control_regexx = re.findall(r'\s*.*\.ForControl\s*=\s*.*', lines,re.IGNORECASE)
#                         if for_control_regexx!=[]:
#                            for_control_value = for_control_regexx[0].split("=")[1].replace('"', '')
#
#                     if for_control_value !="" and label_name_3!="":
#                         break
#             vb.close()
#
#         return label_name_3,for_control_value
#
#     except Exception as e:
#         print(e)


def spliting_of_condition_statement(data):

   try:
    if_counter=0
    case_counter=0
    if_list=[]
    flag=False
    main_list=[]
    for condition_line in data['rule_statement']:

        select_flag_regexx_1 = re.findall(r'^\s*select\s*case\s*.*', condition_line, re.IGNORECASE)

        end_select_regexx_1 = re.findall(r'^\s*end\s*select\s*', condition_line, re.IGNORECASE)

        case_regexx_1 = re.findall(r'^\s*case\s*.*', condition_line, re.IGNORECASE)

        if_regexx_1 = re.findall(r'^\s*\t*IF\s.*', condition_line, re.IGNORECASE)

        if1_regexx_1 = re.findall(r'^\s*\t*IF\s*[(].*', condition_line, re.IGNORECASE)

        end_if_regexx_1 = re.findall(r'^\s*\t*END\s*IF\s*', condition_line, re.IGNORECASE)

        else_if_regexx=re.findall(r'^\s*ElseIf\s*.*',condition_line,re.IGNORECASE)

        if else_if_regexx != []:

            if if_counter > 1:
                main_list.append(if_list)
                if_list = []

            if_counter = if_counter - 1

            # if if_counter == 0:
            #     main_list.append(if_list)
            #     flag = False


        if if_regexx_1 !=[] or if1_regexx_1!=[] or select_flag_regexx_1 !=[] or case_regexx_1!=[] or else_if_regexx!=[]:

            if_counter=if_counter+1
            if if_counter>1 :
                main_list.append(if_list)
                if_list=[]
            flag=True
            if case_regexx_1!=[]:
                case_counter=case_counter+1
                if not case_counter ==1:
                  if_counter = if_counter - 1

        if flag:
            if_list.append(condition_line)

        if end_if_regexx_1 !=[] or end_select_regexx_1!=[]:

             if if_counter>1:
                 main_list.append(if_list)
                 if_list=[]

             if_counter = if_counter - 1

             if if_counter ==0:
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
    
    metadata_1=[]

    if_flag = False

    select_flag=False

    if_counter = 0

    cid_name = ""

    function_name = ""

    dup_function_name=""

    if_data_list = []
    select_data_list=[]
    dup_flag=False
    full_data_list=[]
    select_counter=0
    with open(filename+'.vb', 'r') as input_file:

        for line in input_file.readlines():

            if line.strip() == "" or line.strip().startswith("'"):
                continue

            # function_name_regexx=re.findall(r'^\s*PRIVATE\s*SUB\s*[A0-Z9]*[(][a0-z9]*[)]\s*.*',line,re.IGNORECASE)
            function_name_regexx = re.findall(r'^\s*PRIVATE\s*SUB\s*[A0-Z9_]*[(].*', line, re.IGNORECASE)

            function_name_2_regexx = re.findall(r'^\s*PROTECTED\s*SUB\s*[A0-Z9_]*[(].*', line, re.IGNORECASE)

            function_name_1_regexx=re.findall(r'^\s*\t*PUBLIC\s*SHARED\s*FUNCTION\s*[A0-Z9_]*[(].*',line,re.IGNORECASE)

            function_name_3_regexx=re.findall(r'^\s*\t*PUBLIC\s*SUB\s*[A0-Z9_]*[(].*',line,re.IGNORECASE)

            end_sub = re.findall(r'^\s*end\s*sub\s*', line, re.IGNORECASE)

            select_flag_regexx =re.findall(r'^\s*select\s*case\s*.*',line,re.IGNORECASE )

            end_select_regexx=re.findall(r'^\s*end\s*select\s*',line,re.IGNORECASE)

            case_regexx=re.findall(r'^\s*case\s*.*',line,re.IGNORECASE)

            end_function=re.findall(r'^\s*end\s*function',line,re.IGNORECASE)

            if_regexx = re.findall(r'^\s*\t*IF\s.*', line, re.IGNORECASE)

            if1_regexx = re.findall(r'^\s*\t*IF\s*[(].*', line, re.IGNORECASE)

            end_if_regexx = re.findall(r'^\s*\t*END\s*IF\s*', line, re.IGNORECASE)

            with_regexx = re.findall(r'^\s*With\s*.*', line, re.IGNORECASE)

            end_with_regexx=re.findall(r'^\s*\t*end\s*with\s*',line,re.IGNORECASE)


            if function_name_regexx != [] or function_name_3_regexx !=[] or function_name_2_regexx !=[]:

                if function_name_3_regexx!=[]:
                    fun_value=function_name_3_regexx
                elif  function_name_regexx!=[]:
                    fun_value = function_name_regexx
                elif  function_name_2_regexx!=[]:
                    fun_value = function_name_2_regexx

                function_name = fun_value[0].strip().split(' ')[2].split('(')[0]
                cid_name = ""
                if_data_list = []
                dup_flag=True

            if function_name_1_regexx!=[]:
                function_name = function_name_1_regexx[0].strip().split(' ')[3].split('(')[0]
                cid_name = ""
                if_data_list = []
                dup_flag = True

            if dup_flag:
                  full_data_list.append(line.replace("\t",""))

            if end_sub!=[] or end_function!=[]:
                No_of_Parameters, param_list = fetch_parametres_count(full_data_list,function_name)
                # print(No_of_Parameters,param_list)
                metadata_1.append({"file_name":filename.split('\\')[-1].split('.')[0],"function_name": function_name, "No of Parameters":No_of_Parameters,"Param_list":param_list,"source_statement": full_data_list})
                dup_flag = False
                full_data_list=[]

            if with_regexx != []:
                cid_name = with_regexx[0].strip().split(' ')[1]
                # if cid_name.strip()=="stateinput":
                #     cid_name=""
            if end_with_regexx!=[]:
                cid_name=""
                #if_counter=0

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

            if select_flag_regexx!=[] and if_data_list == []:
                select_flag=True
                select_counter=select_counter+1

            if select_flag:
                if not line.strip() == "":
                    select_data_list.append(line.replace("\t", ""))

            if end_select_regexx !=[] and select_data_list!=[]:

                select_counter=select_counter-1

                if select_counter==0:
                    metadata.append(
                        {"function_name": function_name, "field_name": cid_name, "rule_statement": select_data_list,
                         "file_name": filename.split('\\')[-1].split('.')[0]})
                    select_data_list = []
                    select_flag=False


            if (if1_regexx != [] or if_regexx != [])  and select_data_list == []:
                if_counter = if_counter + 1
                if_flag = True

            if if_flag :

                if not line.strip() == "":
                    if_data_list.append(line.replace("\t",""))

            if end_if_regexx != [] and if_data_list !=[]:

                if_counter = if_counter - 1 #Counter is introduced to capture the nested IF conditions.

                if if_counter == 0:    # At the end of condition , appedning the captured data to global list named as metadata.
                    if_flag = False

                    metadata.append(
                          {"function_name": function_name, "field_name": cid_name, "rule_statement": if_data_list,"file_name":filename.split('\\')[-1].split('.')[0]})
                    if_data_list = []

    if metadata_1!=[]:
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
       print(exc_type, fname, exc_tb.tb_lineno,e)
       print(No_of_Parameters,param_list)

       pass


def classification_of_if(data):
  # print(data)


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
   if_statement_string=""
   if_statement_list=[]
   # global counter
   # counter=0

   # if not (data["parent_rule_id"].__contains__(',') or data['rule_statement'][0].strip().upper().startswith('SELECT ')):
   #     back_trace_fun(
   #         data)  # This function is used to trace back and find rules for all the if condition using their function name.

   # Making multi line if statement to single line IF.

   for line_2 in data["rule_statement"]:
       if (line_2.strip().startswith("If ") or line_2.strip().startswith("If(")) and line_2.strip().endswith(' Then'):
           if_statement_string=line_2.strip()
           break
       elif (line_2.strip().startswith("If ") or line_2.strip().startswith("If(")) and not line_2.strip().endswith(' Then'):
           if_statement_list.append(line_2.strip())
           if_line_flag=True
       elif if_line_flag:
           if_statement_list.append(line_2.strip())
           if line_2.strip().endswith(" Then"):
               if_statement_string=" ".join(if_statement_list)
               if_line_flag=False
               break


   # Segregation of IF.

   if  if_statement_string.__contains__(" OrElse ") or   if_statement_string.__contains__(" AndAlso ") or   if_statement_string.__contains__(" or ")   \
       or  if_statement_string.__contains__(" and "):

      if_statement=if_statement_string.replace('If ','').replace(' Then','') # Delete the IF and Then statement in the if condition.

      if if_statement.strip().startswith('(') and if_statement.strip().endswith(')'):
          if_statement=if_statement[1:len(if_statement)-2]

      # If a single IF statement has multiple condition, we are spliting that using  'orelse,andalso,and,or' keywords.

      if_statement_1=if_statement.split(' OrElse ')
      if_statement_2_list=[]
      if_statement_3_list=[]
      if_statement_4_list = []
      for k in if_statement_1:
          if_statement_2=k.split(' AndAlso ')
          if len(if_statement_2) ==1:
             if_statement_2_list.append(if_statement_2[0])
          elif len(if_statement_2)>1:
              for l in if_statement_2:
                  if_statement_2_list.append(l)


      for k in if_statement_2_list:
          if_statement_3=k.split(' and ')
          if len(if_statement_3) ==1:
             if_statement_3_list.append(if_statement_3[0])
          elif len(if_statement_3)>1:
              for l in if_statement_3:
                  if_statement_3_list.append(l)


      for k in if_statement_3_list:
          if_statement_4 = k.split(' or ')
          if len(if_statement_4) == 1:
              if_statement_4_list.append(if_statement_4[0])
          elif len(if_statement_4) > 1:
              for l in if_statement_4:
                  if_statement_4_list.append(l)


      for statement in if_statement_4_list:

          if statement.strip().startswith('(String'):
              statement=statement[1:]
              if statement.strip().endswith(')))'):
                  statement=statement[0:-2]
              elif statement.strip().endswith('))'):
                  statement = statement[0:-1]
          elif statement.strip().startswith('String'):
              if statement.strip().endswith(')))'):
                  statement=statement[0:-2]
              elif statement.strip().endswith('))'):
                  statement = statement[0:-1]
          elif statement.strip().startswith('(') and not statement.strip().startswith('(String'):
              statement = statement[1:]
              if statement.strip().endswith(')'):
                  statement=statement[0:-1]
          statement='If '+ statement+' Then '
          if_function(statement, data)

   else:

      # if a condition statement has only one condition.

      if_statement_7 = if_statement_string.replace('If ', '').replace(' Then', '')

      if if_statement_7.strip().startswith('(') and if_statement_7.strip().endswith(')'):

          if_statement_6='If '+if_statement_7[1:-1]+' Then'

      else:
          if_statement_6=if_statement_string

      if_function(if_statement_6,data)
       
  except Exception as e:
      exc_type, exc_obj, exc_tb = sys.exc_info()
      fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
      print(exc_type, fname, exc_tb.tb_lineno)
      pass


def if_function(if_statement_string,json_data):
  # print(if_statement_string,"testtttttt")
  try:
   '''
    :param if_statement_string: Only condition lines.`
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

   if_value=if_statement_string.replace('If ','').replace(' Then','')


   if if_value.strip().__contains__(" HashSet") and  if_value.strip().__contains__("Contains"):
       db.rule_report.update_one({"_id": dup_data["_id"]}, {"$set": {"rule_type": "direct_rule"}})

   elif if_value.strip().startswith('String.')or if_value.__contains__(' String.'):

       if if_value.__contains__(','):
           if_value_1=if_value.split(',')[1].strip()
           if if_value_1.startswith('"') or if_value_1.startswith("'"):
               db.rule_report.update_one({"_id": dup_data["_id"]}, {"$set": {"rule_type": "direct_rule"}})
               pass

           else:
               # variable function has to be called.
               db.rule_report.update_one({"_id": dup_data["_id"]},
                                         {"$set": {"rule_type": "variable_type_rule"}})
               variable_if_fun(if_value.split(',')[1].split('.')[0])# sending only the variable
               None

       else:  # for Right hand side check ,we are leaving this if conditon by considering as direct.

           None
           # Direct
           db.rule_report.update_one({"_id": dup_data["_id"]}, {"$set": {"rule_type": "direct_rule"}})


   elif if_value.__contains__('=') or if_value.__contains__('>') or if_value.__contains__('<'):

        boolean_list=["TRUE","FALSE",'"Y"','"N"']
        number_list=["0","1","2","3","4","5","6","7","8","9"]
        if if_value.__contains__('='):
            if_value_2=if_value.split('=')[1].replace('>','').replace('<','')
        elif  if_value.__contains__('>'):

            if_value_2=if_value.split('>')[1].replace('<','').replace('=','')
        elif  if_value.__contains__('<'):
            if_value_2=if_value.split('>')[1].replace('>','').replace('=','')


        if if_value_2.strip().upper()in boolean_list or if_value_2.strip().startswith('"') or \
                any( if_value_2.strip()[0] in s for s in number_list):


            db.rule_report.update_one({"_id": dup_data["_id"]}, {"$set": {"rule_type": "direct_rule"}})
            #Direct if pattern need not to capture anything.

        else:
            # Need to call or check for variable pattern IF.



            if if_value_2.split('.')[0].__contains__('('):
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
       # print("test",if_statement_string)
       single_if_statement=if_statement_string.replace('If ','').replace(' Then','').strip()

       if single_if_statement.__contains__('.'):
           if single_if_statement.split('.')[0].__contains__('(') and single_if_statement.split('.')[0].__contains__(')'):

               db.rule_report.update_one({"_id": dup_data["_id"]},
                                         {"$set": {"rule_type": "variable_type_rule"}})
               variable_if_fun(single_if_statement.split('.')[0].strip())
           elif single_if_statement.split('.')[1].__contains__('(') and single_if_statement.split('.')[1].__contains__(')'):

               db.rule_report.update_one({"_id": dup_data["_id"]},
                                         {"$set": {"rule_type": "variable_type_rule"}})
               variable_if_fun(single_if_statement.split('.')[1].strip())

           else:
               db.rule_report.update_one({"_id": dup_data["_id"]},
                                         {"$set": {"rule_type": "direct_type_rule"}})
               print("checked pattern")
       else:
           db.rule_report.update_one({"_id": dup_data["_id"]},
                                     {"$set": {"rule_type": "variable_type_rule"}})
           variable_if_fun(single_if_statement.split('.')[0].strip())

  except Exception as e:
      exc_type, exc_obj, exc_tb = sys.exc_info()
      fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
      print(exc_type, fname, exc_tb.tb_lineno)
      pass

# def variable_if_fun(if_statement_string):# checking it is variable or function.
#
#     '''
#
#     :param if_statement_string: condition line.
#     :return: Required output
#     1.The input of this fucntion will falls under only variable or function pattern.
#     2.check whether the condition line contains any open and close brackets, if it has then take the name before the
#     bracket.And search that string has any variable assignment or not.IF it has variable assigned ,then capture that line and
#     additionally check whether the assignment line is present in the condition or not .
#     3.If it is inside the condition ,then capture that rule also and insert into collection in a new row.
#     4.If it does not have the assignment line,then consider it as fucntion call.
#     5.If the line does not have any brackets , then consider it as variable pattern and do the same process and capture
#     rules.
#     '''
#
#     variable_flag=False
#     if_line_flag=False
#     inside_if_flag=False
#     if_counter=0
#     lines_flag=False
#     update_flag=False
#     if if_statement_string.__contains__('(') and if_statement_string.__contains__(')'):# checking for function.
#
#         #if_statement_string_1=if_statement_string.split('(')[0]
#
#         name_val_var = if_statement_string.split("(")[0]
#
#         if name_val_var.__contains__('.'):
#             name_val_var=name_val_var.split('.')[1]
#
#         if_statement_list=[]
#         inside_if_list=[]
#         variable_set_lines=[]
#         with open(filename + '.vb', 'r') as vb_file:
#             for lines in vb_file.readlines():
#                 if lines.strip().startswith("'"):
#                     continue
#
#                 end_if_regexx = re.findall(r'^\s*\t*END\s*IF\s*', lines, re.IGNORECASE)
#
#                 if (lines.strip().startswith("If ") or lines.strip().startswith("If(")) and lines.strip().endswith(' Then'):
#                     lines=lines.strip()
#
#                 elif (lines.strip().startswith("If ") or lines.strip().startswith("If(")) and not lines.strip().endswith(' Then'):
#                     if_statement_list.append(lines.strip())
#                     if_line_flag=True
#                     continue
#                 elif if_line_flag:
#                     if_statement_list.append(lines.strip())
#                     if lines.strip().endswith(" Then"):
#                         lines=" ".join(if_statement_list)
#                         if_statement_list=[]
#                         if_line_flag=False
#                     else:
#                         continue
#
#                 if lines.upper().startswith('IF ') or  lines.upper().strip().startswith("IF("):
#
#                     inside_if_flag=True
#                     inside_if_list.append(lines+'\n')
#                     if_counter=if_counter+1
#                     continue # skipping the condition line.
#
#                 if inside_if_flag:
#                     inside_if_list.append(lines+'\n')
#
#                 if lines.split("=")[0].strip().__contains__(name_val_var.strip()) and lines.__contains__("="):
#                     variable_set_lines.append(lines)
#                     variable_flag=True
#                     if inside_if_flag:
#                         lines_flag=True
#                 if end_if_regexx!=[]:
#                      if_counter=if_counter-1
#                      if if_counter==0:
#                         if lines_flag:
#                             db.rule_report.insert_one(
#                                 {
#                             "function_name": "",
#                             "field_name": ""
#                             #, "rule_statement": "\n".join(inside_if_list),
#                             , "rule_statement": inside_if_list,
#                             "file_name": dup_data["file_name"],
#                             "rule_id": "",
#                             "parent_rule_id": dup_data["rule_id"],
#                             "rule_description": "",
#                             "rule_type": "server_side",
#                             "lob": dup_data["lob"],
#                             "dependent_control": dup_data["field_name"]})
#                             lines_flag=False
#                         inside_if_list=[]
#                         inside_if_flag=False
#
#         vb_file.close()
#
#         if not variable_flag:# If not true , then it is a function.
#             print("call function")
#             #print(if_statement_string)
#
#
#     else:#single varaible
#
#       name_val_var = if_statement_string
#
#       if_statement_list = []
#       inside_if_list = []
#       with open(filename + '.vb', 'r') as vb_file:
#           if_statement_list=[]
#           for lines in vb_file.readlines():
#               end_if_regexx = re.findall(r'^\s*\t*END\s*IF\s*', lines, re.IGNORECASE)
#               if lines.strip().startswith("'"):
#                   continue
#
#               if (lines.strip().startswith("If ") or lines.strip().startswith("If(")) and lines.strip().endswith(' Then'):
#                   lines=lines.strip()
#
#               elif (lines.strip().startswith("If ") or lines.strip().startswith("If(")) and not lines.strip().endswith(' Then'):
#                   if_statement_list.append(lines.strip())
#                   if_line_flag=True
#                   continue
#               elif if_line_flag:
#                   if_statement_list.append(lines.strip())
#                   if lines.strip().endswith(" Then"):
#                       lines=" ".join(if_statement_list)
#                       if_statement_list=[]
#                       if_line_flag=False
#                   else:
#                       continue
#
#               if lines.upper().startswith('IF ') or lines.upper().strip().startswith("IF("):
#                   inside_if_flag = True
#                   inside_if_list.append(lines+'\n')
#                   if_counter = if_counter + 1
#                   continue  # skipping the condition line.
#
#               if inside_if_flag:
#                   inside_if_list.append(lines+'\n')
#
#               if lines.split("=")[0].strip().__contains__(name_val_var.strip()) and lines.__contains__("="):
#
#                   variable_flag = True
#                   if inside_if_flag:
#                       lines_flag = True
#                   None
#
#               if end_if_regexx != []:
#                   if_counter = if_counter - 1
#                   if if_counter == 0:
#                       if lines_flag:
#
#                           #db.rule_report.insert_one({"dependent_control" :dup_data["field_name"],"parent_rule_id":dup_data["rule_id"],"rule_statement":"<br>".join(inside_if_list)})
#
#                           db.rule_report.insert_one(
#                               {
#                                   "function_name": "",
#                                   "field_name": ""
#                                   , "rule_statement": inside_if_list,
#                                   "file_name": dup_data["file_name"],
#                                   "rule_id": "",
#                                   "parent_rule_id": dup_data["rule_id"],
#                                   "rule_description": "",
#                                   "rule_type": "server_side",
#                                   "lob": dup_data["lob"],
#                                   "dependent_control": dup_data["field_name"]})
#
#                           lines_flag = False
#                       inside_if_list = []
#                       inside_if_flag = False
#           vb_file.close()
#           if not variable_flag:  # If not true , then it is a function( as per logic this if should be skipped,vijay has to confirm).
#               None

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

        flag_value=False
        if if_statement_string.__contains__('(') and if_statement_string.__contains__(')'):  # checking for function.

                name_val_var = if_statement_string.split("(")[0]
                if name_val_var.__contains__('.'):
                    name_val_var=name_val_var.split('.')[1]
                variable_flag=False
                with open(filename + '.vb', 'r') as vb_file:
                    for lines in vb_file.readlines():
                        if lines.strip().startswith("'"):
                          continue
                        if lines.split("=")[0].strip().__contains__(name_val_var.strip()) and lines.__contains__("="):
                            variable_flag=True
                            break
                vb_file.close()
                if variable_flag:
                    flag_value=same_func(if_statement_string)

                    if not flag_value:
                        recursive_function(if_statement_string, dup_data["function_name"])
                else:
                    None

                    Function_processer(dup_data)
                    #Call fucntion
        else:
            flag_value=same_func(if_statement_string)

            if not flag_value:
                 recursive_function(if_statement_string,dup_data["function_name"])


def same_func(if_statement_string):
  try:
    inside_flag=False
    recursive_flag=False
    name_val_var = if_statement_string.split("(")[0]
    if name_val_var.__contains__('.'):
      name_val_var = name_val_var.split('.')[1]
    if_cursor = db.Code_behind_rules_1.find_one(
        {"$and": [{"file_name": dup_data["file_name"].split('.')[0]}, {"function_name": dup_data["function_name"]}]})

    if_cursor_1 = db.Code_behind_rules.find_one(
        {"$and": [{"file_name": dup_data["file_name"].split('.')[0]}, {"function_name": dup_data["function_name"]}]})

    if if_cursor_1!=[]:
        for data_2 in if_cursor_1["rule_statement"]:
            if data_2.split("=")[0].strip().__contains__(name_val_var.strip()) and data_2.__contains__(
                    "=") and not data_2.strip().startswith('If '):
               inside_flag=True
               recursive_flag = True
               global counter
               counter = counter + 1
               db.rule_report.insert_one(
                   {
                       "function_name": dup_data["function_name"],
                       "field_name": dup_data["field_name"]
                       , "rule_statement": if_cursor_1['rule_statement'],
                       "file_name": dup_data["file_name"],
                       "rule_id": dup_data["rule_id"] + '.' + str(counter),
                       "Rule_Relation": dup_data["rule_id"],
                       "rule_description": "",
                       "rule_type": "",
                       "lob": dup_data["lob"],
                       "parent_rule_id":"",
                       "dependent_control": ""})

               break


    if not inside_flag:
        for data_1 in if_cursor["source_statement"]:
            if data_1.split("=")[0].strip().__contains__(name_val_var.strip()) and data_1.__contains__("=") and not data_1.strip().startswith('If '):
                dup_data_rule = dup_data["rule_statement"]
                dup_data_rule.insert(0,  dup_data["function_name"]+'():'+data_1)
                db.rule_report.update_one({"_id": dup_data["_id"]}, {"$set": {"rule_statement": dup_data_rule}})
                recursive_flag = True

    return recursive_flag


  except Exception as e:
      exc_type, exc_obj, exc_tb = sys.exc_info()
      fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
      print(exc_type, fname, exc_tb.tb_lineno)
      pass


def recursive_function(if_statement_string,fun_name):

  try:

    fun_var='^\s*\t*PRIVATE\s*SUB\s*[A0-Z9_].*\s*[(].*[)]*'
    fun_var_1='^\s*\t*PUBLIC\s*SHARED\s*FUNCTION\s*[A0-Z9_]\s*.*[(].*[)]*'
    fun_name_regexx='^\s*\t*'+fun_name+'\s*[(].*[)]*'
    lines_flag = False
    assign_data_flag = False
    assignment_line=""
    with open(filename + '.vb', 'r') as vb_file:
        for lines in reversed(vb_file.readlines()):
            if lines.strip().startswith("'"):
                continue

            function_name_regexx = re.search(fun_var,lines, re.IGNORECASE)

            function_name_1_regexx = re.search(fun_var_1, lines,
                                                re.IGNORECASE)

            function_call_regexx=re.search(fun_name_regexx,lines,re.IGNORECASE)

            if function_call_regexx!=None:

                lines_flag=True

            if lines_flag:
                lines_variable=lines.split("=")[0].strip()+' '
                if lines_variable.__contains__(if_statement_string.split('(')[0].strip()+' ') and lines.__contains__("="):

                    assignment_line=lines
                    assign_data_flag=True
                else:
                    fun_regexx = re.findall(r'^\s*PRIVATE\s*SUB\s*[A0-Z9_]*[(].*[)]', lines, re.IGNORECASE)

                    fun_regexx_1 = re.findall(r'^\s*\t*PUBLIC\s*SHARED\s*FUNCTION\s*[A0-Z9_]*[(].*', lines,
                                                          re.IGNORECASE)

                    if fun_regexx!=[] or  fun_regexx_1 !=[]:

                        if fun_regexx != []:
                            fun_value_1 = lines.split()[2].split('(')[0].strip()

                        elif fun_regexx_1 != []:
                            fun_value_1 = lines.split()[3].split('(')[0].strip()

                        if assign_data_flag or fun_value_1.upper() == 'SETUPPAGEPRESENTATION':
                            if_cursor=db.Code_behind_rules.find({"$and":[{"file_name":dup_data["file_name"].split('.')[0]},{"function_name":fun_value_1.strip()}]})
                            rule_flag=False
                            rule_data=""
                            for db_data in if_cursor:
                               for rule_line in db_data['rule_statement']:
                                   rule_variable = rule_line.split("=")[0].strip()+' '
                                   if rule_variable.__contains__(
                                       if_statement_string.split('(')[0].strip()+' ') and rule_line.__contains__("="):
                                            rule_flag=True
                                            rule_data=db_data
                                            global counter
                                            counter=counter+1
                                            db.rule_report.update_one({"_id": dup_data["_id"]},
                                                                      {"$set": {"rule_type": "variable_type_rule"}})


                                            db.rule_report.insert_one(
                                                                            {
                                                                        "function_name": fun_value_1,
                                                                        "field_name": dup_data["field_name"]
                                                                        , "rule_statement": db_data['rule_statement'],
                                                                        "file_name": dup_data["file_name"],
                                                                        #"rule_id": dup_data["rule_id"]+'.'+str(counter),
                                                                        "rule_id":rule_id_data+'.'+str(counter),
                                                                        "Rule_Relation": rule_id_data,
                                                                        "rule_description": "",
                                                                        "rule_type": "variable_type_rule",
                                                                        "lob": dup_data["lob"],
                                                                        "dependent_control": "",
                                                                        "parent_rule_id":""})

                                            break


                            if not rule_flag:
                                   # from here check for page_load and update the value
                                   if assignment_line=="":
                                       inside_flag=False
                                       assignmanet_flag=False
                                       if_cursor = db.Code_behind_rules_1.find({"$and": [
                                           {"file_name": dup_data["file_name"].split('.')[0]},
                                           {"function_name":"Page_Load"} ]})
                                       for db_data in if_cursor:
                                           for rule_line in db_data['source_statement']:
                                               rule_variable = rule_line.split("=")[0].strip() + ' '
                                               if rule_variable.__contains__(
                                                       if_statement_string.split('(')[
                                                           0].strip() + ' ') and rule_line.__contains__("="):

                                                       assignmanet_flag=True
                                                       assignment_line_1=rule_line
                                                       if_cursor1 = db.Code_behind_rules.find({"$and": [
                                                           {"file_name": dup_data["file_name"].split('.')[0]},
                                                           {"function_name": "Page_Load"}]})
                                                       for db_data in if_cursor1:
                                                           for rule_line in db_data['rule_statement']:
                                                               rule_variable = rule_line.split("=")[0].strip() + ' '
                                                               if rule_variable.__contains__(
                                                                       if_statement_string.split('(')[
                                                                           0].strip() + ' ') and rule_line.__contains__(
                                                                   "="):
                                                                   inside_flag=True

                                                                   counter = counter + 1
                                                                   db.rule_report.update_one({"_id": dup_data["_id"]},
                                                                                             {"$set": {
                                                                                                 "rule_type": "variable_type_rule"}})
                                                                   db.rule_report.insert_one(
                                                                                           {
                                                                       "function_name": "Page_Load",
                                                                       "field_name": dup_data["field_name"]
                                                                       , "rule_statement": db_data['rule_statement'],
                                                                       "file_name": dup_data["file_name"],
                                                                       "rule_id": dup_data["rule_id"]+'.'+str(counter),
                                                                       "Rule_Relation": dup_data["rule_id"],
                                                                       "rule_description": "",
                                                                       "rule_type": "variable_type_rule",
                                                                       "lob": dup_data["lob"],
                                                                       "parent_rule_id": "",
                                                                       "dependent_control": ""
                                                                                           })
                                                                   break
                                       if assignmanet_flag and not inside_flag:

                                           dup_data_rule=dup_data["rule_statement"]
                                           dup_data_rule.insert(0,"Page_Load():"+assignment_line_1)
                                           db.rule_report.update_one({"_id":dup_data["_id"]},{"$set":[{"rule_statement":dup_data_rule},{"rule_type": "variable_type_rule"}]})

                                   else:

                                       dup_data_rule = dup_data["rule_statement"]
                                       dup_data_rule.insert(0, fun_value_1.strip()+'():'+assignment_line)
                                       db.rule_report.update_one({"_id": dup_data["_id"]},
                                                                 {"$set": {"rule_statement": dup_data_rule,
                                                                           "rule_type":"variable_type_rule"}})

                            break





            if (function_name_regexx!=None or function_name_1_regexx!=None) and lines_flag :
                lines_flag = False

                function_name_regexx_1 = re.findall(r'^\s*PRIVATE\s*SUB\s*[A0-Z9_]*[(].*[)]', lines, re.IGNORECASE)

                function_name_1_regexx_2 = re.findall(r'^\s*\t*PUBLIC\s*SHARED\s*FUNCTION\s*[A0-Z9_]*[(].*', lines,
                                                    re.IGNORECASE)

                if function_name_regexx_1!=[]:

                    fun_value = lines.split()[2].split('(')[0].strip()

                elif function_name_1_regexx_2!=[]:
                    fun_value= lines.split()[3].split('(')[0].strip()

                vb_file.close()

                recursive_function(if_statement_string,fun_value)


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


    dup1_data=data

    function_flag=False


    function_name=data["function_name"]+'\s*[(].*'


    full_function_data=db.Code_behind_rules_1.find({"file_name":data["file_name"].split('.')[0]})

    rules_lines=db.Code_behind_rules.find({"file_name":data["file_name"].split('.')[0]})

    #Trace Backing the function name using recursive function.


    for lines in full_function_data:

        for in_line in lines["source_statement"]:

          if (in_line.strip().startswith("Private ") and in_line.__contains__(" Sub ")) or (in_line.strip().startswith("Public ") and in_line.__contains__(" Shared ") and
              in_line.__contains__(" Function ")) or in_line.strip().upper().startswith("IF") or in_line.strip().upper().startswith("CASE ") or \
              in_line.strip().startswith("SELECT "):

              continue

          function_name_regexx = re.findall(function_name,in_line,re.IGNORECASE)

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

          if function_name_regexx!=[]:


              # checking if this function is called within any rules or not.

              for rec_data in rules_lines:
                  for k in rec_data["rule_statement"]:
                      if (k.strip().startswith("Private ") and k.__contains__(" Sub ")) or (
                              k.strip().startswith("Public ") and k.__contains__(" Shared ") and
                              k.__contains__(" Function ")) or k.strip().upper().startswith(
                          "IF") or k.strip().upper().startswith("CASE ") or \
                              k.strip().startswith("SELECT "):
                          continue
                      function_name_regexx_1 = re.findall(function_name, k, re.IGNORECASE)
                      if function_name_regexx_1!=[]:
                          global counter
                          counter=counter+1
                          function_flag=True

                          db.rule_report.insert_one({"function_name":rec_data["function_name"],
                                                     "field_name" :dup_data["field_name"]
                                                     ,"rule_statement":rec_data["rule_statement"],
                                                     "file_name" :dup_data["file_name"],
                                                     "rule_id":dup_data["rule_id"]+'.'+str(counter) ,
                                                     "Rule_Relation":dup_data["rule_id"],
                                                     "rule_description": "",
                                                     "rule_type": "Function_Invocation_Rule",
                                                     "lob": dup_data["lob"],
                                                     "dependent_control": ""
                                                     })

              if not function_flag:

                          db.rule_report.insert_one({"function_name": "",
                                                     "field_name": dup_data["field_name"],
                                                     "rule_statement": [data["function_name"]+'()'],
                                                     "file_name": dup_data["file_name"],
                                                     "rule_id": "",
                                                     "Rule_Relation": dup_data["rule_id"],
                                                     "rule_description": "",
                                                     "rule_type": "",
                                                     "lob": dup_data["lob"],
                                                     "dependent_control": ""
                                                     })

              # calling the same function until setup page presentation.

              if  lines["function_name"].upper() =="SETUPPAGEPRESENTATION" or lines["function_name"].upper()=="SAVEPAGEDATA":

                 break

              back_trace_fun(lines)

  except Exception as e:
      exc_type, exc_obj, exc_tb = sys.exc_info()
      fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
      print(exc_type, fname, exc_tb.tb_lineno)


# Kiran functions

function_list = tuple(db.Code_behind_rules_1.distinct("function_name"))
Rule_Buffer =[]


# def Function_processer(dup_data):
#     try:
#
#         ref_var_list = fetchimport_var(dup_data['file_name'])
#         ref_file_name_list = fetch_vbfilename(dup_data['lob'])
#         for line in dup_data['rule_statement']:
#
#             matches = [x for x in function_list if x in line]
#             if matches !=[]:
#                 print(matches)
#                 cursor = db.Code_behind_rules_1.find_one({"function_name": "".join(matches)}, {'_id': 0})
#                 for line in cursor['source_statement']:
#                     Rule_Buffer.append(line)
#                 rule_extractor("".join(matches))
#
#             else:
#                 for line in dup_data['rule_statement']:
#                     matches1 = [x for x in ref_var_list if x in line]
#                     if matches1 != []:
#                         calling_function_name = line.split(matches1[0])[1].split('(')[0].replace(".", "")
#                         for line1 in dup_data['rule_statement']:
#                             Rule_Buffer.append(line1)
#                         rule_extractor(calling_function_name)
#
#
#
#     except Exception as e:
#         exc_type, exc_obj, exc_tb = sys.exc_info()
#         fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
#         print(exc_type, fname, exc_tb.tb_lineno)

def state_scan_values(function_name=None,linelist=None):
    brace_counter= 0
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
        if line1.__contains__(State+" =") :
            State = line1.split("=")[-1].strip()


    return Lob_code, State, Rule


def Function_processer(dup_data):
    object_fun = False
    global counter
    # external_fun_set = set()
    parentruleid_list = []

    external_fun_cur = db.master_rules.distinct("function_name", (
    {"Function_Type": "PS", "file_name": dup_data["file_name"].split(".")[0]}))

    # for i in external_fun_cur:
    #     external_fun_set.add(i)
    external_fun_set = [ x for x in external_fun_cur]
    try:


        output_json_value = {}
        # Lob_code, State, Rule = state_scan_values(dup_data['function_name'],None)

        ref_var_list = fetchimport_var(dup_data['file_name'])
        ref_file_name_list = fetch_vbfilename(dup_data['lob'])
        for line in dup_data['rule_statement']:

            if line.lower().__contains__("statescan."):

                Lob_code, State, Rule = state_scan_values(None, dup_data['rule_statement'])
                state_scan_line = "Lob_Code : " + Lob_code + "State : " + State + "Rule :" + Rule
                dup_data['rule_statement'].insert(0, state_scan_line)
                new_list = copy.deepcopy(dup_data['rule_statement'])
                db.rule_report.update_one({"_id": dup_data["_id"]},
                                          {"$set": {
                                              "rule_statement": new_list}})
                break
        for line in dup_data['rule_statement']:


            matches = [x for x in function_list if x in line ]


            if matches != []:

                for match in matches:

                    calling_function_name = match
                    # calling_params_count =  calling_fun_parms_count(line,match)

                    No_of_perams,param_list = fetch_parametres_count(dup_data['rule_statement'], calling_function_name)
                    db.rule_report.update_one({"_id": dup_data["_id"]},
                                              {"$set": {"rule_type": "function_type_rule"}})

                    """Update json with no of parameters                     
                     
                     """




                    print(line )

                    cursor = db.Code_behind_rules_1.find_one({"function_name": "".join(matches)}, {'_id': 0})
                    for line in cursor['source_statement']:
                        Rule_Buffer.append(line)
                    rule_extractor("".join(matches))

            matches1 = [x for x in ref_var_list if x in line]
            if matches1 != []:

                for match in matches1:
                    counter = counter + 1
                    object_fun = True
                    calling_function_name = match
                    No_of_perams,param_list = fetch_parametres_count(dup_data['rule_statement'], calling_function_name)
                    cursor1 = db.master_rules.find({"function_name": calling_function_name,"No of Parameters":No_of_perams}, {'_id': 0})

                    for i in cursor1:
                        parentruleid_list.append(i['rule_id'])
                        # print(calling_function_name)
                    dup_data["External_rule_id"] = ",".join(parentruleid_list)
                    db.rule_report.update_one({"_id": dup_data["_id"]},
                                              {"$set": {"rule_type": "function_type_rule"}})

                    db.rule_report.update_one({"_id": dup_data["_id"]},
                                              {"$set": {"External_rule_id": ",".join(parentruleid_list)}})

                    """filename.function name handling """
            matches2 = [x for x in ref_file_name_list if x in line]
            if matches2 != [] :
                for match in matches2:
                    # print("filen", line)
                    object_fun = True
                    counter = counter + 1
                    calling_function_name = match
                    No_of_perams,param_list = fetch_parametres_count(dup_data['rule_statement'], calling_function_name)
                    cursor1 = db.master_rules.find({"function_name": calling_function_name,"No of Parameters":No_of_perams}, {'_id': 0})

                    for i in cursor1:
                        parentruleid_list.append(i['rule_id'])
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

                        No_of_perams,param_list = fetch_parametres_count(dup_data['rule_statement'],calling_function_name)
                        """inculde noparams var as constrain """
                        cursor1 = db.master_rules.find({"function_name": calling_function_name,"Function_Type":"PS","No of Parameters":No_of_perams}, {'_id': 0})

                        for i in cursor1:
                            # print(i["No of Parameters"])

                            parentruleid_list.append(i['rule_id'])

                        # output_json_value["lob"] = dup_data["lob"]
                        # output_json_value["file_name"] = dup_data["file_name"]
                        # output_json_value["function_name"] = calling_function_name
                        # output_json_value["field_name"] = dup_data["field_name"]
                        # output_json_value["rule_statement"] = i["rule_statement"]
                        # output_json_value["rule_description"] = dup_data["rule_description"]
                        # output_json_value["Rule_Relation"] = i["parent_rule_id"]
                        # output_json_value["rule_id"] = i["rule_id"]
                        # output_json_value["dependent_control"] = dup_data["dependent_control"]
                        # output_json_value["rule_type"] = "External_function_rule"
                        dup_data["External_rule_id"] = ",".join(parentruleid_list)
                        # print(output_json_value)
                        # db.rule_report.insert_one(copy.deepcopy(output_json_value))
                        db.rule_report.update_one({"_id": dup_data["_id"]},
                                                  {"$set": {"rule_type": "function_type_rule"}})
                        db.rule_report.update_one({"_id": dup_data["_id"]},
                                                  {"$set": {"External_rule_id": ",".join(parentruleid_list)}})

    except Exception as e:
        exc_type, exc_obj, exc_tb = sys.exc_info()
        fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
        print(exc_type, fname, exc_tb.tb_lineno)



def rule_extractor(fun_name):
    # rule_statements ={}
    # ref_var_list = fetchimport_var(dup_data['file_name'])
    # ref_file_name_list = fetch_vbfilename(dup_data['lob'])
    output_json_value={}
    # cursor = db.Code_behind_rules_1.find_one({"function_name": "".join(fun_name)}, {'_id': 0})
    global counter
    #counter = 0
    test_data =[]
    fun_name_list = []
    fun_name_list.append(fun_name)
    parent_if = False

    try:
        for index,line in enumerate(Rule_Buffer,0):

            if line.__contains__(fun_name):
                continue
            matches = [x for x in function_list if x in line]
            if matches != [] and "".join(matches) != fun_name:

                append_resurcive_buff( "".join(matches),index)
                fun_name_list.append("".join(matches))
                fun_name = fun_name_list[-1]
                parent_if = False


            if line.lower().__contains__("end sub") and len(fun_name_list) >=2:
                fun_name_list.pop()
                fun_name = fun_name_list[-1]

            if line.lower().__contains__("end if"):
                parent_if = False


            if line.strip().lower().startswith("if") and parent_if == False:

                parent_if = True


                # rule_statements[fun_name] = if_to_end_if_collecter(Rule_Buffer, line)
                counter = counter + 1
                output_json_value["lob"] = dup_data["lob"]
                output_json_value["file_name"] = dup_data["file_name"]
                output_json_value["function_name"] = fun_name
                output_json_value["field_name"] = dup_data["field_name"]

                output_json_value["rule_statement"] = if_to_end_if_collecter(Rule_Buffer, line,index)
                output_json_value["rule_description"] = dup_data["rule_description"]
                output_json_value["parent_rule_id"] = dup_data["rule_id"]
                output_json_value["rule_id"] = dup_data["rule_id"] + "." + str(counter)
                output_json_value["dependent_control"] = dup_data["dependent_control"]
                output_json_value["rule_type"] = "function_type_rule"

                db.rule_report.insert_one(copy.deepcopy(output_json_value))

                test_data.append(copy.deepcopy(output_json_value))
            # """ Obj. function name handling"""
            # matches1 = [x for x in ref_var_list if x in line]
            # if matches1 != [] and "".join(matches1) != fun_name:
            #     # print("obj", line,matches1)
            #     counter = counter + 1
            #     calling_function_name = line.split(matches1[0])[1].split('(')[0].replace(".","")
            #     # print(calling_function_name)
            #     output_json_value["lob"] = dup_data["lob"]
            #     output_json_value["file_name"] = dup_data["file_name"]
            #     output_json_value["function_name"] = calling_function_name
            #     output_json_value["field_name"] = dup_data["field_name"]
            #     output_json_value["rule_statement"] = ["Manual Intervention Required"]
            #     output_json_value["rule_description"] = dup_data["rule_description"]
            #     output_json_value["parent_rule_id"] = dup_data["rule_id"]
            #     output_json_value["rule_id"] = dup_data["rule_id"] + "." + str(counter)
            #     output_json_value["dependent_control"] = dup_data["dependent_control"]
            #     output_json_value["rule_type"] = "function_type_rule"
            #
            #     db.rule_report.insert_one(copy.deepcopy(output_json_value))
            #
            #     test_data.append(copy.deepcopy(output_json_value))
            # """filename.function name handling """
            # matches2 = [x for x in ref_file_name_list if x in line]
            # if matches2 != [] and "".join(matches2) != fun_name:
            #     # print("filen", line)
            #     counter = counter + 1
            #     calling_function_name = line.split(matches2[0])[1].split('(')[0].replace(".","")
            #     # print(calling_function_name)
            #     output_json_value["lob"] = dup_data["lob"]
            #     output_json_value["file_name"] = dup_data["file_name"]
            #     output_json_value["function_name"] = calling_function_name
            #     output_json_value["field_name"] = dup_data["field_name"]
            #     output_json_value["rule_statement"] = ["Manual Intervention Required"]
            #     output_json_value["rule_description"] = dup_data["rule_description"]
            #     output_json_value["parent_rule_id"] = dup_data["rule_id"]
            #     output_json_value["rule_id"] = dup_data["rule_id"] + "." + str(counter)
            #     output_json_value["dependent_control"] = dup_data["dependent_control"]
            #     output_json_value["rule_type"] = dup_data["rule_type"]
            #
            #     db.rule_report.insert_one(copy.deepcopy(output_json_value))
            #
            #     test_data.append(copy.deepcopy(output_json_value))


        #print(json.dumps(test_data,indent=4))

        Rule_Buffer.clear()
    except Exception as e:
        exc_type, exc_obj, exc_tb = sys.exc_info()
        fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
        print(exc_type, fname, exc_tb.tb_lineno)


def calling_fun_parms_count(line,fun):


    params_count = len(line.split(fun)[1].split("(")[1].split(")")[0].split(","))

    return  params_count




def append_resurcive_buff(fun,index):
    try:
        cursor = db.Code_behind_rules_1.find_one({"function_name": fun}, {'_id': 0})
        for li in cursor["source_statement"]:
            index = index+1
            Rule_Buffer.insert(index,li)

        return None
    except Exception as e:
        exc_type, exc_obj, exc_tb = sys.exc_info()
        fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
        print(exc_type, fname, exc_tb.tb_lineno)


def fetch_parametres_count(fun_lines_list,calling_fun_name):
    line_collector_variable = ''
    line_collector_flag = False

    for line in fun_lines_list:

        if line_collector_flag:
            if line.rstrip().endswith(")"):
                line_collector_variable = line_collector_variable + '\n' + line
                parameters_list = line_collector_variable.replace(")", "").replace("\n", "").split(",")
                parameters_count = len(parameters_list)
                return  parameters_count, parameters_list

            else:
                line_collector_variable = line_collector_variable+ '\n' + line
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
                return parameters_count ,parameters_list
            else:
                # para_name_collection = line.split("(")
                # para_name_list = para_name_collection[1]
                line_collector_variable = line.split("(")[1] + '\n'
                # para_name = para_name_list[-1]
                line_collector_flag = True
                continue
    return  "" , ""


def if_to_end_if_collecter(lines_list,line,index):
    try:
        if_counterer = 0
        collect_flag = False
        storage = []
        if_flag = False
        level_list = []
        Lob_code, State, Rule = "","",""
        state_scan_line = ""
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
                Lob_code, State, Rule = state_scan_values(None,level_list)
                state_scan_line = "Lob_Code : "+ Lob_code + "State : " + State + "Rule :" + Rule

        # level_list.append(storage)

        storage.insert(0, state_scan_line)
        return  storage
    except Exception as e:
        exc_type, exc_obj, exc_tb = sys.exc_info()
        fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
        print(exc_type, fname, exc_tb.tb_lineno)

def get_var_app_shared(filename):
    ref_var_list = []
    with open(code_location + "\\WebApplications\\" + filename + '.vb', 'r') as vb_file:
        for lines in vb_file.readlines():
            if lines.upper().__contains__("AS")  and (lines.strip().lower().startswith("private") or lines.strip().lower().startswith("dim")):
                if lines.split()[2].upper() == "AS":
                    line_list = lines.split()
                    if (line_list[0].lower() == "private" or line_list[0].lower() == "dim") and lines.__contains__(".ApplicationShared"):
                        ref_var_list.append(line_list[1])


    return  ref_var_list


def fetchimport_var(filename):
    ref_var_list=[]
    with open(code_location+"\\WebApplications\\"+filename + '.vb', 'r') as vb_file:
        for lines in vb_file.readlines():
            if lines.upper().__contains__("AS") and (lines.__contains__(".Lob") or lines.__contains__(" Lob") or  lines.__contains__(" BusinessServices.") ) and (lines.strip().lower().startswith("private") or lines.strip().lower().startswith("dim")):
                if lines.split()[2].upper() == "AS":
                    line_list = lines.split()
                    if line_list[0].lower() == "private" or line_list[0].lower() == "dim":
                        ref_var_list.append(line_list[1]+".")



    return tuple(ref_var_list)


def fetch_vbfilename(lob):
    lob = 'LobPF'
    ref_file_name_list = []
    # print(code_location)
    import os
    file_list = os.listdir(code_location+"\\ApplicationAssembles\\"+lob+'\\'+lob+".BusinessRules")
    # print(file_list)
    for i in file_list:
        ref_file_name_list.append(i.split(".")[0]+".")

    return tuple(ref_file_name_list)




for filename in glob.glob(os.path.join(vb_path,'*.aspx')):
    metadata=[]
    main(filename,metadata)
