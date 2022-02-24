import os,re
import copy
import sys
import glob
import json
import pandas as pd
from pymongo import MongoClient
import config1

OUTPUT_DATA = []
file = config1.shfile

FILE_LIST = []

# client = MongoClient(config1.database['mongo_endpoint_url'])
# db = client[config1.database['database_name']]
client = MongoClient('localhost', 27017)
db = client['as400']

db.cobol_output.remove()


for file_location,file_type in file.items():

    for filename in glob.glob(os.path.join(file_location, file_type)):
        OUTPUT_DATA.clear()

        #print(file_type)
        if file_type == '*.RPG':
            #print(filename)
            FILE_LIST.append(filename)
            #print(FILE_LIST)
            #print('List of ' + component + 'files to be processed', FILE_LIST)
            for eachFile in FILE_LIST:
                file = open(eachFile, 'r')
                god_string = ''
                for line in file.readlines():
                    if len(line) > 7: #empty lines check
                        line = line[6:]

                        if line[0] == '*' or line.strip().startswith("//"):
                            god_string= god_string + line.replace('\n', '<br>')
                            #print(god_string)
                            continue


        OUTPUT_DATA.append({'component_name': eachFile.strip(file_location).replace(" ","_").strip('.*'), 'component_type': file_type.strip("*."), 'codeString': god_string})
        print(json.dumps(OUTPUT_DATA, indent=4))
        db.cobol_output.insert_many(OUTPUT_DATA)


