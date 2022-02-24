import config
from pymongo import MongoClient
import glob,os,copy
import re
import json
import csv
import sys
import time


start_time = time.time()

Version=" Not directly updating the Control ID in code behind DB"

Version2="Include the classification of IF condition"

mongoClient = MongoClient('localhost', 27017)
db = mongoClient['asp1']
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

        #with open(filename,'r') as input_file:

        code_behind_data = db.Code_behind_rules.find({"file_name": filename.split("\\")[-1].split('.')[0]},{'_id':0})
        code_behind_data_dup=[]
        for k in code_behind_data:
            code_behind_data_dup.append(k)
        #code_behind_data_wihtout_cid=db.Code_behind_rules.find({"$and":[{"file_name":filename.split("\\")[-1].split('.')[0],"field_name":""}]})

        for control_id in screen_fields_list:

            for data in code_behind_data_dup:

                if data["field_name"] == control_id.strip():
                    rule=rule+1
                    data.update(
                        {"rule_id": "rule-" + str(rule), "parent_rule_id": "", "rule_description": "",
                         "rule_type": "server_side", "file_name": filename.split('\\')[-1],"lob":"","dependent_control":""})
                    metadata.append(data)

                    db.rule_report.insert_one(data)
                    classification_of_if(data)
                elif data["field_name"]=="":
                    for line1 in data["rule_statement"]:
                        if line1.strip().startswith("if ") or line1.strip().startswith("If ") or \
                                  line1.strip().startswith("if(") or line1.strip().startswith("If("):
                            continue
                        control_id_dup=' '+control_id+'.'
                        if control_id_dup in line1:
                            rule=rule+1
                            data.update(
                                {"field_name":control_id,"rule_id": "rule-" + str(rule), "parent_rule_id": "",
                                 "rule_description": "",
                                 "rule_type": "server_side", "file_name": filename.split('\\')[-1],"lob":"","dependent_control":""})
                            classification_of_if(data)
                            metadata.append(data)
                            db.rule_report.insert_one(data)
                            break


        # for rule1 in metadata:
        #     rule=rule+1
        #     rule1.update({"rule_id":"Rule-"+str(rule)})
        out_data=[]
        metadata_1 = db.rule_report.find({})
        for screen_data_1 in metadata_1:
            screen_data_1.pop("_id")
            screen_data_1.update({"rule_statement":"".join(screen_data_1["rule_statement"])})
            out_data.append(screen_data_1)

        with open("Rules_Report_2" + '.csv', 'w', newline="") as output_file:
            Fields = ["rule_id","file_name","function_name","field_name","rule_statement","parent_rule_id","rule_description","rule_type","lob","dependent_control"]
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



def section_name_fun(filename,section_name):
    try:
        section_value_flag=False
        section_name_2=""
        with open(filename + '.vb', 'r') as vb_file:
            section_name_1='set'+section_name+'\s*\(\)'

            for lines in vb_file.readlines():

                if lines.strip()=="":
                    continue
                section_value=re.search(section_name_1,lines)
                section_end_sub=re.findall(r'^\s*end\s*sub\s*',lines,re.IGNORECASE)
                if section_value:
                    section_value_flag=True
                if section_end_sub!=[]:
                    section_value_flag=False
                if section_value_flag:
                    section_name_2=re.findall(r'^\s*.*\.PrimaryTitleText\s*=\s*".*"',lines,re.IGNORECASE)
                    if section_name_2!=[]:
                        section_name_2=section_name_2[0].split("=")[1].replace('"','')
                        break
            vb_file.close()
        if section_name_2=="":
            with open(filename + '.vb', 'r') as vb_file:
                section_name_1 = '\s*With\s*'+ section_name
                for lines in vb_file.readlines():
                    if lines.strip() == "":
                        continue
                    section_value = re.search(section_name_1, lines)
                    section_end_sub = re.findall(r'^\s*end\s*sub\s*', lines, re.IGNORECASE)
                    if section_value:
                        section_value_flag = True
                    if section_end_sub != []:
                        section_value_flag = False
                    if section_value_flag:
                        section_name_2 = re.findall(r'^\s*.*\.PrimaryTitleText\s*=\s*".*"', lines,re.IGNORECASE)
                        if section_name_2 != []:
                            section_name_2 = section_name_2[0].split("=")[1].replace('"', '')
                            break
            vb_file.close()
        if section_name_2=="":
            with open(filename + '.vb', 'r') as vb_file:
                section_name_1 = '\s*'+section_name+'\.PrimaryTitleText\s*=\s*".*"'
                for lines in vb_file.readlines():
                    if lines.strip() == "":
                        continue
                    section_value = re.search(section_name_1, lines)
                    if section_value:
                        section_name_2 = re.findall(r'^\s*.*\.PrimaryTitleText\s*=\s*".*"', lines,re.IGNORECASE)
                        if section_name_2 != []:
                            section_name_2 = section_name_2[0].split("=")[1].replace('"', '')
                            break

        vb_file.close()
        return section_name_2

    except Exception as e:
        print(e)

