import config
from pymongo import MongoClient
import glob,os
import re
import json
import csv
import sys
mongoClient = MongoClient('localhost', 27017)
db = mongoClient['asp1']
vb = config.codebase_information['VB']['folder_name']
code_location =config.codebase_information['code_location']

vb_path=code_location+'\\'+vb

Version="Version-2,Contains drop down from kiran and kishore code also -12/8/20"

Version3="Version-3,Conatins class field for Checkbox,textbox,combobox,dropdown,textarea dated on 19/08/2020"

Version4="vesrsion-4, comprises derived Tooltip,multiple level derived tool tip  "

Version7="Ran for coustmer inout and found new patterns for clas field(mothesh) , nested panel and multiple panel item"

output_json={"filename":"","lob":"","section_id":"","section_name":"","CLAS_label":"","comments":"","screen_field":"","CLAS_field":"","type":"","required":"","for_control":"","maximun_length":"",
             "allowkeys":"","min-max":"","tooltip":"","enabled":"","dropdown_value":"","stored_value":"","error_message":""}
metadata=[]
def Remove(duplicate):
    final_list = []
    for list_iter in duplicate:
        if list_iter not in final_list:
            final_list.append(list_iter)
    return final_list

def main(filename,metadata):
    #for filename in glob.glob(os.path.join(vb_path,'*.ascx')):

      try:
        section_flag=False
        section_name=""
        sec_name=""
        nested_counter=0
        section_name_list=[]
        metadata=metadata
        filename=filename
        with open(filename,'r') as input_file:
            for line in input_file.readlines():

                if line.strip()=="":
                    continue

                expand_regexx=re.findall(r'^\s*<\s*.*\s*:\s*ExpandCollapsePanel\s.*',line,re.IGNORECASE)
                end_expand_regexx=re.findall(r'^\s*<\s*/\s*.*\s*:\s*ExpandCollapsePanel\s*>',line,re.IGNORECASE)
                stack_regxx=re.findall(r'^\s*<\s*.*\s*:\s*StackingPanel\s.*',line,re.IGNORECASE)
                end_stack_regexx=re.findall(r'^\s*<\s*/\s*.*\s*:\s*StackingPanel\s*>',line,re.IGNORECASE)

                if (line.__contains__("ExpandCollapsePanel ") and expand_regexx!=[]) or (line.__contains__("StackingPanel ") and stack_regxx!=[]):
                    nested_counter = nested_counter +1
                    section_flag=True
                    continue

                if end_expand_regexx!=[] or end_stack_regexx!=[] :

                    del section_name_list[-1]
                    nested_counter=nested_counter-1
                    section_flag=False

                if section_flag or nested_counter >= 1:

                    expand_item_regexx = re.findall(r'^\s*<\s*.*\s*:\s*ExpandCollapsePanelItem\s*.*id\s*=\s*"\s*[aA-zZ]*"', line,re.IGNORECASE)
                    stack_item_regxx=re.findall(r'^\s*<\s*.*\s*:\s*StackingPanelItem\s*.*id\s*=\s*"\s*[aA-zZ]*"', line,re.IGNORECASE)
                    dropdown_regexx = re.findall(r'^\s*<\s*[aA-zZ].*\s*:\s*DropdownList\s*id\s*=\s*"\s*[aA-zZ]*"', line,re.IGNORECASE)
                    combobox_regexx = re.findall(r'^\s*<\s*[aA-zZ].*\s*:\s*Combobox\s*id\s*=\s*"\s*[aA-zZ]*"', line,re.IGNORECASE)
                    radiobutton_regexx = re.findall(r'^\s*<\s*[aA-zZ].*\s*:\s*RadioButton\s*id\s*=\s*"\s*[aA-zZ]*"', line,
                                                    re.IGNORECASE)

                    checkbox_regexx=re.findall(r'^\s*<\s*[aA-zZ].*\s*:\s*CheckBox\s*id\s*=\s*"\s*[aA-zZ]*"', line,
                                                    re.IGNORECASE)

                    control_regexx=re.findall(r'^\s*<\s*[aA-zZ].*\s*:\s*.*\s*id\s*=\s*.*',line,re.IGNORECASE)
                    if expand_item_regexx!=[] or stack_item_regxx!=[]:


                        if expand_item_regexx!=[]:

                             section_name=expand_item_regexx[0].replace("id","ID").split("ID")[1].replace('"','')
                             section_name = section_name.replace('=', '')

                             section_name_list.append(section_name)

                             sec_name=section_name_fun(filename,section_name)


                        elif stack_item_regxx!=[]:

                            section_name = stack_item_regxx[0].replace("id","ID").split("ID")[1].replace('"', '')
                            section_name = section_name.replace('=', '')
                            section_name_list.append(section_name)

                            sec_name=section_name_fun(filename, section_name)

                    else:


                            sec_name = section_name_fun(filename, section_name_list[-1])



                    if control_regexx!=[]:

                            control_name=control_regexx[0].split(":")[1].split()[0]
                            #ignore_list=["StackingPanelItem","ExpandCollapsePanelItem","Header",'AccountInfoBar','MainTabBar',"LobTabBar","Notification","HiddenField",'ExpandCollapsePanel']

                            consider_list=["LABEL","CHECKBOX","DROPDOWNLIST","LINKBUTTON","RADIOBUTTON","TEXTAREA",
                                         "COMBOBOX","TEXTBOX","HIDDENFIELD"]
                            if control_name.upper() not in  consider_list:
                                continue
                            if control_name.upper()=="LABEL":

                                data_regexx=re.findall('\s*.*\s*id\s*=\s*"\s*[A-Za-z0-9]*"',line,re.IGNORECASE)
                                label_name = data_regexx[0].replace("id","ID").split("ID")[1].replace('"', '')
                                label_name=label_name.replace('=','')
                                label_name_1,for_control=label_name_fun(filename, label_name)

                                json_value = {"filename":filename.split('\\')[len(filename.split('\\'))-1],"lob":filename.split('\\')[len(filename.split('\\'))-2],"SectionID":section_name_list[-1],"SectionName": sec_name, "CLASLabel": label_name_1,"ScreenField":label_name, "CLASField": "", "Type": "label",
                                        "Required": "", "for_control": for_control, "Length": "",
                                        "Allowkeys": "", "Min-Max": "", "Tooltip": "", "Enable": "","DropdownValue":"","StoredValue":"","ErrorMessage":"","Comments":""}
                                label_name_1=""
                                metadata.append(json_value)

                            else :
                                #print(control_name,section_name_list)
                                data_regexx = re.findall('\s*.*\s*id\s*=\s*"\s*[A-Za-z0-9]*"', line, re.IGNORECASE)
                                dropdown_name = data_regexx[0].replace(" id"," ID").split("ID")[1].replace('"', '')
                                dropdown_name = dropdown_name.replace('=', '')
                                json_value = {"filename":filename.split('\\')[len(filename.split('\\'))-1],"lob":filename.split('\\')[len(filename.split('\\'))-2],"SectionID":section_name_list[-1],"SectionName": sec_name, "CLASLabel": "","ScreenField":dropdown_name,"CLASField": "", "Type": control_name,
                                        "Required": "", "for_control": "", "Length": "",
                                        "Allowkeys": "", "Min-Max": "", "Tooltip": "", "Enable": "","DropdownValue":"","StoredValue":"","ErrorMessage":"","Comments":""}
                                input_list=control_fun(filename, dropdown_name, json_value)
                                # print("Input33333333:",input_list)
                                if dropdown_regexx != [] or combobox_regexx != []:
                                    dropdown_vaues_list, storedvalues_list, tool_tip_value = dropdown_vaues(dropdown_name, filename)
                                    json_value["DropdownValue"] =  str(dropdown_vaues_list).replace("[","").replace("]", "").replace("]", "").replace('"',"").replace("'","")
                                    json_value["StoredValue"] = ",".join(storedvalues_list)

                                ######( Kishore radio button)
                                if radiobutton_regexx != []:
                                    # print("Radio::",input_list)
                                    radiobutton_fun(filename, dropdown_name, json_value,input_list)

                                if checkbox_regexx != []:
                                    print("Whattt:",checkbox_regexx)
                                    checkbox_fun(filename, dropdown_name, json_value,input_list)

                else:

                    dropdown_regexx = re.findall(r'^\s*<\s*[aA-zZ].*\s*:\s*DropdownList\s*id\s*=\s*"\s*[aA-zZ]*"', line,
                                                 re.IGNORECASE)
                    combobox_regexx = re.findall(r'^\s*<\s*[aA-zZ].*\s*:\s*Combobox\s*id\s*=\s*"\s*[aA-zZ]*"', line,
                                                 re.IGNORECASE)

                    radiobutton_regexx = re.findall(r'^\s*<\s*[aA-zZ].*\s*:\s*RadioButton\s*id\s*=\s*"\s*[aA-zZ]*"',
                                                     line,
                                                    re.IGNORECASE)

                    checkbox_regexx = re.findall(r'^\s*<\s*[aA-zZ].*\s*:\s*CheckBox\s*id\s*=\s*"\s*[aA-zZ]*"', line,
                                                 re.IGNORECASE)

                    control_regexx = re.findall(r'^\s*<\s*[aA-zZ].*\s*:\s*.*\s*id\s*=\s*.*', line, re.IGNORECASE)
                    if control_regexx!=[]:

                            control_name=control_regexx[0].split(":")[1].split()[0]

                            #ignore_list=["StackingPanelItem","ExpandCollapsePanelItem","Header",'AccountInfoBar','MainTabBar',"LobTabBar","Notification","HiddenField",'ExpandCollapsePanel']

                            consider_list = ["LABEL", "CHECKBOX", "DROPDOWNLIST", "LINKBUTTON", "RADIOBUTTON",
                                           "TEXTAREA",
                                           "COMBOBOX", "TEXTBOX","HIDDENFIELD"]
                            if control_name.upper() not in consider_list:
                                continue

                            if control_name.upper()=="LABEL":

                                data_regexx=re.findall('\s*.*\s*id\s*=\s*"\s*[A-Za-z0-9]*"',line,re.IGNORECASE)

                                label_name = data_regexx[0].replace("id","ID").split("ID")[1].replace('"', '')
                                label_name=label_name.replace('=','')

                                label_name_1,for_control=label_name_fun(filename, label_name)

                                json_value = {"filename":filename.split('\\')[len(filename.split('\\'))-1],"lob":filename.split('\\')[len(filename.split('\\'))-2],"SectionID":"","SectionName": "", "CLASLabel": label_name_1,"ScreenField":label_name, "CLASField": "", "Type": "label",
                                        "Required": "", "for_control": for_control, "Length": "",
                                        "Allowkeys": "", "Min-Max": "", "Tooltip": "", "Enable": "","DropdownValue":"","StoredValue":"","ErrorMessage":"","Comments":""}
                                label_name_1=""
                                metadata.append(json_value)

                            else :

                                data_regexx = re.findall('\s*.*\s*id\s*=\s*"\s*[A-Za-z0-9]*"', line.strip(), re.IGNORECASE)

                                dropdown_name = data_regexx[0].replace(" id"," ID").split("ID")[1].replace('"', '')
                                dropdown_name = dropdown_name.replace('=', '')

                                json_value = {"filename":filename.split('\\')[len(filename.split('\\'))-1],"lob":filename.split('\\')[len(filename.split('\\'))-2],"SectionID":"","SectionName": "", "CLASLabel": "","ScreenField":dropdown_name,"CLASField": "", "Type": control_name,
                                        "Required": "", "for_control": "", "Length": "",
                                        "Allowkeys": "", "Min-Max": "", "Tooltip": "", "Enable": "","DropdownValue":"","StoredValue":"","ErrorMessage":"","Comments":""}
                                input_list=control_fun(filename, dropdown_name, json_value)
                                # print("Input:",input_list)
                                if dropdown_regexx != [] or combobox_regexx != []:
                                    dropdown_vaues_list, storedvalues_list, tool_tip_value = dropdown_vaues(dropdown_name, filename)

                                    json_value["DropdownValue"] = str(dropdown_vaues_list).replace("[", "").replace("]","").replace('"', "").replace("'", "")
                                    json_value["StoredValue"] = ",".join(storedvalues_list).replace('"', "")


                                if radiobutton_regexx != []:
                                    radiobutton_fun(filename, dropdown_name, json_value,input_list)

                                if checkbox_regexx != []:
                                    print("Whennnn:",checkbox_regexx)
                                    checkbox_fun(filename, dropdown_name, json_value,input_list)



        print(json.dumps(metadata,indent=4))

        if metadata!=[]:
            if db.drop_collection("screen_data"):
                print("deleted")

            if db.screen_data.insert_many(metadata):
                print("inserted")



        key = {"filename","lob","SectionID" ,"SectionName", "CLASLabel",
                "ScreenField", "CLASField", "Type",
                "Required", "for_control", "Length",
                "Allowkeys", "Min-Max", "Tooltip", "Enable", "DropdownValue", "StoredValue","_id","ErrorMessage","Comments"}


        screen_data=db.screen_data.find({"$and":[{"Type":"label"},{"for_control":{"$ne":""}}]})

        for data1 in screen_data:
            screen_data1=db.screen_data.update_one({"ScreenField":data1["for_control"].strip()},{"$set":{"CLASLabel":data1["CLASLabel"]}})
            db.screen_data.delete_one({"_id":data1["_id"]})


        metadata1 = db.screen_data.find({}, {"_id": 0, "SectionID": 1, "SectionName": 1, "CLASLabel": 1,
                                             "ScreenField": 1, "CLASField": 1, "Type": 1,
                                             "Required": 1, "Length": 1,
                                             "Allowkeys": 1, "Min-Max": 1, "Tooltip": 1, "Enable": 1,
                                             "DropdownValue": 1, "StoredValue": 1, "ErrorMessage": 1,
                                             "Comments": 1,"filename":1,"lob":1})
        out_data = []

        for screen_data in metadata1:
            out_data.append(screen_data)

        with open("screen_fields" + '.csv', 'w', newline="") as output_file:
            Fields = ["filename","lob","SectionID", "SectionName", "CLASLabel",
                      "ScreenField", "CLASField", "Type",
                      "Required", "Length",
                      "Allowkeys", "Min-Max", "Tooltip", "Enable", "DropdownValue", "StoredValue", "ErrorMessage",
                      "Comments"]
            dict_writer = csv.DictWriter(output_file, fieldnames=Fields)
            dict_writer.writeheader()
            dict_writer.writerows(out_data)

      except Exception as e:
          exc_type, exc_obj, exc_tb = sys.exc_info()
          fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
          print(exc_type, fname, exc_tb.tb_lineno)

          pass


