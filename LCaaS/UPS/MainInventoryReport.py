import glob ,copy, os ,re ,xlsxwriter , json, requests
import requests
from flask import    jsonify
from pymongo import MongoClient
import config

import time
start_time = time.time()

code_location=config.codebase_information['code_location']
# code_location="C:\\Lcaas_UPS"
CobolPath=code_location+'\\'+'*'

client = MongoClient('localhost', 27017)
db = client['SSI']

METADATA=[]
Dict={}
ProgramName=[]
c=[]
Orphan=""
Active=""
execution_details=""
no_of_variables=""
Function_Point=""
no_of_dead_variables=""
no_of_dead_lines=""
cyclomatic_complexity=""
MainList=[]
application="Unknown"
def main():

 for filename in glob.glob(os.path.join(CobolPath, '*.cpy')):
     Type="COPYBOOK"
     ProgramType(filename,Type)

 for filename in  glob.glob(os.path.join(CobolPath, '*.cbl')):
     Type="COBOL"
     ProgramType(filename,Type)

 for filename in glob.glob(os.path.join(CobolPath, '*.aps')):
     Type = "APS"
     ProgramType(filename,Type)

 for filename in  glob.glob(os.path.join(CobolPath, '*.jcl')):
     Type="JCL"
     ProgramType(filename,Type)

 for filename in  glob.glob(os.path.join(CobolPath, '*.sysin')):
     Type="SYSIN"
     ProgramType(filename,Type)

 for filename in  glob.glob(os.path.join(CobolPath, '*.prc')):
     Type="PROC"
     ProgramType(filename,Type)

 for filename in glob.glob(os.path.join(CobolPath,'*.bms')):
     Type="BMS"
     ProgramType(filename,Type)
 # for filename in  glob.glob(os.path.join(CobolPath, '*.*')):
 #     Type=OtherType(filename)
 #
 #     if(Type=="cbl"or Type=="CBL")or(Type=="cpy"or Type=="CPY")or(Type=="aps"or Type=="APS")or(Type=="jcl"or Type=="JCL")or(Type=="proc"or Type=="PROC"):
 #
 #        continue
 #     else:
 #       print(filename)
 #       ProgramType1(filename,Type)

def ProgramType(filename,Type):
    # print("Kishore:",Type)
    global Function_Point
    Temp_filename=filename
    Temp_filename=Temp_filename.split("\\")
    TempLen=len(Temp_filename)
    Filename=Temp_filename[TempLen-1]
    #Filename=Filename.split(".")
    ProgramName.append(Filename)
    NumberOfCodes=[]
    JsonList=[]
    JsonList.append(Filename)
    LinesOfCode=["ComponentType","Loc","commentLines","EmptyLines","Sloc","Path"]
    CommentLines=0
    EmptyLines=0
    Loc=0
    a={}
    empty ="                                                                 "
    i=0
    j=0
    try:
     programname=open(filename,"r",errors='ignore',encoding="ISO-8859-1")
     for line1 in programname.readlines():
        print(line1)
        Loc=Loc+1
        try:
             if line1.strip()=="":
                # print("JK:",line1)
                EmptyLines=EmptyLines+1
             if line1.startswith("//*"):
                 print("Comment:",line1)
                 CommentLines = CommentLines + 1
                 continue
             if line1[6]=="*":
                CommentLines=CommentLines+1
                continue
             if Type == "APS":
                 if line1.strip().startswith('/*'):
                     CommentLines=CommentLines+1
                     continue
             if Type == "BMS":
                 if line1.strip().startswith('*'):
                     CommentLines=CommentLines+1
                     continue
                 # if line1.strip()=="":
                 #     EmptyLines=EmptyLines+1

        except Exception:
            print(filename)
            print(line1)
            print("The given code is not in the Specified Format.")
     if Type == "COBOL" or Type == "APS" or Type == "COPYBOOK":
         Function_Point_Capture = Loc - EmptyLines
         Function_Point = round(Function_Point_Capture/107)
     elif Type == "JCL" or Type == "PROC" or Type == "SYSIN":
         Function_Point_Capture = Loc - EmptyLines
         Function_Point = round(Function_Point_Capture/221)
     else:
         Function_Point = ""

     if Loc!=0:
        Sloc=Loc-CommentLines-EmptyLines
        NumberOfCodes.append(Type)
        NumberOfCodes.append(Loc)
        NumberOfCodes.append(CommentLines)
        NumberOfCodes.append(EmptyLines)
        NumberOfCodes.append(Sloc)
        NumberOfCodes.append(filename)
        JsonList.append(Type)
        JsonList.append(Loc)
        JsonList.append(CommentLines)
        JsonList.append(EmptyLines)
        JsonList.append(Sloc)
        JsonList.append(filename)
        JsonList.append(application)
        JsonList.append(Orphan)
        JsonList.append(Active)
        JsonList.append(execution_details)
        JsonList.append(no_of_variables)
        #JsonList.append(no_of_dead_variables)
        JsonList.append(no_of_dead_lines)
        JsonList.append(cyclomatic_complexity)
        JsonList.append(Function_Point)
        JsonList.append("")
        JsonList.append("")
        JsonList.append("")
        METADATA.append({"component_name":Filename,"component_type":Type,"Loc":Loc,"commented_lines":CommentLines,
                         "blank_lines":EmptyLines,"Sloc":Sloc,"Path":filename,"application":application,"orphan":Orphan,
                         "Active":Active,"execution_details":execution_details, "no_of_variables":no_of_variables,
                         "no_of_dead_lines":no_of_dead_lines, "cyclomatic_complexity":cyclomatic_complexity,
                         "FP":Function_Point,
                         "dead_para_count":"","dead_para_list":"","total_para_count":"","comments":""})


        Loc=0
        CommentLines=0
        EmptyLines=0
        TempList=copy.deepcopy(NumberOfCodes)
        for i in range(len(LinesOfCode)):
            a[LinesOfCode[i]]=TempList[i]
        TempDict=copy.deepcopy(a)
        MainList.append(JsonList)
        a.clear()
        c.append(TempDict)
        NumberOfCodes.clear()
        i=i+1

     j=j+1
    except IOError:
        print("Already open")

    for index in range(len(c)):
      Dict[ProgramName[index]]=c[index]
    programname.close()

