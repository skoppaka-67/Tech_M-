SCRIPT_VERSION = 'Werner coustmized code '

from pymongo import MongoClient
import pytz
import datetime,json
import config
from os.path import join,isfile

global counter
counter = 1

import copy

time_zone = 'Asia/Calcutta'
tz = pytz.timezone(time_zone)
import glob,os,re

# client = MongoClient(config.database['hostname'])
client = MongoClient('localhost', 27017)
db = client[config.database['database_name']]
# # file ={ 'D:\AS400*\RPG': '*.RPG'}
base_location = config.codebase_information['code_location']
cobolfolder = config.codebase_information['COBOL']['folder_name']
# includefolder = config.codebase_information['INCLUDE']['folder_name']
copybookfolder = config.codebase_information['COPYBOOK']['folder_name']
extention = "." + config.codebase_information['COBOL']['extension']
# extention2 = "." + config.codebase_information['INCLUDE']['extension']
extention3 = "." + config.codebase_information['COPYBOOK']['extension']

file ={ 'D:\\WORK\\IMS\\COBOL': '*.cbl'}


# db = client['ver']

source_file = file

# source_file = aps_config.file

def endif_tagging_function(filename):

    process_list = []
    index_list = []


        # for append_lines in check_list:
        #     append_lines = append_lines
        #     if append_lines.strip() == "":  ### ignore the blank lines
        #         continue
        #     if append_lines[0] == "*":
        #         continue
        #     temporary_variable = append_lines
        #     temporary_variable = temporary_variable.strip()
        #     # print(temporary_variable)
        #     main_index = append_lines.index(temporary_variable)
        #     if re.search('IF\s.*',append_lines):
        #
        #         index_list.append(main_index)
        #         print(append_lines)
        #         continue
        #     if index_list[-1] >= main_index:
        #         if index_list[-1] == main_index:
        #             print("END IF")
        #             print(append_lines)
        #             del index_list[-1]
        #         elif index_list[-1] > main_index:
        #             print("END IF")
        #             print(append_lines)
        #             del index_list[-1]
        #             try:
        #                 for list_iter in index_list.reverse():
        #                     if index_list[-1] == main_index:
        #                         print("END IF")
        #                         print(append_lines)
        #                         del index_list[-1]
        #                     elif index_list[-1] > main_index:
        #                         print("END IF")
        #                         print(append_lines)
        #                         del index_list[-1]
        #             except:
        #                 pass

        # print(index_list)
        # # if if_collecting_flag:
        # #     if append_lines[main_if_index] != " " and not re.search('.* end if.*',append_lines,re.IGNORECASE) and not re.search('.* elseif.*',append_lines,re.IGNORECASE) and not re.search('.* else .*',append_lines,re.IGNORECASE):
        # #         process_list.append('\n' + " End If\n")
        # #         process_list.append(append_lines)
        # #         if_collecting_flag = False
        # #         continue
        # #     elif re.search('^\s*If\s.*', append_lines):
        # #         main_if_index = append_lines.index("IF ")
        # #         process_list.append(append_lines)
        # #         index_list.append(main_if_index)
        #
        #
        # if re.search('^\s*If.*', append_lines):
        #     main_if_index = append_lines.index("IF ")
        #     process_list.append(append_lines)
        #     index_list.append(main_if_index)
        #     if_collecting_flag = True
        #     continue
        # else:
        #     process_list.append(append_lines)
        #     continue
    for append_lines in filename:
        append_lines = append_lines[6:72]
        if append_lines.strip() == "":  ### ignore the blank lines
            continue
        if append_lines[0] == "*":
            continue
        if append_lines.strip().startswith('...'):
            # print(append_lines)
            process_list.append(append_lines)
            continue
        # temporary_variable = append_lines
        # temporary_variable = temporary_variable.strip()
        # main_index = append_lines.index(temporary_variable)
        # if append_lines.strip().startswith("ELSE"):
        #     if len(index_list) > 0:
        #         if index_list[-1] > main_index:
        #             # print(" " * index_list[-1] + "END IF")
        #             process_list.append(" " * index_list[-1] + "END-IF")
        #             del index_list[-1]
        #             data = len(index_list)
        #             for list_iter in range(data):
        #                 if index_list[-1] == main_index:
        #                     break
        #                 elif index_list[-1] > main_index:
        #                     # print(" " * index_list[-1] + "END IF")
        #                     process_list.append(" " * index_list[-1] + "END-IF")
        #                     del index_list[-1]
        #
        # if append_lines.strip().startswith("ELSE"):
        #     # print(append_lines)
        #     process_list.append(append_lines)
        #     continue
        #
        # if re.search('IF\s.*', append_lines):
        #
        #     flag = True
        #     if len(index_list) > 0:
        #         if index_list[-1] >= main_index:
        #             if index_list[-1] == main_index:
        #                 flag = False
        #                 # print(" " * index_list[-1] + "END IF")
        #                 process_list.append(" " * index_list[-1] + "END-IF")
        #                 process_list.append(append_lines)
        #                 # print(append_lines)
        #                 del index_list[-1]
        #             elif index_list[-1] > main_index:
        #                 # print(" " * index_list[-1] + "END IF")
        #                 process_list.append(" " * index_list[-1] + "END-IF")
        #                 del index_list[-1]
        #                 data = len(index_list)
        #                 for list_iter in range(data):
        #                     if index_list[-1] == main_index:
        #                         # print(" " * index_list[-1] + "END IF")
        #                         if append_lines.strip().startswith("IF "):
        #                             flag = False
        #                         process_list.append(" " * index_list[-1] + "END-IF")
        #                         process_list.append(append_lines)
        #                         # print(append_lines)
        #                         del index_list[-1]
        #                     elif index_list[-1] > main_index:
        #                         process_list.append(" " * index_list[-1] + "END-IF")
        #                         # print(" " * index_list[-1] + "END IF")
        #                         del index_list[-1]
        #
        #     index_list.append(main_index)
        #
        #     if flag:
        #         # print("MMM",append_lines)
        #         process_list.append(append_lines)
        #     continue
        #
        # if len(index_list) > 0:
        #     if index_list[-1] >= main_index:
        #         if index_list[-1] == main_index:
        #             # print(" " * index_list[-1] + "END IF")
        #             # print(append_lines)
        #             process_list.append(" " * index_list[-1] + "END-IF")
        #             process_list.append(append_lines)
        #             del index_list[-1]
        #         elif index_list[-1] > main_index:
        #             # print(" " * index_list[-1] + "END IF")
        #             process_list.append(" " * index_list[-1] + "END-IF")
        #             # process_list.append(append_lines)
        #             # print(append_lines)
        #             del index_list[-1]
        #             data = len(index_list)
        #             for list_iter in range(data):
        #                 if index_list[-1] == main_index:
        #                     # print(" " * index_list[-1] + "END IF")
        #                     # print(append_lines)
        #                     process_list.append(" " * index_list[-1] + "END-IF")
        #
        #                     del index_list[-1]
        #                 elif index_list[-1] > main_index:
        #                     # print(" " * index_list[-1] + "END IF")
        #                     process_list.append(" " * index_list[-1] + "END-IF")
        #                     del index_list[-1]
        #             process_list.append(append_lines)
        #     else:
        #         # print(append_lines)
        #         process_list.append(append_lines)
        # # else:
        # #     # print(append_lines)
        process_list.append(append_lines)

    return process_list