# def checkbox_fun(filename,dropdown_name,json_value):
#     with open(filename + '.vb', 'r') as vb_file:
#         checkboxvalue_Flag = False
#         checkpara_name = 'With'+' '+dropdown_name
#         endwith_check  = 'End With'
#         inline_check_flag = False
#         counter = 0
#         check_list = []
#         if_collector = ""
#         keywords_for_check_stored = ['Yes"','No"','"Y"','"N"','Status.YES_ABBREIVATED','Status.NO_ ABBREIVATED','Constants.SHORT_Yes','Constants.SHORT_No',
#                                      'CL_EqualsYesAbbrevation','CL_EqualsNoAbbrevation','CL_YesAbbreviation','CL_NoAbbreviation']
#         for lines in vb_file.readlines():
#             if counter == 1:
#                 break
#             if checkboxvalue_Flag:
#                 if re.search('.*If.*',lines,re.IGNORECASE):
#                     if not re.search('.*End If.*',lines,re.IGNORECASE):
#                         if_collector = lines
#                         inline_check_flag = True
#                         continue
#                 if inline_check_flag:
#                     if re.search('.*Checked.*',lines):
#                         for ext in keywords_for_check_stored:
#                             if ext in if_collector and if_collector.__contains__("="):
#                                 stored_value = ext.replace('"','')
#                                 if_collector = ''
#                                 json_value["StoredValue"] = stored_value
#                                 break
#                             elif not if_collector.__contains__("=") and ext in if_collector:
#                                 stored_value = ext
#                                 if_collector = ''
#                                 json_value["StoredValue"] = stored_value
#                                 break
#
#                 if re.search('.*Checked.*',lines) and inline_check_flag == False:
#                    lines = lines.split(".")
#                    stored_value = lines[-1].strip("\n")
#                    json_value["StoredValue"] = stored_value
#                    continue
#
#                 if re.search(endwith_check, lines):
#                     checkboxvalue_Flag = False
#                     inline_check_flag = False
#                     counter = counter + 1
#                     continue
#
#             if re.search(checkpara_name,lines,re.IGNORECASE):
#                 checkboxvalue_Flag = True
#
#     #print("METADATA:",json_value)
#     vb_file.close()


def checkbox_fun(filename,dropdown_name,json_value,input_list):
   try:
        with open(filename + '.vb', 'r') as vb_file:
            print("Dropdown:",dropdown_name)
            checkboxvalue_Flag = False
            checkpara_name = 'With'+' '+dropdown_name
            endwith_check  = 'End With'
            check_box_regexx = 'If' + ' ' + dropdown_name + '.Checked'
            print("Kishore:",check_box_regexx)
            rare_check_box_regexx = '=' + ' ' + dropdown_name + '.Checked'
            checkboxcall_Flag = False
            inline_check_flag = False
            global yes_check_flag
            yes_check_flag = 1
            counter = 0
            nested_counter = 0
            classvalue_check = ""
            check_list = []
            classfield_check_list = []
            if_collector = ""
            global keywords_for_check_stored
            keywords_for_check_stored = ['Yes"','No"','"Y"','"N"','Status.YES_ABBREIVATED','Status.NO_ ABBREIVATED','Constants.SHORT_Yes','Constants.SHORT_No',
                                         'CL_EqualsYesAbbrevation','CL_EqualsNoAbbrevation','CL_YesAbbreviation','CL_NoAbbreviation']
            # print("Checkkkkkkk:",input_list)
            for index,lines in enumerate(vb_file.readlines()):
                # print("Data:",lines)
                # print("1")
                # if counter == 1:
                #     break

                if checkboxcall_Flag:
                    print("2")
                    if re.search('.*End If.*',lines,re.IGNORECASE):
                        checkboxcall_Flag = False
                        counter = counter + 1
                        continue

                    if re.search('.*If.*',lines,re.IGNORECASE) and nested_counter >= 1:
                        checkboxcall_Flag = False
                        counter = counter + 1
                        nested_counter = 0
                        continue


                    if re.search('.*Fields.*', lines, re.IGNORECASE) or re.search('.*Input.*', lines, re.IGNORECASE):
                        nested_counter = nested_counter + 1

                        field_list = lines.split("(")
                        field_value = field_list[1]
                        final_field_value = field_value.split(")")[0]
                        # print("Field_list:", final_field_value)
                        if final_field_value.__contains__('"'):
                            final_field_value = final_field_value.replace('"',"")
                            # print("Inner:",final_field_value)
                            if final_field_value in classfield_check_list:
                                continue
                            else:
                                classfield_check_list.append(final_field_value)
                                # metadata.append({"ClASField":final_field_value})
                                if len(classfield_check_list) == 1:
                                    json_value.update({"CLASField": final_field_value})
                                    print("Classs:",final_field_value)

                                else:
                                    if len(classfield_check_list)>1:
                                        classfield_check_list_temp = []
                                        for index ,i in enumerate(classfield_check_list):

                                            classfield_check_list_temp.append(str(index+1)+'.)'+ i)
                                        json_value.update({"CLASField": "\n".join(classfield_check_list_temp)})



                                # metadata.append(json_value)
                                # final_field_value = ""
                        else:
                            out1 = clas_field_fun(input_list, final_field_value)
                            if out1 in classfield_check_list:
                                continue
                            else:

                                classfield_check_list.append(out1)
                                if len(classfield_check_list) == 1:
                                    json_value.update({"CLASField": out1})
                                else:
                                    json_value.update({"CLASField": classfield_check_list})
                                # out1 = ""
                            # else:
                            #     classvalue_check = out1
                            #     out1 = ""
                                # print("Outer:",out1)


                if checkboxvalue_Flag:
                    print("3")
                    if re.search('.*Checked.*',lines) and inline_check_flag == False:
                       # print("CHK2:",lines)

                       if lines.__contains__("String.Equals"):
                           print("4")
                           lines = lines.split("(")
                           # print("CHK3_inner:", lines)
                           key_value = lines[-1]
                           key_value = key_value.split(")")[0].replace('"',"")
                           # print("KEEYyyy:",key_value)
                           func_call = lines[-2]
                           # print("Jk:",key_value,func_call)

                           key_1,key_2_func = stored_value_new(input_list,func_call)
                           # print("Key1:",key_1,key_2_func)
                           # class_value = key_2
                           # func_value = key_1

                           VB_PATH = find_VBpath(key_1,key_2_func,filename)
                           # print("Inside:",VB_PATH,key_2,key_value)
                           tool_tip = tooltipdervived_var(VB_PATH, key_2_func, key_value)
                           json_value["StoredValue"] = tool_tip
                           print("VB:",tool_tip)
                           counter = counter + 1
                           checkboxvalue_Flag = False
                           print("5")
                           continue

                       else:
                           lines = lines.split(".")
                           # print("CHK3:",lines)
                           stored_value = lines[-1].strip("\n")

                           json_value["StoredValue"] = stored_value
                           # counter = counter + 1
                       continue




                    if re.search('.*If.*',lines,re.IGNORECASE):
                        if not re.search('.*End If.*',lines,re.IGNORECASE):
                            print("6666666666666:",lines)
                            if_collector = lines
                            inline_check_flag = True
                            continue
                    if inline_check_flag:
                        if re.search('.*Checked.*',lines):
                            print("1000000000000:",lines)
                            for ext in keywords_for_check_stored:
                                if ext in if_collector and if_collector.__contains__("="):
                                    stored_value = ext.replace('"','')
                                    if_collector = ''
                                    json_value["StoredValue"] = stored_value
                                    break
                                elif not if_collector.__contains__("=") and ext in if_collector:
                                    stored_value = ext
                                    if_collector = ''
                                    json_value["StoredValue"] = stored_value
                                    break
                                elif if_collector.__contains__("=") and if_collector.__contains__("Checked"):
                                    if_collector_list = if_collector.split("=")
                                    if_collector_newlist = if_collector_list[0]
                                    if_collector_final = if_collector_newlist.split("(")
                                    key_value = if_collector_final[-1].replace('"',"").replace(')',"")

                                    # print("KEEYyyy:",key_value)
                                    func_call = if_collector_final[-2]
                                    # print("Jk:",key_value,func_call)

                                    key_1, key_2_func = stored_value_new(input_list, func_call)
                                    # print("Key1:",key_1,key_2_func)
                                    # class_value = key_2
                                    # func_value = key_1

                                    VB_PATH = find_VBpath(key_1, key_2_func, filename)
                                    # print("Inside:",VB_PATH,key_2,key_value)
                                    tool_tip = tooltipdervived_var(VB_PATH, key_2_func, key_value)
                                    json_value["StoredValue"] = tool_tip
                                    print("VB:", tool_tip)
                                    counter = counter + 1
                                    checkboxvalue_Flag = False
                                    print("5")
                                    continue

                    if re.search(endwith_check, lines):
                        checkboxvalue_Flag = False
                        inline_check_flag = False
                        counter = counter + 1
                        continue

                if re.search(check_box_regexx,lines,re.IGNORECASE):

                    print("called_check:",check_box_regexx)
                    checkboxcall_Flag = True
                    continue

                if re.search(rare_check_box_regexx,lines,re.IGNORECASE):
                    print("8")
                    if re.search('.*Fields.*', lines, re.IGNORECASE) or re.search('.*Input.*', lines, re.IGNORECASE):
                        field_list = lines.split("(")
                        field_value = field_list[1]
                        final_field_value = field_value.split(")")[0]
                        # print("Field_list:", final_field_value)
                        if final_field_value.__contains__('"'):
                            final_field_value = final_field_value.replace('"', "")
                            # print("Inner:", final_field_value)
                            if final_field_value in classfield_check_list:
                                continue
                            else:
                                classfield_check_list.append(final_field_value)
                                json_value["CLASField"] = final_field_value
                                final_field_value = ""
                        else:
                            out1 = clas_field_fun(input_list, final_field_value)
                            if out1 in classfield_check_list:
                                continue
                            else:
                                classfield_check_list.append(out1)
                                json_value.update({"CLASField": out1})
                                out1 = ""

                if re.search(checkpara_name,lines,re.IGNORECASE):
                    # print("CHK1:",lines)
                    print("7")
                    checkboxvalue_Flag = True

        #print("METADATA:",json_value)
        vb_file.close()
   except Exception as e:
       exc_type, exc_obj, exc_tb = sys.exc_info()
       fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
       print(exc_type, fname, exc_tb.tb_lineno)


