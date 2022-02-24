"""

Z  - Else IF

N - Nested Breaking

"""

import os, re, glob, copy, json
import pymongo
import config as config

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
vb_path = code_location
#vb_component_path = "D:\\C#\\test\\*"
# vb_component_path = "D:\\Lcaas_imp\\ApplicationAssembles\\LobCP\\*.BusinessRules"


META_DATA = []
OUTPUT_DATA = []


class Database:

    def __init__(self):
        self.db_name = "java"
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
        filespath = config.filespath
        extentions = ['.java']  # function to return the file paths in the given directory with given extention
        filelist = []
        for root, dirs, files in os.walk(filespath):
            for file in files:
                if file.lower().endswith(tuple([item.lower() for item in extentions])):
                    filelist.append(os.path.join(root, file))
        return filelist

    def remove_duplicates(self, list):
        res = []
        for i in list:
            if i not in res:
                res.append(i)
        return res

    def remove_comments_write_to_temp_file(self, file):
        keyword_list = ['catch', 'try', 'foreach', 'else', 'for', 'case', 'default', 'switch', 'if','while']

        f = open(file, "r")
        target_file = open("FlowChart_Temp_file.txt", "w")
        block_comment_flag = False

        for line in f.readlines():

            if line.strip().startswith('/*'):
                block_comment_flag = True
            if line.strip().__contains__('*/'):
                block_comment_flag = False
            if block_comment_flag:
                continue

            if line.strip().startswith("//"):

                continue

            else:

                line = line.replace("ElseIf", "NElse\nIf")
                for keyword in keyword_list:
                    if line.strip().startswith('}') and line.strip().endswith('{') and line.strip().__contains__(keyword):
                        line = line.replace('{','\n{').replace('}','}\n')

                    if line.strip().startswith('}') and line.__contains__(keyword):
                        line = line.replace('}', '}\n')
                    if line.strip().startswith(keyword) and line.strip().endswith('{'):
                        line = line.replace('{', '\n{')

                        continue
                if line.strip().startswith("If") and not (line.strip().endswith("Then")):
                    target_file.write(line)
                    target_file.write("End If")




                else:
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
        IF_VAR = "if"
        ELSE_VAR = "else"
        if_block = []
        if_flag = False
        bracket_counter = 0
        else_flag = False
        else_brac_counter = 0

        line_list = copy.deepcopy(input_file.readlines())

        # for index, line in enumerate(line_list):
        #
        #     """
        #     Add end-if on top of every else which gives closure.
        #     for IF BLOCK and it is obvious that always IF ends on top of Else.
        #     """
        #
        #     if line.lstrip().startswith(ELSE_VAR) and not( line_list[index -1].__contains__("end-if")) :
        #         line_list.insert(index,"end-if")
        #
        # for index1,line in enumerate(line_list):
        #     if line.strip().startswith("if"):
        #
        #         if_flag = True
        #         continue
        #
        #     if line.strip().startswith("else") or line.strip().startswith("case") or  line.strip().startswith("default") or  line.strip().startswith("switch") :
        #         else_flag = True
        #         continue
        #     if else_flag and line.strip().startswith("{") and if_flag == False:
        #         else_brac_counter +=1
        #         continue
        #
        #
        #
        #     if if_flag and line.strip().startswith("{"):
        #         bracket_counter = bracket_counter + 1
        #         continue
        #
        #     if if_flag and line.strip().startswith("}"):
        #         if else_flag:
        #             else_flag = False
        #             continue
        #         if index1+1 == len(line_list):
        #             continue
        #
        #         if  not line_list[index1+1].__contains__("end-if"):
        #             if line_list[index1-1].__contains__(" break;"):
        #                 continue
        #             if line_list[index1 - 2].__contains__(" break;"):
        #                 continue
        #
        #
        #             else:
        #
        #                 line_list.insert(index1+1,"end-if")
        #                 if_flag = False
        #         else:
        #             if_flag = False
        #
        # # print("***************************")
        # # print(json.dumps(line_list,indent=4))

        return line_list

    # def tagging_end_if_to_singleline_id_for_each_function(self, lines_list):
    #     # input_file = open(file, "r")
    #     IF_VAR = "if"
    #     ELSE_VAR = "else"
    #     if_block = []
    #     if_flag = False
    #     bracket_counter = 0
    #     else_flag = False
    #     else_brac_counter = 0
    #     else_flag_counter = 0
    #
    #     line_list = copy.deepcopy(lines_list)
    #
    #     for index, line in enumerate(line_list):
    #
    #         """
    #         Add end-if on top of every else which gives closure.
    #         for IF BLOCK and it is obvious that always IF ends on top of Else.
    #         """
    #
    #         if line.lstrip().startswith(ELSE_VAR) and not (line_list[index - 1].__contains__("end-if")):
    #             line_list.insert(index, "end-if")
    #
    #     for index1, line in enumerate(line_list):
    #         if line.strip().startswith("if"):
    #             if_flag = True
    #             continue
    #
    #         if line.strip().startswith("catch") or line.strip().startswith("try") or line.strip().startswith(
    #                 "foreach") or line.strip().startswith("else") or line.strip().startswith(
    #             "for") or line.strip().startswith("case") or line.strip().startswith(
    #             "default") or line.strip().startswith("switch"):
    #             else_flag = True
    #             else_flag_counter += 1
    #             continue
    #         # if else_flag and line.strip().startswith("{") and if_flag == False:
    #         #     else_brac_counter += 1
    #         #     continue
    #         if else_flag and line.strip().startswith("}") and if_flag == False:
    #             else_brac_counter += 1
    #             # continue
    #             # if else_brac_counter == 0:
    #             #     else_flag = False
    #
    #         if if_flag and line.strip().startswith("{"):
    #             bracket_counter = bracket_counter + 1
    #             continue
    #
    #         if if_flag and line.strip().startswith("}"):
    #             if else_flag:
    #                 if else_flag_counter == 0:
    #
    #                     else_flag = False
    #                     continue
    #                 else:
    #                     else_flag_counter -= 1
    #
    #                     continue
    #             if index1 + 1 == len(line_list):
    #                 continue
    #
    #             if not line_list[index1 + 1].__contains__("end-if"):
    #                 if line_list[index1 - 1].__contains__(" break;"):
    #                     continue
    #                 if line_list[index1 - 2].__contains__(" break;"):
    #                     continue
    #
    #
    #                 else:
    #
    #                     line_list.insert(index1 + 1, "end-if")
    #                     # if_flag = False
    #             else:
    #                 if_flag = False
    #
    #     # print("***************************")
    #     # print(json.dumps(line_list,indent=4))
    #
    #     return line_list
    def tagging_end_if_to_singleline_id_for_each_function(self, lines_list):
        # input_file = open(file, "r")
        IF_VAR = "if"
        ELSE_VAR = "else"
        if_block = []
        if_flag = False
        bracket_counter = 0
        else_flag = False
        else_brac_counter = 0
        else_flag_counter = 0

        line_list = copy.deepcopy(lines_list)

        for index, line in enumerate(line_list):

            """
            Add end-if on top of every else which gives closure.
            for IF BLOCK and it is obvious that always IF ends on top of Else. 
            """

            if line.lstrip().startswith(ELSE_VAR) and not (line_list[index - 1].__contains__("end-if")):
                line_list.insert(index, "end-if")

        for index1, line in enumerate(line_list):
            if line.strip().startswith("if"):
                if_flag = True
                continue

            if line.strip().startswith("catch") or line.strip().startswith("try") or line.strip().startswith(
                    "foreach") or line.strip().startswith("else") or line.strip().startswith(
                    "for") or line.strip().startswith("case") or line.strip().startswith(
                    "default") or line.strip().startswith("switch") or line.strip().startswith('while'):
                if line_list[index1 + 1].strip().startswith("{"):

                    else_flag = True
                    else_flag_counter += 1
                    continue
                else:

                    continue
            if else_flag and line.strip().startswith("{") and if_flag == False:
                else_brac_counter += 1
                continue
            if else_flag and line.strip().startswith("}") and if_flag == False:
                else_brac_counter -= 1
                if else_brac_counter==0:
                    else_flag=False
                continue

            if if_flag and line.strip().startswith("{"):
                bracket_counter = bracket_counter + 1
                continue

            if if_flag and line.strip().startswith("}"):
                if else_flag:
                    else_flag_counter -= 1
                    if else_flag_counter == 0:
                        bracket_counter = bracket_counter - 1
                        else_flag = False
                        continue
                    else:
                        bracket_counter = bracket_counter - 1

                        continue
                if index1 + 1 == len(line_list):
                    continue

                if not line_list[index1 + 1].__contains__("end-if"):
                    if line_list[index1 - 1].__contains__(" break;"):
                        continue
                    if line_list[index1 - 2].__contains__(" break;"):
                        continue


                    else:

                        line_list.insert(index1 + 1, "end-if")
                        # if_flag = False
                else:
                    if_flag = False

        # print("***************************")
        # print(json.dumps(line_list,indent=4))

        return line_list

    def recur_end_if_tagger(self, line_list):

        pass

    def break_code_into_blocks(self, processed_line_list):
        METADATA = {}
        function_list = []
        flag = False
        bracket_list = []
        count = 0
        function_name = ''
        unique_fun_counter = 0
        bracket_flag=False
        open_bracket_line=''
        close_bracket_line=''
        for line in processed_line_list:

            if line.strip().startswith('protected') or line.strip().startswith('public') or line.strip().startswith(
                    'private'):
                if line.__contains__('(') and line.__contains__(')'):
                    function_name=line.split(')')[0]+')'
                    flag=True
                    #print(function_name)
                if line.__contains__('(') and not line.__contains__(')'):
                    #print(line)
                    bracket_flag=True
                    open_bracket_line=line
                    continue
            if bracket_flag and line.__contains__(')')  and not line.__contains__('('):
                close_bracket_line=open_bracket_line+line
                function_name=close_bracket_line.split(')')[0]+')'
                flag=True


                    # if line.__contains__('void'):
                    #     function_name = line.split("void")[-1].split("(")[0]
                    #     flag = True
                    # else:
                    #     function_name = line.split('(')[0].split()[-1]
                    #     flag = True
            if flag:
                function_list.append(line.rstrip())
                if "{" in line:
                    count+= 1
                    # brackets_list = line.split()
                    # # print(brackets_list)
                    # for i in brackets_list:
                    #     if i == '{':
                    #         count += 1
                if '{{' in line:
                    count+= 2
                if '}}' in line:
                    count-=2

                if "}" in line:
                    count-=1
                    # brackets_list = line.split()
                    # # print(brackets_list)
                    # for i in brackets_list:
                    #     if i == '}':
                    #         count -= 1
                    if count == 0 and flag:
                        flag = False

                        # if function_name in METADATA.keys():
                        #     unique_fun_counter += 1
                        #     function_name = function_name + str(unique_fun_counter)

                        METADATA[function_name] = copy.deepcopy(function_list)
                        function_list.clear()

        return METADATA


