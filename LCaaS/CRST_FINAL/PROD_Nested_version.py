SCRIPT_VERSION = 'PROD version Nested ifs'

import copy
import re
import pytz
import datetime
import os
import sys
from pymongo import MongoClient
import config_crst
import json

client = MongoClient(config_crst.database['hostname'], config_crst.database['port'])
db = client[config_crst.database['database_name']]

# Setting Application timezone
time_zone = 'Asia/Calcutta'
tz = pytz.timezone(time_zone)


def codeCleanup(file):
    '''
    function removes
    -excludes commented lines
    -leading 6 characters
    -replaces any TABS with space
    -captures only the lines of code existing in the procedure division
    '''
    IN_PROC_DIV = False
    loc_in_scope = []
    # Snip program numbers
    # print("Codecleanup:",file)
    # print("Type:",type(file))
    # f = open('DataD_lines.txt','r')
    # print("F:",f)
    for line in file:
        # print("Outer_lines:",line)
        if line[0] == '/':
            continue
        line = line[6:72]
        # print("Lines:", line)
        line = line.replace('\t', '    ')
        if line.strip() != '' and len(line) > 6:
            # if line[0] != '/':
            #     continue
            if line[0] != '*':
                if re.match('.*procedure division.*', line, re.IGNORECASE):
                    IN_PROC_DIV = True
                if IN_PROC_DIV:
                    # line = line[6:72]
                    if line.strip() != '':
                        loc_in_scope.append(line)

    return loc_in_scope


def splitProcedures(PROC_DIV_CODE):
    parasStarted = False
    current_para = ''
    prev_para = ''
    future_para = ''
    storage = []
    res_dict = {}
    paraRepository = {}
    para_names = []
    for line_counter, line in enumerate(PROC_DIV_CODE):
        # print("TW_ELSE_Checking_Lines:",line)
        # Skip lines containing any of the below keywords
        if not re.match('.*eject.*', line, re.IGNORECASE):
            if not re.match('.*\sexit\s.*', line, re.IGNORECASE):
                if not re.match('.* skip1.*', line, re.IGNORECASE):
                    if not re.match('.* skip2.*', line, re.IGNORECASE):
                        if not re.match('.* skip3.*', line, re.IGNORECASE):
                            # If the 8th position is not empty, it must the delcatation of a paragraph
                            # print("Line00000000000000:",line[0])
                            if line[1] != ' ' and not (line.__contains__("END-SECTION.")):
                                # print(prev_para)

                                # future_para = line_counter(prev_para)+line

                                prev_para = current_para
                                # print("Current_para:",current_para)
                                # print("Prev_para:",prev_para)

                                # print("Future_para:",future_para)
                                # print("Prev_paraaaa:",prev_para)
                                current_para = line.split()[0]
                                current_para = current_para.replace('.', '')

                                para_names.append(current_para)
                                # print("PARA_NAMES:",para_names)
                                # print("Prev_paraaaaaa:",prev_para)
                                # print("Current_paraaaaa:",current_para)
                                # print("Storageeeeeee:",storage)
                                if prev_para == '':
                                    para_names.append('00-MAIN')
                                    paraRepository['00-MAIN'] = copy.deepcopy(storage)
                                    storage.clear()

                                else:

                                    paraRepository[prev_para] = copy.deepcopy(storage)
                                    storage.clear()


                            else:
                                # print(line)
                                storage.append(line)
    paraRepository[current_para] = copy.deepcopy(storage)
    list1=[]
    list2=[]
    print("Para_names:",para_names)
    print("Checking:",json.dumps(paraRepository, indent=4))


##### For GE coding standards, to capture sub sections under each section or paras.
    for i,j in paraRepository.items():
        list1.append(i)
        list2.append(j)
    for k in range(0, len(list1)):
        if (paraRepository[list1[k]])==[]:
            for l in range(k+1,len(list1)):
                if len(list1[l]) <= 4 and paraRepository[list1[l]] != []:
                    list2[k].extend(list2[l])
                if paraRepository[list1[l]] == []:
                    break
                elif len(list1[l]) > 4:
                    continue


##### For Nissan coding standards, to capture sub sections under each section or paras.
    # for i,j in paraRepository.items():
    #     list1.append(i)
    #     list2.append(j)
    # for k in range(0, len(list1)):
    #     try:
    #
    #         if (paraRepository[list1[k]]) == []:
    #             for l in range(k + 1, len(list1)):
    #                 if list1[1].endswith("0") and paraRepository[list1[1]] != []:
    #                 #if len(list1[l]) <= 4 and Module_Dict1[list1[l]] != []:
    #                     list2[k].extend(list2[l])
    #                     list1.remove(l)
    #                 if paraRepository[list1[l]] == []:
    #                     break
    #                 elif list1[1].endswith("0"):
    #                 #elif len(list1[l]) > 4:
    #                     continue
    #     except Exception as e:
    #         print(e)

    res_dict = dict(zip(list1, list2))

    # print("GE-dict:",json.dumps(res_dict, indent=4))

    return res_dict, para_names


def getFiles(file_type, file_extension, project_location) -> list:
    # Generating directory of COBOL files
    try:
        print("Project-location:",project_location,file_type,file_extension)
        parent_folder = project_location + '\\' + file_type  ## for windows OS
        parent_folder = project_location + '/' + file_type
        print("Parent_folder:",parent_folder)
        # print(os.path.listdir(parent_folder))
        files_w_extension = [x for x in os.listdir(parent_folder)]
        #print("Files_extension:",files_w_extension)
        files_w_extension = [x for x in os.listdir(parent_folder) if re.match('.+\.' + file_extension, x)]
    except (FileNotFoundError):
        print('Rename the folder to \'' + file_type + '\' and try again... ')
        sys.exit(0)
    except Exception as e:
        print(str(e))
        sys.exit(0)

    # LocalUtils.logger.debug(
    #     'WARNING: ' + (str(len(COBOL_FILE_LIST) - len(files_w_extension))) + ' File(s) do not have a .cbl extension')
    return files_w_extension


def expandCopyooks(file_pointer, copybook_location):
    # Iterate through the contents of the file
    expanded_code = []
    for line in file_pointer:
        # print("first_time_line_passing:",line)
        if line.strip() != '' :
            if line[0] != '*':
                # print("Copy:",line)
                if re.match('\s.*copy\s.*', line, re.IGNORECASE) or re.match('\s*\+\+INCLUDE\s+.*', line, re.IGNORECASE):
                    # print("COPY:",line)
                    copybook_name = line.split()[1]
                    copybook_name = copybook_name.replace('"', '')
                    copybook_name = copybook_name.replace("'", '')
                    copybook_name = copybook_name.replace(".", '')
                    if os.path.isfile(code_location + '\\' + COPYBOOK + '\\' + COMPONENT_NAME + '.cbl'):
                        expanded_code.append(
                            open(code_location + '\\' + COPYBOOK + '\\' + COMPONENT_NAME + '.cbl', 'r'))
                    elif os.path.isfile(code_location + '\\' + COPYBOOK + '\\' + COMPONENT_NAME + '.CBL'):
                        expanded_code.append(
                            open(code_location + '\\' + COPYBOOK + '\\' + COMPONENT_NAME + '.CBL', 'r'))
                    else:
                        print('COULD NOT FIND COPYBOOK', copybook_name)
                        expanded_code.append(line)

                else:
                    expanded_code.append(line)
    # print(expanded_code)
    return expanded_code

# def expandCopyooks(file_pointer, copybook_location):
#     print("File:",file_pointer)
#     # file_handle = open(file_pointer,'r')
#     for line in file_pointer:
#         print("Lines:",line)
#         try:
#             if line.startswith("*"):
#                 continue
#             else:
#                 copyfile = open("DataD_lines.txt", "a")
#                 # if not line[5] == 'd' or line[5] == 'D':
#                 line_list = line.split()
#
#                 for iter in line_list:
#                     if iter.__contains__("COPY"):
#                         print("Iter:",iter)
#                         var = (len(line_list))
#                         if var >=2:
#                             copyname =line_list[var-1].replace('"',"")
#
#                             # if copyname.__contains__(","):
#                             #     copyname_list = copyname.split(",")
#                             #
#                             #     var = len(copyname_list)
#                             #     copyname = copyname_list[var-1]
#                             #
#                             copyname = copyname[:-1]
#
#                             Copyfilepath = CopyPath + '\\' + copyname
#                             print("Copyfilepath:",Copyfilepath)
#
#                             if os.path.isfile(Copyfilepath):
#                                 tempcopyfile = open(os.path.join(CopyPath, copyname), "r")
#                                 copyfile.write("#########" + " " + "BEGIN" + " " + line + '\n')
#                                 for copylines in tempcopyfile.readlines():
#                                     copyfile.write(copylines)
#                                     copyfile.write('\n')
#                                 copyfile.write("#####" + " " + "COPY END" + "####" + '\n')
#                             #else:
#
#
#                 copyfile.write(line)
#
#             copyfile.close()
#
#         except Exception:
#
#             pass
#
#     return copyfile

