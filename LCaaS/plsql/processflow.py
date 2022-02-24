SCRIPT_VERSION = ""
import os,re,glob,json,copy
from pymongo import MongoClient
import xlrd
import pytz
import datetime
import requests
time_zone = 'Asia/Calcutta'
tz = pytz.timezone(time_zone)


file_path = "D:\WORK\plsql\*"

mongoClient = MongoClient('localhost', 27017)
db = mongoClient['plsql_proc']

METADATA = []
procNameList = []
funcNameList = []

comp_list = db.object_list.find({'type': {"$ne": "metadata"}}, {'_id': 0})

try:
    db.procedure_flow_table.remove()
    db.cross_reference_report.remove()
    print("db removed")
except Exception as e:
    print(e)

for comp in comp_list:
    if comp['component_type'] == "PROCEDURE" :
        procNameList.append(comp['component_name'])
    elif comp['component_type'] == "FUNCTION" :
        funcNameList.append(comp['component_name'])

data_json = {"component_name": "",
             "component_type": "",
             "called_name": "",
             "called_type": "",
             "comments":"inline"
             }

def Remove(duplicate):

    final_list = []
    for list_iter in duplicate:
        if list_iter not in final_list:
            final_list.append(list_iter)
    return final_list

def procDivision(filename):

    count = 0
    dict = {}
    comment_flag = False
    procedure_name = ""
    procedure_flag = False
    procedure_open_flag = False
    storage = []
    begin_counter = 0
    case_counter = 0



    f = open(filename, "r")
    for line in f.readlines():
        line = line.strip()

        if line == "":
            continue
        if line.endswith("*/"):
            comment_flag = False
            continue

        if comment_flag:
            continue

        if line.startswith("/*"):
            comment_flag = True
            continue

        if line.startswith("--"):
            continue

        if (line == "END" + " " + procedure_name + ";") or (begin_counter == 1 and re.search("^END;", line) and case_counter ==0):
            begin_counter = 0
            storage.append(line)
            if fun_name in dict:
                dict[fun_name].extend(copy.deepcopy(storage))
            else:
                dict[fun_name] = copy.deepcopy(storage)
            storage.clear()
            procedure_flag = False

        if procedure_flag:
            if re.search("BEGIN.*", line):
                begin_counter = begin_counter + 1

            if begin_counter >= 1 and  (line.strip().startswith("CASE")or line.strip().startswith("(SELECT CASE")):
                case_counter = case_counter + 1

            if case_counter ==0 and (re.search("^END;", line) or re.search("^END$", line.strip())) :
                begin_counter = begin_counter - 1

            if case_counter > 0 and (re.search("^END;", line) or line.strip().startswith("END")):
                case_counter = case_counter - 1
            count = count + 1
            storage.append(line.replace("-->>", "").replace("->", ""))
            continue

        if procedure_open_flag:
            if re.search("BEGIN.*", line):
                begin_counter = begin_counter + 1
                procedure_flag = True
                procedure_open_flag = False
                fun_name = procedure_name
                continue
            else:
                continue

        if re.search("PROCEDURE.*", line):
            try:
                print("PROCE_PACKAGE:", line)
                line = line.split()
                if len(line) > 1:
                    procedure_name = line[1]
                    print("PROCEDURE_NAME:", procedure_name)
                    procedure_open_flag = True
            except Exception as e:
                print(e)

    return dict

def funcDivision(filename):
    fundict = {}
    procName = ""
    flag = False
    storage = []


    f = open(filename, "r")
    for line in f.readlines():
        if line.strip() == "":
            continue
        if line.startswith("--") or line.__contains__("--"):
            continue

        splist = line.split()

        if splist[0] == "FUNCTION":
            procName = splist[1]
            flag = True

        if len(splist)>1 and splist[0].lower() == "end" and splist[1] == procName + ";":
            if procName == "":
                continue
            fundict[procName] = copy.deepcopy(storage)
            storage.clear()
            flag = False

        if flag:
            storage.append(line)

    return fundict

