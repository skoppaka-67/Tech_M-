import re, glob, os, copy, json, xlsxwriter, requests, config
import os.path
from os import path
from pymongo import MongoClient

code_location = config.COBOL_codebase_information['code_location']
JclPath = code_location + '\\' + '*'
client = MongoClient(config.database_COBOL['hostname'], config.database_COBOL['port'])
db = client[config.database_COBOL['database_name']]
SetRegexx = []
ComponentName = []
ComponentType = []
Calledame = []
CalledType = []
Utilities = ["IDCAMS", "IEBCOMPR", "IEBCOPY", "IEBEDIT", "IEBDG", "IEBGENER", "IEBIMAGE", "IEBPTPCH", "IEBUPDTE",
             "IEFBR14", "ICKDSF", "IEHINITT", "IEHLIST", "IEHMOVE", "IEHPROGM", "IFHSTATR", "SPZAP", "SORT", "SYNCSORT",
             "IKJEFT1B", "IKJEFT1A", "IKJEFT01", "ICEGENER", "FTP"]
CobolProg = []
Header = ["file_name", "component_name", "component_type", "calling_app_name", "called_name", "called_type",
          "called_app_name", "dd_name", "access_mode", "step_name", "comments"]
Utility = []
StepName = []
ProcList = []
FileList = []
DispName = []
MainList = []
MainDict = {}
currentstepname = ""
IsDisp = False
sysin_flag = False
Application = ""
DictList = []
DDName = ""
comments = ""


def main():
    for filename in glob.glob(os.path.join(JclPath, '*.jcl')):
        # print(filename)
        Type = "JCL"
        Name = PgmName(filename)
        # print(filename)
        Process(filename, Type, Name)

    for filename in glob.glob(os.path.join(JclPath, '*.proc')):
        # print(filename)
        Type = "PROC"
        Name = PgmName(filename)
        Process(filename, Type, Name)

    for filename in glob.glob(os.path.join(JclPath, '*.SYSIN')):
        Type = "SYSIN"
        Name = PgmName(filename)
        systsin(filename, Type, Name)


def systsin(filename, Type, Name):
    Program_Name = open(filename)
    for line in Program_Name.readlines():
        GlobalStepName = ""
        run_pgm = re.findall(r'.*RUN\s*PROG[R]*[A]*[M]*\s*(.*)\s', line)
        MainList.clear()
        MainDict.clear()
        if run_pgm != []:
            line = run_pgm[0]
            line = line.split('(')
            line = line[1].strip()
            line = line.split(')')
            program_name = line[0].strip()
            MainList.append(Name)
            MainList.append(Name)
            MainList.append(Type)
            MainList.append("")
            MainList.append(program_name)
            MainList.append("COBOL")
            MainList.append("")
            # MainList.append(TempStepName)
            MainList.append("")
            MainList.append("")
            Dict(GlobalStepName)
            TempDict = copy.deepcopy(MainDict)
            if (TempDict != {}):
                DictList.append(TempDict)


def Process(filename, Type, Name):
    GlobalStepName = ""

    Program_Name = open(filename)

    IsDisp = 0
    DispValue = 0
    file_counter = 0
    DBProgram = False
    RunPgm = []
    for line in Program_Name.readlines():
        # print(line)
        if line[0:3] == "//*":
            continue
        elif line[0:2] == "//":

            Regexx = re.findall(r'.*EXEC\s*PGM=.*', line)
            ProcRegexx = re.findall(r'.*\sEXEC\s\w+', line)
            SysinRegexx = re.findall(r'.*DD.*', line)

            if (Regexx != []):
                MainList.clear()
                MainDict.clear()
                GlobalStepName = CheckUtility(Regexx, Name, Type)
                Dict(GlobalStepName)
                TempList = copy.deepcopy(MainList)
                TempDict = copy.deepcopy(MainDict)
                if (TempDict != {}):
                    DictList.append(TempDict)
                continue
            if (ProcRegexx != []):
                MainList.clear()
                MainDict.clear()
                GlobalStepName = CatalogProc(ProcRegexx, Name, Type, line)
                Dict(GlobalStepName)
                TempList = copy.deepcopy(MainList)
                TempDict1 = copy.deepcopy(MainDict)
                if (TempDict1 != {}):
                    DictList.append(TempDict1)
                continue

            if (SysinRegexx != [] or DispValue == 1):

                if DispValue == None or DispValue == 0:
                    MainList.clear()
                    MainDict.clear()
                DispValue = FileRegexx(SysinRegexx, line, Name, Type, IsDisp, GlobalStepName)

                if DispValue == None:
                    Dict(GlobalStepName)
                TempList = copy.deepcopy(MainList)
                TempDict = copy.deepcopy(MainDict)
                if (TempDict != {}):
                    DictList.append(TempDict)

                continue

            if (DispValue == "DBProgram"):

                RunPgm = re.findall(r'.*RUN PROGRAM.*', line)
                if RunPgm != []:
                    DispValue = DBPgm(line, Name, Type, GlobalStepName)
                else:
                    continue
            else:
                continue


