import Vb_Parsing.config as config
import Vb_Parsing.Database as DB
import Vb_Parsing.Utility as util
import copy,json


vb_path = config.vb_path
vb_component_path = config.vb_component_path


META_DATA = []


class Lexical_Analysis:

    def __init__(self,file_list):
        file_list = file_list
        self.process(file_list)

    def process(self,file_list):
        file_name_list = [x.split("\\")[-1].split(".")[0] for x in file_list]
        # print(file_name_list)
        for file in file_list:

            self.pattern_classifier(file,file_name_list)

    @staticmethod
    def fetch_import_var(filename):
        ref_var_list = []

        with open(filename,encoding="UTF-8") as vb_file:
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
        return tuple(util.PreProcessing.remove_duplicates(ref_var_list))

    @staticmethod
    def break_code_into_blocks(file):

        fun_flag = False

        code_block_list = []
        code_block_hash = {}
        function_name = ''

        with open(file,encoding="UTF-8" ) as f:
            for line in f.readlines():
                try:

                    if (line.lower().__contains__("end sub") or line.lower().__contains__("end function")):

                        fun_flag = False
                        code_block_hash[function_name] = copy.deepcopy(code_block_list)
                        function_name = ''
                        code_block_list.clear()


                    if (line.lower().__contains__(" sub ") or line.lower().__contains__(" function ")) and (line.lower().__contains__("public") or line.lower().__contains__("private") or line.lower().__contains__("protected")):
                        if line.strip().startswith("Public Shared Function"):
                            function_name = line.split("Function")[1].split("(")[0]


                        else:
                            # print(line)
                            line1 = line.replace(" Sub"," Function").replace(" sub","Function").replace("function","Function")
                            function_name = line1.split("Function")[1].split("(")[0]
                        fun_flag = True

                    if fun_flag:
                        code_block_list.append(line)
                except IndexError as e:
                    print(f'Error:list index out of range:{line}')



        return code_block_hash



    def pattern_classifier(self,file,filename_list):

        # print(file)

        code_dict = self.break_code_into_blocks(file)

        cursy = DB.Database.Db_conn("Vb_net1", "Pub_Fun_Lookup")

        Pub_shar_db_list = DB.Database.fetch_db_cursor_to_list(
            cursy.find({"Lob_name": file.split("\\")[-2]}, {"_id": 0}))

        Pub_shar_fun_list = [x['Function_name'] for x in Pub_shar_db_list]
        # print("sha", Pub_shar_fun_list,file)

        obj_list = [x for x in self.fetch_import_var(file)]
        # print("obj_list",obj_fun_list,file)
        local_fun_list = [x for x in code_dict.keys()]
        # print("localfunlist",local_fun_list,file)


        """
         "App_name" : "",
        "File_name" : "Forgot.aspx.vb",
        "Function_name" : "Forgot",
        "No_of_params" : 6,
        "List_of_parms" : [
            "ByVal stxt3YDate As String",
            "                                           ByVal stxt3YGrossLossAmt As String",
            "                                           ByVal stxt3YCapNormalLoss As String",
            "                                           ByVal stxt3YDeductible As String",
            "                                           ByVal stxt3YNetNormalLoss As String",
            "                                           ByVal check As Integer As String"
            ],
        "internal" : [
            "login1",
            "delete1"
        ],
        
        "External" : [
           
            {
            "setup1":[filename,no_parms]
            "logout1":[filename,no_parms]
            }
        ]
        
        "Pub_shared" : [
           
            {
            "setup1":[filename,no_parms]
            "logout1":[filename,no_parms]
            }
        ]
        
        
        """


        for funname, lines in code_dict.items():

            # print(file)
            temp_json = {}
            no_of_params, params_list = util.PreProcessing.fetch_parametres_count(lines, funname)
            op_json = {"App_name": file.split("\\")[-2], "File_name": file.split("\\")[-1],
                       "Function_name": funname.strip(), "No_of_params": no_of_params,
                       "List_of_parms": params_list,
                       "External":[],"Internal":[],"Pub_shared":[],"Redirect":[]}

            for line in lines:

                matches1 = [x for x in obj_list if " " + x in line]
                matches1 = util.PreProcessing.remove_duplicates(matches1)

                if matches1 != []:
                    """extrrnal call json foramtion"""
                    print("extrnalobj",matches1)


                internal_fun_list = [x for x in local_fun_list if " " + x in line]
                if internal_fun_list != []:
                    for internal_fun in internal_fun_list:

                        op_json["Internal"].append(internal_fun)


                matches3 = [x for x in Pub_shar_fun_list if " "+x in line and not (line.__contains__("Public Shared"))]
                if matches3 !=[]:

                    print("pb",matches3)

                ext_file_name_list = [x for x in filename_list if " "+x+"." in line and not (line.__contains__("Sub") or line.__contains__("Function"))]
                if ext_file_name_list !=[]:


                    for ext_file_name in ext_file_name_list:


                        if line.__contains__("="):
                            ext_fun_name = line.split("=")[1].split("(")[0].split(".")[1]
                        else:
                            ext_fun_name = line.split("(")[0].split(".")[1]
                        temp_json[ext_fun_name] = [ext_file_name+".vb", 0]



                        # op_json["Pub_shared"]: [
                        #
                        #     {
                        #         "setup1": ["filename", "no_parms"],
                        #         "logout1": ["filename", "no_parms"]
                        #     }
                        # ]

                if line.__contains__("Response.Redirect"):
                    if line.__contains__("~/"):
                        op_json['Redirect'].append(line.split("/")[-1].replace(".aspx","").replace(")","").replace('"',"").strip()+".aspx")

                    else:
                        op_json['Redirect'].append(line.split("(")[1].split(")")[0].replace('"',"").replace("'","").strip().replace(".aspx","").strip()+".aspx")




            op_json["External"].append(copy.deepcopy(temp_json))
            temp_json.clear()
            META_DATA.append(op_json)







if __name__ == '__main__':

    file_list = util.PreProcessing.get_files()
    obj = Lexical_Analysis(file_list)
    print(json.dumps(META_DATA,indent=4))

    db = DB.Database()
    db.db_delete(db_name="Vb_net1",col_name= "one-one_pf")
    db.db_update(db_name="Vb_net1",col_name= "one-one_pf",Metadata=META_DATA)
