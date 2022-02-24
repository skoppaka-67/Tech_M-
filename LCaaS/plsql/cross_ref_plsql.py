SCRIPT_VERSION = ""
import os,re,glob,json,copy
from pymongo import MongoClient
import xlrd
import pytz
import datetime
time_zone = 'Asia/Calcutta'
tz = pytz.timezone(time_zone)


file_path = "D:\WORK\plsql\*"

mongoClient = MongoClient('localhost', 27017)
db = mongoClient['plsql']

METADATA = []
procNameList = []
funcNameList = []



comp_list = db.object_list.find({'type': {"$ne": "metadata"}}, {'_id': 0})

for comp in comp_list:
    if comp['component_type'] == "PROCEDURE" :
        procNameList.append(comp['component_name'])
    elif comp['component_type'] == "FUNCTION" :
        funcNameList.append(comp['component_name'])

data_json = {"component_name": "",
             "component_type": "",
             "calling_app_name": "",
             "called_app_name": "",
             "called_name": "",
             "called_type": "",
             "comments":""

             }

def Remove(duplicate):

    final_list = []
    for list_iter in duplicate:
        if list_iter not in final_list:
            final_list.append(list_iter)
    return final_list

def procDivision():

    procdict = {}
    procName = ""
    flag = False
    storage = []

    for filename in glob.glob(os.path.join(file_path, "*.pkb")):
        f = open(filename, "r")
        for line in f.readlines():
            try:
                if line.strip() == "":
                    continue
                if line.startswith("--") or line.__contains__("--"):
                    continue

                splist = line.split()

                if splist[0] == "PROCEDURE":
                    procName = splist[1]
                    flag = True



                if len(splist)>1 and splist[0].lower() == "end" and splist[1] == procName + ";":
                    procdict[procName] = copy.deepcopy(storage)
                    storage.clear()
                    flag = False

                if flag:
                    storage.append(line)
            except Exception as e:
                print(e,splist)



    return procdict

def funcDivision():
    fundict = {}
    procName = ""
    flag = False
    storage = []

    for filename in glob.glob(os.path.join(file_path, "*.pkb")):
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
                fundict[procName] = copy.deepcopy(storage)
                storage.clear()
                flag = False

            if flag:
                storage.append(line)

    return fundict

def packageVsProc():


    for filename in glob.glob(os.path.join(file_path,"*.pkb")):
        f = open(filename,"r")
        for line in f.readlines():
            if line.strip() == "":
                continue

            splist = line.split()
            if splist[0] == "PROCEDURE":
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
                data_json["component_name"] = filename.split("\\")[-1].split(".")[0]
                data_json["component_type"] = "Package Body"
                data_json["called_name"] = splist[1]
                data_json["called_type"] = "Procedure"
                data_json["comments"] = "inline"
                # data_json1 = copy.deepcopy(data_json)

                METADATA.append(copy.deepcopy(data_json))
                # print(splist[1])


    return METADATA

def procVsProc(procDict,funcDict):

    procNameList.extend(procDict.keys())
    funcNameList.extend(funcDict.keys())

    for k in procDict:
        for ele in procNameList:
            for line in procDict[k]:

                    if line.__contains__(" "+ele) and not (line.__contains__("PROCEDURE") )and not (line.__contains__("::")) and not (line.__contains__("'"+ele)):
                        data_json["component_name"] = k
                        data_json["component_type"] = "Procedure"
                        data_json["called_name"] = ele.replace(";","")
                        data_json["called_type"] = "Procedure"
                        data_json["comments"] = "inline"
                        METADATA.append(copy.deepcopy(data_json))

                    if line.lower().__contains__("pkg."):
                        # print(k+"------->",line.strip().split("Pkg.")[-1].split("(")[0])

                        data_json["component_name"] = k
                        data_json["component_type"] = "Procedure"

                        data_json["called_name"] = line.strip().split("(")[0].replace("IF","")
                        # print(line.strip().split("Pkg."))
                        data_json["called_type"] = "Procedure"
                        data_json["comments"] = "External"
                        METADATA.append(copy.deepcopy(data_json))

        for ele in funcNameList:
            for line in procDict[k]:

                if line.__contains__(" "+ele) and not (line.__contains__("FUNCTION"))and not (line.__contains__("::"))and not (line.__contains__("'"+ele)):
                    data_json["component_name"] = k
                    data_json["component_type"] = "Procedure"
                    data_json["called_name"] = ele.replace(";","")
                    data_json["called_type"] = "Function"
                    data_json["comments"] = "inline"
                    METADATA.append(copy.deepcopy(data_json))

    return METADATA

