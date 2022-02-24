import re, os, glob, copy, xlsxwriter, requests, json, config
import datetime,sys,pytz
from collections import OrderedDict
from pymongo import MongoClient

# PROGRAM VARIABLES
Program_Name = ""
file_name = ""
Goto_Name = "False"
Current_Division_Name = ""
PGM_ID = []
Old_Division_Name = ""
add = ""
Call_Name = []
Module_Name = []
modulelinenumberdict = {}
Module_Line_Number = []
Copy_Name = []
Variables = []
Temp_Line = []
Perform_St = []
paravalue = []
Index = 0
Index_Val = 0
line_Var = ""
b = 0
Key_List = []
Value_list = []
Temp_Mod = []
Temp_Mod1 = []
Temp_List = []

Prev_Mod = ""
Current_Mod = ""

Prev_Len = 0
OutputDict = {}
Module_Dict = {}
MainList = []
MainDict = {}
CallName = []
CopyName = []
TempCopyName = []
TempCallName = []
jsonDict = {}
ParaList = []
ProgramflowList = []
finaldeadparalist2 = []
deaddict = {}

DeadDictFinal = {}
master_dead = set()
master_alive = set()
time_zone = 'Asia/Calcutta'
tz = pytz.timezone(time_zone)
client = MongoClient(config.database_COBOL['hostname'], config.database_COBOL['port'])
db = client[config.database_COBOL['database_name']]

def External_program(paradict):
    Call_List = []

    for name in Call_Name:
        Call_List.append(name.replace("CALL", "").replace(" ", ""))

    for k, v in paradict.items():
        for dict in v:
            if dict['to'] in Call_List:
                dict['to'] = dict['to'].replace("'", "")
                dict['name'] = "External_Program"


def main(file_name):
    Module_Dict = {}
    declare = False
    Old_Division_Name = ""

    Program_Name = open(file_name)

    for line1 in Program_Name.readlines():
        b = IsDivision(line1)
        # print("asdf",b)
        if b != 0:
            break
        else:
            continue
    Temp_File = open("Expanded_Data.txt", "w+")
    Program_Name = open(file_name)
    for line2 in Program_Name.readlines():

        line2 = Cut_Line(line2, b)
        # print(line2)
        if isComment(line2):
            continue
        else:
            copy = re.findall(r'^\s*COPY\s.\S*', line2)

            include = re.findall(r'^\s*[+][+]INCLUDE.*', line2)
            # print("include",include)
            if copy == [] and include == []:
                Copy_Expand(line2, Temp_File)
            elif copy != [] or include != []:
                Index_Val = 0
                Copy_Fun(copy, include)
                Temp_copy = line2.split()
                copy_Name = Temp_copy[1]

                copywithdot = re.match(".*[.]", copy_Name)

                if copywithdot == None:
                    copy_Name1 = copy_Name + "." + "cpy"
                    finalcopyname = os.path.exists(CopyPath)

                if copywithdot != None:
                    copy_Name1 = copy_Name + "cpy"
                    finalcopyname = os.path.exists(CopyPath)

                # print(copy_Name1)

                try:
                    Temp_File2 = open(os.path.join(CopyPath, copy_Name1), "r")

                    for line3 in Temp_File2.readlines():
                        # print(line3)
                        if line3.strip() == "":
                            continue
                        Temp_File1 = line3.split()
                        # print(Temp_File1)
                        if len(Temp_File1) == 1:
                            continue
                        Temp_index = Temp_File1[1]
                        # module = re.findall(r'^\s{1}[A0-Z9].*[-]*.*[.]', line)
                        module = re.findall(r'^\s*[A0-Z9]*[-].*[.]', Temp_File1[1])
                        if Temp_File1[1] == "01":
                            Temp_File1_Len = len(Temp_File1[0])
                            Temp_String = line3[Temp_File1_Len:]
                            Temp_String1 = Temp_String.split()
                            Index = Temp_String.index(Temp_String1[0])
                            Index = Index + Temp_File1_Len - 1
                            Index_Val = Index
                            Temp_Line1 = line3[Index_Val:80]
                            break
                        elif Temp_index[0] == "*":
                            Index = line3.index(Temp_File1[1])
                            Index_Val = Index
                            Temp_Line1 = line3[Index_Val:80]
                            break
                        elif module != []:
                            if (Temp_File1[1] == "END-EVALUATE."):
                                continue
                            else:
                                Index = line3.index(Temp_File1[1])
                                Index_Val = Index - 1
                                Temp_Line1 = line3[Index_Val:80]
                                break

                    if Index_Val != 0:
                        Temp_File1 = open(os.path.join(CopyPath, copy_Name1), "r")
                        Temp_File = open("Expanded_Data.txt", "a+")
                        for line4 in Temp_File1.readlines():
                            Temp_Line1 = line4[Index_Val:80]
                            Temp_File.write(Temp_Line1)
                            Temp_File.write("\n")
                except IOError:
                    continue
    Temp_File.close()
    Program_Name.close()
    Program_Name = open("Expanded_Data.txt")
    r = 0
    flaggy = False
    for number, line in enumerate(Program_Name):
        # print("Program Name:",Program_Name)
        # print("asf",line)
        if isComment(line):
            continue
        else:

            Current_Division_Name = Current_Division(line)
            if Current_Division_Name == None:
                if Old_Division_Name == "IDENTIFICATION DIVISION" or Old_Division_Name == "ID DIVISION":
                    Id_Division(line, file_name)

                elif Old_Division_Name == "ENVIRONMENT DIVISION":
                    Envi_Division(line)

                elif Old_Division_Name == "DATA DIVISION":
                    Data_Division(line)

                elif Old_Division_Name == "PROCEDURE":

                    r = r + 1
                    Declarative = re.findall(r'^\sDECLARATIVES[.]\s*', line)
                    EndDeclarative = re.findall(r'^\sEND\s*DECLARATIVES[.]\s*', line)
                    if Declarative != []:
                        declare = True
                    if EndDeclarative != []:
                        declare = False
                    if declare:
                        continue
                    else:
                        if EndDeclarative == []:
                            flaggy = Proc_Division(line, r, number, flaggy)


            else:
                Old_Division_Name = Current_Division_Name

    if line != "":
        Module_Dict = Output(line)

    return Module_Dict