def func_separation(process_list):

    '''instead of hardcoding, we are assigning it as a varaible'''
    para_names = []
    paraRepository = {}
    procedure_flag = False
    storage = []
    current_para = ""

    for line_counter, line in enumerate(process_list):
        # print(line)

        if not re.match('.*eject.*', line, re.IGNORECASE):
            if not re.match('.*\sexit\s.*', line, re.IGNORECASE):
                if not re.match('.* skip1.*', line, re.IGNORECASE):
                    if not re.match('.* skip2.*', line, re.IGNORECASE):
                        if not re.match('.* skip3.*', line, re.IGNORECASE):
                            # If the 8th position is not empty, it must the delcatation of a paragraph
                            # print("Line00000000000000:",line[0])

                            if line[1] != ' ' and procedure_flag == True:


                                prev_para = current_para
                                current_para = line.split()[0]
                                current_para = current_para.replace('.', '')

                                para_names.append(current_para)

                                if prev_para == '':
                                    para_names.append('00-MAIN')
                                    paraRepository['00-MAIN'] = copy.deepcopy(storage)
                                    storage.clear()
                                    continue


                                else:

                                    paraRepository[prev_para] = copy.deepcopy(storage)
                                    storage.clear()
                                    continue


                            if procedure_flag:
                                storage.append(line)
                                continue

                            if re.search('.*PROCEDURE DIVISION.*',line,re.IGNORECASE):
                                procedure_flag = True
                                continue



    procedure_flag = False
    paraRepository[current_para] = copy.deepcopy(storage)

    # print("Para_names:", para_names)
    # print("Checking:", json.dumps(paraRepository, indent=4))


    return paraRepository, para_names