def DBPgm(line, Name, Type, GlobalStepName):
    calling_app = "Unknown"
    Application = "Unknown"
    RunPgm = re.findall(r'.*RUN PROGRAM.*', line)
    if RunPgm != []:
        DispValue = None
        TempRunPgm = RunPgm[0]
        TempRunPgm = TempRunPgm.split("PROGRAM")
        TempRunPgm1 = TempRunPgm[1].split()
        TempRunPgm1 = TempRunPgm1[0]
        TempRunPgm1 = re.sub('["()"]', "", TempRunPgm1)
        if (TempRunPgm1 != ""):
            type = "COBOL"
            MainList.append(Name)
            MainList.append(Name)
            MainList.append(Type)
            MainList.append(calling_app)
            MainList.append(TempRunPgm1)
            MainList.append(type)
            MainList.append(Application)
            # MainList.append(TempStepName)
            MainList.append("SYSTSIN")
            MainList.append("")

            Dict(GlobalStepName)
            TempList = copy.deepcopy(MainList)
            TempDict = copy.deepcopy(MainDict)
            if (TempDict != {}):
                DictList.append(TempDict)

                return DispValue


def Dict(GlobalStepName):
    try:
        MainList.append(GlobalStepName)
        MainList.append(comments)

        if MainList != [] and len(MainList) == 11:
            for i in range(len(Header)):
                MainDict[Header[i]] = MainList[i]

    except Exception:
        print("Error in creating dictionary")


def DispUpdate(line):
    TempLine = line.split("DISP=")
    TempLine1 = TempLine[1]
    TempLine1 = TempLine1.split(")")
    TempLine2 = re.sub('["("]', '', TempLine1[0])
    MainList.append(TempLine2)


def PgmName(filename):
    filename = filename.split('\\')
    LengthOfFile = len(filename)
    filename1 = filename[LengthOfFile - 1]
    filename1 = filename1.split('.')
    TempFileName = filename1[0]
    ComponentName.append(TempFileName)
    return TempFileName


def CheckUtility(Regexx, Name, Type):
    calling_app = "Unknown"
    Application = "Unknown"
    Regexxstr = Regexx[0]
    Temp_Regexx = Regexxstr.split()
    TempStepName = Temp_Regexx[0]
    TempStepName = TempStepName.split("//")
    TempStepName = TempStepName[1]
    for data in range(len(Temp_Regexx)):
        if Temp_Regexx[data].startswith('PGM='):
            type1 = "COBOL"
            type2 = "Utility"
            PgmName = Temp_Regexx[data]
            PgmName = PgmName.split('=')
            PgmName = PgmName[1]
            PgmName = PgmName.split(',')
            PgmName = PgmName[0]

            if any(PgmName in String for String in Utilities):
                MainList.append(Name)
                MainList.append(Name)
                MainList.append(Type)
                MainList.append(calling_app)
                MainList.append(PgmName)
                MainList.append(type2)
                MainList.append(Application)
                # MainList.append(TempStepName)
                MainList.append("")
                MainList.append("")
                Utility.append(PgmName)
                StepName.append(TempStepName)
                return TempStepName
            else:
                MainList.append(Name)
                MainList.append(Name)
                MainList.append(Type)
                MainList.append(calling_app)
                MainList.append(PgmName)
                MainList.append(type1)
                MainList.append(Application)
                # MainList.append(TempStepName)
                MainList.append("")
                MainList.append("")
                CobolProg.append(PgmName)
                StepName.append(TempStepName)
                return TempStepName


def CatalogProc(ProcRegexx, Name, Type, line):
    # print("proc")
    calling_app = "Unknown"
    Application = "Unknown"
    type3 = "PROC"
    Regexxstr = ProcRegexx[0]
    Temp_Regexx = Regexxstr.split()
    # print(Temp_Regexx)
    TempStepName = Temp_Regexx[0]
    TempStepName = TempStepName.split("//")
    TempStepName = TempStepName[1]
    Proc1Regexx = re.findall(r'.*EXEC\s*PROC[=]\w+', line)
    if Temp_Regexx[2] != "PGM":
        MainList.append(Name)
        MainList.append(Name)
        MainList.append(Type)
        MainList.append(calling_app)
        PgmName = Temp_Regexx[2]
        PgmName = PgmName.split(',')
        PgmName = PgmName[0]
        if Proc1Regexx != []:
            Proc1Regexxstring = Proc1Regexx[0]
            PgmName = Proc1Regexxstring.split('=')
            PgmName = PgmName[1]
        MainList.append(PgmName)
        MainList.append(type3)
        MainList.append(Application)
        # MainList.append(TempStepName)
        MainList.append("")
        MainList.append("")
        ProcList.append(PgmName)
        StepName.append(TempStepName)
        return (TempStepName)


