import copy,json

from pymongo import MongoClient
import pytz
import Vb_Parsing.config as config
import Vb_Parsing.Database as DB
import Vb_Parsing.Utility as util

vb_path = config.vb_path
vb_component_path = config.vb_component_path

SCRIPT_VERSION = "Keyword DB load"
time_zone = 'Asia/Calcutta'
tz = pytz.timezone(time_zone)
mongoClient = MongoClient('localhost', 27017)

metadata = []
files = []

class Glossary:

    def vb_var_capt(self):


        for filename in util.PreProcessing.get_files():

            with open(filename, encoding="utf8") as vb_file:
                output = {"File_name": "",
                          "Variable": "",
                          "Business_Meaning": ""
                          }
                for lines in vb_file.readlines():
                    if lines.strip().upper().startswith("DIM"):

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
                                # print("without ",lines)
                                output["File_name"] = filename.split("\\")[-1]
                                output['Variable'] = lines.split()[1]
                                output['Business_Meaning'] = ''
                                metadata.append(copy.deepcopy(output))

        """******************************  Screen feild id s     *********************************  """
        for file in util.PreProcessing.get_files():
            if file.endswith('.aspx'):
                files.append(file)

        for paths in files:
            with open(paths, encoding="utf8") as openFile:
                # print(paths)
                Lines = openFile.readlines()
                for line in Lines:
                    if "ID=" in line:
                        ids = line.split("ID=")
                        Variable = ids[1].split()[0].replace('"', '')
                        # Variable = Variable.replace('"', '')

                        tempdict = {}
                        tempdict["File_name"] = paths.split("\\")[-1]
                        tempdict["Variable"] = Variable
                        tempdict["Business_Meaning"] = ""
                        # print(tempdict)
                        metadata.append(tempdict.copy())
                        tempdict.clear()

if __name__ == '__main__':
    glossary = Glossary()
    glossary.vb_var_capt()

    print(json.dumps(metadata,indent=4))
    print(len(metadata))

    db = DB.Database()
    db.db_delete(db_name="vb6", col_name="glossary")
    db.db_update(db_name="vb6", col_name="glossary", Metadata=metadata)