def if_process_function(line_list,total_group_block_counter, block_counter, node_sequence, node_code, total_if_block_counter):
    IF_VAR = "IF "
    ELSE_VAR = " ELSE "
    END_IF_VAR = "END-IF"
    ELSE_IF_VAR = "ELSE-IF"

    #
    index_list = []
    # print("Checking:", json.dumps(line_list, indent=4))
    for index, line in enumerate(line_list):
        if re.search('.*\sIF\s.*',line):
            # print("IF" ,line,index)
            index_list.append({IF_VAR: index})

        if re.search('.*ELSE\s.*',line):
            index_list.append({ELSE_VAR: index})

        if re.search('.*ELSE-IF\s.*',line):
            index_list.append({ELSE_IF_VAR.strip(): index})

        if re.search('.*' + END_IF_VAR + '.*', line):
            # print("END --->", line_list[index],index)
            index_list.append({END_IF_VAR: index})
    global counter
    counter = counter + 1
    # print("----->",counter)
    # print(counter,json.dumps(index_list, indent=4))

    stnd_list = []
    pop_list = []
    node_string = 'st=>start: START | past\ne=>end: END | past \n'
    links_string = 'st'
    for index, iter in enumerate(index_list):

        alter_index = index + 1

        if (IF_VAR in index_list[index] and IF_VAR in index_list[alter_index]) or (
                IF_VAR in index_list[index] and ELSE_VAR in index_list[alter_index]) \
                or (
                ELSE_IF_VAR in index_list[index] and ELSE_IF_VAR in index_list[alter_index]) \
                or (
                IF_VAR in index_list[index] and ELSE_IF_VAR in index_list[alter_index]) \
                or (
                ELSE_IF_VAR in index_list[index] and ELSE_VAR in index_list[alter_index]):


            if list(index_list[index].values())[0] + 1 == list(index_list[alter_index].values())[0]:
                block_counter = block_counter + 1
                stnd_list.append(block_counter)
                pop_list.append(block_counter)
                # print(pop_list)
                total_if_block_counter = total_if_block_counter + 1
                conditional_block_var = line_list[list(index_list[index].values())[0]]
                node_sequence.append('C' + str(total_if_block_counter))
                node_code['C' + str(total_if_block_counter)] = conditional_block_var

                # print(f"TRUE-BLOCK:{​​stnd_list[-1]}​​",line_list[list(index_list[index].values())[0] + 1: list(index_list[alter_index].values())[0]])
                true_block_var = ''
                node_sequence.append('T' + str(stnd_list[-1]))
                node_code['T' + str(stnd_list[-1])] = true_block_var

                true_block_var = ''
                conditional_block_var = ''
            else:
                block_counter = block_counter + 1
                stnd_list.append(block_counter)
                pop_list.append(block_counter)
                total_if_block_counter = total_if_block_counter + 1

                # print(f'Cond:{stnd_list[-1]}', line_list[list(index_list[index].values())[0]])

                conditional_block_var = line_list[list(index_list[index].values())[0]]
                node_sequence.append('C' + str(total_if_block_counter))
                str1 = ""
                conditional_block_var = str1.join(conditional_block_var)
                node_code['C' + str(total_if_block_counter)] = conditional_block_var

                # print(f"TRUE-BLOCK:{stnd_list[-1]}",line_list[list(index_list[index].values())[0] + 1: list(index_list[alter_index].values())[0]])

                true_block_var = line_list[
                                 list(index_list[index].values())[0] + 1: list(index_list[alter_index].values())[0]]

                node_sequence.append('T' + str(stnd_list[-1]))
                str1 = ""
                true_block_var = str1.join(true_block_var)
                node_code['T' + str(stnd_list[-1])] = true_block_var



                true_block_var = ''
                conditional_block_var = ''

        if IF_VAR in index_list[index] and END_IF_VAR in index_list[alter_index] \
                or ELSE_IF_VAR in index_list[index] and END_IF_VAR in index_list[alter_index]:
            block_counter = block_counter + 1
            stnd_list.append(block_counter)
            pop_list.append(block_counter)
            total_if_block_counter = total_if_block_counter + 1

            # print(f'Cond:{stnd_list[-1]}', line_list[list(index_list[index].values())[0]])
            conditional_block_var = line_list[list(index_list[index].values())[0]]
            node_sequence.append('C' + str(total_if_block_counter))
            str1 = ""
            conditional_block_var = str1.join(conditional_block_var)
            node_code['C' + str(total_if_block_counter)] = conditional_block_var

            conditional_block_var = ''

            # print(f"TRUE-BLOCK:{stnd_list[-1]}",
            #       line_list[list(index_list[index].values())[0] + 1: list(index_list[alter_index].values())[0]])

            true_block_var = line_list[
                             list(index_list[index].values())[0] + 1: list(index_list[alter_index].values())[0]]
            node_sequence.append('T' + str(stnd_list[-1]))
            str1 = ""
            true_block_var = str1.join(true_block_var)
            node_code['T' + str(stnd_list[-1])] = true_block_var
            true_block_var = ''
            false_block_count = pop_list.pop()
            # print(f"FALSE-BLOCK:{false_block_count}", [])
            node_sequence.append("F" + str(false_block_count))
            node_code['F' + str(false_block_count)] = ''



        if (ELSE_VAR in index_list[index] and IF_VAR in index_list[alter_index]) or (
                ELSE_VAR in index_list[index] and END_IF_VAR in index_list[alter_index]) :
            false_block_var = line_list[
                              list(index_list[index].values())[0] + 1: list(index_list[alter_index].values())[0]]

            # print(f"FALSE-BLOCK:{pop_list.pop()}", [])
            false_block_count = pop_list.pop()
            node_sequence.append("F" + str(false_block_count))
            str1 = ""
            false_block_var = str1.join(false_block_var)
            node_code['F' + str(false_block_count)] = false_block_var
            false_block_var = ''

            # print(f"FALSE-BLOCK:{pop_list.pop()}",
            #       line_list[list(index_list[index].values())[0] + 1: list(index_list[alter_index].values())[0]])

        if alter_index < len(index_list):
            if (END_IF_VAR in index_list[index] and END_IF_VAR in index_list[alter_index]) or (
                    END_IF_VAR in index_list[index] and ELSE_IF_VAR in index_list[alter_index]) or (
                    END_IF_VAR in index_list[index] and ELSE_VAR in index_list[alter_index]) or\
                    (END_IF_VAR in index_list[index] and IF_VAR in index_list[alter_index]):

                if list(index_list[index].values())[0] + 1 == list(index_list[alter_index].values())[0]:
                    if (END_IF_VAR in index_list[index] and END_IF_VAR in index_list[alter_index] ) :
                        try:
                            if not ELSE_VAR in index_list[alter_index + 1]:
                                false_block_count = pop_list.pop()
                                # print(f"FALSE-BLOCK:{false_block_count}", [])
                                node_sequence.append("F" + str(false_block_count))
                                node_code['F' + str(false_block_count)] = ''
                        except:
                            continue
                    else:
                        continue
                else:
                    # print(f"Group-BLOCK:{block_counter}", )
                    group_block_variable = " ".join(
                        line_list[
                        list(index_list[index].values())[0] + 1: list(index_list[alter_index].values())[0]])
                    total_group_block_counter = total_group_block_counter + 1
                    node_sequence.append('G' + str(total_group_block_counter))

                    node_code['G' + str(total_group_block_counter)] = group_block_variable
                    group_block_variable = ''

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

    # node_string = 'st=>start: START | past\ne=>end: END | past \n'
    # links_string = 'st'
    #
    # sorted_node_sequence = []
    # sorted_node_sequence = node_sequence.sort()
    #
    # print(sorted_node_sequence)
    # # for i in range(0, len(node_sequence)):








    # def connections(node_sequence,node_code):
    #     node_string = 'st=>start: START | past\ne=>end: END | past \n'
    #     links_string = 'st'
    #     try:
    #         for i in range(0, len(node_sequence)):
    #             # Make sure the leading line breaks are STRIPPED
    #             node_code[node_sequence[i]] = node_code[node_sequence[i]].lstrip('\n')
    #             node_code[node_sequence[i]] = node_code[node_sequence[i]].replace('=>', '= >')
    #
    #             if re.match('^S.*', node_sequence[i]) or re.match('^G.*', node_sequence[i]):
    #                 links_string = links_string + '->' + node_sequence[i] + '\n' + node_sequence[i]
    #                 node_string = node_string + node_sequence[i] + '=>operation: ' + node_code[
    #                     node_sequence[i]] + ' | approved\n'
    #             if re.match('^C.*', node_sequence[i]):
    #                 node_string = node_string + node_sequence[i] + '=>condition: ' + node_code[
    #                     node_sequence[i]] + ' | rejected\n'
    #
    #                 # If condition is the last block, end it with the (e) node
    #                 if (i + 3) >= len(node_sequence):
    #
    #                     if node_code[node_sequence[i + 2]] == '':
    #                         # If else part does nto exist
    #                         links_string = links_string + '->' + node_sequence[i] + '\n' + node_sequence[
    #                             i] + '(yes)->' + node_sequence[i + 1]
    #                         links_string = links_string + '\n' + node_sequence[i + 1] + '->e'
    #                         links_string = links_string + '\n' + node_sequence[i] + '(no)'
    #
    #                         # links_string = links_string + '\n' + node_sequence[i] + '(no)'
    #                         # links_string = links_string + node_sequence[i + 2]
    #                     else:
    #                         # Else parts
    #                         links_string = links_string + '->' + node_sequence[i] + '\n' + node_sequence[
    #                             i] + '(yes)->' + node_sequence[i + 1] + '\n' + node_sequence[i] + '(no)->' + \
    #                                        node_sequence[i + 2] + '\n' + node_sequence[i + 1] + '->e' + '\n' + \
    #                                        node_sequence[i + 2]
    #
    #                         # links_string = links_string + '\n' + node_sequence[i] + '(no)'
    #
    #
    #
    #                 else:
    #                     # If the conditions is not the last, check if has ELSE part
    #                     if node_code[node_sequence[i + 2]] == '':
    #                         # If there is not else part
    #                         links_string = links_string + '->' + node_sequence[i] + '\n' + node_sequence[
    #                             i] + '(yes)'
    #                         links_string = links_string + '->' + node_sequence[i + 1] + '\n' + node_sequence[
    #                             i] + '(no)'
    #                         links_string = links_string + '->' + node_sequence[i + 3] + '\n' + node_sequence[i + 1]
    #
    #                     else:
    #                         # If there is an else part, behave normally
    #                         links_string = links_string + '->' + node_sequence[i] + '\n' + node_sequence[
    #                             i] + '(yes)'
    #                         links_string = links_string + '->' + node_sequence[i + 1] + '\n' + node_sequence[
    #                             i] + '(no)'
    #                         links_string = links_string + '->' + node_sequence[i + 2]
    #                         links_string = links_string + '\n' + node_sequence[i + 1] + '->' + node_sequence[i + 3]
    #                         links_string = links_string + '\n' + node_sequence[i + 2] + '->' + node_sequence[i + 3]
    #                         # links_string =  links_string + '\n'+node_sequence[i + 1]+ '->' +node_sequence[i + 3]
    #                         # links_string = '\n'+ node_sequence[i + 2]
    #
    #                 # try:
    #                 #     links_string = links_string + node_sequence[i + 1] + '->' + node_sequence[i + 3] + '\n'
    #                 #     links_string = links_string + node_sequence[i + 2] + '->' + node_sequence[i + 3]
    #                 # except:
    #                 #     links_string = links_string + node_sequence[i + 1] + '->e' + '\n'
    #                 #     links_string = links_string + node_sequence[i + 2]
    #                 #     # print('List terminated. No more nodes')
    #                 #
    #                 #
    #
    #             if re.match('^T.*', node_sequence[i]):
    #                 node_string = node_string + node_sequence[i] + '=>operation: ' + node_code[
    #                     node_sequence[i]] + ' | approved \n'
    #                 continue
    #             if re.match('^F.*', node_sequence[i]):
    #                 # links_string = links_string+ '\n' + node_sequence[i]
    #                 # Experimental remove IF condition if it fails
    #                 if not node_code[node_sequence[i]].strip() == '':
    #                     node_string = node_string + node_sequence[i] + '=>operation: ' + node_code[
    #                         node_sequence[i]] + ' | approved \n'
    #
    #                 continue
    #
    #     except Exception as e:
    #         print(str(e))
    #     # Concat the end link
    #     links_string = links_string + '->e'

