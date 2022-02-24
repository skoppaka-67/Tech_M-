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

client = MongoClient(config1.database['mongo_endpoint_url'])
db = client[config1.database['database_name']]
# client = MongoClient('localhost', 27017)
# db = client['as400']

db.codebase.remove()


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

                        if line[0] == '*':

                            # it is a comment line, modify the string
                            line = '<span style=\"color:green\">' + line + '</span>'

                        if line.casefold().__contains__("begsr"):
                           # line = '<span id="canvasScroll">'  +line.strip(' ')+  '</span>'
                            line = ' '.join(line.split())+'<br>'

                            god_string = god_string + line.casefold().replace('\n', '<br>')
                            #print(god_string)
                            continue
                        else:

                            god_string = god_string + line.replace('\n', '<br>')
                            #print(type(god_string))

            OUTPUT_DATA.append({'component_name': eachFile.strip(file_location).replace(" ","_")+file_type.strip('.*'), 'component_type': file_type.strip("*."), 'codeString': god_string})
            print(json.dumps(OUTPUT_DATA[0], indent=4))
            db.codebase.insert_many(OUTPUT_DATA)

        if file_type == '*.CL':
            FILE_LIST.append(filename)
            for eachFile in FILE_LIST:
                file = open(eachFile, 'r')
                god_string = ''
                for line in file.readlines():
                    DATA_LIST = line.split()
                    if len(DATA_LIST) > 1:

                        if DATA_LIST[0].__contains__('/*') and DATA_LIST[-1].__contains__('*/'):
                            # it is a comment line, modify the string
                            line = '<span style=\"color:green\">' + line + '</span>'
                            god_string = god_string + line.casefold().replace('\n', '<br>')
                            # print(god_string)
                            continue
                        else:

                            god_string = god_string + line.replace('\n', '<br>')
                            #print(type(god_string))

            OUTPUT_DATA.append(
                {'component_name': eachFile.strip(file_location).replace(" ", "_")+file_type.strip(".*"), 'component_type': file_type.strip(".*"),
                 'codeString': god_string})
            print(json.dumps(OUTPUT_DATA[0], indent=4))
            db.codebase.insert_many(OUTPUT_DATA)

        if file_type == '*.DSPF':
            FILE_LIST.append(filename)
            for eachFile in FILE_LIST:
                file = open(eachFile, 'r')
                god_string = ''
                for line in file.readlines():
                    # DATA_LIST = line.split()
                    if len(DATA_LIST) > 1:

                        if line[6]=="*":
                            # it is a comment line, modify the string
                            line = '<span style=\"color:green\">' + line + '</span>'
                            god_string = god_string + line.casefold().replace('\n', '<br>')
                            # print(god_string)
                            continue
                        else:

                            god_string = god_string + line.replace('\n', '<br>')
                            #print(type(god_string))

            OUTPUT_DATA.append(
                {'component_name': eachFile.strip(file_location).replace(" ", "_")+file_type.strip(".*"), 'component_type': file_type.strip(".*"),
                 'codeString': god_string})
            print(json.dumps(OUTPUT_DATA[0], indent=4))
            db.codebase.insert_many(OUTPUT_DATA)