# def tooltip_derived(tooltip,filename):
#     try:
#         # print(tooltip)
#         name_val_var = tooltip.split("(")[0]
#         keyvalue = tooltip.split("(")[1].replace(")","")
#
#         with open(filename + '.vb', 'r') as vb_file:
#             for lines in vb_file.readlines():
#                 if lines.strip().startswith("'"):
#                     continue
#                 # print(lines.split("=")[0],name_val_var)
#                 if lines.split("=")[0].strip().__contains__(name_val_var.strip()) and lines.__contains__("="):
#                     VBpath_finder = lines.split("=")[-1]
#                     VBpath_class_var = VBpath_finder.split(".")[0]
#                     VBpath_funtion_name = VBpath_finder.split(".")[1].split("(")[0]
#                     VB_PATH = find_VBpath(VBpath_class_var, VBpath_funtion_name, filename)
#                     tool_tip = tooltipdervived_var(VB_PATH,VBpath_funtion_name,keyvalue)
#                     return  tool_tip
#     except Exception as e:
#         exc_type, exc_obj, exc_tb = sys.exc_info()
#         fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
#         print(exc_type, fname, exc_tb.tb_lineno)
#         print(e)

def tooltipdervived_var(VB_PATH,VBpath_funtion_name,keyvalue):
    fun_storage = []
    fun_dict = {}
    tooltip = []
    internal_const = False
    # print("K1111:",VBpath_funtion_name,keyvalue)

    try:
        collect_flag = False
        if VB_PATH.startswith(code_location):
            VB_PATH = "\\".join(VB_PATH.split("\\")[2:])

        with open(code_location + "\\" + VB_PATH, 'r') as file:
            filename = code_location + "\\" + VB_PATH

            for lines in file:
                if lines.strip().startswith("'"):
                    continue
                if re.search("Function " + VBpath_funtion_name, lines):
                    collect_flag = True

                if lines.__contains__("End function"):
                    if collect_flag == True:
                        fun_storage.append(lines)
                    fun_dict[VBpath_funtion_name] = fun_storage
                    collect_flag = False


                if collect_flag:
                    fun_storage.append(lines)
        if fun_storage != []:
            for ln in fun_storage:
                if ln.strip().startswith("Return"):
                    if ln.__contains__("."):
                        var_name = ln.split(".")[0].replace("Return", "").strip() #return var with function
                        # print("Variableee:",var_name)
                        break
                    else:
                        var_name = ln.split()[-1].strip()#direct return
                        # print("Varrrr:", var_name)
                        break

            for lin in fun_storage:
            #     print("WInning")
    #
                # print(fun_storage)
                if lin.__contains__(var_name + ".Add"):#if line is having add function

                    if lin.__contains__(var_name.strip() + ".Add"+'('):
                        #key present in add
                        if lin.__contains__(var_name.strip() + ".Add"+'("'+keyvalue.strip()+'"'):
                            tooltip.append(lin.split(".Add")[-1].split(',')[1].strip()[:-1])
                            # print(tooltip)


                        else:
                            #constent logic
                            const_val = lin.split("Add")[-1].split(',')[0].replace("(","").replace('"',"")
                            with open(code_location + "\\" + VB_PATH, 'r') as file1:
                                for lines1 in file1:
                                    if lines1.__contains__(const_val) and lines1.__contains__("=") and lines1.strip().__contains__(keyvalue.strip()):
                                        tooltip.append(lin.split(".Add")[-1].split(',')[1].strip()[:-1])


                                    else:
                                        #constent glossary search
                                        data = db.glossary_vb.find_one({"ConstantsVariable": const_val })

                                        if data != None:
                                            if data['ConstantsMeaning'] == keyvalue:
                                                tooltip.append(lin.split(".Add")[-1].split(',')[1].strip()[:-1])




                else:
                    #mulitilevel function calls
                    if lin.__contains__(var_name +",")  or  lin.__contains__(", "+var_name):# passing as parameter
                        # print(lin)
                        x = lin.split('(')[1].split(')')[0].replace(" ","")
                        parm_pos = x.split(",").index(var_name)
                        # print("POSSSS:",parm_pos)
                        if lin.split("(")[0].__contains__("."):#only for tool tip
                            obj_name = lin.split("(")[0].split(".")[0]
                            function_name = lin.split("(")[0].split(".")[1]
                            # print(obj_name,function_name)

                            path = find_tool_tip_file(obj_name,filename)
                            with_name_by_Parm_pos,with_flag =get_withname(path,function_name,parm_pos)

                            tooltip.append(tooltipdervived_var(path,with_name_by_Parm_pos,keyvalue))
                            break
                        else:
                            lin.split("(")[0].__contains__(var_name+",") or lin.split("(")[0].__contains__(","+var_name)
                            function_name = lin.split("(")[0].strip()
                            # print("Kiran:",function_name)
                            # same file functions
                            path =VB_PATH
                            with_name_by_Parm_pos,with_flag = get_withname(path, function_name, parm_pos)
                            # print("Withhhh:",with_name_by_Parm_pos,with_flag)
                            if with_flag:
                                tooltip.append(tooltipdervived_var(filename, with_name_by_Parm_pos,keyvalue))
                            elif with_flag == False:
                                tool_tip =tooltipdervived_var1(filename, with_name_by_Parm_pos, function_name, keyvalue)

                                if tool_tip in keywords_for_check_stored:
                                    return tool_tip

                                if tool_tip != None:
                                    tooltip.append(tool_tip)
                                    break






        else:

            sub_storage = fetch_sub(VBpath_funtion_name, code_location+'\\'+VB_PATH)
            fullsubstorage = fetch_full_sub(VBpath_funtion_name, code_location+'\\'+VB_PATH)
            fullsubstorage1 = fullsubstorage[::-1]  # reversrsing list using slice operator
            storage = fullsubstorage1 + sub_storage
            # print(storage)
            for lin in storage:
                if not lin.__contains__(".Add"):
                    continue

                if lin.__contains__(".Add" + '("' + keyvalue + '"'):
                    tooltip.append(lin.split(".Add")[-1].split(',')[1].strip()[:-1])
                    # print(tooltip)

                else:
                    # constent logic
                    const_val = lin.split("Add")[-1].split(',')[0].replace("(", "").replace('"', "")
                    with open(code_location + "\\" + VB_PATH, 'r') as file1:
                        for lines1 in file1:
                            if lines1.strip().startswith("'"):
                                continue
                            if lines1.__contains__(const_val) and lines1.__contains__("="):
                                tooltip.append(lin.split(".Add")[-1].split(',')[1].strip()[:-1])
                                internal_const = True

                            else:
                                continue

                        if internal_const == False:
                            # constent glossary search
                            data = db.glossary_vb.find_one({"ConstantsVariable": const_val})
                            if  data['ConstantsMeaning'] == keyvalue:
                                tooltip.append(lin.split(".Add")[-1].split(',')[1].strip()[:-1])

        if len(Remove(tooltip))>1:#formating the output with \n
            tooltip2 = []

            for index,i in enumerate(tooltip):
                index = index +1

                if index == 1:
                    tooltip2.append(i.replace('"',""))

                else:

                    tooltip2.append(str(index)+".)"+i.replace('"',""))
            return "\n".join(tooltip2)

        return " ".join(Remove(tooltip))
    except FileNotFoundError as e:

        tooltip =  str(e)
        return tooltip
    except Exception as e :
        exc_type, exc_obj, exc_tb = sys.exc_info()
        fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
        print(exc_type, fname, exc_tb.tb_lineno)
        print(e)

