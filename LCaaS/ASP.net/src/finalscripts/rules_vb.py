'''Script Version-1 dated on 08/October/2020
config file is a python file where the folder source path is mentioned'''

import config
from pymongo import MongoClient
import glob,os,re
import json
import copy
import csv
import sys
import pandas as pd

'''database operation '''
mongoclient = MongoClient('localhost',27017)
db = mongoclient['SIL']

''''The source file is obtained from the config file'''
lob = config.codebase_information['VB']['folder_name']
code_location =config.codebase_information['code_location']
# print("Code_Location:",code_location)
lob_path = code_location+'\\'+'ApplicationAssembles'



def func_separation(original_file,final_level_folder):
    '''joining the entire folder path with the VB compoennt file
       final_level_folder = entire folder path
       original_file = VB file'''
    for filesss in glob.glob(os.path.join(final_level_folder, original_file)):
        with open(filesss, 'r') as input_file:
            storage = []
            '''instead of hardcoding, we are assigning it as a varaible'''
            pub_func = "public function"
            pub_share = "public shared"
            pub_sub = "public sub"
            private_sub = "private sub"
            private_share = "private shared"
            end_func = "End Function"
            end_sub = "End Sub"

            function_type = ""
            para_repositoy_flag = False
            if_collecting_flag = False
            rare_if_collecting_flag = False
            para_list = []
            main_if_index = 0
            para_repository_dict = {}  ### dict which holds the function name as key and the lines under a function as value
            para_repository_arguments = {}  ### dict which holds the function name as key and the no. of arguments as value
            para_repository_function = {}  ### dict which holds the function name as key and the function type as value
            parameters_count = 0
            process_list = []

            ''' The below for loop is used to append all lines in the process list
                There are certain scenarios in which If does not have End If
                Below for loop is used to add End If's to Standalone If's which doesnot have If's'''

            for append_lines in input_file.readlines():
                try:
                    if append_lines.strip() == "":
                        continue
                    if append_lines.lstrip().startswith("'"):
                        continue

                    if if_collecting_flag:
                        if append_lines[main_if_index] != " " and not append_lines.casefold().__contains__("end if"):
                           if append_lines.casefold().__contains__("end sub") or append_lines.casefold().__contains__(
                                "end function") :
                            # process_list.append(append_lines)
                                process_list.append('\n' + "End If")
                                process_list.append(append_lines)
                                if_collecting_flag = False
                                continue
                           elif re.search(' If.*',append_lines,re.IGNORECASE):
                                process_list.append('\n' + "End If")
                                if_collecting_flag = False
                           else:
                               process_list.append('\n' + "End If")
                               if_collecting_flag = False
                               continue
                        elif append_lines[main_if_index] != " " and append_lines.casefold().__contains__("end if"):
                            end_if_index = append_lines.index("end if")
                            if main_if_index == end_if_index:
                                process_list.append(append_lines)
                                if_collecting_flag = False
                                continue
                            else:
                                process_list.append(append_lines)
                                continue
                        elif append_lines.casefold().__contains__("end sub") or append_lines.casefold().__contains__("end function"):
                            process_list.append('\n' + "End If")
                            if_collecting_flag = False
                            continue
                        else:
                            process_list.append(append_lines)
                            continue
                    if re.search(' If.*',append_lines,re.IGNORECASE):
                        main_if_index = append_lines.index("If")
                        process_list.append(append_lines)
                        if_collecting_flag = True
                        continue
                    else:
                        process_list.append(append_lines)
                        continue
                except Exception as e:
                    print(e)

            # for append_lines in input_file.readlines():
            #     if re.search('.*If.*',append_lines,re.IGNORECASE) and append_lines.casefold().__contains__("then") and not append_lines.rstrip().casefold().endswith("="):
            #         if not append_lines.rstrip().casefold().endswith("then"):
            #             process_list.append(append_lines)
            #             process_list.append('\n' + "End If")
            #             continue
            #     if re.search('.*If.*',append_lines,re.IGNORECASE) and append_lines.casefold().__contains__("then") and  append_lines.rstrip().casefold().endswith("="):
            #            process_list.append(append_lines)
            #            rare_if_collecting_flag = True
            #            continue
            #
            #     if rare_if_collecting_flag:
            #         process_list.append(append_lines)
            #         process_list.append('\n' + "End If")
            #         rare_if_collecting_flag = False
            #         continue
            #
            #     if if_collecting_flag:
            #         if append_lines.casefold().__contains__("then") and not append_lines.rstrip().casefold().endswith("then"):
            #             process_list.append(append_lines)
            #             process_list.append('\n' + "End If")
            #             if_collecting_flag = False
            #             continue
            #         else:
            #             process_list.append(append_lines)
            #             continue
            #     if re.search('.*If.*',append_lines,re.IGNORECASE) and (append_lines.casefold().__contains__("andalso")  or append_lines.casefold().__contains__("andelse") or append_lines.casefold().__contains__("orelse") or append_lines.casefold().__contains__("oralso")):
            #         if not append_lines.rstrip().casefold().endswith("then"):
            #            process_list.append(append_lines)
            #            if_collecting_flag = True
            #            continue
            #         else:
            #             process_list.append(append_lines)
            #             continue
            #     else:
            #         process_list.append(append_lines)
            #         continue

            ''' The below FOR loop is used to separate all functions in a VB component file and store it in \
             para_repository_dict , with function name as Key of Dict and Lines of those respective functions as Values of Dict'''
            ''''''

            for line_counter, line in enumerate(process_list):
                if line.strip() == "":
                    continue
                if re.search(end_sub,line,re.IGNORECASE) or re.search(end_func,line,re.IGNORECASE):
                    # print("Winnn")
                    storage.append(line)
                    para_list.append(para_name)
                    if para_name == '':
                        para_list.append("")
                        para_repository_dict[''] = copy.deepcopy(storage)
                        storage.clear()

                    else:

                        para_repository_dict[para_name] = copy.deepcopy(storage)
                        para_repository_arguments[para_name] = parameters_count
                        para_repository_function[para_name] = function_type
                        storage.clear()
                        parameters_count = 0
                        function_type = ""


                    para_repositoy_flag = False
                    continue

                if para_repositoy_flag:
                    storage.append(line)
                    continue

                if re.search(pub_func,line,re.IGNORECASE) or re.search(private_share,line,re.IGNORECASE) or re.search(pub_sub,line,re.IGNORECASE) or re.search(private_sub,line,re.IGNORECASE) or re.search(pub_share,line,re.IGNORECASE):
                    para_name_collection = line.split("(")
                    para_name_list = para_name_collection[0].split()
                    parameters_list = para_name_collection[1].replace(")","").replace("\n","").split(",")
                    parameters_count = len(parameters_list)

                    para_name = para_name_list[-1]
                    if line.casefold().__contains__("public function"):
                        function_type = "PF"
                    elif line.casefold().__contains__("public shared"):
                        function_type = "PU-S"
                    elif line.casefold().__contains__("private shared"):
                        function_type = "PV-S"
                    else:
                        function_type = ""
                    # print("Collection:",para_name)
                    para_repositoy_flag = True
                    continue

    print("Checking:", json.dumps(para_repository_dict, indent=4))
    return para_repository_dict,para_list,para_repository_arguments,para_repository_function

