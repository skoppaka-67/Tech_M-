import os,re
import copy
import sys
import glob
import json
import pandas as pd
from pymongo import MongoClient
# import config1

OUTPUT_DATA = []
file ={ 'D:\\BNSF\\POC\\NAT': '*.NAT','D:\\BNSF\\POC\\COPY' : '*.CPY'}
meatadata = []
FILE_LIST = []

# client = MongoClient(config1.database['mongo_endpoint_url'])
# db = client[config1.database['database_name']]
client = MongoClient('localhost', 27017)
db = client['BNSF_NAT']

db.cobol_output.remove()
d={}

for file_location,file_type in file.items():

    for filename in glob.glob(os.path.join(file_location, file_type)):
        OUTPUT_DATA.clear()

        #print(file_type)
        if file_type == '*.NAT':
            #print(filename)
            FILE_LIST.append(filename)
            #print(FILE_LIST)
            #print('List of ' + component + 'files to be processed', FILE_LIST)
            for eachFile in FILE_LIST:
                file = open(eachFile, 'r')
                god_string = ''
                for line in file.readlines():
                    if len(line) > 7: #empty lines check


                        if line[6] == '*' or line[6:].lstrip().startswith("/*"):
                            god_string= god_string + line.replace('\n', '<br>')
                            #print(god_string)
                            continue

        d = {'component_name': eachFile.split("\\")[-1], 'component_type': "NATURAL-PROGRAM",'application':'Unknown', 'codeString': god_string}

        meatadata.append(copy.deepcopy(d))
print(json.dumps(meatadata, indent=4))
db.cobol_output.insert_many(meatadata)
