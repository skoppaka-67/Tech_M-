import config
from pymongo import MongoClient
import glob,os
import re
import csv
mongoClient = MongoClient('localhost', 27017)
db = mongoClient['asp']
vb = config.codebase_information['VB']['folder_name']
code_location =config.codebase_information['code_location']

vb_path=code_location+'\\'+vb

version="Version-1, without integrating drop down."

output_json={"section_id":"","section_name":"","CLAS_label":"","comments":"","screen_field":"","CLAS_field":"","type":"","required":"","for_control":"","maximun_length":"",
             "allowkeys":"","min-max":"","tooltip":"","enabled":"","dropdown_value":"","stored_value":"","error_message":""}
metadata=[]
def main():
    for filename in glob.glob(os.path.join(vb_path,'*.aspx')):

      try:
        section_flag=False

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
                    expand_item_regexx = re.findall(r'^\s*<\s*.*\s*:\s*ExpandCollapsePanelItem\s*.*id\s*=\s*"\s*[aA-zZ]*"', line,re.IGNORECASE)
                    stack_item_regxx=re.findall(r'^\s*<\s*.*\s*:\s*StackingPanelItem\s*.*id\s*=\s*"\s*[aA-zZ]*"', line,re.IGNORECASE)
                    # label_regexx=re.findall(r'^\s*<\s*.*\s*:\s*label\s*id\s*=\s*"\s*[aA-zZ]*"',line,re.IGNORECASE)
                    # dropdown_regexx=re.findall(r'^\s*<\s*.*\s*:\s*DropdownList\s*id\s*=\s*"\s*[aA-zZ]*"',line)
                    # textbox_regexx=re.findall(r'^\s*<\s*.*\s*:\s*TextBox\s*id\s*=\s*"\s*[aA-zZ]*"',line)
                    radiobutton_regexx = re.findall(r'^\s*<\s*[aA-zZ].*\s*:\s*RadioButton\s*id\s*=\s*"\s*[aA-zZ]*"', line,
                                                    re.IGNORECASE)

                    checkbox_regexx=re.findall(r'^\s*<\s*[aA-zZ].*\s*:\s*CheckBox\s*id\s*=\s*"\s*[aA-zZ]*"', line,
                                                    re.IGNORECASE)

                    control_regexx=re.findall(r'^\s*<\s*[aA-zZ].*\s*:\s*.*\s*id\s*=\s*.*',line,re.IGNORECASE)
                    if expand_item_regexx!=[] or stack_item_regxx!=[]:

                        if expand_item_regexx!=[]:

                             section_name=expand_item_regexx[0].split("id")[1].replace('"','')
                             section_name = section_name.replace('=', '')
                             sec_name=section_name_fun(filename,section_name)


                        elif stack_item_regxx!=[]:

                            section_name = stack_item_regxx[0].split("id")[1].replace('"', '')
                            section_name = section_name.replace('=', '')
                            sec_name=section_name_fun(filename, section_name)
                            #print(sec_name,section_name)



                    if control_regexx!=[]:


                            control_name=control_regexx[0].split(":")[1].split()[0]

                            ignore_list=["StackingPanelItem","ExpandCollapsePanelItem"]

                            if control_name in ignore_list:
                                continue

                            if control_name.upper()=="LABEL":

                                data_regexx=re.findall('\s*.*\s*id\s*=\s*"\s*[aA-zZ]*"',line,re.IGNORECASE)


                                label_name = data_regexx[0].split("id")[1].replace('"', '')
                                label_name=label_name.replace('=','')

                                label_name_1,for_control=label_name_fun(filename, label_name)

                                json = {"SectionID":section_name,"SectionName": sec_name, "CLASLabel": label_name_1,"ScreenField":label_name, "CLASField": "", "Type": "label",
                                        "Required": "", "for_control": for_control, "Length": "",
                                        "Allowkeys": "", "Min-Max": "", "Tooltip": "", "Enable": "","DropdownValue":"","StoredValue":"","ErrorMessage":"","Comments":""}
                                label_name_1=""
                                metadata.append(json)


                            else :

                                data_regexx = re.findall('\s*.*\s*id\s*=\s*"\s*[aA-zZ]*"', line, re.IGNORECASE)

                                dropdown_name = data_regexx[0].split("id")[1].replace('"', '')
                                dropdown_name = dropdown_name.replace('=', '')

                                json = {"SectionID":section_name,"SectionName": sec_name, "CLASLabel": "","ScreenField":dropdown_name,"CLASField": "", "Type": control_name,
                                        "Required": "", "for_control": "", "Length": "",
                                        "Allowkeys": "", "Min-Max": "", "Tooltip": "", "Enable": "","DropdownValue":"","StoredValue":"","ErrorMessage":"","Comments":""}
                                control_fun(filename, dropdown_name,json)
                                ######( Kishore radio button)
                                if radiobutton_regexx != []:
                                    radiobutton_fun(filename, dropdown_name, json)

                                if checkbox_regexx != []:
                                    checkbox_fun(filename, dropdown_name, json)

                                        #print(metadata)
        db.screen_data.insert_many(metadata)

        key = {"SectionID" ,"SectionName", "CLASLabel",
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
                                             "Comments": 1})
        out_data = []

        for screen_data in metadata1:
            out_data.append(screen_data)
        with open("screen_fields" + '.csv', 'w', newline="") as output_file:
            Fields = ["SectionID", "SectionName", "CLASLabel",
                      "ScreenField", "CLASField", "Type",
                      "Required", "Length",
                      "Allowkeys", "Min-Max", "Tooltip", "Enable", "DropdownValue", "StoredValue", "ErrorMessage",
                      "Comments"]
            dict_writer = csv.DictWriter(output_file, fieldnames=Fields)
            dict_writer.writeheader()
            dict_writer.writerows(out_data)

        # metadata1=db.screen_data.find()
        # out_data=[]
        # for screen_data in metadata1:
        #     out_data.append(screen_data)
        # with open("screen_fields" + '.csv', 'w', newline="") as output_file:
        #     dict_writer = csv.DictWriter(output_file, key)
        #     dict_writer.writeheader()
        #     dict_writer.writerows(out_data)


      except Exception as e:
        print(e)
        pass