def tooltipdervived_var1(path, with_name_by_Parm_pos,function_name, keyvalue):
    storage = no_with_storage_function(path,function_name)
    # print("Storageeee:",storage)
    for line in storage:
        if line.__contains__(with_name_by_Parm_pos+".") and line.__contains__(keyvalue):
            # print("Lineeee:",line)
            line = line.split('(')[1].split(')')[0]
            # print("Linesssssssssss:",line)
            if line.split(",")[1].startswith('"'):
                return line.split(",")[1]

            else:
                ref_var =line.split(",")[1]
                # print("Reffff_vaarrr:",ref_var)
                for line1 in storage:
                    if yes_check_flag == 1:
                        # print("Winning")
                        stored_value = checkbox_derivedvar(storage, ref_var)
                        # print("Finalll:",stored_value)
                        return stored_value
                    if line1.__contains__("Dim") and line1.__contains__(ref_var):
                        return line1.split("=")[-1]



def checkbox_derivedvar(storage,ref_var):
    rare_check_flag = False
    if_condition_collector = ""
    rare_check_counter = 0
    stored_value = ""
    # print("Successsss")
    for data in storage:
        # print("Dataaaa:",data)
        if rare_check_counter == 1:
            rare_check_flag = False
            rare_check_counter = 0

        if rare_check_flag:
            if data.__contains__("Checked") and data.__contains__(ref_var):
                stored_value = if_condition_collector.split(".Value")[1].replace('"','').replace(",","").replace(")","")
                stored_value = stored_value.split()[0]
                rare_check_counter = rare_check_counter + 1
                # print("valueee:",stored_value)
                continue

        if re.search('.*If.*',data,re.IGNORECASE):
            if not re.search('.*End If.*',data,re.IGNORECASE):
                # print("IFFFFFFFFFF:",data)
                if_condition_collector = data
                rare_check_flag = True

    return stored_value

def no_with_storage_function(filename,function_name):
    sub_storage = []
    func_found = False

    if filename.lower().endswith(".vb"):
        filename = "\\".join(filename.split("\\")[:-1]) + "\\" + filename.split("\\")[-1].replace(".VB", "")
    with open(filename + '.VB', 'r') as vb_file:
        for lines in vb_file.readlines():
            if lines.__contains__("Sub") and lines.__contains__(function_name):
                func_found =True
            if  func_found:
                sub_storage.append(lines)
            if lines.__contains__("End Sub"):
                func_found = False
    return sub_storage



def stored_value_new(input_list,func_call):
    # print("Data:", input_list)

    func_search = func_call + " "+"="
    # print("FUNC:",func_search)
    key_1 = ""
    key_2 = ""
    for data in input_list:
        # print("Data:",data)
        if re.search(func_search,data,re.IGNORECASE):
            # print("FUNC:",data)

            data_list = data.split(".")
            key_1 = data_list[0]
            key_1 = key_1.split("=")[1]
            key_2 = data_list[1]
            key_2 = key_2.split("(")[0]
            # print("11111111111111111111:",key_1,key_2)

        continue

    return key_1,key_2



def radiobutton_fun(filename,dropdown_name,json,input_list):
    with open(filename + '.vb', 'r') as vb_file:

        storedvalue_Flag = False
        counter = 0
        radiopara_name = 'With'+' '+dropdown_name
        endwith_radio  = 'End With'
        radio_box_regexx = 'If' + ' ' + dropdown_name + '.Checked'
        radioboxcall_Flag = False
        nested_counter = 0
        classfield_radio_list = []

        for lines in vb_file.readlines():
            # if counter == 1:
            #     storedvalue_Flag = False
            #
            #     break

            if radioboxcall_Flag:
                print("22")
                if re.search('.*End If.*', lines, re.IGNORECASE):
                    radioboxcall_Flag = False
                    counter = counter + 1
                    continue

                if re.search('.*If.*', lines, re.IGNORECASE) and nested_counter >= 1:
                    radioboxcall_Flag = False
                    counter = counter + 1
                    nested_counter = 0
                    continue

                if re.search('.*Fields.*', lines, re.IGNORECASE) or re.search('.*Input.*', lines, re.IGNORECASE):
                    nested_counter = nested_counter + 1

                    field_list = lines.split("(")
                    field_value = field_list[1]
                    final_field_value = field_value.split(")")[0]
                    # print("Field_list:", final_field_value)
                    if final_field_value.__contains__('"'):
                        final_field_value = final_field_value.replace('"', "")
                        # print("Inner:",final_field_value)
                        if final_field_value in classfield_radio_list:
                            continue
                        else:
                            classfield_radio_list.append(final_field_value)
                            # metadata.append({"ClASField":final_field_value})
                            if len(classfield_radio_list) == 1:
                                json.update({"CLASField": final_field_value})
                                print("radiooo_Classs:", final_field_value)

                            else:
                                if len(classfield_radio_list) > 1:
                                    classfield_check_list_temp = []
                                    for index, i in enumerate(classfield_radio_list):
                                        classfield_check_list_temp.append(str(index + 1) + '.)' + i)
                                    json.update({"CLASField": "\n".join(classfield_check_list_temp)})

                            # metadata.append(json_value)
                            # final_field_value = ""
                    else:
                        out1 = clas_field_fun(input_list, final_field_value)
                        if out1 in classfield_radio_list:
                            continue
                        else:

                            classfield_radio_list.append(out1)
                            if len(classfield_radio_list) == 1:
                                json.update({"CLASField": out1})
                            else:
                                json.update({"CLASField": classfield_radio_list})

            if storedvalue_Flag:
                if lines.__contains__(".GroupName"):
                    groupname = lines.split("=")[1].replace('"',"").strip('\n')
                    output = radio_field_fun(input_list, groupname)
                    json.update({"CLASField": output})

                if lines.__contains__(".Value"):
                    stored_value = lines.split("=")[1].strip('\n')
                    json["StoredValue"] = stored_value.replace('"',"").strip()

                if re.search(endwith_radio, lines):
                    storedvalue_Flag = False
                    counter = counter + 1
                    continue

                if re.search('.*Checked.*', lines) :
                    # print("CHK2:",lines)

                    if lines.__contains__("String.Equals"):
                        print("4")
                        lines = lines.split("(")
                        # print("CHK3_inner:", lines)
                        key_value = lines[-1]
                        key_value = key_value.split(")")[0].replace('"', "")
                        # print("KEEYyyy:",key_value)
                        func_call = lines[-2]
                        # print("Jk:",key_value,func_call)

                        key_1, key_2_func = stored_value_new(input_list, func_call)
                        # print("Key1:",key_1,key_2_func)
                        # class_value = key_2
                        # func_value = key_1

                        VB_PATH = find_VBpath(key_1, key_2_func, filename)
                        # print("Inside:",VB_PATH,key_2,key_value)
                        tool_tip = tooltipdervived_var(VB_PATH, key_2_func, key_value)
                        json["StoredValue"] = tool_tip
                        print("VB:", tool_tip)
                        # counter = counter + 1
                        checkboxvalue_Flag = False
                        print("5")
                        continue


            if re.search(radio_box_regexx, lines, re.IGNORECASE):
                print("called_radio:", radio_box_regexx)
                print("11")
                radioboxcall_Flag = True
                continue

            if re.search(radiopara_name,lines,re.IGNORECASE):
                storedvalue_Flag = True

    vb_file.close()


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
        label_name_3=[]
        k=0
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

                        #label_name_3 = label_name_2[0].split("=")[1].replace('"', '')
                        label_name_3_1 = label_name_2[0].split("=")
                        k = 0
                        for i in range(len(label_name_3_1)):
                            if k == 0:
                                k = k + 1
                                continue
                            else:
                                if len(label_name_3_1)==2:
                                  label_name_3.append(label_name_3_1[i].strip()[1:len(label_name_3_1[i])-2])
                                elif len(label_name_3_1)>2:
                                    if i==1:
                                        label_name_3.append(label_name_3_1[i].strip()[1:])
                                    elif i == len(label_name_3_1)-1:
                                        label_name_3.append(label_name_3_1[i].strip()[0:len(label_name_3_1[i])-2])
                                    else:
                                        label_name_3.append(label_name_3_1[i])

                    if for_control_regexx!=[]:
                        for_control_value = for_control_regexx[0].split("=")[1].replace('"', '')
            vb_file.close()


        if label_name_3==[] and for_control_value=="":
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
                            label_name_3_1 = label_name_2[0].split("=")
                            k = 0
                            # for i in label_name_3_1:
                            #     if k==0:
                            #         k = k + 1
                            #         continue
                            #     else:
                            #         label_name_3.append(i.replace('"',''))
                            for i in range(len(label_name_3_1)):
                                if k == 0:
                                    k = k + 1
                                    continue
                                else:
                                    if len(label_name_3_1) == 2:
                                        label_name_3.append(label_name_3_1[i].strip()[1:len(label_name_3_1[i]) - 2])

                                    elif len(label_name_3_1) > 2:
                                        if i == 1:
                                            label_name_3.append(label_name_3_1[i].strip()[1:])
                                        elif i == len(label_name_3_1) - 1:
                                            label_name_3.append(label_name_3_1[i].strip()[0:len(label_name_3_1[i])- 2])
                                        else:
                                            label_name_3.append(label_name_3_1[i])


                        if for_control_regexx != []:
                            for_control_value = for_control_regexx[0].split("=")[1].replace('"', '')

                    if for_control_value !="" and label_name_3!=[]:
                        break
                vb_file.close()

        if label_name_3==[] and for_control_value=="":
            with open(filename + '.vb', 'r') as vb_file:
                label_name_1 = '\s*'+ label_name+'\.ForControl\s*=\s*".*"'
                for_control_reg='\s*'+label_name+'\.Text\s*=\s*".*"'
                for lines in vb_file.readlines():
                    if lines.strip() == "":
                        continue
                    label_name_2 = re.search(label_name_1, lines)
                    print(for_control_reg)
                    for_control_reg=re.search(for_control_reg,lines)


                    if label_name_2:
                        label_name_2 = re.findall(r'^\s*.*\.Text\s*=\s*".*"', lines,re.IGNORECASE)
                        if label_name_2!=[]:
                            #label_name_3 = label_name_2[0].split("=")[1].replace('"', '')
                            label_name_3_1 = label_name_2[0].split("=")
                            k = 0
                            # for i in label_name_3_1:
                            #     if k==0:
                            #         k=k+1
                            #         continue
                            #     else:
                            #         label_name_3.append(i.replace('"',''))
                            for i in range(len(label_name_3_1)):
                                if k == 0:
                                    k = k + 1
                                    continue
                                else:
                                    if len(label_name_3_1) == 2:
                                        label_name_3.append(label_name_3_1[i].strip()[1:len(label_name_3_1[i]) - 2])
                                    elif len(label_name_3_1) > 2:
                                        if i == 1:
                                            label_name_3.append(label_name_3_1[i].strip()[1:])
                                        elif i == len(label_name_3_1) - 1:
                                            label_name_3.append(label_name_3_1[i].strip()[0:len(label_name_3_1[i]) - 2])
                                        else:
                                            label_name_3.append(label_name_3_1[i])

                    if for_control_reg:
                        for_control_regexx = re.findall(r'\s*.*\.ForControl\s*=\s*.*', lines,re.IGNORECASE)
                        if for_control_regexx!=[]:
                           for_control_value = for_control_regexx[0].split("=")[1].replace('"', '')

                    if for_control_value !="" and label_name_3!=[]:
                        break
            vb.close()

        return '='.join(label_name_3),for_control_value

    except Exception as e:
        exc_type, exc_obj, exc_tb = sys.exc_info()
        fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
        print(exc_type, fname, exc_tb.tb_lineno)