def noNextLine(para_line_list, current_index):
    try:
        line = para_line_list[current_index + 1]
        return False
    except:
        return True


cobol_folder_name = config_crst.codebase_information['COBOL']['folder_name']
cobol_extension_type = config_crst.codebase_information['COBOL']['extension']
COPYBOOK = config_crst.codebase_information['COPYBOOK']['folder_name']
OUTPUT_DATA = []

print("Cobol_folder_name:",cobol_folder_name)
print(cobol_extension_type)
code_location = config_crst.codebase_information['code_location']
print("Code_location:",code_location)
copybook_location = code_location + '\\' + COPYBOOK  ### for windows OS
# copybook_location = code_location + '/' + COPYBOOK   ### for MAC OS
print("Copybook_location:",copybook_location)
COBOL_FILE_LIST = copy.deepcopy(getFiles(cobol_folder_name, cobol_extension_type, code_location))
print('List of cobol files to be processed', COBOL_FILE_LIST)
for COMPONENT_NAME in COBOL_FILE_LIST:
    print('Processing file: ', COMPONENT_NAME)

    # Setting the static COMPONENT NAME to be used while generating the output

    # file = open(code_location + '\\' + cobol_folder_name + '\\' + COMPONENT_NAME, 'r')  ## for Windows OS
    file = open(code_location + '/' + cobol_folder_name + '/' + COMPONENT_NAME, 'r')   ## for MAC OS
    file = expandCopyooks(file, copybook_location)

    # Code to remove comments and blank lines
    # print("Outer:",file)
    procedure_division_codeblock = codeCleanup(file)[1:]

    # Code to separate all the procedures
    program_procedures, para_list = splitProcedures(procedure_division_codeblock)

    '''
    Helpers for IF condition extraction 
    '''
    keywords_for_if_delimiter = ['ACCEPT','NEXT', 'RETURN', 'STOP RUN', 'END-PERFORM', 'CALL', 'MOVE', 'COMPUTE', 'PERFORM',
                                 'ELSE', 'SET', 'IF', 'STRING', 'EXEC', 'ADD', 'WHEN', 'GO', 'NEXT', 'READ', 'DISPLAY',
                                 'CONTINUE', 'WRITE','DIVIDE','SUBTRACT',
                                 'accept', 'return', 'stop run', 'end-perform', 'call', 'move', 'compute', 'perform',
                                 'else', 'set', 'if', 'exec', 'add', 'when', 'go', 'next', 'read', 'display',
                                 'continue', 'write', 'divide','TERMINATE' ]

    keywords_for_group_variables = ['MOVE', 'INSPECT', 'CLOSE', 'DISPLAY', 'ADD', 'SUBTRACT', 'MULTIPLY', 'DIVIDE',
                                    'COPY', 'TO',
                                    'COMPUTE']

    perform_related_keywords = ['THRU', 'UNTIL', 'TIMES', 'VARYING']

    total_if_counter = 0
    total_individual_block_counter = 0
    total_group_block_counter = 0

    # GROUP BLOCK
    group_block_flag = False
    group_block_variable = ''

    # IF VARIABLES
    if_condition_variable = ''
    if_condition_collector_flag = False

    # TRUE PART VARIABLES
    true_part_variable = ''
    true_part_flag = False

    # FALSE PART VARIABLES
    false_part_variable = ''
    false_part_flag = False

    # PERFORM INLINE TOP
    perform_inline_collector_flag = False
    perform_inline_collector_variable = ''

    # PERFORM INLINE BODY
    perform_inline_body_flag = False
    perform_inline_body_variable = ''

    # MULTILINE PERFORM VARIABLES
    multiline_perform_started_flag = False
    multiline_perform_started_variable = ''

    # EVALUATE VARIABLES
    eval_flag = False
    eval_variable = ''

    when_flag = False
    when_variable = ''

    # EXEC VARIABLES
    exec_flag = False
    exec_variable = ''

    # OPEN VARIABLES
    open_flag = False
    open_variable = ''

    # SET VARIABLES
    set_flag = False
    set_variable = ''

    # WRITE VARIABLES
    write_flag = False
    write_variable = ''

    # DELETE VARIABLES
    delete_flag = False
    delete_variable = ''

    # REWRITE VARIABLES
    rewrite_flag = False
    rewrite_variable = ''

    # CALL VARIABLE
    call_flag = False
    call_variable = ''

    # READ VARIABLE
    read_variable = ''
    read_flag = False

    # Node definitions
    node_definitions = ''
    # Collects the sequence of node
    node_sequence = []
    # Collects actual code of nodes
    node_code = {}

    collector_flag = False
    collector_variable = ''

    nested_if_flag = False
    nested_else_if_flag = False
    nested_true_part_flag = False
    nested_false_part_flag = False
    if_index_list = []
    nested_dict ={}
    nested_false_part_variable = ""
    false_if_counter = 0
    links_dict = {}
    false_tag_list = []
    nested_else_part_list = []
    nested_false_if_counter_count = 0
    immediate_if_counter = 0
    main_if_index = 0

    last_perform_variable = ''

    except_block_variable = ''

    # First level IFs true part tally logic helpers
    truepart_ifs_tallied = True
    truepart_if_opened_count = 0
    truepart_if_closed_count = 0

    # First level IFs false part tally logic helpers
    falsepart_ifs_tallied = True
    falsepart_if_opened_count = 0
    falsepart_if_closed_count = 0

    skip = False
    print('Extracted paragraphs:',para_list)
    # print(para_list)
    for paragraph_name in para_list:
        # print("Para_name:",paragraph_name)
        # no_of_lines_in_para = len(program_procedures[paragraph_name])
        node_code = {}
        node_sequence = []
        immediate_tag_list = []
        true_if_list = []
        check_if_counter = 0
        rare_immediate_if_counter = 0
        rare_immediate_tag_list = []
        no_index_iterative_if_counter = 0
        check_helpful_list = []
        backup_nested_else_part_list = []
        handle_mainelse_counter = 0
        multilevel_if_counter = 0
        multilevel_dict_len = 0
        endpoint_counter = 0
        nested_dict = {}
        one_main_dict = {}
        multilevel_if_dict = {}
        endpoint_list = []
        multilevel_if_list = []
        manylevel_if_dict = {}
        manylevel_if_variable = ""
        check_else_list = []
        multilevel_else_if_list = []
        main_dict = {}
        nested_endif_list = []
        main_false_if_counter = 0
        nested_else_if_counter = 0
        check_endif_list = []
        counter = 0
        true_if_counter = 0
        iterative_multuple_else_counter = 0
        main_dict = {}
        false_if_counter = 0
        nested_false_if_counter = 0
        if_nested_condition_variable_counter = 0
        loop_under_main_else_counter = 0
        try:

            for index, line in enumerate(program_procedures[paragraph_name]):
                if skip:
                    if call_flag:
                        if re.match('.*\..*', line, re.IGNORECASE):
                            call_variable = call_variable + '\n' + line
                            node_sequence.append('S' + str(total_individual_block_counter))
                            false_tag_list.append('S' + str(total_individual_block_counter))
                            node_code['S' + str(total_individual_block_counter)] = call_variable
                            call_variable = ''
                            call_flag = False
                            continue
                        if any(ext in line for ext in keywords_for_if_delimiter):
                            call_variable = call_variable + '\n'
                            node_sequence.append('S' + str(total_individual_block_counter))
                            false_tag_list.append('S' + str(total_individual_block_counter))
                            node_code['S' + str(total_individual_block_counter)] = call_variable
                            call_variable = ''
                            call_flag = False


                        else:
                            call_variable = call_variable + '\n' + line
                            continue

                    if write_flag:
                        if re.match('.*end-write.*', line, re.IGNORECASE) or re.match('.*\..*', line, re.IGNORECASE):
                            write_variable = write_variable + '\n' + line
                            node_sequence.append('P' + str(total_individual_block_counter))
                            false_tag_list.append('P' + str(total_individual_block_counter))
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
                            false_tag_list.append('P' + str(total_individual_block_counter))
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
                            false_tag_list.append('P' + str(total_individual_block_counter))
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
                            false_tag_list.append('P' + str(total_individual_block_counter))
                            node_code['P' + str(total_individual_block_counter)] = read_variable
                            read_variable = ''
                            read_flag = False
                            continue

                        else:
                            read_variable = read_variable + '\n' + line
                            continue

                    if set_flag:
                        if re.match('.*\..*', line, re.IGNORECASE):
                            set_variable = set_variable + '\n' + line
                            node_sequence.append('S' + str(total_individual_block_counter))
                            false_tag_list.append('S' + str(total_individual_block_counter))
                            node_code['S' + str(total_individual_block_counter)] = set_variable
                            set_variable = ''
                            set_flag = False
                            continue

                        else:
                            set_variable = set_variable + '\n' + line
                            continue

                    if open_flag:
                        if re.match('.*\..*', line, re.IGNORECASE):
                            open_variable = open_variable + '\n' + line
                            node_sequence.append('S' + str(total_individual_block_counter))
                            false_tag_list.append('S' + str(total_individual_block_counter))
                            node_code['S' + str(total_individual_block_counter)] = open_variable
                            open_variable = ''
                            open_flag = False
                            continue

                        else:
                            open_variable = open_variable + '\n' + line
                            continue

                    if exec_flag:
                        if re.match('.*end-exec.*', line, re.IGNORECASE):
                            exec_variable = exec_variable + '\n' + line
                            node_sequence.append('S' + str(total_individual_block_counter))
                            false_tag_list.append('S' + str(total_individual_block_counter))
                            node_code['S' + str(total_individual_block_counter)] = exec_variable
                            exec_variable = ''
                            exec_flag = False
                            continue

                        else:
                            exec_variable = exec_variable + '\n' + line
                            continue

                    if eval_flag:
                        if re.match('.*WHEN.*', line, re.IGNORECASE):
                            eval_variable = eval_variable + '\n'
                            node_sequence.append('S' + str(total_individual_block_counter))
                            node_code['S' + str(total_individual_block_counter)] = eval_variable
                            when_variable = line + '\n'
                            main_when_index = when_variable.index("WHEN")
                            eval_variable = ''
                            eval_flag = False
                            when_flag = True
                            continue

                        else:
                            eval_variable = eval_variable + '\n' + line
                            continue

                    if when_flag:
                        if re.match('.*WHEN.*', line, re.IGNORECASE):
                            next_when_index = line.index("WHEN")
                            if main_when_index == next_when_index:
                                total_individual_block_counter = total_individual_block_counter + 1
                                node_sequence.append('S' + str(total_individual_block_counter))
                                node_code['S' + str(total_individual_block_counter)] = when_variable
                                when_variable = ''
                                when_variable = line + '\n'
                                continue

                        if re.match('.*END-EVALUATE.*', line, re.IGNORECASE):
                            end_eval_index = line.index("END-EVALUATE")
                            if eval_index == end_eval_index:
                                when_variable = when_variable + '\n' + line
                                total_individual_block_counter = total_individual_block_counter + 1
                                node_sequence.append('S' + str(total_individual_block_counter))
                                node_code['S' + str(total_individual_block_counter)] = when_variable
                                when_variable = ''
                                when_flag = False
                                continue

                        else:
                            when_variable = when_variable + '\n' + line
                            continue

                    if multiline_perform_started_flag:

                        if (any(ext in line.split() for ext in keywords_for_if_delimiter)) or noNextLine(
                                program_procedures[paragraph_name], index):

                            group_block_flag = False
                            if group_block_variable != '':
                                total_group_block_counter = total_group_block_counter + 1
                                node_sequence.append('G' + str(total_group_block_counter))
                                false_tag_list.append('G' + str(total_group_block_counter))
                                node_code['G' + str(total_group_block_counter)] = group_block_variable
                                group_block_variable = ''

                            total_individual_block_counter = total_individual_block_counter + 1
                            node_sequence.append('S' + str(total_individual_block_counter))
                            false_tag_list.append('S' + str(total_individual_block_counter))
                            node_code[
                                'S' + str(total_individual_block_counter)] = multiline_perform_started_variable
                            multiline_perform_started_flag = False
                            last_perform_variable = line
                            if noNextLine(program_procedures[paragraph_name], index):
                                total_individual_block_counter = total_individual_block_counter + 1
                                node_sequence.append('S' + str(total_individual_block_counter))
                                false_tag_list.append('S' + str(total_individual_block_counter))
                                node_code[
                                    'S' + str(total_individual_block_counter)] = last_perform_variable
                                multiline_perform_started_flag = False
                                continue
                            else:
                                 print("Success")

                        else:

                            multiline_perform_started_variable = multiline_perform_started_variable + '\n' + line

                            continue

                    if perform_inline_body_flag:
                        if re.match('.*END-PERFORM.*', line):
                            if perform_inline_body_variable != '':
                                total_group_block_counter = total_group_block_counter + 1
                                node_sequence.append('G' + str(total_group_block_counter))
                                false_tag_list.append('G' + str(total_group_block_counter))
                                node_code['G' + str(total_group_block_counter)] = perform_inline_body_variable
                                perform_inline_body_variable = ''

                            total_individual_block_counter = total_individual_block_counter + 1
                            node_sequence.append('S' + str(total_individual_block_counter))
                            false_tag_list.append('S' + str(total_individual_block_counter))
                            node_code['S' + str(total_individual_block_counter)] = line
                            # Separate block for end-perform

                            perform_inline_body_flag = False
                            continue
                        else:
                            perform_inline_body_variable = perform_inline_body_variable + '\n' + line
                            continue

                    if perform_inline_collector_flag:
                        if any(ext in line.split() for ext in keywords_for_if_delimiter):

                            group_block_flag = False
                            if group_block_variable != '':
                                total_group_block_counter = total_group_block_counter + 1
                                node_sequence.append('G' + str(total_group_block_counter))
                                false_tag_list.append('G' + str(total_group_block_counter))
                                node_code['G' + str(total_group_block_counter)] = group_block_variable
                                group_block_variable = ''

                            total_individual_block_counter = total_individual_block_counter + 1
                            node_sequence.append('S' + str(total_individual_block_counter))
                            false_tag_list.append('S' + str(total_individual_block_counter))
                            node_code[
                                'S' + str(total_individual_block_counter)] = perform_inline_collector_variable
                            perform_inline_collector_flag = False
                            perform_inline_body_flag = True
                            perform_inline_body_variable = line
                            continue

                        else:
                            perform_inline_collector_variable = perform_inline_collector_variable + '\n' + line
                            continue

                    if if_condition_collector_flag:
                        if any(ext in line for ext in keywords_for_if_delimiter) or (line.strip() == '.'):
                            # stop collecting the IF conditional statement and continue
                            discovered_node = 'C' + str(
                                total_if_counter) + ' =>condition:' + if_condition_variable + ' | approved\n'

                            if re.match('.* if *', line, re.IGNORECASE):
                                multilevel_if_index = if_condition_variable.casefold().index("if")

                                node_sequence.append('C' + str(total_if_counter))
                                if check_if_counter == 1:
                                    false_tag_list.clear()

                                # false_tag_list.append('C' + str(total_if_counter))
                                multilevel_if_dict[total_if_counter] = multilevel_if_index
                                multilevel_if_list.append('C' + str(total_if_counter))
                                multilevel_dict_len = len(multilevel_if_dict)
                                if multilevel_dict_len == 1:

                                    one_main_dict[total_if_counter] = multilevel_if_index
                                multilevel_if_counter = multilevel_if_counter + 1
                                node_code['C' + str(total_if_counter)] = if_condition_variable

                                immediate_if_index = if_condition_variable.casefold().index("if")
                                node_sequence.append('T' + str(total_if_counter))
                                node_code['T' + str(total_if_counter)] = ''
                                node_sequence.append('F' + str(total_if_counter))
                                node_code['F' + str(total_if_counter)] = ''
                                immediate_tag_list.append('C' + str(total_if_counter))
                                next_if_word = program_procedures[paragraph_name][index + 1]

                                if re.search('.*if.*',next_if_word.casefold()):

                                    if_condition_collector_flag = False
                                else:
                                    if_condition_collector_flag = False
                                    immediate_if_counter = immediate_if_counter + 1
                                    if_nested_collection_line = line
                                    nested_if_flag = True

                                    continue
                            else:

                                node_sequence.append('C' + str(total_if_counter))
                                if check_if_counter == 1:
                                    false_tag_list.clear()
                                false_tag_list.append('C' + str(total_if_counter))
                                node_code['C' + str(total_if_counter)] = if_condition_variable
                                if_condition_collector_flag = False

                                true_part_flag = True

                                true_part_variable = ''
                                true_part_variable = true_part_variable + line + '\n'

                                if re.match('.*\.\s*', line, re.IGNORECASE):
                                    # The true part is also terminated
                                    node_sequence.append('T' + str(total_if_counter))
                                    node_code['T' + str(total_if_counter)] = line
                                    node_sequence.append('F' + str(total_if_counter))
                                    node_code['F' + str(total_if_counter)] = ''
                                    true_part_flag = False
                                    continue

                                if re.match('.* if *', line, re.IGNORECASE):
                                    # make sure if execution knows that IFs are no longer tallied
                                    truepart_ifs_tallied = False
                                    # Increment the count of opened if statements
                                    truepart_if_opened_count += 1
                                continue

                        else:
                            if_condition_variable = if_condition_variable + '\n' + line
                            continue

                    if true_part_flag:
                        if re.match('.* if *', line, re.IGNORECASE):
                                node_sequence.append('T' + str(total_if_counter))
                                node_code['T' + str(total_if_counter)] = true_part_variable + '\n'
                                node_sequence.append('F' + str(total_if_counter))
                                node_code['F' + str(total_if_counter)] = ''
                                if_nested_collection_line = line
                                true_part_flag = False
                                true_part_variable = ''
                                nested_if_flag = True
                                continue

                        if re.match('.* else.*',line,re.IGNORECASE):
                            main_else_index = line.casefold().index("else")
                            if main_if_index == main_else_index:
                                discovered_node = 'T' + str(
                                    total_if_counter) + ' =>operation:' + true_part_variable + ' | rejected\n'
                                node_sequence.append('T' + str(total_if_counter))
                                node_code['T' + str(total_if_counter)] = true_part_variable
                                # Clear the true part variable
                                true_part_variable = ''
                                # Set true part flag to false
                                true_part_flag = False
                                false_part_flag = True
                                false_part_variable = ''
                                # false_part_variable = false_part_variable + line + '\n'
                                continue

                        if re.match('.*\..*', line, re.IGNORECASE) or re.match('.*end-if.*', line, re.IGNORECASE):
                            node_sequence.append('T' + str(total_if_counter))
                            node_code['T' + str(total_if_counter)] = true_part_variable + '\n' + line
                            node_sequence.append('F' + str(total_if_counter))
                            node_code['F' + str(total_if_counter)] = ''
                            true_part_flag = False
                            continue

                        else:

                            true_part_variable = true_part_variable + '\n' + line
                            continue

                    if nested_if_flag:


                        # if re.match('.*if.*',line.casefold()):
                        #     if_nested_collection_line = line
                        #     continue

                        if re.match('.* if *', if_nested_collection_line, re.IGNORECASE):
                            # new if condition found, increment the global if counter
                            if if_nested_condition_variable_counter == 1:
                                pass
                            else:

                                if_index = if_nested_collection_line.index("IF")
                                #if_index_list.append(if_index)
                                #print("Index:", if_index_list)

                                total_if_counter = total_if_counter + 1
                                print("Total-if_counter:",total_if_counter)
                                nested_dict[total_if_counter] = if_index
                                print("Nested_dict:",nested_dict)
                                # Start collecting the condition
                                if_nested_condition_variable = if_nested_collection_line
                                # if_condition_collector_flag = True


                        if any(ext in line for ext in keywords_for_if_delimiter):
                            discovered_node = 'C' + str(
                                total_if_counter) + ' =>condition:' + if_nested_condition_variable + ' | approved\n'
                            node_sequence.append('C' + str(total_if_counter))
                            multilevel_if_list.append('C' + str(total_if_counter))
                            #false_tag_list.append('C' + str(total_if_counter))
                            node_code['C' + str(total_if_counter)] = if_nested_condition_variable
                            if immediate_if_counter == 1:
                                immediate_tag_list.append('C' + str(total_if_counter))
                                immediate_if_counter = 0
                            else:
                                pass
                            if if_nested_condition_variable_counter == 1:
                                if_nested_condition_variable_counter = 0
                            else:
                                pass
                            if nested_false_if_counter_count >=1:
                                print("Kishore")
                                nested_else_part_list.append('C' + str(total_if_counter))
                                pass
                            # if_condition_collector_flag = False

                            nested_if_flag = False
                            nested_true_part_flag = True

                            nested_true_part_variable = ''

                        else:
                            if_nested_condition_variable_counter = 0
                            if_nested_condition_variable = if_nested_condition_variable + '\n' + line
                            if_nested_condition_variable_counter = if_nested_condition_variable_counter + 1
                            continue

                    if nested_else_if_flag:

                        # if re.match('.*if.*',line.casefold()):
                        #     if_nested_collection_line = line
                        #     continue

                        if re.match('.* if *', if_nested_collection_line, re.IGNORECASE):
                            # new if condition found, increment the global if counter
                            if if_nested_condition_variable_counter == 1:
                                pass
                            else:
                                if_index = if_nested_collection_line.index("IF")
                                #if_index_list.append(if_index)
                                #print("Index:", if_index_list)

                                total_if_counter = total_if_counter + 1
                                if if_index!= main_if_index:
                                    nested_dict[total_if_counter] = if_index
                                else:
                                    pass
                                print("Total-if_counter:",total_if_counter)

                                print("Nested_dict:",nested_dict)
                                # Start collecting the condition
                                if_nested_condition_variable = if_nested_collection_line
                                # if_condition_collector_flag = True


                        if any(ext in line for ext in keywords_for_if_delimiter):
                            discovered_node = 'C' + str(
                                total_if_counter) + ' =>condition:' + if_nested_condition_variable + ' | approved\n'
                            node_sequence.append('C' + str(total_if_counter))
                            multilevel_else_if_list.append('C' + str(total_if_counter))
                            #false_tag_list.append('C' + str(total_if_counter))
                            node_code['C' + str(total_if_counter)] = if_nested_condition_variable
                            if if_nested_condition_variable_counter == 1:
                                if_nested_condition_variable_counter = 0
                            else:
                                pass
                            if rare_immediate_if_counter == 1:
                                rare_immediate_tag_list.append('C' + str(total_if_counter))
                                rare_immediate_if_counter = 0
                            else:
                                pass
                            if nested_false_if_counter >=1:
                                print("Kishore")
                                nested_else_part_list.append('C' + str(total_if_counter))
                                pass
                            # if_condition_collector_flag = False



                            if re.match('.* if *',line,re.IGNORECASE):
                                node_sequence.append('T' + str(total_if_counter))
                                node_code['T' + str(total_if_counter)] = ''
                                node_sequence.append('F' + str(total_if_counter))
                                node_code['F' + str(total_if_counter)] = ''
                                rare_immediate_if_counter = rare_immediate_if_counter + 1
                                if_nested_collection_line = line
                                continue

                            nested_else_if_flag = False
                            nested_true_part_flag = True

                            nested_true_part_variable = ''

                        else:
                            if_nested_condition_variable_counter = 0
                            if_nested_condition_variable = if_nested_condition_variable + '\n' + line
                            if_nested_condition_variable_counter = if_nested_condition_variable_counter + 1
                            continue


                    if nested_true_part_flag:
                        print("Success")
                        if_nested_collection_line = ""
                        if re.match('.* if *', line, re.IGNORECASE):
                            if re.search('.*ELSE IF.*',line,re.IGNORECASE):
                                node_sequence.append('T' + str(total_if_counter))
                                node_code['T' + str(total_if_counter)] = nested_true_part_variable + '\n'
                                node_sequence.append('F' + str(total_if_counter))
                                node_code['F' + str(total_if_counter)] = ''
                                if_nested_collection_line = line
                                nested_true_part_flag = False
                                nested_else_if_flag = True
                                continue
                            else:
                                node_sequence.append('T' + str(total_if_counter))
                                node_code['T' + str(total_if_counter)] = nested_true_part_variable + '\n'
                                node_sequence.append('F' + str(total_if_counter))
                                node_code['F' + str(total_if_counter)] = ''
                                if_nested_collection_line = line
                                nested_true_part_flag = False
                                nested_if_flag = True
                                continue

                        if re.match('.*end-if.*',line,re.IGNORECASE):
                            node_sequence.append('T' + str(total_if_counter))
                            node_code['T' + str(total_if_counter)] = nested_true_part_variable + '\n' + line
                            node_sequence.append('F' + str(total_if_counter))
                            node_code['F' + str(total_if_counter)] = ''
                            nested_true_part_variable = ''
                            nested_true_part_flag = False
                            # next_line_word = program_procedures[paragraph_name][index + 1]
                            # if re.search
                            #total_if_counter = backup_if_counter
                            #total_if_counter = total_if_counter - 1
                            # true_part_flag = False
                            continue

                        if line.rstrip().endswith("."):
                            node_sequence.append('T' + str(total_if_counter))
                            node_code['T' + str(total_if_counter)] = nested_true_part_variable + '\n' + line
                            node_sequence.append('F' + str(total_if_counter))
                            node_code['F' + str(total_if_counter)] = ''
                            nested_true_part_flag = False
                            continue




                        if re.match('.*else.*',line,re.IGNORECASE):
                            else_index = line.index("ELSE")

                            for iter_counter, iter_index in nested_dict.items():
                                if iter_index == else_index:

                                    if iter_counter in true_if_list:
                                        continue
                                    true_if_counter = iter_counter
                                    true_if_list.append(true_if_counter)



                                    if nested_true_part_variable != '':
                                        if node_code['C' + str(true_if_counter)] != node_code['C' + str(total_if_counter)]:
                                            node_sequence.append('T' + str(total_if_counter))
                                            node_code['T' + str(total_if_counter)] = nested_true_part_variable + '\n'
                                            nested_true_part_flag = False  #
                                            nested_true_part_variable = ''
                                            false_part_flag = True
                                            continue
                                        else:

                                            node_sequence.append('T' + str(true_if_counter))
                                            node_code['T' + str(true_if_counter)] = nested_true_part_variable + '\n'
                                            nested_true_part_flag = False#
                                            nested_true_part_variable = ''
                                            nested_false_if_counter = iter_counter
                                            nested_false_part_flag = True

                                            continue
                                    else:
                                        nested_false_if_counter = iter_counter
                                        nested_true_part_flag = False
                                        nested_false_part_flag = True
                                        continue
                                    #print("Iter_index:",iter_index)

                            for iter_counter, iter_index in main_dict.items():
                                if main_if_index == else_index:
                                    node_sequence.append('T' + str(total_if_counter))
                                    node_code['T' + str(total_if_counter)] = nested_true_part_variable
                                    # Clear the true part variable
                                    nested_true_part_variable = ''
                                    # Set true part flag to false
                                    nested_true_part_flag = False
                                    false_part_flag = True
                                    false_part_variable = ''
                                    continue


                        else:

                            nested_true_part_variable = nested_true_part_variable + '\n' + line
                            continue


                    if nested_false_part_flag:
                        if re.match('.* if *', line, re.IGNORECASE):
                            if nested_false_if_counter != 0:
                                nested_false_if_counter_count = nested_false_if_counter_count + 1
                                node_sequence.append('F' + str(nested_false_if_counter))
                                node_code['F' + str(nested_false_if_counter)] = nested_false_part_variable + '\n'
                                print("false_part-success")
                                if_nested_collection_line = line
                                nested_false_part_flag = False
                                nested_false_part_variable = ''
                                if loop_under_main_else_counter >= 1:
                                    nested_else_if_flag = True
                                    endpoint_list.append('C' + str(nested_false_if_counter))
                                else:

                                    nested_if_flag = True
                                continue
                            else:
                                nested_false_if_counter_count = nested_false_if_counter_count + 1
                                node_sequence.append('F' + str(false_if_counter))
                                node_code['F' + str(false_if_counter)] = nested_false_part_variable + '\n'
                                print("false_part-success")
                                if_nested_collection_line = line
                                nested_false_part_flag = False
                                nested_false_part_variable = ''
                                nested_if_flag = True
                                continue

                        if line.rstrip().endswith("."):
                            if nested_false_if_counter != 0:
                                node_sequence.append('F' + str(nested_false_if_counter))
                                node_code['F' + str(nested_false_if_counter)] = nested_false_part_variable + '\n' + line
                                nested_false_part_flag = False
                                nested_false_part_variable = ''
                                nested_false_if_counter = 0

                                continue
                            # node_sequence.append('T' + str(total_if_counter))
                            # node_code['T' + str(total_if_counter)] = nested_false_part_variable + '\n' + line
                            node_sequence.append('F' + str(total_if_counter))
                            node_code['F' + str(total_if_counter)] = nested_false_part_variable + '\n' + line
                            nested_false_part_flag = False
                            nested_false_part_variable = ''
                            continue

                        if re.match('.*end-if.*',line,re.IGNORECASE):
                            endif_index = line.index("END-IF")
                            for iter_counter, iter_index in nested_dict.items():
                                if iter_index == endif_index:
                                    false_if_counter = iter_counter
                                    node_sequence.append('F' + str(false_if_counter))
                                    node_code['F' + str(false_if_counter)] = nested_false_part_variable + '\n'
                                    nested_false_part_flag = False
                                    break


                        if re.search('.*else.*',line,re.IGNORECASE):
                            else_index = line.index("ELSE")
                            for main_counter,main_index in main_dict.items():
                                if main_index == else_index:
                                    if nested_false_part_variable != '':
                                        if nested_false_if_counter != 0:
                                            node_sequence.append('F' + str(nested_false_if_counter))
                                            node_code['F' + str(nested_false_if_counter)] = nested_false_part_variable + '\n'
                                            nested_false_part_flag = False
                                            nested_false_part_variable = ""

                                            next_line = program_procedures[paragraph_name][index + 1]
                                            if re.search('.* if .*',next_line,re.IGNORECASE):
                                                no_index_iterative_if_counter = no_index_iterative_if_counter + 1
                                                false_part_flag = True
                                            else:
                                                nested_false_if_counter = 0
                                                false_part_flag = True

                                                handle_mainelse_counter = main_counter

                                                continue
                                    else:
                                        nested_false_part_flag = False
                                        nested_false_part_variable = ""
                                        false_part_flag = True
                                        continue

                            continue

                        else:

                            nested_false_part_variable = nested_false_part_variable + '\n' + line
                            continue

                        # nested_true_part_flag = False

                        # else:
                        #
                        #     true_part_variable = true_part_variable + '\n' + line
                        #     continue

                        # If the true part has a dot(.) terminate all nested ifs inside the true block
                        # if re.match('.*\..*', line, re.IGNORECASE):
                        #     truepart_if_opened_count, truepart_if_closed_count = 0, 0
                        #     node_sequence.append('T' + str(total_if_counter))
                        #     node_code['T' + str(total_if_counter)] = true_part_variable + '\n' + line
                        #     node_sequence.append('F' + str(total_if_counter))
                        #     node_code['F' + str(total_if_counter)] = ''
                        #     true_part_flag = False
                        #     continue
                        #
                        # if re.match('.* if *', line, re.IGNORECASE):
                        #     # make sure if execution knows that IFs are no longer tallied
                        #     truepart_ifs_tallied = False
                        #     # Increment the count of opened if statements
                        #     truepart_if_opened_count += 1
                        #     true_part_variable = true_part_variable + '\n' + line
                        #     continue
                        #
                        # if (not truepart_ifs_tallied) and (
                        #         re.match('.*end-if.*', line, re.IGNORECASE) or re.match('.*\.\s.*', line,
                        #                                                                 re.IGNORECASE)):
                        #     truepart_if_closed_count += 1
                        #     true_part_variable = true_part_variable + '\n' + line
                        #     if truepart_if_opened_count == truepart_if_closed_count:
                        #         truepart_ifs_tallied = True
                        #     continue
                        #
                        # if (re.match('.* else *', line, re.IGNORECASE) or re.match('.*end-if.*', line,
                        #                                                            re.IGNORECASE) or re.match('.*\..*',
                        #                                                                                       line,
                        #                                                                                       re.IGNORECASE)) and truepart_ifs_tallied:
                        #     # Condition to capture IF conditions that do not have else parts
                        #     if re.match('.*\..*', line, re.IGNORECASE) or re.match('.*end-if.*', line, re.IGNORECASE):
                        #         node_sequence.append('T' + str(total_if_counter))
                        #         node_code['T' + str(total_if_counter)] = true_part_variable + '\n' + line
                        #         node_sequence.append('F' + str(total_if_counter))
                        #         node_code['F' + str(total_if_counter)] = ''
                        #         true_part_flag = False
                        #         continue
                        #
                        #
                        #     else:
                        #
                        #         # stop collectin the TRUE PART of the condition
                        #         discovered_node = 'T' + str(
                        #             total_if_counter) + ' =>operation:' + true_part_variable + ' | rejected\n'
                        #         node_sequence.append('T' + str(total_if_counter))
                        #         node_code['T' + str(total_if_counter)] = true_part_variable
                        #         # Clear the true part variable
                        #         true_part_variable = ''
                        #         # Set true part flag to false
                        #         true_part_flag = False
                        #         false_part_flag = True
                        #         false_part_variable = ''
                        #         # false_part_variable = false_part_variable + line + '\n'
                        #         continue
                        #
                        # else:
                        #
                        #     true_part_variable = true_part_variable + '\n' + line
                        #     continue

                    if false_part_flag:

                        if re.match('.*\.', line, re.IGNORECASE):
                            if not re.match('.*\.\..*', line, re.IGNORECASE):
                                falsepart_if_opened_count, falsepart_if_closed_count = 0, 0
                                false_part_variable = false_part_variable + line + '\n'
                                if handle_mainelse_counter != 0 and iterative_multuple_else_counter == 0:
                                    node_sequence.append('F' + str(handle_mainelse_counter))
                                    node_code['F' + str(handle_mainelse_counter)] = false_part_variable
                                    # print('false',false_part_variable)
                                    false_part_flag = False
                                    false_part_variable = ""
                                    group_block_flag = True
                                    continue
                                elif iterative_multuple_else_counter > 1:
                                    node_sequence.append('F' + str(total_if_counter))
                                    node_code['F' + str(total_if_counter)] = false_part_variable
                                    # print('false',false_part_variable)
                                    false_part_flag = False
                                    false_part_variable = ''
                                    group_block_flag = True
                                    # total_group_block_counter = total_group_block_counter + 1
                                    continue
                                    print("Final_Success")

                                else:

                                    node_sequence.append('F' + str(total_if_counter))
                                    node_code['F' + str(total_if_counter)] = false_part_variable
                                    # print('false',false_part_variable)
                                    false_part_flag = False
                                    false_part_variable = ''
                                    group_block_flag = True
                                    #total_group_block_counter = total_group_block_counter + 1
                                    continue

                        if re.match('.* if *', line, re.IGNORECASE):
                            if nested_false_if_counter != 0 and no_index_iterative_if_counter == 0  :
                                node_sequence.append('F' + str(nested_false_if_counter))
                                node_code['F' + str(nested_false_if_counter)] = false_part_variable + '\n'
                                endpoint_list.append('C' + str(nested_false_if_counter))
                                false_part_flag = False
                                false_part_variable = ''
                                nested_false_if_counter = 0
                                nested_else_if_flag = True
                                if_nested_collection_line = line
                                continue
                            if no_index_iterative_if_counter == 1:
                                endpoint_list.append('C' + str(nested_false_if_counter))
                                false_part_flag = False
                                false_part_variable = ''
                                nested_false_if_counter = 0
                                nested_else_if_flag = True
                                no_index_iterative_if_counter = 0
                                if_nested_collection_line = line
                                continue
                            if handle_mainelse_counter != 0:
                                node_sequence.append('F' + str(handle_mainelse_counter))
                                node_code['F' + str(handle_mainelse_counter)] = false_part_variable + '\n'
                                # endpoint_list.append('C' + str(handle_mainelse_counter))
                                false_part_flag = False
                                false_part_variable = ''
                                handle_mainelse_counter = 0
                                nested_else_if_flag = True
                                if_nested_collection_line = line
                                continue
                            else:
                                # if nested_false_part_variable != '':
                                #     false_part_flag = False
                                #     nested_false_part_variable = ''
                                #     false_part_variable = ''
                                #     iterative_multuple_else_counter = iterative_multuple_else_counter + 1
                                #     nested_else_if_flag = True
                                #     if_nested_collection_line = line
                                #     continue
                                # else:

                                    node_sequence.append('F' + str(total_if_counter))
                                    node_code['F' + str(total_if_counter)] = false_part_variable + '\n'
                                    endpoint_list.append('C' + str(total_if_counter))
                                    false_part_flag = False
                                    false_part_variable = ''
                                    nested_else_if_flag = True
                                    loop_under_main_else_counter = loop_under_main_else_counter + 1
                                    if_nested_collection_line = line
                                    continue
                            # # make sure if execution knows that IFs are no longer tallied
                            # falsepart_ifs_tallied = False
                            # # Increment the count of opened if statements
                            # falsepart_if_opened_count += 1
                            # false_part_variable = false_part_variable + '\n' + line
                            # continue

                        if (not falsepart_ifs_tallied) and (
                                re.match('.*end-if.*', line, re.IGNORECASE) or re.match('.*\.\s*.*', line,
                                                                                        re.IGNORECASE)):
                            falsepart_if_closed_count += 1
                            false_part_variable = false_part_variable + '\n' + line
                            if falsepart_if_opened_count == falsepart_if_closed_count:
                                falsepart_ifs_tallied = True
                            continue

                        if (re.match('.*end-if.*', line, re.IGNORECASE) or re.match('.*\.\s*.*', line,
                                                                                    re.IGNORECASE)) and falsepart_ifs_tallied:
                            if not re.match('.*\.\..*', line, re.IGNORECASE):
                                # if any one of the above is true
                                false_part_variable = false_part_variable + line + '\n'
                                discovered_node = 'F' + str(
                                    total_if_counter) + ' =>operation:' + false_part_variable + ' | rejected\n'
                                # print(discovered_node)
                                node_sequence.append('F' + str(total_if_counter))
                                node_code['F' + str(total_if_counter)] = false_part_variable
                                # print('false',false_part_variable)
                                false_part_flag = False
                                group_block_flag = True
                                #total_group_block_counter = total_group_block_counter + 1

                                continue

                            else:
                                false_part_variable = false_part_variable + '\n' + line
                                continue

                        else:
                             if re.search('.* else.*',line,re.IGNORECASE):
                                 continue
                             else:

                                false_part_variable = false_part_variable + '\n' + line
                                continue

                skip = True

                if re.match('.* if *', line, re.IGNORECASE):
                    # new if condition found, increment the global if counter
                    print("Line_indexx:",index)
                    main_dict = {}
                    total_if_counter = total_if_counter + 1
                    check_if_counter = check_if_counter + 1
                    main_if_index = line.casefold().index("if")
                    main_dict[total_if_counter] = main_if_index
                    # Start collecting the condition
                    if_condition_variable = line
                    if_condition_collector_flag = True
                    group_block_flag = False
                    if group_block_variable != '':
                        if group_block_variable[main_if_index] != "":
                            total_group_block_counter = total_group_block_counter + 1
                            node_sequence.append('G' + str(total_group_block_counter))
                            false_tag_list.append('G' + str(total_group_block_counter))
                            node_code['G' + str(total_group_block_counter)] = group_block_variable
                            group_block_variable = ''
                    continue

                if re.search('.*end-if.*',line,re.IGNORECASE):
                    continue


                # check if the word perform shows up in the line
                if re.match('.* PERFORM\s.*', line):

                    # If the perform statement is terminating in single line then kachak

                    # Once the perform keyword is identified below three possiblities can occur
                    # Perform ends in the same line
                    # Single line perform spperform_blockans over multiple lines
                    # Multi line perform exists

                    current_line_word_list = line.split()
                    # try:
                    #     position_of_perform_currentline = current_line_word_list.index('PERFORM')
                    # except:
                    #     break
                    position_of_perform_currentline = current_line_word_list.index('PERFORM')
                    inline_perform_keyword_list = ['UNTIL', 'VARYING']

                    if len(current_line_word_list) - 2 >= position_of_perform_currentline:
                        first_word_after_perform = current_line_word_list[position_of_perform_currentline + 1]
                        if (first_word_after_perform in inline_perform_keyword_list):
                            # start the inline perform catcher logic
                            perform_inline_collector_flag = True
                            perform_inline_collector_variable = line
                            # total_individual_block_counter = total_individual_block_counter + 1
                            # node_sequence.append('S' + str(total_individual_block_counter))
                            # node_code['S' + str(total_individual_block_counter)] = line
                            continue

                        if len(current_line_word_list) - 1 >= position_of_perform_currentline + 2:
                            if current_line_word_list[position_of_perform_currentline + 2] == 'TIMES':
                                # start the inline perform catcher logic
                                perform_inline_collector_flag = True
                                perform_inline_collector_variable = line
                                continue

                    try:
                        next_line_word_list = program_procedures[paragraph_name][index + 1].split()
                    except:
                        if group_block_variable != '':
                            total_group_block_counter = total_group_block_counter + 1
                            node_sequence.append('G' + str(total_group_block_counter))
                            false_tag_list.append('G' + str(total_group_block_counter))
                            node_code['G' + str(total_group_block_counter)] = group_block_variable
                            group_block_variable = ''
                        total_individual_block_counter = total_individual_block_counter + 1
                        except_block_variable = line + '\n'
                        node_sequence.append('S' + str(total_individual_block_counter))
                        false_tag_list.append('S' + str(total_individual_block_counter))
                        node_code['S' + str(total_individual_block_counter)] = except_block_variable
                        except_block_variable = ''
                        continue

                    # If the last word is perform which means the next line contatins the important keywords
                    if (position_of_perform_currentline + 1) == len(current_line_word_list):
                        # check if it has at least two words
                        if len(next_line_word_list) >= 2:
                            if next_line_word_list[1] == 'TIMES':
                                # start the inline perform catcher logic
                                perform_inline_collector_flag = True
                                perform_inline_collector_variable = line
                                continue
                        if len(next_line_word_list) >= 1:
                            if (next_line_word_list[0] in inline_perform_keyword_list):
                                # start the inline perform catcher logic
                                perform_inline_collector_flag = True
                                perform_inline_collector_variable = line
                                continue

                    # If non of the perform logics are accepted then search for occurence of next cobol keyword
                    multiline_perform_started_flag = True
                    multiline_perform_started_variable = line
                    group_block_flag = False
                    if group_block_variable != '':
                        total_group_block_counter = total_group_block_counter + 1
                        node_sequence.append('G' + str(total_group_block_counter))
                        false_tag_list.append('G' + str(total_group_block_counter))
                        node_code['G' + str(total_group_block_counter)] = group_block_variable
                        group_block_variable = ''
                    continue

                if re.match('.* evaluate .*', line, re.IGNORECASE):
                    eval_variable = ''
                    eval_index = line.index("EVALUATE")
                    total_individual_block_counter = total_individual_block_counter + 1
                    # if re.match('.*\.\s*', line):
                    eval_variable = line + '\n'
                    # Set the perform varying collector flag
                    eval_flag = True
                    if group_block_variable != '':
                        total_group_block_counter = total_group_block_counter + 1
                        node_sequence.append('G' + str(total_group_block_counter))
                        node_code['G' + str(total_group_block_counter)] = group_block_variable
                        group_block_variable = ''
                    continue

                if re.match('.* exec .*', line, re.IGNORECASE):
                    if not re.match('.* exec .*end-exec.*', line, re.IGNORECASE):
                        exec_variable = ''
                        total_individual_block_counter = total_individual_block_counter + 1
                        # if re.match('.*\.\s*', line):
                        exec_variable = line + '\n'
                        # Set the perform varying collector flag
                        exec_flag = True
                        if group_block_variable != '':
                            total_group_block_counter = total_group_block_counter + 1
                            node_sequence.append('G' + str(total_group_block_counter))
                            false_tag_list.append('G' + str(total_group_block_counter))
                            node_code['G' + str(total_group_block_counter)] = group_block_variable
                            group_block_variable = ''
                        continue
                    else:
                        exec_variable = ''
                        total_individual_block_counter = total_individual_block_counter + 1
                        node_sequence.append('S' + str(total_individual_block_counter))
                        false_tag_list.append('S' + str(total_individual_block_counter))
                        node_code['S' + str(total_individual_block_counter)] = line
                        group_block_flag = False
                        if group_block_variable != '':
                            total_group_block_counter = total_group_block_counter + 1
                            node_sequence.append('G' + str(total_group_block_counter))
                            false_tag_list.append('G' + str(total_group_block_counter))
                            node_code['G' + str(total_group_block_counter)] = group_block_variable
                            group_block_variable = ''
                        continue

                if re.match('.* open .*', line, re.IGNORECASE):
                    if not re.match('.* open .*\..*', line, re.IGNORECASE):
                        open_variable = ''
                        total_individual_block_counter = total_individual_block_counter + 1
                        # if re.match('.*\.\s*', line):
                        open_variable = line + '\n'
                        # Set the perform varying collector flag
                        open_flag = True
                        if group_block_variable != '':
                            total_group_block_counter = total_group_block_counter + 1
                            node_sequence.append('G' + str(total_group_block_counter))
                            false_tag_list.append('G' + str(total_group_block_counter))
                            node_code['G' + str(total_group_block_counter)] = group_block_variable
                            group_block_variable = ''
                        continue
                    else:
                        open_variable = ''
                        group_block_flag = False
                        if group_block_variable != '':
                            total_group_block_counter = total_group_block_counter + 1
                            node_sequence.append('G' + str(total_group_block_counter))
                            false_tag_list.append('G' + str(total_group_block_counter))
                            node_code['G' + str(total_group_block_counter)] = group_block_variable
                            group_block_variable = ''
                        total_individual_block_counter = total_individual_block_counter + 1
                        node_sequence.append('S' + str(total_individual_block_counter))
                        false_tag_list.append('S' + str(total_individual_block_counter))
                        node_code['S' + str(total_individual_block_counter)] = line
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
                            false_tag_list.append('G' + str(total_group_block_counter))
                            node_code['G' + str(total_group_block_counter)] = group_block_variable
                            group_block_variable = ''
                        continue
                    else:
                        if group_block_variable != '':
                            total_group_block_counter = total_group_block_counter + 1
                            node_sequence.append('G' + str(total_group_block_counter))
                            false_tag_list.append('G' + str(total_group_block_counter))
                            node_code['G' + str(total_group_block_counter)] = group_block_variable
                            group_block_variable = ''
                        set_variable = ''
                        total_individual_block_counter = total_individual_block_counter + 1
                        node_sequence.append('S' + str(total_individual_block_counter))
                        false_tag_list.append('S' + str(total_individual_block_counter))
                        node_code['S' + str(total_individual_block_counter)] = line
                        group_block_flag = False

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
                            false_tag_list.append('G' + str(total_group_block_counter))
                            node_code['G' + str(total_group_block_counter)] = group_block_variable
                            group_block_variable = ''
                        continue
                    else:
                        group_block_flag = False
                        if group_block_variable != '':
                            total_group_block_counter = total_group_block_counter + 1
                            node_sequence.append('G' + str(total_group_block_counter))
                            false_tag_list.append('G' + str(total_group_block_counter))
                            node_code['G' + str(total_group_block_counter)] = group_block_variable
                            group_block_variable = ''
                        delete_variable = ''
                        total_individual_block_counter = total_individual_block_counter + 1
                        node_sequence.append('P' + str(total_individual_block_counter))
                        false_tag_list.append('P' + str(total_individual_block_counter))
                        node_code['P' + str(total_individual_block_counter)] = line
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
                            false_tag_list.append('G' + str(total_group_block_counter))
                            node_code['G' + str(total_group_block_counter)] = group_block_variable
                            group_block_variable = ''
                        continue
                    else:
                        group_block_flag = False
                        if group_block_variable != '':
                            total_group_block_counter = total_group_block_counter + 1
                            node_sequence.append('G' + str(total_group_block_counter))
                            false_tag_list.append('G' + str(total_group_block_counter))
                            node_code['G' + str(total_group_block_counter)] = group_block_variable
                            group_block_variable = ''
                        write_variable = ''
                        total_individual_block_counter = total_individual_block_counter + 1
                        node_sequence.append('P' + str(total_individual_block_counter))
                        false_tag_list.append('P' + str(total_individual_block_counter))
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
                            false_tag_list.append('G' + str(total_group_block_counter))
                            node_code['G' + str(total_group_block_counter)] = group_block_variable
                            group_block_variable = ''
                        continue
                    else:
                        group_block_flag = False
                        if group_block_variable != '':
                            total_group_block_counter = total_group_block_counter + 1
                            node_sequence.append('G' + str(total_group_block_counter))
                            false_tag_list.append('G' + str(total_group_block_counter))
                            node_code['G' + str(total_group_block_counter)] = group_block_variable
                            group_block_variable = ''
                        rewrite_variable = ''
                        total_individual_block_counter = total_individual_block_counter + 1
                        node_sequence.append('P' + str(total_individual_block_counter))
                        false_tag_list.append('P' + str(total_individual_block_counter))
                        node_code['P' + str(total_individual_block_counter)] = line
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
                            false_tag_list.append('G' + str(total_group_block_counter))
                            node_code['G' + str(total_group_block_counter)] = group_block_variable
                            group_block_variable = ''
                        continue
                    else:
                        read_variable = ''
                        if group_block_variable != '':
                            total_group_block_counter = total_group_block_counter + 1
                            node_sequence.append('G' + str(total_group_block_counter))
                            false_tag_list.append('G' + str(total_group_block_counter))
                            node_code['G' + str(total_group_block_counter)] = group_block_variable
                            group_block_variable = ''
                        total_individual_block_counter = total_individual_block_counter + 1
                        node_sequence.append('P' + str(total_individual_block_counter))
                        false_tag_list.append('P' + str(total_individual_block_counter))
                        node_code['P' + str(total_individual_block_counter)] = line
                        group_block_flag = False
                        continue

                if re.match('.* call .*', line, re.IGNORECASE):
                    if re.match('.* call .*\.\s*', line, re.IGNORECASE):
                        group_block_flag = False
                        if group_block_variable != '':
                            total_group_block_counter = total_group_block_counter + 1
                            node_sequence.append('G' + str(total_group_block_counter))
                            false_tag_list.append('G' + str(total_group_block_counter))
                            node_code['G' + str(total_group_block_counter)] = group_block_variable
                            group_block_variable = ''
                        call_variable = ''
                        total_individual_block_counter = total_individual_block_counter + 1
                        node_sequence.append('S' + str(total_individual_block_counter))
                        false_tag_list.append('S' + str(total_individual_block_counter))
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
                            false_tag_list.append('G' + str(total_group_block_counter))
                            node_code['G' + str(total_group_block_counter)] = group_block_variable
                            group_block_variable = ''
                            continue
                        else:
                            continue
                # if group_block_flag:
                #     group_block_variable = group_block_variable +'\n'+ line
                #     continue

                # if any(ext in line for ext in keywords_for_group_variables):
                #     group_block_variable = group_block_variable + line + '\n'
                #     continue

                if line.strip() != '':
                    if line.strip() != '.':
                        group_block_variable = group_block_variable + line + '\n'
                        continue

            # if group_block_flag and group_block_variable!='':
            if group_block_variable != '':
                if group_block_variable[main_if_index] != "":

                    total_group_block_counter = total_group_block_counter + 1
                    node_sequence.append('G' + str(total_group_block_counter))
                    false_tag_list.append('G' + str(total_group_block_counter))
                    node_code['G' + str(total_group_block_counter)] = group_block_variable
                    group_block_variable = ''

                else:
                    total_group_block_counter = total_group_block_counter + 1
                    node_sequence.append('G' + str(total_group_block_counter))
                    false_tag_list.append('G' + str(total_group_block_counter))
                    node_code['G' + str(total_group_block_counter)] = group_block_variable
                    group_block_variable = ''

                # node_definitions = node_definitions + '\n'+ discovered_node
            print('Filename:', COMPONENT_NAME + '\n' + 'Paragraph:', paragraph_name)
            # print(node_sequence)
            # print(json.dumps(node_code, indent=4))
        except Exception as e:
            print(e)

        # if false_tag_list[0] != C:
        #     false_tag_list.remove(false_tag_list[0])
            # if iter_link.startswith("C"):
            #false_tag_list.remove(iter_link)
        # print("Iter_Success:",false_tag_list)
        # print("Else_Success:",nested_else_part_list)
        # print("rare_immediate:",rare_immediate_tag_list)
        # print("original_multilevel:",multilevel_else_if_list)
        for node_sequence_iteration in rare_immediate_tag_list:
            if node_sequence_iteration in multilevel_else_if_list:
                multilevel_else_if_list.remove(node_sequence_iteration)
        print("Multilevel_else_if_list:",multilevel_else_if_list)
        node_string = 'st=>start: START | past\ne=>end: END | past \n'
        links_string = 'st'
        try:
            for i in range(0, len(node_sequence)):
                # Make sure the leading line breaks are STRIPPED
                check_helpful_list.append(node_sequence[i])
                node_code[node_sequence[i]] = node_code[node_sequence[i]].lstrip('\n')
                node_code[node_sequence[i]] = node_code[node_sequence[i]].replace('=>', '= >')
                print("Test_1:",false_tag_list)
                if re.match('^S.*', node_sequence[i]) or re.match('^G.*', node_sequence[i]):
                    links_string = links_string + '->' + node_sequence[i] + '\n' + node_sequence[i]

                    if node_sequence[i] in false_tag_list:
                        false_tag_list.remove(node_sequence[i])
                        print("testing:",false_tag_list)
                    node_string = node_string + node_sequence[i] + '=>operation: ' + node_code[
                        node_sequence[i]] + ' | approved\n'
                if re.match('^P.*', node_sequence[i]):
                    links_string = links_string + '->' + node_sequence[i] + '\n' + node_sequence[i]
                    node_string = node_string + node_sequence[i] + '=>inputoutput: ' + node_code[
                        node_sequence[i]] + ' | io\n'

                if re.match('^C.*', node_sequence[i]):
                    if node_sequence[i] in nested_else_part_list:
                        # backup_nested_else_part_list.add(node_sequence[i])
                        nested_else_part_list.remove(node_sequence[i])
                    if node_sequence[i] in false_tag_list:
                        false_tag_list.remove(node_sequence[i])
                    if node_sequence[i] in immediate_tag_list:
                        immediate_tag_list.remove(node_sequence[i])
                    if node_sequence[i] in multilevel_else_if_list:
                        multilevel_else_if_list.remove(node_sequence[i])
                    # if node_sequence[i] in rare_immediate_tag_list:
                    #     rare_immediate_tag_list.remove(node_sequence[i])
                        #print("Failure_test:",nested_else_part_list)
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
                            # If there is not else part
                            if node_code[node_sequence[i + 1]] == '':
                                links_string = links_string + '->' + node_sequence[i] + '\n' + node_sequence[
                                    i] + '(yes)'
                                if node_sequence[i + 3] in rare_immediate_tag_list:
                                    for immediate_iter in rare_immediate_tag_list:

                                        if immediate_iter in check_helpful_list:
                                            continue
                                        else:

                                            links_string = links_string + '->' + immediate_iter + '\n' + node_sequence[
                                                i] + '(no)'
                                            break
                                else:
                                    for immediate_iter in immediate_tag_list:

                                        links_string = links_string + '->' + immediate_iter + '\n' + node_sequence[
                                            i] + '(no)'
                                        break
                            # links_string = links_string + '->' + node_sequence[i + 1] + '\n' + node_sequence[
                            #     i] + '(no)'
                                if node_sequence[i + 3] in rare_immediate_tag_list:
                                    for iter_linker in multilevel_else_if_list:

                                        links_string = links_string + '->' + iter_linker + '\n' + node_sequence[i + 3]
                                        break
                                else:

                                    if false_tag_list == []:
                                        links_string = links_string + '->e' + '\n' + node_sequence[i + 3]

                                    for iter_link in false_tag_list:
                                        # if iter_link[0] != "C":

                                              links_string = links_string + '->' + iter_link + '\n' + node_sequence[i + 3]
                                              break
                                # else:
                                #     continue
                            else:
                                links_string = links_string + '->' + node_sequence[i] + '\n' + node_sequence[
                                    i] + '(yes)'
                                links_string = links_string + '->' + node_sequence[i + 1] + '\n' + node_sequence[
                                    i] + '(no)'
                                for iter_link in false_tag_list:
                                    # if iter_link[0] != "C":

                                    links_string = links_string + '->' + iter_link + '\n' + node_sequence[i + 1]
                                    break
                                if false_tag_list == []:
                                    links_string = links_string + '->e' + '\n' + node_sequence[i + 1]
                        else:
                            # If there is an else part, behave normally
                            links_string = links_string + '->' + node_sequence[i] + '\n' + node_sequence[
                                i] + '(yes)'
                            links_string = links_string + '->' + node_sequence[i + 1] + '\n' + node_sequence[
                                i] + '(no)'

                            if node_code[node_sequence[i + 2]] == '\n':
                                links_string = links_string + '->' + node_sequence[i + 3] + '\n'

                            else:

                                links_string = links_string + '->' + node_sequence[i + 2]

                    ## Main true block has contents and main false block has contents, after false block content to handle nested-if's
                    ## endpoint list captures the Main IF counter after encountering Main else false block contents
                    ## multilevel_else_if_list contains all nested if's under Main else block
                            if node_sequence[i] in endpoint_list:
                                if false_tag_list == []:
                                    links_string = links_string + '\n' + node_sequence[i + 1] + '->e'
                                    if  node_code[node_sequence[i + 2]] == '\n':
                                       for iter_link in multilevel_else_if_list:
                                          links_string = links_string + '\n' + iter_link
                                          break
                                    else:
                                        for iter_link in multilevel_else_if_list:
                                            links_string = links_string +  '\n' + node_sequence[i + 2] + '->' + iter_link
                                            break
                                else:
                                    if node_code[node_sequence[i + 2]] == '\n':
                                        for iter_link in false_tag_list:
                                            links_string = links_string + '\n' + node_sequence[i + 1] + '->' + iter_link + '\n' + node_sequence[i + 3]
                                            break
                                    else:
                                        if node_sequence[i] in rare_immediate_tag_list:
                                            for iter_link in false_tag_list:
                                                links_string = links_string + '\n' + node_sequence[i + 1] + '->' + iter_link
                                                break
                                            for iter_link in false_tag_list:
                                                links_string = links_string + '\n' + node_sequence[i + 2] + '->' + iter_link + '\n' + node_sequence[i + 3]
                                                break
                                        else:

                                            for iter_link in multilevel_else_if_list:
                                                    links_string = links_string + '\n' + node_sequence[i + 1] + '->' + iter_link
                                                    break

                                            for iter_link in multilevel_else_if_list:

                                                    links_string = links_string +  '\n' + node_sequence[i + 2] + '->' + iter_link
                                                    break


                            else:

                                if node_sequence[i + 3] in check_helpful_list:
                                    if false_tag_list == []:
                                        links_string = links_string + '\n' + node_sequence[i + 1] + '->e'
                                        links_string = links_string + '\n' + node_sequence[i + 2] + '->e' + '\n' + node_sequence [i + 3]
                                    else:
                                        for iter_link in false_tag_list:
                                            links_string = links_string + '\n' + node_sequence[i + 1] + '->' + iter_link
                                            break
                                        for iter_link in false_tag_list:
                                            links_string = links_string + '\n' + node_sequence[
                                                i + 2] + '->' + iter_link
                                            break
                                else:
                                    if  node_sequence[i] in multilevel_if_list and nested_else_part_list != []:
                                        links_string = links_string + '\n' + node_sequence[i + 1] + '->e'
                                    else:

                                        links_string = links_string + '\n' + node_sequence[i + 1] + '->' + node_sequence[i + 3]
                                for else_link in nested_else_part_list:


                                          # links_string = links_string + '\n' + else_link + '->' + node_sequence[i + 3]
                                               links_string = links_string + '\n' + node_sequence[i + 2] + '->' + else_link
                                               break

                                if node_sequence[i] in multilevel_if_list:
                                    for iter_link in false_tag_list:
                                        links_string = links_string + '\n' + node_sequence[i + 2] + '->' + iter_link
                                        break

                                else:




                                    if nested_else_part_list == []:
                                        # if node_sequence[i + 3] in check_helpful_list:
                                        #     if false_tag_list == []:
                                        #         links_string = links_string + '\n' + node_sequence[i + 2] + '->e' + '\n' + node_sequence [i + 3]
                                        #     else:
                                        #         for iter_link in false_tag_list:
                                        #             links_string = links_string + '\n' + node_sequence[
                                        #                 i + 2] + '->' + iter_link
                                        #             break
                                        # else:

                                            links_string = links_string + '\n' + node_sequence[i + 2] + '->' + \
                                                               node_sequence[i + 3]


                            # links_string = links_string + '\n' + node_sequence[i + 2] + '->' + node_sequence[i + 3]
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

         ## the below 4 lines are used to remove the blank lines in links string

        lines = links_string.split("\n")
        non_empty_lines = [line for line in lines if line.strip() != ""]

        links_string = ""
        for line in non_empty_lines:
            links_string += line + "\n"



        # print("Link_Success:",links_string)
        # print(node_sequence)
        # print(node_string)
        # print(links_string)
        # print({"option": node_string + '\n' + links_string,"component_name":COMPONENT_NAME,"para_name":paragraph_name.split('.')[0]})
        OUTPUT_DATA.append({"option": node_string + '\n' + links_string, "component_name": COMPONENT_NAME,
                            "para_name": paragraph_name.split('.')[0]})
        # print(node_sequence)
        print("option:",node_string + '\n' + links_string)
        node_sequence.clear()
        false_tag_list.clear()
        nested_else_part_list.clear()
        immediate_tag_list.clear()
        multilevel_if_list.clear()
        check_helpful_list.clear()
        backup_nested_else_part_list.clear()
        endpoint_list.clear()
        node_string = ''
        links_string = ''

# Delete already existing data
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
