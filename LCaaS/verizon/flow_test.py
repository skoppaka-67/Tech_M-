"""

Z  - Else IF

N - Nested Breaking

"""


import os, re, glob, copy
import pymongo
import Vb_Parsing.config as config




# vb = config.codebase_information['VB']['folder_name']
# code_location = config.codebase_information['code_location']
# vb_path = code_location + '\\' + vb + '\\*'
# vb_component_path = code_location + "\\ApplicationAssembles\\*\\*"

# vb = config.codebase_information['VB']['folder_name']
# code_location = config.codebase_information['code_location']
# vb_path = code_location + '\\*'
# vb_component_path = "D:\\Lcaas_imp\\ApplicationAssembles\\LobCP\\*.BusinessRules"


vb = config.codebase_information['VB']['folder_name']
code_location = config.codebase_information['code_location']
vb_path = code_location + '\\*'
vb_component_path = "D:\\VB_IMP\\vbcomponent"
# vb_component_path = "D:\\Lcaas_imp\\ApplicationAssembles\\LobCP\\*.BusinessRules"



META_DATA = []


class Database:

    def __init__(self):
        self.db_name = "Vb_net1"
        self.col_name = "para_flowchart_data"

        # self.Db_conn(self.db_name,self.col_name)

    def Db_conn(self, db_name, col_name):
        conn = pymongo.MongoClient("localhost", 27017)
        return conn[db_name][col_name]

    def db_update(self, db_name, col_name, Metadata):

        cursy = self.Db_conn(db_name, col_name)

        try:
            cursy.insert_many(Metadata)
            print(db_name, col_name, "Created and inserted")

        except Exception as e:
            print("Error:", db_name, col_name, e)

    def db_delete(self, db_name, col_name):
        cursy = self.Db_conn(db_name, col_name)
        try:
            cursy.delete_many({})
            print(db_name, col_name, "Deleted")

        except Exception as e:
            print("Error:", db_name, col_name, e)


