# -*- coding: utf-8 -*-
"""
@author: KN00636678

JAVA component type

Dependencies: config file with
filepath, collectionname and dbname
which should be changed according to the user

"""
import os
import config
import copy
import json
import pandas as pd
import re

from pymongo import MongoClient
client = MongoClient('localhost', 27017)

filespath = config.filespath
dbname = config.dbname
collectionname = config.componenttypecn

modaldict = {"component_name" : "",
             "component_type" : "",
             "WebServlet"     : "",
             "application"    : ""}

foldernames = ["src\\com\\masterofproperty\\","WebContent"]

extensions = ['.java','.jsp','.js','.css']

def getallfiles(filespath,extensions):#function to return the file paths in the given directory with given extention
    filelist = []
    for root, dirs, files in os.walk(filespath):
        for file in files:
            if file.lower().endswith(tuple([item.lower() for item in extensions])):
                filelist.append(os.path.join(root, file))
    return filelist

def getapplication(filepath,foldernames):
    if filepath.lower().endswith(".java") and filepath.__contains__(foldernames[0]):
        return filepath.split(foldernames[0])[1].split("\\")[0].upper()
    elif filepath.__contains__(foldernames[1]):
        return foldernames[1].upper()
    else:
        return filepath.split("\\")[-2].upper()

def getcomponenttype(filepath,Lines):
    if filepath.lower().endswith(".jsp"):
        return "JAVA_SERVER_PAGE"
    elif filepath.lower().endswith(".css"):
        return "STYLE_SHEET"
    elif filepath.lower().endswith(".js"):
        return "JAVA_SCRIPT"
    elif filepath.lower().endswith(".java") and filepath.split("\\")[-1].split(".",1)[0].strip().endswith("DAO"):
        return "DATA_ACCESS_OBJECT"
    elif filepath.lower().endswith(".java"):
        for line in Lines:
            if line.strip().startswith("public interface"):
                return "INTERFACE"
                break
            elif line.strip().startswith("public class") and line.strip().__contains__("extends HttpServlet"):
                return "SERVLET"
                break
        else:
            return "JAVA_CLASS" 
    else:
        return filepath.split("\\")[-1].split(".",1)[1].upper()

def getwebservlet(Lines,ctype):
    if ctype=="SERVLET":
        for line in Lines:
            if line.strip().startswith("@WebServlet"):
                return re.findall('"([^"]*)"', line)[0]
    else:
        return None
    
def getallreports(filespath):
    output = []
    for filepath in getallfiles(filespath,extensions):
        Lines =  open(filepath).readlines()
        tempdict = copy.deepcopy(modaldict)
        tempdict["component_name"] = filepath.split("\\")[-1]
        tempdict["component_type"] = getcomponenttype(filepath,Lines)
        tempdict["WebServlet"] = getwebservlet(Lines,tempdict["component_type"])
        tempdict["application"] = getapplication(filepath,foldernames)
        output.append(copy.deepcopy(tempdict))
        
    return output

def dbinsertfunction(filespath,dbname,collectionname):
    col = client[dbname][collectionname]
    output = getallreports(filespath)    
    if output!=[]:   
        if col.count_documents({}) != 0 :
            col.drop()  
            print("Deleted the old",dbname,collectionname,"collection")
            
        col.insert_one({"type" : "metadata",
                        "headers" : ["component_name","component_type","application"]})        
        col.insert_many(output)
        print("Inserted the list of jsons of",dbname,collectionname)
    else:
        print("There are no jsons in the output to insert in the DB",dbname,collectionname)


        
if __name__ == '__main__':
    # output = getallreports(filespath)
    # if not os.path.exists("outputs//"):
    #     os.makedirs("outputs//")
    # json.dump(output , open('outputs\\component_type.json', 'w'), indent=4)
    # pd.DataFrame(output).to_excel("outputs\\component_type.xlsx", index=False)     
    dbinsertfunction(filespath,dbname,collectionname)
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        