def packageVsProc(filename):


    f = open(filename,"r")
    for line in f.readlines():
        if line.strip() == "":
            continue

        splist = line.split()
        if splist[0] == "PROCEDURE":
            data_json.clear()
            data_json["filename"] = filename
            data_json["component_name"] = filename.split("\\")[-1].split(".")[0]
            data_json["component_type"] = "Package Body"
            data_json["called_name"] = splist[1]
            data_json["called_type"] = "Procedure"
            data_json["comments"] = "inline"

            # data_json1 = copy.deepcopy(data_json)

            METADATA.append(copy.deepcopy(data_json))
            # print(splist[1])


    return METADATA

def packageVsFunction():
    for filename in glob.glob(os.path.join(file_path,"*.pkb")):
        f = open(filename,"r")
        for line in f.readlines():
            if line.strip() == "":
                continue

            splist = line.split()
            if splist[0] == "FUNCTION":
                data_json.clear()
                data_json["filename"] = filename
                data_json["component_name"] = filename.split("\\")[-1].split(".")[0]
                data_json["component_type"] = "Package Body"
                data_json["called_name"] = splist[1]
                data_json["called_type"] = "Procedure"
                data_json["comments"] =   "inline"
                # data_json1 = copy.deepcopy(data_json)

                METADATA.append(copy.deepcopy(data_json))
                # print(splist[1])


    return METADATA

def procVsProc(procDict,funcDict,filename):

    procNameList.extend(procDict.keys())
    funcNameList.extend(funcDict.keys())

    for k in procDict:
        for ele in procNameList:
            for line in procDict[k]:
                    # print(line)
                    if line.__contains__(" "+ele) and not (line.__contains__("PROCEDURE") )and not (line.__contains__("::")) and not (line.__contains__("'"+ele)) and not (line.__contains__("END "+ele) ):
                        data_json.clear()

                        data_json["filename"] = filename
                        data_json["component_name"] = k
                        data_json["component_type"] = "Procedure"
                        data_json["called_name"] = ele
                        data_json["called_type"] = "Procedure"
                        data_json["comments"] = "inline"
                        METADATA.append(copy.deepcopy(data_json))

                    if line.lower().__contains__("pkg."):
                        # print(k+"------->",line.strip().split("Pkg.")[-1].split("(")[0])
                        # line = line.strip()
                        # print(line)
                        # line = line.split("PKG.")[1]
                        # print(line)
                        # line = line.split("(")[0].replace(";", "").replace("IF", "")

                        try:
                            data_json.clear()

                            data_json["filename"] = filename

                            data_json["component_name"] = k
                            data_json["component_type"] = "Procedure"
                            if line.__contains__("PKG."):
                                data_json["called_name"] = line.strip().split("PKG.")[1].split("(")[0].replace(";","").replace("IF","")

                            elif line.__contains__("pkg."):
                                data_json["called_name"] = line.strip().split("pkg.")[1].split("(")[0].replace(";",
                                                                                                               "").replace("IF", "")
                            data_json["called_type"] = "Procedure"
                            data_json["comments"] = "inline"
                            METADATA.append(copy.deepcopy(data_json))
                        except Exception as e:
                            raise Exception(e, line)


        for ele in funcNameList:
            for line in procDict[k]:

                if line.__contains__(" "+ele) and not (line.__contains__("FUNCTION"))and not (line.__contains__("'"+ele))and not (line.__contains__("::")):
                    data_json.clear()
                    data_json["filename"] = filename
                    data_json["component_name"] = k
                    data_json["component_type"] = "Procedure"
                    data_json["called_name"] = ele
                    data_json["called_type"] = "FUNCTION"
                    data_json["comments"] = "inline"
                    METADATA.append(copy.deepcopy(data_json))

    return METADATA