class PreProcessing():

    def get_files(self):
        filenames_list = []
        for filename1 in glob.glob(os.path.join(vb_path, '*.aspx.vb')):
            filenames_list.append(filename1)
        for filename2 in glob.glob(os.path.join(vb_component_path, '*.vb')):
            filenames_list.append(filename2)

        # return ["D:\Lcaas_imp\WebApplications\LobPF\PFPolicyInput.aspx.vb"]
        return filenames_list


    def remove_duplicates(self, list):
        res = []
        for i in list:
            if i not in res:
                res.append(i)
        return res

    def remove_comments_write_to_temp_file(self, file):

        f = open(file, "r")
        target_file = open("FlowChart_Temp_file.txt", "w")

        for line in f.readlines():
            if line.strip().startswith("'"):

                continue
            else:

                line = line.replace("ElseIf","NElse\nIf")
                # print(line)



                target_file.write(line)
        target_file.close()
        processed_line_list = self.tagging_end_if_to_singleline_id("FlowChart_Temp_file.txt")

        code_block_dict = self.break_code_into_blocks(processed_line_list)

        # code_hash_El_ifhandled  = self.break_el_if_tag_end_if(code_block_dict)

        target_file.close()
        os.remove("FlowChart_Temp_file.txt")
        return code_block_dict

    def break_el_if_tag_end_if(self, code_block_dict):

        for fun_name, line_list in code_block_dict.items():
            for pointer, line in enumerate(line_list):
                print(pointer, line)

    def tagging_end_if_to_singleline_id(self, file):
        input_file = open(file, "r")
        pub_func = "public function"
        pub_share = "public shared"
        pub_sub = "public sub"
        private_sub = "private sub"
        private_share = "private shared"
        private_func = "private function"
        friend_func = "friend function"
        end_func = "End Function"
        end_sub = "End Sub"
        process_list = []
        if_collecting_flag = False
        rare_if_collecting_flag = False
        for append_lines in input_file.readlines():
            # print("Äppend:",append_lines)
            then_index = ""
            then_line = ""
            balance_append_line = ""
            end_if_index = ""

            if append_lines.strip() == "":  ### ignore the blank lines
                continue
            if append_lines.lstrip().startswith("'"):  ### ignore the commented lines
                continue

            if rare_if_collecting_flag:
                '''
                #### The rare_if_collecting_flag will be set True when the lines containing If is hit and when there
                #### is no keyword then in that line.
                #### In this portion, we will be searching for the line containing then and the position of the keyword
                #### then in that line. Until the line containing keyword then is hit, we will be appending the remaining
                #### in between lines to the process list
                #### If the keyword then is in the last index position of the line, no EndIf tagging is required
                #### simply append the line to the process list.
                #### If the keyword then is placed in any position other than the last index position, then it is a
                #### single line IF, we need manual addition of End If tagging to it, which happens in if collecting flag.
                '''
                if append_lines.casefold().__contains__("then"):
                    if not append_lines.rstrip().casefold().endswith("then"):

                        then_index = append_lines.casefold().find("then")
                        then_line = append_lines[:then_index + 4]
                        balance_append_line = append_lines[then_index + 5:]
                        process_list.append(then_line)
                        process_list.append(balance_append_line)
                        rare_if_collecting_flag = False
                        if_collecting_flag = True
                        continue
                    else:
                        process_list.append(append_lines)
                        rare_if_collecting_flag = False
                        continue

                else:
                    process_list.append(append_lines)
                    continue

            if if_collecting_flag:

                if append_lines[main_if_index] != " " and not re.search('.* end if.*', append_lines,
                                                                        re.IGNORECASE) and not re.search('.* elseif.*',
                                                                                                         append_lines,
                                                                                                         re.IGNORECASE) and not re.search(
                    '.* else .*', append_lines, re.IGNORECASE):
                    if append_lines.casefold().__contains__("end sub") or append_lines.casefold().__contains__(
                            "end function"):
                        # process_list.append(append_lines)
                        process_list.append('\n' + " End If\n")
                        process_list.append(append_lines)
                        if_collecting_flag = False
                        continue
                    elif re.search('^\s*If\s.*', append_lines, re.IGNORECASE):
                        process_list.append('\n' + " End If\n")
                        if_collecting_flag = False
                    elif re.search('^\s*elseif\s.*', append_lines, re.IGNORECASE):
                        process_list.append(append_lines)
                        continue
                    elif re.search('^\s*else\s.*', append_lines, re.IGNORECASE):
                        process_list.append(append_lines)
                        continue
                    else:
                        process_list.append('\n' + " End If\n")
                        process_list.append(append_lines)
                        if_collecting_flag = False
                        continue

                elif append_lines[main_if_index] != " ":

                    if append_lines.strip().lower().__contains__("end if"):
                        end_if_index = append_lines.lower().index("end if")
                    elif append_lines.strip().lower().__contains__("elseif "):
                        end_if_index = append_lines.lower().index("elseif ")
                    elif append_lines.strip().lower().__contains__("else "):
                        end_if_index = append_lines.lower().index("else ")
                    if main_if_index > end_if_index:
                        process_list.append('\n' + " End If\n")
                        process_list.append(append_lines)
                        if_collecting_flag = False
                        continue
                    elif main_if_index == end_if_index:
                        process_list.append(append_lines)
                        if_collecting_flag = False
                        continue
                    else:
                        process_list.append(append_lines)
                        continue
                elif append_lines.casefold().__contains__("end sub") or append_lines.casefold().__contains__(
                        "end function"):
                    process_list.append('\n' + " End If\n")
                    process_list.append(append_lines)
                    if_collecting_flag = False
                    continue
                else:
                    process_list.append(append_lines)
                    continue

            if re.search('^\s*If.*', append_lines):

                if append_lines.rstrip().casefold().endswith("then"):  ## Scenario 1 - lines containing IF keyword
                    process_list.append(append_lines)  ### and keyword then in the last index position
                    continue
                if not append_lines.casefold().__contains__("then"):  ## Scenario 2 - lines containing only IF keyword
                    main_if_index = append_lines.index("If ")  ### single line if's need to tag End-If.
                    process_list.append(append_lines)
                    rare_if_collecting_flag = True
                    continue
                if append_lines.casefold().__contains__("then"):  ### Scenario 3 - lines containing IF keyword
                    if not append_lines.rstrip().casefold().endswith(
                            "then"):  ### and keyword then. keyword then shouldnot
                        ### be in the last position
                        main_if_index = append_lines.index("If ")
                        then_index = append_lines.casefold().find("then")
                        then_line = append_lines[:then_index + 4]
                        balance_append_line = append_lines[then_index + 5:]
                        process_list.append(then_line)
                        process_list.append(balance_append_line)
                        if_collecting_flag = True
                        continue
                else:
                    process_list.append(append_lines)
                    continue
            else:
                process_list.append(append_lines)
                continue

        return process_list

    def break_code_into_blocks(self, processed_line_list):

        fun_flag = False

        code_block_list = []
        code_block_hash = {}
        function_name = ''

        for line in processed_line_list:
            try:

                if (line.lower().__contains__("end sub") or line.lower().__contains__("end function")):
                    fun_flag = False
                    code_block_hash[function_name] = copy.deepcopy(code_block_list)
                    function_name = ''
                    code_block_list.clear()

                if (line.lower().__contains__(" sub ") or line.lower().__contains__(" function ")) and (
                        line.lower().__contains__("public") or line.lower().__contains__(
                    "private")) or line.lower().__contains__("protected"):
                    fun_flag = True
                    if line.strip().startswith("Public Shared Function"):
                        function_name = line.split("Function")[1].split("(")[0]
                        continue


                    else:
                        # print(line)
                        line1 = line.replace(" Sub", "Function").replace(" sub", "Function").replace("function",
                                                                                                     "Function")
                        function_name = line1.split("Function")[1].split("(")[0]
                        continue

                if fun_flag:
                    code_block_list.append(line)
            except IndexError as e:
                print(f'Error:list index out of range:{line}')

        return code_block_hash


