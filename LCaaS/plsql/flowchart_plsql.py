SCRIPT_VERSION = 'Werner coustmized code '

from pymongo import MongoClient



import pytz
import datetime,json
import plsql_config

import copy

time_zone = 'Asia/Calcutta'
tz = pytz.timezone(time_zone)
import glob,os,re
file = plsql_config.file


time_zone = 'Asia/Calcutta'
tz = pytz.timezone(time_zone)

client = MongoClient('localhost', 27017)
db = client['plsql']

OUTPUT_DATA = []



def trigger(filename,Type,file_location):
    ModuleName = filename
    ModuleType = Type
    print("Module:", ModuleName)
    f = open(ModuleName, "r")
    count = 0
    dict = {}
    comment_flag = False
    procedure_name = ""
    procedure_flag = False
    procedure_open_flag = False
    storage = []

    for line in f.readlines():
        line = line.strip()
        print("Lines:", line)
        if line == "":
            continue
        if line.endswith("*/"):
            comment_flag = False
            continue

        if comment_flag:
            continue

        if line.startswith("/*"):
            comment_flag = True
            continue

        if line.startswith("--"):
            continue

        if re.search("END;",line) or (line == "END" +" " + procedure_name + ";") :
            #if not (re.search("END LOOP",line) or re.search("END IF",line)):
                print("Storage:",storage)
                storage.append(line)
                dict[fun_name] = copy.deepcopy(storage)
                storage.clear()
                procedure_flag = False
                procedure_open_flag = False
                pass

        if procedure_flag:
            count = count + 1
            storage.append(line)
            continue


        if procedure_open_flag:
            if re.search("BEGIN.*",line):
                #print("BEGIN:",line)
                procedure_flag = True
                procedure_open_flag = False
                fun_name = procedure_name
                continue
            else:
                continue


        if re.search("TRIGGER.*", line):
            # print("PROCEDURE:",line)
            line = line.split("TRIGGER")
            print("Trigger:", line)
            procedure_name = line[1].strip("(").strip()
            print("TRIGGER_NAME:", procedure_name)
            procedure_open_flag = True

    return dict

def function(filename,Type,file_location):
    ModuleName = filename
    ModuleType = Type
    print("Module:", ModuleName)
    f = open(ModuleName, "r")
    count = 0
    dict = {}
    comment_flag = False
    procedure_name = ""
    procedure_flag = False
    procedure_open_flag = False
    storage = []

    for line in f.readlines():
        line = line.strip()
        print("Lines:",line)
        if line == "":
            continue
        if line.endswith("*/"):
            comment_flag = False
            continue

        if comment_flag:
            continue

        if line.startswith("/*"):
            comment_flag = True
            continue

        if line.startswith("--"):
            continue

        if (line == "END" + " " + procedure_name + ";"):
            # if not (re.search("END LOOP",line) or re.search("END IF",line)):
            print("Storage:", "Success")
            storage.append(line)
            dict[fun_name] = copy.deepcopy(storage)
            storage.clear()
            procedure_flag = False
            procedure_open_flag = False
            pass



        if procedure_flag:
            count = count + 1
            storage.append(line)
            continue


        if procedure_open_flag:
            if re.search("BEGIN.*",line):
                procedure_flag = True
                procedure_open_flag = False
                fun_name = procedure_name
                continue
            else:
                continue




        if re.search("FUNCTION.*", line):
            # print("PROCEDURE:",line)
            line = line.split("FUNCTION")
            #print("Function:",line)
            procedure_name = line[1] . strip("(") . strip()
            #print("PROCEDURE_NAME:", procedure_name)
            procedure_open_flag = True

    print("FNC:", json.dumps(dict, indent=4))
    return dict


