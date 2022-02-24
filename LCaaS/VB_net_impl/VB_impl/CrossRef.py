import os, glob,copy
from xlsxwriter import Workbook
import pymongo
import Vb_Parsing.config as config

vb = config.codebase_information['VB']['folder_name']
code_location = config.codebase_information['code_location']
vb_path=code_location+'\\'+vb+'\\*'
vb_component_path = code_location + "\\ApplicationAssembles\\*\\*"
META_DATA = []


class pub_sh_lookup:




    def build_lookup(self,file_list):

            op_json = {"Lob_name":"",
                       "File_name":"",
                       "Function_name":"",
                       "No_of_params":"",
                       "List_of_parms":""
            }
            DB_Data=[]

            for filename in file_list:
                try:
                    f = open(filename, "r")
                    read = False

                    line_list = []
                    for line in f.readlines():
                        calling_fun_name =''
                        if line.lower().__contains__("public shared function") or line.lower().__contains__("public shared sub"):
                            read = True
                            if line.lower().__contains__("shared function"):
                                calling_fun_name = line.split("Function")[1].split("(")[0].strip()
                                op_json['Function_name'] = calling_fun_name
                            if line.lower().__contains__(" shared sub"):
                                if line.__contains__("Sub"):
                                    calling_fun_name = line.split("Sub")[1].split("(")[0].strip()
                                    op_json['Function_name'] = calling_fun_name
                                else:
                                    calling_fun_name = line.split("sub")[1].split("(")[0].strip()
                                    op_json['Function_name'] = calling_fun_name
                        if read:
                            line_list.append(line)
                        if (line.lower().__contains__("end function") or line.lower().__contains__("end sub")) and line_list != []:
                            read = False
                            no_of_params ,params_list =self.fetch_parametres_count(line_list,calling_fun_name)
                            op_json['File_name'] = filename.split("\\")[-1]
                            op_json['Lob_name'] = filename.split("\\")[-2].replace(".BusinessRules","")

                            op_json['No_of_params'] = no_of_params
                            op_json['List_of_parms'] = params_list
                            DB_Data.append(copy.deepcopy(op_json))
                            op_json.clear()
                            line_list.clear()
                except Exception as e:
                    print("Error::",e)


            self.db_delete("Vb_net", "Pub_Fun_Lookup")
            self.db_update("Vb_net", "Pub_Fun_Lookup", DB_Data)

    def db_update(self,db_name,col_name,Metadata):

        cursy = self.Db_conn(db_name, col_name)

        try:
                cursy.insert_many(Metadata)
                print(db_name,col_name,"Created and inserted")

        except Exception as e:
            print("Error:", db_name,col_name,e)


    def db_delete(self,db_name,col_name):
        cursy = self.Db_conn(db_name, col_name)
        try:
            cursy.delete_many({})
            print(db_name,col_name,"Deleted")

        except Exception as e :
            print("Error:", db_name,col_name,e)


    @staticmethod
    def fetch_parametres_count(fun_lines_list, calling_fun_name):
        try:
            line_collector_variable = ''
            line_collector_flag = False

            for line in fun_lines_list:

                if line_collector_flag:
                    if line.rstrip().endswith(")")  or line.__contains__(")"):
                        line_collector_variable = line_collector_variable + '\n' + line
                        parameters_list = line_collector_variable.replace(")", "").replace("\n", "").split(",")
                        parameters_count = len(parameters_list)
                        return parameters_count, parameters_list

                    else:
                        line_collector_variable = line_collector_variable + '\n' + line
                        continue

                if line.__contains__(calling_fun_name):
                    if line.rstrip().endswith(")") or line.__contains__(")"):
                        para_name_collection = line.split("(")
                        para_name_list = para_name_collection[0].split()
                        parameters_list = para_name_collection[1].split(")")[0].replace("\n", "").split(",")
                        if parameters_list == [""]:
                            parameters_count = 0
                        else:
                            parameters_count = len(parameters_list)
                        para_name = para_name_list[-1]
                        return parameters_count, parameters_list
                    else:

                        line_collector_variable = line.split("(")[1] + '\n'

                        line_collector_flag = True
                        continue
            return "", ""
        except IndexError as e :
            print(e)

    @staticmethod
    def write_to_excel(Wb_name, metadata, ordered_list):

        try:
            wb = Workbook(Wb_name)
            ws = wb.add_worksheet("Sheet1")
            first_row = 0
            # list object calls by index but dict object calls items randomly

            for header in ordered_list:
                col = ordered_list.index(header)  # we are keeping order.
                ws.write(first_row, col, header)
            row = 1
            for records in metadata:
                for _key, _value in records.items():
                    col = ordered_list.index(_key)
                    ws.write(row, col, _value)
                row += 1  # enter the next row
            wb.close()
        except Exception as e:
            print("Errpr:", e, metadata[0])

    @staticmethod
    def Db_conn(db_name, col_name):
        conn = pymongo.MongoClient("localhost", 27017)
        return conn[db_name][col_name]

    @staticmethod
    def get_files():
        filenames_list = []
        for filename1 in glob.glob(os.path.join(vb_path, '*.aspx.vb')):
            filenames_list.append(filename1)
        for filename2 in glob.glob(os.path.join(vb_component_path, '*.vb')):
            filenames_list.append(filename2)

        return filenames_list