def Copy_Expand(line, Temp_File):
    Temp_File.write(line)
    Temp_File.write("\n")


def IsDivision(line1):
    Temp_Line = line1
    if Temp_Line[7:21] == "IDENTIFICATION" or Temp_Line[7:9] == "ID":
        Index = line1.index(Temp_Line[7:21])
        Index = Index - 1
        return Index
    else:
        return False


def Cut_Line(line, b):
    line = line[b:72]

    return line


def isComment(line):
    if line[0:1] == '*':
        return True
    else:
        return False


def Current_Division(line):
    if line[1:24] == "IDENTIFICATION DIVISION" or line[1:3] == "ID":
        Current_Division_Name = "IDENTIFICATION DIVISION"
        return Current_Division_Name
    elif line[1:21] == "ENVIRONMENT DIVISION":
        Current_Division_Name = "ENVIRONMENT DIVISION"
        return Current_Division_Name
    elif line[1:14] == "DATA DIVISION":
        Current_Division_Name = "DATA DIVISION"
        return Current_Division_Name

    elif line[1:10] == "PROCEDURE":
        Current_Division_Name = "PROCEDURE"
        return Current_Division_Name
    else:
        Current_Division_Name = None
        return Current_Division_Name


def Id_Division(line, file_name):
    # print(filename)
    if line[1:11] == "PROGRAM-ID":
        Temp_ID = line[12:65]
        # TempID=Temp_ID.strip()
        # if TempID=="":
        file_name = file_name.split('\\')
        file_name = file_name[len(file_name) - 1]
        file_name = file_name.split('.')
        file_name = file_name[0]
        # print(file_name)
        PGM_ID.append(file_name)
        # if TempID!="":
        #     TempID = TempID.split('.')
        #     PGM_ID.append(TempID[0])


def Envi_Division(line):
    return None


def Data_Division(line):
    Temp_Variable = re.findall(r'.*PIC.*', line)
    if Temp_Variable != []:
        Temp_Variable1 = re.findall(r'.*FILLER.*', line)
        if isFiller(Temp_Variable1):
            return
        else:
            Temp_Value = Temp_Variable[0]
            Temp_Value = Temp_Value[1:65].strip()
            Variables.append(Temp_Value)
    copy = re.findall(r'^\s*COPY.\S*', line)
    include = re.findall(r'^\s*[+][+]INCLUDE.*', line)
    Copy_Fun(copy, include)