def standalone(filename,Type,file_location):
    ModuleName = filename
    ModuleType = Type
    print("Module:", ModuleName)
    f = open(ModuleName, "r")
    count = 0
    dict = {}
    comment_flag = False
    procedure_name = ""
    procedure_flag = False
    procedure_open_flag = False
    storage = []

    for line in f.readlines():
        line = line.strip()

        if line == "":
            continue
        if line.endswith("*/"):
            comment_flag = False
            continue

        if comment_flag:
            continue

        if line.startswith("/*"):
            comment_flag = True
            continue

        if line.startswith("--"):
            continue

        if re.search("END;",line) or (line == "END" +" " + procedure_name + ";") :
            #if not (re.search("END LOOP",line) or re.search("END IF",line)):
                #print("Storage:",storage)
                storage.append(line)
                dict[fun_name] = copy.deepcopy(storage)
                storage.clear()
                procedure_flag = False
                procedure_open_flag = False
                pass


        if procedure_flag:
            count = count + 1
            storage.append(line)
            continue


        if procedure_open_flag:
            if re.search("BEGIN.*",line):
                procedure_flag = True
                fun_name = procedure_name
                continue
            else:
                continue


        if re.search("PROCEDURE.*", line):
            # print("PROCEDURE:",line)
            line = line.split("PROCEDURE")
            #print("Standalone:",line)
            procedure_name = line[1].strip("(").strip()
            #print("PROCEDURE_NAME:", procedure_name)
            procedure_open_flag = True


    #print("PRC:",json.dumps(dict, indent=4))
    return dict

def ProgramType(filename,Type,file_location):
    ModuleName = filename
    ModuleType = Type
    print("Module:", ModuleName)
    f = open(ModuleName, "r")

    count = 0
    dict = {}
    comment_flag = False
    procedure_name = ""
    procedure_flag = False
    procedure_open_flag = False
    storage = []
    begin_counter = 0
    case_counter = 0



    f = open(filename, "r")
    for line in f.readlines():
        line = line.strip()

        if line == "":
            continue
        if line.endswith("*/"):
            comment_flag = False
            continue

        if comment_flag:
            continue

        if line.startswith("/*"):
            comment_flag = True
            continue

        if line.startswith("--"):
            continue

        if (line == "END" + " " + procedure_name + ";") or (begin_counter == 1 and re.search("^END;", line) and case_counter ==0):
            begin_counter = 0
            storage.append(line)
            if fun_name in dict:
                dict[fun_name].extend(copy.deepcopy(storage))
            else:
                dict[fun_name] = copy.deepcopy(storage)
            storage.clear()
            procedure_flag = False

        if procedure_flag:
            if re.search("BEGIN.*", line):
                begin_counter = begin_counter + 1

            if begin_counter >= 1 and  (line.strip().startswith("CASE")or line.strip().startswith("(SELECT CASE")):
                case_counter = case_counter + 1

            if case_counter ==0 and (re.search("^END;", line) or re.search("^END$", line.strip())) :
                begin_counter = begin_counter - 1

            if case_counter > 0 and (re.search("^END;", line) or line.strip().startswith("END")):
                case_counter = case_counter - 1
            count = count + 1
            storage.append(line.replace("-->>", "").replace("->", ""))
            continue

        if procedure_open_flag:
            if re.search("BEGIN.*", line):
                begin_counter = begin_counter + 1
                procedure_flag = True
                procedure_open_flag = False
                fun_name = procedure_name
                continue
            else:
                continue

        if re.search("PROCEDURE.*", line):
            try:
                print("PROCE_PACKAGE:", line)
                line = line.split()
                if len(line) > 1:
                    procedure_name = line[1]
                    print("PROCEDURE_NAME:", procedure_name)
                    procedure_open_flag = True
            except Exception as e:
                print(e)

    return dict


