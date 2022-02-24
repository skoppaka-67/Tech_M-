import xlrd, os, copy, re, glob, xlsxwriter, openpyxl
from pymongo import MongoClient
import time, datetime, pytz, json
import timeit, sys

import config1

import xlrd

ConditionPath = 'D:\\AS400\\Copy of AS400_RPG_Rules_Cookbook.xlsx'
wb = xlrd.open_workbook(ConditionPath)
sheet = wb.sheet_by_index(1)
row = sheet.nrows
cols = sheet.ncols
key_word_list = []

for index in range(row):
    value = sheet.cell_value(index, 0)
    key_word_list.append(value)

PGM_ID = []
Current_Division_Name = ""
time_zone = 'Asia/Calcutta'
tz = pytz.timezone(time_zone)

client = MongoClient(config1.database['mongo_endpoint_url'])
db = client[config1.database['database_name']]

cobol_folder_name = config1.codebase_information['COBOL']['folder_name']
cobol_extension_type = config1.codebase_information['COBOL']['extension']
COPYBOOK = config1.codebase_information['COPYBOOK']['folder_name']

code_location = config1.codebase_information['code_location']
# ConditionPath=config1.codebase_information['condition_path']
CobolPath = code_location + '\\' + cobol_folder_name


def main():
    i = 0
    j = 0
    METADATA = []
    modulelist = []
    performlist = []
    CopyPath = code_location + '\\' + COPYBOOK
    counter = 0
    current_para = ""
    paralist = []
    oneline_buffer = []
    command_section = False
    #DB delete

    # if db.bre_rules_report.delete_many(
    #         {"type": {"$ne": "metadata"}}).acknowledged:
    #    print("DB delete")

    for filename in glob.glob(os.path.join(CobolPath, '*.rpg')):
        print(filename)
        if counter == 5:
            counter = 0
            # print("Metabta",METADATA)
            # ( METADATA)
            METADATA = []
        counter = counter + 1
        procFlag_copy = False
        Performparalist = []
        Id_Division(filename)
        i = i + 1
        Program_Name = open(filename)
        flag = False
        for line in Program_Name.readlines():
            if line.strip() == '' or line[5:].strip() == '' or line[6] == '*' or line.__contains__(
                    '//') or line.__contains__('/TITLE'):

                continue

            else:
                with open("Copy_Expanded_Data" + str(i) + '.txt', "a+") as copy_file:
                    if line[5] == 'd' or line[5] == 'h' or line[5] == 'f' or line[6] == '*' or line[5] == 'D':
                        continue
                    else:
                        copy_regexx = re.findall(r'\s*COPY\s.*', line, re.IGNORECASE)
                        if copy_regexx != []:
                            if copy_regexx != []:
                                copyname = copy_regexx[0]
                                copyname = copyname.split()
                                copyname = copyname[1]
                                if copyname.__contains__(","):
                                    copyname = copyname.split(',')
                                    copyname = copyname[1]
                                copyname = copyname + '.cpy'
                                Copyfilepath = CopyPath + '\\' + copyname
                                if os.path.isfile(Copyfilepath):
                                    Temp_File2 = open(os.path.join(CopyPath, copyname), "r")
                                    copy_file.write("#########" + " " + "BEGIN" + " " + line.strip() + '\n')
                                    for copylines in Temp_File2.readlines():
                                        copylines = re.sub('\t', '     ', copylines)
                                        copy_file.write(copylines)
                                        copy_file.write('\n')
                                    copy_file.write("#####" + " " + "COPY END" + "####" + '\n')
                                else:
                                    copy_file.write(line)
                        else:
                            copy_file.write(line)
                            copy_file.write('\n')
                copy_file.close()
        counter = 0

        with open("Copy_Expanded_Data" + str(i) + '.txt', "r") as temp_file:
            with  open("Duplicatefile" + str(i) + '.txt', "a+") as temp_file1:
                temp_file1.write("                    ***Program-Start**            begsr " + "\n")

                for lines in temp_file.readlines():
                    module = re.findall(r'^\s*.*\s*begsr\s.*', lines, re.IGNORECASE)
                    if module != []:
                        counter = counter + 1
                    temp_file1.write('\n')
                    if module != [] and counter == 1:
                        temp_file1.write("                          endsr    " + "\n")
                    temp_file1.write(lines)

        #  Making in one line.

        wb = xlrd.open_workbook(ConditionPath)
        sheet = wb.sheet_by_index(1)
        row = sheet.nrows
        cols = sheet.ncols
        Key_Word_List = []
        for index in range(row):
            value = sheet.cell_value(index, 2)
            Key_Word_List.append(value)

        Key_Word_List = ['/free', 'end-free', ' add', ' adddur', ' cat', ' check', ' checkr', ' div', ' in ', ' lookup',
                         ' mult', ' scan', ' setoff', ' seton', ' sorta', ' sub', ' subdur', ' subst', ' time',
                         ' xfoot', ' xlate', ' z-add', ' z-sub', ' close', ' open', ' comp', ' if', ' ifeq', ' ifgt',
                         ' ifge', ' iflt', ' ifle', ' ifne', ' select', ' test', '  when', ' else', ' chain', ' delete',
                         ' except', ' excpt', ' exfmt', ' read', ' readc', ' reade', ' readp', ' readpe', ' setgt',
                         ' setll', ' update', ' write', ' begsr', ' cab', ' cabge', ' cabgt', ' cable', ' cablt',
                         ' cabne', ' call ', ' callb', ' callp', ' cas', ' caseq', ' casgt', ' casge', ' caslt',
                         ' casle', ' casne', ' clear', ' define', ' do', ' dou', ' dow', ' dump', ' endsr', ' end',
                         ' endcs', 'endsr;', ' enddo', ' endfor', ' endif', ' endmon', ' endsl', ' eval', ' evalr',
                         ' exsr', ' extrct', ' for', ' goto', ' iter', ' klist', ' leave', ' leavesr', ' monitor',
                         ' move(p)', ' move', ' movel(p)', ' movel', ' mvr', ' other', ' occur', ' onerror', ' out',
                         ' plist', ' return', ' tag', ' unlock', ' dsply', 'copy ']

        with open("Duplicatefile" + str(i) + '.txt', "r+") as expanded_file:
            for line in expanded_file.readlines():
                keywordflag = False
                temp_line = line[6:]

                if temp_line.strip() == '' or line[
                    0] == '*' or line.strip() == "skip" or line[6:].strip() == "skip" or line.strip() == 'eject':

                    continue
                else:
                    with open("Duplicatefile0" + str(i) + '.txt', "a+") as temp_file1:
                        line1 = line[6:].split()
                        command_line = line[6:]
                        if line[5].lower() == 'p':
                            temp_file1.write(command_line)
                            continue
                        for data in range(len(Key_Word_List)):
                            if command_line.lower().__contains__(Key_Word_List[data]):
                                keywordflag = True
                        if keywordflag:
                            if oneline_buffer == []:
                                oneline_buffer.append(re.sub('\n', '', command_line))
                            else:
                                line6 = ""
                                for data in range(len(oneline_buffer)):
                                    line6 = line6 + oneline_buffer[data]
                                temp_file1.write('\n')
                                line6 = line6 + "                     ^" + current_para + "\n"
                                temp_file1.write(line6)
                                oneline_buffer.clear()
                                # command_line=command_line+"         ^"+current_para
                                oneline_buffer.append(re.sub('\n', '', command_line))
                        else:
                            command_line = "     <br>" + command_line
                            oneline_buffer.append(re.sub('\n', '', command_line))
                            # temp_file1.write(line)

                        module = re.findall(r'^\s*.*\s*begsr\s.*', command_line, re.IGNORECASE)
                        if module != []:
                            if line1[0] == "begsr" or line1[0] == "BEGSR":
                                current_para = line1[1]
                                paralist.append(re.sub(';', '', current_para))
                            else:
                                current_para = line1[0]
                                paralist.append(re.sub(';', '', current_para))

            # Print last line.
            with open("Duplicatefile0" + str(i) + '.txt', "a+") as temp_file1:
                line6 = ""
                for data in range(len(oneline_buffer)):
                    line6 = line6 + oneline_buffer[data]
                line6 = line6 + "                     ^" + current_para + "\n"
                temp_file1.write(line6)
                print(line6)

        # Expanding the perform statements.

        # For the first para the para reference is not taken while using the direct file
        # ,so two files are created and used for expansion.

        with open("Duplicatefile0" + str(i) + '.txt', "r") as temp_file:
            for line in temp_file.readlines():
                # line=line[6:]
                if line[1:].strip() == '' or line[0] == '*':
                    continue
                else:
                    perform = re.findall(r'^\s*exsr\s*.*', line, re.IGNORECASE)
                    case_statements = re.findall(r'^\s*.*case.*', line, re.IGNORECASE)

                    if perform != []:
                        Temp_perform = perform[0]
                        Temp_perform = Temp_perform.split()
                        Temp_perform = Temp_perform[1]
                        if Temp_perform.__contains__(';'):
                            Temp_perform = Temp_perform[:-1]
                        Performparalist.append(Temp_perform)
                    elif (case_statements != []):
                        temp_case_statements = case_statements[0].split()
                        temp_case_statements = temp_case_statements[3]
                        if temp_case_statements.__contains__(';'):
                            temp_case_statements = temp_case_statements[:-1]
                        Performparalist.append(temp_case_statements)
                    module = re.findall(r'^\s*.*\s*begsr\s.*', line, re.IGNORECASE)
                    if module != []:
                        modulelist.append(module)
                    lenofmodulelist = len(modulelist)
                    if module != []:
                        currentmodule = modulelist[lenofmodulelist - 1]
                        currentmodulevalue = currentmodule[0]
                        currentmodulevalue = re.sub('begsr', '', currentmodulevalue)
                    if perform != [] or case_statements != []:
                        if perform != []:

                            performlist.append(perform)
                            performline = perform
                            perform = perform[0].split()
                            perform = perform[1]

                        elif case_statements != []:
                            performlist.append(case_statements)
                            performline = case_statements
                            perform = case_statements[0].split()
                            perform = perform[3]

                        with  open("FinalFile0" + str(i) + '.txt', "a") as temp_file1:
                            if perform == "":
                                temp_file1.write('\n')
                            else:
                                # performWrite = '@' + performline[0] + '  ^' + currentmodulevalue
                                performWrite = '@' + performline[0]
                                temp_file1.write('\n')
                                temp_file1.write(performWrite)

                        with  open("Duplicatefile0" + str(i) + '.txt', "r+") as temp_file:
                            for line in temp_file.readlines():
                                # line=line[5:]
                                module = re.findall(r'^\s*.*\s*begsr\s.*', line, re.IGNORECASE)
                                if module != []:
                                    module = module[0]
                                    module = module.split()
                                    if module[0] == "begsr" or module[0] == "BEGSR":
                                        module = module[1]
                                    else:
                                        module = module[0]
                                if module.__contains__(';'):
                                    module = module[:-1]
                                if perform == []:
                                    perform = ""
                                if module == []:
                                    module = ""
                                if perform.lower() == module.lower() and (perform != [] or perform != ""):
                                    flag = True
                                if flag:
                                    module = re.findall(r'^\s*.*\s*begsr\s.*', line, re.IGNORECASE)
                                    endsr = re.findall(r'^\s*.*\sendsr\s*.*', line, re.IGNORECASE)

                                    if flag:
                                        with  open("FinalFile0" + str(i) + '.txt', "a") as temp_file1:
                                            # print(line)
                                            temp_file1.write('\n')
                                            temp_file1.write(line)
                                    if endsr != []:
                                        flag = False
                    else:
                        with  open("FinalFile0" + str(i) + '.txt', "a") as temp_file1:
                            temp_file1.write('\n')
                            temp_file1.write(line)

        modulelist = []
        performlist = []

        with open("FinalFile0" + str(i) + '.txt', "r") as temp_file:
            for line in temp_file.readlines():
                # line=line[6:]
                if line.strip() == '' or line[0] == '*':
                    continue
                else:
                    perform = re.findall(r'^\s*exsr\s*.*', line, re.IGNORECASE)
                    case_statements = re.findall(r'^\s[^@]*.*case.*', line, re.IGNORECASE)

                    if perform != []:
                        Temp_perform = perform[0]
                        Temp_perform = Temp_perform.split()
                        Temp_perform = Temp_perform[1]
                        if Temp_perform.__contains__(';'):
                            Temp_perform = Temp_perform[:-1]
                        Performparalist.append(Temp_perform)
                    elif (case_statements != []):
                        temp_case_statements = case_statements[0].split()
                        temp_case_statements = temp_case_statements[3]
                        if temp_case_statements.__contains__(';'):
                            temp_case_statements = temp_case_statements[:-1]
                        Performparalist.append(temp_case_statements)
                    module = re.findall(r'^\s*.*\s*begsr\s.*', line, re.IGNORECASE)
                    if module != []:
                        modulelist.append(module)
                    lenofmodulelist = len(modulelist)
                    if module != []:
                        currentmodule = modulelist[lenofmodulelist - 1]
                        currentmodulevalue = currentmodule[0]
                        currentmodulevalue = re.sub('begsr', '', currentmodulevalue)
                    if perform != [] or case_statements != []:
                        if perform != []:

                            performlist.append(perform)
                            performline = perform
                            perform = perform[0].split()
                            perform = perform[1]

                        elif case_statements != []:
                            performlist.append(case_statements)
                            performline = case_statements
                            perform = case_statements[0].split()
                            perform = perform[3]

                        with  open("FinalFile1" + str(i) + '.txt', "a") as temp_file1:
                            if perform == "":
                                temp_file1.write('\n')
                            else:
                                # performWrite = '@' + performline[0] + '  ^' + currentmodulevalue
                                performWrite = '@' + performline[0]
                                temp_file1.write('\n')
                                temp_file1.write(performWrite)

                        with  open("Duplicatefile0" + str(i) + '.txt', "r+") as temp_file:
                            for line in temp_file.readlines():
                                # line=line[6:]
                                module = re.findall(r'^\s*.*\s*begsr\s.*', line, re.IGNORECASE)
                                if module != []:
                                    module = module[0]
                                    module = module.split()
                                    if module[0] == "begsr" or module[0] == "BEGSR":
                                        module = module[1]
                                    else:
                                        module = module[0]
                                if module.__contains__(';'):
                                    module = module[:-1]
                                if perform == []:
                                    perform = ""
                                if module == []:
                                    module = ""
                                if perform.lower() == module.lower() and (perform != [] or perform != ""):
                                    flag = True
                                if flag:
                                    module = re.findall(r'^\s*.*\s*begsr\s.*', line, re.IGNORECASE)
                                    endsr = re.findall(r'^\s*.*\sendsr\s*.*', line, re.IGNORECASE)

                                    if flag:
                                        with  open("FinalFile1" + str(i) + '.txt', "a") as temp_file1:
                                            # print(line)
                                            temp_file1.write('\n')
                                            temp_file1.write(line)
                                    if endsr != []:
                                        flag = False
                    else:
                        with  open("FinalFile1" + str(i) + '.txt', "a") as temp_file1:
                            temp_file1.write('\n')
                            temp_file1.write(line)

        modulelist = []
        performlist = []

        with open("FinalFile1" + str(i) + '.txt', "r") as temp_file:
            for line in temp_file.readlines():
                # line=line[6:]
                if line.strip() == '' or line[0] == '*':
                    continue
                else:
                    perform = re.findall(r'^\s*exsr\s*.*', line, re.IGNORECASE)
                    case_statements = re.findall(r'^\s[^@]*.*case.*', line, re.IGNORECASE)

                    if perform != []:
                        Temp_perform = perform[0]
                        Temp_perform = Temp_perform.split()
                        Temp_perform = Temp_perform[1]
                        if Temp_perform.__contains__(';'):
                            Temp_perform = Temp_perform[:-1]
                        Performparalist.append(Temp_perform)
                    elif (case_statements != []):
                        temp_case_statements = case_statements[0].split()
                        temp_case_statements = temp_case_statements[3]
                        if temp_case_statements.__contains__(';'):
                            temp_case_statements = temp_case_statements[:-1]
                        Performparalist.append(temp_case_statements)
                    module = re.findall(r'^\s*.*\s*begsr\s.*', line, re.IGNORECASE)
                    if module != []:
                        modulelist.append(module)
                    lenofmodulelist = len(modulelist)
                    if module != []:
                        currentmodule = modulelist[lenofmodulelist - 1]
                        currentmodulevalue = currentmodule[0]
                        currentmodulevalue = re.sub('begsr', '', currentmodulevalue)
                    if perform != [] or case_statements != []:
                        if perform != []:

                            performlist.append(perform)
                            performline = perform
                            perform = perform[0].split()
                            perform = perform[1]

                        elif case_statements != []:
                            performlist.append(case_statements)
                            performline = case_statements
                            perform = case_statements[0].split()
                            perform = perform[3]

                        with  open("FinalFile2" + str(i) + '.txt', "a") as temp_file1:
                            if perform == "":
                                temp_file1.write('\n')
                            else:
                                # performWrite = '@' + performline[0] + '  ^' + currentmodulevalue
                                performWrite = '@' + performline[0]
                                temp_file1.write('\n')
                                temp_file1.write(performWrite)

                        with  open("Duplicatefile0" + str(i) + '.txt', "r+") as temp_file:
                            for line in temp_file.readlines():
                                # line=line[6:]
                                module = re.findall(r'^\s*.*\s*begsr\s.*', line, re.IGNORECASE)
                                if module != []:
                                    module = module[0]
                                    module = module.split()
                                    if module[0] == "begsr" or module[0] == "BEGSR":
                                        module = module[1]
                                    else:
                                        module = module[0]
                                if module.__contains__(';'):
                                    module = module[:-1]
                                if perform == []:
                                    perform = ""
                                if module == []:
                                    module = ""
                                if perform.lower() == module.lower() and (perform != [] or perform != ""):
                                    flag = True
                                if flag:
                                    module = re.findall(r'^\s*.*\s*begsr\s.*', line, re.IGNORECASE)
                                    endsr = re.findall(r'^\s*.*\sendsr\s*.*', line, re.IGNORECASE)

                                    if flag:
                                        with  open("FinalFile2" + str(i) + '.txt', "a") as temp_file1:
                                            # print(line)
                                            temp_file1.write('\n')
                                            temp_file1.write(line)
                                    if endsr != []:
                                        flag = False
                    else:
                        with  open("FinalFile2" + str(i) + '.txt', "a") as temp_file1:
                            temp_file1.write('\n')
                            temp_file1.write(line)
        modulelist = []
        performlist = []

        with open("FinalFile2" + str(i) + '.txt', "r") as temp_file:
            for line in temp_file.readlines():
                # line=line[6:]
                if line.strip() == '' or line[0] == '*':
                    continue
                else:
                    perform = re.findall(r'^\s*exsr\s*.*', line, re.IGNORECASE)
                    case_statements = re.findall(r'^\s[^@]*.*case.*', line, re.IGNORECASE)

                    if perform != []:
                        Temp_perform = perform[0]
                        Temp_perform = Temp_perform.split()
                        Temp_perform = Temp_perform[1]
                        if Temp_perform.__contains__(';'):
                            Temp_perform = Temp_perform[:-1]
                        Performparalist.append(Temp_perform)
                    elif (case_statements != []):
                        temp_case_statements = case_statements[0].split()
                        temp_case_statements = temp_case_statements[3]
                        if temp_case_statements.__contains__(';'):
                            temp_case_statements = temp_case_statements[:-1]
                        Performparalist.append(temp_case_statements)
                    module = re.findall(r'^\s*.*\s*begsr\s.*', line, re.IGNORECASE)
                    if module != []:
                        modulelist.append(module)
                    lenofmodulelist = len(modulelist)
                    if module != []:
                        currentmodule = modulelist[lenofmodulelist - 1]
                        currentmodulevalue = currentmodule[0]
                        currentmodulevalue = re.sub('begsr', '', currentmodulevalue)
                    if perform != [] or case_statements != []:
                        if perform != []:

                            performlist.append(perform)
                            performline = perform
                            perform = perform[0].split()
                            perform = perform[1]

                        elif case_statements != []:
                            performlist.append(case_statements)
                            performline = case_statements
                            perform = case_statements[0].split()
                            perform = perform[3]

                        with  open("FinalFile3" + str(i) + '.txt', "a") as temp_file1:
                            if perform == "":
                                temp_file1.write('\n')
                            else:
                                # performWrite = '@' + performline[0] + '  ^' + currentmodulevalue
                                performWrite = '@' + performline[0]
                                temp_file1.write('\n')
                                temp_file1.write(performWrite)

                        with  open("Duplicatefile0" + str(i) + '.txt', "r+") as temp_file:
                            for line in temp_file.readlines():
                                # line=line[6:]
                                module = re.findall(r'^\s*.*\s*begsr\s.*', line, re.IGNORECASE)
                                if module != []:
                                    module = module[0]
                                    module = module.split()
                                    if module[0] == "begsr" or module[0] == "BEGSR":
                                        module = module[1]
                                    else:
                                        module = module[0]
                                if module.__contains__(';'):
                                    module = module[:-1]
                                if perform == []:
                                    perform = ""
                                if module == []:
                                    module = ""
                                if perform.lower() == module.lower() and (perform != [] or perform != ""):
                                    flag = True
                                if flag:
                                    module = re.findall(r'^\s*.*\s*begsr\s.*', line, re.IGNORECASE)
                                    endsr = re.findall(r'^\s*.*\sendsr\s*.*', line, re.IGNORECASE)

                                    if flag:
                                        with  open("FinalFile3" + str(i) + '.txt', "a") as temp_file1:
                                            # print(line)
                                            temp_file1.write('\n')
                                            temp_file1.write(line)
                                    if endsr != []:
                                        flag = False
                    else:
                        with  open("FinalFile3" + str(i) + '.txt', "a") as temp_file1:
                            temp_file1.write('\n')
                            temp_file1.write(line)
        modulelist = []
        performlist = []

        with open("FinalFile3" + str(i) + '.txt', "r") as temp_file:
            for line in temp_file.readlines():
                # line=line[6:]
                if line.strip() == '' or line[0] == '*':
                    continue
                else:
                    perform = re.findall(r'^\s*exsr\s*.*', line, re.IGNORECASE)
                    case_statements = re.findall(r'^\s[^@]*.*case.*', line, re.IGNORECASE)

                    if perform != []:
                        Temp_perform = perform[0]
                        Temp_perform = Temp_perform.split()
                        Temp_perform = Temp_perform[1]
                        if Temp_perform.__contains__(';'):
                            Temp_perform = Temp_perform[:-1]
                        Performparalist.append(Temp_perform)
                    elif (case_statements != []):
                        temp_case_statements = case_statements[0].split()
                        temp_case_statements = temp_case_statements[3]
                        if temp_case_statements.__contains__(';'):
                            temp_case_statements = temp_case_statements[:-1]
                        Performparalist.append(temp_case_statements)
                    module = re.findall(r'^\s*.*\s*begsr\s.*', line, re.IGNORECASE)
                    if module != []:
                        modulelist.append(module)
                    lenofmodulelist = len(modulelist)
                    if module != []:
                        currentmodule = modulelist[lenofmodulelist - 1]
                        currentmodulevalue = currentmodule[0]
                        currentmodulevalue = re.sub('begsr', '', currentmodulevalue)
                    if perform != [] or case_statements != []:
                        if perform != []:

                            performlist.append(perform)
                            performline = perform
                            perform = perform[0].split()
                            perform = perform[1]

                        elif case_statements != []:
                            performlist.append(case_statements)
                            performline = case_statements
                            perform = case_statements[0].split()
                            perform = perform[3]

                        with  open("FinalFile4" + str(i) + '.txt', "a") as temp_file1:
                            if perform == "":
                                temp_file1.write('\n')
                            else:
                                # performWrite = '@' + performline[0] + '  ^' + currentmodulevalue
                                performWrite = '@' + performline[0]
                                temp_file1.write('\n')
                                temp_file1.write(performWrite)

                        with  open("Duplicatefile0" + str(i) + '.txt', "r+") as temp_file:
                            for line in temp_file.readlines():
                                # line=line[6:]
                                module = re.findall(r'^\s*.*\s*begsr\s.*', line, re.IGNORECASE)
                                if module != []:
                                    module = module[0]
                                    module = module.split()
                                    if module[0] == "begsr" or module[0] == "BEGSR":
                                        module = module[1]
                                    else:
                                        module = module[0]
                                if module.__contains__(';'):
                                    module = module[:-1]
                                if perform == []:
                                    perform = ""
                                if module == []:
                                    module = ""
                                if perform.lower() == module.lower() and (perform != [] or perform != ""):
                                    flag = True
                                if flag:
                                    module = re.findall(r'^\s*.*\s*begsr\s.*', line, re.IGNORECASE)
                                    endsr = re.findall(r'^\s*.*\sendsr\s*.*', line, re.IGNORECASE)

                                    if flag:
                                        with  open("FinalFile4" + str(i) + '.txt', "a") as temp_file1:
                                            # print(line)
                                            temp_file1.write('\n')
                                            temp_file1.write(line)
                                    if endsr != []:
                                        flag = False
                    else:
                        with  open("FinalFile4" + str(i) + '.txt', "a") as temp_file1:
                            temp_file1.write('\n')
                            temp_file1.write(line)

        modulelist = []
        performlist = []

        with open("FinalFile4" + str(i) + '.txt', "r") as temp_file:
            for line in temp_file.readlines():
                # line=line[6:]
                if line.strip() == '' or line[0] == '*':
                    continue
                else:
                    perform = re.findall(r'^\s*exsr\s*.*', line, re.IGNORECASE)
                    case_statements = re.findall(r'^\s[^@]*.*case.*', line, re.IGNORECASE)

                    if perform != []:
                        Temp_perform = perform[0]
                        Temp_perform = Temp_perform.split()
                        Temp_perform = Temp_perform[1]
                        if Temp_perform.__contains__(';'):
                            Temp_perform = Temp_perform[:-1]
                        Performparalist.append(Temp_perform)
                    elif (case_statements != []):
                        temp_case_statements = case_statements[0].split()
                        temp_case_statements = temp_case_statements[3]
                        if temp_case_statements.__contains__(';'):
                            temp_case_statements = temp_case_statements[:-1]
                        Performparalist.append(temp_case_statements)
                    module = re.findall(r'^\s*.*\s*begsr\s.*', line, re.IGNORECASE)
                    if module != []:
                        modulelist.append(module)
                    lenofmodulelist = len(modulelist)
                    if module != []:
                        currentmodule = modulelist[lenofmodulelist - 1]
                        currentmodulevalue = currentmodule[0]
                        currentmodulevalue = re.sub('begsr', '', currentmodulevalue)
                    if perform != [] or case_statements != []:
                        if perform != []:

                            performlist.append(perform)
                            performline = perform
                            perform = perform[0].split()
                            perform = perform[1]

                        elif case_statements != []:
                            performlist.append(case_statements)
                            performline = case_statements
                            perform = case_statements[0].split()
                            perform = perform[3]

                        with  open("FinalFile5" + str(i) + '.txt', "a") as temp_file1:
                            if perform == "":
                                temp_file1.write('\n')
                            else:
                                # performWrite = '@' + performline[0] + '  ^' + currentmodulevalue
                                performWrite = '@' + performline[0]
                                temp_file1.write('\n')
                                temp_file1.write(performWrite)

                        with  open("Duplicatefile0" + str(i) + '.txt', "r+") as temp_file:
                            for line in temp_file.readlines():
                                # line=line[6:]
                                module = re.findall(r'^\s*.*\s*begsr\s.*', line, re.IGNORECASE)
                                if module != []:
                                    module = module[0]
                                    module = module.split()
                                    if module[0] == "begsr" or module[0] == "BEGSR":
                                        module = module[1]
                                    else:
                                        module = module[0]
                                if module.__contains__(';'):
                                    module = module[:-1]
                                if perform == []:
                                    perform = ""
                                if module == []:
                                    module = ""
                                if perform.lower() == module.lower() and (perform != [] or perform != ""):
                                    flag = True
                                if flag:
                                    module = re.findall(r'^\s*.*\s*begsr\s.*', line, re.IGNORECASE)
                                    endsr = re.findall(r'^\s*.*\sendsr\s*.*', line, re.IGNORECASE)

                                    if flag:
                                        with  open("FinalFile5" + str(i) + '.txt', "a") as temp_file1:
                                            # print(line)
                                            temp_file1.write('\n')
                                            temp_file1.write(line)
                                    if endsr != []:
                                        flag = False
                    else:
                        with  open("FinalFile5" + str(i) + '.txt', "a") as temp_file1:
                            temp_file1.write('\n')
                            temp_file1.write(line)
        modulelist = []
        performlist = []

        with open("FinalFile5" + str(i) + '.txt', "r") as temp_file:
            for line in temp_file.readlines():
                # line=line[6:]
                if line.strip() == '' or line[0] == '*':
                    continue
                else:
                    perform = re.findall(r'^\s*exsr\s*.*', line, re.IGNORECASE)
                    case_statements = re.findall(r'^\s[^@]*.*case.*', line, re.IGNORECASE)

                    if perform != []:
                        Temp_perform = perform[0]
                        Temp_perform = Temp_perform.split()
                        Temp_perform = Temp_perform[1]
                        if Temp_perform.__contains__(';'):
                            Temp_perform = Temp_perform[:-1]
                        Performparalist.append(Temp_perform)
                    elif (case_statements != []):
                        temp_case_statements = case_statements[0].split()
                        temp_case_statements = temp_case_statements[3]
                        if temp_case_statements.__contains__(';'):
                            temp_case_statements = temp_case_statements[:-1]
                        Performparalist.append(temp_case_statements)
                    module = re.findall(r'^\s*.*\s*begsr\s.*', line, re.IGNORECASE)
                    if module != []:
                        modulelist.append(module)
                    lenofmodulelist = len(modulelist)
                    if module != []:
                        currentmodule = modulelist[lenofmodulelist - 1]
                        currentmodulevalue = currentmodule[0]
                        currentmodulevalue = re.sub('begsr', '', currentmodulevalue)
                    if perform != [] or case_statements != []:
                        if perform != []:

                            performlist.append(perform)
                            performline = perform
                            perform = perform[0].split()
                            perform = perform[1]

                        elif case_statements != []:
                            performlist.append(case_statements)
                            performline = case_statements
                            perform = case_statements[0].split()
                            perform = perform[3]

                        with  open("FinalFile6" + str(i) + '.txt', "a") as temp_file1:
                            if perform == "":
                                temp_file1.write('\n')
                            else:
                                # performWrite = '@' + performline[0] + '  ^' + currentmodulevalue
                                performWrite = '@' + performline[0]
                                temp_file1.write('\n')
                                temp_file1.write(performWrite)

                        with  open("Duplicatefile0" + str(i) + '.txt', "r+") as temp_file:
                            for line in temp_file.readlines():
                                # line=line[6:]
                                module = re.findall(r'^\s*.*\s*begsr\s.*', line, re.IGNORECASE)
                                if module != []:
                                    module = module[0]
                                    module = module.split()
                                    if module[0] == "begsr" or module[0] == "BEGSR":
                                        module = module[1]
                                    else:
                                        module = module[0]
                                if module.__contains__(';'):
                                    module = module[:-1]
                                if perform == []:
                                    perform = ""
                                if module == []:
                                    module = ""
                                if perform == module and (perform != [] or module != ""):
                                    flag = True
                                if flag:
                                    module = re.findall(r'^\s*.*\s*begsr\s.*', line, re.IGNORECASE)
                                    endsr = re.findall(r'^\s*.*\sendsr\s*.*', line, re.IGNORECASE)

                                    if flag:
                                        with  open("FinalFile6" + str(i) + '.txt', "a") as temp_file1:
                                            # print(line)
                                            temp_file1.write('\n')
                                            temp_file1.write(line)
                                    if endsr != []:
                                        flag = False

                    else:
                        with  open("FinalFile6" + str(i) + '.txt', "a") as temp_file1:
                            temp_file1.write('\n')
                            temp_file1.write(line)
        modulelist = []
        performlist = []

        with open("FinalFile6" + str(i) + '.txt', "r") as temp_file:
            for line in temp_file.readlines():
                # line=line[6:]
                if line.strip() == '' or line[0] == '*':
                    continue
                else:
                    perform = re.findall(r'^\s*exsr\s*.*', line, re.IGNORECASE)
                    case_statements = re.findall(r'^\s[^@]*.*case.*', line, re.IGNORECASE)

                    if perform != []:
                        Temp_perform = perform[0]
                        Temp_perform = Temp_perform.split()
                        Temp_perform = Temp_perform[1]
                        if Temp_perform.__contains__(';'):
                            Temp_perform = Temp_perform[:-1]
                        Performparalist.append(Temp_perform)
                    elif (case_statements != []):
                        temp_case_statements = case_statements[0].split()
                        temp_case_statements = temp_case_statements[3]
                        if temp_case_statements.__contains__(';'):
                            temp_case_statements = temp_case_statements[:-1]
                        Performparalist.append(temp_case_statements)
                    module = re.findall(r'^\s*.*\s*begsr\s.*', line, re.IGNORECASE)
                    if module != []:
                        modulelist.append(module)
                    lenofmodulelist = len(modulelist)
                    if module != []:
                        currentmodule = modulelist[lenofmodulelist - 1]
                        currentmodulevalue = currentmodule[0]
                        currentmodulevalue = re.sub('begsr', '', currentmodulevalue)
                    if perform != [] or case_statements != []:
                        if perform != []:

                            performlist.append(perform)
                            performline = perform
                            perform = perform[0].split()
                            perform = perform[1]

                        elif case_statements != []:
                            performlist.append(case_statements)
                            performline = case_statements
                            perform = case_statements[0].split()
                            perform = perform[3]

                        with  open("FinalFile7" + str(i) + '.txt', "a") as temp_file1:
                            if perform == "":
                                temp_file1.write('\n')
                            else:
                                # performWrite = '@' + performline[0] + '  ^' + currentmodulevalue
                                performWrite = '@' + performline[0]
                                temp_file1.write('\n')
                                temp_file1.write(performWrite)

                        with  open("Duplicatefile0" + str(i) + '.txt', "r+") as temp_file:
                            for line in temp_file.readlines():
                                # line=line[6:]
                                module = re.findall(r'^\s*.*\s*begsr\s.*', line, re.IGNORECASE)
                                if module != []:
                                    module = module[0]
                                    module = module.split()
                                    if module[0] == "begsr" or module[0] == "BEGSR":
                                        module = module[1]
                                    else:
                                        module = module[0]
                                if module.__contains__(';'):
                                    module = module[:-1]
                                if perform == []:
                                    perform = ""
                                if module == []:
                                    module = ""
                                if perform.lower() == module.lower() and (perform != [] or perform != ""):
                                    flag = True
                                if flag:
                                    module = re.findall(r'^\s*.*\s*begsr\s.*', line, re.IGNORECASE)
                                    endsr = re.findall(r'^\s*.*\sendsr\s*.*', line, re.IGNORECASE)

                                    if flag:
                                        with  open("FinalFile7" + str(i) + '.txt', "a") as temp_file1:
                                            # print(line)
                                            temp_file1.write('\n')
                                            temp_file1.write(line)
                                    if endsr != []:
                                        flag = False
                    else:
                        with  open("FinalFile7" + str(i) + '.txt', "a") as temp_file1:
                            temp_file1.write('\n')
                            temp_file1.write(line)
        modulelist = []
        performlist = []

        with open("FinalFile7" + str(i) + '.txt', "r") as temp_file:
            for line in temp_file.readlines():
                # line=line[6:]
                if line.strip() == '' or line[0] == '*':
                    continue
                else:
                    perform = re.findall(r'^\s*exsr\s*.*', line, re.IGNORECASE)
                    case_statements = re.findall(r'^\s[^@]*.*case.*', line, re.IGNORECASE)

                    if perform != []:
                        Temp_perform = perform[0]
                        Temp_perform = Temp_perform.split()
                        Temp_perform = Temp_perform[1]
                        if Temp_perform.__contains__(';'):
                            Temp_perform = Temp_perform[:-1]
                        Performparalist.append(Temp_perform)
                    elif (case_statements != []):
                        temp_case_statements = case_statements[0].split()
                        temp_case_statements = temp_case_statements[3]
                        if temp_case_statements.__contains__(';'):
                            temp_case_statements = temp_case_statements[:-1]
                        Performparalist.append(temp_case_statements)
                    module = re.findall(r'^\s*.*\s*begsr\s.*', line, re.IGNORECASE)
                    if module != []:
                        modulelist.append(module)
                    lenofmodulelist = len(modulelist)
                    if module != []:
                        currentmodule = modulelist[lenofmodulelist - 1]
                        currentmodulevalue = currentmodule[0]
                        currentmodulevalue = re.sub('begsr', '', currentmodulevalue)
                    if perform != [] or case_statements != []:
                        if perform != []:

                            performlist.append(perform)
                            performline = perform
                            perform = perform[0].split()
                            perform = perform[1]

                        elif case_statements != []:
                            performlist.append(case_statements)
                            performline = case_statements
                            perform = case_statements[0].split()
                            perform = perform[3]

                        with  open("FinalFile8" + str(i) + '.txt', "a") as temp_file1:
                            if perform == "":
                                temp_file1.write('\n')
                            else:
                                # performWrite = '@' + performline[0] + '  ^' + currentmodulevalue
                                performWrite = '@' + performline[0]
                                temp_file1.write('\n')
                                temp_file1.write(performWrite)

                        with  open("Duplicatefile0" + str(i) + '.txt', "r+") as temp_file:
                            for line in temp_file.readlines():
                                # line=line[6:]
                                module = re.findall(r'^\s*.*\s*begsr\s.*', line, re.IGNORECASE)
                                if module != []:
                                    module = module[0]
                                    module = module.split()
                                    if module[0] == "begsr" or module[0] == "BEGSR":
                                        module = module[1]
                                    else:
                                        module = module[0]
                                if module.__contains__(';'):
                                    module = module[:-1]
                                if perform == []:
                                    perform = ""
                                if module == []:
                                    module = ""
                                if perform.lower() == module.lower() and (perform != [] or perform != ""):
                                    flag = True
                                if flag:
                                    module = re.findall(r'^\s*.*\s*begsr\s.*', line, re.IGNORECASE)
                                    endsr = re.findall(r'^\s*.*\sendsr\s*.*', line, re.IGNORECASE)

                                    if flag:
                                        with  open("FinalFile8" + str(i) + '.txt', "a") as temp_file1:
                                            # print(line)
                                            temp_file1.write('\n')
                                            temp_file1.write(line)
                                    if endsr != []:
                                        flag = False
                    else:
                        with  open("FinalFile8" + str(i) + '.txt', "a") as temp_file1:
                            temp_file1.write('\n')
                            temp_file1.write(line)
        modulelist = []
        performlist = []

        with open("FinalFile8" + str(i) + '.txt', "r") as temp_file:
            for line in temp_file.readlines():
                # line=line[6:]
                if line.strip() == '' or line[0] == '*':
                    continue
                else:
                    perform = re.findall(r'^\s*exsr\s*.*', line, re.IGNORECASE)
                    case_statements = re.findall(r'^\s[^@]*.*case.*', line, re.IGNORECASE)

                    if perform != []:
                        Temp_perform = perform[0]
                        Temp_perform = Temp_perform.split()
                        Temp_perform = Temp_perform[1]
                        if Temp_perform.__contains__(';'):
                            Temp_perform = Temp_perform[:-1]
                        Performparalist.append(Temp_perform)
                    elif (case_statements != []):
                        temp_case_statements = case_statements[0].split()
                        temp_case_statements = temp_case_statements[3]
                        if temp_case_statements.__contains__(';'):
                            temp_case_statements = temp_case_statements[:-1]
                        Performparalist.append(temp_case_statements)
                    module = re.findall(r'^\s*.*\s*begsr\s.*', line, re.IGNORECASE)
                    if module != []:
                        modulelist.append(module)
                    lenofmodulelist = len(modulelist)
                    if module != []:
                        currentmodule = modulelist[lenofmodulelist - 1]
                        currentmodulevalue = currentmodule[0]
                        currentmodulevalue = re.sub('begsr', '', currentmodulevalue)
                    if perform != [] or case_statements != []:
                        if perform != []:

                            performlist.append(perform)
                            performline = perform
                            perform = perform[0].split()
                            perform = perform[1]

                        elif case_statements != []:
                            performlist.append(case_statements)
                            performline = case_statements
                            perform = case_statements[0].split()
                            perform = perform[3]

                        with  open("FinalFile9" + str(i) + '.txt', "a") as temp_file1:
                            if perform == "":
                                temp_file1.write('\n')
                            else:
                                # performWrite = '@' + performline[0] + '  ^' + currentmodulevalue
                                performWrite = '@' + performline[0]
                                temp_file1.write('\n')
                                temp_file1.write(performWrite)

                        with  open("Duplicatefile0" + str(i) + '.txt', "r+") as temp_file:
                            for line in temp_file.readlines():
                                # line=line[6:]
                                module = re.findall(r'^\s*.*\s*begsr\s.*', line, re.IGNORECASE)
                                if module != []:
                                    module = module[0]
                                    module = module.split()
                                    if module[0] == "begsr" or module[0] == "BEGSR":
                                        module = module[1]
                                    else:
                                        module = module[0]
                                if module.__contains__(';'):
                                    module = module[:-1]
                                if perform == []:
                                    perform = ""
                                if module == []:
                                    module = ""
                                if perform.lower() == module.lower() and (perform != [] or perform != ""):
                                    flag = True
                                if flag:
                                    module = re.findall(r'^\s*.*\s*begsr\s.*', line, re.IGNORECASE)
                                    endsr = re.findall(r'^\s*.*\sendsr\s*.*', line, re.IGNORECASE)

                                    if flag:
                                        with  open("FinalFile9" + str(i) + '.txt', "a") as temp_file1:
                                            # print(line)
                                            temp_file1.write('\n')
                                            temp_file1.write(line)
                                    if endsr != []:
                                        flag = False
                    else:
                        with  open("FinalFile9" + str(i) + '.txt', "a") as temp_file1:
                            temp_file1.write('\n')
                            temp_file1.write(line)
        modulelist = []
        performlist = []

        with open("FinalFile9" + str(i) + '.txt', "r") as temp_file:
            for line in temp_file.readlines():
                # line=line[6:]
                if line.strip() == '' or line[0] == '*':
                    continue
                else:
                    perform = re.findall(r'^\s*exsr\s*.*', line, re.IGNORECASE)
                    case_statements = re.findall(r'^\s[^@]*.*case.*', line, re.IGNORECASE)

                    if perform != []:
                        Temp_perform = perform[0]
                        Temp_perform = Temp_perform.split()
                        Temp_perform = Temp_perform[1]
                        if Temp_perform.__contains__(';'):
                            Temp_perform = Temp_perform[:-1]
                        Performparalist.append(Temp_perform)
                    elif (case_statements != []):
                        temp_case_statements = case_statements[0].split()
                        temp_case_statements = temp_case_statements[3]
                        if temp_case_statements.__contains__(';'):
                            temp_case_statements = temp_case_statements[:-1]
                        Performparalist.append(temp_case_statements)
                    module = re.findall(r'^\s*.*\s*begsr\s.*', line, re.IGNORECASE)
                    if module != []:
                        modulelist.append(module)
                    lenofmodulelist = len(modulelist)
                    if module != []:
                        currentmodule = modulelist[lenofmodulelist - 1]
                        currentmodulevalue = currentmodule[0]
                        currentmodulevalue = re.sub('begsr', '', currentmodulevalue)
                    if perform != [] or case_statements != []:
                        if perform != []:

                            performlist.append(perform)
                            performline = perform
                            perform = perform[0].split()
                            perform = perform[1]

                        elif case_statements != []:
                            performlist.append(case_statements)
                            performline = case_statements
                            perform = case_statements[0].split()
                            perform = perform[3]

                        with  open("FinalFile10" + str(i) + '.txt', "a") as temp_file1:
                            if perform == "":
                                temp_file1.write('\n')
                            else:
                                # performWrite = '@' + performline[0] + '  ^' + currentmodulevalue
                                performWrite = '@' + performline[0]
                                temp_file1.write('\n')
                                temp_file1.write(performWrite)

                        with  open("Duplicatefile0" + str(i) + '.txt', "r+") as temp_file:
                            for line in temp_file.readlines():
                                # line=line[6:]
                                module = re.findall(r'^\s*.*\s*begsr\s.*', line, re.IGNORECASE)
                                if module != []:
                                    module = module[0]
                                    module = module.split()
                                    if module[0] == "begsr" or module[0] == "BEGSR":
                                        module = module[1]
                                    else:
                                        module = module[0]
                                if module.__contains__(';'):
                                    module = module[:-1]
                                if perform == []:
                                    perform = ""
                                if module == []:
                                    module = ""
                                if perform.lower() == module.lower() and (perform != [] or perform != ""):
                                    flag = True
                                if flag:
                                    module = re.findall(r'^\s*.*\s*begsr\s.*', line, re.IGNORECASE)
                                    endsr = re.findall(r'^\s*.*\sendsr\s*.*', line, re.IGNORECASE)

                                    if flag:
                                        with  open("FinalFile10" + str(i) + '.txt', "a") as temp_file1:
                                            # print(line)
                                            temp_file1.write('\n')
                                            temp_file1.write(line)
                                    if endsr != []:
                                        flag = False
                    else:
                        with  open("FinalFile10" + str(i) + '.txt', "a") as temp_file1:
                            temp_file1.write('\n')
                            temp_file1.write(line)
        modulelist = []
        performlist = []

        with open("FinalFile10" + str(i) + '.txt', "r") as temp_file:
            for line in temp_file.readlines():
                # line=line[6:]
                if line.strip() == '' or line[0] == '*':
                    continue
                else:
                    perform = re.findall(r'^\s*exsr\s*.*', line, re.IGNORECASE)
                    case_statements = re.findall(r'^\s[^@]*.*case.*', line, re.IGNORECASE)

                    if perform != []:
                        Temp_perform = perform[0]
                        Temp_perform = Temp_perform.split()
                        Temp_perform = Temp_perform[1]
                        if Temp_perform.__contains__(';'):
                            Temp_perform = Temp_perform[:-1]
                        Performparalist.append(Temp_perform)
                    elif (case_statements != []):
                        temp_case_statements = case_statements[0].split()
                        temp_case_statements = temp_case_statements[3]
                        if temp_case_statements.__contains__(';'):
                            temp_case_statements = temp_case_statements[:-1]
                        Performparalist.append(temp_case_statements)
                    module = re.findall(r'^\s*.*\s*begsr\s.*', line, re.IGNORECASE)
                    if module != []:
                        modulelist.append(module)
                    lenofmodulelist = len(modulelist)
                    if module != []:
                        currentmodule = modulelist[lenofmodulelist - 1]
                        currentmodulevalue = currentmodule[0]
                        currentmodulevalue = re.sub('begsr', '', currentmodulevalue)
                    if perform != [] or case_statements != []:
                        if perform != []:

                            performlist.append(perform)
                            performline = perform
                            perform = perform[0].split()
                            perform = perform[1]

                        elif case_statements != []:
                            performlist.append(case_statements)
                            performline = case_statements
                            perform = case_statements[0].split()
                            perform = perform[3]

                        with  open("FinalFile11" + str(i) + '.txt', "a") as temp_file1:
                            if perform == "":
                                temp_file1.write('\n')
                            else:
                                # performWrite = '@' + performline[0] + '  ^' + currentmodulevalue
                                performWrite = '@' + performline[0]
                                temp_file1.write('\n')
                                temp_file1.write(performWrite)

                        with  open("Duplicatefile0" + str(i) + '.txt', "r+") as temp_file:
                            for line in temp_file.readlines():
                                # line=line[6:]
                                module = re.findall(r'^\s*.*\s*begsr\s.*', line, re.IGNORECASE)
                                if module != []:
                                    module = module[0]
                                    module = module.split()
                                    if module[0] == "begsr" or module[0] == "BEGSR":
                                        module = module[1]
                                    else:
                                        module = module[0]
                                if module.__contains__(';'):
                                    module = module[:-1]
                                if perform == []:
                                    perform = ""
                                if module == []:
                                    module = ""
                                if perform.lower() == module.lower() and (perform != [] or perform != ""):
                                    flag = True
                                if flag:
                                    module = re.findall(r'^\s*.*\s*begsr\s.*', line, re.IGNORECASE)
                                    endsr = re.findall(r'^\s*.*\sendsr\s*.*', line, re.IGNORECASE)

                                    if flag:
                                        with  open("FinalFile11" + str(i) + '.txt', "a") as temp_file1:
                                            # print(line)
                                            temp_file1.write('\n')
                                            temp_file1.write(line)
                                    if endsr != []:
                                        flag = False
                    else:
                        with  open("FinalFile11" + str(i) + '.txt', "a") as temp_file1:
                            temp_file1.write('\n')
                            temp_file1.write(line)
        modulelist = []
        performlist = []

        with open("FinalFile11" + str(i) + '.txt', "r") as temp_file:
            for line in temp_file.readlines():
                # line=line[6:]
                if line.strip() == '' or line[0] == '*':
                    continue
                else:
                    perform = re.findall(r'^\s*exsr\s*.*', line, re.IGNORECASE)
                    case_statements = re.findall(r'^\s[^@]*.*case.*', line, re.IGNORECASE)

                    if perform != []:
                        Temp_perform = perform[0]
                        Temp_perform = Temp_perform.split()
                        Temp_perform = Temp_perform[1]
                        if Temp_perform.__contains__(';'):
                            Temp_perform = Temp_perform[:-1]
                        Performparalist.append(Temp_perform)
                    elif (case_statements != []):
                        temp_case_statements = case_statements[0].split()
                        temp_case_statements = temp_case_statements[3]
                        if temp_case_statements.__contains__(';'):
                            temp_case_statements = temp_case_statements[:-1]
                        Performparalist.append(temp_case_statements)
                    module = re.findall(r'^\s*.*\s*begsr\s.*', line, re.IGNORECASE)
                    if module != []:
                        modulelist.append(module)
                    lenofmodulelist = len(modulelist)
                    if module != []:
                        currentmodule = modulelist[lenofmodulelist - 1]
                        currentmodulevalue = currentmodule[0]
                        currentmodulevalue = re.sub('begsr', '', currentmodulevalue)
                    if perform != [] or case_statements != []:
                        if perform != []:

                            performlist.append(perform)
                            performline = perform
                            perform = perform[0].split()
                            perform = perform[1]

                        elif case_statements != []:
                            performlist.append(case_statements)
                            performline = case_statements
                            perform = case_statements[0].split()
                            perform = perform[3]

                        with  open("FinalFile12" + str(i) + '.txt', "a") as temp_file1:
                            if perform == "":
                                temp_file1.write('\n')
                            else:
                                # performWrite = '@' + performline[0] + '  ^' + currentmodulevalue
                                performWrite = '@' + performline[0]
                                temp_file1.write('\n')
                                temp_file1.write(performWrite)

                        with  open("Duplicatefile0" + str(i) + '.txt', "r+") as temp_file:
                            for line in temp_file.readlines():
                                # line=line[6:]
                                module = re.findall(r'^\s*.*\s*begsr\s.*', line, re.IGNORECASE)
                                if module != []:
                                    module = module[0]
                                    module = module.split()
                                    if module[0] == "begsr" or module[0] == "BEGSR":
                                        module = module[1]
                                    else:
                                        module = module[0]
                                if module.__contains__(';'):
                                    module = module[:-1]
                                if perform == []:
                                    perform = ""
                                if module == []:
                                    module = ""
                                if perform.lower() == module.lower() and (perform != [] or perform != ""):
                                    flag = True
                                if flag:
                                    module = re.findall(r'^\s*.*\s*begsr\s.*', line, re.IGNORECASE)
                                    endsr = re.findall(r'^\s*.*\sendsr\s*.*', line, re.IGNORECASE)

                                    if flag:
                                        with  open("FinalFile12" + str(i) + '.txt', "a") as temp_file1:
                                            # print(line)
                                            temp_file1.write('\n')
                                            temp_file1.write(line)
                                    if endsr != []:
                                        flag = False
                    else:
                        with  open("FinalFile12" + str(i) + '.txt', "a") as temp_file1:
                            temp_file1.write('\n')
                            temp_file1.write(line)

        modulelist = []
        performlist = []

        with open("FinalFile12" + str(i) + '.txt', "r") as temp_file:
            for line in temp_file.readlines():
                # line=line[6:]
                if line.strip() == '' or line[0] == '*':
                    continue
                else:
                    perform = re.findall(r'^\s*exsr\s*.*', line, re.IGNORECASE)
                    case_statements = re.findall(r'^\s[^@]*.*case.*', line, re.IGNORECASE)

                    if perform != []:
                        Temp_perform = perform[0]
                        Temp_perform = Temp_perform.split()
                        Temp_perform = Temp_perform[1]
                        if Temp_perform.__contains__(';'):
                            Temp_perform = Temp_perform[:-1]
                        Performparalist.append(Temp_perform)
                    elif (case_statements != []):
                        temp_case_statements = case_statements[0].split()
                        temp_case_statements = temp_case_statements[3]
                        if temp_case_statements.__contains__(';'):
                            temp_case_statements = temp_case_statements[:-1]
                        Performparalist.append(temp_case_statements)
                    module = re.findall(r'^\s*.*\s*begsr\s.*', line, re.IGNORECASE)
                    if module != []:
                        modulelist.append(module)
                    lenofmodulelist = len(modulelist)
                    if module != []:
                        currentmodule = modulelist[lenofmodulelist - 1]
                        currentmodulevalue = currentmodule[0]
                        currentmodulevalue = re.sub('begsr', '', currentmodulevalue)
                    if perform != [] or case_statements != []:
                        if perform != []:

                            performlist.append(perform)
                            performline = perform
                            perform = perform[0].split()
                            perform = perform[1]

                        elif case_statements != []:
                            performlist.append(case_statements)
                            performline = case_statements
                            perform = case_statements[0].split()
                            perform = perform[3]

                        with  open("FinalFile13" + str(i) + '.txt', "a") as temp_file1:
                            if perform == "":
                                temp_file1.write('\n')
                            else:
                                # performWrite = '@' + performline[0] + '  ^' + currentmodulevalue
                                performWrite = '@' + performline[0]
                                temp_file1.write('\n')
                                temp_file1.write(performWrite)

                        with  open("Duplicatefile0" + str(i) + '.txt', "r+") as temp_file:
                            for line in temp_file.readlines():
                                # line=line[6:]
                                module = re.findall(r'^\s*.*\s*begsr\s.*', line, re.IGNORECASE)
                                if module != []:
                                    module = module[0]
                                    module = module.split()
                                    if module[0] == "begsr" or module[0] == "BEGSR":
                                        module = module[1]
                                    else:
                                        module = module[0]

                                if module.__contains__(';'):
                                    module = module[:-1]

                                if perform == []:
                                    perform = ""
                                if module == []:
                                    module = ""
                                if perform.lower() == module.lower() and (perform != [] or perform != ""):
                                    flag = True
                                if flag:
                                    module = re.findall(r'^\s*.*\s*begsr\s.*', line, re.IGNORECASE)
                                    endsr = re.findall(r'^\s*.*\sendsr\s*.*', line, re.IGNORECASE)

                                    if flag:
                                        with  open("FinalFile13" + str(i) + '.txt', "a") as temp_file1:
                                            # print(line)
                                            temp_file1.write('\n')
                                            temp_file1.write(line)
                                    if endsr != []:
                                        flag = False
                    else:
                        with  open("FinalFile13" + str(i) + '.txt', "a") as temp_file1:
                            temp_file1.write('\n')
                            temp_file1.write(line)

        modulelist = []
        performlist = []

        with open("FinalFile13" + str(i) + '.txt', "r") as temp_file:
            for line in temp_file.readlines():
                # line=line[6:]
                if line.strip() == '' or line[0] == '*':
                    continue
                else:
                    perform = re.findall(r'^\s*exsr\s*.*', line, re.IGNORECASE)
                    case_statements = re.findall(r'^\s[^@]*.*case.*', line, re.IGNORECASE)

                    if perform != []:
                        Temp_perform = perform[0]
                        Temp_perform = Temp_perform.split()
                        Temp_perform = Temp_perform[1]
                        if Temp_perform.__contains__(';'):
                            Temp_perform = Temp_perform[:-1]
                        Performparalist.append(Temp_perform)
                    elif (case_statements != []):
                        temp_case_statements = case_statements[0].split()
                        temp_case_statements = temp_case_statements[3]
                        if temp_case_statements.__contains__(';'):
                            temp_case_statements = temp_case_statements[:-1]
                        Performparalist.append(temp_case_statements)
                    module = re.findall(r'^\s*.*\s*begsr\s.*', line, re.IGNORECASE)
                    if module != []:
                        modulelist.append(module)
                    lenofmodulelist = len(modulelist)
                    if module != []:
                        currentmodule = modulelist[lenofmodulelist - 1]
                        currentmodulevalue = currentmodule[0]
                        currentmodulevalue = re.sub('begsr', '', currentmodulevalue)
                    if perform != [] or case_statements != []:
                        if perform != []:

                            performlist.append(perform)
                            performline = perform
                            perform = perform[0].split()
                            perform = perform[1]

                        elif case_statements != []:
                            performlist.append(case_statements)
                            performline = case_statements
                            perform = case_statements[0].split()
                            perform = perform[3]

                        with  open("FinalFile14" + str(i) + '.txt', "a") as temp_file1:
                            if perform == "":
                                temp_file1.write('\n')
                            else:
                                # performWrite = '@' + performline[0] + '  ^' + currentmodulevalue
                                performWrite = '@' + performline[0]
                                temp_file1.write('\n')
                                temp_file1.write(performWrite)

                        with  open("Duplicatefile0" + str(i) + '.txt', "r+") as temp_file:
                            for line in temp_file.readlines():
                                # line=line[6:]
                                module = re.findall(r'^\s*.*\s*begsr\s.*', line, re.IGNORECASE)
                                if module != []:
                                    module = module[0]
                                    module = module.split()
                                    if module[0] == "begsr" or module[0] == "BEGSR":
                                        module = module[1]
                                    else:
                                        module = module[0]
                                if module.__contains__(';'):
                                    module = module[:-1]
                                if perform == []:
                                    perform = ""
                                if module == []:
                                    module = ""
                                if perform.lower() == module.lower() and (perform != [] or perform != ""):
                                    flag = True
                                if flag:
                                    module = re.findall(r'^\s*.*\s*begsr\s.*', line, re.IGNORECASE)
                                    endsr = re.findall(r'^\s*.*\sendsr\s*.*', line, re.IGNORECASE)

                                    if flag:
                                        with  open("FinalFile14" + str(i) + '.txt', "a") as temp_file1:
                                            # print(line)
                                            temp_file1.write('\n')
                                            temp_file1.write(line)
                                    if endsr != []:
                                        flag = False
                    else:
                        with  open("FinalFile14" + str(i) + '.txt', "a") as temp_file1:
                            temp_file1.write('\n')
                            temp_file1.write(line)

        modulelist = []
        performlist = []

        with open("FinalFile14" + str(i) + '.txt', "r") as temp_file:
            for line in temp_file.readlines():
                # line=line[6:]
                if line.strip() == '' or line[0] == '*':
                    continue
                else:
                    perform = re.findall(r'^\s*exsr\s*.*', line, re.IGNORECASE)
                    case_statements = re.findall(r'^\s[^@]*.*case.*', line, re.IGNORECASE)

                    if perform != []:
                        Temp_perform = perform[0]
                        Temp_perform = Temp_perform.split()
                        Temp_perform = Temp_perform[1]
                        if Temp_perform.__contains__(';'):
                            Temp_perform = Temp_perform[:-1]
                        Performparalist.append(Temp_perform)
                    elif (case_statements != []):
                        temp_case_statements = case_statements[0].split()
                        temp_case_statements = temp_case_statements[3]
                        if temp_case_statements.__contains__(';'):
                            temp_case_statements = temp_case_statements[:-1]
                        Performparalist.append(temp_case_statements)
                    module = re.findall(r'^\s*.*\s*begsr\s.*', line, re.IGNORECASE)
                    if module != []:
                        modulelist.append(module)
                    lenofmodulelist = len(modulelist)
                    if module != []:
                        currentmodule = modulelist[lenofmodulelist - 1]
                        currentmodulevalue = currentmodule[0]
                        currentmodulevalue = re.sub('begsr', '', currentmodulevalue)
                    if perform != [] or case_statements != []:
                        if perform != []:

                            performlist.append(perform)
                            performline = perform
                            perform = perform[0].split()
                            perform = perform[1]

                        elif case_statements != []:
                            performlist.append(case_statements)
                            performline = case_statements
                            perform = case_statements[0].split()
                            perform = perform[3]

                        with  open("FinalFile15" + str(i) + '.txt', "a") as temp_file1:
                            if perform == "":
                                temp_file1.write('\n')
                            else:
                                # performWrite = '@' + performline[0] + '  ^' + currentmodulevalue
                                performWrite = '@' + performline[0]
                                temp_file1.write('\n')
                                temp_file1.write(performWrite)

                        with  open("Duplicatefile0" + str(i) + '.txt', "r+") as temp_file:
                            for line in temp_file.readlines():
                                # line=line[6:]
                                module = re.findall(r'^\s*.*\s*begsr\s.*', line, re.IGNORECASE)
                                if module != []:
                                    module = module[0]
                                    module = module.split()
                                    if module[0] == "begsr" or module[0] == "BEGSR":
                                        module = module[1]
                                    else:
                                        module = module[0]
                                if module.__contains__(';'):
                                    module = module[:-1]
                                if perform == []:
                                    perform = ""
                                if module == []:
                                    module = ""
                                if perform.lower() == module.lower() and (perform != [] or perform != ""):
                                    flag = True
                                if flag:
                                    module = re.findall(r'^\s*.*\s*begsr\s.*', line, re.IGNORECASE)
                                    endsr = re.findall(r'^\s*.*\sendsr\s*.*', line, re.IGNORECASE)

                                    if flag:
                                        with  open("FinalFile15" + str(i) + '.txt', "a") as temp_file1:
                                            # print(line)
                                            temp_file1.write('\n')
                                            temp_file1.write(line)
                                    if endsr != []:
                                        flag = False
                    else:
                        with  open("FinalFile15" + str(i) + '.txt', "a") as temp_file1:
                            temp_file1.write('\n')
                            temp_file1.write(line)

        #   taging .
        # Performparalist=['œinit', 'œmain', 'œlast', 'œsethd', 'œmenu', 'œhelp', 'œcmdky', 'œhelp', 'œcmdky', 'œnmadd', '@ThirdPA', '@Endowment', 'œprdct', 'œagrno', 'œloand', 'œprpin', 'œinpol', 'œwarni', 'œuaptd', 'œaaddr', 'œintpay', '*pssr', 'œresp', 'œcmdky', 'œresp', 'œcmdky', 'œresp', 'œcmdky', 'œresp', 'œcmdky', 'œresp', 'œcmdky', 'œresp', 'œcmdky', 'œresp', 'œcmdky', 'œRESP', 'œCMDKY', 'œresp', 'œcmdky', 'œresp', 'œcmdky', 'œresp', 'œcmdky', 'sdscl', 'msgrtv', 'œsethd', 'œmenu', '*pssr', 'sdscl', 'msgrtv', 'œhelp', 'œcmdky', 'œhelp', 'œcmdky', 'œnmadd', '@ThirdPA', '@Endowment', 'œprdct', 'œagrno', 'œloand', 'œprpin', 'œinpol', 'œwarni', 'œuaptd', 'œaaddr', 'œintpay', 'œresp', 'œcmdky', 'œresp', 'œcmdky', 'œresp', 'œcmdky', 'œresp', 'œcmdky', 'œresp', 'œcmdky', 'œresp', 'œcmdky', 'œresp', 'œcmdky', 'œresp', 'œcmdky', 'œresp', 'œcmdky', 'œRESP', 'œCMDKY', 'œresp', 'œcmdky', 'sdscl', 'msgrtv', 'œhelp', 'œcmdky', 'œhelp', 'œcmdky', 'œnmadd', '@ThirdPA', '@Endowment', 'œprdct', 'œagrno', 'œloand', 'œprpin', 'œinpol', 'œwarni', 'œuaptd', 'œaaddr', 'œintpay', 'œresp', 'œcmdky', 'œresp', 'œcmdky', 'œresp', 'œcmdky', 'œresp', 'œcmdky', 'œresp', 'œcmdky', 'œresp', 'œcmdky', 'œresp', 'œcmdky', 'œresp', 'œcmdky', 'œresp', 'œcmdky', 'œRESP', 'œCMDKY', 'œresp', 'œcmdky', 'œresp', 'œcmdky', 'œresp', 'œcmdky', 'œresp', 'œcmdky', 'œresp', 'œcmdky', 'œresp', 'œcmdky', 'œresp', 'œcmdky', 'œresp', 'œcmdky', 'œresp', 'œcmdky', 'œresp', 'œcmdky', 'œRESP', 'œCMDKY', 'œresp', 'œcmdky']

        exsr_flag = False
        with open("FinalFile15" + str(i) + '.txt') as infile, open('output' + str(i) + '.txt', 'w') as outfile:
            for line in infile:
                if not line.strip():
                    continue  # skip the empty line
                else:
                    # module = re.findall(r'^\s{1}[a0-z9].[^"]*[-]*[.]', line)
                    module = re.findall(r'^\s*.*\s*begsr\s.*', line, re.IGNORECASE)
                    exsr_line = re.findall(r'^[@]*\s*exsr\s*.*', line, re.IGNORECASE)
                    caseq_line = re.findall(r'^[@]*\s*option\s*caseq\s*.*', line, re.IGNORECASE)

                    if exsr_line != []:
                        exsr_flag = True
                    performlistflag = True
                    if module != [] and exsr_flag:

                        line1 = module[0].split()

                        if line1[0] == "begsr" or line1[0] == "BEGSR":

                            module = line1[1]
                        else:

                            module = line1[0]

                        performlistflag = False
                        # print(line)
                        # print(module.strip(" "))
                        # print(Performparalist)
                        if module.strip(" ") in Performparalist:
                            if line.__contains__("begsr"):
                                line = line.replace('begsr', 'begsr1')

                            elif line.__contains__("BEGSR"):
                                line = line.replace('BEGSR', 'BEGSR1')

                            outfile.write(line)

                            performlistflag = False
                        else:
                            outfile.write(line)
                        if module.__contains__("EXIT."):
                            performlistflag = False

                    if line.__contains__("endsr"):
                        # print(line)
                        exsr_flag = False
                    if performlistflag:
                        outfile.write(line)
                        # print(line)
                # outfile.write(line)

        exsr_flag = False
        with open("output" + str(i) + '.txt') as infile, open('output1' + str(i) + '.txt', 'w') as outfile:
            for line in infile:
                if not line.strip():
                    continue  # skip the empty line
                else:
                    # module = re.findall(r'^\s{1}[a0-z9].[^"]*[-]*[.]', line)
                    module = re.findall(r'^\s*.*\s*begsr\s.*', line, re.IGNORECASE)
                    exsr_line = re.findall(r'^[@]*\s*exsr\s*.*', line, re.IGNORECASE)
                    caseq_line = re.findall(r'^[@]*\s*option\s*caseq\s*.*', line, re.IGNORECASE)

                    if caseq_line != []:
                        exsr_flag = True
                    performlistflag = True
                    if module != [] and exsr_flag:
                        line1 = module[0].split()

                        if line1[0] == "begsr" or line1[0] == "BEGSR":
                            module = line1[1]
                        else:
                            module = line1[0]
                        # if line1[0]=='@' and line1[1]=="option" and line1[2]=="caseq":
                        #     print(line1[4])
                        #     module=line1[4]

                        performlistflag = False
                        # print(line)
                        # print(module.strip(" "))
                        # print(Performparalist)
                        if module.strip(" ") in Performparalist:
                            if line.__contains__("begsr"):
                                line = line.replace('begsr', 'begsr1')

                            elif line.__contains__("BEGSR"):
                                line = line.replace('BEGSR', 'BEGSR1')

                            outfile.write(line)

                            performlistflag = False
                        else:
                            outfile.write(line)
                        if module.__contains__("EXIT."):
                            performlistflag = False

                    if line.__contains__("endsr"):
                        # print(line)
                        exsr_flag = False
                    if performlistflag:
                        outfile.write(line)

        performlistflag = True
        with open("output1" + str(i) + '.txt') as infile, open('output2' + str(i) + '.txt', 'w') as outfile:
            for line in infile:
                if not line.strip():
                    continue  # skip the empty line
                else:
                    # module = re.findall(r'^\s{1}[a0-z9].[^"]*[-]*[.]', line)
                    module = re.findall(r'^\s*.*\s*begsr\s.*', line, re.IGNORECASE)

                    if module != []:

                        line1 = module[0].split()

                        if line1[0] == "begsr" or line1[0] == "BEGSR":
                            module = line1[1]
                        else:
                            module = line1[0]

                        # elif line1[0]=='@' and line1[1]=="option" and line1[2]=="caseq":
                        #
                        #     module=line1[4]

                        # print(Performparalist)
                        performlistflag = True
                        # print("perof",Performparalist)
                        # print(module)
                        if module.strip(" ") in Performparalist:
                            # print("inside",Performparalist)
                            performlistflag = False
                        if module.__contains__("EXIT."):
                            performlistflag = False
                    if performlistflag:
                        outfile.write(line)

        Old_Division_Name = ""
        main_list2 = []
        main_dict2 = {}
        main_list3 = []
        main_dict3 = {}
        temp_string = ''
        header = ['cond', 'tag', 'category', 'statement']
        wb = xlrd.open_workbook(ConditionPath)
        sheet = wb.sheet_by_index(1)
        row = sheet.nrows
        cols = sheet.ncols
        for index in range(row):
            temp_list = []
            temp_list1 = []
            value = sheet.cell_value(index, 0)
            TypeValue = sheet.cell_value(index, 1)
            category = sheet.cell_value(index, 2)
            state_group = sheet.cell_value(index, 3)

            for index1 in range(cols):
                value1 = sheet.cell_value(index, index1)
                temp_list1.append(value1)
                temp_list.append(value1)
            del temp_list[0]
            del temp_list[0]
            del temp_list1[0]
            del temp_list1[0]
            temp_string = temp_list[0]
            temp_string1 = temp_list1[0]
            temp_string = temp_string
            temp_string1 = temp_string1
            temp_list[0] = temp_string
            temp_list1[0] = temp_string1
            for a in range(len(header)):
                main_dict2[header[a]] = temp_list[a]
            temp_dict = copy.deepcopy(main_dict2)
            main_list2.append(temp_dict)
            for j in range(len(header)):
                main_dict3[header[j]] = temp_list1[j]
            temp_dict1 = copy.deepcopy(main_dict3)
            main_list3.append(temp_dict1)

        # METADATA=[]
        rule_number = 0
        RC1 = 0
        RC2 = 0
        RC3 = 0
        RC4 = 0
        RC5 = 0
        RC6 = 0
        RC7 = 0
        RC8 = 0
        Db_update_counter = 0

        with open("output2" + str(i) + '.txt', "r") as temp_file:
            parent_rule_id_list = []
            ifcounter = 0
            counter = 0
            endifcounter = 0
            case_counter = 0
            case_flag = False
            select_flag = False
            endsr_flag = False
            for line1 in temp_file.readlines():

                loopNumber = 0
                exsr_regexx = re.findall(r'^\s*exsr\s*.*', line1, re.IGNORECASE)

                endsr_regexx = re.findall(r'^\s*.*\sendsr\s*.*', line1, re.IGNORECASE)

                begsr_regexx = re.findall(r'^\s*.*\s*begsr\s.*', line1, re.IGNORECASE)
                # print(main_list3)
                for item in main_list3:
                    loopNumber = loopNumber + 1
                    Reg_ex = item.get('cond')
                    programName = PGM_ID[i - 1]
                    lengthofprogramName = len(programName) - 1
                    programName = programName[0:lengthofprogramName]
                    Open_Rex = re.search(Reg_ex, line1.lower(), re.IGNORECASE)

                    if (Open_Rex != None):
                        # print("matched",line1)
                        if line1.__contains__("begsr1"):
                            line1 = line1.replace("begsr1", "begsr")
                        splitline = line1.split('^')
                        line = splitline[0]
                        stripline = line.strip()
                        # if len(splitline) == 1:
                        #    print("in",splitline)
                        #    paravalue = ""
                        # else:
                        paravalue = splitline[1]
                        paravalue = paravalue.strip()
                        rule_number = rule_number + 1

                        lengthofprogramname = len(programName)
                        if programName.__contains__('.'):
                            rule_id = programName[0:lengthofprogramname - 1] + '-' + str(rule_number)
                        else:
                            rule_id = programName + '-' + str(rule_number)
                        tag_value = item.get('tag')
                        catg_value = item.get('category')
                        statement_value = item.get('statement')

                        ##Parent id.

                        ifregexx = re.match('.*\sif\s.*', line.lower(), re.IGNORECASE)
                        # endifregexx = re.match('.*\sendif\s*', line.lower(),re.IGNORECASE)
                        endif1regexx = re.match('.*\sendif.*', line.lower(), re.IGNORECASE)
                        endregexx = re.match('.*\send\s.*', line.lower(), re.IGNORECASE)
                        evaluateregexx = re.match('.*\seval\s.*', line.lower(), re.IGNORECASE)
                        whenregexx = re.match('.*\swhen\s.*', line.lower(), re.IGNORECASE)
                        selectregexx = re.match('.*\sselect\s.*', line.lower(), re.IGNORECASE)
                        endselectregexx = re.match('.*\sendsl\s.*', line.lower(), re.IGNORECASE)
                        endcs_regexx = re.match('.*\sendcs\s*.*', line.lower(), re.IGNORECASE)
                        case_regexx = re.match('.*case.*', line.lower(), re.IGNORECASE)

                        # IF statemensts.

                        if ifregexx != None:

                            if ifcounter == 0:
                                firstparavalue = paravalue
                                ifcounter = ifcounter + 1
                                p_rule_id = rule_id
                                parent_rule_id_list.append(rule_id)
                                if_flag = True
                            else:
                                parent_rule_id_list.append(rule_id)
                        if selectregexx != None:
                            select_para = paravalue
                            select_flag = True
                            when_counter = 0

                        if select_flag:
                            if whenregexx != None:
                                when_flag = True
                                when_counter = when_counter + 1
                                if when_counter > 1:
                                    if parent_rule_id_list != []:
                                        p_id_list_len = len(parent_rule_id_list)
                                        del parent_rule_id_list[p_id_list_len - 1]
                                parent_rule_id_list.append(rule_id)

                        if endselectregexx != None and select_para.strip() == paravalue.strip():
                            select_flag = False

                            if parent_rule_id_list != [] and when_flag:
                                when_flag = False
                                p_id_list_len = len(parent_rule_id_list)
                                del parent_rule_id_list[p_id_list_len - 1]

                        """
                        if  endregexx!=None or endif1regexx!=None:
                                endifcounter=endifcounter+1
                                p_id_list_len = len(parent_rule_id_list)
                                if parent_rule_id_list != []:
                                    del parent_rule_id_list[p_id_list_len - 1]
                                ifcounter = ifcounter - 1
                        """

                        if case_regexx != None:
                            case_counter = case_counter + 1
                            if case_counter > 1:
                                p_id_list_len = len(parent_rule_id_list)
                                if parent_rule_id_list != []:
                                    del parent_rule_id_list[p_id_list_len - 1]

                            case_flag = True
                            parent_rule_id_list.append(rule_id)
                            case_para = paravalue

                        """
                        if case_flag:
                            print("caseeeeeeeeeeeeeee",line)
                            if endsr_regexx!=[]:
                                print("counter")
                                endsr_counter=endsr_counter+1
                                endsr_flag=True
                            if begsr_regexx!=[]:
                                print("exsr")
                                exsr_counter=exsr_counter+1
        
                            if endsr_counter>0 and endsr_counter == exsr_counter:
                                print('1',line)
                                p_id_list_len = len(parent_rule_id_list)
                                if parent_rule_id_list != []:
                                    del parent_rule_id_list[p_id_list_len - 1]
                                case_flag=False
        
                            if  endsr_flag ==False and case_counter>0:
                                endsr_flag=False
                                p_id_list_len = len(parent_rule_id_list)
                                if parent_rule_id_list != []:
                                    del parent_rule_id_list[p_id_list_len - 1]
        
                            #if case_regexx!=None and case_para == paravalue:
                                #print('2',line)
                                #p_id_list_len = len(parent_rule_id_list)
                                #if parent_rule_id_list != []:
                                #    del parent_rule_id_list[p_id_list_len - 1]
                                #parent_rule_id_list.append(rule_id)
                            #if endsr_regexx!=[] and endsr_counter==1:
                            #    print('3',line)
                            #    p_id_list_len = len(parent_rule_id_list)
                            #    if parent_rule_id_list != []:
                            #        del parent_rule_id_list[p_id_list_len - 1]
                        """
                        if endcs_regexx != None and case_flag == True and case_para.strip() == paravalue.strip():
                            case_counter = 0
                            case_flag = False
                            p_id_list_len = len(parent_rule_id_list)
                            if parent_rule_id_list != []:
                                del parent_rule_id_list[p_id_list_len - 1]

                        if (tag_value == "RC1"):
                            Db_update_counter = Db_update_counter + 1
                            line = ' '.join(line.split())
                            p_id_value = ""
                            loopNumber = 0
                            paravaluesplit = paravalue.split()
                            for data in range(len(parent_rule_id_list)):
                                if p_id_value == "":

                                    p_id_value = p_id_value + parent_rule_id_list[data]
                                else:
                                    p_id_value = p_id_value + ',' + parent_rule_id_list[data]

                            METADATA.append({'s_no': '', 'pgm_name': programName,
                                             'fragment_Id': rule_id,
                                             'para_name': paravalue, 'source_statements': line,
                                             'statement_group': statement_value, 'rule_category': catg_value,
                                             'parent_rule_id': p_id_value, 'business_documentation': ''})

                            RC1 = RC1 + 1
                            break
                        elif (tag_value == "RC2"):
                            Db_update_counter = Db_update_counter + 1
                            line = ' '.join(line.split())
                            p_id_value = ""
                            loopNumber = 0
                            paravaluesplit = paravalue.split()
                            for data in range(len(parent_rule_id_list)):
                                if p_id_value == "":

                                    p_id_value = p_id_value + parent_rule_id_list[data]
                                else:
                                    p_id_value = p_id_value + ',' + parent_rule_id_list[data]

                            METADATA.append({'s_no': '', 'pgm_name': programName,
                                             'fragment_Id': rule_id,
                                             'para_name': paravalue, 'source_statements': line,
                                             'statement_group': statement_value, 'rule_category': catg_value,
                                             'parent_rule_id': p_id_value, 'business_documentation': ''})

                            RC2 = RC2 + 1
                            break
                        elif (tag_value == "RC3"):
                            Db_update_counter = Db_update_counter + 1
                            ifregexx = re.match('.*\sif\s.*', line.lower(), re.IGNORECASE)
                            line = ' '.join(line.split())
                            p_id_value = ""
                            loopNumber = 0
                            paravaluesplit = paravalue.split()

                            for data in range(len(parent_rule_id_list)):
                                if p_id_value == "":

                                    p_id_value = p_id_value + parent_rule_id_list[data]
                                else:
                                    p_id_value = p_id_value + ',' + parent_rule_id_list[data]

                            """
                            if ifregexx!=None:
                                print(line)
                                newid=parent_rule_id_list
                                length=len(newid)
                                p_id_value=""
                                print(parent_rule_id_list)
                                if newid!=[]:
                                    del newid[length - 1]
                                for data in range(len(newid)):
                                   if p_id_value == "":
                                       p_id_value = p_id_value + newid[data]
                                   else:
                                       p_id_value = p_id_value + ',' + newid[data]
                                print("zf",newid)
                            """
                            METADATA.append({'s_no': '', 'pgm_name': programName,
                                             'fragment_Id': rule_id,
                                             'para_name': paravalue, 'source_statements': line,
                                             'statement_group': statement_value, 'rule_category': catg_value,
                                             'parent_rule_id': p_id_value, 'business_documentation': ''})

                            RC3 = RC3 + 1
                            break
                        elif (tag_value == "RC4"):
                            Db_update_counter = Db_update_counter + 1
                            line = ' '.join(line.split())
                            p_id_value = ""
                            loopNumber = 0
                            paravaluesplit = paravalue.split()
                            for data in range(len(parent_rule_id_list)):
                                if p_id_value == "":

                                    p_id_value = p_id_value + parent_rule_id_list[data]
                                else:
                                    p_id_value = p_id_value + ',' + parent_rule_id_list[data]

                            METADATA.append({'s_no': '', 'pgm_name': programName,
                                             'fragment_Id': rule_id,
                                             'para_name': paravalue, 'source_statements': line,
                                             'statement_group': statement_value, 'rule_category': catg_value,
                                             'parent_rule_id': p_id_value, 'business_documentation': ''})

                            RC4 = RC4 + 1
                            break
                        elif (tag_value == "RC5"):
                            Db_update_counter = Db_update_counter + 1
                            line = ' '.join(line.split())
                            p_id_value = ""
                            loopNumber = 0
                            paravaluesplit = paravalue.split()
                            for data in range(len(parent_rule_id_list)):
                                if p_id_value == "":

                                    p_id_value = p_id_value + parent_rule_id_list[data]
                                else:
                                    p_id_value = p_id_value + ',' + parent_rule_id_list[data]

                            METADATA.append({'s_no': '', 'pgm_name': programName,
                                             'fragment_Id': rule_id,
                                             'para_name': paravalue, 'source_statements': line,
                                             'statement_group': statement_value, 'rule_category': catg_value,
                                             'parent_rule_id': p_id_value, 'business_documentation': ''})

                            RC5 = RC5 + 1
                            break
                        elif (tag_value == "RC6"):
                            Db_update_counter = Db_update_counter + 1
                            line = ' '.join(line.split())
                            if line.startswith("@") and line.__contains__("exsr") or line.__contains__("case"):
                                line = re.sub("@ ", " ", line)
                            p_id_value = ""
                            loopNumber = 0
                            paravaluesplit = paravalue.split()
                            for data in range(len(parent_rule_id_list)):
                                if p_id_value == "":

                                    p_id_value = p_id_value + parent_rule_id_list[data]
                                else:
                                    p_id_value = p_id_value + ',' + parent_rule_id_list[data]

                            METADATA.append({'s_no': '', 'pgm_name': programName,
                                             'fragment_Id': rule_id,
                                             'para_name': paravalue, 'source_statements': line,
                                             'statement_group': statement_value, 'rule_category': catg_value,
                                             'parent_rule_id': p_id_value, 'business_documentation': ''})

                            RC6 = RC6 + 1

                            if endregexx != None or endif1regexx != None:
                                endifcounter = endifcounter + 1
                                p_id_list_len = len(parent_rule_id_list)
                                if parent_rule_id_list != []:
                                    del parent_rule_id_list[p_id_list_len - 1]
                                ifcounter = ifcounter - 1

                            break
                        elif (tag_value == "RC7"):
                            Db_update_counter = Db_update_counter + 1
                            line = ' '.join(line.split())
                            p_id_value = ""
                            loopNumber = 0
                            paravaluesplit = paravalue.split()
                            for data in range(len(parent_rule_id_list)):
                                if p_id_value == "":

                                    p_id_value = p_id_value + parent_rule_id_list[data]
                                else:
                                    p_id_value = p_id_value + ',' + parent_rule_id_list[data]

                            METADATA.append({'s_no': '', 'pgm_name': programName,
                                             'fragment_Id': rule_id,
                                             'para_name': paravalue, 'source_statements': line,
                                             'statement_group': statement_value, 'rule_category': catg_value,
                                             'parent_rule_id': p_id_value, 'business_documentation': ''})

                            RC7 = RC7 + 1
                            break
                        elif (tag_value == "RC8"):
                            Db_update_counter = Db_update_counter + 1
                            line = ' '.join(line.split())
                            p_id_value = ""
                            loopNumber = 0
                            paravaluesplit = paravalue.split()
                            for data in range(len(parent_rule_id_list)):
                                if p_id_value == "":

                                    p_id_value = p_id_value + parent_rule_id_list[data]
                                else:
                                    p_id_value = p_id_value + ',' + parent_rule_id_list[data]

                            METADATA.append({'s_no': '', 'pgm_name': programName,
                                             'fragment_Id': rule_id,
                                             'para_name': paravalue, 'source_statements': line,
                                             'statement_group': statement_value, 'rule_category': catg_value,
                                             'parent_rule_id': p_id_value, 'business_documentation': ''})

                            RC8 = RC8 + 1
                            break

        os.remove("output1" + str(i) + '.txt')
        os.remove("output" + str(i) + '.txt')
        os.remove("output2" + str(i) + '.txt')

        if Db_update_counter <= 100000000000000:
            Db_Insert(METADATA)
            METADATA.clear()
            Db_update_counter = 0

        os.remove("Copy_Expanded_Data" + str(i) + ".txt")
        os.remove("Duplicatefile0" + str(i) + ".txt")
        os.remove("Duplicatefile" + str(i) + ".txt")
        times = 16

        for num in range(times):
            os.remove("FinalFile" + str(num) + str(i) + '.txt')

        # m=json.loads(METADATA)