# def if_main(if_collector_list,rules_counter,metadata):
#     if_rules_variable = ""
#     if_collector_flag = False
#     within_if_flag = False
#     for ifter in if_collector_list:
#
#            if within_if_flag:
#                if re.search('.*End if.*',ifter,re.IGNORECASE):
#                    end_if_index = ifter.index("End If")
#
#                    if_rules_variable = if_rules_variable + '\n' + ifter
#                    metadata.append({"Rules":if_rules_variable,
#                                     "Rule-ID":parent_rules_counter})
#                    within_if_flag = False
#                    continue
#                if re.search('.*ElseIf.*',ifter,re.IGNORECASE):
#                    if rules_counter == parent_rules_counter:
#                         metadata.append({"Rules":if_rules_variable,
#                                     "Rule-ID":parent_rules_counter})
#                         continue
#
#                    else:
#                        metadata.append({"Rules": if_rules_variable,
#                                         "Rule-ID": rules_counter,
#                                         "Parent-Rule-ID": parent_rules_counter})
#                        if_rules_variable = ""
#                        rules_counter = rules_counter + 1
#                        continue
#                else:
#                    if_rules_variable = if_rules_variable + '\n' + ifter
#                    continue
#
#            if re.search('.*If.*',ifter,re.IGNORECASE) :
#                 if_rules_variable = ""
#                 if_index = ifter.index("If")
#                 if_rules_variable = if_rules_variable + '\n' + ifter
#                 rules_counter = rules_counter + 1
#                 parent_rules_counter = rules_counter
#
#                 within_if_flag = True
#                 continue
#     return rules_counter

