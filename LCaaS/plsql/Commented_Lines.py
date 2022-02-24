import os,re
import copy
import sys
import glob
import json
import pandas as pd
from pymongo import MongoClient
import plsql_config

OUTPUT_DATA = []
file = plsql_config.file

FILE_LIST = []


mongoClient = MongoClient('localhost', 27017)
db = mongoClient['plsql']

db.cobol_output.remove()

for file_location,file_type in file.items():

    for filename in glob.glob(os.path.join(file_location, file_type)):
        OUTPUT_DATA.clear()
        comment_flag = False
        #print(file_type)
        if file_type == '*.pkb' or file_type == '*.pks' or file_type == '*.prc' or file_type == '*.fnc' or file_type == '*.trg' :
            #print(filename)
            FILE_LIST.append(filename)
            #print(FILE_LIST)
            #print('List of ' + component + 'files to be processed', FILE_LIST)
            for eachFile in FILE_LIST:
                file = open(eachFile, 'r')
                god_string = ''
                for line in file.readlines():

                    if line.strip().endswith("*/"):
                        # line = '<span style=\"color:green\">' + line + '</span>'
                        god_string = god_string + line.casefold().replace('\n', '<br>')
                        comment_flag = False
                    if comment_flag:
                        # line = '<span style=\"color:green\">' + line + '</span>'
                        god_string = god_string + line.casefold().replace('\n', '<br>')
                        continue
                    if line.strip().startswith("/*"):
                        # line = '<span style=\"color:green\">' + line + '</span>'
                        god_string = god_string + line.casefold().replace('\n', '<br>')
                        comment_flag = True
                        if line.strip().endswith("*/"):
                            comment_flag = False


                    if line.strip().startswith("--"):

                        # line = '<span style=\"color:green\">' + line + '</span>'
                        god_string = god_string + line.casefold().replace('\n', '<br>')



            OUTPUT_DATA.append({'component_name': eachFile.strip(file_location).replace(" ","_").split(".")[0], 'component_type': file_type.replace("pks","Package Specification").replace("pkb","Package Body").replace("prc","Procedure").replace("fnc","Function").replace("trg","Trigger").strip(".*"), 'codeString': god_string})
            print(json.dumps(OUTPUT_DATA[0], indent=4))
            db.cobol_output.insert_many(OUTPUT_DATA)
        #
        # if file_type == '*.CL':
        #     FILE_LIST.append(filename)
        #     for eachFile in FILE_LIST:
        #         file = open(eachFile, 'r')
        #         god_string = ''
        #         for line in file.readlines():
        #             DATA_LIST = line.split()
        #             if len(DATA_LIST) > 1:
        #
        #                 if DATA_LIST[0].__contains__('/*') and DATA_LIST[-1].__contains__('*/'):
        #                     # it is a comment line, modify the string
        #                     line = '<span style=\"color:green\">' + line + '</span>'
        #                     god_string = god_string + line.casefold().replace('\n', '<br>')
        #                     # print(god_string)
        #                     continue
        #                 else:
        #
        #                     god_string = god_string + line.replace('\n', '<br>')
        #                     #print(type(god_string))
        #
        #     OUTPUT_DATA.append(
        #         {'component_name': eachFile.strip(file_location).replace(" ", "_")+file_type.strip(".*"), 'component_type': file_type.strip(".*"),
        #          'codeString': god_string})
        #     print(json.dumps(OUTPUT_DATA[0], indent=4))
        #     db.codebase.insert_many(OUTPUT_DATA)