def label_name_fun(filename,label_name):
    try:
        section_value_flag = False
        for_control_value=""
        label_name_2=""
        label_name_3=""

        with open(filename + '.vb', 'r') as vb_file:
            label_name_1 = 'set' + label_name + '\s*\(\)'
            for lines in vb_file.readlines():
                if lines.strip()=="":
                    continue
                label_value = re.search(label_name_1, lines)
                label_end_sub = re.findall(r'^\s*end\s*sub\s*', lines, re.IGNORECASE)
                if label_value:
                    section_value_flag = True
                if label_end_sub != []:
                    section_value_flag = False
                if section_value_flag:
                    label_name_2 = re.findall(r'^\s*.*\.Text\s*=\s*".*"', lines,re.IGNORECASE)
                    for_control_regexx=re.findall(r'\s*.*\.ForControl\s*=\s*.*',lines,re.IGNORECASE)
                    if label_name_2 != []:
                        label_name_3 = label_name_2[0].split("=")[1].replace('"', '')
                    if for_control_regexx!=[]:
                        for_control_value = for_control_regexx[0].split("=")[1].replace('"', '')
            vb_file.close()


        if label_name_3=="" and for_control_value=="":
            with open(filename + '.vb', 'r') as vb_file:
                label_name_1 = '\s*With\s*' + label_name
                for lines in vb_file.readlines():
                    if lines.strip() == "":
                        continue
                    label_value = re.search(label_name_1, lines)
                    label_end_sub = re.findall(r'^\s*end\s*sub\s*', lines, re.IGNORECASE)
                    if label_value:
                        section_value_flag = True
                    if label_end_sub != []:
                        section_value_flag = False
                    if section_value_flag:
                        label_name_2 = re.findall(r'^\s*.*\.Text\s*=\s*".*"', lines,re.IGNORECASE)
                        for_control_regexx = re.findall(r'\s*.*\.ForControl\s*=\s*.*', lines,re.IGNORECASE)
                        if label_name_2 != []:
                            label_name_3 = label_name_2[0].split("=")[1].replace('"', '')
                        if for_control_regexx != []:
                            for_control_value = for_control_regexx[0].split("=")[1].replace('"', '')

                    if for_control_value !="" and label_name_3!="":
                        break
                vb_file.close()

        if label_name_3=="" and for_control_value=="":
            with open(filename + '.vb', 'r') as vb_file:
                label_name_1 = '\s*'+ label_name+'\.ForControl\s*=\s*".*"'
                for_control_reg='\s*'+label_name+'\.Text\s*=\s*".*"'
                for lines in vb_file.readlines():
                    if lines.strip() == "":
                        continue
                    label_name_2 = re.search(label_name_1, lines)
                    for_control_reg=re.search(for_control_reg,lines)
                    if label_name_2:
                        label_name_2 = re.findall(r'^\s*.*\.Text\s*=\s*".*"', lines,re.IGNORECASE)
                        if label_name_2!=[]:
                            label_name_3 = label_name_2[0].split("=")[1].replace('"', '')
                    if for_control_reg:
                        for_control_regexx = re.findall(r'\s*.*\.ForControl\s*=\s*.*', lines,re.IGNORECASE)
                        if for_control_regexx!=[]:
                           for_control_value = for_control_regexx[0].split("=")[1].replace('"', '')

                    if for_control_value !="" and label_name_3!="":
                        break
            vb.close()

        return label_name_3,for_control_value

    except Exception as e:
        print(e)