# def select_main(select_collector_list,rules_counter,metadata):
#
#
#          within_select_flag = False
#          select_if_flag = False
#          case_counter = 0
#          parent_rules_counter = 0
#          case_parent_rules_counter = 0
#          case_variable = ""
#          select_if_variable = ""
#          for selector in select_collector_list:
#
#              if within_select_flag:
#                  if select_if_flag:
#                      if re.search('.*End If.*',selector,re.IGNORECASE):
#                          metadata.append({"Rules":select_if_variable,
#                                           "Rule-ID":rules_counter,
#                                           "Parent-Rule-ID":str(parent_rules_counter) + "," + str(case_parent_rules_counter)})
#                          select_if_flag = False
#                          continue
#
#
#                      else:
#                          select_if_variable = select_if_variable + '\n' + selector
#                          continue
#
#                  # if case_counter == 1:
#                  if re.search('.*End Select.*',selector,re.IGNORECASE):
#                      if case_variable != "":
#                          metadata.append({"Rules":case_variable,
#                                           "Rule-ID":rules_counter,
#                                           "Parent-Rule-ID":parent_rules_counter})
#                          rules_counter = rules_counter + 1
#                          metadata.append({"Rules":selector,
#                                           "Rule-ID":rules_counter,
#                                           "Parent-Rule-ID":parent_rules_counter
#
#                          })
#                          within_select_flag = False
#                          continue
#                      else:
#                          rules_counter = rules_counter + 1
#                          metadata.append({"Rules": selector,
#                                           "Rule-ID": rules_counter,
#                                           "Parent-Rule-ID": parent_rules_counter
#
#                                           })
#                          within_select_flag = False
#                          continue
#                  if re.search('.*Case.*',selector,re.IGNORECASE):
#
#                      case_parent_rules_counter = rules_counter
#
#                      metadata.append({"Rules":case_variable,
#                                       "Rule-ID":rules_counter,
#                                       "Parent-Rule-ID":parent_rules_counter})
#                      case_variable = ""
#                      case_variable = case_variable + '\n' + selector
#                      rules_counter = rules_counter + 1
#                      continue
#
#                  if re.search('.*If.*',selector,re.IGNORECASE):
#                      if not re.search('.*End If.*',selector,re.IGNORECASE):
#                          case_parent_rules_counter = rules_counter
#                          metadata.append({"Rules": case_variable,
#                                           "Rule-ID": rules_counter,
#                                           "Parent-Rule-ID": parent_rules_counter})
#                          case_variable = ""
#                          select_if_variable = select_if_variable + '\n' + selector
#                          rules_counter = rules_counter + 1
#                          select_if_flag = True
#                          continue
#
#                  else:
#                      case_variable = case_variable + '\n' + selector
#                      continue
#
#              if re.search('.*Case.*',selector,re.IGNORECASE) and not selector.__contains__("Select"):
#
#                  case_variable = case_variable + '\n' + selector
#                  rules_counter = rules_counter + 1
#                  within_select_flag = True
#                  continue
#
#
#              if re.search('.*Select.*',selector,re.IGNORECASE):
#                  rules_variable = ""
#                  rules_variable = selector
#                  rules_counter = rules_counter + 1
#                  parent_rules_counter = rules_counter
#                  metadata.append({"Rules":rules_variable,
#                                  "Rule-ID":parent_rules_counter})
#
#                  # within_select_flag = True
#                  continue
#
#          return rules_counter

