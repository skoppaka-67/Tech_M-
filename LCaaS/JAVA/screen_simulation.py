"""

JAVA screen simulation

Dependencies: config file with
filepath, collectionname and dbname
which should be changed according to the user
component_type file has to run before running this,application, component type

"""
import os, copy, json
import config
from pymongo import MongoClient
import re
import pandas as pd

client = MongoClient('localhost', 27017)

dbname = config.dbname
collectionname = config.screensimcn
filespath = config.filespath

componentcollection = config.componenttypecn
col2 = client[dbname][componentcollection]

extensions=['.jsp','.java','.css','.js']


def getallfiles(filespath, extensions):  # function to return the file paths in the given directory with given extention
    filelist = []
    for root, dirs, files in os.walk(filespath):
        for file in files:
            if file.lower().endswith(tuple([item.lower() for item in extensions])):
                filelist.append(os.path.join(root, file))
    return filelist

def removejavalines(Lines):
    flag = False
    for index,line in enumerate(Lines):
        if "<%" in line and "%>" in line:
            Lines[index] = re.sub('<%.*?%>', '',line)
        if not "<%" in line and "%>" in line:
            Lines[index] = line.split("%>")[1]
            flag = False
        if flag:
            Lines[index] = ""            
        if "<%" in line and not "%>" in line:
            Lines[index] = line.split("<%")[0]
            flag = True            
    return Lines

def getallreports(filespath):
    output = []
    cursor = list(col2.find({'type': {"$ne": "metadata"}},{"component_name":1,"component_type":1,"application":1,"_id":0}))    
    for filepath in getallfiles(filespath, [".jsp"]):
        Lines = open(filepath).readlines()                                                    
        tempdict = {}
        tempdict["component_name"] = filepath.split("\\")[-1]#filename
        tempdict["component_type"] = [item["component_type"] for item in cursor if item["component_name"] == filepath.split("\\")[-1]][0]
        tempdict["application"]    = [item["application"]    for item in cursor if item["component_name"] == filepath.split("\\")[-1]][0]
        Lines = [line for line in Lines if line.strip()!=""]
        tempdict["codeString"]     = "".join(removejavalines(Lines))
        output.append(tempdict.copy())              
    return output


def dbinsertfunction(filespath, dbname, collectionname):
    # function to insert the list of jsons to respective db, collection
    col = client[dbname][collectionname]
    output = getallreports(filespath)
    if col.count_documents({}) != 0:
        col.drop()
        print("Deleted the old", dbname, collectionname, "collection")
    col.insert_one({"type": "metadata",
                    "headers": ["component_name", "component_type", "application","codeString"]})    
    if output != []:
        col.insert_many(output)
        print("Inserted the list of jsons of", dbname, collectionname)
    else:
        print("There are no jsons in the output to insert in the DB", dbname, collectionname)


if __name__ == '__main__':
    #output = show_code(filespath)
    # if not os.path.exists("outputs//"):
    #     os.makedirs("outputs//")
    # json.dump(output, open('outputs\\screen_simulation.json', 'w'), indent=4)
    # pd.DataFrame(output).to_excel("outputs\\screen_simulation.xlsx", index=False)
    dbinsertfunction(filespath, dbname, collectionname)