def code_behind_fun(filename):


    metadata = []
    
    metadata_1=[]

    if_flag = False

    if_counter = 0

    cid_name = ""

    function_name = ""

    dup_function_name=""

    if_data_list = []
    dup_flag=False
    full_data_list=[]
    with open(filename+'.vb', 'r') as input_file:

        for line in input_file.readlines():

            if line.strip() == "":
                continue


            # function_name_regexx=re.findall(r'^\s*PRIVATE\s*SUB\s*[A0-Z9]*[(][a0-z9]*[)]\s*.*',line,re.IGNORECASE)
            function_name_regexx = re.findall(r'^\s*PRIVATE\s*SUB\s*[A0-Z9_]*[(].*', line, re.IGNORECASE)
            function_name_2_regexx = re.findall(r'^\s*PRIVATE\s*FUNCTION\s*[A0-Z9_]*[(].*', line, re.IGNORECASE)


            function_name_1_regexx=re.findall(r'^\s*\t*PUBLIC\s*SHARED\s*FUNCTION\s*[A0-Z9_]*[(].*',line,re.IGNORECASE)


            end_sub = re.findall(r'^\s*end\s*sub\s*', line, re.IGNORECASE)

            end_function=re.findall(r'^\s*end\s*function',line,re.IGNORECASE)

            if_regexx = re.findall(r'^\s*\t*IF\s.*', line, re.IGNORECASE)

            if1_regexx = re.findall(r'^\s*\t*IF\s*[(].*', line, re.IGNORECASE)

            end_if_regexx = re.findall(r'^\s*\t*END\s*IF\s*', line, re.IGNORECASE)

            with_regexx = re.findall(r'^\s*With\s*.*', line, re.IGNORECASE)
            end_with_regexx=re.findall(r'^\s*\t*end\s*with\s*',line,re.IGNORECASE)

            if function_name_2_regexx != []:
                function_name = function_name_2_regexx[0].strip().split(' ')[2].split('(')[0]
                cid_name = ""
                if_data_list = []
                dup_flag = True
            if function_name_regexx != [] :
                function_name = function_name_regexx[0].strip().split(' ')[2].split('(')[0]
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

                metadata_1.append({"file_name":filename.split('\\')[-1].split('.')[0],"function_name": function_name, "source_statement": full_data_list})
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

            if if1_regexx != [] or if_regexx != []:
                if_counter = if_counter + 1

                if_flag = True

            if if_flag:

                if not line.strip() == "":
                    if_data_list.append(line.replace("\t",""))

            #if end_if_regexx != [] or if_counter >= 2:

            if end_if_regexx != []:

                if_counter = if_counter - 1

                if if_counter == 0:
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




def classification_of_if(data):
   global dup_data
   dup_data = data
   if_line_flag = False
   if_statement_string=""
   if_statement_list=[]
   counter=0
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

   #print(if_statement_string)
   # Segregation of IF.
   if  if_statement_string.__contains__(" OrElse ") or   if_statement_string.__contains__(" AndAlso ") or   if_statement_string.__contains__(" or ")   \
       or  if_statement_string.__contains__(" and "):

      None

   else:

      if_function(if_statement_string,data)
       
   # if if_statement_string[2:].strip().startswith("("):
   #     print("ggggggggggggggg",if_statement_string)

   #elif if_statement_string[2:].strip().startswith("String.") or if_statement_string[2:].strip().startswith("String.") :

   #back_trace_fun(data)


def if_function(if_statement_string,data):


   if_value=if_statement_string.replace('If ','').replace(' Then','')

   if if_value.strip().startswith('String.')or if_value.__contains__(' String.'):

       if if_value.__contains__(','):
           if_value_1=if_value.split(',')[1].strip()
           if if_value_1.startswith('"') or if_value_1.startswith("'"):
               pass

           else:
               # variable function has to be called.
              
               variable_if_fun(if_value.split(',')[1].split('.')[0])# sending only the variable
               None

       else:  # for Right hand side check ,we are leaving this if conditon by considering as direct.

           None

   elif if_value.__contains__('=') or if_value.__contains__('>') or if_value.__contains__('<'):

        boolean_list=["TRUE","FALSE",'"Y"','"N"']
        if if_value.__contains__('='):
            if_value_2=if_value.split('=')[1].replace('>','').replace('<','')
        elif  if_value.__contains__('>'):
            if_value_2=if_value.split('>')[1].replace('<','').replace('=','')
        elif  if_value.__contains__('<'):
            if_value_2=if_value.split('>')[1].replace('>','').replace('=','')

        if if_value_2.strip().upper()in boolean_list or if_value_2.strip().startswith('"') :
            None
            # print(if_statement_string)
            #Direct if pattern need not to capture anything.
        else:
            # Need to call or check for variable pattern IF.
            #print(if_value_2)    
            variable_if_fun(if_value_2.split('.')[0])

           
   else: 
       #print(if_statement_string)
       single_if_statement=if_statement_string.replace('If ','').replace(' Then','').split('.')[0]
       variable_if_fun(single_if_statement)

       #it contains only single variable ,it can be divided into function or variable.






