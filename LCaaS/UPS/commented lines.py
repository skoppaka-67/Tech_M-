import os,re
import copy
import sys
import glob
import json
import pandas as pd
from pymongo import MongoClient
# import config1

OUTPUT_DATA = []
file = shfile ={ 'D:\\WORK\\IMS\\COBOL': '*.cbl',}

FILE_LIST = []

# client = MongoClient(config1.database['mongo_endpoint_url'])
# db = client[config1.database['database_name']]
client = MongoClient('localhost', 27017)
db = client['IMS']

db.cobol_output.remove()


for file_location,file_type in file.items():

    for filename in glob.glob(os.path.join(file_location, file_type)):
        OUTPUT_DATA.clear()

        #print(file_type)
        if file_type == '*.cbl':
            #print(filename)
            FILE_LIST.append(filename)
            #print(FILE_LIST)
            #print('List of ' + component + 'files to be processed', FILE_LIST)
            for eachFile in FILE_LIST:
                file = open(eachFile, 'r')
                god_string = ''
                for line in file.readlines():
                    line = line[6:]
                    if len(line) > 1: #empty lines check


                        if line[0] == '*' or line.strip().startswith("//"):
                            god_string= god_string + line.replace('\n', '<br>').replace("<S>","< S >")
                            #print(god_string)
                            continue

        # eachFile.split("\\")
        OUTPUT_DATA.append({'component_name': eachFile.split("\\")[-1], 'component_type': "COBOL", 'codeString': god_string})
        print(god_string)
        db.cobol_output.insert_many(OUTPUT_DATA)