def spliting_of_condition_statement(final_list):

   try:
    if_counter=0
    case_counter=0
    elif_counter=0
    if_list=[]
    flag=False
    main_list=[]



    for condition_key,condition_value in para_iter.items():
            for condition_line in condition_value:

                select_flag_regexx_1 = re.findall(r'^\s*select\s*case\s*.*', condition_line, re.IGNORECASE)

                end_select_regexx_1 = re.findall(r'^\s*end\s*select\s*', condition_line, re.IGNORECASE)

                case_regexx_1 = re.findall(r'^\s*case\s*.*', condition_line, re.IGNORECASE)

                if_regexx_1 = re.findall(r'^\s*\t*IF\s.*', condition_line, re.IGNORECASE)

                elif_regexx_1 = re.findall(r'^\s*ElseIf\s.*',condition_line, re.IGNORECASE)

                if1_regexx_1 = re.findall(r'^\s*\t*IF\s*[(].*', condition_line, re.IGNORECASE)

                end_if_regexx_1 = re.findall(r'^\s*\t*END\s*IF\s*', condition_line, re.IGNORECASE)

                if if_regexx_1 !=[] or if1_regexx_1!=[] or select_flag_regexx_1 !=[] or case_regexx_1!=[] or elif_regexx_1!=[]:

                    if_counter=if_counter+1
                    if if_counter>1 :
                        main_list.append(if_list)
                        if_list=[]
                    flag=True
                    if elif_regexx_1!= []:
                        elif_counter=elif_counter+1
                        if not elif_counter ==1:
                            if_counter = if_counter - 1
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



def rules_func(para_repository_dict,paragraph_name):
   # print(name_of_file,final_level_folder)

          metadata = []
          rules_counter = 0

          global rules_variable
          rules_variable = ""
          if_collector_flag = False
          select_collector_flag = False
          if_collector_list = []
          select_collector_list = []
          select_counter = 0
          end_select_counter = 0
          para_repository_final = {}
          final_list = []
          if_counter = 0
          end_if_counter = 0

          for line in para_repository_dict[paragraph_name]:
                   # print("Rules_Check:",json.dumps(para_repository_dict, indent=4))


                   if re.search('.*End If.*',line,re.IGNORECASE):
                       end_if_counter = end_if_counter + 1
                       if if_counter == end_if_counter:
                            if_collector_list.append(line)
                            para_repository_final[paragraph_name] = copy.deepcopy(if_collector_list)
                            final_list.append(para_repository_final)
                            para_repository_final = {}
                            if_collector_list.clear()
                            if_collector_flag = False
                            continue



                   if if_collector_flag:
                       if re.search('.*If.*',line,re.IGNORECASE):
                           if not re.search('.*End If.*',line,re.IGNORECASE) and not re.search('.*ElseIf.*',line,re.IGNORECASE):
                                if_counter = if_counter + 1
                       if_collector_list.append(line)

                       continue
                   if re.search('.*End Select.*',line,re.IGNORECASE):
                       end_select_counter = end_select_counter + 1
                       if select_counter == end_select_counter:
                            select_collector_list.append(line)
                            para_repository_final[paragraph_name] = copy.deepcopy(select_collector_list)
                            final_list.append(para_repository_final)
                            para_repository_final = {}
                            select_collector_list.clear()
                            select_collector_flag = False
                            continue

                   if select_collector_flag:
                       if re.search('.*Select.*', line, re.IGNORECASE):
                            if not re.search('.*End Select.*', line, re.IGNORECASE):
                                select_counter = select_counter + 1
                       select_collector_list.append(line)
                       continue

                   if re.search('.*Select Case.*',line,re.IGNORECASE):
                       select_counter = select_counter + 1
                       select_collector_list.append(line)
                       select_collector_flag = True
                       continue


                   if re.search('.*If.*',line,re.IGNORECASE):
                       # print("Ifff:",line)
                       if_counter = if_counter + 1
                       if_collector_list.append(line)
                       if_collector_flag = True
                       continue
                   else:
                       continue




          return final_list