def checkbox_fun(filename,dropdown_name,json):
    with open(filename + '.vb', 'r') as vb_file:
        # print("Vb_file:",vb_file)
        checkboxvalue_Flag = False
        # exit_flag = False
        checkpara_name = 'With'+' '+dropdown_name
        endwith_check  = 'End With'
        inline_check_flag = False
        counter = 0
        check_list = []
        if_collector = ""
        keywords_for_check_stored = ['Yes"','No"','"Y"','"N"','Status.YES_ABBREIVATED','Status.NO_ ABBREIVATED','Constants.SHORT_Yes','Constants.SHORT_No',
                                     'CL_EqualsYesAbbrevation','CL_EqualsNoAbbrevation','CL_YesAbbreviation','CL_NoAbbreviation']
        for lines in vb_file.readlines():


            if counter == 1:

                break

            if checkboxvalue_Flag:
                if re.search('.*If.*',lines,re.IGNORECASE):
                    if not re.search('.*End If.*',lines,re.IGNORECASE):
                        if_collector = lines
                        inline_check_flag = True
                        continue
                if inline_check_flag:
                    if re.search('.*Checked.*',lines):
                        for ext in keywords_for_check_stored:
                            if ext in if_collector and if_collector.__contains__("="):
                                stored_value = ext.replace('"','')
                                if_collector = ''
                                json["StoredValue"] = stored_value
                                print("Ext:", stored_value)
                                break
                            elif not if_collector.__contains__("=") and ext in if_collector:
                                stored_value = ext
                                if_collector = ''
                                json["StoredValue"] = stored_value
                                break

                if re.search('.*Checked.*',lines) and inline_check_flag == False:
                   lines = lines.split(".")
                   stored_value = lines[-1].strip("\n")
                   json["StoredValue"] = stored_value
                   print("Check:",stored_value)
                   continue
                        # else:
                        #     if if_collector =="":
                        #         lines = lines.split(".")
                        #         stored_value = lines[-1]
                        #         print("Check:",stored_value)

                if re.search(endwith_check, lines):
                    checkboxvalue_Flag = False
                    inline_check_flag = False
                    counter = counter + 1
                    continue

            if re.search(checkpara_name,lines,re.IGNORECASE):
                checkboxvalue_Flag = True

    print("METADATA:",json)
    vb_file.close()


