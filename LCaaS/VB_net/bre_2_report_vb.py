import config
import os, re, sys
import requests
from pymongo import MongoClient
code_location = config.codebase_information['code_location']
pgm_list = []
mongoClient = MongoClient('localhost', 27017)
db = mongoClient['C#']

class bre2():

 def __init__(self):
     global rule
     rule=0

 def startup(self):
     try:
        if db.drop_collection("Code_behind_rules"):
           print("deleted")
        if  db.drop_collection("rule_report"):
           print("deleted")
        for path, subdirs, files in os.walk(code_location):
            for name in files:
                # if not (name == "Browsing2.aspx.vb" or name == "CheckOut.aspx.vb"):
                #     continue
                metadata=[]
                filename = os.path.join(path, name)
                if filename.split('\\')[-1].upper().endswith(".VB") or filename.split('\\')[-1].upper().endswith("MASTER.VB"):
                    metadata=bre2.code_behind_fun(filename ,metadata)
                    bre2.db_insert(self,metadata)
                    bre2.split_data_function(self,filename)

        return "done"
     except Exception as e:
         exc_type, exc_obj, exc_tb = sys.exc_info()
         fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
         print(exc_type, fname, exc_tb.tb_lineno)

 def code_behind_fun(filename,metadata):
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

         with open(filename , 'r') as input_file:
             end_if_handled = bre2.single_line_if(input_file)
             for line in end_if_handled:
                 if line.strip() == "" or line.strip().startswith("'"):
                     continue

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

                 if function_name_1_regexx != []:
                     function_name = function_name_1_regexx[0].strip().split(' ')[3].split('(')[0]
                     cid_name = ""
                     if_data_list = []


                 if with_regexx != []:
                     cid_name = with_regexx[0].strip().split(' ')[1]

                 if end_with_regexx != []:
                     cid_name = ""


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
                             {"file_name": filename.split('\\')[-1],
                              "function_name": function_name,
                              "rule_statement": select_data_list
                              })
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
                             {"file_name": filename.split('\\')[-1],"function_name": function_name,  "rule_statement": if_data_list,
                              })
                         if_data_list = []

         return metadata
     except Exception as e:
         exc_type, exc_obj, exc_tb = sys.exc_info()
         fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
         print(exc_type, fname, exc_tb.tb_lineno)
         pass

 def db_insert(self,metadata):
   try:
     if metadata != [] and metadata != None:
         if db.Code_behind_rules.insert_many(metadata):
             print("inserted")
         metadata.clear()
     return "Insert success"
   except Exception as e:
       exc_type, exc_obj, exc_tb = sys.exc_info()
       fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
       print(exc_type, fname, exc_tb.tb_lineno)

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

                     main_if_index = append_lines.upper().index("IF ")
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

 def split_data_function(self,filename):

   print(filename)
   try:
     rule= 0
     metadata_1=[]
     code_behind_data = db.Code_behind_rules.find({"file_name":filename.split("\\")[-1]})
     for data in code_behind_data:
         previous_case_line = ""
         nested_select_flag = False
         main_select_counter = 0
         global parent_rule_id
         parent_rule_id = []
         condition_split_list = bre2.spliting_of_condition_statement(data)
         for condition_data_line_1 in condition_split_list:

             if condition_data_line_1 == []:
                 continue

             condition_data_line = condition_data_line_1[0]

             if condition_data_line.upper().strip().startswith("IF") or condition_data_line.upper().strip().startswith(
                     "SELECT ") or \
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

                 # to remove duplicate

                 parent_rule_id.append("rule-" + str(rule))

                 data1 = {"fragment_id":filename.split("\\")[-1]+"-" +str(rule),"pgm_name": filename.split("\\")[-1],"para_name": data["function_name"],
                          "Rule": "rule-" + str(rule), "source_statements": " <br> ".join(condition_data_line_1),"rule_relation": ",".join(parent_rule_id),
                           "rule_description": "",
                          "rule_type": ""
                          }
                 metadata_1.append(data1)
                 db.rule_report.insert_one(data1)
                 global dup_data
                 dup_data = data1
                 global counter
                 counter = 0
                 global rule_id_data
                 rule_id_data = data1["Rule"]
                 for j in condition_data_line_1:
                     if j.__contains__("End If") or j.__contains__("End Select"):
                         parent_rule_id.pop()
                         previous_case_line = ""
                         if j.__contains__("End Select"):
                             parent_rule_id.pop()
                             main_select_counter = main_select_counter - 1

             else:

                 data1= {"fragment_id":filename.split("\\")[-1]+"-" +str(rule),"pgm_name": filename.split("\\")[-1],"para_name": data["function_name"],
                      "Rule": "", "source_statements": " <br> ".join(condition_data_line_1), "rule_relation": ",".join(parent_rule_id),
                      "rule_description": "",
                      "rule_type": ""
                     }
                 metadata_1.append(data1)

                 db.rule_report.insert_one(
                     {"fragment_id":filename.split("\\")[-1]+"-" +str(rule),"pgm_name": filename.split("\\")[-1],"para_name": data["function_name"],
                      "Rule": "", "source_statements": " <br> ".join(condition_data_line_1), "rule_relation": ",".join(parent_rule_id),
                      "rule_description": "",
                      "rule_type": ""
                     })
                 for j in condition_data_line_1:
                     if j.__contains__("End If") or (j.__contains__("End Select") and not main_select_counter > 1):
                         if j.__contains__("End Select"):
                             parent_rule_id.pop()
                             main_select_counter = main_select_counter - 1
                         parent_rule_id.pop()
     print(len(metadata_1))
     #db.Code_behind_rules.drop()  ## for test case need to comment this to revent the code behind rule collection.
     return metadata_1
   except Exception as e:
       exc_type, exc_obj, exc_tb = sys.exc_info()
       fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
       print(exc_type, fname, exc_tb.tb_lineno)

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

if __name__ == '__main__':
    bre_object=bre2()
    bre_object.startup()