def Proc_Division(line, r, number, Goto_Name):
    module = re.findall(r'^\s{1}[A0-Z9].*[-]*.*[.]', line)
    if (module != []):
        # print("Module_Name:",module)
        Temp_Proc = module[0]
        # print("TEmp_Proc:",Temp_Proc)
        Temp_Val = Temp_Proc[1:71].strip()
        # print("Temp_Val:",Temp_Val)
        if Temp_Val[0:1] == "D ":
            return
        else:
            splitwithspace = Temp_Val.split()
            Temp_Val = Temp_Val.split('.')
            Temp_Val = Temp_Val[0]
            if len(splitwithspace) != 1 and splitwithspace[1] == "SECTION.":
                Temp_Val = splitwithspace[0]
            Temp_Val = re.sub('["\s"]', '-', Temp_Val)

            Module_Name.append(Temp_Val)
            Module_Line_Number.append(number)
            # print(Temp_Val)
            Perform_St.append(Temp_Val)
    elif (module == []):
        call = re.findall(r'^\s*CALL\s*.\S*', line, re.IGNORECASE)
        copy = re.findall(r'^\s*COPY.\S*', line)
        Perform = re.findall(r'^\s*PERFORM\s.*', line)

        Goto = re.findall(r'\s*GO\s*TO\s.*', line)
        Inprocedure = re.findall(r'^\s*INPUT\s*PROCEDURE\s.*', line)
        Outprocedure = re.findall(r'^\s*OUTPUT\s*PROCEDURE\s.*', line)
        include = re.findall(r'^\s*[+][+]INCLUDE.*', line)

        if (call != []):

            Temp_Call = call[0]
            Temp_Val = Temp_Call[1:71].strip()
            Call_Name.append(Temp_Val)

            Perform_St.append(Temp_Val.replace('CALL', 'PERFORM'))

        elif (copy != [] or include != []):
            Copy_Fun(copy, include)
        elif (Perform != []):

            Temp_Perform = Perform[0]
            Temp_Per = Temp_Perform[1:71].strip()
            Temp_Per1 = Temp_Per.split()
            if len(Temp_Per1) == 1:
                return
            elif Temp_Per1[1] == "VARYING" or Temp_Per1[1] == "UNTIL":
                return
            else:
                Temp_Per = Temp_Per.split('.')
                Temp_Per = Temp_Per[0]
                Perform_St.append(Temp_Per)

        elif (Goto != [] or Goto_Name == "True"):
            if Goto_Name == "True":
                Goto_Value = line.strip()
                Perform_St.append(Goto_Value)
                Goto_Name = "False"
                return Goto_Name
            Temp_Goto = Goto[0]
            Temp_Goto = Temp_Goto[1:71].strip()
            Temp_Goto1 = Temp_Goto.split()
            if len(Temp_Goto1) == 1:
                return
            else:
                Temp_Goto = Temp_Goto.split('.')
                Temp_Goto = Temp_Goto[0]
                Temp_Goto_space = Temp_Goto.split()
                if len(Temp_Goto1) == 2 and (Temp_Goto_space[0] == "GO" and Temp_Goto_space[1] == "TO"):
                    Goto_Name = "True"
                    return Goto_Name
                if len(Temp_Goto1) > 2:
                    if (Temp_Goto_space[0] == "GO" and Temp_Goto_space[1] == "TO"):
                        Temp_Goto_name = Temp_Goto_space[2]
                        # if Temp_Goto_name !="EOJ":
                        Temp_Goto_subtituted = "PERFORM" + " " + Temp_Goto_name
                        Perform_St.append(Temp_Goto_subtituted)

        elif (Inprocedure != []):
            Temp_inProcedure = Inprocedure[0]
            Temp_inProcedure = Temp_inProcedure.split()
            if len(Temp_inProcedure) == 1:
                return
            else:
                if (Temp_inProcedure[0] == "INPUT" and Temp_inProcedure[1] == "PROCEDURE"):
                    Temp_inProcedure_name = Temp_inProcedure[2]
                    Temp_inProcedure_name = "PERFORM" + " " + Temp_inProcedure_name
                    Perform_St.append(Temp_inProcedure_name)
        elif (Outprocedure != []):
            Temp_outProcedure = Outprocedure[0]
            Temp_outProcedure = Temp_outProcedure.split()
            if len(Temp_outProcedure) == 1:
                return
            else:
                if (Temp_outProcedure[0] == "OUTPUT" and Temp_outProcedure[1] == "PROCEDURE"):
                    Temp_outProcedure_name = Temp_outProcedure[2]
                    Temp_outProcedure_name = "PERFORM" + " " + Temp_outProcedure_name
                    Perform_St.append(Temp_outProcedure_name)


