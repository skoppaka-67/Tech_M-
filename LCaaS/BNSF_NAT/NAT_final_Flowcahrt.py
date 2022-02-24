SCRIPT_VERSION = 'Werner coustmized code '

from pymongo import MongoClient
import pytz
import datetime, json
import config
from collections import OrderedDict
from os.path import join, isfile

global counter
counter = 1
output = []

case = "caseq"
begin = "DEFINE"
search_element = ["begsr", "exsr", "caseq"]
end = "END-SUBROUTINE"
call_sub = "exsr"

import copy

time_zone = 'Asia/Calcutta'
tz = pytz.timezone(time_zone)
import glob, os, re

# client = MongoClient(aps_config.database['mongo_endpoint_url'])
# db = client[aps_config.database['database_name']]
# # file ={ 'D:\AS400*\RPG': '*.RPG'}
base_location = config.codebase_information['code_location']
cobolfolder = config.codebase_information['COBOL']['folder_name']
includefolder = config.codebase_information['INCLUDE']['folder_name']
copybookfolder = config.codebase_information['COPYBOOK']['folder_name']
extention = "." + config.codebase_information['COBOL']['extension']
extention2 = "." + config.codebase_information['INCLUDE']['extension']
extention3 = "." + config.codebase_information['COPYBOOK']['extension']

file = {r'D:\BNSF\POC\NAT': '*.NAT'}

client = MongoClient('localhost', 27017)
db = client['BNSF_NAT_SSI']

source_file = file

# source_file = aps_config.file

try:
    db.para_flowchart_data.delete_many({'type': {"$ne": "metadata"}})
except Exception as e:
    print('Error:' + str(e))


def endif_tagging_function(filename):
    process_list = []
    index_list = []

    for append_lines in filename:
        append_lines = append_lines[5:]
        if append_lines.strip() == "":  ### ignore the blank lines
            continue
        if append_lines[0] == "*":
            continue
        if append_lines.strip().startswith("/*"):
            continue
        if append_lines.strip().startswith('...'):
            # print(append_lines)
            process_list.append(append_lines.replace("END-NOREC", "END-IF"))
            continue
        if append_lines.__contains__("/*"):

            line = append_lines.split("/*")[0]
            process_list.append(" " + line.replace("END-NOREC", "END-IF"))
            continue


        process_list.append(" " + append_lines.replace("END-NOREC", "END-IF"))

    return process_list


def func_separation(process_list):
    flag_main = False
    sub_flag = False
    sub_name = ''
    main_list = []
    sub_list = []
    data = {}
    for line in process_list:
        if line.strip().startswith('END-DEFINE'):
            flag_main = True
            continue
        if line.strip().startswith('DEFINE') and not (
                line.strip().startswith('DEFINE DATA') or line.strip().startswith('DEFINE WINDOW')):
            if flag_main:
                data['Main'] = copy.deepcopy(main_list)
                main_list.clear()
                flag_main = False

            if line.strip().startswith("DEFINE SUBROUTINE"):
                a = line.split("DEFINE SUBROUTINE")
                sub_name = a[1].split()[0]
            elif line.strip().startswith("DEFINE"):
                a = line.split("DEFINE")
                sub_name = a[1].split()[0]

            sub_flag = True
        if flag_main:
            main_list.append(line)

        if line.strip().startswith('END-SUBROUTINE'):
            data[sub_name] = copy.deepcopy(sub_list)

            sub_flag = False
            sub_list.clear()

        if sub_flag:
            sub_list.append(line)
    if main_list !=[] and flag_main:
        data['Main'] = copy.deepcopy(main_list)
        main_list.clear()
        flag_main = False


    return data, data.keys()