def variable_if_fun(if_statement_string):# checking it is variable or function.

    variable_flag=False
    if_line_flag=False
    inside_if_flag=False
    if_counter=0
    lines_flag=False
    if if_statement_string.__contains__('(') and if_statement_string.__contains__(')'):# checking for function.

        #if_statement_string_1=if_statement_string.split('(')[0]
        
        name_val_var = if_statement_string.split("(")[0]
        if_statement_list=[]
        inside_if_list=[]
        with open(filename + '.vb', 'r') as vb_file:
            for lines in vb_file.readlines():
                if lines.strip().startswith("'"):
                    continue

                end_if_regexx = re.findall(r'^\s*\t*END\s*IF\s*', lines, re.IGNORECASE)

                if (lines.strip().startswith("If ") or lines.strip().startswith("If(")) and lines.strip().endswith(' Then'):
                    lines=lines.strip()

                elif (lines.strip().startswith("If ") or lines.strip().startswith("If(")) and not lines.strip().endswith(' Then'):
                    if_statement_list.append(lines.strip())
                    if_line_flag=True
                    continue
                elif if_line_flag:
                    if_statement_list.append(lines.strip())
                    if lines.strip().endswith(" Then"):
                        lines=" ".join(if_statement_list)
                        if_statement_list=[]
                        if_line_flag=False
                    else:
                        continue

                if lines.upper().startswith('IF ') or  lines.upper().strip().startswith("IF("):

                    inside_if_flag=True
                    inside_if_list.append(lines)
                    if_counter=if_counter+1
                    continue # skipping the condition line.

                if inside_if_flag:
                    inside_if_list.append(lines)

                if lines.split("=")[0].strip().__contains__(name_val_var.strip()) and lines.__contains__("="):

                    variable_flag=True
                    if inside_if_flag:
                        lines_flag=True
                if end_if_regexx!=[]:
                     if_counter=if_counter-1
                     if if_counter==0:
                        if lines_flag:
                            db.rule_report.insert_one(
                                {"dependent_control": dup_data["field_name"], "parent_rule_id": dup_data["rule_id"],
                                 "rule_statement": " ".join(inside_if_list)})

                            # print(inside_if_list)
                            lines_flag=False
                        inside_if_list=[]
                        inside_if_flag=False


        vb_file.close()
        if not variable_flag:# If not true , then it is a function.
            # print("call function",if_statement_string)
            Function_processer(if_statement_string,dup_data)

    else:#single varaible 

      name_val_var = if_statement_string
      if_statement_list = []
      inside_if_list = []
      with open(filename + '.vb', 'r') as vb_file:
          if_statement_list=[]
          for lines in vb_file.readlines():
              end_if_regexx = re.findall(r'^\s*\t*END\s*IF\s*', lines, re.IGNORECASE)
              if lines.strip().startswith("'"):
                  continue

              if (lines.strip().startswith("If ") or lines.strip().startswith("If(")) and lines.strip().endswith(' Then'):
                  lines=lines.strip()

              elif (lines.strip().startswith("If ") or lines.strip().startswith("If(")) and not lines.strip().endswith(' Then'):
                  if_statement_list.append(lines.strip())
                  if_line_flag=True
                  continue
              elif if_line_flag:
                  if_statement_list.append(lines.strip())
                  if lines.strip().endswith(" Then"):
                      lines=" ".join(if_statement_list)
                      if_statement_list=[]
                      if_line_flag=False
                  else:
                      continue

              if lines.upper().startswith('IF ') or lines.upper().strip().startswith("IF("):
                  inside_if_flag = True
                  inside_if_list.append(lines)
                  if_counter = if_counter + 1
                  continue  # skipping the condition line.

              if inside_if_flag:
                  inside_if_list.append(lines)

              if lines.split("=")[0].strip().__contains__(name_val_var.strip()) and lines.__contains__("="):
                  variable_flag = True
                  if inside_if_flag:
                      lines_flag = True
                  None

              if end_if_regexx != []:
                  if_counter = if_counter - 1
                  if if_counter == 0:
                      if lines_flag:
                          #rint("gg",inside_if_list,dup_data)
                          db.rule_report.insert_one({"dependent_control" :dup_data["field_name"],"parent_rule_id":dup_data["rule_id"],"rule_statement":" ".join(inside_if_list)})

                          lines_flag = False
                      inside_if_list = []
                      inside_if_flag = False
          vb_file.close()
          if not variable_flag:  # If not true , then it is a function( as per logic this if should be skipped,vijay has to confirm).
              # print("call function",if_statement_string)
            pass