def isFiller(Temp_Variable1):
    if (Temp_Variable1 != []):
        return True
    else:
        return False


def Copy_Fun(copy, include):
    if (copy != []):
        Temp_Copy = copy[0]
        Temp_Val = Temp_Copy[1:65].strip()
        Copy_Name.append(Temp_Val)
    elif (include != []):
        Temp_include = include[0]
        Temp_Val = Temp_include[1:65].strip()
        Copy_Name.append(Temp_Val)


def isContinue(line):
    if (line[6] == '-'):
        return True
    else:
        return False


def Last_Pt(c):
    if c == len(Module_Name):
        Temp_List[c - 1] = Value_list.copy()
        Value_list.clear()


def Output(line):
    #  print()
    for numbers in range(len(Module_Name)):
        modulelinenumberdict[Module_Name[numbers]] = Module_Line_Number[numbers]
    empty_list = []
    ProgNameLen = len(PGM_ID) - 1
    # print(ProgNameLen)
    # print('Program_ID:',PGM_ID[ProgNameLen])
    #  print()
    for element in Module_Name:
        None
    for element in Copy_Name:
        element = element.split()
    TempCopyName = copy.deepcopy(CopyName)
    for element in Call_Name:
        element = element.split()
    TempCallName = copy.deepcopy(CallName)
    c = 0
    Current_Mod = ""
    #print(Perform_St)
    if Perform_St != []:
        Temp_perform = Perform_St[0]
        Temp_perform = Temp_perform.split()
        if Temp_perform[0] == "PERFORM":
            Perform_St.insert(0, "00-MAIN")
            Module_Name.insert(0, "00-MAIN")
        for element in range(len(Module_Name)):
            empty_list = []
            Temp_List.append(empty_list)

        for element in Module_Name:
            d = 0
            for element1 in Perform_St:
                Temp_Mod = element1.split()
                if Module_Name[c] == Perform_St[d] or Module_Name[c] == Current_Mod:
                    if Module_Name[c] == Perform_St[d]:
                        Current_Mod = Perform_St[d]
                    elif Temp_Mod[0] == "PERFORM":

                        Value_list.append(Temp_Mod[1])
                    elif len(Temp_Mod) == 1:
                        Temp_List[c] = Value_list.copy()
                        Value_list.clear()
                        break
                d = d + 1
            c = c + 1
            Last_Pt(c)
    # print( Temp_List)
    outputlist = []
    outputlist1 = []

    ######################################################################################
    # Deleting the duplicates in the list.

    for listvalue in Temp_List:
        outputlist = []
        if listvalue == []:
            outputlist1.append(listvalue)
            continue
        for x in listvalue:
            if x not in outputlist and x != []:
                outputlist.append(x)
            copylist = copy.deepcopy(outputlist)
        outputlist1.append(copylist)
    # print(outputlist1)

    #########################################################################################
    # print("IIIIIIIIIIIIII:",Module_Name)
    # print("JJJJJJJJJJJJJJ:",outputlist1)
    i = iter(Module_Name)
    j = iter(outputlist1)
    k = list(zip(i, j))
    # print("KKKKKKKKKKKKK:",k)

    for (x, y) in k:
        Module_Dict1[x] = y
    # print("MMMMMMMMMMMMMMM:",json.dumps(New_Dict, indent=4))

    # print("MMMMMMMMMMMMMMM:", json.dumps(Module_Dict1, indent=4))
    list1 = []
    list2 = []

    for i, j in Module_Dict1.items():
        list1.append(i)
        list2.append(j)
    for k in range(0, len(list1)):
        try:

            if (Module_Dict1[list1[k]]) == []:
                for l in range(k + 1, len(list1)):
                    if len(list1[l]) <= 4 and Module_Dict1[list1[l]] != []:
                        list2[k].extend(list2[l])
                        list1.remove(l)
                    if Module_Dict1[list1[l]] == []:
                        break
                    elif len(list1[l]) > 4:
                        continue
        except Exception as e:
            print(e)
    # print("List1:",list1)
    # print("List2:",list2)

    Module_Dict2 = dict(zip(list1, list2))

    Module_Dict = {k: v for k, v in Module_Dict2.items() if ((len(k) > 4) or (len(k) == 4 and k.isalpha()))}
    # print("expected:", json.dumps(Module_Dict, indent=4))

    # print("expected:",json.dumps(Module_Dict2,indent=4))

    # print("modu:",json.dumps(Module_Dict, indent=4))

    ParaList.append(Module_Dict)
    # print(Module_Dict)
    data(TempCallName, TempCopyName, Module_Dict)
    NoOfPrg = len(PGM_ID)
    NoOfPrg = NoOfPrg - 1
    MainList.append(empty_list)
    MainList[NoOfPrg] = copy.deepcopy(OutputDict)
    OutputDict.clear()

    return Module_Dict


