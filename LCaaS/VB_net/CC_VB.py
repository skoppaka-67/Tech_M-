SCRIPT_VERSION = 'Cyclomatic Complexity for VB component'

import config,os,re,glob,csv
from pymongo import MongoClient

'''database operation '''
mongoclient = MongoClient('localhost',27017)
db = mongoclient['vb']

code_location =config.codebase_information['code_location']
lob_folder = config.codebase_information['GLOSSARY']['folder_name']
code_behind_folder = config.codebase_information['VB']['folder_name']
lob_path = code_location + "\\" + lob_folder
code_behind_path = code_location + "\\" + code_behind_folder


class Cyclo_child():

    def processor(self,final_level_foder,original_file,file_ext):
        print("Winning:",final_level_foder,original_file)

        for filesss in glob.glob(os.path.join(final_level_foder,original_file)):
            if_counts = 0
            case_count = 0
            for_count = 0
            do_count = 0
            CCData = []

            Metadata =[]
            select_flag = False
            with open(filesss, 'r') as input_file:
                r = 0
                for lines in input_file.readlines():
                    if lines.lstrip().startswith("'"):
                        continue

                    if re.search('.*If\s.*',lines):
                        if not re.search('.*End If.*',lines):
                            if_counts = if_counts + 1
                            continue

                    if select_flag:
                        if re.search('.*End Select.*',lines,re.IGNORECASE):
                            select_flag = False
                            continue
                        if re.search('.*Case.*',lines,re.IGNORECASE):
                            case_count = case_count + 1
                            continue

                    if re.search('.*Select Case.*',lines,re.IGNORECASE):
                        select_flag = True
                        continue

                    if re.search('.*For\s.*',lines):
                        for_count = for_count + 1
                        continue

                    if re.search('.*Do\s.*',lines):
                        do_count = do_count + 1
                        continue



            r = if_counts+case_count+for_count
            CCData.append(r+1)
            res = int("".join(map(str, CCData)))
            Metadata.append({"component_name":original_file,"component_type":file_ext.casefold(),"cyclomatic_complexity":res})
            r = 0
            return Metadata

class Cyclo_parent(Cyclo_child):
    def __init__(self,code_location,lob_path,code_behind_path):
            self.code_location = code_location
            self.lob_path = lob_path
            self.code_behind_path = code_behind_path

    def code_behind_func(self,code_behind_path):
        print(code_behind_path)
        filename = os.listdir(code_behind_path)
        print("C:",filename)
        for file in (filename):
            original_file = file
            print("Original:", original_file)
            file = file.split(".")
            file_ext = file[1:]
            if len(file_ext) == 2:
                file_ext = (".".join(file_ext))

            if file_ext == "ASPX.VB" or file_ext == "aspx.vb":
                Metadata = self.processor(code_behind_path, original_file, file_ext)
                db.master_inventory_report.insert_many(Metadata)


    def lob_func(self,lob_path):
        folders = os.listdir(lob_path)
        for folder in folders:
            next_level_folder = os.path.join(lob_path, folder)
            next_folder = os.listdir(next_level_folder)
            # print(next_folder)
            business = "BusinessRules"
            shared = "Shared"
            for next_iter in next_folder:
                if re.search(business, next_iter, re.IGNORECASE) or re.search(shared, next_iter, re.IGNORECASE):
                    final_level_folder = os.path.join(next_level_folder, next_iter)
                    # print("Final:",final_level_folder)
                    filename = os.listdir(final_level_folder)
                    print("In:",filename)
                    self.main_logic(filename,final_level_folder)

                    # return filename
                    # main_logic



    def main_logic(self,filename,final_level_folder):
            print("Out:",filename)
            for file in (filename):
                original_file = file
                print("Original:", original_file)
                file = file.split(".")
                file_ext = file[1]
                if file_ext == "VB" or file_ext == "vb":
                    Metadata = self.processor(final_level_folder,original_file,file_ext)
                    db.master_inventory_report.insert_many(Metadata)

                    # for file in (filename):
                    #     print("File:",file)



#db.master_inventory_report.remove()
file = Cyclo_parent(code_location,lob_path,code_behind_path)
print(file.code_location,file.lob_path,file.code_behind_path)
file.lob_func(lob_path)
file.code_behind_func(code_behind_path)

out_data = []
metadata_1 = db.master_inventory_report.find({})
for screen_data_1 in metadata_1:
      screen_data_1.pop("_id")
#     screen_data_1.update({"rule_statement": " ".join(screen_data_1["rule_statement"])})
      out_data.append(screen_data_1)