def back_trace_fun(data):

  try:

    dup1_data=data

    function_name=data["function_name"]+'\s*[(].*'

    full_function_data=db.Code_behind_rules_1.find({"file_name":data["file_name"].split('.')[0]})

    rules_lines=db.Code_behind_rules.find({"file_name":data["file_name"].split('.')[0]})

    #trace Backing the function name using recursive function.


    for lines in full_function_data:

        for in_line in lines["source_statement"]:

          if (in_line.strip().startswith("Private ") and in_line.__contains__(" Sub ")) or (in_line.strip().startswith("Public ") and in_line.__contains__(" Shared ") and
              in_line.__contains__(" Function ")):
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
                      function_name_regexx_1 = re.findall(function_name, k, re.IGNORECASE)
                      if function_name_regexx_1!=[]:
                          db.rule_report.insert_one({"dependent_control" :dup_data["field_name"],"function_name":rec_data["function_name"],"parent_rule_id":dup_data["rule_id"],"rule_statement":rec_data["rule_statement"]})

              # calling the same function until setup page presentation.

              if  lines["function_name"].upper() =="SETUPPAGEPRESENTATION":
                 break

              back_trace_fun(lines)

  except Exception as e:
      exc_type, exc_obj, exc_tb = sys.exc_info()
      fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
      print(exc_type, fname, exc_tb.tb_lineno)



def Function_processer(function_name,dup_data):
    '''

    :Desc : Function is used to Fetch the Rules in Function used in if statemets.
    :param function_name:
    :param dup_data:
    :return:None - DB update of sub rules

    '''
    try:
        rule_statements = {}
        test_data= []

        # test_data.append(dup_data)
        output_json_value = {}

        function_name_line =dup_data['rule_statement'][0]
        function_name= re.sub('if', '', function_name_line, flags=re.IGNORECASE)
        function_name = function_name.split('(')[0].strip()
        ref_var_list = fetchimport_var(dup_data['file_name'])

        if function_name.__contains__('.'):
            '''
            If Funcion name contains a object refrence or filename
            '''
            # refrence_checker(dup_data['file_name'],function_name)

            pass
        else:

            rule_statements = Rule_Extractor(function_name,ref_var_list) #
        count = 0
        for key , value in rule_statements.items():
            Fields = ["rule_id","file_name","function_name","field_name","rule_statement","parent_rule_id","rule_description","rule_type","lob","dependent_control"]


            if rule_statements[key] != []:
                for rules in value:
                    count = count + 1
                    output_json_value["lob"] = dup_data["lob"]
                    output_json_value["file_name"] = dup_data["file_name"]
                    output_json_value["function_name"] = key.strip()
                    output_json_value["field_name"] = dup_data["field_name"]
                    output_json_value["rule_statement"] = " \n ".join(rules)
                    output_json_value["rule_description"] = dup_data["rule_description"]
                    output_json_value["parent_rule_id"] = dup_data["rule_id"]
                    output_json_value["rule_id"] = dup_data["rule_id"] + "."+str(count)
                    output_json_value["dependent_control"] = dup_data["dependent_control"]
                    output_json_value["rule_type"] = dup_data["rule_type"]

                    db.rule_report.insert_one(copy.deepcopy(output_json_value))
                    test_data.append(copy.deepcopy(output_json_value))
        print(json.dumps(test_data,indent=4))
    except Exception as e:
        exc_type, exc_obj, exc_tb = sys.exc_info()
        fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
        print(exc_type, fname, exc_tb.tb_lineno)
        print("Exception :", e)