def data(TempCallName, TempCopyName, Module_Dict):
    ItemsToDisplayList = ["ModuleName", "CallStatements", "CopyBooks", "PerformStatements"]
    # print(json.dumps(Module_Dict, indent=4))

    ItemsFromProgram = [Module_Name, TempCallName, TempCopyName, Module_Dict]
    i = iter(ItemsToDisplayList)
    j = iter(ItemsFromProgram)
    k = list(zip(i, j))
    for (x, y) in k:
        OutputDict[x] = y


def Program_Flow(Module_Name, Module_Dict):
    firstdict = {}
    seconddict = {}
    thirddict = {}

    for element in Module_Name:
        for element1 in Module_Dict:

            Module = Module_Dict.get(element1)

            for element2 in Module:
                thirddict[element2] = Module_Dict[element2]

        firstdict[element] = thirddict


def ExcelWriting():
    ProgNameLen = len(PGM_ID) - 1
    workbook = xlsxwriter.Workbook('Demo.xlsx')
    worksheet = workbook.add_worksheet(PGM_ID[ProgNameLen])

    row = 0
    col = 0
    for Key in (Module_Dict):
        row += 1
        worksheet.write(row, col, Key)
        for item in Module_Dict[Key]:
            worksheet.write(row, col, "Perform Statements")
            worksheet.write(row, col + 1, item)
            worksheet.write(row, col, Key)
            row += 1


def flowData(Module_Dict):
    Keys = ['from', 'to', 'name']
    Values = []
    Newlist = []
    Dict = {}
    newdict = {}
    templist = []
    templist1 = []
    # print("Module_Dicttttt:",Module_Dict)
    # print("calllist,",Call_Name)
    for Key in (Module_Dict):
        for item in Module_Dict[Key]:
            Values.append(Key)
            Values.append(item)
            Values.append(Key)

            templist = Values.copy()
            # print(templist)
            for i in range(len(Keys)):
                Dict[Keys[i]] = templist[i]
            newdict = copy.deepcopy(Dict)
            Newlist.append(newdict)
            Dict.clear()
            Values.clear()
    templist1 = Newlist.copy()
    ProgramflowList.append(templist1)
    Newlist.clear()