def funVsFun(procDict,funcDict):

    funcNameList.extend(funcDict.keys())
    procNameList.extend(procDict.keys())
    for k in funcDict:
        for ele in funcNameList:
            for line in funcDict[k]:

                    if line.__contains__(" "+ele) and not (line.__contains__("FUNCTION") )and not (line.__contains__("::"))and not (line.__contains__("'"+ele)):
                        data_json["component_name"] = k
                        data_json["component_type"] = "Function"
                        data_json["called_name"] = ele.replace(";","")
                        data_json["called_type"] = "Function"
                        data_json["comments"] = "inline"
                        METADATA.append(copy.deepcopy(data_json))

                    if line.lower().__contains__(":="):
                        splist = line.split(":=")
                        try:
                            if splist[-1].strip()[0].isnumeric() or splist[-1].strip() == "" or splist[-1].strip()[0] == "'":
                                pass

                            else:

                                if splist[-1].__contains__("("):
                                    data_json["component_name"] = k
                                    data_json["component_type"] = "Function"
                                    data_json["called_name"] = splist[-1].split("(")[0].replace(";","")
                                    data_json["called_type"] = "Function"
                                    METADATA.append(copy.deepcopy(data_json))

                                else:
                                    data_json["component_name"] = k
                                    data_json["component_type"] = "Function"
                                    data_json["called_name"] = splist[-1].strip().replace(";","")
                                    data_json["called_type"] = "Function"
                                    METADATA.append(copy.deepcopy(data_json))

                        except IndexError as e:
                            pass


        for ele in procNameList:
            for line in funcDict[k]:

                if line.__contains__(" "+ele) and not (line.__contains__("PROCEDURE"))and not (line.__contains__("::"))and not (line.__contains__("'"+ele)):
                    data_json["component_name"] = k
                    data_json["component_type"] = "Function"
                    data_json["called_name"] = ele.replace(";","")
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

def populate_object_list_db(): # one time loading to the db with excel file
    path_to_excel = 'D:\\WORK\plsql\\CrossReference.xlsx'
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





for filename in glob.glob(os.path.join(file_path,"*.pkb")):#igonre pack specs

    f = open(filename, "r")
    for index,line in enumerate(f.readlines()):
        type = "PACKAGE"
        if index == 0 and line.__contains__("CREATE OR REPLACE PACKAGE BODY"):
            packageVsProc()
            procDict = procDivision()
            funcDict = funcDivision()
            procVsProc(procDict,funcDict)
            funVsFun(procDict,funcDict)

            readExcel()
            populate_object_list_db()
    #         print(json.dumps(procDict,indent=4))


for filename in glob.glob(os.path.join(file_path,"*.prc")):
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
                proc_index = splist.index("PROCEDURE")
                procName = splist[proc_index+1].replace("(","")
            storage.append(line)

    procdict[procName] = copy.deepcopy(storage)
    procVsProc(procdict,funcDict)


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









print(json.dumps(Remove(METADATA),indent=4))
print(len(Remove(METADATA)))


try:
    db.cross_reference_report.remove()
    print("db removed")
except Exception as e:
    print(e)

h= {"type": "metadata", "headers": ['component_name', 'component_type', 'called_name', 'called_type','comments']}
try:
    db.cross_reference_report.insert_one(h)
    print("Headers added")

except Exception as e:
    print(e)
# Insert into DB
try:

    db.cross_reference_report.insert_many(Remove(METADATA))
    # updating the timestamp based on which report is called
    current_time = datetime.datetime.now(tz=tz).strftime("%A, %d. %B %Y %I:%M%p")
    if db.cross_reference_report.update_one({"type": "metadata"}, {"$set": {"last_updated_on": current_time,
                                                              "time_zone": time_zone,
                                                              # "headers":["component_name","component_type"],
                                                              "script_version": SCRIPT_VERSION
                                                              }}, upsert=True).acknowledged:
        print('update sucess')

except Exception as e:
    print('Error:' + str(e))
