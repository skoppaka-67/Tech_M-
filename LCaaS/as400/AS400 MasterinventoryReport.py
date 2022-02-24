import glob, copy, os, re
import json
import pandas as pd
from collections import OrderedDict
import requests

# dir_path = os.path.dirname(os.path.realpath(__file__))

RPG_Path ="D:\warner\RPG"
CL_Path = 'D:\AS400\CL'
CPY_Path = 'D:\AS400\COPY'
METADATA = []
ProgramName = []
Dict = {}
c = []
MainList = []
METADATA=[]
Dict={}
ProgramName=[]
c=[]
Orphan=""
Active=""
execution_details=""
no_of_variables=""
no_of_dead_variables=""
no_of_dead_lines=""
cyclomatic_complexity=""
MainList=[]
application="Unknown"

# application="Unknown"


def main():
    for filename in glob.glob(os.path.join(RPG_Path, '*.RPG')):
        #print(filename)
        Type = "RPG"
        ProgramType(filename, Type)

    # for filename in glob.glob(os.path.join(CL_Path, '*.CL')):
    #     Type="CL"
    #     ProgramType(filename,Type)
    #
    # for filename in glob.glob(os.path.join(CPY_Path, '*.CPY')):
    #     Type="CPY"
    #     ProgramType(filename,Type)





def ProgramType(filename, Type):
    Temp_filename = filename
    Temp_filename = Temp_filename.split("\\")
    TempLen = len(Temp_filename)
    Filename = Temp_filename[TempLen - 1]
    Filename = Filename.split(".")
    ProgramName.append(Filename[0])
    JsonList = []
    JsonList.append(Filename[0])
    CommentLines = 0
    EmptyLines = 0
    Loc = 0
    programname = open(filename, errors='ignore')
    for line1 in programname.readlines():
        Loc = Loc + 1

        try:

            if (line1.strip() == ''):
                EmptyLines = EmptyLines + 1
                #print(line1,EmptyLines)
                continue


            elif len(line1) < 6:
                continue



            if (line1[6].__contains__("*") or re.search("//",line1)) and Type !="CL" :
                 CommentLines = CommentLines + 1


            # if line1.__contains__("/*") and line1.__contains__("*/")  :
            #     CommentLines = CommentLines + 1

            DATA_LIST = line1.split()
            if len(DATA_LIST) > 1:

                if DATA_LIST[0].__contains__('/*') and DATA_LIST[-1].__contains__('*/'):
                    CommentLines = CommentLines + 1
                    #print(DATA_LIST)
            # print(DATA_LIST)








        except Exception:
            pass

            #print("The given code is not in the Specified Format.",line1)

    if Loc != 0:
        Sloc = Loc - CommentLines - EmptyLines

        METADATA.append(OrderedDict({"component_name": Filename[0].replace(" ","_"), "component_type": Type, "Loc": Loc, "commented_lines": CommentLines,
             "blank_lines": EmptyLines, "Sloc": Sloc, "Path": filename, "application": application, "orphan": Orphan,
             "Active": Active, "execution_details": execution_details, "no_of_variables": no_of_variables,
             "no_of_dead_lines": no_of_dead_lines, "cyclomatic_complexity": cyclomatic_complexity,
             "dead_para_count": "", "dead_para_list": "", "total_para_count": ""}))
        # df = pd.DataFrame(METADATA)
        # writer = pd.ExcelWriter('MasterInventory.xlsx', engine='xlsxwriter')
        # df.to_excel(writer, 'Sheet1', index=False)
        # writer.save()
        print(json.dumps(METADATA,indent=4))


main()

# print(json.dumps(METADATA, indent=4))
r = requests.post('http://localhost:5004/api/v1/update/masterInventory', json={"data":METADATA,"headers":["component_name","component_type","Loc","commented_lines","blank_lines","Sloc","application","no_of_dead_lines", "cyclomatic_complexity","dead_para_count","total_para_count"]})
print(r.status_code)
print(r.text)
