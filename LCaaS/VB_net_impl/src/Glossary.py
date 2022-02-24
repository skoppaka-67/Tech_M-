import glob, os,copy
from xlsxwriter import Workbook
import pymongo
from pymongo import MongoClient
import pytz
import config



SCRIPT_VERSION = "Keyword DB load"
time_zone = 'Asia/Calcutta'
tz = pytz.timezone(time_zone)
mongoClient = MongoClient('localhost', 27017)

vb = config.codebase_information['VB']['folder_name']
# code_location = config.codebase_information['code_location']
code_location = "D:\\VB_IMP"
vb_path = code_location + '\\*'
# vb_component_path = "D:\\Lcaas_imp\\ApplicationAssembles\\*\\*.BusinessRules"
vb_component_path = "D:\\VB_IMP\\vbcomponent"



class Glossary:

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
                        print(lines)
                        output["File_name"] = filename.split("\\")[-1]
                        output['Variable'] = lines.split()[1]
                        output['Business_Meaning'] = ''
                        metadata.append(copy.deepcopy(output))

                    if len(lines.split()) >= 1:
                        if (lines.strip().upper().startswith("PUBLIC") or lines.strip().upper().startswith(
                                "PRIVATE") or lines.strip().upper().startswith("PROTECTED")) and (
                                not lines.lower().__contains__("sub")  and not lines.lower().__contains__("function") and
                                not lines.lower().__contains__("property")  and not lines.lower().__contains__("class")):
                            # print(lines)
                            if lines.strip().split()[1] == "Static" or lines.strip().split()[1] == "Const":
                                # print("with",lines)
                                output["File_name"] = filename.split("\\")[-1]
                                output['Variable'] = lines.split()[2]
                                output['Business_Meaning'] = ''
                                metadata.append(copy.deepcopy(output))
                            else:
                                print("without ",lines)
                                output["File_name"] = filename.split("\\")[-1]
                                output['Variable'] = lines.split()[1]
                                output['Business_Meaning'] = ''
                                metadata.append(copy.deepcopy(output))
        """******************************  Screen feild id s     """
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

    @staticmethod
    def get_files():
        filenames_list = []
        for filename1 in glob.glob(os.path.join(vb_path, '*.aspx.vb')):
            filenames_list.append(filename1)
        for filename2 in glob.glob(os.path.join(vb_component_path, '*.vb')):
            filenames_list.append(filename2)

        return filenames_list

    @staticmethod
    def Db_conn(db_name, col_name):
        conn = pymongo.MongoClient("localhost", 27017)
        return conn[db_name][col_name]

    @staticmethod
    def fetch_db_cursor_to_list(cursor):
        data_list = []
        for js_bre_data_iter in cursor:
            data_list.append(js_bre_data_iter)
        return data_list

    @staticmethod
    def remove_duplicates(list):
        res = []
        for i in list:
            if i not in res:
                res.append(i)
        return res

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









if __name__ == '__main__':
    glossary = Glossary()
    glossary.vb_var_capt('Vb_net1','glossary')
