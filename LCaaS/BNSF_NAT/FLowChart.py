SCRIPT_VERSION = 'Updated flowchart of Natural on 05/12/2019'
# Handled  if statements with single true statement
# Multiple continuous if lines are handled(OR and AND)

from pymongo import MongoClient

import glob, copy, os, re
import json
import requests
import pandas as pd
from pandas import ExcelWriter
import linecache
from collections import OrderedDict
import ast
import config
import pytz
import datetime

sp_list = ""
case = "caseq"
begin ="DEFINE"
search_element=["begsr","exsr","caseq"]
end = "END-SUBROUTINE"
call_sub = "exsr"
begin_sr = []     #list of All begin subroutines
execute_sr = []   # list of all execute subroutines
lines=[]
to = []
From=" "
fun_repositary=OrderedDict()
child_fun = []
master_alive = set()
Dead_keys= set()
main_excsr = []
METADATA=OrderedDict()
count_of_dead_lines=[0]
dead_para_count=[]
dead_para_list=[]
dead_para_list1=" "
total_para_count=[]
tempfilename=''
dead_Metadata=OrderedDict()
output = {}
row = OrderedDict()

time_zone = 'Asia/Calcutta'
tz = pytz.timezone(time_zone)


CopyPath = config.CopyPath
file = config.file

client = MongoClient('localhost', 27017)
db = client['BNSF_NAT_SSI']


# client = MongoClient(config1.database['mongo_endpoint_url'])
# db = client[config1.database['database_name']]

def read_lines():

    dict = OrderedDict()
    dict_dead = OrderedDict()
    flag = False
    data = []
    file_handle = open("copyexpanded.txt", "r")
    fun_name = ''
    count = 0
    define_counter = 0
    storage = []
    begin_counter = 0
    for line in file_handle:
        #print("Copy_expanded lines:",line)
        try:
            #if len(line) > 8:

                line = line[:72]
                #print("Copy_expanded lines:", line)
                if line[0] == '*':
                    #print("Commented_lines:",line)
                    continue
                if line.strip().startswith('/*'):
                    continue


                else:

                    # print("Copy_expanded lines:", line)
                    # if (re.search(end, line) or re.search("DEFINE.*",line) or re.search("RETURN", line) or re.search("DEFINE SUBROUTINE.*",line.strip()) or re.search("END",line)) :
                    #     # counting lines
                    #     if (re.search("DEFINE SUBROUTINE.*",line.strip()) )or re.search('.*END TRANSACTION.*',line) or re.search(".*DEFINE WINDOW.*",line) or re.search(".*END-SELECT.*",line) or re.search(".*END-.*",line) or re.search(".*END-DEFINE.*",line) or re.search(".*INDEPENDENT.*",line)\
                    #        or re.search('.*#APPROVE-PEND.*',line)  or re.search('CCEND',line) or re.search("RETURN-",line) or re.search("DEFINE DATA",line) or re.search("REDEFINE",line) or re.search("#PENDING-FOUND",line)\
                    #             or re.search('#UPDATES-PENDING',line) or re.search('#PENDING',line) or re.search('SEND-MQ',line  or re.search('OQ-TPEND_YBLK_DESC VIEW OF OQ-TPEND_YBLK_DESC',line) \
                    #                                                                                              ):
                    if re.search("DEFINE SUBROUTINE.*",line.lstrip()) or re.search("DEFINE.*",line.lstrip()) or re.search("END\Z",line.rstrip()):
                        if re.search('REDEFINE',line) or re.search('#APPROVE-PEND',line) or re.search('DEFINE WINDOW',line) or re.search('DEFINE DATA',line) or re.search('END-DEFINE',line):

                                pass
                        # if define_counter == 1:
                        #     continue

                        # print('end number', index)
                        #print(dict)
                        else:
                            print("DEFINE:", line)
                            storage.append(line)

                            if fun_name == "":
                                dict["Main"] = copy.deepcopy(storage)
                            else:

                                dict[fun_name] = copy.deepcopy(storage)


                            storage.clear()
                            define_counter = define_counter + 1
                            fun_name = " "
                            dict_dead[fun_name] = count
                            count = 2

                            flag = False
                            #  print(line + '------------------------------------------')
                    if flag:
                        count = count + 1
                        storage.append(line.rstrip())

                    if (re.search(begin, line.strip()) ):

                        if re.search("DEFINE DATA",line) or re.search("REDEFINE",line) or re.search("DEFINE WINDOW",line) :
                            continue
                        #print(line)
                        else:
                            # if re.search(".*END-DEFINE*",line):
                            #     flag = True
                            #     continue
                            # else:

                                flag = True
                                if line.__contains__("/*"):
                                    line = line.split("/*")[0]
                                new_line1 = line.split()
                                temp_fun_name = new_line1[-1]
                                if new_line1[-2].__contains__("/*"):
                                    fun_name = new_line1[-3]

                                else:
                                    fun_name = temp_fun_name


        except Exception:
            # print(line)
            pass
    print("Correct:", json.dumps(dict, indent=4))
    return dict



write_variable = ""

keywords_for_if_delimiter = ['*','INPUT','SET','IGNORE','DECIDE','SELECT','CALLNAT','#STAT-CD','ACCEPT','#BLK-RUL-TYPE1','ASSIGN','STOP', 'COMPRESS', 'REINPUT', 'RETURN', 'STOP RUN', 'END-PERFORM', 'CALL', 'MOVE', 'COMPUTE', 'PERFORM',
                                 'ELSE','FACTORY', 'SET KEY', 'IF', 'EXEC','##MSG', 'ADD', 'WHEN', 'GO', 'NEXT', 'READ', 'DISPLAY',
                                 'CONTINUE','*PF-KEY', 'WRITE','FIND','READ','DO','#COLOUR-EDIT','ESCAPE BOTTOM','FETCH','ESCAPE ROUTINE','UPDATE','REPEAT','ESCAPE TOP','#TOKMOD-EDIT','BACKOUT TRANSACTION',]

if_condition_collector_flag =  False

collected_if_condition_variable = ""

single_line_flag = False
single_line_variable = ''

endswith_flag = False

startswith_flag = False

# First level IFs true part tally logic helpers
truepart_ifs_tallied = True
truepart_if_opened_count = 0
truepart_if_closed_count = 0

# First level IFs false part tally logic helpers
falsepart_ifs_tallied = True
falsepart_if_opened_count = 0
falsepart_if_closed_count = 0

true_part_flag = ''
true_part_variable = ''

false_part_variable = ''
false_part_flag = ''

find_variable = ''
find_flag =  False

move_variable = ""

read_flag = False
read_variable = ""

norecord_flag = False
norecord_variable = ""

repeatuntil_flag = False
repeatuntil_variable = ""

decide_flag = False
decide_variable = ""

endrepeat_variable = ''
value_variable = ''

return_variable = ''

input_variable = ''

endfor_variable = ''

reinput_variable = ''

perform_variable = ''

endfind_variable = ''

endread_variable = ''

set_variable = ''

callnat_variable = ''

obtain_variable = ''

find_statement = ''

loop_variable = ''

for_variable = ''

decide_for_variable = ''
decide_for_flag = False

when_variable = ''
when_flag = False

total_if_counter = 0
total_individual_block_counter = 0
total_group_block_counter = 0

# GROUP BLOCK
group_block_flag = False
group_block_variable = ''

# Node definitions
node_definitions = ''
# Collects the sequence of node
node_sequence = []
# Collects actual code of nodes
node_code = {}
OUTPUT_DATA = []

## Nested_part
nested_if_flag = False
nested_else_if_flag = False
# nested_true_part_flag = False
nested_false_part_flag = False
value_flag = False
nested_false_part_variable = ''
nested_true_part_variable = ''