def Id_Division(filename):
    filename = filename.split('\\')
    filelength = len(filename)
    Temp_ID = filename[filelength - 1]
    print(Temp_ID[:-3])
    PGM_ID.append(Temp_ID[:-3])


def Db_Insert(METADATA):
    UpdateCounter = 0
    UpdateCounter = UpdateCounter + 1
    db_data = {"data": METADATA,
               "headers": ['s_no', 'pgm_name', 'fragment_Id', 'para_name', 'source_statements', 'statement_group',
                           'rule_category', 'parent_rule_id', 'business_documentation']}

    try:
        keys = list(db_data.keys())
        print('parent keys', keys)

        if 'data' in keys:
            # fetching headers
            x_BRE_report_header_list = db_data['headers']
            print('COBOL Report header list', x_BRE_report_header_list)
            # Adding header field to db_data
            db_data['headers'] = x_BRE_report_header_list

            if len(db_data['data']) == 0:
                print({"status": "failure", "reason": "data field is empty"})
            else:
                # Delete all COBOl associated records in the table
                previousDeleted = False
                try:
                    if UpdateCounter == 1000000000000:
                        if db.bre_rules_report.delete_many(
                                {"type": {"$ne": "metadata"}}).acknowledged:
                            print('Deleted all the COBOL components from the x-reference report')
                            previousDeleted = True
                            print('--------just deleted all de cobols')
                        else:
                            print('Something went wrong')
                            print({"status": "failed",
                                   "reason": "unable to delete from database. Please check in with your Administrator"})
                            print('--------did not deleted all de cobols')
                except Exception as e:
                    print({"status": "failed", "reason": str(e)})

                # Update the database with the content from HTTP request body

                if previousDeleted or UpdateCounter == 1:

                    try:

                        db.bre_rules_report.insert_many(db_data['data'])
                        print('db inserteed bro')
                        # updating the timestamp based on which report is called
                        current_time = datetime.datetime.now(tz=tz).strftime("%A, %d. %B %Y %I:%M%p")
                        # Setting the time so that we know when each of the JCL and COBOLs were run

                        # db.cross_reference_report.insert_one({"type":"metadata", "JCL":{"last_updated_on":ct},"COBOL":{"last_updated_on":ct}})

                        if db.bre_rules_report_pytest.count_documents({"type": "metadata"}) > 0:
                            print('meta happen o naw',
                                  db.bre_rules_report.update_one({"type": "metadata"},
                                                                        {"$set": {
                                                                            "BRE.last_updated_on": current_time,
                                                                            "BRE.time_zone": time_zone,
                                                                            "headers": x_BRE_report_header_list
                                                                        }},
                                                                        upsert=True).acknowledged)
                        else:
                            db.bre_rules_report_pytest.insert_one(
                                {"type": "metadata",
                                 "COBOL": {"last_updated_on": current_time, "time_zone": time_zone},
                                 "headers": x_BRE_report_header_list})

                        print(current_time)
                        print({"status": "success", "reason": "Successfully inserted data and "})
                    except Exception as e:
                        print('Error' + str(e))
                        print({"status": "failed", "reason": str(e)})

    except Exception as e:
        print('Error: ' + str(e))
        print({"status": "failure", "reason": "Response json not in the required format"})


main()