def ExcelWriting():
    #Columns = ["component_name", "component_type", "Loc", "commented_lines", "blank_lines", "Sloc", "Path",
    #           "Application", "orphan", "Active", "execution_details", "no_of_variables", "no_of_dead_variables",
    #           "no_of_dead_lines", "cyclomatic_complexity"]

    workbook = xlsxwriter.Workbook('Master Inventory Report CBLT.xlsx')
    worksheet = workbook.add_worksheet("Master Inventory Report CBLT")
    Format=workbook.add_format({'bold': True,'bg_color':'yellow','border_color':'black'})
    worksheet.write('A1','Component Name',Format)
    worksheet.write('B1','Component Type',Format)
    worksheet.write('C1','Loc',Format)
    worksheet.write('D1','Commented Loc',Format)
    worksheet.write('E1','Blank Lines',Format)
    worksheet.write('F1','SLOC',Format)
    worksheet.write('G1','Path',Format)
    worksheet.write('H1','Orphan',Format)
    worksheet.write('I1','Active',Format)
    worksheet.write('J1', 'execution_details', Format)
    worksheet.write('K1', 'no_of_variables', Format)
    worksheet.write('L1', 'no_of_dead_variables', Format)
    worksheet.write('M1', 'no_of_dead_lines', Format)
    worksheet.write('N1', 'cyclomatic_complexity', Format)
    worksheet.write('O1', 'FP', Format)

    for index in range(len(ProgramName)):
        worksheet.write(index+1,0,ProgramName[index])
    row=0
    Key=Dict.keys()
    for index in Key:
       one= Dict.get(index)
       col=1
       row=row+1
       for value in one:
          item= one.get(value)
          worksheet.write(row,col,item)
          col=col+1
          if (col==12):
              break
    try:
     workbook.close()
    except IOError:
        print ("Please close the Excel before running the program")