def radiobutton_fun(filename,dropdown_name,json):
    with open(filename + '.vb', 'r') as vb_file:
        # print("Vb_file:",vb_file)
        storedvalue_Flag = False
        counter = 0
        radiopara_name = 'With'+' '+dropdown_name
        endwith_radio  = 'End With'
        for lines in vb_file.readlines():

            if counter == 1:

                break

            if storedvalue_Flag:
                if lines.__contains__(".Value"):
                    stored_value = lines.split("=")[1].strip('\n')
                    json["StoredValue"] = stored_value.replace('"',"").strip()

                if re.search(endwith_radio, lines):
                    storedvalue_Flag = False
                    counter = counter + 1
                    continue

            if re.search(radiopara_name,lines,re.IGNORECASE):
                storedvalue_Flag = True


    print("METADATA:",json)
    vb_file.close()




def section_name_fun(filename,section_name):
    try:
        section_value_flag=False
        section_name_2=""
        with open(filename + '.vb', 'r') as vb_file:
            section_name_1='set'+section_name+'\s*\(\)'
            #section_name_2='\s*with\s*'+section_value
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
                # section_name_2='\s*with\s*'+section_value
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

        #print(section_name_2)

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


def control_fun(filename, textbox_name, json):
    try:
        maxlist = []
        tooltip_list=[]
        section_value_flag = False

        with open(filename + '.vb', 'r') as vb_file:
            textbox_name_1 = 'set' + textbox_name + '\s*\(\)'
            count=0
            for lines in vb_file.readlines():
                if lines.strip()=="":
                    continue
                textbox_value = re.search(textbox_name_1, lines)
                dropdown_end_sub = re.findall(r'^\s*end\s*sub\s*', lines, re.IGNORECASE)
                if textbox_value:
                    count1 = 0
                    section_value_flag = True
                if section_value_flag:
                    count = count + 1
                    value = attribute_fun(lines, count)

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
                            json.update({"Comments": "external function call"})

                        for k, v in value.items():
                            if k =="Tooltip":

                                count1=count1+1

                                v=str(count1)+'.)'+v
                                tooltip_list.append(v)
                                continue
                        json.update(value)
                if dropdown_end_sub != []:
                    section_value_flag = False

        vb_file.close()
        value={"Tooltip":'\n'.join(tooltip_list)}
        json.update(value)
        if (json["Required"]=="" and json["for_control"]=="" and json["Length"]=="" and json["Allowkeys"]=="" and
            json["Min-Max"]=="" and json["Tooltip"]==""):
            with open(filename + '.vb', 'r') as vb_file:
                textbox_name_1 = '\s*With\s*' + textbox_name+'[^aA-zZ]'
                for lines in vb_file.readlines():
                    if lines.strip() == "":
                        continue
                    textbox_value = re.search(textbox_name_1, lines,re.IGNORECASE)
                    dropdown_end_sub = re.findall(r'^\s*end\s*sub\s*', lines, re.IGNORECASE)
                    if textbox_value:
                        count1 = 0
                        section_value_flag = True
                    if section_value_flag:
                        count = count + 1
                        value = attribute_fun(lines, count)
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
                                json.update({"Comments": "external function call"})
                            for k, v in value.items():
                                if k == "Tooltip":
                                    count1 = count1 + 1
                                    v = str(count1) + '.)' + v
                                    tooltip_list.append(v)
                                    continue
                            json.update(value)
                    if dropdown_end_sub != []:
                        section_value_flag = False
            vb_file.close()
            value = {"Tooltip": '\n'.join(tooltip_list)}
            json.update(value)

        if (json["Required"] == "" and json["for_control"] == "" and json["Length"] == "" and json[
                "Allowkeys"] == "" and
                    json["Min-Max"] == "" and json["Tooltip"] == ""):
                with open(filename + '.vb', 'r') as vb_file:
                    count = 0
                    for lines in vb_file.readlines():
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
                                json.update({"Comments": "external function call"})
                            for k, v in value.items():
                                if k == "Tooltip":
                                    count = count + 1
                                    v = str(count) + '.)' + v
                                    tooltip_list.append(v)
                                    continue
                            json.update(value)
                vb_file.close()
                value = {"Tooltip": '\n'.join(tooltip_list)}
                json.update(value)


        #print(json)


        metadata.append(json)
    except Exception as e:
        print(e)


def attribute_fun(lines,count):
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

       if tooltip_regexx!=[]:
           tooltip_value=tooltip_regexx[0].split('=')[1].replace('"', "")

           return {"Tooltip":tooltip_value}

       if  error_message_regexx!=[]:

           error_value = error_message_regexx[0].split('=')[1].replace('"', "")
           return {"ErrorMessage":error_value}


   except Exception as e:
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





main()