folders = os.listdir(lob_path)
'''Below logic is to access the folders dynamically and we need to process only the vb file
Business, Shared and Resource folders under each lob is accessed'''
for folder in folders:
    next_level_folder = os.path.join(lob_path,folder)
    # print(next_level_folder)
    next_folder = os.listdir(next_level_folder)
    # print(next_folder)
    business = "BusinessRules"
    shared = "Shared"
    for next_iter in next_folder:
        if re.search(business,next_iter,re.IGNORECASE) or re.search(shared,next_iter,re.IGNORECASE):
            final_level_folder = os.path.join(next_level_folder,next_iter)
            # print("Final:",final_level_folder)
            filename = os.listdir(final_level_folder)
            # print("JK:",filename)
            for file in (filename):
                original_file = file
                print("Original:",original_file)
                file = file.split(".")
                name_of_file = file[0]
                if file[-1].upper() == "VB":
                    # print("Filesss:",file)
                    para_repository_dict,para_list,para_repository_argument,para_repository_function = func_separation(original_file,final_level_folder)
                    # para_repository_dict,para_list = rules_func(para_repository_dict,para_list)

                    rule = 0
                    main_select_counter = 0
                    parent_rule_id = []
                    previous_case_line = ""
                    for paragraph_name in para_list:
                        final_list = rules_func(para_repository_dict, paragraph_name)
                        for para_iter in final_list:
                            # print("Para_Iter:",json.dumps(para_repository_dict, indent=4))
                            condition_split_list = spliting_of_condition_statement(para_iter)
                    # rules_func(para_repository_dict,para_list)
                            for condition_data_line_1 in condition_split_list:

                                if condition_data_line_1 == []:
                                    continue

                                condition_data_line = condition_data_line_1[0]

                                if condition_data_line.upper().strip().startswith(
                                        "IF") or condition_data_line.upper().strip().startswith("ELSEIF") or condition_data_line.upper().strip().startswith("SELECT ") or \
                                        condition_data_line.upper().strip().startswith("CASE "):
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

                                    if condition_data_line.upper().strip().startswith("ELSEIF "):
                                        parent_rule_id.pop()

                                    parent_rule_id.append("rule-" + str(rule))
                                    # print("Parent:",parent_rule_id)
                                    data1 = {"LOB": folder, "File Name": original_file, "File Path": final_level_folder,
                                             "Function Name": paragraph_name,"No of Parameters":para_repository_argument[paragraph_name],
                                             "Function Type":para_repository_function[paragraph_name],
                                             "rule_id": "rule-" + str(rule), "rule_statement": condition_data_line_1,

                                             "parent_rule_id": ",".join(parent_rule_id)}

                                    db.rule_report.insert_one(data1)

                                    for j in condition_data_line_1:
                                        # if j.__contains__("End If") or j.__contains__("End Select") or (j.strip().upper().startswith("CASE ") and  main_select_counter <= 1):
                                        if j.__contains__("End If") or j.__contains__("End Select"):
                                            parent_rule_id.pop()
                                            previous_case_line = ""
                                            if j.__contains__("End Select"):
                                                parent_rule_id.pop()
                                                main_select_counter = main_select_counter - 1

                                    # classification_of_if(data1)

                                else:


                                    data1 = {"LOB": folder, "File Name": original_file, "File Path": final_level_folder,
                                         "Function Name": paragraph_name,"No of Parameters":para_repository_argument[paragraph_name],
                                         "Function Type": para_repository_function[paragraph_name],
                                         "rule_id": "", "rule_statement": condition_data_line_1,

                                         "parent_rule_id": ",".join(parent_rule_id)}

                                    db.rule_report.insert_one(data1)

                                    for j in condition_data_line_1:
                                        if j.__contains__("End If") or (
                                                j.__contains__("End Select") and not main_select_counter > 1):
                                            if j.__contains__("End Select"):
                                                parent_rule_id.pop()
                                                main_select_counter = main_select_counter - 1
                                            parent_rule_id.pop()



                        # break

            ### Below commented lines are used to print the output into an Excel.
            # print("Metadata:",data1)
            # df = pd.DataFrame(data1)
            #
            # # Create a Pandas Excel writer using XlsxWriter as the engine.
            # writer = pd.ExcelWriter('pandas_simple.xlsx', engine='xlsxwriter')
            #
            # # Convert the dataframe to an XlsxWriter Excel object.
            # df.to_excel(writer, sheet_name='Sheet1')
            #
            # # Close the Pandas Excel writer and output the Excel file.
            # writer.save()

            out_data = []
            metadata_1 = db.rule_report.find({})
            for screen_data_1 in metadata_1:
                  screen_data_1.pop("_id")
            #     screen_data_1.update({"rule_statement": " ".join(screen_data_1["rule_statement"])})
                  out_data.append(screen_data_1)

            with open("screen_fields1" + '.csv', 'w', newline="") as output_file:
                Fields = ["LOB", "File Name", "File Path", "Function Name","No of Parameters","Function Type",
                          "rule_id","rule_statement", "parent_rule_id"]
                dict_writer = csv.DictWriter(output_file, fieldnames=Fields)
                dict_writer.writeheader()
                dict_writer.writerows(out_data)