def control_fun(filename, textbox_name, json_value):
    try:
        maxlist = []
        tooltip_list=[]
        section_value_flag = False
        input_list=[]

        with open(filename+'.vb','r') as vb_file:
            for lines in vb_file.readlines():
                input_list.append(lines)
        vb_file.close()

        with open(filename + '.vb', 'r') as vb_file:
            textbox_name_1 = 'set' + textbox_name + '\s*\(\)'
            count=0
            for lines in vb_file.readlines():

                if json_value["Type"].lower() == "textbox" or json_value["Type"].lower()=="combobox" or json_value["Type"].lower()=="textarea":
                    json_value=clas_field_fun_1(lines,textbox_name,json_value,input_list)


                if json_value["Type"].lower()=="dropdownlist":
                    json_value=dropdown_clas_field(lines,textbox_name,json_value,input_list)

                    # text_box_regexx='\s*.*=\s*'+textbox_name+'\.Text.*'
                    # text_box_value_regexx=re.findall(text_box_regexx,lines)
                    #
                    # if text_box_value_regexx!=[]:
                    #
                    #     text_box_value=text_box_value_regexx[0].split('=')[0]
                    #
                    #     field_regexx=re.findall(r'\s*.*\.Fields\s*(.*)\.Value\s*',text_box_value)
                    #
                    #     variable_regexx=re.findall(r'\s*\t*Dim\s*[A0-Z9]*\s*',text_box_value,re.IGNORECASE)
                    #
                    #     Input_regexx=re.findall(r'\s*.*\.Input\s*(.*)\.Value\s*',text_box_value)
                    #
                    #     if field_regexx!=[]:
                    #
                    #         if field_regexx[0].__contains__('"'):
                    #             clas_field_value=field_regexx[0].replace('(',"").replace('"',"").replace(")","")
                    #             json_value.update({"CLASField": clas_field_value})
                    #         else:
                    #
                    #             field_var=field_regexx[0].replace('(',"").replace(')',"").strip()
                    #             out1=clas_field_fun(input_list,field_var)
                    #             json_value.update({"CLASField": out1})
                    #
                    #
                    #     if Input_regexx!=[]:
                    #         if Input_regexx[0].__contains__('"'):
                    #              clas_field_value = Input_regexx[0].replace('(', "").replace('"', "").replace(")", "")
                    #              json_value.update({"CLASField":clas_field_value})
                    #         else:
                    #             field_var1 = Input_regexx[0].replace('(', "").replace(')', "").strip()
                    #             out_value=clas_field_fun(input_list,field_var1)
                    #             json_value.update({"CLASField": out_value})
                    #
                    #
                    #     if variable_regexx!=[]:
                    #         variable_value=variable_regexx[0].split(' ')[1]
                    #         variable_value1='\s*.*=\s*'+variable_value+'\s*'
                    #         for data in input_list:
                    #            variable_value_regexx=re.findall(variable_value1,data)
                    #            if variable_value_regexx!=[]:
                    #               data=data.split('=')[0].split(')')[0].split('(')[1]
                    #               if data.__contains__('"'):
                    #
                    #                   clas_field_value1=data.replace('"','')
                    #                   json_value.update({"CLASField": clas_field_value1})
                    #               else:
                    #                   field_var2 = data.strip()
                    #                   data=clas_field_fun(input_list,field_var2)
                    #                   json_value.update({"CLASField": data})

                if lines.strip()=="":
                    continue
                textbox_value = re.search(textbox_name_1, lines)
                dropdown_end_sub = re.findall(r'^\s*end\s*sub\s*', lines, re.IGNORECASE)
                if textbox_value:
                    count1 = 0
                    section_value_flag = True
                if section_value_flag:
                    count = count + 1
                    value = attribute_fun(lines, count,filename)

                    if value != None:
                        if type(value) == list:
                            maxlist.append(value[0])
                            if len(maxlist) == 2:
                                value = {"Min-Max": '-'.join(maxlist)}
                                maxlist = []
                            elif len(maxlist) == 1:
                                continue
                        for k, v in value.items():
                            dict_value = v

                        if dict_value.__contains__("(") and dict_value.__contains__(")"):
                            json_value.update({"Comments": "external function call"})

                        for k, v in value.items():
                            if k =="Tooltip":
                                count1=count1+1
                                v=str(count1)+'.)'+v
                                tooltip_list.append(v)
                                continue
                        json_value.update(value)
                if dropdown_end_sub != []:
                    section_value_flag = False

        vb_file.close()
        value={"Tooltip":'\n'.join(tooltip_list)}
        json_value.update(value)
        if (json_value["Required"]=="" and json_value["for_control"]=="" and json_value["Length"]=="" and json_value["Allowkeys"]=="" and
            json_value["Min-Max"]=="" and json_value["Tooltip"]==""):
            with open(filename + '.vb', 'r') as vb_file:
                textbox_name_1 = '\s*With\s*' + textbox_name+'[^aA-zZ]'
                for lines in vb_file.readlines():

                    if json_value["Type"].lower() == "textbox" or json_value["Type"].lower() == "combobox":
                        json_value = clas_field_fun_1(lines, textbox_name, json_value, input_list)

                    if json_value["Type"].lower()=="dropdownlist":
                        json_value = dropdown_clas_field(lines, textbox_name, json_value, input_list)

                    if lines.strip() == "":
                        continue
                    textbox_value = re.search(textbox_name_1, lines,re.IGNORECASE)
                    dropdown_end_sub = re.findall(r'^\s*end\s*sub\s*', lines, re.IGNORECASE)
                    if textbox_value:
                        count1 = 0
                        section_value_flag = True
                    if section_value_flag:
                        count = count + 1
                        value = attribute_fun(lines, count,filename)
                        if value != None:
                            if type(value) == list:
                                maxlist.append(value[0])
                                if len(maxlist) == 2:
                                    value = {"Min-Max": '-'.join(maxlist)}
                                    maxlist = []
                                elif len(maxlist) == 1:
                                    continue
                            for k, v in value.items():
                                dict_value = v
                            if dict_value.__contains__("(") and dict_value.__contains__(")"):
                                json_value.update({"Comments": "external function call"})
                            for k, v in value.items():
                                if k == "Tooltip":
                                    count1 = count1 + 1
                                    v = str(count1) + '.)' + v
                                    tooltip_list.append(v)
                                    continue
                            json_value.update(value)
                    if dropdown_end_sub != []:
                        section_value_flag = False
            vb_file.close()
            value = {"Tooltip": '\n'.join(tooltip_list)}
            json_value.update(value)

        if (json_value["Required"] == "" and json_value["for_control"] == "" and json_value["Length"] == "" and json_value[
                "Allowkeys"] == "" and
                    json_value["Min-Max"] == "" and json_value["Tooltip"] == ""):
                with open(filename + '.vb', 'r') as vb_file:
                    count = 0
                    for lines in vb_file.readlines():
                        if json_value["Type"].lower() == "textbox" or json_value["Type"].lower() == "combobox":
                            json_value = clas_field_fun_1(lines, textbox_name, json_value, input_list)

                        if json_value["Type"].lower()=="dropdownlist":
                            json_value = dropdown_clas_field(lines, textbox_name, json_value, input_list)

                        if lines.strip() == "":
                            continue
                        value=attribute_fun_1(lines,textbox_name)
                        if value != None:

                            if type(value) == list:
                                maxlist.append(value[0])
                                if len(maxlist) == 2:
                                    value = {"Min-Max": '-'.join(maxlist)}
                                    maxlist = []
                                elif len(maxlist) == 1:
                                    continue
                            for k, v in value.items():
                                dict_value = v
                            if dict_value.__contains__("(") and dict_value.__contains__(")"):
                                json_value.update({"Comments": "external function call"})
                            for k, v in value.items():
                                if k == "Tooltip":
                                    count = count + 1
                                    v = str(count) + '.)' + v
                                    tooltip_list.append(v)
                                    continue
                            json_value.update(value)
                vb_file.close()
                value = {"Tooltip": '\n'.join(tooltip_list)}
                json_value.update(value)

        metadata.append(json_value)

    except Exception as e:
        exc_type, exc_obj, exc_tb = sys.exc_info()
        fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
        print(exc_type, fname, exc_tb.tb_lineno)
    return input_list