def if_process_function(line_list, total_group_block_counter, block_counter, node_sequence, node_code,
                        total_if_block_counter):
    IF_VAR = "IF"
    ELSE_VAR = "ELSE"
    END_IF_VAR = "END-IF"
    ELSE_IF_VAR = "ELSE-IF"
    NELSE_VAR = "NElse"

    # 3 = {str} '                        NElse\n'
    index_list = []
    # print(json.dumps(line_list,indent=4))
    for index, line in enumerate(line_list):
        if line.strip().startswith(IF_VAR):
            # print("IF_line" ,line,index)
            index_list.append({IF_VAR: index})

        if line.lstrip().startswith(ELSE_VAR) and not (line.strip().__contains__(ELSE_IF_VAR)):
            # print("ELSE_line", line, index)
            index_list.append({ELSE_VAR: index})

        if line.lstrip().startswith(NELSE_VAR):
            # print("**ELSE_IF_line", line, index)
            index_list.append({NELSE_VAR.strip(): index})

        if re.search('.*' + END_IF_VAR + '.*', line):
            # print("END --->", line_list[index],index)
            index_list.append({END_IF_VAR: index})

    # print(json.dumps(index_list, indent=4))
    # print(json.dumps(line_list, indent=4))

    stnd_list = []
    pop_list = []
    # print(json.dumps(line_list,indent=4))
    for index, iter in enumerate(index_list):

        alter_index = index + 1
        if IF_VAR in index_list[index] and ELSE_VAR in index_list[alter_index] or \
                (IF_VAR in index_list[index] and IF_VAR in index_list[alter_index]):

            if list(index_list[index].values())[0] + 1 == list(index_list[alter_index].values())[0]:

                block_counter = block_counter + 1
                stnd_list.append(block_counter)
                pop_list.append(block_counter)
                # print(pop_list)
                total_if_block_counter = total_if_block_counter + 1
                conditional_block_var = line_list[list(index_list[index].values())[0]]
                node_sequence.append('C' + str(total_if_block_counter))

                node_code['C' + str(total_if_block_counter)] = conditional_block_var

                # print(f"TRUE-BLOCK:{stnd_list[-1]}",line_list[list(index_list[index].values())[0] + 1: list(index_list[alter_index].values())[0]])

                true_block_var = []

                node_sequence.append('T' + str(stnd_list[-1]))

                node_code['T' + str(stnd_list[-1])] = "".join(true_block_var)

                true_block_var = ''
                conditional_block_var = ''



            else:
                block_counter = block_counter + 1
                stnd_list.append(block_counter)
                pop_list.append(block_counter)
                # print(pop_list)
                total_if_block_counter = total_if_block_counter + 1

                conditional_block_var = line_list[list(index_list[index].values())[0]]
                node_sequence.append('C' + str(total_if_block_counter))

                node_code['C' + str(total_if_block_counter)] = conditional_block_var

                true_block_var = line_list[
                                 list(index_list[index].values())[0] + 1: list(index_list[alter_index].values())[0]]

                node_sequence.append('T' + str(stnd_list[-1]))

                node_code['T' + str(stnd_list[-1])] = "".join(true_block_var)

                true_block_var = ''
                conditional_block_var = ''
        if IF_VAR in index_list[index] and NELSE_VAR in index_list[alter_index]:
            block_counter = block_counter + 1
            stnd_list.append(block_counter)
            pop_list.append(block_counter)
            # print(pop_list)
            total_if_block_counter = total_if_block_counter + 1

            conditional_block_var = line_list[list(index_list[index].values())[0]]
            node_sequence.append('C' + str(total_if_block_counter))

            node_code['C' + str(total_if_block_counter)] = conditional_block_var

            true_block_var = line_list[
                             list(index_list[index].values())[0] + 1: list(index_list[alter_index].values())[0]]

            node_sequence.append('T' + str(stnd_list[-1]))

            node_code['T' + str(stnd_list[-1])] = "".join(true_block_var)

            true_block_var = ''
            conditional_block_var = ''

        if IF_VAR in index_list[index] and END_IF_VAR in index_list[alter_index]:
            block_counter = block_counter + 1
            stnd_list.append(block_counter)
            pop_list.append(block_counter)
            total_if_block_counter = total_if_block_counter + 1

            conditional_block_var = line_list[list(index_list[index].values())[0]]
            node_sequence.append('C' + str(total_if_block_counter))

            node_code['C' + str(total_if_block_counter)] = conditional_block_var

            conditional_block_var = ''

            true_block_var = line_list[
                             list(index_list[index].values())[0] + 1: list(index_list[alter_index].values())[0]]
            node_sequence.append('T' + str(stnd_list[-1]))

            node_code['T' + str(stnd_list[-1])] = "".join(true_block_var)
            true_block_var = ''
            false_block_count = pop_list[-1]

            node_sequence.append("F" + str(false_block_count))
            node_code['F' + str(false_block_count)] = ""
            pop_list.pop()

        if (ELSE_VAR in index_list[index] and IF_VAR in index_list[alter_index]):
            false_block_var = line_list[
                              list(index_list[index].values())[0] + 1: list(index_list[alter_index].values())[
                                  0]]
            false_block_count = pop_list[-1]
            node_sequence.append("F" + str(false_block_count))
            node_code['F' + str(false_block_count)] = "".join(false_block_var)
            node_sequence.append("N")
            false_block_var = ''
        if (NELSE_VAR in index_list[index] and IF_VAR in index_list[alter_index]):
            # print("coming")
            if list(index_list[index].values())[0] + 1 == list(index_list[alter_index].values())[0]:
                # print("coming1")
                false_block_count = pop_list[-1]
                node_sequence.append("F" + str(false_block_count))
                node_code['F' + str(false_block_count)] = ""
                node_sequence.append("Z")
                pop_list.pop()
                false_block_var = ''

        if (ELSE_VAR in index_list[index] and END_IF_VAR in index_list[alter_index]):
            false_block_var = line_list[
                              list(index_list[index].values())[0] + 1: list(index_list[alter_index].values())[0]]
            if list(index_list[index].values())[0] + 1 == list(index_list[alter_index].values())[0]:
                continue
            else:
                false_block_count = pop_list[-1]
                node_sequence.append("F" + str(false_block_count))
                node_code['F' + str(false_block_count)] = "".join(false_block_var)
                false_block_var = ''
                pop_list.pop()

        if alter_index < len(index_list):

            if (END_IF_VAR in index_list[index] and END_IF_VAR in index_list[alter_index]) or (
                    END_IF_VAR in index_list[index] and ELSE_VAR in index_list[alter_index]) or (
                    END_IF_VAR in index_list[index] and IF_VAR in index_list[alter_index]):

                if list(index_list[index].values())[0] + 1 == list(index_list[alter_index].values())[0]:
                    # if pop_list == []:
                    # print("ERRORCOND --",index_list[index],index_list[alter_index])

                    if END_IF_VAR in index_list[index] and END_IF_VAR in index_list[alter_index]:
                        # print("comin4")
                        # print(node_sequence)
                        if 'F' + str(pop_list[-1]) in node_sequence:
                            if node_code['F' + str(pop_list[-1])] != "":
                                pop_list.pop()
                            else:
                                # print("comin5")

                                pop_list.pop()
                        else:
                            node_sequence.append('F' + str(pop_list[-1]))
                            node_code['F' + str(pop_list[-1])] = ''
                            pop_list.pop()


                    # if (END_IF_VAR in index_list[index] and END_IF_VAR in index_list[
                    #     alter_index]) and pop_list != []:
                    #
                    #     #
                    #     continue
                    else:
                        continue
                else:
                    if (END_IF_VAR in index_list[index] and END_IF_VAR in index_list[alter_index]):
                        group_block_variable = " ".join(
                            line_list[
                            list(index_list[index].values())[0] + 1: list(index_list[alter_index].values())[0]])
                        total_group_block_counter = total_group_block_counter + 1
                        node_sequence.append('G' + str(total_group_block_counter))

                        node_code['G' + str(total_group_block_counter)] = group_block_variable
                        node_sequence.append('F' + str(pop_list[-1]))
                        if 'F' + str(pop_list[-1]) in node_code and node_code['F' + str(pop_list[-1])] != '':
                            pop_list.pop()
                        else:
                            node_code['F' + str(pop_list[-1])] = ''
                            pop_list.pop()
                    else:
                        group_block_variable = " ".join(
                            line_list[
                            list(index_list[index].values())[0] + 1: list(index_list[alter_index].values())[0]])
                        total_group_block_counter = total_group_block_counter + 1
                        node_sequence.append('G' + str(total_group_block_counter))

                        node_code['G' + str(total_group_block_counter)] = group_block_variable

    # print(node_sequence)
    # print(node_code)
    if pop_list != []:
        for iter_pop in pop_list:
            # print(iter_pop)
            false_block_var = ""
            false_block_count = iter_pop
            node_sequence.append("F" + str(false_block_count))
            node_code['F' + str(false_block_count)] = false_block_var
            false_block_var = ''
            # pop_list.pop(iter_pop)
            # print(iter_pop)
    return total_group_block_counter, block_counter, node_sequence, node_code, total_if_block_counter