for file_location, file_type in file.items():
    print("File_location:",file_location,file_type)
    for filename in glob.glob(os.path.join(file_location,file_type)):
        print("File:",filename)
        ModuleName = filename
        print(ModuleName)
        f = open(ModuleName, "r")
        i = 1
        for line in f.readlines():
            try:

                if line.strip() == '' or line[5:].strip() == '' or line[8] == '*' :
                    #print("asf",line)
                    continue

                else:
                    line = line[4:]
                    # print("Passed_lines:",line)
                    copyfile = open("copyexpanded.txt", "a")

                if re.search("INCLUDE.*", line):

                    sp_list = line.split()

                    copyname = sp_list[1]

                    copyname = copyname + '.cpy'

                    Copyfilepath = CopyPath + '\\' + copyname

                    if os.path.isfile(Copyfilepath):
                        tempcopyfile = open(os.path.join(CopyPath, copyname), "r")
                        copyfile.write("#########" + " " + "BEGIN" + " " + line + '\n')
                        for copylines in tempcopyfile.readlines():
                            copyfile.write(copylines)
                            copyfile.write('\n')
                        copyfile.write("#####" + " " + "COPY END" + "####" + '\n')

                copyfile.write(line)

                copyfile.close()

            except Exception:

              pass



        dict = read_lines()
        # print("Check:", json.dumps(dict, indent=4))
        list_of_functions = list(dict.keys())
        # print("list of functions:",list_of_functions)
        # print("Main:",json.dumps(dict,indent=4))
        for function in list_of_functions:
            print("Function:",function)
            main_if_dict = {}
            check_if_counter = 0
            end_tag_list = []
            ## Nested true part if's
            innerlevel_mainif_list = []
            innerif_nested_dict = {}
            innerif_check_list = []
            innerif_elsecheck_list = []
            innerif_end_tag_list = []
            complicated_endif_list = []
            check_helpful_list = []
            endif_complicated_list = []
            main_endif_counter = 0
            next_if_word_index = 0
            nested_true_part_flag = False
            nested_false_part_flag = False
            true_if_counter = 0
            ## links-string
            check_innerif_end_tag_list = []

            ## Nested false part if's
            innerlevel_mainelse_list = []


            for index,line in enumerate(dict[function]):
                #print("Lines:", line)
                discovered_node = ''




                if if_condition_collector_flag:
                    if any(ext in line for ext in keywords_for_if_delimiter) or line.lstrip()[0] == '#':
                        if line.rstrip().endswith("OR") or line.rstrip().endswith("AND") or line.lstrip().startswith("AND") or line.lstrip().startswith("OR"):
                            if_condition_variable = if_condition_variable + '\n' + line
                            continue
                        else:
                            discovered_node = 'C' + str(
                                total_if_counter) + ' =>condition:' + if_condition_variable + ' | approved\n'

                            if re.search('.*IF .*', line):
                                node_sequence.append('C' + str(total_if_counter))
                                if check_if_counter == 1:
                                    end_tag_list.clear()
                                end_tag_list.append('C' + str(total_if_counter))
                                node_code['C' + str(total_if_counter)] = if_condition_variable
                                print("Success")
                                node_sequence.append('T' + str(total_if_counter))
                                node_code['T' + str(total_if_counter)] = ''
                                node_sequence.append('F' + str(total_if_counter))
                                node_code['F' + str(total_if_counter)] = ''
                                next_if_word = dict[function][index + 1]
                                if re.search('.*IF.*', next_if_word,re.IGNORECASE):

                                    if_condition_collector_flag = False
                                else:
                                    if_condition_collector_flag = False
                                    # immediate_if_counter = immediate_if_counter + 1
                                    if_nested_collection_line = line
                                    nested_if_flag = True

                                    continue


                            else:

                                node_sequence.append('C' + str(total_if_counter))
                                if check_if_counter == 1:
                                    end_tag_list.clear()
                                end_tag_list.append('C' + str(total_if_counter))
                                node_code['C' + str(total_if_counter)] = if_condition_variable
                                if_condition_collector_flag = False
                                if_condition_variable = ''
                                true_part_flag = True

                                true_part_variable = ''

                    else:
                        if_condition_variable = if_condition_variable + '\n' + line
                        continue

                if nested_if_flag:

                    if re.match('.*if *', if_nested_collection_line, re.IGNORECASE):
                        try:
                            inner_if_index = if_nested_collection_line.index("IF")
                        except ValueError as v:
                            print("Error:",if_nested_collection_line,v)
                        total_if_counter = total_if_counter + 1
                        innerif_nested_dict[total_if_counter] = inner_if_index
                        if_nested_condition_variable = if_nested_collection_line

                    if any(ext in line for ext in keywords_for_if_delimiter):
                        discovered_node = 'C' + str(
                            total_if_counter) + ' =>condition:' + if_nested_condition_variable + ' | approved\n'
                        node_sequence.append('C' + str(total_if_counter))
                        innerlevel_mainif_list.append('C' + str(total_if_counter))
                        node_code['C' + str(total_if_counter)] = if_nested_condition_variable

                        nested_if_flag = False
                        nested_true_part_flag = True

                        nested_true_part_variable = ''

                    else:
                        if_nested_condition_variable = if_nested_condition_variable + '\n' + line
                        if_nested_collection_line = ''
                        continue


                if nested_else_if_flag:

                    if re.match('.*if *', if_nested_collection_line, re.IGNORECASE):
                        inner_if_index = if_nested_collection_line.index("IF")
                        total_if_counter = total_if_counter + 1
                        innerif_nested_dict[total_if_counter] = inner_if_index
                        if_nested_condition_variable = if_nested_collection_line

                    if any(ext in line for ext in keywords_for_if_delimiter):
                        discovered_node = 'C' + str(
                            total_if_counter) + ' =>condition:' + if_nested_condition_variable + ' | approved\n'
                        node_sequence.append('C' + str(total_if_counter))
                        innerlevel_mainelse_list.append('C' + str(total_if_counter))
                        node_code['C' + str(total_if_counter)] = if_nested_condition_variable

                        nested_else_if_flag = False
                        nested_true_part_flag = True

                        nested_true_part_variable = ''

                    else:
                        if_nested_condition_variable = if_nested_condition_variable + '\n' + line
                        if_nested_collection_line = ''
                        continue

                if nested_true_part_flag:
                    if_nested_collection_line = ""
                    if re.match('.* if *', line,re.IGNORECASE):
                        if not (re.match('.*END-IF.*', line, re.IGNORECASE) or re.match('.*IF NOT .*', line,
                                                                                        re.IGNORECASE) or re.match(
                                '.*IF NO RECORD FOUND.*', line, re.IGNORECASE) or re.match('.*differenc.*',line) or re.match('.*displayed if.*',line,re.IGNORECASE) or re.match('.*what if.*',line) or re.match('.*IF NO RECORDS FOUND.*',
                                                                                           line, re.IGNORECASE)):
                            node_sequence.append('T' + str(total_if_counter))
                            node_code['T' + str(total_if_counter)] = nested_true_part_variable + '\n'
                            node_sequence.append('F' + str(total_if_counter))
                            node_code['F' + str(total_if_counter)] = ''
                            if_nested_collection_line = line
                            nested_true_part_flag = False
                            nested_if_flag = True
                            continue

                    if re.match('.*ELSE.*',line,re.IGNORECASE):
                        innerif_else_index = line.index("ELSE")
                        for innerif_key,innerif_value in innerif_nested_dict.items():
                            if innerif_value == innerif_else_index:
                                if innerif_key in innerif_elsecheck_list:
                                    continue
                                true_if_counter = innerif_key
                                innerif_elsecheck_list.append(true_if_counter)
                                node_sequence.append('T' + str(true_if_counter))
                                node_code['T' + str(true_if_counter)] = nested_true_part_variable + '\n'
                                nested_true_part_flag = False
                                nested_true_part_variable = ''
                                nested_false_part_variable = ''
                                nested_false_part_flag = True
                        continue

                    if re.match('.*end-if.*', line, re.IGNORECASE):
                        inner_endif_index = line.index("END-IF")
                        for innerif_key,innerif_value in innerif_nested_dict.items():
                            if innerif_value == inner_endif_index:
                                if innerif_key in innerif_check_list:
                                    continue
                                true_if_counter = innerif_key
                                innerif_check_list.append(true_if_counter)
                                node_sequence.append('T' + str(true_if_counter))
                                node_code['T' + str(true_if_counter)] = nested_true_part_variable + '\n'
                                node_sequence.append('F' + str(true_if_counter))
                                node_code['F' + str(true_if_counter)] = ''
                                nested_true_part_flag = False
                                nested_true_part_variable = ''
                        continue

                    if re.match('.*DOEND.*',line):
                        doend_index = line.index("DOEND")
                        if doend_index == main_if_index:
                            node_sequence.append('T' + str(true_if_counter))
                            node_code['T' + str(true_if_counter)] = nested_true_part_variable + '\n'
                            node_sequence.append('F' + str(true_if_counter))
                            node_code['F' + str(true_if_counter)] = ''
                            nested_true_part_flag = False
                            nested_true_part_variable = ''
                            continue


                    else:
                        nested_true_part_variable = nested_true_part_variable + '\n' + line
                        continue


                if nested_false_part_flag:
                    if_nested_collection_line = ""
                    if re.match('.*IF *', line, re.IGNORECASE):
                        if not (re.match('.*END-IF.*', line, re.IGNORECASE) or re.match('.*difference.*',line,re.IGNORECASE) or re.match('.*IF NOT .*', line,
                                                                                        re.IGNORECASE) or re.match(
                                '.*IF NO RECORD FOUND.*', line, re.IGNORECASE) or re.match('.*IF NO RECORDS FOUND.*',
                                                                                           line, re.IGNORECASE)):
                            if true_if_counter != '' :
                                node_sequence.append('F' + str(true_if_counter))
                                node_code['F' + str(true_if_counter)] = nested_false_part_variable + '\n'
                                if_nested_collection_line = line
                                nested_false_part_flag = False
                                nested_if_flag = True
                                continue

                    if re.match('.*DOEND.*',line):
                        doend_index = line.index("DOEND")
                        if doend_index == main_if_index:
                            # node_sequence.append('T' + str(true_if_counter))
                            # node_code['T' + str(true_if_counter)] =
                            node_sequence.append('F' + str(true_if_counter))
                            node_code['F' + str(true_if_counter)] = nested_false_part_variable + '\n'
                            nested_false_part_flag = False
                            nested_false_part_variable = ''
                            continue

                    if re.match('.*END-IF.*',line):
                        endif_index = line.index("END-IF")
                        if endif_index == inner_if_index:
                            node_sequence.append('F' + str(true_if_counter))
                            node_code['F' + str(true_if_counter)] = nested_false_part_variable + '\n'
                            nested_false_part_flag = False
                            nested_false_part_variable = ''
                            continue

                    else:
                        nested_false_part_variable = nested_false_part_variable + '\n' + line
                        continue

                if true_part_flag:
                    if re.match('.*if *', line, re.IGNORECASE):
                            if not (re.match('.*END-IF.*',line,re.IGNORECASE) or re.match('.*WhtIf.*',line) or re.match('.*what if.*',line,re.IGNORECASE) or re.match('.*notification.*',line) or re.match('.*IF NOT .*',line,re.IGNORECASE) or  re.match('.*IF NO RECORD FOUND.*', line, re.IGNORECASE) or re.match('.*IF NO RECORDS FOUND.*',line,re.IGNORECASE)):
                                node_sequence.append('T' + str(total_if_counter))
                                node_code['T' + str(total_if_counter)] = true_part_variable + '\n'
                                node_sequence.append('F' + str(total_if_counter))
                                node_code['F' + str(total_if_counter)] = ''
                                if_nested_collection_line = line
                                true_part_flag = False
                                true_part_variable = ''
                                nested_if_flag = True
                                continue

                    if re.match('.*ELSE.*',line,re.IGNORECASE):

                        main_else_index = line.index("ELSE")
                        if main_if_index == main_else_index:
                            node_sequence.append('T' + str(total_if_counter))
                            node_code['T' + str(total_if_counter)] = true_part_variable + '\n'
                            true_part_flag = False
                            true_part_variable = ''
                            false_part_flag = True
                            false_part_variable = ''
                            continue

                    if re.match('.*END-IF.*',line,re.IGNORECASE) or re.match('.*DOEND.*',line,re.IGNORECASE):
                        if line.__contains__("END-IF"):
                            main_endif_index = line.index("END-IF")
                            if main_if_index == main_endif_index:
                                node_sequence.append('T' + str(total_if_counter))
                                node_code['T' + str(total_if_counter)] = true_part_variable + '\n'
                                node_sequence.append('F' + str(total_if_counter))
                                node_code['F' + str(total_if_counter)] = ''
                                true_part_flag = False
                                true_part_variable = ''
                                continue
                        else:
                            next_line_word = dict[function][index + 1]
                            if next_line_word.__contains__("ELSE"):
                                true_part_variable = true_part_variable + '\n' + line
                                continue
                            main_enddo_index = line.index("DOEND")

                            if main_if_index == main_enddo_index:
                                node_sequence.append('T' + str(total_if_counter))
                                node_code['T' + str(total_if_counter)] = true_part_variable + '\n' + line
                                node_sequence.append('F' + str(total_if_counter))
                                node_code['F' + str(total_if_counter)] = ''
                                true_part_flag = False
                                true_part_variable = ''
                                continue

                    else:
                        true_part_variable = true_part_variable + '\n' + line
                        try:
                            next_if_word = dict[function][index + 1]
                            if re.search('.*IF.*',next_if_word):
                                if not re.search('.*END-IF.*',next_if_word):
                                    next_if_word_index = next_if_word.index("IF")
                                    if next_if_word_index == main_if_index:
                                        node_sequence.append('T' + str(total_if_counter))
                                        node_code['T' + str(total_if_counter)] = true_part_variable
                                        node_sequence.append('F' + str(total_if_counter))
                                        node_code['F' + str(total_if_counter)] = ''
                                        true_part_flag = False
                                        true_part_variable = ''
                                        continue

                            continue

                        except Exception as e:
                            print(e)


                if false_part_flag:
                    if re.match('.* if *', line, re.IGNORECASE):
                        if not (re.match('.*END-IF.*', line, re.IGNORECASE) or re.match('.*IF NOT .*',line,re.IGNORECASE) or  re.match('.*IF NO RECORD FOUND.*', line, re.IGNORECASE) or re.match('.*IF NO RECORDS FOUND.*',line,re.IGNORECASE)):
                            print("false_part_success")

                            node_sequence.append('F' + str(total_if_counter))
                            node_code['F' + str(total_if_counter)] = false_part_variable + '\n'
                            if_nested_collection_line = line
                            false_part_flag = False
                            false_part_variable = ''
                            nested_else_if_flag = True
                            continue

                    if re.match('.*END-IF.*',line,re.IGNORECASE):
                        main_endif_index = line.index("END-IF")
                        if main_if_index == main_endif_index:

                            node_sequence.append('F' + str(total_if_counter))
                            node_code['F' + str(total_if_counter)] = false_part_variable + '\n'
                            false_part_flag = False
                            false_part_variable = ''
                            continue

                    else:
                        false_part_variable = false_part_variable + '\n' + line
                        continue


                # if if_condition_collector_flag:
                #     if any(ext in line for ext in keywords_for_if_delimiter):
                #         discovered_node = 'C' + str(
                #             total_if_counter) + ' =>condition:' + if_condition_variable + ' | approved\n'
                #         node_sequence.append('C' + str(total_if_counter))
                #         node_code['C' + str(total_if_counter)] = if_condition_variable
                #         if_condition_collector_flag = False
                #         if_condition_variable = ''
                #         next_if_line = dict[function][index + 1]
                #         first_if_index = next_if_line.find("IF")
                #         if first_if_index == if_index:
                #             true_part_variable = true_part_variable + '\n' + line
                #             node_sequence.append('T' + str(total_if_counter))
                #             node_code['T' + str(total_if_counter)] = true_part_variable + '\n'
                #             node_sequence.append('F' + str(total_if_counter))
                #             node_code['F' + str(total_if_counter)] = ''
                #             true_part_variable = ''
                #             continue
                #         else:
                #             true_part_flag = True
                #             true_part_variable = ''
                #
                #         # except Exception as e:
                #         #     print(e)
                #         #single_line_flag = True
                #         # true_part_flag = True
                #         # true_part_variable = ''
                #     elif line[0] != " ":
                #         discovered_node = 'C' + str(
                #             total_if_counter) + ' =>condition:' + if_condition_variable + ' | approved\n'
                #         node_sequence.append('C' + str(total_if_counter))
                #         node_code['C' + str(total_if_counter)] = if_condition_variable
                #         if_condition_collector_flag = False
                #         if_condition_variable = ''
                #         next_if_line = dict[function][index + 1]
                #         first_if_index = next_if_line.find("IF")
                #         if first_if_index == if_index:
                #             true_part_variable = true_part_variable + '\n' + line
                #             node_sequence.append('T' + str(total_if_counter))
                #             node_code['T' + str(total_if_counter)] = true_part_variable + '\n'
                #             node_sequence.append('F' + str(total_if_counter))
                #             node_code['F' + str(total_if_counter)] = ''
                #             true_part_variable = ''
                #             continue
                #         else:
                #             true_part_flag = True
                #             true_part_variable = ''
                #
                #
                #
                #     else:
                #         if line.endswith('OR') or line.endswith('AND'):
                #             if_condition_variable = if_condition_variable + '\n' + line
                #             continue
                #         else:
                #             collected_if_condition_variable = if_condition_variable + '\n' + line
                #             discovered_node = 'C' + str(
                #                 total_if_counter) + ' =>condition:' + collected_if_condition_variable + ' | approved\n'
                #             node_sequence.append('C' + str(total_if_counter))
                #             node_code['C' + str(total_if_counter)] = collected_if_condition_variable
                #             # print(if_condition_variable)
                #             if_condition_collector_flag = False
                #             if_condition_variable = ''
                #
                #             sec_next_if_line = dict[function][index + 2]
                #
                #             sec_if_index = sec_next_if_line.find("IF")
                #
                #
                #             if sec_if_index == if_index:
                #                 single_line_flag = True
                #                 continue
                #
                #             else:
                #                 true_part_flag = True
                #                 true_part_variable = ''
                #                 continue
                #
                #
                #
                # if single_line_flag:
                #     true_part_variable = true_part_variable + '\n' + line
                #     node_sequence.append('T' + str(total_if_counter))
                #     node_code['T' + str(total_if_counter)] = true_part_variable + '\n'
                #     node_sequence.append('F' + str(total_if_counter))
                #     node_code['F' + str(total_if_counter)] = ''
                #     true_part_variable = ''
                #     single_line_flag = False
                #     continue
                #
                #
                #
                # if true_part_flag:
                #     # next_if_line = dict[function][index + 1]
                #     # if next_if_line.startswith('IF'):
                #     #     total_individual_block_counter = total_individual_block_counter + 1
                #     #     single_line_variable = line + '\n'
                #     #     node_sequence.append('S' + str(total_individual_block_counter))
                #     #     node_code['S' + str(total_individual_block_counter)] = single_line_variable
                #     #     single_line_flag = False
                #     #     true_part_flag = False
                #     #     single_line_variable = ''
                #     #     continue
                #
                #     # if re.match('IF\s+.*', line, re.IGNORECASE) :
                #     #     if not re.match('IF NO RECORD  FOUND',line,re.IGNORECASE):
                #     #         # make sure if execution knows that IFs are no longer tallied
                #     #         # true_part_variable = ''
                #     #
                #     #         if_index = line.index('IF')
                #     #         #print("Index:",if_index)
                #     #         truepart_ifs_tallied = False
                #     #         # Increment the count of opened if statements
                #     #         truepart_if_opened_count += 1
                #     #         true_part_variable = true_part_variable + '\n' + line
                #     #         continue
                #
                #     # if (not truepart_ifs_tallied) and (re.match('.*END-IF', line, re.IGNORECASE) or re.match('.*DOEND',line,re.IGNORECASE)):
                #     #     truepart_if_closed_count += 1
                #     #     true_part_variable = true_part_variable + '\n' + line
                #     #     if truepart_if_opened_count == truepart_if_closed_count:
                #     #         truepart_ifs_tallied = True
                #     #         truepart_if_opened_count, truepart_if_closed_count = 0, 0
                #     #     continue
                #
                #     if (re.match('ELSE', line) or re.match('LOOP',line) or re.match('.*END-IF', line) or re.match('ELSE IF', line) or re.match('.*DOEND',line,re.IGNORECASE)) and truepart_ifs_tallied:
                #         if re.match('.*END-IF', line, re.IGNORECASE) or re.match('.*DOEND',line,re.IGNORECASE) or re.match('.*LOOP.*',line,re.IGNORECASE) :
                #             next_else_line = dict[function][index + 1]
                #             if not (re.match('ELSE', next_else_line,re.IGNORECASE) or re.match('ELSE IF',next_else_line,re.IGNORECASE)) and next_else_line[if_index] != " ":
                #
                #                     node_sequence.append('T' + str(total_if_counter))
                #                     node_code['T' + str(total_if_counter)] = true_part_variable + '\n' + line
                #                     node_sequence.append('F' + str(total_if_counter))
                #                     node_code['F' + str(total_if_counter)] = ''
                #                     true_part_variable = ''
                #                     true_part_flag = False
                #
                #                     continue
                #             elif re.match('LOOP',line,re.IGNORECASE):
                #                 node_sequence.append('T' + str(total_if_counter))
                #                 node_code['T' + str(total_if_counter)] = true_part_variable + '\n'
                #                 node_sequence.append('F' + str(total_if_counter))
                #                 node_code['F' + str(total_if_counter)] = ''
                #                 true_part_variable = ''
                #
                #                 inner_loop_variable = line
                #                 node_sequence.append('S' + str(total_individual_block_counter))
                #                 node_code['S' + str(total_individual_block_counter)] = inner_loop_variable
                #                 inner_loop_variable = ''
                #                 true_part_flag = False
                #                 continue
                #
                #             else:
                #                 true_part_variable = true_part_variable + '\n' + line
                #                 continue
                #         else:
                #             if (re.match('ELSE', line, re.IGNORECASE) or re.match('ELSE IF',line,re.IGNORECASE)):
                #                 # print(line)
                #                 discovered_node = 'T' + str(
                #                     total_if_counter) + ' =>operation:' + true_part_variable + ' | rejected\n'
                #                 node_sequence.append('T' + str(total_if_counter))
                #                 node_code['T' + str(total_if_counter)] = true_part_variable
                #                 node_sequence.append('F' + str(total_if_counter))
                #                 node_code['F' + str(total_if_counter)] = ''
                #                 # print(true_part_variable)
                #                 # Clear the true part variable
                #                 true_part_variable = ''
                #                 # Set true part flag to false
                #                 true_part_flag = False
                #                 false_part_flag = True
                #                 false_part_variable = ''
                #                 # false_part_variable = false_part_variable + line + '\n'
                #                 continue
                #
                #     else:
                #
                #             true_part_variable = true_part_variable + '\n' + line
                #             continue
                #
                # if false_part_flag:
                #
                #     # if re.match('IF\s+.*', line,re.IGNORECASE):
                #     #     if not re.match('IF NO RECORD  FOUND', line, re.IGNORECASE) :
                #     #         # make sure if execution knows that IFs are no longer tallied
                #     #         falsepart_ifs_tallied = False
                #     #         # Increment the count of opened if statements
                #     #         falsepart_if_opened_count += 1
                #     #         false_part_variable = false_part_variable + '\n' + line
                #     #         continue
                #
                #     if (not falsepart_ifs_tallied) and (re.match('END-IF', line, re.IGNORECASE)or re.match('DOEND',line,re.IGNORECASE)):
                #         falsepart_if_closed_count += 1
                #         false_part_variable = false_part_variable + '\n' + line
                #         if falsepart_if_opened_count == falsepart_if_closed_count:
                #             falsepart_ifs_tallied = True
                #             falsepart_if_opened_count, falsepart_if_closed_count = 0, 0
                #             try:
                #
                #                 next_line = dict[function][index + 1]
                #                 if (re.match('END-IF', next_line, re.IGNORECASE) or re.match('DOEND', next_line,
                #                                                                            re.IGNORECASE)):
                #                     continue
                #                 # else:
                #                 #     discovered_node = 'F' + str(
                #                 #         total_if_counter) + ' =>operation:' + false_part_variable + ' | rejected\n'
                #                 #     # print(discovered_node)
                #                 #     node_sequence.append('F' + str(total_if_counter))
                #                 #     node_code['F' + str(total_if_counter)] = false_part_variable
                #                 #     # print('false',false_part_variable)
                #                 #     false_part_flag = False
                #                 #     group_block_flag = True
                #                 #     total_group_block_counter = total_group_block_counter + 1
                #                 #
                #                 #     continue
                #             except:
                #                     discovered_node = 'F' + str(
                #                         total_if_counter) + ' =>operation:' + false_part_variable + ' | rejected\n'
                #                     # print(discovered_node)
                #                     node_sequence.append('F' + str(total_if_counter))
                #                     node_code['F' + str(total_if_counter)] = false_part_variable
                #                     # print('false',false_part_variable)
                #                     false_part_flag = False
                #                     group_block_flag = True
                #                     total_group_block_counter = total_group_block_counter + 1
                #
                #                     continue
                #
                #
                #         #continue
                #
                #     if (re.match('END-IF', line, re.IGNORECASE) or re.match('DOEND',line,re.IGNORECASE) or re.match('RETURN',line,re.IGNORECASE) or re.match('END-SUBROUTINE',line,re.IGNORECASE)) and falsepart_ifs_tallied:
                #         if (re.match('RETURN',line,re.IGNORECASE) or re.match('END-SUBROUTINE',line,re.IGNORECASE)):
                #
                #             false_part_variable = false_part_variable + '\n'
                #             discovered_node = 'F' + str(
                #                 total_if_counter) + ' =>operation:' + false_part_variable + ' | rejected\n'
                #             # print(discovered_node)
                #             node_sequence.append('F' + str(total_if_counter))
                #             node_code['F' + str(total_if_counter)] = false_part_variable
                #             # print('false',false_part_variable)
                #             false_part_flag = False
                #             group_block_flag = True
                #             total_group_block_counter = total_group_block_counter + 1
                #
                #             continue
                #         else:
                #             false_part_variable = false_part_variable + line + '\n'
                #             discovered_node = 'F' + str(
                #                 total_if_counter) + ' =>operation:' + false_part_variable + ' | rejected\n'
                #             # print(discovered_node)
                #             node_sequence.append('F' + str(total_if_counter))
                #             node_code['F' + str(total_if_counter)] = false_part_variable
                #             # print('false',false_part_variable)
                #             false_part_flag = False
                #             group_block_flag = True
                #             total_group_block_counter = total_group_block_counter + 1
                #
                #             continue
                #
                #     else:
                #
                #         false_part_variable = false_part_variable + '\n' + line
                #         continue

                if norecord_flag:
                    if re.match('.*END-NOREC.*', line, re.IGNORECASE) or re.match('.*LOOP.*',line,re.IGNORECASE) or line[0] != '':
                        norecord_variable = norecord_variable + '\n' + line
                        node_sequence.append('S' + str(total_individual_block_counter))
                        end_tag_list.append('S' + str(total_individual_block_counter))
                        node_code['S' + str(total_individual_block_counter)] = norecord_variable
                        norecord_variable = ''
                        norecord_flag = False
                        continue

                    else:
                        norecord_variable = norecord_variable + '\n' + line

                        continue

                if decide_flag:
                    if re.match('.*VALUE.*', line, re.IGNORECASE):
                        decide_variable = decide_variable + '\n'
                        node_sequence.append('S' + str(total_individual_block_counter))
                        end_tag_list.append('S' + str(total_individual_block_counter))
                        node_code['S' + str(total_individual_block_counter)] = decide_variable
                        value_variable = line + '\n'
                        main_value_index = value_variable.index("VALUE")
                        decide_variable = ''
                        decide_flag = False
                        value_flag = True
                        continue

                    else:
                        decide_variable = decide_variable + '\n' + line
                        continue

                if decide_for_flag:
                    if re.match('.*WHEN.*', line, re.IGNORECASE):
                        decide_for_variable = decide_for_variable + '\n'
                        node_sequence.append('S' + str(total_individual_block_counter))
                        end_tag_list.append('S' + str(total_individual_block_counter))
                        node_code['S' + str(total_individual_block_counter)] = decide_for_variable
                        when_variable = line + '\n'
                        main_when_index = when_variable.index("WHEN")
                        decide_for_variable = ''
                        decide_for_flag = False
                        when_flag = True
                        continue

                    else:
                        decide_for_variable = decide_for_variable + '\n' + line
                        continue

                if when_flag:
                    if re.match('.*WHEN.*',line,) :
                        if line.__contains__("DECIDE"):
                            when_variable = when_variable + '\n' + line
                            continue
                        when_index = line.index("WHEN")
                        # values_index = line.index("VALUES")
                        # if when_index == main_when_index :
                        when_variable = when_variable + '\n'
                        total_individual_block_counter = total_individual_block_counter + 1
                        node_sequence.append('S' + str(total_individual_block_counter))
                        end_tag_list.append('S' + str(total_individual_block_counter))
                        node_code['S' + str(total_individual_block_counter)] = when_variable
                        when_variable = ''
                        when_variable = line + '\n'
                        continue

                    # else:
                    #     value_variable = value_variable + '\n' + line
                    #     continue

                    if re.match('.*WHEN NONE.*',line,re.IGNORECASE):
                        none_index = line.index("WHEN NONE")
                        # if none_index == main_when_index:
                        when_variable = when_variable + '\n'
                        total_individual_block_counter = total_individual_block_counter + 1
                        node_sequence.append('S' + str(total_individual_block_counter))
                        end_tag_list.append('S' + str(total_individual_block_counter))
                        node_code['S' + str(total_individual_block_counter)] = when_variable
                        when_variable = ''
                        when_variable = line + '\n'
                        continue

                    if re.match('.*END-DECIDE.*',line,re.IGNORECASE):
                        enddecide_index = line.index("END-DECIDE")
                        # if decide_for_index == enddecide_index:
                        when_variable = when_variable + '\n' + line
                        total_individual_block_counter = total_individual_block_counter + 1
                        node_sequence.append('S' + str(total_individual_block_counter))
                        end_tag_list.append('S' + str(total_individual_block_counter))
                        node_code['S' + str(total_individual_block_counter)] = when_variable
                        when_variable = ''
                        when_flag = False
                        continue
                        # else:
                        #     when_variable = when_variable + '\n' + line
                        #     continue

                    else:
                        when_variable = when_variable + '\n' + line
                        continue


                if value_flag:
                    if re.match('.*VALUE.*',line,) :
                        if line.__contains__("DECIDE"):
                            value_variable = value_variable + '\n' + line
                            continue
                        value_index = line.index("VALUE")
                        # values_index = line.index("VALUES")
                        if value_index == main_value_index :
                            value_variable = value_variable + '\n'
                            total_individual_block_counter = total_individual_block_counter + 1
                            node_sequence.append('S' + str(total_individual_block_counter))
                            end_tag_list.append('S' + str(total_individual_block_counter))
                            node_code['S' + str(total_individual_block_counter)] = value_variable
                            value_variable = ''
                            value_variable = line + '\n'
                            continue

                    # else:
                    #     value_variable = value_variable + '\n' + line
                    #     continue

                    if re.match('.*NONE.*',line,re.IGNORECASE):
                        none_index = line.index("NONE")
                        if none_index == main_value_index:
                            value_variable = value_variable + '\n'
                            total_individual_block_counter = total_individual_block_counter + 1
                            node_sequence.append('S' + str(total_individual_block_counter))
                            end_tag_list.append('S' + str(total_individual_block_counter))
                            node_code['S' + str(total_individual_block_counter)] = value_variable
                            value_variable = ''
                            value_variable = line + '\n'
                            continue

                    if re.match('.*END-DECIDE.*',line,re.IGNORECASE):
                        enddecide_index = line.index("END-DECIDE")
                        if decide_index == enddecide_index:
                            value_variable = value_variable + '\n' + line
                            total_individual_block_counter = total_individual_block_counter + 1
                            node_sequence.append('S' + str(total_individual_block_counter))
                            end_tag_list.append('S' + str(total_individual_block_counter))
                            node_code['S' + str(total_individual_block_counter)] = value_variable
                            value_variable = ''
                            value_flag = False
                            continue
                        else:
                            value_variable = value_variable + '\n' + line
                            continue

                    else:
                        value_variable = value_variable + '\n' + line
                        continue

                if read_flag:
                    if read_variable.endswith("WITH") or line.startswith("WHERE") or line.startswith("AND") or line.startswith("OR")or line.startswith("START"):
                        read_variable = read_variable + '\n' + line
                        continue

                    else:
                        read_variable = read_variable + '\n'
                        node_sequence.append('P' + str(total_individual_block_counter))
                        end_tag_list.append('P' + str(total_individual_block_counter))
                        node_code['P' + str(total_individual_block_counter)] = read_variable
                        read_variable = ''
                        read_flag = False
                        continue

                if repeatuntil_flag:
                    if repeatuntil_variable.endswith("OR") or repeatuntil_variable.endswith("AND"):

                        repeatuntil_variable = repeatuntil_variable + '\n' + line
                        continue
                    else:
                        repeatuntil_variable = repeatuntil_variable + '\n'
                        node_sequence.append('S' + str(total_individual_block_counter))
                        end_tag_list.append('S' + str(total_individual_block_counter))
                        node_code['S' + str(total_individual_block_counter)] = repeatuntil_variable
                        repeatuntil_variable = ''
                        repeatuntil_flag = False
                        continue



                if find_flag:
                    if find_statement.endswith("WITH") or line.startswith("WHERE") or line.startswith("AND") or line.startswith("OR")or line.startswith("START"):
                        find_variable = find_statement + '\n' + line
                        find_statement = ''
                        continue
                    if not(line.endswith("WITH") or line.startswith("WHERE") or line.startswith("AND") or line.startswith("OR")or line.startswith("START")):
                        find_variable = find_variable + '\n'
                        node_sequence.append('S' + str(total_individual_block_counter))
                        end_tag_list.append('S' + str(total_individual_block_counter))
                        node_code['S' + str(total_individual_block_counter)] = find_variable
                        find_variable = ''
                        find_flag = False
                        #continue


                if read_flag:
                    if read_statement.endswith("WITH") or line.startswith("WHERE") or line.startswith("AND") or line.startswith("OR")or line.startswith("START"):
                        read_variable = read_statement + '\n' + line
                        read_statement = ''
                        continue
                    if not(line.endswith("WITH") or line.startswith("WHERE") or line.startswith("AND") or line.startswith("OR")or line.startswith("START")):
                        read_variable = read_variable + '\n'
                        node_sequence.append('S' + str(total_individual_block_counter))
                        end_tag_list.append('S' + str(total_individual_block_counter))
                        node_code['S' + str(total_individual_block_counter)] = read_variable
                        read_variable = ''
                        read_flag = False
                        #continue

                if re.match('.*DECIDE ON.*', line, re.IGNORECASE)  :
                    decide_index =  line.index("DECIDE")
                    decide_variable = ''
                    total_individual_block_counter = total_individual_block_counter + 1
                    # if re.match('.*\.\s*', line):
                    decide_variable = line + '\n'
                    # Set the perform varying collector flag
                    decide_flag = True
                    if group_block_variable != '':
                        total_group_block_counter = total_group_block_counter + 1
                        node_sequence.append('G' + str(total_group_block_counter))
                        end_tag_list.append('G' + str(total_group_block_counter))
                        node_code['G' + str(total_group_block_counter)] = group_block_variable
                        group_block_variable = ''
                    continue

                if re.match('.*DECIDE FOR.*', line, re.IGNORECASE)  :
                    decide_for_index =  line.index("DECIDE")
                    decide_for_variable = ''
                    total_individual_block_counter = total_individual_block_counter + 1
                    # if re.match('.*\.\s*', line):
                    decide_for_variable = line + '\n'
                    # Set the perform varying collector flag
                    decide_for_flag = True
                    if group_block_variable != '':
                        total_group_block_counter = total_group_block_counter + 1
                        node_sequence.append('G' + str(total_group_block_counter))
                        end_tag_list.append('G' + str(total_group_block_counter))
                        node_code['G' + str(total_group_block_counter)] = group_block_variable
                        group_block_variable = ''
                    continue



                # if re.search('.*DECIDE ON.*',line,re.IGNORECASE) or re.match('.*DECIDE FOR.*',line,re.IGNORECASE):
                #     if group_block_variable != '':
                #         total_group_block_counter = total_group_block_counter + 1
                #         node_sequence.append('G' + str(total_group_block_counter))
                #         node_code['G' + str(total_group_block_counter)] = group_block_variable
                #         group_block_variable = ''
                #     decide_variable = ''
                #     total_individual_block_counter = total_individual_block_counter + 1
                #     decide_variable = line + '\n'
                #     # print(read_variable)
                #     node_sequence.append('S' + str(total_individual_block_counter))
                #     node_code['S' + str(total_individual_block_counter)] = decide_variable
                #     decide_variable = ''
                #     continue


                if re.search(r'FOR .*', line, re.IGNORECASE):
                    if not re.search('.*DECIDE FOR.*',line,re.IGNORECASE):
                    # print(line)
                        if group_block_variable != '':
                            total_group_block_counter = total_group_block_counter + 1
                            node_sequence.append('G' + str(total_group_block_counter))
                            end_tag_list.append('G' + str(total_group_block_counter))
                            node_code['G' + str(total_group_block_counter)] = group_block_variable
                            group_block_variable = ''
                        for_variable = ''
                        total_individual_block_counter = total_individual_block_counter + 1
                        for_variable = line + '\n'
                        # print(read_variable)
                        node_sequence.append('S' + str(total_individual_block_counter))
                        end_tag_list.append('S' + str(total_individual_block_counter))
                        node_code['S' + str(total_individual_block_counter)] = for_variable
                        for_variable = ''
                        continue


                if re.search(r'SET\s.*', line, re.IGNORECASE):
                    # print(line)
                    if group_block_variable != '':
                        total_group_block_counter = total_group_block_counter + 1
                        node_sequence.append('G' + str(total_group_block_counter))
                        end_tag_list.append('G' + str(total_group_block_counter))
                        node_code['G' + str(total_group_block_counter)] = group_block_variable
                        group_block_variable = ''
                    set_variable = ''
                    total_individual_block_counter = total_individual_block_counter + 1
                    set_variable = line + '\n'
                    # print(read_variable)
                    node_sequence.append('S' + str(total_individual_block_counter))
                    end_tag_list.append('S' + str(total_individual_block_counter))
                    node_code['S' + str(total_individual_block_counter)] = set_variable
                    set_variable = ''
                    continue

                if re.match('.*IF NO RECORD FOUND.*', line, re.IGNORECASE) or re.match('.*IF NO RECORDS FOUND.*',line,re.IGNORECASE):
                    #if not (re.match('END-READ.*', line, re.IGNORECASE)):
                    if group_block_variable != '':
                        total_group_block_counter = total_group_block_counter + 1
                        node_sequence.append('G' + str(total_group_block_counter))
                        end_tag_list.append('G' + str(total_group_block_counter))
                        node_code['G' + str(total_group_block_counter)] = group_block_variable
                        group_block_variable = ''
                    norecord_variable = ''
                    total_individual_block_counter = total_individual_block_counter + 1
                    norecord_variable = line + '\n'
                    # print(read_variable)
                    # node_sequence.append('S' + str(total_individual_block_counter))
                    # end_tag_list.append('S' + str(total_individual_block_counter))
                    # node_code['S' + str(total_individual_block_counter)] = norecord_variable
                    norecord_flag = True
                    continue

                if re.match("END-READ.*",line,re.IGNORECASE):
                    if group_block_variable != '':
                        total_group_block_counter = total_group_block_counter + 1
                        node_sequence.append('G' + str(total_group_block_counter))
                        end_tag_list.append('G' + str(total_group_block_counter))
                        node_code['G' + str(total_group_block_counter)] = group_block_variable
                        group_block_variable = ''
                    endread_variable = ''
                    total_individual_block_counter = total_individual_block_counter + 1
                    endread_variable = line + '\n'
                    # print(read_variable)
                    node_sequence.append('S' + str(total_individual_block_counter))
                    end_tag_list.append('S' + str(total_individual_block_counter))
                    node_code['S' + str(total_individual_block_counter)] = endread_variable
                    endread_variable = ''
                    continue

                if re.match('REPEAT UNTIL .*', line, re.IGNORECASE):

                    repeatuntil_variable = ''
                    total_individual_block_counter = total_individual_block_counter + 1
                    # if re.match('.*\.\s*', line):
                    repeatuntil_variable = line
                    repeatuntil_flag = True
                    if group_block_variable != '':
                        total_group_block_counter = total_group_block_counter + 1
                        node_sequence.append('G' + str(total_group_block_counter))
                        end_tag_list.append('G' + str(total_group_block_counter))
                        node_code['G' + str(total_group_block_counter)] = group_block_variable
                        group_block_variable = ''
                    continue

                if re.match('READ .*',line,re.IGNORECASE):
                    read_variable = ''
                    total_individual_block_counter = total_individual_block_counter + 1
                    read_statement = ''
                    if line.endswith("WITH") or line.startswith("WHERE") or line.startswith("AND") or line.startswith("OR")or line.startswith("START"):
                        read_statement = line
                        read_flag = True
                        if group_block_variable != '':
                            total_group_block_counter = total_group_block_counter + 1
                            node_sequence.append('G' + str(total_group_block_counter))
                            end_tag_list.append('G' + str(total_group_block_counter))
                            node_code['G' + str(total_group_block_counter)] = group_block_variable
                            group_block_variable = ''
                        continue
                    else:
                        if group_block_variable != '':
                            total_group_block_counter = total_group_block_counter + 1
                            node_sequence.append('G' + str(total_group_block_counter))
                            end_tag_list.append('G' + str(total_group_block_counter))
                            node_code['G' + str(total_group_block_counter)] = group_block_variable
                            group_block_variable = ''
                        read_variable = ''
                        read_variable = line + '\n'
                        node_sequence.append('S' + str(total_individual_block_counter))
                        end_tag_list.append('S' + str(total_individual_block_counter))
                        node_code['S' + str(total_individual_block_counter)] = read_variable
                        read_variable = ''
                        continue

                if re.match('FIND .*', line, re.IGNORECASE):
                    find_variable = ''
                    total_individual_block_counter = total_individual_block_counter + 1
                    find_statement = ''

                    if line.endswith("WITH") or line.startswith("WHERE") or line.startswith("AND") or line.startswith("OR")or line.startswith("START"):
                        find_statement = line
                        find_flag = True
                        if group_block_variable != '':
                            total_group_block_counter = total_group_block_counter + 1
                            node_sequence.append('G' + str(total_group_block_counter))
                            end_tag_list.append('G' + str(total_group_block_counter))
                            node_code['G' + str(total_group_block_counter)] = group_block_variable
                            group_block_variable = ''
                        continue

                    else:
                        if group_block_variable != '':
                            total_group_block_counter = total_group_block_counter + 1
                            node_sequence.append('G' + str(total_group_block_counter))
                            end_tag_list.append('G' + str(total_group_block_counter))
                            node_code['G' + str(total_group_block_counter)] = group_block_variable
                            group_block_variable = ''
                        find_variable = ''
                        find_variable = line + '\n'
                        node_sequence.append('S' + str(total_individual_block_counter))
                        end_tag_list.append('S' + str(total_individual_block_counter))
                        node_code['S' + str(total_individual_block_counter)] = find_variable
                        find_variable = ''
                        continue

                if re.match("END-FIND.*",line,re.IGNORECASE):
                    if group_block_variable != '':
                        total_group_block_counter = total_group_block_counter + 1
                        node_sequence.append('G' + str(total_group_block_counter))
                        end_tag_list.append('G' + str(total_group_block_counter))
                        node_code['G' + str(total_group_block_counter)] = group_block_variable
                        group_block_variable = ''
                    endfind_variable = ''
                    total_individual_block_counter = total_individual_block_counter + 1
                    endfind_variable = line + '\n'
                    # print(read_variable)
                    node_sequence.append('S' + str(total_individual_block_counter))
                    end_tag_list.append('S' + str(total_individual_block_counter))
                    node_code['S' + str(total_individual_block_counter)] = endfind_variable
                    endfind_variable = ''
                    continue

                if re.match("LOOP.*",line,re.IGNORECASE):
                    print("Loop:",line)
                    if group_block_variable != '':
                        total_group_block_counter = total_group_block_counter + 1
                        node_sequence.append('G' + str(total_group_block_counter))
                        end_tag_list.append('G' + str(total_group_block_counter))
                        node_code['G' + str(total_group_block_counter)] = group_block_variable
                        group_block_variable = ''
                    loop_variable = ''
                    total_individual_block_counter = total_individual_block_counter + 1
                    loop_variable = line + '\n'
                    # print(read_variable)
                    node_sequence.append('S' + str(total_individual_block_counter))
                    end_tag_list.append('S' + str(total_individual_block_counter))
                    node_code['S' + str(total_individual_block_counter)] = loop_variable
                    loop_variable = ''
                    continue

                if re.match("CALL .*",line,re.IGNORECASE):
                    if group_block_variable != '':
                        total_group_block_counter = total_group_block_counter + 1
                        node_sequence.append('G' + str(total_group_block_counter))
                        end_tag_list.append('G' + str(total_group_block_counter))
                        node_code['G' + str(total_group_block_counter)] = group_block_variable
                        group_block_variable = ''
                    call_variable = ''
                    total_individual_block_counter = total_individual_block_counter + 1
                    call_variable = line + '\n'
                    # print(read_variable)
                    node_sequence.append('S' + str(total_individual_block_counter))
                    end_tag_list.append('S' + str(total_individual_block_counter))
                    node_code['S' + str(total_individual_block_counter)] = call_variable
                    call_variable = ''
                    continue

                if re.match("CALLNAT .*",line,re.IGNORECASE):
                    if group_block_variable != '':
                        total_group_block_counter = total_group_block_counter + 1
                        node_sequence.append('G' + str(total_group_block_counter))
                        end_tag_list.append('G' + str(total_group_block_counter))
                        node_code['G' + str(total_group_block_counter)] = group_block_variable
                        group_block_variable = ''
                    callnat_variable = ''
                    total_individual_block_counter = total_individual_block_counter + 1
                    callnat_variable = line + '\n'
                    # print(read_variable)
                    node_sequence.append('S' + str(total_individual_block_counter))
                    end_tag_list.append('S' + str(total_individual_block_counter))
                    node_code['S' + str(total_individual_block_counter)] = callnat_variable
                    callnat_variable = ''
                    continue

                if re.match('.*IF .*', line) :
                    if not re.match('.*IF NOT .*',line,re.IGNORECASE) or  re.match('.*IF NO RECORD FOUND.*', line, re.IGNORECASE) or re.match('.*IF NO RECORDS FOUND.*',line,re.IGNORECASE):
                        print("Line passed:", line)
                        main_if_index = line.index("IF")
                        # print("Index:",if_index)
                        if_condition_variable = " "
                        total_if_counter = total_if_counter + 1
                        check_if_counter = check_if_counter + 1
                        main_if_dict[total_if_counter] = main_if_index
                        if_condition_variable = line
                        if_line = line
                        if_condition_collector_flag = True
                        group_block_flag = False
                        if group_block_variable != '':
                            total_group_block_counter = total_group_block_counter + 1
                            node_sequence.append('G' + str(total_group_block_counter))
                            end_tag_list.append('G' + str(total_group_block_counter))
                            node_code['G' + str(total_group_block_counter)] = group_block_variable
                            group_block_variable = ''
                        continue

                if re.match('.*END-IF.*', line,re.IGNORECASE):
                    main_endif_index = line.index("END-IF")
                    if main_if_index == main_endif_index:
                        if group_block_variable != '' and innerlevel_mainif_list != []:
                            total_group_block_counter = total_group_block_counter + 1
                            node_sequence.append('G' + str(total_group_block_counter))
                            innerif_end_tag_list.append('G' + str(total_group_block_counter))
                            node_code['G' + str(total_group_block_counter)] = group_block_variable
                            group_block_variable = ''
                            continue

                        if  node_sequence != [] and node_sequence[-1].startswith("S"):
                            endif_complicated_list.append(node_sequence[-1])
                            continue
                        else:
                            main_endif_counter = main_endif_counter + 1
                            continue

                    else:

                        for innerif_key, innerif_value in innerif_nested_dict.items():
                            if innerif_value == main_endif_index:
                                if innerif_key in innerif_check_list:
                                    continue
                                true_if_counter = innerif_key
                                innerif_check_list.append(true_if_counter)
                                if group_block_variable != '' and innerlevel_mainif_list != []:
                                    total_group_block_counter = total_group_block_counter + 1
                                    node_sequence.append('G' + str(total_group_block_counter))
                                    complicated_endif_list.append('C' + str(true_if_counter))
                                    # innerif_end_tag_list.append('G' + str(total_group_block_counter))
                                    node_code['G' + str(total_group_block_counter)] = group_block_variable
                                    group_block_variable = ''
                        continue

                if re.match('.*IF NOT .*',line,re.IGNORECASE):
                    if_condition_variable = " "
                    main_if_index = line.index("IF NOT")
                    total_if_counter = total_if_counter + 1
                    if_condition_variable = line
                    discovered_node = 'C' + str(
                        total_if_counter) + ' =>condition:' + if_condition_variable + ' | approved\n'
                    node_sequence.append('C' + str(total_if_counter))
                    node_code['C' + str(total_if_counter)] = if_condition_variable
                    true_part_variable = ''
                    true_part_flag = True
                    group_block_flag = False
                    if group_block_variable != '':
                        total_group_block_counter = total_group_block_counter + 1
                        node_sequence.append('G' + str(total_group_block_counter))
                        end_tag_list.append('G' + str(total_group_block_counter))
                        node_code['G' + str(total_group_block_counter)] = group_block_variable
                        group_block_variable = ''
                    continue


                if re.match("OBTAIN .*",line,re.IGNORECASE):
                    if group_block_variable != '':
                        total_group_block_counter = total_group_block_counter + 1
                        node_sequence.append('G' + str(total_group_block_counter))
                        end_tag_list.append('G' + str(total_group_block_counter))
                        node_code['G' + str(total_group_block_counter)] = group_block_variable
                        group_block_variable = ''
                    obtain_variable = ''
                    total_individual_block_counter = total_individual_block_counter + 1
                    obtain_variable = line + '\n'
                    # print(read_variable)
                    node_sequence.append('S' + str(total_individual_block_counter))
                    end_tag_list.append('S' + str(total_individual_block_counter))
                    node_code['S' + str(total_individual_block_counter)] = obtain_variable
                    obtain_variable = ''
                    continue

                if re.match("RETURN .*",line,re.IGNORECASE):
                    if group_block_variable != '':
                        total_group_block_counter = total_group_block_counter + 1
                        node_sequence.append('G' + str(total_group_block_counter))
                        end_tag_list.append('G' + str(total_group_block_counter))
                        node_code['G' + str(total_group_block_counter)] = group_block_variable
                        group_block_variable = ''
                    return_variable = ''
                    total_individual_block_counter = total_individual_block_counter + 1
                    return_variable = line + '\n'
                    # print(read_variable)
                    node_sequence.append('S' + str(total_individual_block_counter))
                    end_tag_list.append('S' + str(total_individual_block_counter))
                    node_code['S' + str(total_individual_block_counter)] = return_variable
                    return_variable = ''
                    continue


                if re.match("INPUT USING.*",line,re.IGNORECASE):
                    if group_block_variable != '':
                        total_group_block_counter = total_group_block_counter + 1
                        node_sequence.append('G' + str(total_group_block_counter))
                        end_tag_list.append('G' + str(total_group_block_counter))
                        node_code['G' + str(total_group_block_counter)] = group_block_variable
                        group_block_variable = ''
                    input_variable = ''
                    total_individual_block_counter = total_individual_block_counter + 1
                    input_variable = line + '\n'
                    # print(read_variable)
                    node_sequence.append('S' + str(total_individual_block_counter))
                    end_tag_list.append('S' + str(total_individual_block_counter))
                    node_code['S' + str(total_individual_block_counter)] = input_variable
                    input_variable = ''
                    continue

                if re.match("REINPUT .*",line,re.IGNORECASE):
                    if group_block_variable != '':
                        total_group_block_counter = total_group_block_counter + 1
                        node_sequence.append('G' + str(total_group_block_counter))
                        end_tag_list.append('G' + str(total_group_block_counter))
                        node_code['G' + str(total_group_block_counter)] = group_block_variable
                        group_block_variable = ''
                    reinput_variable = ''
                    total_individual_block_counter = total_individual_block_counter + 1
                    reinput_variable = line + '\n'
                    # print(read_variable)
                    node_sequence.append('S' + str(total_individual_block_counter))
                    end_tag_list.append('S' + str(total_individual_block_counter))
                    node_code['S' + str(total_individual_block_counter)] = reinput_variable
                    reinput_variable = ''
                    continue



                if re.match("REPEAT .*",line,re.IGNORECASE):
                    if group_block_variable != '':
                        total_group_block_counter = total_group_block_counter + 1
                        node_sequence.append('G' + str(total_group_block_counter))
                        end_tag_list.append('G' + str(total_group_block_counter))
                        node_code['G' + str(total_group_block_counter)] = group_block_variable
                        group_block_variable = ''
                    repeat_variable = ''
                    total_individual_block_counter = total_individual_block_counter + 1
                    repeat_variable = line + '\n'
                    # print(read_variable)
                    node_sequence.append('S' + str(total_individual_block_counter))
                    end_tag_list.append('S' + str(total_individual_block_counter))
                    node_code['S' + str(total_individual_block_counter)] = repeat_variable
                    repeat_variable = ''
                    continue

                if re.match("END-REPEAT .*",line,re.IGNORECASE):
                    if group_block_variable != '':
                        total_group_block_counter = total_group_block_counter + 1
                        node_sequence.append('G' + str(total_group_block_counter))
                        end_tag_list.append('G' + str(total_group_block_counter))
                        node_code['G' + str(total_group_block_counter)] = group_block_variable
                        group_block_variable = ''
                    endrepeat_variable = ''
                    total_individual_block_counter = total_individual_block_counter + 1
                    endrepeat_variable = line + '\n'
                    # print(read_variable)
                    node_sequence.append('S' + str(total_individual_block_counter))
                    end_tag_list.append('S' + str(total_individual_block_counter))
                    node_code['S' + str(total_individual_block_counter)] = endrepeat_variable
                    endrepeat_variable = ''
                    continue

                if re.match(".*END-FOR .*",line,re.IGNORECASE):
                    if group_block_variable != '':
                        total_group_block_counter = total_group_block_counter + 1
                        node_sequence.append('G' + str(total_group_block_counter))
                        end_tag_list.append('G' + str(total_group_block_counter))
                        node_code['G' + str(total_group_block_counter)] = group_block_variable
                        group_block_variable = ''
                    endfor_variable = ''
                    total_individual_block_counter = total_individual_block_counter + 1
                    endfor_variable = line + '\n'
                    # print(read_variable)
                    node_sequence.append('S' + str(total_individual_block_counter))
                    end_tag_list.append('S' + str(total_individual_block_counter))
                    node_code['S' + str(total_individual_block_counter)] = endfor_variable
                    endfor_variable = ''
                    continue

                if re.match('.*END-DECIDE.*',line,re.IGNORECASE):
                    if group_block_variable != '':
                        total_group_block_counter = total_group_block_counter + 1
                        node_sequence.append('G' + str(total_group_block_counter))
                        end_tag_list.append('G' + str(total_group_block_counter))
                        node_code['G' + str(total_group_block_counter)] = group_block_variable
                        group_block_variable = ''
                    enddecide_variable = ''
                    total_individual_block_counter = total_individual_block_counter + 1
                    enddecide_variable = line + '\n'
                    # print(read_variable)
                    node_sequence.append('S' + str(total_individual_block_counter))
                    end_tag_list.append('S' + str(total_individual_block_counter))
                    node_code['S' + str(total_individual_block_counter)] = enddecide_variable
                    enddecide_variable = ''
                    continue

                if re.match('.*PERFORM .*', line, re.IGNORECASE):
                    if group_block_variable != '':
                        total_group_block_counter = total_group_block_counter + 1
                        node_sequence.append('G' + str(total_group_block_counter))
                        end_tag_list.append('G' + str(total_group_block_counter))
                        node_code['G' + str(total_group_block_counter)] = group_block_variable
                        group_block_variable = ''
                    perform_variable = ''
                    total_individual_block_counter = total_individual_block_counter + 1
                    perform_variable = line + '\n'
                    # print(read_variable)
                    node_sequence.append('S' + str(total_individual_block_counter))
                    end_tag_list.append('S' + str(total_individual_block_counter))
                    node_code['S' + str(total_individual_block_counter)] = perform_variable
                    perform_variable = ''
                    continue

                if re.match('WRITE .*', line, re.IGNORECASE):
                    if group_block_variable != '':
                        total_group_block_counter = total_group_block_counter + 1
                        node_sequence.append('G' + str(total_group_block_counter))
                        end_tag_list.append('G' + str(total_group_block_counter))
                        node_code['G' + str(total_group_block_counter)] = group_block_variable
                        group_block_variable = ''
                    write_variable = ''
                    total_individual_block_counter = total_individual_block_counter + 1
                    write_variable = line + '\n'
                    # print(read_variable)
                    node_sequence.append('S' + str(total_individual_block_counter))
                    end_tag_list.append('S' + str(total_individual_block_counter))
                    node_code['S' + str(total_individual_block_counter)] = write_variable
                    write_variable = ''
                    continue




                if line.strip() != '':
                    if line.strip() != '.':
                        group_block_variable = group_block_variable + line + '\n'
                        continue

            if group_block_variable != '':
                total_group_block_counter = total_group_block_counter + 1
                node_sequence.append('G' + str(total_group_block_counter))
                end_tag_list.append('G' + str(total_group_block_counter))
                node_code['G' + str(total_group_block_counter)] = group_block_variable
                group_block_variable = ''

            node_string = 'st=>start: START | past\ne=>end: END | past \n'
            links_string = 'st'
            try:
                for i in range(0, len(node_sequence)):
                    # Make sure the leading line breaks are STRIPPED
                    check_helpful_list.append(node_sequence[i])
                    node_code[node_sequence[i]] = node_code[node_sequence[i]].lstrip('\n')
                    node_code[node_sequence[i]] = node_code[node_sequence[i]].replace('=>', '= >')

                    if re.match('^S.*', node_sequence[i]) or re.match('^G.*', node_sequence[i]):
                        if node_sequence[i] in innerif_end_tag_list:
                            innerif_end_tag_list.remove(node_sequence[i])
                        if node_sequence[i] in end_tag_list:
                            end_tag_list.remove(node_sequence[i])
                        links_string = links_string + '->' + node_sequence[i] + '\n' + node_sequence[i]
                        node_string = node_string + node_sequence[i] + '=>operation: ' + node_code[
                            node_sequence[i]] + ' | approved\n'
                    if re.match('^C.*', node_sequence[i]):
                        if node_sequence[i] in end_tag_list:
                            end_tag_list.remove(node_sequence[i])
                        node_string = node_string + node_sequence[i] + '=>condition: ' + node_code[
                            node_sequence[i]] + ' | rejected\n'

                        # If condition is the last block, end it with the (e) node
                        if (i + 3) >= len(node_sequence):

                            if node_code[node_sequence[i + 2]] == '':
                                # If else part does nto exist
                                links_string = links_string + '->' + node_sequence[i] + '\n' + node_sequence[
                                    i] + '(yes)->' + node_sequence[i + 1]
                                links_string = links_string + '\n' + node_sequence[i + 1] + '->e'
                                links_string = links_string + '\n' + node_sequence[i] + '(no)'

                                # links_string = links_string + '\n' + node_sequence[i] + '(no)'
                                # links_string = links_string + node_sequence[i + 2]
                            else:
                                # Else parts
                                links_string = links_string + '->' + node_sequence[i] + '\n' + node_sequence[
                                    i] + '(yes)->' + node_sequence[i + 1] + '\n' + node_sequence[i] + '(no)->' + \
                                               node_sequence[i + 2] + '\n' + node_sequence[i + 1] + '->e' + '\n' + \
                                               node_sequence[i + 2]

                                # links_string = links_string + '\n' + node_sequence[i] + '(no)'



                        else:
                            # If the conditions is not the last, check if has ELSE part

                            if node_code[node_sequence[i + 2]] == '':
                                if node_code[node_sequence[i + 1]] == '':   # if an IF condition is immediate to another if condition

                                # If there is not else part
                                    links_string = links_string + '->' + node_sequence[i] + '\n' + node_sequence[
                                        i] + '(yes)'
                                    if node_sequence[i + 3] in innerlevel_mainif_list:
                                        for immediate_iter in innerlevel_mainif_list:

                                            if immediate_iter in check_helpful_list:
                                                continue
                                            else:

                                                links_string = links_string + '->' + immediate_iter + '\n' + \
                                                               node_sequence[
                                                                   i] + '(no)'
                                                break
                                else:
                                    links_string = links_string + '->' + node_sequence[i] + '\n' + node_sequence[
                                        i] + '(yes)'

                                    links_string = links_string + '->' + node_sequence[i + 1] + '\n' + node_sequence[
                                        i] + '(no)'
                                if node_sequence[i] not in innerlevel_mainif_list:
                                    if end_tag_list == []:
                                        links_string = links_string + '->e'  + '\n' + node_sequence[
                                            i + 1]
                                    else:

                                        for iter_counter in end_tag_list:
                                            links_string = links_string + '->' + iter_counter + '\n' + node_sequence[
                                                i + 1]
                                            break
                                else:
                                    if node_sequence[i] in complicated_endif_list:
                                        for iter_counter in innerif_end_tag_list:
                                            if iter_counter in check_innerif_end_tag_list:
                                                continue
                                            links_string = links_string + '->' + iter_counter + '\n' + node_sequence[
                                                i + 1]
                                            check_innerif_end_tag_list.append(iter_counter)
                                            break

                                    if endif_complicated_list != []:
                                        for iter in endif_complicated_list:
                                            links_string = links_string + '->' + iter + '\n' + node_sequence[i + 1]

                                    else:
                                        links_string = links_string + '->' + node_sequence[i + 3] + '\n' + node_sequence[i + 1]

                            else:
                                # If there is an else part, behave normally
                                links_string = links_string + '->' + node_sequence[i] + '\n' + node_sequence[
                                    i] + '(yes)'
                                links_string = links_string + '->' + node_sequence[i + 1] + '\n' + node_sequence[
                                    i] + '(no)'
                                if node_code[node_sequence[i + 2]] == '\n':
                                    links_string = links_string + '->' + node_sequence[i + 3]
                                else:

                                    links_string = links_string + '->' + node_sequence[i + 2]

                                if node_sequence[i] in innerlevel_mainif_list:
                                    for iter in endif_complicated_list:
                                        links_string = links_string + '\n' + node_sequence[i + 1] + '->' + iter + '\n' + node_sequence[i + 3]
                                        break

                                if node_sequence[i + 3] in innerlevel_mainelse_list:  ## for nested nodes coming under Main Else
                                    if end_tag_list == []:
                                        links_string = links_string + '\n' + node_sequence[i + 1] + '->e'
                                        for iter in innerlevel_mainelse_list:
                                            links_string = links_string + '\n' + node_sequence[i + 2] + '->' + iter
                                            break
                                    else:

                                        for iter in end_tag_list:
                                            links_string = links_string + '\n' + node_sequence[i + 1] + '->' + iter
                                            break
                                        for iter in innerlevel_mainelse_list:
                                            links_string = links_string + '\n' + node_sequence[i + 2] + '->' + iter + '\n' + node_sequence[i + 3]
                                            break

                                else:



                                    links_string = links_string + '\n' + node_sequence[i + 1] + '->' + node_sequence[
                                        i + 3]
                                    links_string = links_string + '\n' + node_sequence[i + 2] + '->' + node_sequence[
                                        i + 3]
                                # links_string =  links_string + '\n'+node_sequence[i + 1]+ '->' +node_sequence[i + 3]
                                # links_string = '\n'+ node_sequence[i + 2]

                        # try:
                        #     links_string = links_string + node_sequence[i + 1] + '->' + node_sequence[i + 3] + '\n'
                        #     links_string = links_string + node_sequence[i + 2] + '->' + node_sequence[i + 3]
                        # except:
                        #     links_string = links_string + node_sequence[i + 1] + '->e' + '\n'
                        #     links_string = links_string + node_sequence[i + 2]
                        #     # print('List terminated. No more nodes')
                        #
                        #

                    if re.match('^T.*', node_sequence[i]):
                        node_string = node_string + node_sequence[i] + '=>operation: ' + node_code[
                            node_sequence[i]] + ' | approved \n'
                        continue
                    if re.match('^F.*', node_sequence[i]):
                        # links_string = links_string+ '\n' + node_sequence[i]
                        # Experimental remove IF condition if it fails
                        if not node_code[node_sequence[i]].strip() == '':
                            node_string = node_string + node_sequence[i] + '=>operation: ' + node_code[
                                node_sequence[i]] + ' | approved \n'

                        continue

            except Exception as e:
                print(str(e))
            # Concat the end link
            links_string = links_string + '->e'

            # print(node_sequence)
            # print(node_string)
            # print(links_string)
            # print({"option": node_string + '\n' + links_string,"component_name":COMPONENT_NAME,"para_name":paragraph_name.split('.')[0]})
            # print(filename.strip(file_location))
            #nodes = node_string + '\n' + links_string
            OUTPUT_DATA.append({"option": node_string + '\n' + links_string,
                                "component_name": filename ,
                                "para_name": function})
            print("Option:",node_string + '\n' + links_string)
            print("CHeck:",filename.strip(file_location))
            #return  "st=>start: START | past\ne=>end: END | past \nC1=>condition: IF #INPUT NE 'OPENLANE' | rejected\nT1=>operation: MOVE AUTOTRAN.VINCODE TO #BI-VINCODE\nMOVE AUTOTRAN.MOD1 TO #O-RDR-TYPE\nEND-IF | approved \n\nst->C1\nC1(yes)->T1\nT1->e"

            #print("Option:",nodes)

            # print(node_sequence)
            node_sequence.clear()
            node_string = ''
            links_string = ''
            # print(json.dumps(OUTPUT_DATA,indent=4))


        # print(OUTPUT_DATA)


        os.remove("copyexpanded.txt")

        try:
            db.para_flowchart_data.delete_many({'type': {"$ne": "metadata"}})
        except Exception as e:
            print('Error:' + str(e))

        # Insert into DB
        try:

            db.para_flowchart_data.insert_many(OUTPUT_DATA)
            # updating the timestamp based on which report is called
            current_time = datetime.datetime.now(tz=tz).strftime("%A, %d. %B %Y %I:%M%p")
            if db.para_flowchart_data.update_one({"type": "metadata"}, {"$set": {"last_updated_on": current_time,
                                                                                 "time_zone": time_zone,
                                                                                 # "headers":["component_name","component_type"],
                                                                                 "script_version": SCRIPT_VERSION
                                                                                 }}, upsert=True).acknowledged:
                print('update sucess')

        except Exception as e:
            print('Error:' + str(e))