def attribute_fun(lines,count,vb_file):
   try:

       #text_value_regexx=re.findall(r'\s*.*\.Text\s*=\s*.*',lines,re.IGNORECASE)
       allow_key_Regexx=re.findall(r'\s*.*\.AllowKeys\s*=\s*.*',lines,re.IGNORECASE)
       maxlen_regexx=re.findall(r'\s*.*\.MaxLength\s*=\s*.*',lines,re.IGNORECASE)
       validatore_required_regexx=re.findall(r'\s*.*\.Validators\.Required\.Enabled\s*=\s*.*',lines,re.IGNORECASE)
       validator_min_regexx=re.findall(r'\s*.*\.Validators\.Range\.MinimumValue\s*=\s*.*',lines,re.IGNORECASE)
       validator_max_regexx=re.findall(r'\s*.*\.Validators\.Range\.MaximumValue\s*=\s*.*',lines,re.IGNORECASE)
       tooltip_regexx=re.findall(r'\s*.*\.ToolTip\s*=\s*.*',lines,re.IGNORECASE)
       error_message_regexx=re.findall(r'\s*.*\.Validators\.Required\.ErrorMessage\s*=\s*.*',lines,re.IGNORECASE)
       dropdown_end_sub = re.findall(r'^\s*.*end\s*sub\s*', lines, re.IGNORECASE)

       if allow_key_Regexx!=[]:
          allow_key_value=allow_key_Regexx[0].split('=')[1].replace('"',"")
          return {"Allowkeys":allow_key_value}

       if maxlen_regexx!=[]:
           maxlen_value = maxlen_regexx[0].split('=')[1].replace('"', "")
           return {"Length":maxlen_value}

       if validatore_required_regexx!=[]:
           validatore_value=validatore_required_regexx[0].split('=')[1].replace('"', "")
           return {"Required":validatore_value+' '}

       if validator_max_regexx!=[]:
           validator_max_value=validator_max_regexx[0].split('=')[1].replace('"', "")
           return [validator_max_value]

       if validator_min_regexx!=[]:
           validator_min_value=validator_min_regexx[0].split('=')[1].replace('"', "")
           return  [validator_min_value]

       if tooltip_regexx != []:
           tooltip_value = tooltip_regexx[0].split('=')[1].replace('"', "")

           if tooltip_value.__contains__("("):
               tooltip_value = tooltip_derived(tooltip_value, vb_file)
               # print("111",tooltip_value)


           return {"Tooltip": tooltip_value}

       if  error_message_regexx!=[]:
           error_value = error_message_regexx[0].split('=')[1].replace('"', "")
           return {"ErrorMessage":error_value}
       #
       # if text_value_regexx!=[]:
       #     text_value = text_value_regexx[0].split('=')[1].replace('"', "")
       #     print(text_value)


   except Exception as e:
       exc_type, exc_obj, exc_tb = sys.exc_info()
       fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
       print(exc_type, fname, exc_tb.tb_lineno)
       print(e)


def attribute_fun_1(lines,textbox_name):
   try:

       allow_key_Regexx=re.findall(r'\s*.*\.AllowKeys\s*=\s*.*',lines,re.IGNORECASE)
       maxlen_regexx=re.findall(r'\s*.*\.MaxLength\s*=\s*.*',lines,re.IGNORECASE)
       validatore_required_regexx=re.findall(r'\s*.*\.Validators\.Required\.Enabled\s*=\s*.*',lines,re.IGNORECASE)
       validator_min_regexx=re.findall(r'\s*.*\.Validators\.Range\.MinimumValue\s*=\s*.*',lines,re.IGNORECASE)
       validator_max_regexx=re.findall(r'\s*.*\.Validators\.Range\.MaximumValue\s*=\s*.*',lines,re.IGNORECASE)
       tooltip_regexx=re.findall(r'\s*.*\.ToolTip\s*=\s*.*',lines,re.IGNORECASE)
       error_message_regexx=re.findall(r'\s*.*\.Validators\.Required\.ErrorMessage\s*=\s*.*',lines,re.IGNORECASE)
       dropdown_end_sub = re.findall(r'^\s*.*end\s*sub\s*', lines, re.IGNORECASE)

       if allow_key_Regexx!=[]:

          allow_key_value=allow_key_Regexx[0].split('=')[1].replace('"',"")
          #print(allow_key_Regexx[0].split('=')[0].split('.')[0].strip())
          if allow_key_Regexx[0].split('=')[0].split('.')[0].strip() == textbox_name:
            return {"Allowkeys":allow_key_value}

       if maxlen_regexx!=[]:
           maxlen_value = maxlen_regexx[0].split('=')[1].replace('"', "")
           if maxlen_regexx[0].split('=')[0].split('.')[0].strip() == textbox_name:
            return {"Length":maxlen_value}

       if validatore_required_regexx!=[]:
           validatore_value=validatore_required_regexx[0].split('=')[1].replace('"', "")
           if validatore_required_regexx[0].split('=')[0].split('.')[0].strip() == textbox_name:
             return {"Required":validatore_value}

       if validator_max_regexx!=[]:

           validator_max_value=validator_max_regexx[0].split('=')[1].replace('"', "")
           if validator_max_regexx[0].split('=')[0].split('.')[0].strip() == textbox_name:
            return [validator_max_value]

       if validator_min_regexx!=[]:

           validator_min_value=validator_min_regexx[0].split('=')[1].replace('"', "")
           if validator_min_regexx[0].split('=')[0].split('.')[0].strip()== textbox_name:
            return  [validator_min_value]

       if tooltip_regexx!=[]:
           tooltip_value=tooltip_regexx[0].split('=')[1].replace('"', "")
           if tooltip_regexx[0].split('=')[0].split('.')[0].strip() == textbox_name:
                 return {"Tooltip":tooltip_value}

       if  error_message_regexx!=[]:
           #print(error_message_regexx)
           error_value = error_message_regexx[0].split('=')[1].replace('"', "")
           if error_message_regexx[0].split('=')[0].split('.')[0].strip() == textbox_name:
                return {"ErrorMessage":error_value}


   except Exception as e:
       print(e)

def dropdown_vaues(id, filename):

   reassigned = False
   dim_var_search = False
   datasource_ref_var_list = []
   dirct_fun_call = False
   dropdown_vaues_list = []
   final_dropdown_vaues_list = []
   key_list = []
   sub_storage = fetch_sub(id, filename)
   fullsubstorage = fetch_full_sub(id, filename)
   fullsubstorage1 = fullsubstorage[::-1]  # reversrsing list using slice operator
   storage = fullsubstorage1 + sub_storage
   # print(storage)
   storedvalues_list = []
   tool_tip_value = ''
   if storage == []:
       storage = no_with_storage(id, filename)


   for content in storage:
       '''
       To Handel direct function call which is assigned to a variable within the sub 
       ex:
       Dim oLookup As SqlLookup
        oLookup = _oLobBC.GetListBlanketcode2(_sState, sEffDate)
        '''
       if content.__contains__("Dim") and not (content.__contains__("=")):
           dim_var = content.split()[1]
           dim_var_search = True
       if dim_var_search:
           if content.strip().startswith(dim_var):
               VBpath_finder = content.split("=")[-1]
               VBpath_class_var = VBpath_finder.split(".")[0]
               VBpath_funtion_name = VBpath_finder.split(".")[1].split("(")[0]
               VB_PATH = find_VBpath(VBpath_class_var, VBpath_funtion_name, filename)
               dropdown_vaues_list.append(fetch_stored_values_drop_down(VB_PATH, VBpath_funtion_name))
               return Remove(dropdown_vaues_list), storedvalues_list, tool_tip_value

       else:

           '''
           to fetch the dropdown values based on keys assigned to the datasource variable 
           example : .Datasource = oLookup.Item("ExpModeType1").DataSource
           '''
           VB_PATH =''
           if content.lower().__contains__("datasource"):
               # print(content.split("=")[-1].strip())
               if (content.split("=")[-1].strip().lower().__contains__("datasource")):
                   VBpath_finder = content.split("=")[-1]
                   datasource_ref_var = VBpath_finder.split(".")[0]
                   # key_list.append(VBpath_finder.split("(")[1].split(")")[0].replace('"',""))
                   key_list = fetch_the_keyList(storage)

                   for l in storage:
                       if l.__contains__(datasource_ref_var) and l.__contains__("=") and not (
                       l.split("=")[-1].lower().__contains__("datasource")):
                           VBpath_class_var = l.split("=")[-1].split(".")[0]
                           VBpath_funtion_name = l.split("=")[-1].split(".")[1].split("(")[0]
                           VB_PATH = find_VBpath(VBpath_class_var, VBpath_funtion_name, filename)
                           dropdown_vaues_list.append(fetch_stored_values_drop_down1(VB_PATH, VBpath_funtion_name,key_list))
                   if VB_PATH == '':
                       result_line =full_Vb_scane(filename,datasource_ref_var)
                       if result_line != '':
                           if result_line.__contains__("="):
                               VBpath_class_var = result_line.split("=")[-1].split(".")[0]

                               VBpath_funtion_name = result_line.split("=")[-1].split(".")[1].split("(")[0]
                               VB_PATH = find_VBpath(VBpath_class_var, VBpath_funtion_name, filename)
                               dropdown_vaues_list.append(
                                   fetch_stored_values_drop_down1(VB_PATH, VBpath_funtion_name, key_list))
                               storedvalues_list, tool_tip_value = find_stored_values_dropdown(storage)




               if key_list != [] and type(dropdown_vaues_list) == str:

                   for key in key_list:
                       for iter in dropdown_vaues_list:
                           for k, v in iter.items():
                               if key == k.replace('"', ""):
                                   final_dropdown_vaues_list.append(",".join(iter[k]))
                   storedvalues_list, tool_tip_value = find_stored_values_dropdown(storage)

                   return ("\n".join(final_dropdown_vaues_list)), storedvalues_list, tool_tip_value
               else:
                   return (str(dropdown_vaues_list)), storedvalues_list, tool_tip_value
               #
               # VBpath_finder = content.split("=")[-1]
               # VBpath_class_var = VBpath_finder.split(".")[0]
               # VBpath_funtion_name = VBpath_finder.split(".")[1].split("(")[0]
               # VB_PATH = find_VBpath(VBpath_class_var, VBpath_funtion_name, filename)
               # #print(VB_PATH)
               # dropdown_vaues_list.append(fetch_stored_values_drop_down(VB_PATH, VBpath_funtion_name))
               # break
               '''
               if datasource var is assignied with other variabel and that variable is assigined to refrence variable
               in other sub
               example:
               .Datasource = BlanketCode

               Private Sub setddlExpModStatus()
                   Dim dtBlanketCode As Datatable = _oLobBC.GetListBlanketcode1(_sstate)
                   BlanketCode = dtBlanketCode
                   With ddlExpModStatus
                        .Datasource = dtBlanketCode
                   End with
               End Sub


               '''
               if not (content.split("=")[-1].strip().lower().__contains__("datasource")) and content.__contains__(
                       "(") and content.__contains__(")") and content.lower().__contains__("datasource"):
                   dirct_fun_call = True

                   if dirct_fun_call:
                       VBpath_finder = content.split("=")[-1]
                       VBpath_class_var = VBpath_finder.split(".")[0]
                       VBpath_funtion_name = VBpath_finder.split(".")[1].split("(")[0]
                       VB_PATH = find_VBpath(VBpath_class_var, VBpath_funtion_name, filename)
                       # print(VB_PATH)
                       dropdown_vaues_list.append(fetch_stored_values_drop_down(VB_PATH, VBpath_funtion_name))
                       break

               else:
                   ref_var = content.split("=")[1]
                   with open(filename + '.vb', 'r') as vb_file:
                       for lines1 in vb_file.readlines():
                           if lines1.__contains__(ref_var.strip() + " ="):
                               reassinged_var = lines1.split("=")[-1]
                               reassigned = True
                               break
                   if reassigned:
                       with open(filename + '.vb', 'r') as vb_file:
                           for lines2 in vb_file.readlines():
                               if re.search("Dim " + reassinged_var.strip(), lines2):
                                   VBpath_finder = lines2.split("=")[-1]
                                   VBpath_class_var = VBpath_finder.split(".")[0]
                                   VBpath_funtion_name = VBpath_finder.split(".")[1].split("(")[0]
                                   VB_PATH = find_VBpath(VBpath_class_var, VBpath_funtion_name, filename)
                                   # print(VB_PATH)
                                   dropdown_vaues_list.append(
                                       fetch_stored_values_drop_down(VB_PATH, VBpath_funtion_name))
                                   storedvalues_list, tool_tip_value = find_stored_values_dropdown(storage)
                                   return Remove(dropdown_vaues_list), storedvalues_list, tool_tip_value

   return Remove(dropdown_vaues_list), storedvalues_list, tool_tip_value