def code_expansion(filename):
    openFile = open(filename)

    Lines = openFile.readlines()
    MainLines = Lines  # lines are copied to to this variable
    return MainLines


for file_location, file_type in source_file.items():
    for filename in glob.glob(os.path.join(file_location, file_type)):
        # print(filename)
        Lines = code_expansion(filename)
        process_list = endif_tagging_function(Lines)
        paraRepository, para_names = func_separation(process_list)

        keywords_for_if_delimiter = ['ESCAPE', 'ACCEPT', 'NEXT', 'RETURN', 'STOP RUN', 'END-PERFORM', 'CALL', 'MOVE',
                                     'COMPUTE',
                                     'PERFORM',
                                     'ELSE', 'SET', 'IF', 'STRING', 'EXEC', 'ADD', 'WHEN', 'GO', 'NEXT', 'READ',
                                     'DISPLAY',
                                     'CONTINUE', 'WRITE', 'DIVIDE', 'SUBTRACT',
                                     'accept', 'return', 'stop run', 'end-perform', 'call', 'move', 'compute',
                                     'perform',
                                     'else', 'set', 'if', 'exec', 'add', 'when', 'go', 'next', 'read', 'display',
                                     'continue', 'write', 'divide', 'TERMINATE']

        perform_related_keywords = ['THRU', 'UNTIL', 'TIMES', 'VARYING']

        para_list = []
        OUTPUT_DATA = []
        for paragraph_name in para_names:
            if paragraph_name in para_list:
                continue
            else:
                para_list.append(paragraph_name)
        for paragraph_name in para_list:
            if paragraph_name == "":
                continue

            node_code = {}
            node_sequence = []
            parent_if_list = []
            total_if_block_counter = 0
            total_individual_block_counter = 0
            total_group_block_counter = 0
            block_counter = 0

            if_counter = 0
            if_collector_list = []

            endif_counter = 0

            # REWRITE VARIABLES
            rewrite_flag = False
            rewrite_variable = ''

            # DELETE VARIABLES
            delete_flag = False
            delete_variable = ''

            # CALL VARIABLES
            call_flag = False
            call_variable = ''

            # READ VARIABLES
            read_flag = False
            read_variable = ''

            # WRITE VARIABLES
            write_flag = False
            write_variable = ''

            # SET VARIABLES
            set_flag = False
            set_variable = ''

            # GROUP BLOCK
            group_block_flag = False
            group_block_variable = ''

            if_condition_collector_flag = False

            dict = {}
            dict_counter = 0
            for index, line in enumerate(paraRepository[paragraph_name]):
                # print(line)
                if call_flag:
                    if re.match('.*\..*', line, re.IGNORECASE):
                        call_variable = call_variable + '\n' + line
                        node_sequence.append('S' + str(total_individual_block_counter))
                        node_code['S' + str(total_individual_block_counter)] = call_variable
                        call_variable = ''
                        call_flag = False
                        continue
                    if any(ext in line for ext in keywords_for_if_delimiter):
                        call_variable = call_variable + '\n'
                        node_sequence.append('S' + str(total_individual_block_counter))
                        node_code['S' + str(total_individual_block_counter)] = call_variable
                        call_variable = ''
                        call_flag = False


                    else:
                        call_variable = call_variable + '\n' + line
                        continue

                if set_flag:
                    if re.match('.*\..*', line, re.IGNORECASE):
                        set_variable = set_variable + '\n' + line
                        node_sequence.append('S' + str(total_individual_block_counter))
                        node_code['S' + str(total_individual_block_counter)] = set_variable
                        set_variable = ''
                        set_flag = False
                        continue

                    else:
                        set_variable = set_variable + '\n' + line
                        continue

                if write_flag:
                    if re.match('.*end-write.*', line, re.IGNORECASE) or re.match('.*\..*', line, re.IGNORECASE):
                        write_variable = write_variable + '\n' + line
                        node_sequence.append('P' + str(total_individual_block_counter))
                        node_code['P' + str(total_individual_block_counter)] = write_variable
                        write_variable = ''
                        write_flag = False
                        continue

                    else:
                        write_variable = write_variable + '\n' + line
                        continue

                if rewrite_flag:
                    if re.match('.*end-rewrite.*', line, re.IGNORECASE) or re.match('.*\..*', line, re.IGNORECASE):
                        rewrite_variable = rewrite_variable + '\n' + line
                        node_sequence.append('P' + str(total_individual_block_counter))
                        node_code['P' + str(total_individual_block_counter)] = rewrite_variable
                        rewrite_variable = ''
                        rewrite_flag = False
                        continue

                    else:
                        rewrite_variable = rewrite_variable + '\n' + line
                        continue

                if delete_flag:
                    if re.match('.*end-delete.*', line, re.IGNORECASE) or re.match('.*\..*', line, re.IGNORECASE):
                        delete_variable = delete_variable + '\n' + line
                        node_sequence.append('P' + str(total_individual_block_counter))
                        node_code['P' + str(total_individual_block_counter)] = delete_variable
                        delete_variable = ''
                        delete_flag = False
                        continue

                    else:
                        delete_variable = delete_variable + '\n' + line
                        continue

                if read_flag:

                    if (re.match('.*end-read.*', line, re.IGNORECASE) or re.match('.*\.\s*', line, re.IGNORECASE)):
                        read_variable = read_variable + '\n' + line
                        node_sequence.append('P' + str(total_individual_block_counter))
                        node_code['P' + str(total_individual_block_counter)] = read_variable
                        read_variable = ''
                        read_flag = False
                        continue

                    else:
                        read_variable = read_variable + '\n' + line
                        continue

                if if_condition_collector_flag:
                    if re.match('.*end-if.*', line, re.IGNORECASE):
                        endif_counter = endif_counter + 1
                        if_collector_list.append(line.rstrip() + '\n')
                        if if_counter == endif_counter:
                            if_condition_collector_flag = False
                            # print(paragraph_name)
                            total_group_block_counter, block_counter, node_sequence, node_code, total_if_block_counter = if_process_function(
                                if_collector_list, total_group_block_counter, block_counter, node_sequence, node_code,
                                total_if_block_counter)

                            dict[dict_counter] = copy.deepcopy(node_sequence)

                            dict_counter = dict_counter + 1
                            node_sequence.clear()

                            if_collector_list.clear()
                        continue

                    if re.match('.* IF .*', line):
                        if not re.match('.*end-if.*', line, re.IGNORECASE):
                            if_counter = if_counter + 1
                            if_collector_list.append(line.rstrip() + '\n')

                            continue

                    else:
                        if_collector_list.append(line.rstrip() + '\n')
                        continue

                if re.match('.* IF .*', line):
                    if not re.match('.*end-if.*', line, re.IGNORECASE):
                        # new if condition found, increment the global if counter
                        #     print("Line_indexx:", index)
                        # Start collecting the condition
                        if_counter = if_counter + 1
                        parent_if_list.append(if_counter)
                        if_collector_list.append(line.rstrip() + '\n')

                        if_condition_collector_flag = True
                        group_block_flag = False
                        if group_block_variable != '':
                            total_group_block_counter = total_group_block_counter + 1
                            node_sequence.append('G' + str(total_group_block_counter))
                            node_code['G' + str(total_group_block_counter)] = group_block_variable
                            group_block_variable = ''
                        continue

                if re.match('.* delete .*', line, re.IGNORECASE):
                    if not (re.match('.* delete .*end-delete.*', line, re.IGNORECASE) or re.match('.* delete .*\.\s*',
                                                                                                  line, re.IGNORECASE)):
                        delete_variable = ''
                        total_individual_block_counter = total_individual_block_counter + 1
                        # if re.match('.*\.\s*', line):
                        delete_variable = line + '\n'
                        # Set the perform varying collector flag
                        delete_flag = True
                        if group_block_variable != '':
                            total_group_block_counter = total_group_block_counter + 1
                            node_sequence.append('G' + str(total_group_block_counter))
                            node_code['G' + str(total_group_block_counter)] = group_block_variable
                            group_block_variable = ''
                        continue
                    else:
                        group_block_flag = False
                        if group_block_variable != '':
                            total_group_block_counter = total_group_block_counter + 1
                            node_sequence.append('G' + str(total_group_block_counter))
                            node_code['G' + str(total_group_block_counter)] = group_block_variable
                            group_block_variable = ''
                        delete_variable = ''
                        total_individual_block_counter = total_individual_block_counter + 1
                        node_sequence.append('P' + str(total_individual_block_counter))
                        node_code['P' + str(total_individual_block_counter)] = line
                        continue

                if re.match('.* rewrite .*', line, re.IGNORECASE):
                    if not (re.match('.* rewrite .*end-rewrite.*', line, re.IGNORECASE) or re.match(
                            '.* rewrite .*\.\s*', line, re.IGNORECASE)):
                        rewrite_variable = ''
                        total_individual_block_counter = total_individual_block_counter + 1
                        # if re.match('.*\.\s*', line):
                        rewrite_variable = line + '\n'
                        # Set the perform varying collector flag
                        rewrite_flag = True
                        if group_block_variable != '':
                            total_group_block_counter = total_group_block_counter + 1
                            node_sequence.append('G' + str(total_group_block_counter))
                            node_code['G' + str(total_group_block_counter)] = group_block_variable
                            group_block_variable = ''
                        continue
                    else:
                        group_block_flag = False
                        if group_block_variable != '':
                            total_group_block_counter = total_group_block_counter + 1
                            node_sequence.append('G' + str(total_group_block_counter))
                            node_code['G' + str(total_group_block_counter)] = group_block_variable
                            group_block_variable = ''
                        rewrite_variable = ''
                        total_individual_block_counter = total_individual_block_counter + 1
                        node_sequence.append('P' + str(total_individual_block_counter))
                        node_code['P' + str(total_individual_block_counter)] = line
                        continue

                if re.match('.* set .*', line, re.IGNORECASE):
                    if not re.match('.* set .*\..*', line, re.IGNORECASE):
                        set_variable = ''
                        total_individual_block_counter = total_individual_block_counter + 1
                        # if re.match('.*\.\s*', line):
                        set_variable = line + '\n'
                        # Set the perform varying collector flag
                        set_flag = True
                        if group_block_variable != '':
                            total_group_block_counter = total_group_block_counter + 1
                            node_sequence.append('G' + str(total_group_block_counter))
                            node_code['G' + str(total_group_block_counter)] = group_block_variable
                            group_block_variable = ''
                        continue
                    else:
                        if group_block_variable != '':
                            total_group_block_counter = total_group_block_counter + 1
                            node_sequence.append('G' + str(total_group_block_counter))
                            node_code['G' + str(total_group_block_counter)] = group_block_variable
                            group_block_variable = ''
                        set_variable = ''
                        total_individual_block_counter = total_individual_block_counter + 1
                        node_sequence.append('S' + str(total_individual_block_counter))
                        node_code['S' + str(total_individual_block_counter)] = line
                        group_block_flag = False

                        continue

                if re.match('.* read .*', line, re.IGNORECASE):
                    if not (re.match('.* read .*end-read.*', line, re.IGNORECASE) or re.match('.* read.*\..*', line,
                                                                                              re.IGNORECASE)):
                        read_variable = ''
                        total_individual_block_counter = total_individual_block_counter + 1
                        # if re.match('.*\.\s*', line):
                        read_variable = line + '\n'
                        # Set the perform varying collector flag
                        read_flag = True
                        if group_block_variable != '':
                            total_group_block_counter = total_group_block_counter + 1
                            node_sequence.append('G' + str(total_group_block_counter))
                            node_code['G' + str(total_group_block_counter)] = group_block_variable
                            group_block_variable = ''
                        continue
                    else:
                        read_variable = ''
                        if group_block_variable != '':
                            total_group_block_counter = total_group_block_counter + 1
                            node_sequence.append('G' + str(total_group_block_counter))
                            node_code['G' + str(total_group_block_counter)] = group_block_variable
                            group_block_variable = ''
                        total_individual_block_counter = total_individual_block_counter + 1
                        node_sequence.append('P' + str(total_individual_block_counter))
                        node_code['P' + str(total_individual_block_counter)] = line
                        group_block_flag = False
                        continue

                if re.match('.* write .*', line, re.IGNORECASE):
                    if not (re.match('.* write .*end-write.*', line, re.IGNORECASE) or re.match('.* write .*\.\s*',
                                                                                                line, re.IGNORECASE)):
                        write_variable = ''
                        total_individual_block_counter = total_individual_block_counter + 1
                        # if re.match('.*\.\s*', line):
                        write_variable = line + '\n'
                        # Set the perform varying collector flag
                        write_flag = True
                        if group_block_variable != '':
                            total_group_block_counter = total_group_block_counter + 1
                            node_sequence.append('G' + str(total_group_block_counter))
                            node_code['G' + str(total_group_block_counter)] = group_block_variable
                            group_block_variable = ''
                        continue
                    else:
                        group_block_flag = False
                        if group_block_variable != '':
                            total_group_block_counter = total_group_block_counter + 1
                            node_sequence.append('G' + str(total_group_block_counter))
                            node_code['G' + str(total_group_block_counter)] = group_block_variable
                            group_block_variable = ''
                        write_variable = ''
                        total_individual_block_counter = total_individual_block_counter + 1
                        node_sequence.append('P' + str(total_individual_block_counter))
                        node_code['P' + str(total_individual_block_counter)] = line
                        continue

                if re.match('.* call .*', line, re.IGNORECASE):
                    if re.match('.* call .*\.\s*', line, re.IGNORECASE):
                        group_block_flag = False
                        if group_block_variable != '':
                            total_group_block_counter = total_group_block_counter + 1
                            node_sequence.append('G' + str(total_group_block_counter))
                            node_code['G' + str(total_group_block_counter)] = group_block_variable
                            group_block_variable = ''
                        call_variable = ''
                        total_individual_block_counter = total_individual_block_counter + 1
                        node_sequence.append('S' + str(total_individual_block_counter))
                        node_code['S' + str(total_individual_block_counter)] = line

                        continue

                    else:
                        call_variable = ''
                        total_individual_block_counter = total_individual_block_counter + 1
                        # if re.match('.*\.\s*', line):
                        call_variable = line + '\n'
                        # Set the perform varying collector flag
                        call_flag = True
                        if group_block_variable != '':
                            total_group_block_counter = total_group_block_counter + 1
                            node_sequence.append('G' + str(total_group_block_counter))
                            node_code['G' + str(total_group_block_counter)] = group_block_variable
                            group_block_variable = ''
                            continue
                        else:
                            continue

                if line.strip() != '':
                    if line.strip() != '.':
                        group_block_variable = group_block_variable + line + '\n'
                        continue

            if group_block_variable != '':
                total_group_block_counter = total_group_block_counter + 1
                node_sequence.append('G' + str(total_group_block_counter))
                node_code['G' + str(total_group_block_counter)] = group_block_variable
                group_block_variable = ''

            if node_sequence != []:
                dict[dict_counter] = copy.deepcopy(node_sequence)
            node_string = 'st=>start: START | past\ne=>end: END | past \n'
            links_string = 'st'
            missing_list = []
            elseif_list = []
            connector_list = []
            second_connector_list = ""
            dict_keys = []
            dict_values = []

            for keys, values in dict.items():
                dict_keys.append(keys)
                dict_values.append(values)

            if dict == {}:
                position = 0
                for i in range(len(node_sequence)):

                    if re.match('^S.*', node_sequence[i]) or re.match('^G.*', node_sequence[i]):
                        if i + 1 <= len(node_sequence) - 1:
                            if node_sequence[i + 1] in missing_list:
                                connector_list.append(node_sequence[i])
                                links_string = links_string + '->' + node_sequence[i]
                                node_string = node_string + node_sequence[i] + '=>operation: ' + node_code[
                                    node_sequence[i]] + ' | approved\n'
                            else:
                                links_string = links_string + '->' + node_sequence[i] + '\n' + node_sequence[i]
                                node_string = node_string + node_sequence[i] + '=>operation: ' + node_code[
                                    node_sequence[i]] + ' | approved\n'
                        else:
                            links_string = links_string + '->' + node_sequence[i] + '\n' + node_sequence[i]
                            node_string = node_string + node_sequence[i] + '=>operation: ' + node_code[
                                node_sequence[i]] + ' | approved\n'
                    if re.match('^C.*', node_sequence[i]):
                        node_string = node_string + node_sequence[i] + '=>condition: ' + node_code[
                            node_sequence[i]] + ' | rejected\n'
                        c_index = node_sequence.index(node_sequence[i])
                        if node_sequence[c_index + 2] != 'F' + node_sequence[i][1]:
                            missing_list.append('F' + node_sequence[i][1])
                            if node_code['F' + node_sequence[i][1]] != '':
                                links_string = links_string + '->' + node_sequence[i] + '\n' + node_sequence[
                                    i] + '(yes)->' + node_sequence[i + 1]
                                links_string = links_string + '\n' + node_sequence[
                                    i] + '(no)->' + ('F' + node_sequence[i][1])

                        else:
                            if node_code['F' + node_sequence[i][1]] != '':
                                links_string = links_string + '->' + node_sequence[i] + '\n' + node_sequence[
                                    i] + '(yes)->' + \
                                               node_sequence[i + 1]

                                links_string = links_string + '\n' + node_sequence[i] + '(no)->' + node_sequence[i + 2]

                                # if (i + 3) > len(node_sequence):
                                try:
                                    if re.match('^C.*', node_sequence[i + 3]):
                                        connector_list.append(node_sequence[i + 1])
                                    if node_sequence[i + 3] in missing_list:
                                        connector_list.append(node_sequence[i + 1])
                                        connector_list.append(node_sequence[i + 2])
                                    else:
                                        continue
                                except:
                                    continue

                            else:
                                links_string = links_string + '->' + node_sequence[i] + '\n' + node_sequence[
                                    i] + '(yes)->' + \
                                               node_sequence[i + 1]

                                if node_sequence[i + 3] in missing_list:
                                    connector_list.append(node_sequence[i + 1])
                                    connector_list.append(node_sequence[i] + '(no)')

                    if re.match('^T.*', node_sequence[i]):
                        node_string = node_string + node_sequence[i] + '=>operation: ' + node_code[
                            node_sequence[i]] + ' | approved \n'
                        if node_sequence[i] in connector_list:
                            continue

                        if i + 2 <= len(node_sequence) - 1:
                            if re.match('^S.*', node_sequence[i + 2]) or re.match('^G.*', node_sequence[i + 2]):
                                links_string = links_string + '\n' + node_sequence[i] + '->' + node_sequence[i + 2]
                            else:
                                links_string = links_string + '\n' + node_sequence[i]
                        else:
                            connector_list.append(node_sequence[i])

                    if re.match('^F.*', node_sequence[i]):
                        if not node_code[node_sequence[i]].strip() == '':
                            node_string = node_string + node_sequence[i] + '=>operation: ' + node_code[
                                node_sequence[i]] + ' | approved \n'

                        if node_sequence[i] in connector_list:
                            continue
                        if (node_code[node_sequence[i]] == '') and (
                                re.match('^S.*', node_sequence[i + 1]) or re.match('^G.*', node_sequence[i + 1])):
                            links_string = links_string + '\n' + ('C' + node_sequence[i][1]) + '(no)'





                        else:
                            links_string = links_string + '\n' + node_sequence[i]

                if connector_list != []:
                    if (position + 1) in dict:
                        second_connector_list = dict_values[position + 1][0]
                        links_string = links_string + '->' + second_connector_list
                        for iter in connector_list:
                            # print(type(iter))
                            # print(type(links_string), type(second_connector_list))

                            links_string = links_string + '\n' + iter + '->' + second_connector_list
                    else:
                        links_string = links_string + '->' + 'e'
                        for iter in connector_list:
                            links_string = links_string + '\n' + iter + '->' + 'e'
                else:
                    if str(position + 1) in dict and dict != {}:
                        second_connector_list = dict_values[position + 1][0]
                        links_string = links_string + '->' + second_connector_list
                    else:
                        links_string = links_string + '->' + 'e'


            else:
                position = 0

                for dict_key in dict_keys:

                    position = dict_keys.index(dict_key)
                    # print(position)https://github.com/skoppaka-67
                    node_sequence = dict_values[position]

                    connector_list.clear()
                    for i in range(len(node_sequence)):

                        if re.match('^S.*', node_sequence[i]) or re.match('^G.*', node_sequence[i]):
                            if i + 1 <= len(node_sequence) - 1:
                                if node_sequence[i + 1] in missing_list:
                                    connector_list.append(node_sequence[i])
                                    links_string = links_string + '->' + node_sequence[i]
                                    node_string = node_string + node_sequence[i] + '=>operation: ' + node_code[
                                        node_sequence[i]] + ' | approved\n'
                                else:
                                    if re.match('^S.*', node_sequence[i+1]) or re.match('^C.*', node_sequence[i+1]):
                                        links_string = links_string + '->' + node_sequence[i] + '\n' + node_sequence[i]
                                        node_string = node_string + node_sequence[i] + '=>operation: ' + node_code[
                                            node_sequence[i]] + ' | approved\n'
                                    else:
                                        """
                                        If G variable has  F's or N's or Z's as next variable
                                        for loop will find next C or S variable and breaks
                                        """

                                        for next_link_finder in node_sequence[i+1:]:
                                            if re.match('^S.*', next_link_finder) or re.match('^C.*', next_link_finder):
                                                links_string = links_string + '->' + node_sequence[i] + '\n' + \
                                                               node_sequence[i] + '->' + next_link_finder

                                                node_string = node_string + node_sequence[i] + '=>operation: ' + \
                                                              node_code[
                                                                  node_sequence[i]] + ' | approved\n'
                                                break

                            else:
                                links_string = links_string + '->' + node_sequence[i] + '\n' + node_sequence[i]
                                node_string = node_string + node_sequence[i] + '=>operation: ' + node_code[
                                    node_sequence[i]] + ' | approved\n'
                        if re.match('^C.*', node_sequence[i]):
                            node_string = node_string + node_sequence[i] + '=>condition: ' + node_code[
                                node_sequence[i]] + ' | rejected\n'
                            c_index = node_sequence.index(node_sequence[i])
                            if c_index + 2 <= len(node_sequence) - 1:
                                if node_sequence[c_index + 2] != 'F' + node_sequence[i][1:]:
                                    missing_list.append('F' + node_sequence[i][1])
                                    if node_code['F' + node_sequence[i][1:]] != '':
                                        if node_code['T' + node_sequence[i][1:]] != '':

                                            links_string = links_string + '->' + node_sequence[i] + '\n' + \
                                                           node_sequence[
                                                               i] + '(yes)->' + node_sequence[i + 1]
                                            links_string = links_string + '\n' + node_sequence[
                                                i] + '(no)->' + ('F' + node_sequence[i][1:])
                                        else:
                                            links_string = links_string + '->' + node_sequence[i] + '\n' + \
                                                           node_sequence[
                                                               i] + '(yes)->' + node_sequence[i + 2]
                                            links_string = links_string + '\n' + node_sequence[
                                                i] + '(no)->' + ('F' + node_sequence[i][1:])
                                    else:
                                        if node_code['T' + node_sequence[i][1:]] != '':
                                            links_string = links_string + '->' + node_sequence[i] + '\n' + \
                                                           node_sequence[
                                                               i] + '(yes)->' + node_sequence[i + 1]
                                            f_index = node_sequence.index('F' + node_sequence[i][1:])
                                            if f_index + 1 <= len(node_sequence) - 1:
                                                if node_sequence[f_index + 1] in missing_list:
                                                    connector_list.append(node_sequence[i] + '(no)')
                                                else:
                                                    if node_sequence[f_index + 1] == 'Z' or node_sequence[
                                                        f_index + 1] == 'N':
                                                        if f_index + 2 <= len(node_sequence) - 1:
                                                            links_string = links_string + '\n' + node_sequence[
                                                                i] + '(no)->' + (node_sequence[f_index + 2])
                                                        else:
                                                            links_string = links_string + '\n' + node_sequence[
                                                                i] + '(no)->' + '->' + 'e'

                                                    else:
                                                        links_string = links_string + '\n' + node_sequence[
                                                            i] + '(no)->' + (node_sequence[f_index + 1])
                                            else:
                                                if node_code[node_sequence[f_index]] == '':
                                                    continue
                                                else:
                                                    connector_list.append(node_sequence[i] + '(no)')

                                        else:

                                            links_string = links_string + '->' + node_sequence[i] + '\n' + \
                                                           node_sequence[
                                                               i] + '(yes)->' + node_sequence[i + 2]
                                            f_index = node_sequence.index('F' + node_sequence[i][1:])
                                            if f_index + 1 <= len(node_sequence) - 1:
                                                if node_sequence[f_index + 1] in missing_list:
                                                    connector_list.append(node_sequence[i] + '(no)')
                                                else:
                                                    if re.search('.*N.*', node_sequence[f_index + 1]):
                                                        links_string = links_string + '\n' + node_sequence[
                                                            i] + '(no)->' + (node_sequence[f_index + 2])

                                                    else:
                                                        if node_code[node_sequence[f_index+1]] != ''and re.search('.*F.*', node_sequence[f_index+1]):
                                                            connector_list.append(node_sequence[i] + '(no)')

                                                        else:

                                                            if  node_code[node_sequence[f_index+1]] == '' and  node_code['T' + node_sequence[i][1:]] == '':
                                                               continue

                                                            else:

                                                                links_string = links_string + '\n' + node_sequence[
                                                                    i] + '(no)->' + (node_sequence[f_index + 1])
                                            else:
                                                connector_list.append(node_sequence[i] + '(no)')


                                else:
                                    if node_code['F' + node_sequence[i][1:]] != '':
                                        if node_code['T' + node_sequence[i][1:]] != '':
                                            links_string = links_string + '->' + node_sequence[i] + '\n' + \
                                                           node_sequence[
                                                               i] + '(yes)->' + \
                                                           node_sequence[i + 1]
                                            if i + 3 <= len(node_sequence) - 1:
                                                if re.search('.*Z.*', node_sequence[i + 3]):
                                                    links_string = links_string + '\n' + node_sequence[i] + '(no)->' + \
                                                                   node_sequence[
                                                                       i + 4]
                                                else:
                                                    links_string = links_string + '\n' + node_sequence[i] + '(no)->' + \
                                                                   node_sequence[
                                                                       i + 2]
                                            else:

                                                if node_sequence[i + 2] == 'F' + node_sequence[i][1:]:
                                                    links_string = links_string + '\n' + node_sequence[i] + '(no)->' + \
                                                                   node_sequence[
                                                                       i + 2]

                                        else:

                                            if i + 3 > len(node_sequence)-1:
                                                links_string = links_string + '->' + node_sequence[i] + '\n' + \
                                                               node_sequence[
                                                                   i] + '(yes)->' + \
                                                               node_sequence[-1]

                                                f_index = node_sequence.index('F' + node_sequence[i][1:])
                                                if f_index + 1 <= len(node_sequence) - 1:
                                                    if node_sequence[f_index + 1] in missing_list:
                                                        connector_list.append(node_sequence[i] + '(no)')
                                                    else:
                                                        links_string = links_string + '\n' + node_sequence[
                                                            i] + '(no)->' + (node_sequence[f_index + 1])
                                                else:
                                                    connector_list.append(node_sequence[i] + '(no)')
                                            else:
                                                links_string = links_string + '->' + node_sequence[i] + '\n' + \
                                                               node_sequence[
                                                                   i] + '(yes)->' + \
                                                               node_sequence[i +3]

                                                f_index = node_sequence.index('F' + node_sequence[i][1:])
                                                if f_index + 1 <= len(node_sequence) - 1:
                                                    if node_sequence[f_index + 1] in missing_list:
                                                        connector_list.append(node_sequence[i] + '(no)')
                                                    else:
                                                        links_string = links_string + '\n' + node_sequence[
                                                            i] + '(no)->' + (node_sequence[f_index + 1])
                                                else:
                                                    connector_list.append(node_sequence[i] + '(no)')


                                            # if (i + 3) > len(node_sequence):
                                            # try:
                                            #     if re.match('^C.*', node_sequence[i + 3]):
                                            #         connector_list.append(node_sequence[i + 1])
                                            #     if node_sequence[i + 3] in missing_list:
                                            #         connector_list.append(node_sequence[i + 1])
                                            #         connector_list.append(node_sequence[i + 2])
                                            #     else:
                                            #         continue
                                            # except:
                                            #     continue



                                    else:
                                        if node_code['T' + node_sequence[i][1:]] != "":
                                            links_string = links_string + '->' + node_sequence[i] + '\n' + \
                                                           node_sequence[
                                                               i] + '(yes)->' + \
                                                           node_sequence[i + 1]
                                            f_index = node_sequence.index('F' + node_sequence[i][1:])
                                            if f_index + 1 <= len(node_sequence) - 1:
                                                if node_sequence[f_index + 1] in missing_list:
                                                    connector_list.append(node_sequence[i] + '(no)')
                                                elif re.search('.*Z.*', node_sequence[f_index + 1]):
                                                    links_string = links_string + '\n' + node_sequence[i] + '(no)->' + \
                                                                   node_sequence[
                                                                       f_index + 2]
                                                elif re.search('.*N.*', node_sequence[f_index + 1]):
                                                    links_string = links_string + '\n' + node_sequence[i] + '(no)->' + \
                                                                   node_sequence[
                                                                       f_index + 2]
                                                else:
                                                    links_string = links_string + '\n' + node_sequence[
                                                        i] + '(no)->' + (node_sequence[f_index + 1])
                                            else:
                                                connector_list.append(node_sequence[i] + '(no)')
                                        else:
                                            f_index = node_sequence.index('F' + node_sequence[i][1:])
                                            if f_index + 1 <= len(node_sequence) - 1:
                                                if node_sequence[f_index + 1] in missing_list:
                                                    connector_list.append(node_sequence[i] + '(yes)')
                                                    connector_list.append(node_sequence[i] + '(no)')
                                                else:
                                                    links_string = links_string + '\n' + node_sequence[
                                                        i] + '(yes)->' + (node_sequence[f_index + 1])
                                                    links_string = links_string + '\n' + node_sequence[
                                                        i] + '(no)->' + (node_sequence[f_index + 1])
                                            else:
                                                connector_list.append(node_sequence[i] + '(yes)')
                                                connector_list.append(node_sequence[i] + '(no)')

                                        # if node_sequence[i + 3] in missing_list:
                                        #     connector_list.append(node_sequence[i + 1])
                                        #     connector_list.append(node_sequence[i] + '(no)')
                            else:
                                links_string = links_string + '\n' + node_sequence[
                                    i] + '(no)->' + '->' + 'e'

                        if re.match('^T.*', node_sequence[i]):

                            node_string = node_string + node_sequence[i] + '=>operation: ' + node_code[
                                node_sequence[i]] + ' | approved \n'
                            if 'C' + node_sequence[i][1:] + '(yes)' in connector_list:
                                continue
                            if node_code[node_sequence[i]] == "":
                                continue

                            if i + 2 <= len(node_sequence) - 1:
                                if node_sequence[i + 2] == 'N':
                                    connector_list.append(node_sequence[i])
                                    continue
                                if node_sequence[i + 2] == 'Z':
                                    connector_list.append(node_sequence[i])
                                    continue
                                if node_sequence[i + 2] in missing_list:
                                    connector_list.append(node_sequence[i])
                                    continue

                                """
                                Not working with all cases 
                                """

                                if re.match('^S.*', node_sequence[i + 2]) or re.match('^G.*', node_sequence[i + 2]) and (node_sequence[i+2] in node_code and node_code[node_sequence[i+2]] !=''):
                                    node_string = node_string + node_sequence[i+2] + '=>operation: ' + node_code[
                                        node_sequence[i+2]] + ' | approved \n'
                                    links_string = links_string + '\n' + node_sequence[i] + '->' + node_sequence[i + 2]
                                    continue

                            if i == len(node_sequence) - 2 or re.match('^F.*', node_sequence[i + 2]) :
                                connector_list.append(node_sequence[i])
                            else:

                                links_string = links_string + '\n' + node_sequence[i]
                            # if node_sequence[i] in connector_list:
                            #     continue

                            # if i + 2 <= len(node_sequence) - 1:
                            #     if re.match('^S.*', node_sequence[i + 2]) or re.match('^G.*', node_sequence[i + 2]):
                            #         links_string = links_string + '\n' + node_sequence[i] + '->' + node_sequence[i + 2]
                            #     else:
                            #         links_string = links_string + '\n' + node_sequence[i]
                            # else:
                            #     connector_list.append(node_sequence[i])

                        if re.match('^F.*', node_sequence[i]):

                            if not node_code[node_sequence[i]].strip() == '':
                                node_string = node_string + node_sequence[i] + '=>operation: ' + node_code[
                                    node_sequence[i]] + ' | approved \n'
                            if 'C' + node_sequence[i][1:] + '(no)' in connector_list or "F" + node_sequence[
                                i] in connector_list:
                                continue

                            if i + 1 == len(node_sequence) - 1:
                                if node_sequence[i + 1] in missing_list:
                                    connector_list.append(node_sequence[i])
                                    continue
                                else:
                                    if node_code[node_sequence[i]] == "":
                                        continue
                                    else:
                                        connector_list.append(node_sequence[i])
                            else:
                                if i == len(node_sequence) - 1:
                                    if node_code[node_sequence[i]] == "":
                                        if not int(str(position + 1))  in dict and dict != {}:
                                            last_correct_link = links_string.split("->")[-1]
                                            links_string = links_string + '\n' + last_correct_link + '->' + 'e'

                                        else:
                                            continue




                                    else:
                                        connector_list.append(node_sequence[i])
                                        continue
                                if node_code[node_sequence[i]] == "":
                                    continue
                                else:
                                    links_string = links_string + '\n' + node_sequence[i]
                                    continue
                            # if node_code[node_sequence[i]] =="":
                            #     continue
                            # else:
                            #     links_string = links_string + '\n' + node_sequence[i]
                            # if node_sequence[i] in connector_list:
                            #     continue
                            # if (node_code[node_sequence[i]] == '') and (
                            #         re.match('^S.*', node_sequence[i + 1]) or re.match('^G.*', node_sequence[i + 1])):
                            #     links_string = links_string + '\n' + ('C' + node_sequence[i][1]) + '(no)'

                    if connector_list != []:
                        if (position + 1) in dict:
                            second_connector_list = dict_values[position + 1][0]
                            links_string = links_string + '->' + second_connector_list
                            for iter in connector_list:
                                # print(type(iter))
                                # print(type(links_string), type(second_connector_list))

                                links_string = links_string + '\n' + iter + '->' + second_connector_list
                        else:
                            links_string = links_string + '->' + 'e'
                            for iter in connector_list:
                                links_string = links_string + '\n' + iter + '->' + 'e'
                    else:
                        if str(position + 1) in dict and dict != {}:
                            second_connector_list = dict_values[position + 1][0]
                            links_string = links_string + '->' + second_connector_list
                        else:
                            if node_code[node_sequence[-1]] == '':
                                continue
                            else:

                                links_string = links_string + '->' + 'e'

                            




                OUTPUT_DATA.append({"option": node_string + '\n' + links_string,
                                    "component_name": filename.split("\\")[-1],
                                    "para_name": paragraph_name})

                print("*****************")
                print(paragraph_name)

                print('\n')

                print(node_string)
                print('\n')
                print(links_string)


                node_sequence.clear()
                node_string = ''
                links_string = ''
                connector_list.clear()
                elseif_list.clear()


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
            print('Error:' + str(e),filename)

        # print(paragraph_name)

