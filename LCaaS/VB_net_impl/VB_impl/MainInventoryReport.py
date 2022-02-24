import glob ,copy, os ,re ,xlsxwriter , json, requests
import requests
# import config

import time
start_time = time.time()

# code_location=config.codebase_information['code_location']
code_location="D:\Lcaas_imp\WebApplications\LobPF"
CobolPath=code_location+'\\'+'*'

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
def main():
     for path, subdirs, files in os.walk(code_location):
        for name in files:
            filename=os.path.join(path, name)
            Type = OtherType(filename)
            if Type.strip().endswith('.aspx'):
                Type = "Aspx"
                html_fun(filename, Type)
            elif Type.strip().endswith('.js'):
                Type="Javascript"
                js_fun(filename,Type)
            else:
                if Type.upper() ==".VB":
                    Type="BusinessComponent"
                elif Type.upper() ==".ASPX.VB":
                    Type="CodeBehind"
                ProgramType(filename, Type)


def ProgramType(filename,Type):
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
     programname=open(filename,"r")
     for line1 in programname.readlines():
        Loc=Loc+1
        try:
         if line1.strip().startswith("'"):
            CommentLines=CommentLines+1
            continue
         elif line1.strip()=="":
            EmptyLines=EmptyLines+1
        except Exception:
            print(filename)
            print(line1)
            print("The given code is not in the Specified Format.")
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
        METADATA.append({"component_name":Filename,"component_type":Type,"Loc":Loc,"commented_lines":CommentLines,
                         "blank_lines":EmptyLines,"Sloc":Sloc,"Path":filename,"application":application,"orphan":Orphan,
                         "Active":Active,"execution_details":execution_details, "no_of_variables":no_of_variables,
                         "no_of_dead_lines":no_of_dead_lines, "cyclomatic_complexity":cyclomatic_complexity,
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

def html_fun(filename,Type):
    Temp_filename = filename
    Temp_filename = Temp_filename.split("\\")
    TempLen = len(Temp_filename)
    Filename = Temp_filename[TempLen - 1]
    # Filename=Filename.split(".")
    ProgramName.append(Filename)
    NumberOfCodes = []
    JsonList = []
    JsonList.append(Filename)
    LinesOfCode = ["ComponentType", "Loc", "commentLines", "EmptyLines", "Sloc", "Path"]
    CommentLines = 0
    EmptyLines = 0
    Loc = 0
    a = {}
    empty = "                                                                 "
    i = 0
    j = 0
    try:
        programname = open(filename, "r")
        comment_line_flag=False
        for line1 in programname.readlines():
            Loc = Loc + 1
            try:
                if line1.strip().startswith("<!--"):
                    comment_line_flag = True
                if line1.strip().startswith("<!--"):
                    CommentLines = CommentLines + 1
                    print(line1)
                    if comment_line_flag:
                        if line1.strip().endswith("-->") or line1.strip().__contains__('-->'):
                            comment_line_flag = False
                    continue
                elif line1.strip() == "":
                    EmptyLines = EmptyLines + 1
            except Exception:
                print(filename)
                print(line1)
                print("The given code is not in the Specified Format.")
        if Loc != 0:
            Sloc = Loc - CommentLines - EmptyLines
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
            # JsonList.append(no_of_dead_variables)
            JsonList.append(no_of_dead_lines)
            JsonList.append(cyclomatic_complexity)
            JsonList.append("")
            JsonList.append("")
            JsonList.append("")
            METADATA.append(
                {"component_name": Filename, "component_type": Type, "Loc": Loc, "commented_lines": CommentLines,
                 "blank_lines": EmptyLines, "Sloc": Sloc, "Path": filename, "application": application,
                 "orphan": Orphan,
                 "Active": Active, "execution_details": execution_details, "no_of_variables": no_of_variables,
                 "no_of_dead_lines": no_of_dead_lines, "cyclomatic_complexity": cyclomatic_complexity,
                 "dead_para_count": "", "dead_para_list": "", "total_para_count": "", "comments": ""})

            Loc = 0
            CommentLines = 0
            EmptyLines = 0
            TempList = copy.deepcopy(NumberOfCodes)
            for i in range(len(LinesOfCode)):
                a[LinesOfCode[i]] = TempList[i]
            TempDict = copy.deepcopy(a)
            MainList.append(JsonList)
            a.clear()
            c.append(TempDict)
            NumberOfCodes.clear()
            i = i + 1

        j = j + 1
    except IOError:
        print("Already open")

    for index in range(len(c)):
        Dict[ProgramName[index]] = c[index]
    programname.close()

def js_fun(filename,Type):
    Temp_filename = filename
    Temp_filename = Temp_filename.split("\\")
    TempLen = len(Temp_filename)
    Filename = Temp_filename[TempLen - 1]
    # Filename=Filename.split(".")
    ProgramName.append(Filename)
    NumberOfCodes = []
    JsonList = []
    JsonList.append(Filename)
    LinesOfCode = ["ComponentType", "Loc", "commentLines", "EmptyLines", "Sloc", "Path"]
    CommentLines = 0
    EmptyLines = 0
    Loc = 0
    a = {}
    empty = "                                                                 "
    i = 0
    j = 0
    try:
        programname = open(filename, "r")
        comment_line_flag=False
        for line1 in programname.readlines():
            Loc = Loc + 1
            try:
                if line1.strip().startswith("/*"):
                    comment_line_flag=True
                if line1.strip().startswith("//") or comment_line_flag:
                    CommentLines = CommentLines + 1
                    if comment_line_flag:
                        if line1.strip().endswith("*/") or line1.strip().__contains__('*/'):
                            comment_line_flag=False
                    continue
                elif line1.strip() == "":
                    EmptyLines = EmptyLines + 1
            except Exception:
                print(filename)
                print(line1)
                print("The given code is not in the Specified Format.")
        if Loc != 0:
            Sloc = Loc - CommentLines - EmptyLines
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
            # JsonList.append(no_of_dead_variables)
            JsonList.append(no_of_dead_lines)
            JsonList.append(cyclomatic_complexity)
            JsonList.append("")
            JsonList.append("")
            JsonList.append("")
            METADATA.append(
                {"component_name": Filename, "component_type": Type, "Loc": Loc, "commented_lines": CommentLines,
                 "blank_lines": EmptyLines, "Sloc": Sloc, "Path": filename, "application": application,
                 "orphan": Orphan,
                 "Active": Active, "execution_details": execution_details, "no_of_variables": no_of_variables,
                 "no_of_dead_lines": no_of_dead_lines, "cyclomatic_complexity": cyclomatic_complexity,
                 "dead_para_count": "", "dead_para_list": "", "total_para_count": "", "comments": ""})

            Loc = 0
            CommentLines = 0
            EmptyLines = 0
            TempList = copy.deepcopy(NumberOfCodes)
            for i in range(len(LinesOfCode)):
                a[LinesOfCode[i]] = TempList[i]
            TempDict = copy.deepcopy(a)
            MainList.append(JsonList)
            a.clear()
            c.append(TempDict)
            NumberOfCodes.clear()
            i = i + 1

        j = j + 1
    except IOError:
        print("Already open")

    for index in range(len(c)):
        Dict[ProgramName[index]] = c[index]
    programname.close()

def ExcelWriting():
    #Columns = ["component_name", "component_type", "Loc", "commented_lines", "blank_lines", "Sloc", "Path",
    #           "Application", "orphan", "Active", "execution_details", "no_of_variables", "no_of_dead_variables",
    #           "no_of_dead_lines", "cyclomatic_complexity"]

    workbook = xlsxwriter.Workbook('Master Inventory Report.xlsx')
    worksheet = workbook.add_worksheet("Master Inventory Report")
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

def OtherType(filepath):
    Temp_filename=filepath
    Temp_filename=Temp_filename.split("\\")
    TempLen=len(Temp_filename)
    Filename=Temp_filename[TempLen-1]
    Filename_len=Filename.index('.')
    Type=Filename[Filename_len:]
    return Type


main()
ExcelWriting()
Columns=["component_name","component_type","Loc","commented_lines","blank_lines","Sloc","Path","application","orphan","Active",  "execution_details", "no_of_variables","no_of_dead_lines", "cyclomatic_complexity","dead_para_count","dead_para_list","total_para_count","comments"]
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


#print(JsonList)

#print(METADATA)
r = requests.post('http://localhost:5000/api/v1/update/masterInventory', json={"data":METADATA,"headers":["component_name","component_type","Loc","commented_lines","blank_lines","Sloc","application", "no_of_dead_lines", "cyclomatic_complexity","dead_para_count","total_para_count","comments"]})
print(r.status_code)
print(r.text)