def full_Vb_scane(filename,ele):
    result_line =''

    with open(filename + '.vb', 'r') as vb_file:
        for lines in vb_file.readlines():
            if re.search(ele , lines):
                result_line = lines



    return result_line



def fetch_the_keyList(storage):
    keyList = []
    for content in storage:
        if (content.split("=")[-1].strip().lower().__contains__("datasource")):
            VBpath_finder = content.split("=")[-1]
            keyList.append(VBpath_finder.split("(")[1].split(")")[0].replace('"', ""))

    return keyList


def find_stored_values_dropdown(storage):
    storedvalues_list = []
    tool_tip_value = ""

    for content in storage:

        if content.__contains__("DataValueField"):
            storedvalues_list.append(content.split("=")[-1].replace('"', ""))
        if content.__contains__(".ToolTip"):
            tool_tip_value = content.split("=")[-1]

    return storedvalues_list, tool_tip_value


# def find_VBpath(VBpath_class_var, VBpath_funtion_name, filename):
#     if filename.endswith(".VB"):
#         filename = filename.replace(".VB", "")
#     with open(filename + '.vb', 'r') as vb_file:
#         for line in vb_file.readlines():
#             if line.__contains__(VBpath_class_var + " As New") and (not line.__contains__("nothing")):
#                 temp_path = line.split("New")[-1].replace("BusinessServices", "ApplicationAssembles").replace(".",
#                                                                                                  "\\").strip() + ".VB"
#                 path_list = temp_path.split("\\")
#                 path_list.insert(2, path_list[1] + "." + path_list[0].replace("ApplicationAssembles", "BusinessRules"))
#                 VBfile_path = "\\".join(path_list)
#                 break
#             else:
#                 continue
#     return VBfile_path

def find_VBpath(VBpath_class_var, VBpath_funtion_name, filename):
    # print("File:",filename)
    # print("Class:",VBpath_class_var)
    if filename.endswith(".VB"):
        filename = filename.replace(".VB","")
        # print("File:",filename)
    # print("Checking")
    with open(filename + '.vb', 'r') as vb_file:
        for line in vb_file.readlines():
            if line.__contains__(VBpath_class_var.strip() + " As New") and (not line.__contains__("nothing")):
                temp_path = line.split("New")[-1].replace("BusinessServices", "ApplicationAssembles").replace(".",
                                                                                                              "\\").strip() + ".VB"
                path_list = temp_path.split("\\")
                path_list.insert(2, path_list[1] + "." + path_list[0].replace("ApplicationAssembles", "BusinessRules"))
                VBfile_path = "\\".join(path_list)
                break
            else:
                continue
    return VBfile_path


def fetch_sub(id, filename):
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


def fetch_full_sub(id, filename):
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

    return fullsubstorage


def fetch_stored_values_drop_down(VB_PATH, VBpath_funtion_name):
    fun_storage = []
    fun_dict = {}
    value_list = []

    collect_flag = False
    param_list = ""
    db_sate_var_value = set()
    with open(code_location + "\\" + VB_PATH, 'r') as file:

        for lines in file:
            if re.search("Function " + VBpath_funtion_name, lines):
                collect_flag = True

            if lines.__contains__("End function"):
                if collect_flag == True:
                    fun_storage.append(lines)
                fun_dict[VBpath_funtion_name] = fun_storage
                collect_flag = False

            if collect_flag:
                fun_storage.append(lines)
    for ln in fun_storage:
        if ln.strip().startswith("Return"):
            if ln.__contains__("."):
                var_name = ln.split(".")[0].replace("Return", "").strip()
                break
            else:
                var_name = ln.split()[-1].strip()
                break
    for lin in fun_storage:

        if lin.__contains__(var_name + ".Add"):
            # lin =  lin.rstrip("(")
            lin_list = lin.split("(")
            lin_list1 = lin_list[1].split(",")
            if len(lin_list1) == 4:
                prc_var = lin_list1[2].strip()
                quer_key = lin_list1[0].strip()
                # db_sate_var = lin_list1[-1].strip().replace(")","")
            if len(lin_list1) == 5:
                prc_var = lin_list1[2].strip()
                quer_key = lin_list1[0].strip()
                db_sate_var = lin_list1[-2].strip().replace(")", "")
            for content in fun_storage:
                content = content.strip()

                if content.strip().startswith(quer_key + " ="):
                    quer_key_valu = content.split("=")[-1].strip()
                    value_list.insert(1,"Key name" + ":" + quer_key_valu)
                if content.strip().startswith(prc_var + " ="):
                    prc_var_valu = content.split("=")[-1].strip()
                    value_list.insert(0,"1.)Proc name" + ":" + prc_var_valu)
                if len(lin_list1) == 4 or len(lin_list1) == 5:
                    if content.strip().startswith("Dim ") and content.__contains__(
                            "System.Data.SqlClient.SqlParameter"):
                        db_sate_var_list = content.split(".SqlParameter")
                        db_sate_var_value.add(db_sate_var_list[-1].split(",")[0].replace("(", "").replace("\'", ""))
                        param_list = (list(db_sate_var_value))
            value_list.insert(3,"Paramater" + ":" + ",".join(param_list))

    return ",".join(value_list)


def fetch_stored_values_drop_down1(VB_PATH, VBpath_funtion_name,key_list):

    fun_storage = []
    multi_prc_flag = False
    proc_valu_list = []
    data = []
    parm_value_list = set()
    q_key_dict = {}
    key_found = False
    fun_dict = {}
    value_list = []
    collect_flag = False
    param_list = ""
    db_sate_var_value = set()
    try:
        with open(code_location + "\\" + VB_PATH, 'r') as file:

            for lines in file:
                if re.search("Function " + VBpath_funtion_name, lines):
                    collect_flag = True

                if lines.__contains__("End function"):
                    if collect_flag == True:
                        fun_storage.append(lines)
                    fun_dict[VBpath_funtion_name] = fun_storage
                    collect_flag = False

                if collect_flag:
                    fun_storage.append(lines)
        for lns in fun_storage:
            if lns.strip().startswith("Return"):
                if lns.__contains__("."):
                    var_name = lns.split(".")[0].replace("Return", "").strip()
                    break
                else:
                    var_name = lns.split()[-1].strip()
                    break

        # for ln in range(len(fun_storage)):
        #     #print(ln,fun_storage[ln])
        #
        #     if fun_storage[ln].__contains__(var_name+".Add"):
        #         lin_list = fun_storage[ln].split("(")
        #         lin_list1 = lin_list[1].split(",")

        for lin in reversed(fun_storage):
            add_counter =len(key_list)
            count = 1

            if lin.__contains__(var_name + ".Add"):


                # lin =  lin.rstrip("(")
                lin_list = lin.split("(")
                lin_list1 = lin_list[1].split(",")
                prc_var = lin_list1[2].strip()
                quer_key = lin_list1[0].strip()
                for content in reversed(fun_storage):
                    content = content.strip()

                    if content.strip().startswith(quer_key + " ="):
                        multi_prc_flag = False
                        quer_key_valu = content.split("=")[-1].strip()
                        value_list.append("Key name" + ":" + quer_key_valu)
                        q_key_dict[quer_key_valu] = Remove(value_list)
                        add_counter = add_counter-1
                        value_list.clear()
                        proc_valu_list.clear()
                        count = 1

                    if content.strip().startswith(prc_var + " ="):
                        prc_var_valu = content.split("=")[-1].strip()
                        proc_valu_list.append(prc_var_valu)

                        count = count + 1
                        if count > 2:
                            multi_prc_flag = True

                    if multi_prc_flag:
                        proc_valu_list.append(prc_var_valu)

                    if len(proc_valu_list) > 1 and multi_prc_flag == True:
                        value_list.clear()
                        value_list.append(str(add_counter)+".)"+"Proc name" + ":" + ",".join(Remove(proc_valu_list)))

                    if len(proc_valu_list) >= 1 and multi_prc_flag == False:
                        value_list.append(str(add_counter)+".)"+"Proc name"  + ":" + prc_var_valu)

                    if len(lin_list1) == 4 or len(lin_list1) == 5:
                        if content.strip().startswith("Dim ") and content.__contains__(
                                "System.Data.SqlClient.SqlParameter"):
                            db_sate_var_list = content.split(".SqlParameter")
                            db_sate_var_value.add(db_sate_var_list[-1].split(",")[0].replace("(", "").replace("\'", ""))
                            param_list = ",".join(list(db_sate_var_value))
                parm_value_list.add("Paramater" + ":" + (param_list))
                # print("list_val",param_list+"\n")

                for k, v in q_key_dict.items():

                    v.append(",".join(list(parm_value_list)))



        return q_key_dict
    except FileNotFoundError as e:

        return  str(e)

def second_radio_fun(input_list,function_name,groupname,index_value):
    function_name = function_name.lstrip("\t")
    sub_regexx = 'Sub ' + function_name
    required_flag = False
    counter = 0
    for data in input_list:
        # print("1111")
        if counter == 1:
            break

        if required_flag:
            if re.search('.*End Sub.*', data, re.IGNORECASE):
                required_flag = False
                counter = counter + 1
                continue


            if re.search(required_value, data,re.IGNORECASE):
                if data.__contains__("Fields"):
                    variable = data.split("(")[1]
                    var_value = variable.split(")")[0]
                    # print("Var:",var_value)
                    if var_value.__contains__('"'):
                        out2 = var_value.replace('"',"")
                    else:
                        out2 = clas_field_fun(input_list, var_value)

        if re.search(sub_regexx,data,re.IGNORECASE):
            # print("In")
            parameters_separation_list = data.split("(")
            parameters = parameters_separation_list[1]
            parameters_list = parameters.split(",")
            if len(parameters_list) >= index_value + 1:
                required_parm = parameters_list[index_value]
                required_value = required_parm.split()[0]
                required_flag = True
                continue


    return out2

