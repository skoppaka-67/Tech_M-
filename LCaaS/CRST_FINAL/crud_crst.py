import glob,os,re

import config_crst
from pymongo import MongoClient
import pandas as pd
client = MongoClient('localhost', 27017)
db = client['CRST_FULL']

code_location="D:\\CRST_FULL"
CobolPath=code_location+'\\'+'*'

Metadata = []
db.crud_report.remove(Metadata)
def main():
    for filename in glob.glob(os.path.join(CobolPath, '*.cbl')):
        print("Enter:",filename)
        Type = "COBOL"
        process_func(filename,Type)

def table_func(file_variable,declaration_list):
    table_flag = False
    tab_counter = 0
    tab_value = ''
    for var in declaration_list:
        if tab_counter == 1:
            table_flag = False
            tab_counter = 0
            break

        if table_flag:
            if re.search('.*VALUE.*',var,re.IGNORECASE):

                tab_value = var.split()[1].replace("'","")
                print("TAB:", tab_value)
                tab_counter = tab_counter + 1
        if re.search(file_variable,var,re.IGNORECASE):
            table_flag = True
            print("VAR:",file_variable)

    return tab_value

def process_func(filename,Type):

    declaration_flag = False
    procedure_flag = False
    declaration_list = []
    f = open(filename,'r')
    for lines in f.readlines():
        # print("Lines:",lines)
        lines = lines[6:72]
        # print("In:",lines)
        if lines.strip() == "":
            continue
        if lines[0] == "*" :
            continue
        else:
            # print(lines)
            if re.search('.*PROCEDURE DIVISION.*',lines,re.IGNORECASE):
                print("1")
                declaration_flag = False

            if declaration_flag:
                declaration_list.append(lines)
                continue

            if re.search('.ENVIRONMENT DIVISION',lines,re.IGNORECASE):
                declaration_flag = True
                continue
    f.close()

    f1 = open(filename,'r')
    keywords_for_crud_delimiter = ['ZULU_DELETE','ZULU_FETCH','ZULU_FIND','ZULU_GET','ZULU_INSERT','ZULU_READBY','ZULU_UPDATE']
    call_flag = False
    call_variable = ''
    counter = 0
    tab_value = ''
    for data in f1.readlines():



        data = data[6:72]
        if data.strip() == "":
            continue
        if data[0] == "*" :
            continue
        else:
            if counter == 1:
                call_flag = False
                counter = 0
                call_variable = ''
                continue
            if call_flag:
                if data.__contains__("USING"):
                    file_value = data.split(",")[0]
                    file_variable = file_value.split()[1].rstrip('\n')
                    print("File_1:",file_value)
                    # print(file_value)
                    # print("JK:", file_variable)
                    file_variable = file_variable + "-ID"
                    tab_value = table_func(file_variable,declaration_list)
                    try:
                        table = tab_value.split(":")[1]
                        counter = counter + 1
                        Metadata.append({"component_name":filename.split('\\')[-1],
                                         "component_type":Type,
                                         "calling_app_name": "",
                                         "Table":table,
                                         "CRUD":crud_operation,
                                         "SQL": call_variable + " " + tab_value
                                          })
                    except Exception as e:
                        print(e)

                else:

                     file_value = data.split(",")[0]
                     print("File_2:", file_value)
                     file_variable = file_value.strip().rstrip('\n')

                     file_variable = file_variable + "-ID"
                     tab_value = table_func(file_variable, declaration_list)
                     try:
                         table = tab_value.split(":")[1]
                         counter = counter + 1
                         Metadata.append({"component_name": filename.split('\\')[-1],
                                          "component_type": Type,
                                          "calling_app_name": "",
                                          "Table": table,
                                          "CRUD": crud_operation,
                                          "SQL": call_variable + " " + tab_value
                                          })
                     except Exception as e:
                         print(e)

            if re.search('.*CALL.*',data,re.IGNORECASE):
                if any(extension in data for extension in keywords_for_crud_delimiter):
                    # print("EXT:",extension)]
                    call_variable = data.split()[1].replace("'","")
                    print("Collapse:",call_variable)
                    if call_variable == "ZULU_DELETETSQ":
                        continue
                    if call_variable == "ZULU_FETCH" or call_variable == "ZULU_FIND" or call_variable == "ZULU_GET" or call_variable =="ZULU_READBY":
                        crud_operation = "READ"
                    elif call_variable == "ZULU_DELETE":
                        crud_operation = "DELETE"
                    elif call_variable == "ZULU_INSERT":
                        crud_operation = "CREATE"
                    elif call_variable == "ZULU_UPDATE":
                        crud_operation = "UPDATE"
                    call_flag = True



main()
db.crud_report.insert_many(Metadata)
# df = pd.DataFrame(Metadata)
#
# # Create a Pandas Excel writer using XlsxWriter as the engine.
# writer = pd.ExcelWriter('crud_simple.xlsx', engine='xlsxwriter')
#
# # Convert the dataframe to an XlsxWriter Excel object.
# df.to_excel(writer, sheet_name='Sheet1')
#
# # Close the Pandas Excel writer and output the Excel file.
# writer.save()
