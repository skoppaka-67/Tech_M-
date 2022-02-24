import os,re
import copy
import sys
import glob
import json
import pandas as pd
from pymongo import MongoClient
# import config1

OUTPUT_DATA = []
file = shfile ={ 'D:\\CRST_FULL\\COBOL\\': '*.cbl',}
god_flag = False
FILE_LIST = []

# client = MongoClient(config1.database['mongo_endpoint_url'])
# db = client[config1.database['database_name']]
client = MongoClient('localhost', 27017)
db = client['CRST_FULLV1']

db.new_cobol_output.remove()


for file_location,file_type in file.items():

    for filename in glob.glob(os.path.join(file_location, file_type)):
        OUTPUT_DATA.clear()

        #print(file_type)
        if file_type == '*.cbl':
            print(filename)
            FILE_LIST.append(filename)
            #print(FILE_LIST)
            #print('List of ' + component + 'files to be processed', FILE_LIST)
            for eachFile in FILE_LIST:
                file = open(eachFile, 'r')
                god_string = ''
                for line in file.readlines():
                    line = line[6:72]
                    if len(line) > 1: #empty lines check


                        if line.__contains__("DATA DIVISION."):
                           # print(line)
                           god_flag = False
                           break

                        if god_flag:
                            if line[0] == '*' or line.strip().startswith("//"):
                                # print(line)
                                god_string = god_string + line.strip("*").replace('\n', '<br>').replace("<S>", "< S >") + '<br>'
                                continue
                            else:
                                continue
                        if line[0] == '*' or line.strip().startswith("//"):
                            # print(line)
                            god_string= god_string + line.strip("*").replace('\n', '<br>').replace("<S>","< S >") + '<br>'
                            god_flag = True
                            #print(god_string)
                            continue

        # eachFile.split("\\")
        OUTPUT_DATA.append({'component_name': eachFile.split("\\")[-1], 'component_type': "COBOL", 'codeString': god_string})
        print(god_string)
        db.new_cobol_output.insert_many(OUTPUT_DATA)