def FileRegexx(SysinRegexx, line, Name, Type, IsDisp, GlobalStepName):
    calling_app = "Unknown"
    Application = "Unknown"
    global currentstepname

    lengthofmainlist = len(DictList)
    if lengthofmainlist!=0:
        currentstepnamedict = DictList[lengthofmainlist - 1]
        currentstepname = currentstepnamedict["dd_name"]
    # print("asd",currentstepname)

    if SysinRegexx != []:
        type2 = "FILE"
        Regexxstr = SysinRegexx[0]
        Temp_Regexx = Regexxstr.split()
        TempStepName = Temp_Regexx[0]
        TempStepName = TempStepName.split("//")
        TempStepName = TempStepName[1]
        DDName = TempStepName
        TempFile = SysinRegexx[0]
        TempFile1 = SysinRegexx[0]
        TempFile = TempFile.split()

        if TempStepName == "SYSTSIN":
            DsnName = re.findall(r'.*DSN=.*', line)
            if (DsnName != []):
                # Capturing Systsin Name

                systsin_name = DsnName[0].split("=")
                file_line = systsin_name[1]
                file_line = file_line.split(',')[0]

                systsin_name = systsin_name[1]

                file_name = systsin_name[1]
                if line.__contains__("PARMLIB"):
                    systsin_name = systsin_name.split("(")[1]
                    systsin_name = systsin_name.split(")")[0]

                    sysin_Path = code_location + '\\' + 'SYSIN\\' + systsin_name + '.sysin'

                    try:
                        # print("adasfasfasf")
                        with open(sysin_Path, "r+") as sysin_file:
                            for lines in sysin_file.readlines():
                                run_pgm = re.findall(r'.*RUN\s*PROG[R]*[A]*[M]*\s*(.*)\s', lines)

                                # MainList.clear()
                                # MainDict.clear()
                                if run_pgm != []:

                                    line4 = run_pgm[0]
                                    line4 = line4.split('(')
                                    line4 = line4[1].strip()
                                    line4 = line4.split(')')
                                    program_name4 = line4[0].strip()
                                    MainList.append(Name)
                                    MainList.append(Name)
                                    MainList.append(Type)
                                    MainList.append("Unknown")
                                    MainList.append(program_name4)
                                    MainList.append("COBOL")
                                    MainList.append("Unknown")
                                    # MainList.append(TempStepName)
                                    MainList.append("SYSTSIN")
                                    MainList.append("")

                                    # Dict(GlobalStepName)
                                    # print("asfffff",line)
                                    MainList.append(GlobalStepName)
                                    if file_line.__contains__(','):
                                        file_line = file_line.split(',')[0]

                                    MainList.append(file_line)

                                    if MainList != [] and len(MainList) == 11:
                                        for i in range(len(Header)):
                                            MainDict[Header[i]] = MainList[i]

                            return None
                    except:
                        systsin_name = DsnName[0].split("=")
                        file_line = systsin_name[1]
                        file_line = file_line.split(',')[0]

                        if DsnName[0].__contains__("DISP"):
                            len_list = len(systsin_name)

                        MainList.append(Name)
                        MainList.append(Name)
                        MainList.append(Type)
                        MainList.append("Unknown")
                        MainList.append(file_line)
                        MainList.append("SYSTSIN")
                        MainList.append("Unknown")
                        # MainList.append(TempStepName)
                        MainList.append("SYSTSIN")
                        MainList.append(systsin_name[len_list - 1])

                        # Dict(GlobalStepName)
                        MainList.append(GlobalStepName)
                        MainList.append(comments)

                        if MainList != [] and len(MainList) == 11:
                            for i in range(len(Header)):
                                MainDict[Header[i]] = MainList[i]

                            # print(systsin_name)
                        return None


            elif (Temp_Regexx[2] == "*"):
                return "DBProgram"

        for index in range(len(TempFile)):
            if TempFile[index].startswith("PATH="):
                return
        if any("SYSOUT=*" in String for String in TempFile) or any("DUMMY" in String for String in TempFile):
            return
        else:

            DsnName = re.findall(r'.*DSN=.*,', line)

            OverrideDsnName = re.findall(r'.*DSN=.*', line)

            if (DsnName != []):

                DsnName1 = DsnName[0]
                DsnName1 = DsnName1.split()
                DsnName2 = DsnName1[2]
                if DsnName1[2].startswith("DSN="):
                    TempDsnName1 = DsnName2.split(",")
                    TempDsnName2 = TempDsnName1[0].split("=")
                    FileList.append(TempDsnName2[1])
                    MainList.append(Name)
                    MainList.append(Name)
                    MainList.append(Type)
                    MainList.append(calling_app)

                    if DDName == "":
                        DDName = currentstepname

                    if DDName == "SYSTSIN":
                        if TempDsnName2[1].__contains__("("):
                            runpgmname = TempDsnName2[1].split('(')
                            runpgmname = runpgmname[1].split(')')
                            runpgmname = runpgmname[0]
                        else:
                            runpgmname = TempDsnName2[1]
                            MainList.append(runpgmname)
                            MainList.append("SYSTSIN")
                    else:
                        MainList.append(TempDsnName2[1])
                        MainList.append(type2)

                    MainList.append(Application)
                    TempDisp = line.split("DISP")

                    MainList.append(DDName)

                    if len(TempDisp) != 1:
                        TempDisp1 = TempDisp[1]
                        TempDisp1 = TempDisp1.split(")")
                        TempDisp2 = TempDisp1[0]
                        TempDisp2 = re.sub('["=("]', '', TempDisp2)
                        TempDisp2 = TempDisp2.split()
                        TempDisp2 = TempDisp2[0]
                        MainList.append(TempDisp2)

                    else:
                        IsDisp = 1
                        return IsDisp

    else:
        DispVar = re.findall(r'//\s.*DISP=.*', line)

        if DispVar != []:
            DispUpdate(line)
            if len(MainList) == len(Header):
                Dict(GlobalStepName)

            else:

                Dict(GlobalStepName)


        else:
            IsDisp = 1
            return IsDisp