def funVsFun(procDict,funcDict,filename):

    funcNameList.extend(funcDict.keys())
    procNameList.extend(procDict.keys())
    for k in funcDict:
        for ele in funcNameList:
            for line in funcDict[k]:
                    # print(line)

                    if line.__contains__(" "+ele) and not (line.__contains__("FUNCTION") )and not (line.__contains__("::")):
                        data_json.clear()
                        data_json["filename"] = filename
                        data_json["component_name"] = k
                        data_json["component_type"] = "FUNCTION"
                        data_json["called_name"] = ele
                        data_json["called_type"] = "FUNCTION"
                        data_json["comments"] = "inline"
                        METADATA.append(copy.deepcopy(data_json))

                    # if line.lower().__contains__(":="):

                    """
                    required proper pattren to handle :=
                    """

                    #    splist = line.split(":=")
                    #    try:
                    #         if splist[-1].strip()[0].isnumeric() or splist[-1].strip() == "" or splist[-1].strip()[0] == "'":
                    #             pass
                    #
                    #         else:
                    #
                    #             if splist[-1].__contains__("(")  :
                    #                 data_json.clear()
                    #                 data_json["filename"] = filename
                    #                 data_json["component_name"] = k
                    #                 data_json["component_type"] = "FUNCTION"
                    #                 data_json["called_name"] = splist[-1].split("(")[0].split()[-1]
                    #                 data_json["called_type"] = "FUNCTION"
                    #                 data_json["comments"] = line
                    #
                    #                 METADATA.append(copy.deepcopy(data_json))
                    #
                    #             else:
                    #                 data_json.clear()
                    #                 data_json["filename"] = filename
                    #                 data_json["component_name"] = k
                    #                 data_json["component_type"] = "FUNCTION"
                    #                 data_json["called_name"] = splist[-1].strip()
                    #                 data_json["called_type"] = "FUNCTION"
                    #                 data_json["comments"] = line
                    #
                    #                 METADATA.append(copy.deepcopy(data_json))
                    #
                    #    except IndexError as e:
                    #         pass


        for ele in procNameList:
            for line in funcDict[k]:

                if line.__contains__(" "+ele) and not (line.__contains__("PROCEDURE"))and not (line.__contains__("::"))and not (line.__contains__("::")):
                    data_json.clear()
                    data_json["filename"] = filename
                    data_json["component_name"] = k
                    data_json["component_type"] = "FUNCTION"
                    data_json["called_name"] = ele
                    data_json["called_type"] = "Procedure"
                    data_json["comments"] = "inline"

                    METADATA.append(copy.deepcopy(data_json))

    return METADATA

def readExcel():

    path_to_excel = 'D:\\WORK\\plsql\\CrossReference.xlsx'
    sheet_index = 1

    workbook = xlrd.open_workbook(path_to_excel)
    sheet = workbook.sheet_by_index(sheet_index)

    component_type = 'PACKAGE'
    cross_reference_json_data = []
    cross_reference_json_headers = ['component_name', 'component_type', 'called_name', 'called_type']

    # db.cross_reference.insert(meta_data)

    for row_number in range(1, sheet.nrows):
        row_values = sheet.row_values(row_number)
        called_list = row_values[1].split(' ')
        type_position = 0
        if 'PROCEDURE' in called_list:
            type_position = called_list.index('PROCEDURE')
        elif 'FUNCTION' in called_list:
            type_position = called_list.index('FUNCTION')
        if '(' in called_list[type_position + 1]:
            called_list = called_list[type_position + 1].split('(')
        cross_reference_json = {
            'component_name': row_values[0],
            'component_type': component_type,
            'called_name': called_list[type_position + 1],
            'called_type': called_list[type_position],
            'comments': 'standalone'
        }
        try:
            # db.cross_reference.insert(cross_reference_json)
            METADATA.append(cross_reference_json)
        except Exception as e:
            print(e, 'Error during inserting record')