def Dead_Code(filename):
    DeadDict = {}
    moduledead = []
    finaldeadparalist = []
    TotalNoOfDeadLine = 0
    PerformParaList = []
    FullParaList = []
    DeadParaList = []
    lines = []
    ModuleName = []
    for para in Perform_St:
        para = para.split()
        if para[0] == "PERFORM":
            Temp_para = para[1]
            PerformParaList.append(Temp_para)
    r = 0
    for elements in Module_Dict:
        Module = Module_Dict.get(elements)
        if Module == [] and r == 0:
            continue
        else:
            r = r + 1
            FullParaList.append(elements)
    if FullParaList != []:
        del FullParaList[0]
    for element1 in FullParaList:
        if element1 in PerformParaList:
            continue
        else:
            DeadParaList.append(element1)
    Program_Name = open(filename)
    for line1 in Program_Name.readlines():
        b = IsDivision(line1)
        if b != 0:
            break
        else:
            continue
    lenOfFullparalist = len(FullParaList)
    Program_Name = open(filename)
    r = 0
    CurtModule = ""
    paravalue = []
    for line in Program_Name.readlines():
        line = Cut_Line(line, b)
        module = re.findall(r'^\s{1}[A0-Z9].*[-]*.*[.]', line)
        if module != []:
            module = module[0].split('.')
            module = module[0].strip()
            CurtModule = module
        if CurtModule != [] and CurtModule != module:
            r = r + 1
        else:
            lines.append(r)
            ModuleName.append(module)
            r = 0
    lines.append(r)
    del lines[0]
    temp_line = lines.copy()
    temp_Module = ModuleName.copy()
    for i in range(len(temp_line)):
        DeadDict[temp_Module[i]] = temp_line[i]
    for data2 in Module_Dict:
        paravalue = Module_Dict.get(data2)
        if paravalue != []:
            master_alive.add(data2)
            break
    for elemente in paravalue:
        # print("ele",elemente)
        findAliveChildren(elemente)
    for elements1 in paravalue:
        master_alive.add(elements1)

    # print("asli",master_alive)

    for i in DeadParaList:
        para = DeadDict.get(i.strip())
        if (para == None):
            para = 0
        TotalNoOfDeadLine = TotalNoOfDeadLine + para
    notalivepara = []
    for item in Module_Name:
        if item in master_alive:

            continue
        else:
            notalivepara.append(item)
    master_alive.clear()
    for alivepara1 in notalivepara:

        try:
            del Module_Dict[alivepara1]
        except KeyError:
            continue

    dictfilt = lambda x, y: dict([(i, x[i]) for i in x if i in set(y)])
    wanted_keys = DeadParaList
    result = dictfilt(DeadDict, wanted_keys)

    temp_result = copy.deepcopy(result)
    finaldeadparalist.append(len(temp_result))
    finaldeadparalist.append(DeadParaList)
    finaldeadparalist.append(TotalNoOfDeadLine)
    finaldeadparalist.append(len(Module_Name))
    finaldeadparalist1 = copy.deepcopy(finaldeadparalist)

    HeaderParalist = ["dead_para_count", "dead_para_list", "total_dead_lines", "total_para_count"]
    deaddict1 = copy.deepcopy(deaddict)
    for m in range(len(HeaderParalist)):
        deaddict1[HeaderParalist[m]] = finaldeadparalist1[m]

    finaldeadparalist2.append(deaddict1)

    for k in range(len(PGM_ID)):
        DeadDictFinal[PGM_ID[k]] = finaldeadparalist2[k]
    # print(PGM_ID)


def findAliveChildren(ele):
    try:
        if Module_Dict[ele] == []:

            master_alive.add(ele)
            return
        else:
            for item in Module_Dict[ele]:

                if item in master_alive:

                    continue
                else:

                    master_alive.add(item)
                    findAliveChildren(item)
    except KeyError:
        return


cobol_folder_name = config.COBOL_codebase_information['COBOL']['folder_name']
cobol_extension_type = config.COBOL_codebase_information['COBOL']['extension']
COPYBOOK = config.COBOL_codebase_information['COPYBOOK']['folder_name']

code_location = config.COBOL_codebase_information['code_location']

CobolPath = code_location + '\\' + cobol_folder_name
CopyPath = code_location + '\\' + COPYBOOK

workbook = xlsxwriter.Workbook('Demo.xlsx')
for filename in glob.glob(os.path.join(CobolPath, '*.cbl')):
    # print("File passed:",filename)
    Module_Dict1 = {}
    New_Dict = {}
    Copy_Name.clear()
    Module_Name.clear()
    Perform_St.clear()
    CallName.clear()
    CopyName.clear()
    Module_Dict = main(filename)
    Dead_Code(filename)
    flowData(Module_Dict)
    # print("M:",Module_Dict)
    second_list = []
    main_list = []

    # ExcelWriting()

workbook.close()

paradict = {}
for i in range(len(PGM_ID)):
    MainDict[PGM_ID[i]] = MainList[i]

for i in range(len(PGM_ID)):
    jsonDict[PGM_ID[i]] = ParaList[i]

for i in range(len(PGM_ID)):
    paradict[PGM_ID[i]] = ProgramflowList[i]
JsonDict1 = {}
flowDict = {}

flowDict["data"] = paradict
External_program(paradict)
Call_Name.clear()

