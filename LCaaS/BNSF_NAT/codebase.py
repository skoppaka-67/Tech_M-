import os,re
import copy
import sys
import glob
import json
import pandas as pd
from pymongo import MongoClient

shfile ={ 'D:\\BNSF\\POC\\NAT': '*.NAT',"D:\\BNSF\\POC\\MAP":'*.MAP','D:\\BNSF\\POC\\PRM':'*.PRM',"D:\\BNSF\\POC\\DDM":'*.DDM','D:\\BNSF\\POC\\LDA':'*.LDA'}
file = shfile

FILE_LIST = []

FILE_LIST1 = []

client = MongoClient('localhost', 27017)
db = client['BNSF_NAT']

db.codebase.remove()

OUTPUT_DATA =[]
for file_location,file_type in file.items():

    for filename in glob.glob(os.path.join(file_location, file_type)):
        OUTPUT_DATA.clear()

        print(file_type)
        if file_type == '*.NAT':
            #print(filename)
            FILE_LIST.append(filename)
            #print(FILE_LIST)
            #print('List of ' + component + 'files to be processed', FILE_LIST)
            for eachFile in FILE_LIST:
                file = open(eachFile, 'r')
                god_string = ''
                for line in file.readlines():
                    if len(line) > 5: #empty lines check
                        # line = line[6:]

                        line = line.replace("<S>", "< S >")
                        line = line.replace("<I>", "< I >")

                        if line[6] == '*'  or line[6:].lstrip().startswith("/*"):

                            # it is a comment line, modify the string
                            line = '<span style=\"color:green\">' + line + '</span>'



                        if line.__contains__("DEFINE"):

                           if re.search("DEFINE DATA", line) or re.search("REDEFINE", line) or re.search("END-DEFINE",line):
                                    pass


                           else:
                                line =   line.strip(' ')


                                line = ' '.join(line.split())+'<br>'

                                god_string = god_string + line.replace('\n', '<br>')
                                #print(god_string)
                                continue
                        else:

                            god_string = god_string + line.replace('\n', '<br>')
                            #print(type(god_string))

            OUTPUT_DATA.append({'component_name': eachFile.split("\\")[-1], 'component_type': "Natural-Program", 'codeString': god_string})
           # print(json.dumps(OUTPUT_DATA[0], indent=4))
            db.codebase.insert_many(OUTPUT_DATA)
            OUTPUT_DATA.clear()

        if file_type == "*.MAP":
            FILE_LIST.append(filename)
            # print(FILE_LIST)
            # print('List of ' + component + 'files to be processed', FILE_LIST)
            for eachFile in FILE_LIST:
                file = open(eachFile, 'r')
                god_string = ''
                for line in file.readlines():
                    if len(line) > 7:  # empty lines check
                        # line = line[8:]

                        line = line.replace("<S>", "< S >")
                        line = line.replace("<I>", "< I >")

                        if line[8] == '*':
                            # it is a comment line, modify the string
                            line = '<span style=\"color:green\">' + line + '</span>'



                            god_string = god_string + line.replace('\n', '<br>')
                            # print(type(god_string))
                        else:

                                        god_string = god_string + line.replace('\n', '<br>')
                                        #print(type(god_string))
            OUTPUT_DATA.append(
                    {'component_name': eachFile.split("\\")[-1], 'component_type': "MAP",
                     'codeString': god_string})
                # print(json.dumps(OUTPUT_DATA[0], indent=4))
            db.codebase.insert_many(OUTPUT_DATA)
            print("update success")
            OUTPUT_DATA.clear()
        if file_type == "*.PRM":
                FILE_LIST.append(filename)
                # print(FILE_LIST)
                # print('List of ' + component + 'files to be processed', FILE_LIST)
                for eachFile in FILE_LIST:
                    file = open(eachFile, 'r')
                    god_string = ''
                    for line in file.readlines():
                        if len(line) > 7:  # empty lines check
                            # line = line[8:]

                            line = line.replace("<S>", "< S >")
                            line = line.replace("<I>", "< I >")

                            if line.__contains__('**C')  or line.__contains__('/*C')  :
                                # it is a comment line, modify the string
                                line = '<span style=\"color:green\">' + line + '</span>'

                                god_string = god_string + line.replace('\n', '<br>')
                                # print(type(god_string))
                            else:

                                god_string = god_string + line.replace('\n', '<br>')
                                # print(type(god_string))

                OUTPUT_DATA.append(
                    {'component_name': eachFile.split("\\")[-1].replace("PRM","PDA"), 'component_type': "PDA",
                     'codeString': god_string})
                # print(json.dumps(OUTPUT_DATA[0], indent=4))
                db.codebase.insert_many(OUTPUT_DATA)
                print("update success")
                OUTPUT_DATA.clear()

        if file_type == "*.LDA":
                FILE_LIST.append(filename)
                # print(FILE_LIST)
                # print('List of ' + component + 'files to be processed', FILE_LIST)
                for eachFile in FILE_LIST:
                    file = open(eachFile, 'r')
                    god_string = ''
                    for line in file.readlines():
                        if len(line) > 7:  # empty lines check
                            # line = line[8:]

                            line = line.replace("<S>", "< S >")
                            line = line.replace("<I>", "< I >")

                            if line.__contains__('**C')  or line.__contains__('/*C')  :
                                # it is a comment line, modify the string
                                line = '<span style=\"color:green\">' + line + '</span>'

                                god_string = god_string + line.replace('\n', '<br>')
                                # print(type(god_string))
                            else:

                                god_string = god_string + line.replace('\n', '<br>')
                                # print(type(god_string))

                OUTPUT_DATA.append(
                    {'component_name': eachFile.split("\\")[-1], 'component_type': "LDA",
                     'codeString': god_string})
                # print(json.dumps(OUTPUT_DATA[0], indent=4))
                db.codebase.insert_many(OUTPUT_DATA)
                print("update success")
                OUTPUT_DATA.clear()

        if file_type == "*.DDM":
                FILE_LIST.append(filename)
                # print(FILE_LIST)
                # print('List of ' + component + 'files to be processed', FILE_LIST)
                for eachFile in FILE_LIST:
                    file = open(eachFile, 'r')
                    god_string = ''
                    for line in file.readlines():
                        if len(line) > 7:  # empty lines check
                            # line = line[8:]

                            line = line.replace("<S>", "< S >")
                            line = line.replace("<I>", "< I >")

                            if line.__contains__('**C')  or line.__contains__('/*C')  :
                                # it is a comment line, modify the string
                                line = '<span style=\"color:green\">' + line + '</span>'

                                god_string = god_string + line.replace('\n', '<br>')
                                # print(type(god_string))
                            else:

                                god_string = god_string + line.replace('\n', '<br>')
                                # print(type(god_string))

                OUTPUT_DATA.append(
                    {'component_name': eachFile.split("\\")[-1], 'component_type': "DDM",
                     'codeString': god_string})
                # print(json.dumps(OUTPUT_DATA[0], indent=4))
                db.codebase.insert_many(OUTPUT_DATA)
                print("update success")
                OUTPUT_DATA.clear()
##############################################################################################################