def radio_field_fun(input_list,groupname):
    classvalue_name = ""
    output = ""
    join_name = ""
    groupname_regexx =groupname.strip().rstrip("'").replace("'","")
    # print("Group:",groupname_regexx)
    for data in input_list:
        # print("1")
        # const_value = re.findall(groupname_regexx,data)
        # print("Const:",const_value)
        if data.__contains__(groupname_regexx):
            if data.__contains__(".Fields"):
                classvalue_name = data.split("Fields(")
                classvalue = classvalue_name[1].split(")")
                class_value = classvalue[0]
                if class_value.__contains__('"'):
                    output = class_value.replace('"',"")
                else:
                    output = clas_field_fun(input_list,class_value)
                # print("Class:",class_value)
            else:
                if data.__contains__("("):
                    second_case_class = data.split("(")
                    function_name = second_case_class[0]
                    position_of_groupname = second_case_class[1:]
                    join_name = (join_name.join(position_of_groupname))
                    join_name_split = join_name.split(",")
                    for position,item in enumerate(join_name_split):
                        if re.search(groupname_regexx,item):
                            index_value = position
                            output = second_radio_fun(input_list,function_name,groupname,index_value)
                    # index_value = join_name_split.index(groupname)
                    #         print("POS:",index_value)

                    # print("Second_case:",function_name)

    return output


def clas_field_fun(input_list,field_var):
    try:
        print("ggg",field_var)
        const_regexx='\s*Const\s*'+field_var+'\s.*=\s.*'
        const_value1=""
        for data in input_list:
            const_value=re.findall(const_regexx,data)
            if const_value!=[]:
                const_value=const_value[0].split("=")[1]
                if const_value.__contains__('"'):
                    const_value1=const_value.replace('"','').strip()

        if const_value1=="":
            data=db.glossary_vb.find_one({"ConstantsVariable":field_var.strip()})
            const_value1=data["ConstantsMeaning"]
            print("ccc",field_var)

        return const_value1

    except Exception as e:
        exc_type, exc_obj, exc_tb = sys.exc_info()
        fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
        print(exc_type, fname, exc_tb.tb_lineno)


def clas_field_fun_1(lines,textbox_name,json_value,input_list):
    text_box_regexx = '\s*.*=.*' + textbox_name + '\.Text.*'
    text_box_value_regexx = re.findall(text_box_regexx, lines)

    if text_box_value_regexx != []:

        text_box_value = text_box_value_regexx[0].split('=')[0]

        field_regexx = re.findall(r'\s*.*\.Fields\s*(.*)\.Value\s*', text_box_value)

        variable_regexx = re.findall(r'\s*\t*Dim\s*[A0-Z9]*\s*', text_box_value, re.IGNORECASE)

        Input_regexx = re.findall(r'\s*.*\.Input\s*(.*)\.Value\s*', text_box_value)

        if field_regexx != []:

            if field_regexx[0].__contains__('"'):
                clas_field_value = field_regexx[0].replace('(', "").replace('"', "").replace(")", "")
                json_value.update({"CLASField": clas_field_value})
            else:

                field_var = field_regexx[0].replace('(', "").replace(')', "").strip()
                out1 = clas_field_fun(input_list, field_var)
                json_value.update({"CLASField": out1})

        if Input_regexx != []:
            if Input_regexx[0].__contains__('"'):
                clas_field_value = Input_regexx[0].replace('(', "").replace('"', "").replace(")", "")
                json_value.update({"CLASField": clas_field_value})
            else:
                field_var1 = Input_regexx[0].replace('(', "").replace(')', "").strip()
                out_value = clas_field_fun(input_list, field_var1)
                json_value.update({"CLASField": out_value})

        if variable_regexx != []:
            variable_value = variable_regexx[0].strip().split(' ')[1]
            variable_value1 = '\s*.*=\s*' + variable_value + '\s*'
            for data in input_list:
                variable_value_regexx = re.findall(variable_value1, data)
                if variable_value_regexx != []:
                    data = data.split('=')[0].split(')')[0].split('(')[1]
                    if data.__contains__('"'):
                        clas_field_value1 = data.replace('"', '')
                        json_value.update({"CLASField": clas_field_value1})
                    else:
                        field_var2 = data.strip()
                        data = clas_field_fun(input_list, field_var2)
                        json_value.update({"CLASField": data})

    return json_value


def dropdown_clas_field(lines,textbox_name,json_value,input_list):
    text_box_regexx = '\s*.*=\s*' + textbox_name + '\.SelectedValue.*'
    text_box_value_regexx = re.findall(text_box_regexx, lines)

    if text_box_value_regexx != []:

        text_box_value = text_box_value_regexx[0].split('=')[0]

        field_regexx = re.findall(r'\s*.*\.Fields\s*(.*)\.Value\s*', text_box_value)

        variable_regexx = re.findall(r'\s*\t*Dim\s*[A0-Z9]*\s*', text_box_value.strip(), re.IGNORECASE)

        Input_regexx = re.findall(r'\s*.*\.Input\s*(.*)\.Value\s*', text_box_value)

        if field_regexx != []:

            if field_regexx[0].__contains__('"'):
                clas_field_value = field_regexx[0].replace('(', "").replace('"', "").replace(")", "")
                json_value.update({"CLASField": clas_field_value})
            else:

                field_var = field_regexx[0].replace('(', "").replace(')', "").strip()
                out1 = clas_field_fun(input_list, field_var)
                json_value.update({"CLASField": out1})

        if Input_regexx != []:
            if Input_regexx[0].__contains__('"'):
                clas_field_value = Input_regexx[0].replace('(', "").replace('"', "").replace(")", "")
                json_value.update({"CLASField": clas_field_value})
            else:
                field_var1 = Input_regexx[0].replace('(', "").replace(')', "").strip()
                out_value = clas_field_fun(input_list, field_var1)
                json_value.update({"CLASField": out_value})

        if variable_regexx != []:
            variable_value = variable_regexx[0].split(' ')[1]
            variable_value1 = '\s*.*=\s*' + variable_value + '\s*'
            for data in input_list:
                variable_value_regexx = re.findall(variable_value1, data)
                if variable_value_regexx != []:
                    data = data.split('=')[0].split(')')[0].split('(')[1]
                    if data.__contains__('"'):

                        clas_field_value1 = data.replace('"', '')
                        json_value.update({"CLASField": clas_field_value1})
                    else:
                        field_var2 = data.strip()
                        data = clas_field_fun(input_list, field_var2)
                        json_value.update({"CLASField": data})

    return json_value



def tooltip_derived(tooltip,filename):
    try:
        # print(tooltip)
        name_val_var = tooltip.split("(")[0]
        keyvalue = tooltip.split("(")[1].replace(")","")

        with open(filename + '.vb', 'r') as vb_file:
            for lines in vb_file.readlines():
                # print(lines.split("=")[0],name_val_var)
                if lines.split("=")[0].strip().__contains__(name_val_var.strip()) and lines.__contains__("="):
                    VBpath_finder = lines.split("=")[-1]
                    VBpath_class_var = VBpath_finder.split(".")[0]
                    VBpath_funtion_name = VBpath_finder.split(".")[1].split("(")[0]
                    VB_PATH = find_VBpath(VBpath_class_var, VBpath_funtion_name, filename)
                    tool_tip = tooltipdervived_var(VB_PATH,VBpath_funtion_name,keyvalue)
                    return  tool_tip
    except Exception as e:
        exc_type, exc_obj, exc_tb = sys.exc_info()
        fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
        print(exc_type, fname, exc_tb.tb_lineno)
        print(e)




def find_tool_tip_file(VBpath_class_var, filename):
    with open(filename , 'r') as vb_file:
        for line in vb_file.readlines():
            if line.__contains__(VBpath_class_var.strip() + " As New") and (not line.__contains__("nothing")):
                tool_tip_filename  = line.split("New")[-1].strip() + ".VB"
                tool_tip_path = "\\".join(filename.split("\\")[:-1])+"\\"+tool_tip_filename

                break
            else:
                continue

    return tool_tip_path

def get_withname(VB_PATH,VBpath_funtion_name,pos):
    storage=[]
    contains_with_flag =  False
    storage =  fetch_sub_with_name(VBpath_funtion_name,VB_PATH)
    with_name_parm = storage[0].split('(')[1].split(')')[0].split(",")[pos]
    # print("PAraaaa:",with_name_parm)
    if with_name_parm.__contains__("As"):
        with_name = with_name_parm.split("As")[0].replace("ByVal","").replace("ByRef","").strip()
        contains_with_flag = False

        # print("name:",with_name)
        return with_name, contains_with_flag
    else:
        with_name = with_name_parm.split()[-1]
        for lines in storage:
            if lines.lower().__contains__("with") and lines.__contains__(with_name):
                contains_with_flag = True
        return with_name, contains_with_flag


    # print(with_name)
    return None,None

def fetch_sub_with_name(id,filename):
    sub_storage = []
    collect_flag = False
    # if filename.lower().endswith(".vb"):
    #     filename = "\\".join(filename.split("\\")[:-1])+"\\"+filename.split("\\")[-1].replace(".VB","")
    with open(code_location+'\\'+filename , 'r') as vb_file:
        for lines in vb_file.readlines():
            Sub_id = "Sub " + id
            # print(with_id)
            # if lines.__contains__(with_id):
            if re.search(Sub_id, lines):
                collect_flag = True

            if lines.__contains__("End Sub"):
                if collect_flag == True:
                    sub_storage.append(lines)
                collect_flag = False

            if collect_flag:
                sub_storage.append(lines)

    return sub_storage

def no_with_storage(id,filename):
    sub_storage = []

    if filename.lower().endswith(".vb"):
        filename = "\\".join(filename.split("\\")[:-1]) + "\\" + filename.split("\\")[-1].replace(".VB", "")
    with open(filename + '.vb', 'r') as vb_file:
        for lines in vb_file.readlines():
            if lines.__contains__(id+"."):
                sub_storage.append(lines)


    return sub_storage



for filename in glob.glob(os.path.join(vb_path,'*.aspx')):
    metadata=[]
    main(filename,metadata)


for filename in glob.glob(os.path.join(vb_path,'*.ascx')):
    metadata=[]
    main(filename,metadata)