def ExcelWriting():
    workbook = xlsxwriter.Workbook('JCL_Xref.xlsx')
    worksheet = workbook.add_worksheet("JCL_Xref Report")
    Format = workbook.add_format({'bold': True, 'bg_color': 'yellow', 'border_color': 'black'})
    worksheet.write('A1', 'file_name', Format)
    worksheet.write('B1', 'Component Name', Format)
    worksheet.write('C1', 'Component Type', Format)
    worksheet.write('D1', 'called_name', Format)
    worksheet.write('E1', 'called_type', Format)
    worksheet.write('F1', 'application', Format)
    worksheet.write('G1', 'dd_name', Format)
    worksheet.write('H1', 'disp', Format)
    worksheet.write('I1', 'step_name', Format)
    worksheet.write('J1', 'comments', Format)
    r = 1
    c = 0
    for index in range(len(DictList)):
        worksheet.write(r, c, DictList[index].get("file_name"))
        worksheet.write(r, c + 1, DictList[index].get("component_name"))
        worksheet.write(r, c + 2, DictList[index].get("component_type"))
        worksheet.write(r, c + 3, DictList[index].get("called_name"))
        worksheet.write(r, c + 4, DictList[index].get("called_type"))
        worksheet.write(r, c + 5, DictList[index].get("application"))
        worksheet.write(r, c + 6, DictList[index].get("dd_name"))
        worksheet.write(r, c + 7, DictList[index].get("disp"))
        worksheet.write(r, c + 8, DictList[index].get("step_name"))
        worksheet.write(r, c + 9, DictList[index].get("comments"))
        r = r + 1

    try:
        workbook.close()
    except IOError:
        print("Please close the Excel before running the program")


main()
ExcelWriting()

Final_Dict = {}
Final_Dict["data"] = DictList

# print("ff", Final_Dict)

try:
    db.cross_reference_report.insert_many(DictList)
    db.cross_reference_report.insert_one({"type": "metadata", "headers": ["file_name",
                                                                          "component_name",
                                                                          "component_type",
                                                                          "calling_app_name",
                                                                          "called_name",
                                                                          "called_type",
                                                                          "called_app_name",
                                                                          "dd_name", "access_mode",
                                                                          "step_name", "comments"]})
    # print('db update success')
except Exception as e:
    print(e)
    # print('error in inserting db')

# r = requests.post('http://localhost:5000/api/v1/update/crossReference/JCL', json={"data": DictList,
#                                                                                   "headers": ["file_name",
#                                                                                               "component_name",
#                                                                                               "component_type",
#                                                                                               "calling_app_name",
#                                                                                               "called_name",
#                                                                                               "called_type",
#                                                                                               "called_app_name",
#                                                                                               "dd_name", "access_mode",
#                                                                                               "step_name", "comments"]})
# print(r.status_code)
# print(r.text)