class flowchartProcessing(PreProcessing, Database):

    def __init__(self, DB_CON, pre_prop):

        super().__init__()
        cursy = DB_CON.Db_conn("Vb_net1", "Pub_Fun_Lookup")

        PUB_SHRD_FUN_LIST = cursy.distinct("Function_name")

        file_list = pre_prop.get_files()
        # self.file_list = ["D:\Lcaas_imp\WebApplications\LobPF\PFLocCovergaeInput.aspx.vb"]
        self.file_list = file_list


        cursy = DB_CON.Db_conn("Vb_net1", "Pub_Fun_Lookup")

        self.PUB_SHRD_FUN_LIST = cursy.distinct("Function_name")

        """Pass Files using for loop"""
        for file in self.file_list:
            # code_block_dict = pre_prop.remove_comments_write_to_temp_file(
            #     "D:\Lcaas_imp\WebApplications\LobPF\PFLocCovergaeInput.aspx.vb")
            #
            # self.obj_list = self.fetchimport_var("D:\Lcaas_imp\WebApplications\LobPF\PFLocCovergaeInput.aspx.vb")
            #
            # self.block_separation(code_block_dict, "D:\Lcaas_imp\WebApplications\LobPF\PFLocCovergaeInput.aspx.vb")
            print("File",file)
            code_block_dict = pre_prop.remove_comments_write_to_temp_file(file)

            self.obj_list = self.fetchimport_var(file)

            self.block_separation(code_block_dict, file)
    def fetchimport_var(self, filename):
        ref_var_list = []

        with open(filename, 'r') as vb_file:
            for lines in vb_file.readlines():

                if lines.strip().startswith("Imports") or lines.strip().startswith("Namespace"):
                    continue

                if lines.upper().__contains__("AS") and (
                        (lines.__contains__(".Lob") or lines.__contains__(" Lob")) and ((
                        (lines.strip().lower().startswith("private") or lines.strip().lower().startswith(
                            "dim")))) or lines.__contains__(
                    " BusinessServices.")):
                    lines = lines.replace("New", '')
                    lines = lines.replace(".BusinessRules", '')

                    if lines.split()[2].upper() == "AS":
                        line_list = lines.split()
                        # print(line_list)
                        if line_list[0].lower() == "private" or line_list[0].lower() == "dim":
                            op_dict = dict(obj_name="", called_file_name="", called_lob_name="")

                            if line_list[3].__contains__("BusinessServices."):

                                if len(line_list[3].split("BusinessServices.")[1].split(".")) > 1:  # len

                                    op_dict['obj_name'] = line_list[1] + "."
                                    if line_list[3].split("BusinessServices.")[1].split(".")[1].__contains__("("):
                                        op_dict['called_file_name'] = \
                                            line_list[3].split("BusinessServices.")[1].split(".")[1].split("(")[0]
                                    else:

                                        op_dict['called_file_name'] = \
                                            line_list[3].split("BusinessServices.")[1].split(".")[1]
                                    op_dict['called_lob_name'] = line_list[3].split("BusinessServices.")[1].split(".")[
                                        0]
                                    # op_dict['line'] = line_list
                                    ref_var_list.append(op_dict)
                                else:
                                    op_dict['obj_name'] = line_list[1] + "."
                                    if line_list[3].split("BusinessServices.")[1].split(".")[0].__contains__("("):
                                        op_dict['called_file_name'] = \
                                            line_list[3].split("BusinessServices.")[1].split(".")[0].split("(")[0]
                                    else:
                                        op_dict['called_file_name'] = \
                                            line_list[3].split("BusinessServices.")[1].split(".")[0]

                                    op_dict['called_lob_name'] = ""
                                    # op_dict['line'] = line_list
                                    ref_var_list.append(op_dict)

                            elif line_list[3].startswith("Lob"):
                                op_dict['obj_name'] = line_list[1] + "."
                                if line_list[3].split(".")[1].__contains__("("):
                                    op_dict['called_file_name'] = line_list[3].split(".")[1].split("(")[0]
                                else:
                                    op_dict['called_file_name'] = line_list[3].split(".")[1]
                                op_dict['called_lob_name'] = line_list[3].split(".")[0]
                                # op_dict['line'] = line_list
                                ref_var_list.append(op_dict)
        # print(json.dumps(ref_var_list,indent=4))
        return tuple(self.remove_duplicates(ref_var_list))

    def block_separation(self, code_block_dict,file_name):
        node_sequence = []
        OUTPUT_DATA = []

        group_block_variable = ""

        total_group_block_counter = 0
        total_individual_block_counter = 0
        total_if_block_counter = 0
        block_counter = 0
        node_code = {}
        flag = False
        case_flag = False
        case_counter = 0
        prev_case_counter = 0
        case_var = ''
        if_counter = 0
        if_else_counter = 0
        if_block = []
        if_flag = False
        collect_case = False
        for fun_name in code_block_dict.keys():
            # print(fun_name)
            dict_counter = 0
            dict = {}

            for index, line in enumerate(code_block_dict[fun_name]):

                if line.strip().startswith("If") and case_flag == False:

                    if group_block_variable != '':
                        total_group_block_counter = total_group_block_counter + 1

                        node_sequence.append('G' + str(total_group_block_counter))

                        node_code['G' + str(total_group_block_counter)] = group_block_variable
                        group_block_variable = ''
                    if code_block_dict[fun_name][index-1].strip().startswith("NElse"):
                        if_block.append(line.rstrip() + "\n")
                        if_else_counter = if_else_counter + 1
                        continue
                    if_counter = if_counter + 1
                    if_block.append(line.rstrip() + "\n")
                    if_flag = True
                    continue
                if line.strip().startswith("End If") and case_flag == False:
                    # print(line)
                    if_block.append(line.rstrip() + "\n")
                    if_counter = if_counter - 1
                    if if_counter == 0:
                        # print(json.dumps(if_block,indent=4,))

                        flag, total_group_block_counter, block_counter, node_sequence, node_code, total_if_block_counter = self.creat_conditional_block(
                            if_block, block_counter, total_group_block_counter, node_sequence, node_code,
                            total_if_block_counter)

                        dict[dict_counter] = copy.deepcopy(node_sequence)
                        dict_counter = dict_counter + 1
                        if_flag = False
                        if_block.clear()
                        node_sequence.clear()
                    continue

                if if_flag:
                    if_block.append(line.rstrip() + "\n")
                    continue

                if re.match(".*Case .*", line, re.IGNORECASE) and not (line.__contains__("Select")) and collect_case:

                    case_flag = True
                    case_counter = case_counter + 1
                    if case_counter > 1:
                        # print(case_var)
                        flag, group_block_variable, total_group_block_counter, node_sequence, node_code, total_individual_block_counter = self.identify_indvidual_block_process(
                            case_var, group_block_variable, total_group_block_counter, node_sequence, node_code,
                            total_individual_block_counter)
                        case_counter = 1
                        case_var = ''
                        case_flag = True
                        case_var = case_var + line + "\n"
                        continue

                if (re.match(".* Select .*", line, re.IGNORECASE) or re.match(".* End Select", line,
                                                                              re.IGNORECASE)):

                    if group_block_variable != '':
                        total_group_block_counter = total_group_block_counter + 1

                        node_sequence.append('G' + str(total_group_block_counter))

                        node_code['G' + str(total_group_block_counter)] = group_block_variable
                        group_block_variable = ''
                    else:
                        if re.match(".* End Select", line, re.IGNORECASE):

                            flag, group_block_variable, total_group_block_counter, node_sequence, node_code, total_individual_block_counter = self.identify_indvidual_block_process(
                                case_var, group_block_variable, total_group_block_counter, node_sequence, node_code,
                                total_individual_block_counter)
                            case_var = ''
                            flag, group_block_variable, total_group_block_counter, node_sequence, node_code, total_individual_block_counter = self.identify_indvidual_block_process(
                                line, group_block_variable, total_group_block_counter, node_sequence, node_code,
                                total_individual_block_counter)
                        elif re.match(".* Select .*", line, re.IGNORECASE):
                            flag, group_block_variable, total_group_block_counter, node_sequence, node_code, total_individual_block_counter = self.identify_indvidual_block_process(
                                line, group_block_variable, total_group_block_counter, node_sequence, node_code,
                                total_individual_block_counter)

                    case_counter = 0
                    case_var = ''
                    case_flag = False
                    collect_case = True

                if case_flag:
                    case_var = case_var + line + "\n"
                    continue

                else:
                    if flag:  ### set flag to check groupblock or individualblock  Flag will be true if individualblock False for Gropblock

                        continue

                    flag, group_block_variable, total_group_block_counter, node_sequence, node_code, total_individual_block_counter = self.identify_indvidual_block_process(
                        line, group_block_variable, total_group_block_counter, node_sequence, node_code,
                        total_individual_block_counter)

                if flag:  ### set flag to check groupblock or individualblock  Flag will be true if individualblock False for Gropblock
                    flag = False
                    continue
                else:
                    if line.strip() != '':
                        if line.strip() != '.':
                            group_block_variable = group_block_variable + line + '\n'
                            continue

            if group_block_variable != '':
                total_group_block_counter = total_group_block_counter + 1

                node_sequence.append('G' + str(total_group_block_counter))

                node_code['G' + str(total_group_block_counter)] = group_block_variable

                group_block_variable = ''

            """ 
            node sequnce is empty or not 
            """

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

                pass


            else:


                position = 0
                for dict_key in dict_keys:

                    position = dict_keys.index(dict_key)
                    # print(position)
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
                            if c_index + 2 <= len(node_sequence) - 1:
                                if node_sequence[c_index + 2] != 'F' + node_sequence[i][1:]:
                                    missing_list.append('F' + node_sequence[i][1])
                                    if node_code['F' + node_sequence[i][1:]] != '':
                                        if node_code['T' + node_sequence[i][1:]] != '':

                                            links_string = links_string + '->' + node_sequence[i] + '\n' + node_sequence[
                                                i] + '(yes)->' + node_sequence[i + 1]
                                            links_string = links_string + '\n' + node_sequence[
                                                i] + '(no)->' + ('F' + node_sequence[i][1:])
                                        else:
                                            links_string = links_string + '->' + node_sequence[i] + '\n' + node_sequence[
                                                i] + '(yes)->' + node_sequence[i + 2]
                                            links_string = links_string + '\n' + node_sequence[
                                                i] + '(no)->' + ('F' + node_sequence[i][1:])
                                    else:
                                        if node_code['T' + node_sequence[i][1:]] != '':
                                            links_string = links_string + '->' + node_sequence[i] + '\n' + node_sequence[
                                                i] + '(yes)->' + node_sequence[i + 1]
                                            f_index = node_sequence.index('F' + node_sequence[i][1:])
                                            if f_index + 1 <= len(node_sequence) - 1:
                                                if node_sequence[f_index + 1] in missing_list:
                                                    connector_list.append(node_sequence[i] + '(no)')
                                                else:
                                                    if node_sequence[f_index + 1] == 'Z'  or node_sequence[f_index + 1] == 'N' :
                                                        if f_index + 2 <= len(node_sequence)-1:
                                                            links_string = links_string + '\n' + node_sequence[
                                                                i] + '(no)->' + (node_sequence[f_index + 2])
                                                        else:
                                                            links_string = links_string + '\n' + node_sequence[
                                                                i] + '(no)->' +  '->' + 'e'

                                                    else:
                                                        links_string = links_string + '\n' + node_sequence[
                                                            i] + '(no)->' + (node_sequence[f_index + 1])
                                            else:
                                                connector_list.append(node_sequence[i] + '(no)')

                                        else:

                                            links_string = links_string + '->' + node_sequence[i] + '\n' + node_sequence[
                                                i] + '(yes)->' + node_sequence[i + 2]
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
                                    if node_code['F' + node_sequence[i][1:]] != '':
                                        if node_code['T' + node_sequence[i][1:]] != '':
                                            links_string = links_string + '->' + node_sequence[i] + '\n' + node_sequence[
                                                i] + '(yes)->' + \
                                                           node_sequence[i + 1]
                                            if i+3 <= len(node_sequence)-1:
                                                if re.search('.*Z.*',node_sequence[i + 3]):
                                                    links_string = links_string + '\n' + node_sequence[i] + '(no)->' + \
                                                                   node_sequence[
                                                                       i + 4]
                                                else:
                                                    links_string = links_string + '\n' + node_sequence[i] + '(no)->' + \
                                                                   node_sequence[
                                                                       i + 2]
                                        else:
                                            links_string = links_string + '->' + node_sequence[i] + '\n' + node_sequence[
                                                i] + '(yes)->' + \
                                                           node_sequence[i + 3]

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
                                            links_string = links_string + '->' + node_sequence[i] + '\n' + node_sequence[
                                                i] + '(yes)->' + \
                                                           node_sequence[i + 1]
                                            f_index = node_sequence.index('F' + node_sequence[i][1:])
                                            if f_index + 1 <= len(node_sequence) - 1:
                                                if node_sequence[f_index + 1] in missing_list:
                                                    connector_list.append(node_sequence[i] + '(no)')
                                                elif  re.search('.*Z.*',node_sequence[f_index + 1]):
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
                                if re.match('^S.*', node_sequence[i + 2]) or re.match('^G.*', node_sequence[i + 2]):
                                    links_string = links_string + '\n' + node_sequence[i] + '->' + node_sequence[i + 2]
                                    continue

                            if i == len(node_sequence) - 2:
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
                                # [C7,T7,F7,C8,T8,F8]
                            if i + 1 == len(node_sequence) - 1:
                                if node_sequence[i + 1] in missing_list:
                                    connector_list.append(node_sequence[i])
                                    continue
                            else:
                                if i == len(node_sequence) - 1:
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
                            links_string = links_string + '->' + 'e'
                print(links_string)
                print(node_string)
                # print(fun_name, node_sequence)
                connector_list.clear()
                elseif_list.clear()

            """
            node fomation and linking 
            """





            # print(fun_name)
            # print("NodeSeque:", node_sequence)
            # print("Nodecode:", json.dumps(node_code,indent=4))
            # print(fun_name,node_code)

            OUTPUT_DATA.append({"option": node_string + '\n' + links_string,
                                "component_name": file_name.split("\\")[-1].replace(" ", "_"),
                                "para_name": fun_name.strip()})

            node_sequence.clear()
            node_code.clear()
            group_block_variable = ""

            total_group_block_counter = 0
            total_individual_block_counter = 0
            total_if_block_counter = 0
            block_counter = 0
            flag = False
            case_flag = False
            case_counter = 0
            prev_case_counter = 0
            case_var = ''
            if_counter = 0
            if_flag = False
            collect_case = False
        # print(json.dumps(OUTPUT_DATA,indent=4))



            # Insert into DB
        try:
            DB_CON.db_update("Vb_net1","para_flowchart_data",OUTPUT_DATA)

            print('update sucess')

        except Exception as e:
            print('Error:' + str(e))

    # noinspection PyPep8Naming

    def creat_individual_block(self, line, group_block_variable, total_group_block_counter, node_sequence, node_code,
                               total_individual_block_counter):

        if group_block_variable != '':
            total_group_block_counter = total_group_block_counter + 1
            node_sequence.append('G' + str(total_group_block_counter))
            node_code['G' + str(total_group_block_counter)] = group_block_variable
            group_block_variable = ''
        individual_var_storage = ''
        total_individual_block_counter = total_individual_block_counter + 1
        individual_var_storage = line + '\n'
        # print(read_variable)
        node_sequence.append('S' + str(total_individual_block_counter))
        node_code['S' + str(total_individual_block_counter)] = individual_var_storage
        individual_var_storage = ''
        return True, group_block_variable, total_group_block_counter, node_sequence, node_code, total_individual_block_counter

    def identify_indvidual_block_process(self, line, group_block_variable, total_group_block_counter, node_sequence,
                                         node_code,
                                         total_individual_block_counter):

        individual_block_vars = ['.*Dim .*', '.*for .*', '.*Do .*', ".* Select .*", ".*Case .*", ".* End Select"]

        for value in individual_block_vars:

            if re.match(value, line, re.IGNORECASE):
                return self.creat_individual_block(line, group_block_variable, total_group_block_counter, node_sequence,
                                                   node_code,
                                                   total_individual_block_counter)



            else:
                continue
        else:
            Pub_shar_fun = [x for x in self.PUB_SHRD_FUN_LIST if " " + x in line]
            if Pub_shar_fun != []:
                return self.creat_individual_block(line, group_block_variable, total_group_block_counter, node_sequence,
                                                   node_code,
                                                   total_individual_block_counter)

            Ref_file = [x for x in self.file_list if x.split("\\")[-1].split(".")[0] in line]
            if Ref_file != []:
                return self.creat_individual_block(line, group_block_variable, total_group_block_counter, node_sequence,
                                                   node_code,
                                                   total_individual_block_counter)

            ref_obj_list = [x['obj_name'] for x in self.obj_list]
            obj_ref = [x for x in ref_obj_list if " " + x in line]
            if obj_ref != []:
                return self.creat_individual_block(line, group_block_variable, total_group_block_counter, node_sequence,
                                                   node_code,
                                                   total_individual_block_counter)

            else:

                return False, group_block_variable, total_group_block_counter, node_sequence, node_code, total_individual_block_counter

    def creat_conditional_block(self, line_list, block_counter, total_group_block_counter, node_sequence, node_code,
                                total_if_block_counter):


        IF_VAR = "If"
        ELSE_VAR = "Else"
        END_IF_VAR = "End If"
        ELSE_IF_VAR = "ElseIf"
        NELSE_VAR = "NElse"

        #3 = {str} '                        NElse\n'
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
                            node_code['F' + str(pop_list[-1])] = ''
                            pop_list.pop()
                        else:
                            group_block_variable = " ".join(
                                line_list[
                                list(index_list[index].values())[0] + 1: list(index_list[alter_index].values())[0]])
                            total_group_block_counter = total_group_block_counter + 1
                            node_sequence.append('G' + str(total_group_block_counter))

                            node_code['G' + str(total_group_block_counter)] = group_block_variable

        # print(json.dumps(node_code, indent=4))
        # print(node_sequence)



        return True, total_group_block_counter, block_counter, node_sequence, node_code, total_if_block_counter

    # def linking(self,dict):






pre_prop = PreProcessing()
DB_CON = Database()
flw = flowchartProcessing(DB_CON, pre_prop)