def code_expansion(filename):

    flag_changer = "PROCEDURE DIVISION"
    include = "++INCLUDE"
    copy = "COPY"
    openFile = open(filename)

    Lines = openFile.readlines()
    MainLines = Lines  # lines are copied to to this variable
    flag = False
    for line in Lines:  # iterate through lines of file
        if flag_changer in line:  # this flag changer is for capture lines after PROCEDURE DIVISION
            flag = True
        if flag == True:
            indexline = line
            line = line[6:72]
            line = line.strip()
            if not line.startswith("*"):  # if not a comment line
                if include in line:  # check for "++INCLUDE"
                    # print(True)
                    includefilename = line.split(include)[1].split()[
                                          0] + extention2  # splits line to get the include file name
                    if isfile(
                            base_location + "\\" + includefolder + "\\" + includefilename):  # opens include file and add the line of file to the mainlines
                        openFile2 = open(base_location + "\\" + includefolder + "\\" + includefilename,
                                         encoding="utf8").readlines()
                        indexofline = MainLines.index(indexline)
                        del MainLines[MainLines.index(indexline)]
                        MainLines[indexofline: indexofline] = openFile2

    Lines = MainLines
    flag = False
    for line in Lines:  # iterate through lines of file
        if flag_changer in line:  # this flag changer is for capture lines after PROCEDURE DIVISION
            flag = True
        if flag == True:
            indexline = line
            line = line[6:72]
            line = line.strip()
            if not line.startswith("*"):  # if not a comment line
                if copy in line:  # check for "COPY"
                    if line.split()[0] == copy:
                        copybookfilename = line.split(copy)[1].split()[
                                               0] + extention3  # splits line to get the copy file name
                        if isfile(
                                base_location + "\\" + copybookfolder + "\\" + copybookfilename):  # opens copy file and add the line of file to the mainlines
                            # print("True2")
                            openFile3 = open(base_location + "\\" + copybookfolder + "\\" + copybookfilename,
                                             encoding="utf8").readlines()
                            indexofline = MainLines.index(indexline)
                            del MainLines[MainLines.index(indexline)]
                            MainLines[indexofline: indexofline] = openFile3

    Lines = MainLines



    return  Lines