def Rule_Extractor(function_name,ref_var_list):
    '''
    :Desc: Function will identify child function calls called inside the function
    :param: function_name:
    :return:
    '''

    rule_statements = {}
    cursor = db.Code_behind_rules_1.find_one({"function_name" :function_name},{'_id':0})
    function_list = tuple(db.Code_behind_rules_1.distinct("function_name"))

    called_fun_list=[]
    storage=[]
    if_counter = 0
    collect_flag = False

    for line in  cursor['source_statement'][1:]: #Start reading from Second line in the list

        #below shoret circuit expression is used to search for internal function calls.
        matches = [x for x in function_list if x in line]

        if matches != []:
            rule_statements["".join(matches)] = if_to_end_if_lines("".join(matches))
        elif line.strip().lower().startswith("if"):
            if function_name in rule_statements.keys():

                rule_statements[function_name+" "] =if_to_end_if_collecter(cursor['source_statement'],line) # to allow duplicates in Dictionary
            else:
                rule_statements[function_name] = if_to_end_if_collecter(cursor['source_statement'], line)



    '''
    add logic here for second level chaild functions having function name with refrence 
    
    obj.function()
    
    '''

    # for i in called_fun_list:
    #     rule_statements[i] = if_to_end_if_lines(i)

    print(json.dumps(rule_statements,indent=4))

    return rule_statements

def if_to_end_if_collecter(lines_list,line):
    if_counter = 0
    collect_flag = False
    storage = []
    level_list = []
    for ln in lines_list:
        if ln == line:
            collect_flag = True
            if_counter = if_counter + 1
        if collect_flag:
            storage.append(ln.strip())
        if ln.lower().strip().startswith("end if"):
            if_counter = if_counter - 1
            if if_counter == 0:
                break
    level_list.append(storage)
    return level_list

def if_to_end_if_lines(function_name):
    '''
    Desc: Function is used to Capture child rules in associated function
    :param function_name:
    :return:
    '''
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

def refrence_checker(filename,function_name):
    with open(code_location+"\\WebApplications\\"+filename + '.vb', 'r') as vb_file:
        for lines in vb_file.readlines():
            # print(lines)
            pass



def fetchimport_var(filename):
    ref_var_list=[]
    with open(code_location+"\\WebApplications\\"+filename + '.vb', 'r') as vb_file:
        for lines in vb_file.readlines():
            if lines.upper().__contains__("AS") and lines.__contains__(".Lob") or lines.__contains__(" Lob")  and (lines.strip().lower().startswith("private") or lines.strip().lower().startswith("dim")):
                if lines.split()[2].upper() == "AS":
                    line_list = lines.split()
                    if line_list[0].lower() == "private" or line_list[0].lower() == "dim":
                        ref_var_list.append(line_list[1])



    return tuple(ref_var_list)



for filename in glob.glob(os.path.join(vb_path,'*.aspx')):
    metadata=[]
    main(filename,metadata)
#     test_json ={
#
#     "function_name" : "setchkCpPfLocNtDescInd",
#     "field_name" : "chkCpPfLocNtDescInd",
#     "rule_statement" : [
#         "                If _oCPProp.ControlcboCpPfBlanketLmtCode() Then\n",
#         "                    .OnClientClick = \"chkCpPfLocNtDescInd_onclick();\"\n",
#         "                Else\n",
#         "                    .OnClientClick = \"disableTextbox('lbltxtCpPfLocNtDescLmt','chkCpPfLocNtDescInd','txtCpPfLocNtDescLmt')\"\n",
#         "                End If\n"
#     ],
#     "file_name" : "CPPropertyInput.aspx",
#     "rule_id" : "rule-2",
#     "parent_rule_id" : "",
#     "rule_description" : "",
#     "rule_type" : "server_side",
#     "lob" : "",
#     "dependent_control" : ""
# }
#
#     function_name =  "                If _oCPProp.ControlcboCpPfBlanketLmtCode() Then"
#
#
#     Function_processer(function_name , test_json)