class flowchartProcessing(PreProcessing, Database):

    def __init__(self, DB_CON, pre_prop):

        super().__init__()
        cursy = DB_CON.Db_conn("Vb_net1", "Pub_Fun_Lookup")

        PUB_SHRD_FUN_LIST = cursy.distinct("Function_name")

        file_list = pre_prop.get_files()
        # self.file_list = ["D:\Lcaas_imp\WebApplications\LobPF\PFLocCovergaeInput.aspx.vb"]
        self.file_list = file_list

        cursy = DB_CON.Db_conn("java", "Pub_Fun_Lookup")

        self.PUB_SHRD_FUN_LIST = cursy.distinct("Function_name")

        """Pass Files using for loop"""
        for file in self.file_list:
            # code_block_dict = pre_prop.remove_comments_write_to_temp_file(
            #     "D:\Lcaas_imp\WebApplications\LobPF\PFLocCovergaeInput.aspx.vb")
            #
            # self.obj_list = self.fetchimport_var("D:\Lcaas_imp\WebApplications\LobPF\PFLocCovergaeInput.aspx.vb")
            #
            # self.block_separation(code_block_dict, "D:\Lcaas_imp\WebApplications\LobPF\PFLocCovergaeInput.aspx.vb")
            print("File", file)
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

    def block_separation(self, code_block_dict, file_name):

        for fun_name in code_block_dict.keys():
            # print(fun_name)
            dict_counter = 0
            dict = {}
            node_sequence = []

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

            bracket_counter = 0
            pre_processed_list = self.tagging_end_if_to_singleline_id_for_each_function(code_block_dict[fun_name])
            # print(json.dumps(pre_processed_list,indent=4))
            for index, line in enumerate(pre_processed_list):

                if line.strip().startswith("if") and case_flag == False:

                    if group_block_variable != '':
                        total_group_block_counter = total_group_block_counter + 1

                        node_sequence.append('G' + str(total_group_block_counter))

                        node_code['G' + str(total_group_block_counter)] = group_block_variable
                        group_block_variable = ''
                    if code_block_dict[fun_name][index - 1].strip().startswith("NElse"):
                        if_block.append(line.rstrip() + "\n")
                        if_else_counter = if_else_counter + 1
                        continue

                    if_block.append(line.rstrip() + "\n")
                    if_flag = True
                    continue

                if if_flag and line.strip().startswith("{"):
                    if (pre_processed_list[index - 1].strip().lower().startswith("switch") or
                            pre_processed_list[index - 1].strip().lower().startswith("for") or
                            pre_processed_list[index - 1].strip().lower().startswith("else") or
                            pre_processed_list[index - 1].strip().lower().startswith("default") or
                            pre_processed_list[index - 1].strip().lower().startswith("case")
                            or pre_processed_list[index - 1].strip().lower().startswith("try")
                            or pre_processed_list[index - 1].strip().lower().startswith("foreach")
                            or pre_processed_list[index - 1].strip().lower().startswith("catch")

                    ):

                        continue
                    else:
                        bracket_counter = bracket_counter + 1
                        if_block.append(line.rstrip() + "\n")
                        continue

                # if if_flag and ( line.strip().lower().startswith("switch")or
                #                  line.strip().lower().startswith("for")or
                #                  line.strip().lower().startswith("else")or
                #                  line.strip().lower().startswith("default")or
                #                  line.strip().lower().startswith("case")
                #                 ):
                #     bracket_counter = bracket_counter - 1
                if if_flag and line.strip().startswith("end-if"):
                    bracket_counter = bracket_counter - 1
                    if_block.append(line.rstrip() + "\n")
                    if bracket_counter == 0 and if_flag:
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
                            if line.strip().startswith('{') or line.strip().startswith('}'):
                                continue
                            else:
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
                                    """Check weather false block is containing values or not """
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

                                            if i + 3 > len(node_sequence) - 1:
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
                                if re.match('^S.*', node_sequence[i + 2]) or re.match('^G.*', node_sequence[i + 2]):
                                    links_string = links_string + '\n' + node_sequence[i] + '->' + node_sequence[i + 2]
                                    continue
                                if re.match('^C.*', node_sequence[i + 2]):
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
                            links_string = links_string + '->' + 'e'

            """
            node fomation and linking 
            """

            print(fun_name)
            # print("NodeSeque:", node_sequence)
            # print("Nodecode:", json.dumps(node_code,indent=4))
            # print(fun_name,node_code)
            print(node_string)
            print(links_string)

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
            DB_CON.db_update("java", "para_flowchart_data", OUTPUT_DATA)
            OUTPUT_DATA.clear()

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

        IF_VAR = "if"
        ELSE_VAR = "else"
        END_IF_VAR = "end-if"
        ELSE_IF_VAR = "ElseIf"
        NELSE_VAR = "NElse"

        # 3 = {str} '                        NElse\n'
        index_list = []
        # print(json.dumps(line_list,indent=4))
        line_list = self.remove_brackets(line_list)

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
        # print(json.dumps(index_list,indent=4))
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

                if len(index_list) > alter_index + 1:
                    if ELSE_VAR in index_list[alter_index + 1] and list(index_list[alter_index].values())[0] + 1 == \
                            list(index_list[alter_index + 1].values())[0]:
                        continue
                    else:
                        false_block_count = pop_list[-1]

                        node_sequence.append("F" + str(false_block_count))
                        node_code['F' + str(false_block_count)] = ""
                        pop_list.pop()

            if (ELSE_VAR in index_list[index] and IF_VAR in index_list[alter_index]):

                false_block_var = line_list[
                                  list(index_list[index].values())[0] + 1: list(index_list[alter_index].values())[
                                      0]]
                if END_IF_VAR in index_list[index - 1] and list(index_list[index - 1].values())[0] + 1 == \
                        list(index_list[index].values())[0]:
                    false_block_count = pop_list[-1]

                    node_sequence.append("F" + str(false_block_count))
                    node_code['F' + str(false_block_count)] = "".join(false_block_var)
                    pop_list.pop()
                    false_block_var = ''
                else:
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

                        # elif END_IF_VAR in index_list[index] and ELSE_VAR in index_list[alter_index]:
                        #
                        #     if len(index_list)< alter_index +1:

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

        # print(json.dumps(node_code, indent=4))
        # print(node_sequence)
        if pop_list != []:

            for item in pop_list:
                false_block_count = pop_list[-1]

                node_sequence.append("F" + str(false_block_count))
                node_code['F' + str(false_block_count)] = ""
                pop_list.pop()

        return False, total_group_block_counter, block_counter, node_sequence, node_code, total_if_block_counter

    # def linking(self,dict):

    def remove_brackets(self, linelist):
        processed_line_list = []
        for line in linelist:

            if line.strip().startswith("}") or line.strip().startswith("{"):
                continue
            else:
                processed_line_list.append(line)

        return processed_line_list


pre_prop = PreProcessing()
DB_CON = Database()
flw = flowchartProcessing(DB_CON, pre_prop)