for file_location, file_type in source_file.items():
    for filename in glob.glob(os.path.join(file_location,file_type)):
        # print(filename)
        Lines = code_expansion(filename)
        process_list = endif_tagging_function(Lines)
        paraRepository,para_names = func_separation(process_list)

        keywords_for_if_delimiter = ['ESCAPE','ACCEPT', 'NEXT', 'RETURN', 'STOP RUN', 'END-PERFORM', 'CALL', 'MOVE', 'COMPUTE',
                                     'PERFORM',
                                     'ELSE', 'SET', 'IF', 'STRING', 'EXEC', 'ADD', 'WHEN', 'GO', 'NEXT', 'READ',
                                     'DISPLAY',
                                     'CONTINUE', 'WRITE', 'DIVIDE', 'SUBTRACT',
                                     'accept', 'return', 'stop run', 'end-perform', 'call', 'move', 'compute',
                                     'perform',
                                     'else', 'set', 'if', 'exec', 'add', 'when', 'go', 'next', 'read', 'display',
                                     'continue', 'write', 'divide', 'TERMINATE']

        perform_related_keywords = ['THRU', 'UNTIL', 'TIMES', 'VARYING']
        if_collector_list = []

        total_if_block_counter = 0
        total_individual_block_counter = 0
        total_group_block_counter = 0
        block_counter = 0

        if_counter = 0
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

        # para_names = ["MAIN"]
        # paraRepository = {"MAIN" : [" IF  FAC-IN-OUT-CODE OF DCLFAC-BOM = 'O'\n",
        #                             "    WS-200-MMS-QTY = WS-200-MMS-QTY * WS-200-PCT-OUT\n",
        #                             "    IF  DS507-RMC-LOGIC-IND = 'Y'\n",
        #                             "       PERFORM 8000-INVOKE-EPMCX676\n",
        #                             "       REPEAT VARYING WS-200-SUB2 FROM 1 BY 1\n",
        #                             "       IF  RETRIEVAL-ERROR\n",
        #                             "          ESCAPE\n",
        #                             "       ELSE\n",
        #                             "          PERFORM 8800 - ASSIGN - ITEMS - TO - LINK - REC\n",
        #                             "          IF RETRIEVAL - ERROR\n",
        #                             "             ESCAPE\n",
        #                             "          END IF\n",
        #                             "       END IF\n",
        #                             "    ELSE\n",
        #                             "       PERFORM 8400-INVOKE-EPMCX657\n",
        #                             "       PERFORM 8800-ASSIGN-ITEMS-TO-LINK-REC\n",
        #                             "       IF RETRIEVAL-ERROR\n",
        #                             "         ESCAPE\n",
        #                             "       ELSE\n",
        #                             "         PERFORM 8400-INVOKE-EPMCX657\n",
        #                             "       END IF\n",
        #                             "       PERFORM KIRAN KISHORE\n",
        #                             "    END IF\n",
        #                             " ELSE\n",
        #                             "     WS-200-MMS-QTY = WS-200-MMS-QTY * WS-200-PCT-IN \n",
        #                             "     PERFORM 8400-INVOKE-EPMCX657\n",
        #                             "     IF RETRIEVAL-ERROR\n",
        #                             "        ESCAPE\n",
        #                             "     END IF\n",
        #                             " END IF\n"]}
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

            dict= {}
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
                    if re.match('.*end-if.*',line,re.IGNORECASE):
                        endif_counter = endif_counter + 1
                        if_collector_list.append(line.rstrip()+'\n')
                        if if_counter == endif_counter:
                            if_condition_collector_flag = False
                            # print(paragraph_name)
                            total_group_block_counter, block_counter, node_sequence, node_code, total_if_block_counter = if_process_function(if_collector_list,total_group_block_counter,block_counter,node_sequence,node_code,total_if_block_counter)

                            dict[dict_counter] = copy.deepcopy(node_sequence)

                            dict_counter = dict_counter + 1
                            node_sequence.clear()

                            if_collector_list.clear()
                        continue

                    if re.match('.* IF .*',line):
                        if not re.match('.*end-if.*',line,re.IGNORECASE):
                            if_counter = if_counter + 1
                            if_collector_list.append(line.rstrip()+'\n')

                            continue

                    else:
                        if_collector_list.append(line.rstrip()+'\n')
                        continue






                if re.match('.* IF *', line):
                    if not re.match('.*end-if.*',line,re.IGNORECASE):
                    # new if condition found, increment the global if counter
                    #     print("Line_indexx:", index)
                        # Start collecting the condition
                        if_counter = if_counter + 1
                        parent_if_list .append(if_counter)
                        if_collector_list.append(line.rstrip()+'\n')

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

            # node_string = 'st=>start: START | past\ne=>end: END | past \n'
            # links_string = 'st'
            # missing_list = []
            # connector_list = []
            # for i in range(0, len(node_sequence)):
            #     # node_code[node_sequence[i]] = node_code[node_sequence[i]].lstrip('\n')
            #     # node_code[node_sequence[i]] = node_code[node_sequence[i]].replace('=>', '= >')
            #
            #     if re.match('^S.*', node_sequence[i]) or re.match('^G.*', node_sequence[i]):
            #         if node_sequence[i + 1] in missing_list:
            #             connector_list.append(node_sequence[i])
            #             links_string = links_string + '->' + node_sequence[i]
            #         else:
            #             links_string = links_string + '->' + node_sequence[i] + '\n' + node_sequence[i]
            #     if re.match('^C.*', node_sequence[i]):
            #         c_index = node_sequence.index(node_sequence[i])
            #         if node_sequence[c_index + 2] != 'F' + node_sequence[i][1]:
            #             missing_list.append('F' + node_sequence[i][1])
            #             if node_code['F' + node_sequence[i][1]] != '':
            #                 links_string = links_string + '->' + node_sequence[i] + '\n' + node_sequence[
            #                     i] + '(yes)->' + node_sequence[i + 1]
            #                 links_string = links_string + '\n' + node_sequence[
            #                     i] + '(no)->' + ('F' + node_sequence[i][1])
            #
            #         else:
            #             if node_code['F' + node_sequence[i][1]] != '':
            #                 links_string = links_string + '->' + node_sequence[i] + '\n' + node_sequence[
            #                     i] + '(yes)->' + node_sequence[i + 1]
            #
            #                 links_string = links_string + '\n' + node_sequence[i] + '(no)->' + node_sequence[i + 2]
            #
            #                 if re.match('^C.*', node_sequence[i + 3]):
            #                     connector_list.append(node_sequence[i + 1])
            #                 if node_sequence[i + 3] in missing_list:
            #                     connector_list.append(node_sequence[i + 1])
            #                     connector_list.append(node_sequence[i + 2])
            #
            #             else:
            #                 links_string = links_string + '->' + node_sequence[i] + '\n' + node_sequence[
            #                     i] + '(yes)->' + node_sequence[i + 1]
            #
            #                 if node_sequence[i + 3] in missing_list:
            #                     connector_list.append(node_sequence[i + 1])
            #                     connector_list.append(node_sequence[i] + '(no)')
            #
            #     if re.match('^T.*', node_sequence[i]):
            #         if node_sequence[i] in connector_list:
            #             continue
            #         if re.match('^S.*', node_sequence[i + 2]) or re.match('^G.*', node_sequence[i + 2]):
            #             links_string = links_string + '\n' + node_sequence[i] + '->' + node_sequence[i + 2]
            #         else:
            #             links_string = links_string + '\n' + node_sequence[i]
            #
            #     if re.match('^F.*', node_sequence[i]):
            #
            #         if node_sequence[i] in connector_list:
            #             continue
            #         if (node_code[node_sequence[i]] == '') and (
            #                 re.match('^S.*', node_sequence[i + 1]) or re.match('^G.*', node_sequence[i + 1])):
            #             links_string = links_string + '\n' + ('C' + node_sequence[i][1]) + '(no)'
            #
            #
            #
            #
            #
            #         else:
            #             links_string = links_string + '\n' + node_sequence[i]
            #
            # connections(node_sequence, node_code)
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

            for keys,values in dict.items():
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
                for dict_key in dict_keys:

                    position = dict_keys.index(dict_key)
                    # print(position)
                    node_sequence = dict_values[position]
                    # print(node_sequence)
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

                            if node_sequence[c_index + 2] != 'F' + node_sequence[i][1:]:
                                missing_list.append('F' + node_sequence[i][1:])

                                if node_code['F' + node_sequence[i][1:]] != '':
                                    if node_code[node_sequence [i + 1]] == "":
                                        if i + 2 <= len(node_sequence) - 1:
                                            links_string = links_string + '->' + node_sequence[i] + '\n' + node_sequence[
                                                i] + '(yes)->' + node_sequence[i + 2]
                                            links_string = links_string + '\n' + node_sequence[
                                                i] + '(no)->' + ('F' + node_sequence[i][1:])
                                        else:
                                            links_string = links_string + '->' + node_sequence[i]
                                            connector_list.append('C' + node_sequence[i][1:] + '(yes)')
                                            links_string = links_string + '\n' + node_sequence[
                                                i] + '(no)->' + ('F' + node_sequence[i][1:])
                                    else:
                                        links_string = links_string + '->' + node_sequence[i] + '\n' + node_sequence[
                                            i] + '(yes)->' + node_sequence[i + 1]
                                        links_string = links_string + '\n' + node_sequence[
                                            i] + '(no)->' + ('F' + node_sequence[i][1:])
                                else:
                                    if node_code[node_sequence[i + 1]] == "":
                                        if re.search('.*ELSE-IF.*', node_code[node_sequence[i + 2]]):
                                            connector_list.append( node_sequence[i] + '(yes)')

                                    else:
                                        links_string = links_string + '->' + node_sequence[i] + '\n' + node_sequence[
                                            i] + '(yes)->' + node_sequence[i + 1]
                                    if re.search('.*ELSE-IF.*',node_code[node_sequence[i + 2]]):
                                        elseif_list.append('F' + node_sequence[i][1:])
                                        links_string = links_string  + '\n' + node_sequence[
                                            i] + '(no)->' + node_sequence[i + 2]

                                    else:
                                        connector_list.append(node_sequence[i] + '(no)')

                            else:
                                if node_code['F' + node_sequence[i][1:]] != '':
                                    if node_code[node_sequence [ i+ 1]] == "":
                                        if i + 3 <= len(node_sequence) - 1:
                                            links_string = links_string + '->' + node_sequence[i] + '\n' + node_sequence[
                                                i] + '(yes)->' + node_sequence[i + 3]
                                            links_string = links_string + '\n' + node_sequence[i] + '(no)->' + \
                                                           node_sequence[i + 2]
                                        else:
                                            links_string = links_string + '->' + node_sequence[i]
                                            connector_list.append('C' + node_sequence[i][1:] + '(yes)')
                                            links_string = links_string + '\n' + node_sequence[i] + '(no)->' + \
                                                           node_sequence[i + 2]
                                    else:
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
                                    if node_code[node_sequence [ i+ 1]] == "":
                                        if i + 3 <= len(node_sequence) - 1:
                                            if re.search('.*ELSE-IF.*', node_code[node_sequence[i + 3]]):
                                                links_string = links_string + '->' + node_sequence[i] + '\n' + \
                                                               node_sequence[
                                                                   i] + '(yes)->' + node_sequence[i + 3]
                                                elseif_list.append('F' + node_sequence[i][1:])
                                    else:
                                        links_string = links_string + '->' + node_sequence[i] + '\n' + node_sequence[
                                            i] + '(yes)->' + \
                                                       node_sequence[i + 1]


                                    try:
                                        if node_sequence[i + 3] in missing_list:
                                            connector_list.append(node_sequence[i + 1])
                                            connector_list.append(node_sequence[i] + '(no)')

                                    except:

                                        continue

                        if re.match('^T.*', node_sequence[i]):
                            if not node_code[node_sequence[i]].strip() == '':
                                node_string = node_string + node_sequence[i] + '=>operation: ' + node_code[
                                    node_sequence[i]] + ' | approved \n'
                            if node_sequence[i] in connector_list or ('C' + node_sequence[i][1:]) + '(yes)' in connector_list:
                                continue

                            if ('F' + node_sequence[i][1:]) in elseif_list:
                                connector_list.append(node_sequence[i])
                                continue
                            if node_code[node_sequence[i]] == '':
                                continue
                            if i + 2 <= len(node_sequence) - 1:
                                if re.match('^S.*', node_sequence[i + 2]) or re.match('^G.*', node_sequence[i + 2]):
                                    links_string = links_string + '\n' + node_sequence[i] + '->' + node_sequence[i + 2]
                                elif node_code[node_sequence[i + 1]] == '' and re.search('^C.*', node_sequence[i + 2]):
                                    connector_list.append(node_sequence[i])
                                else:
                                    links_string = links_string + '\n' + node_sequence[i]
                            else:
                                connector_list.append(node_sequence[i])

                        if re.match('^F.*', node_sequence[i]):
                            if not node_code[node_sequence[i]].strip() == '':
                                node_string = node_string + node_sequence[i] + '=>operation: ' + node_code[
                                    node_sequence[i]] + ' | approved \n'
                            if node_sequence[i] in connector_list or node_sequence[i] in elseif_list or ('C' + node_sequence[i][1:]) + '(no)' in connector_list:
                                continue
                            try:
                                if (node_code[node_sequence[i]] == '') :

                                    links_string = links_string + '\n' + ('C' + node_sequence[i][1:]) + '(no)'


                                elif node_sequence[i] in missing_list and node_sequence[i + 1] in missing_list:
                                    connector_list.append(node_sequence[i])

                                else:
                                    links_string = links_string + '\n' + node_sequence[i]
                            except:
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
                        if (position + 1) in dict:
                            second_connector_list = dict_values[position + 1][0]
                            links_string = links_string + '->' + second_connector_list
                        else:
                            links_string = links_string + '->' + 'e'
                OUTPUT_DATA.append({"option": node_string + '\n' + links_string,
                                    "component_name": filename.split("\\")[-1],
                                    "para_name": paragraph_name.casefold()})
                print("*****************")
                print(paragraph_name)

                print('\n')

                print(node_string)
                print('\n')
                print(links_string)

                # print(node_sequence)
                # print(links_string)
                #
                node_sequence.clear()
                node_string = ''
                links_string = ''
                connector_list.clear()
                elseif_list.clear()
                # print(json.dumps(OUTPUT_DATA,indent=4))

                # print(OUTPUT_DATA)

            # os.remove("Copy_Expanded_Data" + '.txt')

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

        # print(paragraph_name)


