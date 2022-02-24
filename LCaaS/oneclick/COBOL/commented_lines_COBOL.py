import os,re
import copy
import sys
import glob
import json,config
import pandas as pd
from pymongo import MongoClient
# import config1

OUTPUT_DATA = []
# file = shfile ={ 'D:\\POC\\BNSF\\COBOL\\': '*.cbl'}
file={config.COBOL_codebase_information['code_location']+'\\'+'COBOL' : '*.cbl'}
FILE_LIST = []

# client = MongoClient(config1.database['mongo_endpoint_url'])
# db = client[config1.database['database_name']]
# client = MongoClient('localhost', 27017)
# db = client['IMS_COBOL_NEW']
client = MongoClient(config.database_COBOL['hostname'], config.database_COBOL['port'])
db = client[config.database_COBOL['database_name']]

db.cobol_output.delete_many({})


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
        #print(json.dumps(OUTPUT_DATA, indent=4))
        db.cobol_output.insert_many(OUTPUT_DATA)