def process(dict,filename):
    #print("Passed:",json.dumps(dict, indent=4))
    component_name = filename
    #print("Component:",component_name)
    list_of_functions = list(dict.keys())
    #print("List_of_functions:", list_of_functions)
    discovered_node = ''

    keywords_for_if_delimiter = ['THEN']
    total_if_counter = 0
    total_elif_counter = 0

    elif_part_flag = False
    elif_part_variable = ''

    true_part_flag = False
    true_part_variable = ''

    false_part_flag = False
    false_part_variable = ''

    if_index = 0
    if_condition_variable = ""
    if_condition_collector_flag = False

    update_variable = ""
    update_flag = False

    select_variable = ""
    select_flag = False

    insert_variable = ""
    insert_flag = False

    # First level IFs true part tally logic helpers
    truepart_ifs_tallied = True
    truepart_if_opened_count = 0
    truepart_if_closed_count = 0

   # First level IFs false part tally logic helpers
    falsepart_ifs_tallied = True
    falsepart_if_opened_count = 0
    falsepart_if_closed_count = 0

    elifpart_ifs_tallied = True
    elifpart_if_opened_count = 0
    elifpart_if_closed_count = 0


    forall_flag = False
    forall_variable = ""

    case_when_flag = False
    case_when_variable = ""

    exception_flag = False
    exception_when_flag = False
    exception_when_variable = ""

    delete_variable = ""
    delete_flag = False

    for_variable = ""
    for_flag = False

    while_variable = ""
    while_flag = False

    loop_variable = ''
    end_loop_variable = ''

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
    # OUTPUT_DATA = []

    for function in list_of_functions:
        #print("Function_checking:", list_of_functions)
        for index, line in enumerate(dict[function]):
            # print("Passed_Checking:",json.dumps(dict, indent=4))



            if exception_when_flag:
                #if line.startswith("WHEN"):
                    print("when:",line)
                    try:
                        next_when_line = dict[function][index+1]
                        if next_when_line.startswith("WHEN"):
                            exception_when_variable = exception_when_variable + '\n' + line
                            node_sequence.append('S' + str(total_individual_block_counter))
                            node_code['S' + str(total_individual_block_counter)] = exception_when_variable
                            exception_when_variable = ''
                            total_individual_block_counter = total_individual_block_counter + 1
                            #exception_when_flag = False
                            continue
                        elif next_when_line.startswith("END"):
                            exception_when_variable = exception_when_variable + '\n' + line
                            continue
                        elif line.startswith("END"):
                            exception_when_variable = exception_when_variable + '\n' + line
                            node_sequence.append('S' + str(total_individual_block_counter))
                            node_code['S' + str(total_individual_block_counter)] = exception_when_variable
                            exception_when_variable = ''
                            exception_when_flag = False
                            continue

                        else:

                            exception_when_variable = exception_when_variable + '\n' + line
                            continue

                    except:
                                if line.startswith("END"):
                                    exception_when_variable = exception_when_variable + '\n' + line
                                    node_sequence.append('S' + str(total_individual_block_counter))
                                    node_code['S' + str(total_individual_block_counter)] = exception_when_variable
                                    exception_when_variable = ''
                                    exception_when_flag = False
                                    continue

            if case_when_flag:

                        if line.startswith("WHEN"):
                            case_when_variable = case_when_variable + '\n' + line
                            node_sequence.append('S' + str(total_individual_block_counter))
                            node_code['S' + str(total_individual_block_counter)] = case_when_variable
                            case_when_variable = ''
                            total_individual_block_counter = total_individual_block_counter + 1
                            #exception_when_flag = False
                            continue
                        # elif next_when_line.startswith("END"):
                        #     exception_when_variable = exception_when_variable + '\n' + line
                        #     continue
                        elif re.search("END CASE;",line):
                            case_when_variable = case_when_variable + '\n' + line
                            node_sequence.append('S' + str(total_individual_block_counter))
                            node_code['S' + str(total_individual_block_counter)] = case_when_variable
                            case_when_variable = ''
                            case_when_flag = False
                            continue

                        else:

                            case_when_variable = case_when_variable + '\n' + line
                            continue






            if for_flag:
                #try:
                    #next_for_line = dict[function][index+1]
                    if re.search("LOOP.*",line,re.IGNORECASE):
                        for_variable = for_variable + '\n'
                        node_sequence.append('S' + str(total_individual_block_counter))
                        node_code['S' + str(total_individual_block_counter)] = for_variable
                        for_variable = ''
                        for_flag = False


                    else:
                        for_variable = for_variable + '\n' + line
                        continue
                #except Exception as e:
                    #print(e)

            if while_flag:
                next_while_line = dict[function][index+1]
                if re.search("LOOP.*",next_while_line,re.IGNORECASE):
                    while_variable = while_variable + '\n' + line
                    node_sequence.append('S' + str(total_individual_block_counter))
                    node_code['S' + str(total_individual_block_counter)] = while_variable
                    while_variable = ''
                    while_flag = False
                    continue

                else:
                    while_variable = while_variable + '\n' + line
                    continue



            if if_condition_collector_flag:
                if any(ext in line for ext in keywords_for_if_delimiter):

                    discovered_node = 'C' + str(
                        total_if_counter) + ' =>condition:' + if_condition_variable + ' | approved\n'
                    node_sequence.append('C' + str(total_if_counter))
                    node_code['C' + str(total_if_counter)] = if_condition_variable
                    # print(if_condition_variable)
                    if_condition_collector_flag = False

                    true_part_flag = True

                    true_part_variable = ''


            if true_part_flag:

                if re.match("IF .*",line,re.IGNORECASE):
                    truepart_ifs_tallied = False
                    # Increment the count of opened if statements
                    truepart_if_opened_count += 1
                    true_part_variable = true_part_variable + '\n' + line
                    continue

                if (not truepart_ifs_tallied) and ( re.match("END IF;",line,re.IGNORECASE)):
                    truepart_if_closed_count += 1
                    true_part_variable = true_part_variable + '\n' + line
                    if truepart_if_opened_count == truepart_if_closed_count:
                        truepart_ifs_tallied = True
                        truepart_if_opened_count, truepart_if_closed_count = 0, 0
                    continue

                #next_line = dict[function][index+1]
                if re.search("ELSIF.*",line,re.IGNORECASE) and truepart_ifs_tallied:
                    discovered_node = 'T' + str(
                        total_if_counter) + ' =>operation:' + true_part_variable +  ' | rejected\n'
                    node_sequence.append('T' + str(total_if_counter))
                    node_code['T' + str(total_if_counter)] = true_part_variable + '\n'
                    node_sequence.append('F' + str(total_if_counter))
                    node_code['F' + str(total_if_counter)] = ''
                    true_part_variable = ''
                    true_part_flag = False
                    elif_part_flag = True
                    elif_part_variable = ''




                elif re.search("ELSE.*",line,re.IGNORECASE) and truepart_ifs_tallied:
                    #else_index = line.index("ELSE")
                    #if if_index == else_index:
                        discovered_node = 'T' + str(
                            total_if_counter) + ' =>operation:' + true_part_variable + ' | rejected\n'
                        node_sequence.append('T' + str(total_if_counter))
                        node_code['T' + str(total_if_counter)] = true_part_variable
                        node_sequence.append('F' + str(total_if_counter))
                        node_code['F' + str(total_if_counter)] = ''
                        true_part_variable = ''
                        true_part_flag = False
                        false_part_flag = True
                        false_part_variable = ''
                        continue

                elif re.search("END IF;",line) and truepart_ifs_tallied:
                    end_if_index = line.find("END IF")
                    if if_index == end_if_index:

                        node_sequence.append('T' + str(total_if_counter))
                        node_code['T' + str(total_if_counter)] = true_part_variable + '\n' + line
                        node_sequence.append('F' + str(total_if_counter))
                        node_code['F' + str(total_if_counter)] = ''
                        true_part_variable = ''
                        true_part_flag = False

                        continue

                else:
                    true_part_variable = true_part_variable + '\n' + line
                    continue


            if false_part_flag:

                if re.match('IF .*', line, re.IGNORECASE):
                    # make sure if execution knows that IFs are no longer tallied
                    falsepart_ifs_tallied = False
                    # Increment the count of opened if statements
                    falsepart_if_opened_count += 1
                    false_part_variable = false_part_variable + '\n' + line
                    continue

                if (not falsepart_ifs_tallied) and (re.match("END IF;",line,re.IGNORECASE)):
                    falsepart_if_closed_count += 1
                    false_part_variable = false_part_variable + '\n' + line
                    if falsepart_if_opened_count == falsepart_if_closed_count:
                        falsepart_ifs_tallied = True
                        falsepart_if_opened_count, falsepart_if_closed_count = 0, 0
                    continue


                if re.search("END IF;",line,re.IGNORECASE) and  falsepart_ifs_tallied:
                    false_part_variable = false_part_variable + line + '\n'
                    discovered_node = 'F' + str(
                        total_if_counter) + ' =>operation:' + false_part_variable + ' | rejected\n'
                    # print(discovered_node)
                    node_sequence.append('F' + str(total_if_counter))
                    node_code['F' + str(total_if_counter)] = false_part_variable
                    # print('false',false_part_variable)
                    false_part_flag = False
                    group_block_flag = True
                    total_group_block_counter = total_group_block_counter + 1

                    continue
                else:

                    false_part_variable = false_part_variable + '\n' + line
                    continue

            if elif_part_flag:

                if re.match('IF .*', line, re.IGNORECASE):
                    # make sure if execution knows that IFs are no longer tallied
                    elifpart_ifs_tallied = False
                    # Increment the count of opened if statements
                    elifpart_if_opened_count += 1
                    elif_part_variable = elif_part_variable + '\n' + line
                    continue

                if (not elifpart_ifs_tallied) and (re.match("END IF;",line,re.IGNORECASE)):
                    elifpart_if_closed_count += 1
                    elif_part_variable = elif_part_variable + '\n' + line
                    if elifpart_if_opened_count == elifpart_if_closed_count:
                        elifpart_ifs_tallied = True
                        elifpart_if_opened_count, elifpart_if_closed_count = 0, 0
                    pass

                next_line = dict[function][index + 1]
                if re.search("ELSIF.*",next_line,re.IGNORECASE) :
                    total_individual_block_counter = total_individual_block_counter + 1
                    elif_part_variable = elif_part_variable + '\n' + line + '\n'
                    # print(read_variable)
                    node_sequence.append('S' + str(total_individual_block_counter))
                    node_code['S' + str(total_individual_block_counter)] = elif_part_variable
                    elif_part_variable = ''
                    continue

                    # discovered_node = 'T' + str(
                    #     total_if_counter) + ' =>operation:' + elif_part_variable + ' | rejected\n'
                    # node_sequence.append('T' + str(total_if_counter))
                    # node_code['T' + str(total_if_counter)] = elif_part_variable
                    # node_sequence.append('F' + str(total_if_counter))
                    # node_code['F' + str(total_if_counter)] = ''
                    # elif_part_flag = False
                    # elif_part_variable = ''
                    # continue


                # elif re.search("ELSE.*", line, re.IGNORECASE):
                #
                #     discovered_node = 'T' + str(
                #         total_if_counter) + ' =>operation:' + elif_part_variable + ' | rejected\n'
                #     node_sequence.append('T' + str(total_if_counter))
                #     node_code['T' + str(total_if_counter)] = elif_part_variable
                #     node_sequence.append('F' + str(total_if_counter))
                #     node_code['F' + str(total_if_counter)] = ''
                #     elif_part_variable = ''
                #     elif_part_flag = False
                #     false_part_flag = True
                #     false_part_variable = ''
                #     continue



                elif re.search("END IF;", line, re.IGNORECASE):


                    # node_sequence.append('T' + str(total_if_counter))
                    # node_code['T' + str(total_if_counter)] = elif_part_variable + '\n' + line
                    # node_sequence.append('F' + str(total_if_counter))
                    # node_code['F' + str(total_if_counter)] = ''
                    # elif_part_variable = ''
                    # elif_part_flag = False
                    #
                    # continue

                    total_individual_block_counter = total_individual_block_counter + 1
                    elif_part_variable = elif_part_variable + '\n' + line + '\n'
                    # print(read_variable)
                    node_sequence.append('S' + str(total_individual_block_counter))
                    node_code['S' + str(total_individual_block_counter)] = elif_part_variable
                    elif_part_variable = ''
                    elif_part_flag = False
                    continue
                else:
                    elif_part_variable = elif_part_variable + '\n' + line
                    continue

            if re.search("ELSIF .*",line,re.IGNORECASE):
                elif_part_variable = ''
                total_if_counter = total_if_counter + 1
                elif_part_variable = line
                elif_part_flag = True
                continue

            if forall_flag:
                if line.endswith(";"):
                    forall_variable = forall_variable + '\n' + line
                    node_sequence.append('S' + str(total_individual_block_counter))
                    node_code['S' + str(total_individual_block_counter)] = forall_variable
                    forall_variable = ''
                    forall_flag = False
                    continue

                else:
                    forall_variable = forall_variable + '\n' + line
                    continue




            if insert_flag:
                if line.endswith(";"):
                    insert_variable = insert_variable + '\n' + line
                    node_sequence.append('S' + str(total_individual_block_counter))
                    node_code['S' + str(total_individual_block_counter)] = insert_variable
                    insert_variable = ''
                    insert_flag = False
                    continue

                else:
                    insert_variable = insert_variable + '\n' + line
                    continue

            if delete_flag:
                if line.endswith(";"):
                    delete_variable = delete_variable + '\n' + line
                    node_sequence.append('S' + str(total_individual_block_counter))
                    node_code['S' + str(total_individual_block_counter)] = delete_variable
                    delete_variable = ''
                    delete_flag = False
                    continue

                else:
                    delete_variable = delete_variable + '\n' + line
                    continue

            if update_flag:
                if line.endswith(";"):
                    update_variable = update_variable + '\n' + line
                    node_sequence.append('S' + str(total_individual_block_counter))
                    node_code['S' + str(total_individual_block_counter)] = update_variable
                    update_variable = ''
                    update_flag = False
                    continue

                else:
                    update_variable = update_variable + '\n' + line
                    continue

            if select_flag:
                if line.endswith(";"):
                    select_variable = select_variable + '\n' + line
                    node_sequence.append('S' + str(total_individual_block_counter))
                    node_code['S' + str(total_individual_block_counter)] = select_variable
                    select_variable = ''
                    select_flag = False
                    continue

                else:
                    select_variable = select_variable + '\n' + line
                    continue





            if re.search("EXCEPTION.*",line,re.IGNORECASE):
                exception_variable = ''
                print("Exception:",line)
                total_individual_block_counter = total_individual_block_counter + 1
                exception_when_variable = line
                exception_when_flag = True

                if group_block_variable != '':
                    total_group_block_counter = total_group_block_counter + 1
                    node_sequence.append('G' + str(total_group_block_counter))
                    node_code['G' + str(total_group_block_counter)] = group_block_variable
                    group_block_variable = ''
                continue

            if re.search("CASE.*",line):
                case_variable = ''
                #print("Exception:",line)
                total_individual_block_counter = total_individual_block_counter + 1
                case_when_variable = line
                case_when_flag = True

                if group_block_variable != '':
                    total_group_block_counter = total_group_block_counter + 1
                    node_sequence.append('G' + str(total_group_block_counter))
                    node_code['G' + str(total_group_block_counter)] = group_block_variable
                    group_block_variable = ''
                continue



            if re.search("SELECT.*",line):
                print("SELECT_LINES:",line)
                select_variable = ''
                total_individual_block_counter = total_individual_block_counter + 1
                select_variable = line
                select_flag = True
                if group_block_variable != '':
                    total_group_block_counter = total_group_block_counter + 1
                    node_sequence.append('G' + str(total_group_block_counter))
                    node_code['G' + str(total_group_block_counter)] = group_block_variable
                    group_block_variable = ''
                continue

            if re.search("UPDATE.*",line):
                update_variable = ''
                total_individual_block_counter = total_individual_block_counter + 1
                update_variable = line
                update_flag = True
                if group_block_variable != '':
                    total_group_block_counter = total_group_block_counter + 1
                    node_sequence.append('G' + str(total_group_block_counter))
                    node_code['G' + str(total_group_block_counter)] = group_block_variable
                    group_block_variable = ''
                continue

            if re.search("INSERT.*",line):
                insert_variable = ''
                total_individual_block_counter = total_individual_block_counter + 1
                insert_variable = line
                insert_flag = True
                if group_block_variable != '':
                    total_group_block_counter = total_group_block_counter + 1
                    node_sequence.append('G' + str(total_group_block_counter))
                    node_code['G' + str(total_group_block_counter)] = group_block_variable
                    group_block_variable = ''
                continue

            if re.search("DELETE",line):
                if not re.search("DELETE;",line):
                    delete_variable = ''
                    total_individual_block_counter = total_individual_block_counter + 1
                    delete_variable = line
                    delete_flag = True
                    if group_block_variable != '':
                        total_group_block_counter = total_group_block_counter + 1
                        node_sequence.append('G' + str(total_group_block_counter))
                        node_code['G' + str(total_group_block_counter)] = group_block_variable
                        group_block_variable = ''
                    continue

            if re.search(" FOR",line):
                print("FOR:",line)
                for_variable = ''
                total_individual_block_counter = total_individual_block_counter + 1
                for_variable = line
                for_flag = True
                if group_block_variable != '':
                    total_group_block_counter = total_group_block_counter + 1
                    node_sequence.append('G' + str(total_group_block_counter))
                    node_code['G' + str(total_group_block_counter)] = group_block_variable
                    group_block_variable = ''
                continue

            if re.search("WHILE.*",line):
                while_variable = ''
                total_individual_block_counter = total_individual_block_counter + 1
                while_variable = line
                while_flag = True
                if group_block_variable != '':
                    total_group_block_counter = total_group_block_counter + 1
                    node_sequence.append('G' + str(total_group_block_counter))
                    node_code['G' + str(total_group_block_counter)] = group_block_variable
                    group_block_variable = ''
                continue


            if re.search("FORALL.*",line):
                forall_variable = ''
                total_individual_block_counter = total_individual_block_counter + 1
                forall_variable = line
                forall_flag = True
                if group_block_variable != '':
                    total_group_block_counter = total_group_block_counter + 1
                    node_sequence.append('G' + str(total_group_block_counter))
                    node_code['G' + str(total_group_block_counter)] = group_block_variable
                    group_block_variable = ''
                continue




            if re.match("LOOP.*", line, re.IGNORECASE):
                print("Loop:", line)
                if group_block_variable != '':
                    total_group_block_counter = total_group_block_counter + 1
                    node_sequence.append('G' + str(total_group_block_counter))
                    node_code['G' + str(total_group_block_counter)] = group_block_variable
                    group_block_variable = ''
                loop_variable = ''
                total_individual_block_counter = total_individual_block_counter + 1
                loop_variable = line + '\n'
                # print(read_variable)
                node_sequence.append('S' + str(total_individual_block_counter))
                node_code['S' + str(total_individual_block_counter)] = loop_variable
                loop_variable = ''
                continue

            if re.search("END LOOP",line,re.IGNORECASE):
                if group_block_variable != '':
                    total_group_block_counter = total_group_block_counter + 1
                    node_sequence.append('G' + str(total_group_block_counter))
                    node_code['G' + str(total_group_block_counter)] = group_block_variable
                    group_block_variable = ''
                end_loop_variable = ''
                total_individual_block_counter = total_individual_block_counter + 1
                end_loop_variable = line + '\n'
                # print(read_variable)
                node_sequence.append('S' + str(total_individual_block_counter))
                node_code['S' + str(total_individual_block_counter)] = end_loop_variable
                end_loop_variable = ''
                continue


            if re.match('IF .*', line):
                if_condition_variable = " "
                if_index = line.index("IF")
                total_if_counter = total_if_counter + 1
                if_condition_variable = line
                if_condition_collector_flag = True
                group_block_flag = False
                if group_block_variable != '':
                    total_group_block_counter = total_group_block_counter + 1
                    node_sequence.append('G' + str(total_group_block_counter))
                    node_code['G' + str(total_group_block_counter)] = group_block_variable
                    group_block_variable = ''
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

        node_string = 'st=>start: START | past\ne=>end: END | past \n'
        links_string = 'st'
        try:
            for i in range(0, len(node_sequence)):
                # Make sure the leading line breaks are STRIPPED
                node_code[node_sequence[i]] = node_code[node_sequence[i]].lstrip('\n')
                node_code[node_sequence[i]] = node_code[node_sequence[i]].replace('=>', '= >')

                if re.match('^S.*', node_sequence[i]) or re.match('^G.*', node_sequence[i]):
                    links_string = links_string + '->' + node_sequence[i] + '\n' + node_sequence[i]
                    node_string = node_string + node_sequence[i] + '=>operation: ' + node_code[
                        node_sequence[i]] + ' | approved\n'
                if re.match('^C.*', node_sequence[i]):
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
                            links_string = links_string + '->' + node_sequence[i] + '\n' + node_sequence[
                                i] + '(yes)'
                            links_string = links_string + '->' + node_sequence[i + 1] + '\n' + node_sequence[
                                i] + '(no)'
                            links_string = links_string + '->' + node_sequence[i + 3] + '\n' + node_sequence[
                                i + 1]

                        else:
                            # If there is an else part, behave normally
                            links_string = links_string + '->' + node_sequence[i] + '\n' + node_sequence[
                                i] + '(yes)'
                            links_string = links_string + '->' + node_sequence[i + 1] + '\n' + node_sequence[
                                i] + '(no)'
                            links_string = links_string + '->' + node_sequence[i + 2]
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
        print("from Here")
        print(node_string)
        print("---------------")
        print(links_string)
        # print({"option": node_string + '\n' + links_string,"component_name":COMPONENT_NAME,"para_name":paragraph_name.split('.')[0]})
        print("CCCCCCCCCC:",component_name.strip(file_location))
        # nodes = node_string + '\n' + links_string
        OUTPUT_DATA.append({"option": node_string + '\n' + links_string,

                            "component_name": component_name.split("\\")[-1],
                            "para_name": function.upper()})
        # print("Nodes:",nodes)
        # return  "st=>start: START | past\ne=>end: END | past \nC1=>condition: IF #INPUT NE 'OPENLANE' | rejected\nT1=>operation: MOVE AUTOTRAN.VINCODE TO #BI-VINCODE\nMOVE AUTOTRAN.MOD1 TO #O-RDR-TYPE\nEND-IF | approved \n\nst->C1\nC1(yes)->T1\nT1->e"

        # print("Option:",nodes)

        # print(node_sequence)
        node_sequence.clear()
        node_string = ''
        links_string = ''
    #print(json.dumps(OUTPUT_DATA,indent =4))
    return OUTPUT_DATA

def db_update(OUTPUT_DATA):

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


        #return OUTPUT_DATA


for file_location,file_type in file.items():
    for filename in glob.glob(os.path.join(file_location,file_type)):
        if file_type == "*.pkb":
            Type = "Package Body"
            dict=ProgramType(filename,Type,file_location)
            process(dict,filename)
            db_update(OUTPUT_DATA)

        elif file_type == "*.prc":
            Type = "Procedure"
            dict=standalone(filename, Type, file_location)
            process(dict, filename)
            db_update(OUTPUT_DATA)
            print("Failure")

        elif file_type == "*.fnc":
            Type = "Function"
            dict=function(filename, Type, file_location)
            process(dict, filename)
            db_update(OUTPUT_DATA)

        elif file_type == "*.trg":
            Type = "Trigger"
            dict=trigger(filename, Type, file_location)
            process(dict, filename)
            db_update(OUTPUT_DATA)


# # if __name__ == '__main__':
# main()