def populate_object_list_db():
    path_to_excel = 'D:\\WORK\\plsql\\CrossReference.xlsx'
    other_sheet_index = 0
    workbook = xlrd.open_workbook(path_to_excel)
    other_sheet = workbook.sheet_by_index(other_sheet_index)
    procedure_json_data = []
    procedure_json_headers = ['component_name', 'component_type']
    meta_data = {'type': 'metadata', 'headers': procedure_json_headers}
    db.object_list.remove()
    db.object_list.insert(meta_data)

    for row_numb in range(1, other_sheet.nrows):
        other_row_values = other_sheet.row_values(row_numb)
        procedure_component_name = other_row_values[0]
        procedure_component_type = other_row_values[1]
        procedure_json = {
            'component_name': procedure_component_name,
            'component_type': procedure_component_type
        }
        try:
            db.object_list.insert(procedure_json)
        except Exception as e:
            print(e, 'Error during inserting record')
        procedure_json_data.append(procedure_json)
    # print('List of procedures: ', procedure_json_data)
    print('Object List inserted')


def ProcessFlow(metadata,filename,procDict,funcDict, flag):
    # import json
    # open_file = open(r'D:\Santhanam\input_json.json')

    data = metadata
    dead_param = []
    key_list = []
    val_list = []
    Metadata = []
    out_dict={}
    file_with_ext=filename.split('\\')[-1]
    d={}
    if(flag==0):
        for d1 in data:

            d['from']=d1['component_name']
            d['to']=d1['called_name']
            d['name']=d1['component_name']
            Metadata.append(d)
    else:
        for d1 in data:
            key_list.append(str(d1['component_name']).upper())
            val_list.append(((d1['called_name']).upper()))

        for key, val in zip(key_list, val_list):
            d = {}
            if (key not in val_list):
                dead_param.append(key)
                d['from'] = key
                d['to'] = val
                d['name'] = key
                Metadata.append(d)

            else:
                d['from'] = key
                d['to'] = val
                d['name'] = key
                Metadata.append(d)
    import json
    Metadata.extend(pocvstable(procDict,funcDict,filename))
    out_dict={file_with_ext:Remove(Metadata)}
    print(json.dumps(Remove(out_dict), indent=4))

    r= requests.post('http://localhost:5009/api/v1/update/procedureFlow', json={"data": out_dict})


    print(r.status_code)
    print(r.text)
    print("prcflow-->",filename)

    # print(list(set(dead_param)))
    return dead_param

def pocvstable(proclist,funclist,filename):
    db1 = mongoClient['plsql']
    # curd_cursy = db1.crud_report.find({"component_name": filename.split("\\")[-1].split(".")[0], })
    # CRUD_DATA = [x for x in curd_cursy]
    METADATA = []

    for ele in proclist:
        d = {}
        curd_cursy = db1.crud_report.find({"component_name": filename.split("\\")[-1].split(".")[0],"Procedure" : ele})
        for doc in curd_cursy:
            d['from'] = ele
            d['to'] = doc["Table"]
            d['name'] = "TABLE"
            METADATA.append(d)

    return  METADATA



for filename in glob.glob(os.path.join(file_path,"*.pkb")):#igonre pack specs
    f = open(filename, "r")
    print("FILE NAME --------->",filename)
    # for index,line in enumerate(f.readlines()):
    #     if index == 0 and line.__contains__("CREATE OR REPLACE PACKAGE BODY"):
    packageVsProc(filename)
    procDict = procDivision(filename)
    funcDict = funcDivision(filename)
    procVsProc(procDict,funcDict,filename)
    funVsFun(procDict,funcDict,filename)
    # pocvstable(procDict.keys(),funcDict.keys(),filename)

    # readExcel()
    # populate_object_list_db()
    ProcessFlow(Remove(METADATA), filename,procDict,funcDict,flag=1)
    db.cross_reference_report.insert_many(Remove(METADATA))


    METADATA.clear()
            # print(json.dumps(procDict,indent=4))
    # print(json.dumps(Remove(METADATA),indent=4))
    # print(len(Remove(METADATA)))
    #



