""""
JAVA SHOW CODE REPORT
Dependencies: config file with
filepath, collection name and dbname
which should be changed according to the user
"""
import os, copy, json
import config
from pymongo import MongoClient
import pandas as pd

client = MongoClient('localhost', 27017)

dbname = config.dbname
collectionname = config.showcodecn
filespath = config.filespath
extentions = [".jsp", ".java", ".css", ".js"]

def getallfiles(filespath,extensions):#function to return the file paths in the given directory with given extensions
    filelist = []
    for root, dirs, files in os.walk(filespath):
        for file in files:
            if file.lower().endswith(tuple([item.lower() for item in extensions])):
                filelist.append(os.path.join(root, file))
    return filelist

def getExtensionType(file):
    colname=config.componenttypecn
    col = client[dbname][colname]
    #file=file.split('\\')[-1]
    component_type=list(col.find({"component_name" : file.split('\\')[-1]},{'_id':0}))
    component_type=component_type[0]['component_type']
    return component_type

def show_code(filespath):
    """
    this function is to fetch all the lines from java and jsp files and return a string with <br> tag attached after each line
    :param filespath: this is to call getfiles function to create list of java and jsp files
    :return: we are returning metadata, which contains component name as file name, component type as file extension, cosestring as string we are creating.
    """
    files = getallfiles(filespath,extentions)
    # print(file)
    storage = []
    output = {}
    METADATA = []
    filename = ''
    for filename in files:
        f = open(filename, 'r')
        Lines = f.readlines()
        Lines = [line for line in Lines if line.strip()]
        code_string = '<br>'.join(Lines)

        output['component_name'] = filename.split("\\")[-1]
        output['component_type'] = getExtensionType(filename)
        output['codeString'] = code_string
        METADATA.append(copy.deepcopy(output))
        f.close()

    return METADATA


def dbinsertfunction(dbname, collectionname):
    """
    this function is to update database by calling show code and getfiles functions
    :param dbname: database name from config file
    :param collectionname: collectionname from config file
    """
    output = show_code(filespath)
   
    # print(output)
    col = client[dbname][collectionname]
    if output != []:
        if col.count_documents({}) != 0:
            col.drop()
            print("Deleted the old", dbname, collectionname, "collection")

        col.insert_one({"type": "metadata",
                        "headers": [
                            ""
                            "component_name",
                            "component_type",
                            "codeString"

                        ]})
        col.insert_many(output)
        print("Inserted the list of jsons of", dbname, collectionname)

    else:
        print("There are no jsons in the output to insert in the DB", dbname, collectionname)


if __name__ == '__main__':
    #output = show_code(filespath)
    dbinsertfunction(dbname, collectionname)
    # if not os.path.exists("outputs//"):
    #     os.makedirs("outputs//")
    # json.dump(output, open('outputs\\show_code.json', 'w'), indent=4)
    # pd.DataFrame(output).to_excel("outputs\\show_code.xlsx", index=False)


