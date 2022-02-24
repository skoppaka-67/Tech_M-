"""
JAVA Glossary Report
Dependencies: config file with
filepath, collection name and dbname
which should be changed according to the user
*** component_type file has to run before running this, so that we can fetch application name and component type from that ***
"""

import os, copy, json
import config
from pymongo import MongoClient
import pandas as pd
import openpyxl

client = MongoClient('localhost', 27017)

dbname = config.dbname
collectionname = config.glossarycn
filespath = config.filespath
extentions = [".jsp", ".java", ".css", ".js"]


def getallfiles(filespath, extentions):  # function to return the file paths in the given directory with given extention
    filelist = []
    for root, dirs, files in os.walk(filespath):
        for file in files:
            if file.lower().endswith(tuple([item.lower() for item in extentions])):
                filelist.append(os.path.join(root, file))
    return filelist


def get_screenfield_data():
    """
    1.In this function we are getting screenfield data from database
    2.If screenfield is not empty then we are creating json for glossary report
    :return: returns glossary report json's for non empty screen fields
    """
    col = client[dbname]['screenfields']
    validation_dict = {}
    output = []
    screenfields_list = []
    screenfileds_data = list(col.find({'type': {"$ne": "metadata"}},
                                      {'_id': 0, 'filename': 1, 'screenfield': 1}))

    return screenfileds_data


def glossary(filespath, extentions):
    """
    This function is to fetch variables in java files
    :return:
    """
    files = getallfiles(filespath, extentions)
    screenfield = get_screenfield_data()
    METADATA = []
    variable_name = ''

    for file in files:
        if file.endswith('.java'):
            f = open(file, 'r')
            for line in f.readlines():
                # if line.__contains__('new') and line.__contains__('(') and line.__contains__(')') and line.__contains__(
                #         '='):
                if all(x in line for x in ['new', '(', ')', '=']):
                    #print(line)
                    # print(line)
                    variable_name = line.split('=')[0].split()[-1]
                    #print(variable_name)
                    # print(variable_name)
                    modeldict = {
                        "File_name": file.split('\\')[-1],
                        "Variable": variable_name,
                        "Business_Meaning": ""
                    }
                    METADATA.append(copy.deepcopy(modeldict))
                    modeldict.clear()
                if line.__contains__('=') and line.__contains__(';')  and line.__contains__('(') and not line.__contains__('new'):
                    variable_name=line.split('=')[0].split()[-1]
                    # print(variable_name)
                    modeldict = {
                        "File_name": file.split('\\')[-1],
                        "Variable": variable_name,
                        "Business_Meaning": ""
                    }
                    METADATA.append(copy.deepcopy(modeldict))
                    modeldict.clear()
                if line.strip().startswith('int') or line.strip().startswith('float') or line.strip().startswith(
                        'boolean') or line.strip().startswith('String'):
                    # print(line)
                    if line.strip().endswith(';'):
                        line = line.replace(';', '', 1)

                        # print(line)
                        variable_name = line.split('=')[0].split()[-1]
                        # print(variable_name)
                        modeldict = {
                            "File_name": file.split('\\')[-1],
                            "Variable": variable_name,
                            "Business_Meaning": ""
                        }
                        METADATA.append(copy.deepcopy(modeldict))
                        modeldict.clear()
                # if line.strip().startswith('static') or line.strip().startswith('private') or line.strip().startswith(
                #         'public'):
                if line.strip().startswith(('private', 'public', 'static')):

                    if line.strip().endswith(';') and not (line.__contains__('=') or line.__contains__('(')):
                        # print(line,file)
                        line = line.replace(';', '', 1)
                        # print(line)
                        variable_list = line.split()
                        # print(variable_list)
                        for i in variable_list[2:]:
                            variable_list = i.split(',')
                            # print(variable_list)
                            for variable in variable_list:
                                if variable != '':
                                    # print(variable)
                                    modeldict = {
                                        "File_name": file.split('\\')[-1],
                                        "Variable": variable,
                                        "Business_Meaning": ""
                                    }
                                    METADATA.append(copy.deepcopy(modeldict))
                                    modeldict.clear()

                        # if line.__contains__(','):
                        #     line = line.replace(';', '', 1)
                        #     #print(line)
                        #     variable_list = line.split()
                        #     #print(variable_list)
                        #     for i in variable_list[2:]:
                        #         variable_list = i.split(',')
                        #         # print(variable_list)
                        #         for variable in variable_list:
                        #             if variable != '':
                        #                 #print(variable)
                        #                 modeldict = {
                        #                     "File_name": file.split('\\')[-1],
                        #                     "Variable": variable,
                        #                     "Business_Meaning": ""
                        #                 }
                        #                 METADATA.append(copy.deepcopy(modeldict))
                        #                 modeldict.clear()

                if line.strip().startswith('public') or line.strip().startswith('private') or line.strip().startswith(
                        'protected') or line.strip().startswith('static'):
                    if line.strip().endswith(';') and line.__contains__('='):
                        line = line.replace(';', '', 1)
                        # print(line)
                        variable_name = line.split("=")[0].split("private")[-1]
                        variable_name = variable_name.split()[-1]
                        # print(variable_name)

                        modeldict = {
                            "File_name": file.split('\\')[-1],
                            "Variable": variable_name,
                            "Business_Meaning": ""
                        }
                        METADATA.append(copy.deepcopy(modeldict))
                        modeldict.clear()
                    if line.strip().startswith('public') or line.strip().startswith(
                            'private') or line.strip().startswith(
                        'protected'):
                        if line.strip().endswith(';') and line.__contains__('(') and line.__contains__(')'):
                            # print(line)
                            variables = line.split('(')[1].split(')')[0]
                            # print(variable_name)
                            if variables.strip() != '':

                                variables = variables.split(',')
                                for var in variables:
                                    variable_name = var.split()[-1]
                                    if variable_name.strip() != '':
                                        # print(variable_name)

                                        # variable_name = line.split(')')[0].split()[-1]
                                        modeldict = {
                                            "File_name": file.split('\\')[-1],
                                            "Variable": variable_name,
                                            "Business_Meaning": ""
                                        }
                                        METADATA.append(copy.deepcopy(modeldict))
                                        modeldict.clear()
                        # print(variable_name)
                        # print(line)
        for record in screenfield:
            # print(record)
            # print(file.split('\\')[-1])
            if record['screenfield'] != '':
                if record['filename'] == file.split('\\')[-1]:
                    # print(record)
                    modeldict = {
                        "File_name": file.split('\\')[-1],
                        "Variable": record['screenfield'],
                        "Business_Meaning": ""
                    }
                    METADATA.append(copy.deepcopy(modeldict))
                    modeldict.clear()

    #print(json.dumps(METADATA,indent=4))
    metadata = []
    for doc in METADATA:
        if doc not in metadata:
            metadata.append(doc)
    #print(json.dumps(metadata, indent=4))
    return metadata


