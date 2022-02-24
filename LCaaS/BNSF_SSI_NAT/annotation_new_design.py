import pytz
import xlrd, datetime
from xlsxwriter import Workbook
import pymongo
from pymongo import MongoClient
import glob, os, json, re, copy
import pytz
import config

SCRIPT_VERSION = "Keyword DB load"
time_zone = 'Asia/Calcutta'
tz = pytz.timezone(time_zone)
mongoClient = MongoClient('localhost', 27017)

vb = config.codebase_information['VB']['folder_name']
code_location = config.codebase_information['code_location']
vb_path = code_location + '\\' + vb
vb_component_path = code_location + "\\ApplicationAssembles\\LobPF\\*"


class Annotate:

    def keyword_load(self, loc, db_name, col_name):
        Metadata = []

        wb = xlrd.open_workbook(loc)
        sheet = wb.sheet_by_index(0)
        sheet.cell_value(0, 0)

        for i in range(0, sheet.nrows):
            d = {"keyword": " "+sheet.row_values(i)[0]+" ", "Meaning": " "+sheet.row_values(i)[1]+" "}
            # print(sheet.row_values(i)[1],sheet.row_values(i)[2])
            Metadata.append(d)

        self.db_delete(db_name, col_name)
        self.db_update(db_name, col_name, Metadata)

    def vb_var_capt(self, db_name, col_name):
        metadata = []
        file_list = self.get_files()

        for filename in file_list:

            with open(filename, 'r') as vb_file:
                output = {"File_name": "",
                          "Variable": "",
                          "Business_Meaning": ""
                          }
                for lines in vb_file.readlines():
                    if lines.strip().upper().startswith("DIM"):
                        # print(lines)
                        output["File_name"] = filename.split("\\")[-1]
                        output['Variable'] = lines.split()[1]
                        output['Business_Meaning'] = ''
                        metadata.append(copy.deepcopy(output))

                    if len(lines.split()) >= 1:
                        if (lines.strip().upper().startswith("PUBLIC") or lines.strip().upper().startswith(
                                "PRIVATE") or lines.strip().upper().startswith("PROTECTED")) and (
                                lines.strip().split()[1] != "Sub" and lines.strip().split()[1] != "Function" and
                                lines.strip().split()[1] != "Property"):
                            if lines.strip().split()[1] == "Static" or lines.strip().split()[1] == "Const":
                                # print("with",lines)
                                output["File_name"] = filename.split("\\")[-1]
                                output['Variable'] = lines.split()[2]
                                output['Business_Meaning'] = ''
                                metadata.append(copy.deepcopy(output))
                            else:
                                # print("without ",lines)
                                output["File_name"] = filename.split("\\")[-1]
                                output['Variable'] = lines.split()[1]
                                output['Business_Meaning'] = ''
                                metadata.append(copy.deepcopy(output))
        """******************************       """
        Screen_data_collection = self.Db_conn(db_name, "screen_data")
        keywords_cursy = Screen_data_collection.find({"CLASLabel": {"$ne": ""}},
                                                     {"filename": 1, "ScreenField": 1, "CLASLabel": 1, "_id": 0})
        screen_list = self.fetch_db_cursor_to_list(keywords_cursy)
        for dict in screen_list:
            dict["File_name"] = dict.pop("filename")
            dict["Variable"] = dict.pop("ScreenField")
            dict["Business_Meaning"] = dict.pop("CLASLabel")

        metadata.extend(screen_list)

        ordered_list = ["File_name", "Variable",
                        "Business_Meaning"]
        self.write_to_excel("VB_glossary.xlsx", self.remove_duplicates(metadata), ordered_list)
        self.db_delete(db_name, col_name)
        self.db_update(db_name, col_name, metadata)

    def js_var_capt(self, db_name, col_name):
        metadata_js = []

        for filename in glob.glob(os.path.join(vb_path, '*.js')):
            try:
                with open(filename, 'r') as js_file:
                    output = {"File_name": "",
                              # "Function_name":"",
                              "Variable": "",
                              "Business_Meaning": ""
                              }
                    for lines in js_file.readlines():
                        if lines.strip().lower().startswith("function"):
                            function_name = lines.split()[1].split("(")[0]
                        if lines.__contains__("const"):
                            # print(lines)
                            split_line = lines.split()
                            index = split_line.index("const")
                            output["File_name"] = filename.split("\\")[-1]
                            output['Function_name'] = function_name
                            output['Variable'] = split_line[index + 1].split("=")[0]
                            output['Business_Meaning'] = ''
                            metadata_js.append(copy.deepcopy(output))



                        elif lines.strip().upper().startswith("VAR"):
                            if lines.__contains__(",") and not lines.__contains__("("):
                                split_line = lines.split(',')

                                # print(lines)
                                for i in split_line:
                                    output["File_name"] = filename.split("\\")[-1]
                                    # output['Function_name'] = function_name
                                    output['Variable'] = i.strip().replace('var', '')
                                    output['Business_Meaning'] = ''
                                    metadata_js.append(copy.deepcopy(output))
                            else:
                                output["File_name"] = filename.split("\\")[-1]
                                # output['Function_name'] = function_name
                                output['Variable'] = lines.split()[1]
                                output['Business_Meaning'] = ''
                                metadata_js.append(copy.deepcopy(output))

                        elif lines.strip().upper().startswith("LET"):
                            if lines.__contains__(","):
                                split_line = lines.split(',')

                                # print(lines)
                                for i in split_line:
                                    output["File_name"] = filename.split("\\")[-1]
                                    # output['Function_name'] = function_name
                                    output['Variable'] = i.strip().replace('var', '').replace('let', "")
                                    output['Business_Meaning'] = ''
                                    metadata_js.append(copy.deepcopy(output))
                            else:
                                output["File_name"] = filename.split("\\")[-1]
                                # output['Function_name'] = function_name
                                output['Variable'] = lines.split()[1]
                                output['Business_Meaning'] = ''
                                metadata_js.append(copy.deepcopy(output))

            except Exception as e:
                print(filename, e, lines)

        ordered_list = ["File_name", "Variable",
                        "Business_Meaning"]
        self.write_to_excel("JS_glossary_js.xlsx", self.remove_duplicates(metadata_js), ordered_list)
        self.db_delete(db_name, col_name)
        self.db_update(db_name, col_name, metadata_js)

    def vb_var_annotation(self, db_name, rules_col, Var_col, key_col):

        rules_collection = self.Db_conn(db_name, rules_col)

        rules_cursy = rules_collection.find({"type": {"$ne": "metadata"}}, {'_id': False})
        rules_objects = self.fetch_db_cursor_to_list(rules_cursy)

        keywords_collection = self.Db_conn(db_name, Var_col)
        keywords_cursy = keywords_collection.find({"type": {"$ne": "metadata"}}, {'_id': False})
        keywords_objects = self.fetch_db_cursor_to_list(keywords_cursy)

        for bre_i in rules_objects:
            try:
                bre_i['source_statements'] = [x.replace("\n", " \n").replace('End If', "End If ") for x in
                                           bre_i['source_statements']]

                # bre_i['rule_statement'] = [" "+ x for x in bre_i['rule_statement']]
                bre_i['rule_description'] = "".join(bre_i['source_statements'])
                bre_i['source_statements'] = "".join(bre_i['source_statements'])

                for dict in keywords_objects:
                    if bre_i["pgm_name"] == dict["File_name"].replace('.vb', ""):
                        if bre_i['rule_description'].__contains__(dict['Variable']):

                            if dict['Business_Meaning'] == "":
                                continue

                            else:

                                replaced1 = re.sub(dict['Variable'], "[" + dict['Business_Meaning'] + "]",
                                                   bre_i['rule_description'])
                                # print(replaced1)

                                bre_i['rule_description'] = replaced1

            except Exception as e:
                print("Error:", e, bre_i)

        self.db_delete(db_name, rules_col)
        self.db_update(db_name, rules_col, rules_objects)
        self.keyword_annotation(db_name, rules_col, key_col)

    def keyword_annotation(self, db_name, rules_col, keyword_col):
        rules_collection = self.Db_conn(db_name, rules_col)

        rules_cursy = rules_collection.find({"type": {"$ne": "metadata"}}, {'_id': False})
        rules_objects = self.fetch_db_cursor_to_list(rules_cursy)

        keywords_collection = self.Db_conn(db_name, keyword_col)
        keywords_cursy = keywords_collection.find({"type": {"$ne": "metadata"}}, {'_id': False})
        keywords_objects = self.fetch_db_cursor_to_list(keywords_cursy)

        for bre_i in rules_objects:
            try:

                for dict in keywords_objects:
                    if bre_i['rule_description'].__contains__(dict['keyword']):
                        replaced1 = re.sub(" " + dict['keyword'] + " ", " " + dict['Meaning'] + " ",
                                           bre_i['rule_description'])

                        bre_i['rule_description'] = replaced1
                print(bre_i['rule_description'])

            except Exception as e:
                print('Error:', e, bre_i)

        ordered_list = ["file_name", "function_name", "field_name", "rule_statement", "rule_description", "rule_id",
                        "Rule_Relation", "External_rule_id", "rule_type", "type", "lob", "dependent_control",
                        "parent_rule_id", "Event_type"]
        self.write_to_excel(rules_col + ".xlsx", rules_objects, ordered_list)

        self.db_delete(db_name, rules_col)
        self.db_update(db_name, rules_col, rules_objects)

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

    def Excel_upload(self, db_name, col_name, Wb_name):
        Metadata = []

        wb = xlrd.open_workbook(Wb_name)
        sheet = wb.sheet_by_index(0)
        sheet.cell_value(0, 0)

        for i in range(1, sheet.nrows):
            d = {'File_name': sheet.row_values(i)[0], "Variable": sheet.row_values(i)[1],
                 "Business_Meaning": sheet.row_values(i)[2],
                 }

            Metadata.append(d)

        self.db_delete(db_name, col_name)
        self.db_update(db_name, col_name, Metadata)

    @staticmethod
    def get_files():
        filenames_list = []
        for filename1 in glob.glob(os.path.join(vb_path, '*.aspx.vb')):
            filenames_list.append(filename1)
        for filename2 in glob.glob(os.path.join(vb_component_path, '*.vb')):
            filenames_list.append(filename2)

        return filenames_list

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
    def fetch_db_cursor_to_list(cursor):
        data_list = []
        for js_bre_data_iter in cursor:
            data_list.append(js_bre_data_iter)
        return data_list

    @staticmethod
    def Db_conn(db_name, col_name):
        conn = pymongo.MongoClient("localhost", 27017)
        return conn[db_name][col_name]

    @staticmethod
    def remove_duplicates(list):
        res = []
        for i in list:
            if i not in res:
                res.append(i)
        return res


annotate = Annotate()

Excel_path = "D:\\bnsf\\BNSF_NAT\\one_click\\Natural_keywords.xlsx"

'''Uncomment for the first Run '''
annotate.keyword_load(Excel_path,'BNSF_NAT_POC_NEW','keyword_lookup')

# annotate.keyword_load("JS_Keywords.xlsx",'asp4_var','keyword_lookup_js')
# annotate.vb_var_capt('asp4_var','glossary')
# annotate.js_var_capt('asp4_var','glossary_js')


"""VB Annotation objects """
# annotate.vb_var_annotation("BNSF_NAT", "bre_rules_report", "glossary", "keyword_lookup")
# annotate.vb_var_annotation("BNSF_NAT", "bre_report2", "glossary", "keyword_lookup")

"""JS annotation Objects """
# annotate.vb_var_annotation("asp4_var","Bussiness_Rules","glossary_js")


"""Uploading  excel with meaning"""
# annotate.Excel_upload("asp4_var","glossary","VB_glossary.xlsx")
# annotate.Excel_upload("asp4","glossary_js","glossary_js.xlsx")