#print(json.dumps(paradict, indent=4))
final_dict={"data":paradict}
def updateProcedureFlow(final_dict):
    # get data from POST request body
    data = final_dict

    # JSON document for db upload
    db_data = []

    # Payload
    payload = {}

    # List of all cobol programs that have been processed
    program_list = []
    # check if the text is json

    # JsonVerified, verification_payload = jsonVerify(data)
    # if JsonVerified:
    #     payload = verification_payload
    # else:
    #     return verification_payload

    # Must have a key "data"
    payload = data
    try:
        keys = list(payload.keys())
        #print('parent keys', keys)

        if 'data' in keys:
            # Getting a list of all programs
            program_list = list(payload['data'].keys())
            for program in program_list:
                # creating skeleton for program
                temp = {"component_name": " ",
                        "nodes": [],
                        "links": []
                        }

                temp['component_name'] = program + ".cbl"
                node_set = set()
                link_set = set()
                #print('fruit ', payload['data'][program])

                for pgm_name in payload['data'][program]:
                    # print(pgm_name)
                    from_node = pgm_name['from']
                    to_node = pgm_name['to']
                    if pgm_name['name'] == "External_Program":

                        node_set.add('p_' + from_node)
                        node_set.add('p_' + to_node)
                        # temp['links'].append({"source":'p_'+from_node,"target":'p_'+to_node})
                        link_set.add(json.dumps(
                            {"source": 'p_' + from_node, "target": 'p_' + to_node, "label": 'External_Program'}))

                    else:
                        node_set.add('p_' + from_node)
                        node_set.add('p_' + to_node)
                        # temp['links'].append({"source":'p_'+from_node,"target":'p_'+to_node})
                        link_set.add(json.dumps({"source": 'p_' + from_node, "target": 'p_' + to_node}))

                    #print(json.dumps({"source": 'p_' + from_node, "target": 'p_' + to_node}))

                #print(link_set)
                for item in link_set:
                    temp['links'].append(json.loads(item))

                # ite variable to increment position variable
                ite = 1
                for item in node_set:
                    # temp['nodes'].append({"id":item,"label":item[2:],"position":"x"+str(ite)})
                    temp['nodes'].append({"id": item, "label": item[2:]})
                    ite = ite + 1

                db_data.append(temp)
            #print(db_data)

            previousDeleted = False

            try:
                # print('Remove operation', db.procedure_flow_table.remove({}))
                if db.procedure_flow_table.delete_many({}):  # Mongodb syntax to delete all records
                    #print('Deleted all the data from previous runs')
                    previousDeleted = True
                else:
                    pass
                    #print('Something went wrong')
                    # return jsonify(
                    #     {"status": "failed",
                    #      "reason": "unable to delete from database. Please check in with your Administrator"})

            except Exception as e:
                print(e)
                # return jsonify({"status": "failed", "reason": str(e)})

            if previousDeleted:
                #print('Entering the insert block')
                try:

                    db.procedure_flow_table_EC.insert_many(db_data)
                    print('it has happened')
                    # updating the timestamp based on which report is called
                    current_time = datetime.datetime.now(tz=tz).strftime("%A, %d. %B %Y %I:%M%p")
                    # Setting the time so that we know when each of the JCL and COBOLs were run

                    # db.cross_reference_report.insert_one({"type":"metadata", "JCL":{"last_updated_on":ct},"COBOL":{"last_updated_on":ct}})

                    if db.procedure_flow_table_EC.count_documents({"type": "metadata"}) > 0:
                        print(db.crud_report.update_one({"type": "metadata"},
                                                                             {"$set": {
                                                                                 "last_updated_on": current_time,
                                                                                 "time_zone": time_zone,
                                                                             }},
                                                                             upsert=True).acknowledged)
                    else:
                        db.procedure_flow_table_EC.insert_one(
                            {"type": "metadata", "last_updated_on": current_time, "time_zone": time_zone})

                    #print(current_time)
                    # return jsonify({"status": "success", "reason": "Successfully inserted data yay. "})
                except Exception as e:
                    print('Error' + str(e))
                    # return jsonify({"status": "failed", "reason": str(e)})
            # return jsonify(db_data)

    except Exception as e:
        print('Error: ' + str(e))
        #print('Error on line {}'.format(sys.exc_info()[-1].tb_lineno))
        # return jsonify({"status": "failure", "reason": "Response json not in the required format"})



updateProcedureFlow(final_dict)
# r = requests.post('http://localhost:5000/api/v1/update/procedureFlow_EC', json={"data": paradict})
# print(r.status_code)
# print(r.text)