for filename in glob.glob(os.path.join(file_path,"*.prc")):
    storage = []
    procdict = {}
    funcDict={}
    procName=''
    flag =False
    f = open(filename, "r")
    for index,line in enumerate(f.readlines()):
        if line.strip() == "":
            continue
        if line.startswith("--") or line.__contains__("--"):
            continue
        else:
            splist = line.upper().split()
            if index == 0 and line.__contains__("CREATE"):

                # print(splist)
                proc_index = splist.index("PROCEDURE")
                procName = splist[proc_index+1].replace("(","")
                flag = True


            if len(splist)>1 and splist[0].lower() == "end" and splist[1] == procName + ";":
                procdict[procName] = copy.deepcopy(storage)
                storage.clear()
                flag = False

            if flag:
                storage.append(line)
    # procdict[procName] = copy.deepcopy(storage)
    procVsProc(procdict,funcDict)
    # print(json.dumps(METADATA,indent = 4))
    if len(METADATA)==0:

      d= {  "component_name":  filename.split("\\")[-1].split(".")[0],
        "nodes": [
            {
                "id": "p_"+ filename.split("\\")[-1].split(".")[0].upper(),
                "label":  filename.split("\\")[-1].split(".")[0].upper()
            }
        ],
            "links": []
        }
      db.procedure_flow_table.insert_one(d)

    else:
        ProcessFlow(METADATA, filename, flag=0)

    # db.cross_reference_report.insert_many(METADATA)
    METADATA.clear()


for filename in glob.glob(os.path.join(file_path,"*.fnc")):
    storage = []
    procdict = {}
    funcDict={}
    procName=''
    f = open(filename, "r")
    for index,line in enumerate(f.readlines()):
        if line.strip() == "":
            continue
        if line.startswith("--") or line.__contains__("--"):
            continue
        else:
            if index == 0 and line.__contains__("CREATE"):
                splist = line.upper().split()
                # print(splist)
                proc_index = splist.index("FUNCTION")
                procName = splist[proc_index+1].replace("(","")
            storage.append(line)

    procdict[procName] = copy.deepcopy(storage)
    funVsFun(procdict,funcDict)

    if len(METADATA)==0:

      d= {  "component_name":  filename.split("\\")[-1].split(".")[0],
        "nodes": [
            {
                "id": "p_"+ filename.split("\\")[-1].split(".")[0].upper(),
                "label":  filename.split("\\")[-1].split(".")[0].upper()
            }
            ],
        "links": []
        }
      db.procedure_flow_table.insert_one(d)
    else:
        ProcessFlow(METADATA, filename,flag=0)

    # db.cross_reference_report.insert_many(METADATA)
    METADATA.clear()


for filename in glob.glob(os.path.join(file_path,"*.trg")):
    storage = []
    procdict = {}
    funcDict={}
    procName=''
    f = open(filename, "r")
    for index,line in enumerate(f.readlines()):
        if line.strip() == "":
            continue
        if line.startswith("--") or line.__contains__("--"):
            continue
        else:
            if index == 0 and line.__contains__("CREATE"):
                splist = line.upper().split()
                # print(splist)
                proc_index = splist.index("TRIGGER")
                procName = splist[proc_index+1].replace("(","")
            storage.append(line)

    procdict[procName] = copy.deepcopy(storage)
    funVsFun(procdict,funcDict)#need to change based on trigger call syntax

    if len(METADATA)==0:

      d= {  "component_name":  filename.split("\\")[-1].split(".")[0],
        "nodes": [
            {
                "id": "p_"+ filename.split("\\")[-1].split(".")[0].upper(),
                "label":  filename.split("\\")[-1].split(".")[0].upper()
            }
            ],
        "links": []

        }
      db.procedure_flow_table.insert_one(d)
    else:
        ProcessFlow(METADATA, filename,flag=0)


    # db.cross_reference_report.insert_many(METADATA)
    METADATA.clear()


db.cross_reference_report.insert_one({"type" : "metadata",
    "headers" : [


    "component_name",
        "component_type",
        "called_name",
        "called_type",

    ]})