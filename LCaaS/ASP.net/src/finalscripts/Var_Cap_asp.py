from pymongo import MongoClient
import glob, os, json, re,copy
import pytz, datetime
import csv
import config
from xlsxwriter import Workbook



mongoClient = MongoClient('localhost', 27017)
db = mongoClient['asp4']
vb = config.codebase_information['VB']['folder_name']
code_location =config.codebase_information['code_location']
vb_path=code_location+'\\'+vb
ref_var_list = []
metadata = []
metadata_js = []

vb_component_path = code_location + "\\ApplicationAssembles\\LobPF\\*"
def remove_duplicates(list):
    res = []
    for i in list:
        if i not in res:
            res.append(i)
    return res

def get_files():
    filenames_list = []
    for filename1 in glob.glob(os.path.join(vb_path, '*.aspx.vb')):
        filenames_list.append(filename1)
    for filename2 in glob.glob(os.path.join(vb_component_path, '*.vb')):
        filenames_list.append(filename2)


    return filenames_list




file_list = get_files()

for filename in file_list:


        with open(filename , 'r') as vb_file:
            output =   {"File_name" : "",
            "Variable": "",
            "Business_Meaning": ""
                      }
            for lines in vb_file.readlines():
                if lines.strip().upper().startswith("DIM"):
                    # print(lines)
                    output["File_name"] = filename.split("\\")[-1]
                    output['Variable'] = lines.split()[1]
                    output['Business_Meaning'] = ''
                    metadata.append(copy.deepcopy(output))

                if len(lines.split()) >= 1 :
                    if (lines.strip().upper().startswith("PUBLIC") or lines.strip().upper().startswith("PRIVATE") or lines.strip().upper().startswith("PROTECTED")) and (lines.strip().split()[1] != "Sub" and lines.strip().split()[1] != "Function" and lines.strip().split()[1] != "Property") :
                        if lines.strip().split()[1] == "Static" or lines.strip().split()[1] == "Const":
                            # print("with",lines)
                            output["File_name"] = filename.split("\\")[-1]
                            output['Variable'] = lines.split()[2]
                            output['Business_Meaning'] = ''
                            metadata.append(copy.deepcopy(output))
                        else:
                            # print("without ",lines)
                            output["File_name"] = filename.split("\\")[-1]
                            output['Variable'] = lines.split()[1]
                            output['Business_Meaning'] = ''
                            metadata.append(copy.deepcopy(output))

# print(json.dumps(metadata,indent=4))


for filename in glob.glob(os.path.join(vb_path,'*.js')):
    try:
        with open(filename, 'r') as js_file:
            output = {"File_name": "",
                      # "Function_name":"",
                      "Variable": "",
                      "Business_Meaning": ""
                      }
            for lines in js_file.readlines():
                if lines.strip().lower().startswith("function"):
                    function_name = lines.split()[1].split("(")[0]
                if lines.__contains__("const"):
                    print(lines)
                    split_line = lines.split()
                    index = split_line.index("const")
                    output["File_name"] = filename.split("\\")[-1]
                    output['Function_name'] = function_name
                    output['Variable'] = split_line[index +1].split("=")[0]
                    output['Business_Meaning'] = ''
                    metadata_js.append(copy.deepcopy(output))

                # if lines.__contains__("var") and lines.__contains__("="):
                #     # print(lines)
                #     pass

                elif lines.strip().upper().startswith("VAR"):
                    if lines.__contains__(",") and not lines.__contains__("("):
                        split_line = lines.split(',')

                    # print(lines)
                        for i in split_line:

                            output["File_name"] = filename.split("\\")[-1]
                            # output['Function_name'] = function_name
                            output['Variable'] =  i.strip().replace('var', '')
                            output['Business_Meaning'] = ''
                            metadata_js.append(copy.deepcopy(output))
                    else:
                        output["File_name"] = filename.split("\\")[-1]
                        # output['Function_name'] = function_name
                        output['Variable'] =  lines.split()[1]
                        output['Business_Meaning'] = ''
                        metadata_js.append(copy.deepcopy(output))

                elif lines.strip().upper().startswith("LET"):
                    if lines.__contains__(","):
                        split_line = lines.split(',')

                    # print(lines)
                        for i in split_line:

                            output["File_name"] = filename.split("\\")[-1]
                            # output['Function_name'] = function_name
                            output['Variable'] =  i.strip().replace('var', '').replace('let',"")
                            output['Business_Meaning'] = ''
                            metadata_js.append(copy.deepcopy(output))
                    else:
                        output["File_name"] = filename.split("\\")[-1]
                        # output['Function_name'] = function_name
                        output['Variable'] =  lines.split()[1]
                        output['Business_Meaning'] = ''
                        metadata_js.append(copy.deepcopy(output))

    except Exception as e:
        print(filename,e,lines)

# print(json.dumps(metadata_js,indent=4))


wb=Workbook("glossary_Vb.xlsx")
ws=wb.add_worksheet("Sheet1")
first_row=0
ordered_list=["File_name","Variable","Business_Meaning"] #list object calls by index but dict object calls items randomly

for header in ordered_list:
    col=ordered_list.index(header) # we are keeping order.
    ws.write(first_row,col,header)
row=1
for records in metadata:
    for _key,_value in records.items():
        col=ordered_list.index(_key)
        ws.write(row,col,_value)
    row+=1 #enter the next row
wb.close()





ordered_list=["File_name","Variable","Business_Meaning"] #list object calls by index but dict object calls items randomly
wb=Workbook("1glossary_js.xlsx")
ws=wb.add_worksheet("Sheet1")
first_row=0
for header in ordered_list:
    col=ordered_list.index(header) # we are keeping order.
    ws.write(first_row,col,header)
row=1
for records in metadata_js:
    for _key,_value in records.items():
        col=ordered_list.index(_key)
        ws.write(row,col,_value)
    row+=1 #enter the next row
wb.close()


print(json.dumps(metadata_js,indent=4))

try:
    db.glossary.remove()
    db.glossary_js.remove()

except Exception as e:
    print("Exception in Db deletion ", e)

try:

    db.glossary.insert_many(remove_duplicates(metadata))
    db.glossary_js.insert_many(remove_duplicates(metadata_js))
    print("DB update Success")
except Exception as e:
    print(" unable to update  DB")