class Xref(pub_sh_lookup):


    def __init__(self, file_list):
        self.file_list = file_list
        self.process()


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

    def fetch_file_list(self, filelist):
        namelist = []
        dicts = {}
        for file in filelist:
            dicts["file_name"] = file.split("\\")[-1].replace(".aspx.vb", "").replace('.VB', '').replace('.vb', '')
            dicts['lob_name'] = file.split(("\\"))[-2].replace(".BusinessRules", '')
            namelist.append(copy.deepcopy(dicts))

        return namelist

    @staticmethod
    def remove_duplicates(list):
        res = []
        for i in list:
            if i not in res:
                res.append(i)
        return res

    def json_maker(self,file,ref_list,matches_list,ref,flag):
        op_json = {
            "component_name": "",
            "component_type": "",
            "called_name": "",
            "called_type": "",
            "calling_Lob_name": "",
            "called_Lob_name": "",
            "step_name": "",
            "disp": "",
            "comments": "",
            "dd_name": "",

        }

        val = next(item for item in ref_list if item[ref] == matches_list[0])
        # print(val,line)
        op_json["component_name"] = file.split("\\")[-1].split(".")[0]
        op_json['component_type'] = file.split("\\")[-1].split(".")[1].replace("aspx", "aspx.vb")
        op_json['calling_Lob_name'] = file.split("\\")[-2].replace(".BusinessRules", '')
        op_json['called_name'] = val['called_file_name']
        op_json['called_type'] = 'VB' if flag else val["File_name"].split(".")[1].replace("aspx", "aspx.vb")
        op_json['called_Lob_name'] = val['called_lob_name']
        META_DATA.append(copy.deepcopy(op_json))
        pass




    def break_code_into_blocks(self,file):

        fun_flag = False
        f = open(file, "r")
        code_block_list = []
        code_block_hash = {}
        function_name = ''


        for line in f.readlines():
            try:

                if (line.lower().__contains__("end sub") or line.lower().__contains__("end function")):

                    fun_flag = False
                    code_block_hash[function_name] = copy.deepcopy(code_block_list)
                    function_name = ''
                    code_block_list.clear()


                if (line.lower().__contains__(" sub ") or line.lower().__contains__(" function ")) and (line.lower().__contains__("public") or line.lower().__contains__("private")):
                    if line.strip().startswith("Public Shared Function"):
                        function_name = line.split("Function")[1].split("(")[0]


                    else:
                        # print(line)
                        line1 = line.replace(" Sub","Function").replace(" sub","Function").replace("function","Function")
                        function_name = line1.split("Function")[1].split("(")[0]
                    fun_flag = True

                if fun_flag:
                    code_block_list.append(line)
            except IndexError as e:
                print(f'Error:list index out of range:{line}')



        return code_block_hash


    def scan_for_stored_proc(self,code_block_dict,file):

        # function_name_list = [x for x in code_block_dict.keys()]
        # print(function_name_list)
        command_type = False
        op_json = {}
        store_proc_name =''
        for fun , line_list in code_block_dict.items():
            for line in line_list:
                if line.__contains__(".CommandType") and line.__contains__("CommandType.StoredProcedure") and line.__contains__("="):
                    command_type = True
                    break

                if line.__contains__(".CommandText ")  and line.__contains__("="):
                    store_proc_name = line.split('=')[1]
            if command_type:
                op_json["component_name"] = file.split("\\")[-1].split(".")[0]
                op_json['component_type'] = file.split("\\")[-1].split(".")[1].replace("aspx", "aspx.vb")
                op_json['calling_Lob_name'] = file.split("\\")[-2].replace(".BusinessRules", '')
                op_json['called_name'] = store_proc_name
                op_json['called_type'] = 'Store Proc'
                op_json['called_Lob_name'] =  file.split("\\")[-2].replace(".BusinessRules", '')
                META_DATA.append(copy.deepcopy(op_json))

            for index,line in enumerate(line_list):
                if line.__contains__('(CommandType.StoredProcedure'):

                    if line.strip().endswith("_"):
                        line = line.strip() + line_list[index+1].strip()
                        print(line)
                        store_proc_name = line.split("(CommandType.StoredProcedure")[1].split(",")[1].split(")")[0]
                        store_proc_name = self.check_storeproc_var_or_not(store_proc_name, line_list)
                        op_json["component_name"] = file.split("\\")[-1].split(".")[0]
                        op_json['component_type'] = file.split("\\")[-1].split(".")[1].replace("aspx", "aspx.vb")
                        op_json['calling_Lob_name'] = file.split("\\")[-2].replace(".BusinessRules", '')
                        op_json['called_name'] = store_proc_name
                        op_json['called_type'] = 'Store Proc'
                        op_json['called_Lob_name'] = file.split("\\")[-2].replace(".BusinessRules", '')
                        META_DATA.append(copy.deepcopy(op_json))

                    else:


                        store_proc_name = line.split("(CommandType.StoredProcedure")[1].split(",")[1].split(")")[0]
                        store_proc_name =self.check_storeproc_var_or_not(store_proc_name,line_list)
                        op_json["component_name"] = file.split("\\")[-1].split(".")[0]
                        op_json['component_type'] = file.split("\\")[-1].split(".")[1].replace("aspx", "aspx.vb")
                        op_json['calling_Lob_name'] = file.split("\\")[-2].replace(".BusinessRules", '')
                        op_json['called_name'] = store_proc_name
                        op_json['called_type'] = 'Store Proc'
                        op_json['called_Lob_name'] = file.split("\\")[-2].replace(".BusinessRules", '')
                        META_DATA.append(copy.deepcopy(op_json))

                if line.__contains__(',CommandType.StoredProcedure'):
                    store_proc_line = line.split("(")[1].split(")")[0]
                    store_proc_name = store_proc_line.split(",")[0]
                    store_proc_name = self.check_storeproc_var_or_not(store_proc_name, line_list)
                    op_json["component_name"] = file.split("\\")[-1].split(".")[0]
                    op_json['component_type'] = file.split("\\")[-1].split(".")[1].replace("aspx", "aspx.vb")
                    op_json['calling_Lob_name'] = file.split("\\")[-2].replace(".BusinessRules", '')
                    op_json['called_name'] = store_proc_name
                    op_json['called_type'] = 'Store Proc'
                    op_json['called_Lob_name'] = file.split("\\")[-2].replace(".BusinessRules", '')
                    META_DATA.append(copy.deepcopy(op_json))





    def check_storeproc_var_or_not(self,store_proc_name,line_list):
        if not (store_proc_name.strip().startswith('"')):
            for sp in line_list:
                if sp.__contains__(store_proc_name) and sp.__contains__("="):
                    store_proc_name = sp.split("=")[1]

        return store_proc_name

    def process(self):

        op_json = {
            "component_name": "",
            "component_type": "",
            "called_name": "",
            "called_type": "",
            "calling_Lob_name": "",
            "called_Lob_name": "",
            "step_name": "",
            "disp": "",
            "comments": "",
            "dd_name": "",

        }
        ref_file_dict_list = self.fetch_file_list(file_list)
        ref_file_list = [x['file_name'] for x in ref_file_dict_list]
        cursy = self.Db_conn("Vb_net", "Pub_Fun_Lookup")
        # print(ref_file_list)
        for file in file_list:
            Pub_shar_db_list = self.fetch_db_cursor_to_list(cursy.find({"Lob_name": file.split("\\")[-2].replace(".BusinessRules", '').strip()},{"_id":0}))

            Pub_shar_fun_list = [x['Function_name'] for x in Pub_shar_db_list]
            code_blocks_dict = self.break_code_into_blocks(file)



            ref_var_list = self.fetchimport_var(file)
            obj_list = [x['obj_name'] for x in ref_var_list]
            # print(file)

            f = open(file, "r")

            for line in f.readlines():
                matches1 = [x for x in obj_list if " " + x in line]
                matches1 = self.remove_duplicates(matches1)
                if matches1 != []:
                    # print(matches1,line)
                    # self.json_maker(file,ref_var_list,matches1,"obj_name",True)

                    val = next(item for item in ref_var_list if item["obj_name"] == matches1[0])
                    # print(val,line)
                    op_json["component_name"] = file.split("\\")[-1].split(".")[0]
                    op_json['component_type'] = file.split("\\")[-1].split(".")[1].replace("aspx", "aspx.vb")
                    op_json['calling_Lob_name'] = file.split("\\")[-2].replace(".BusinessRules", '')
                    op_json['called_name'] = val['called_file_name']
                    op_json['called_type'] = 'VB'
                    op_json['called_Lob_name'] = val['called_lob_name']
                    META_DATA.append(copy.deepcopy(op_json))

                matches2 = [x for x in ref_file_list if x + " " in line]
                if matches2 != []:
                    # print(matches2,line)
                    # self.json_maker(file, ref_file_dict_list, matches2, "file_name", True)
                    val = next(item for item in ref_file_dict_list if item["file_name"] == matches2[0])
                    op_json["component_name"] = file.split("\\")[-1].split(".")[0]
                    op_json['component_type'] = file.split("\\")[-1].split(".")[1].replace("aspx", "aspx.vb")
                    op_json['calling_Lob_name'] = file.split("\\")[-2].replace(".BusinessRules", '')
                    op_json['called_name'] = matches2[0]
                    op_json['called_type'] = 'VB'
                    op_json['called_Lob_name'] = val['lob_name']
                    META_DATA.append(copy.deepcopy(op_json))

                matches3 = [x for x in Pub_shar_fun_list if " "+x in line and not (line.__contains__("Public Shared"))]
                if matches3 !=[]:
                    # print(line , matches3)
                    # self.json_maker(file, Pub_shar_db_list, matches3, "Function_name", False)
                    val = next(item for item in Pub_shar_db_list if item["Function_name"] == matches3[0])
                    op_json["component_name"] = file.split("\\")[-1].split(".")[0]
                    op_json['component_type'] = file.split("\\")[-1].split(".")[1].replace("aspx", "aspx.vb")
                    op_json['calling_Lob_name'] = file.split("\\")[-2].replace(".BusinessRules", '')
                    op_json['called_name'] = val["File_name"]
                    op_json['called_type'] = val["File_name"].split(".")[1].replace("aspx", "aspx.vb")
                    op_json['called_Lob_name'] = val['Lob_name']
                    META_DATA.append(copy.deepcopy(op_json))
            store_proc_jsons = self.scan_for_stored_proc(code_blocks_dict,file)





pubShLokUp =  pub_sh_lookup()

file_list =pub_sh_lookup.get_files()
pubShLokUp.build_lookup(file_list)
xref =Xref(file_list)

# print(json.dumps(xref.remove_duplicates(META_DATA),indent=4))
print(len(xref.remove_duplicates(META_DATA)))
pubShLokUp.db_delete("Vb_net","cross_reference_report")
pubShLokUp.db_update("Vb_net","cross_reference_report",xref.remove_duplicates(META_DATA))