def ProgramType1(filename,Type):
    # if Type=="CBL":
    #     Type="COBOL"
    # else:
    #     Type="COPYBOOK"
    #print(filename)
    Temp_filename=filename
    Temp_filename=Temp_filename.split("\\")
    TempLen=len(Temp_filename)
    Filename=Temp_filename[TempLen-1]
    #Filename=Filename.split(".")
    #Filename=Filename.strip()
    ProgramName.append(Filename)
    NumberOfCodes=[]
    JsonList=[]
    JsonList.append(Filename)
    LinesOfCode=["ComponentType","Loc","commentLines","EmptyLines","Sloc","Path"]
    CommentLines=0
    EmptyLines=0
    Loc=0
    a={}
    i=0
    j=0
    programname=open(filename,"r",errors='ignore',encoding="ISO-8859-1")
    for line1 in programname.readlines():
        Loc=Loc+1
        if line1.startswith("//*"):
            print("Comment:", line1)
            CommentLines = CommentLines + 1
            continue
        # if line1[0]=="*":
        #     CommentLines=CommentLines+1
        #     continue
        elif line1.strip() == "":
            EmptyLines = EmptyLines + 1
    if Loc!=0:
        Sloc=Loc-CommentLines-EmptyLines
        NumberOfCodes.append(Type)
        NumberOfCodes.append(Loc)
        NumberOfCodes.append(CommentLines)
        NumberOfCodes.append(EmptyLines)
        NumberOfCodes.append(Sloc)
        NumberOfCodes.append(filename)
        JsonList.append(Type)
        JsonList.append(Loc)
        JsonList.append(CommentLines)
        JsonList.append(EmptyLines)
        JsonList.append(Sloc)
        JsonList.append(filename)
        JsonList.append(application)
        JsonList.append(Orphan)
        JsonList.append(Active)
        JsonList.append(execution_details)
        JsonList.append(no_of_variables)
        #JsonList.append(no_of_dead_variables)
        JsonList.append(no_of_dead_lines)
        JsonList.append(cyclomatic_complexity)
        JsonList.append("")
        JsonList.append("")
        JsonList.append("")
        METADATA.append(
            {"component_name": Filename, "component_type": Type.upper(), "Loc": Loc, "commented_lines": CommentLines,
             "blank_lines": EmptyLines, "Sloc": Sloc, "Path": filename, "application": application, "orphan": Orphan,
             "Active": Active, "execution_details": execution_details, "no_of_variables": no_of_variables,
             "no_of_dead_lines": no_of_dead_lines, "cyclomatic_complexity": cyclomatic_complexity,
             "dead_para_count": "", "dead_para_list": "", "total_para_count": "","comments":""})


        Loc=0
        CommentLines=0
        EmptyLines=0
        TempList=copy.deepcopy(NumberOfCodes)
        for i in range(len(LinesOfCode)):
            a[LinesOfCode[i]]=TempList[i]
        MainList.append(JsonList)
        TempDict=copy.deepcopy(a)
        a.clear()
        c.append(TempDict)
        NumberOfCodes.clear()
        i=i+1
    j=j+1
    for index in range(len(c)):
      Dict[ProgramName[index]]=c[index]
    programname.close()

def OtherType(filepath):
    Temp_filename=filepath
    Temp_filename=Temp_filename.split("\\")
    TempLen=len(Temp_filename)
    Filename=Temp_filename[TempLen-1]
    Filename=Filename.split(".")
    #Filename=Filename.strip()
    Type=Filename[1]
    return Type


main()
ExcelWriting()
Columns=["component_name","component_type","Loc","commented_lines","blank_lines","Sloc","Path","application","orphan","Active",  "execution_details", "no_of_variables","no_of_dead_lines", "cyclomatic_complexity","FP","dead_para_count","dead_para_list","total_para_count","comments"]

JsonDict={}
JsonDict1={}
JsonDict1['headers']=Columns
JsonDict1['header_count']=len(Columns)
JsonList=[]
for index in range(len(MainList)):
    for index1 in range(len(MainList[index])):
      JsonDict[Columns[index1]]=MainList[index][index1]
    TempDict=copy.deepcopy(JsonDict)
    JsonList.append(TempDict)
    JsonDict.clear()

JsonDict1["data"]=JsonList

# dict1= {}
# h=["component_name","component_type","Loc","commented_lines","blank_lines","Sloc","application", "no_of_dead_lines", "cyclomatic_complexity","dead_para_count","total_para_count","comments"]
# dict1["data"]=METADATA
# dict1["headers"]=h
# db.master_inventory_report.insert_one(dict1)


# print(JsonList)

print(json.dumps(METADATA,indent=4))

r = requests.Session()
r.trust_env = False
# payload = {
#             'username' : "wfg2nbc",
#             'password' : "Apr2020"
#             }

rs = r.post('http://localhost:5000/api/v1/update/masterInventory', json={"data":METADATA,"headers":["component_name","component_type","Loc","commented_lines","blank_lines","Sloc","application", "no_of_dead_lines", "cyclomatic_complexity","dead_para_count","total_para_count","comments"]})
print(rs.status_code)

print(rs.text)