# def glossary_equals(filespath,extensions):
#     files=getallfiles(filespath,extensions)
#     METADATA=[]
#     for file in files:
#         if file.endswith('.java'):
#             f=open(file,'r')
#             for line in f.readlines():
#                 if line.strip().startswith('int') and line.__contains__(';'):
#                     #print(line)
#                     pass
#                 if line.strip().startswith('public') or line.strip().startswith('private') or line.strip().startswith('protected') or line.strip().startswith('static'):
#                     if line.strip().endswith(';') and line.__contains__('='):
#                         #print(line)
#                         variable_name=line.split("=")[0].split("private")[-1]
#                         variable_name=variable_name.split()[-1]
#                         #print(variable_name)
#
#
#                         modeldict = {
#                             "File_name": file.split('\\')[-1],
#                             "Variable":variable_name,
#                             "Business_Meaning": ""
#                         }
#                         METADATA.append(copy.deepcopy(modeldict))
#     #print(json.dumps(METADATA,indent=4))
#     return METADATA
def variables_count():
    """
    This function is to update number of variables in master inventory report
    """
    master_col=client[dbname]['master_inventory_report']
    master_inventory_data = list(master_col.find({'type': {"$ne": "metadata"}},
                                      {'_id': 0,'component_name':1}))
    variable_jsons=glossary(filespath,extentions)
    files=getallfiles(filespath,['.java'])
    variables_count=[]
    for file in files:
        for record in variable_jsons:
            if record['File_name']==file.split('\\')[-1]:
                variables_count.append(record)
        count=len(variables_count)
        if count!=0:
            for item in master_inventory_data:
                if item['component_name']==file.split('\\')[-1]:
                    data=({"component_name": file.split('\\')[-1]},
                    {"$set": {"no_of_variables": count}})
                    #print(file.split('\\')[-1], count)
                    variables_count.clear()
                    try:
                        master_col.update_one(*data)
                    except Exception as e:
                        exc_type, exc_obj, exc_tb = sys.exc_info()
                        fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
                        print(exc_type, fname, exc_tb.tb_lineno)


def dbinsertfunction(dbname, collectionname, filespath):
    """
    this function is to update database by calling show code and getfiles functions
    :param dbname: database name from config file
    :param collectionname: collectionname from config file
    """
    output = glossary(filespath, extentions)
    col = client[dbname][collectionname]
    if output != []:
        if col.count_documents({}) != 0:
            col.drop()
            print("Deleted the old", dbname, collectionname, "collection")

        col.insert_one({"type": "metadata",
                        "headers": [
                            "File_name",
                            "Variable",
                            "Business_Meaning"

                        ]})
        col.insert_many(output)
        print("Inserted the list of jsons of", dbname, collectionname)

    else:
        print("There are no jsons in the output to insert in the DB", dbname, collectionname)


if __name__ == '__main__':
    # output = glossary(filespath, extentions)
    dbinsertfunction(dbname, collectionname, filespath)
    variables_count()
    # pd.DataFrame(output).to_excel("outputs\\glossary.xlsx", index=False)
    # json.dump(output, open('outputs\\glossary.json', 'w'), indent=4)