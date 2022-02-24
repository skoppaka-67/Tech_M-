# -*- coding: utf-8 -*-
"""
@author: KN00636678

JAVA Cross reference report

Dependencies: 
config file with filepath, collectionname and dbname
componenttype collection name
Run the componenttype.py file before using using report

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
collectionname = config.crossreferencecn
componentcollection = config.componenttypecn
col2 = client[dbname][componentcollection]

foldernames = ["src\\com\\masterofproperty\\","WebContent"]
remainingfilepath = filespath + "\\Property_codedump\\src\\"

modaldict = {"filename" : "",
             "component_name" : "",
             "component_type" : "",
             "calling_app_name" : "",
             "called_name" : "",
             "called_type" : "",
             "called_app_name" : "",
             "dd_name" : "",
             "access_mode" : "",
             "step_name" : "",
             "Comments" : ""}

extensions = ['.java','.jsp','.js','.css']

def getallfiles(filespath,extensions):#function to return the file paths in the given directory with given extention
    filelist = []
    for root, dirs, files in os.walk(filespath):
        for file in files:
            if file.lower().endswith(tuple([item.lower() for item in extensions])):
                filelist.append(os.path.join(root, file))
    return filelist


def getjavareport(filepath,cursor):
    output = []
    # cursor = list(col2.find({'type': {"$ne": "metadata"}},{"component_name":1,"component_type":1,"application":1,"_id":0}))
    # for filepath in getallfiles(filespath,[".java"]):# iterate through every file
    #     print('----------------filename :',filepath.split("\\")[-1],'----------------------')
    Lines = open(filepath).readlines()
    functionnames = []
    functionnames = functionnames + [item.split("\\")[-1].split(".")[0] for item in getallfiles(filepath.rsplit("\\",1)[0],extensions)]
    for line in Lines:#iterate through lines of file 
        # print("line",line)           
        if line.strip().startswith("import ") and line.strip().endswith(";"):
            if not (line.strip().startswith("import java.") or line.strip().startswith("import javax.")):
                path = line.split("import ")[1].split(";")[0]
                if path.endswith("*"):
                    path = path.replace("*","")
                    functionnames = functionnames + [item.split("\\")[-1].split(".")[0] for item in getallfiles(remainingfilepath+path.replace(".","\\"),extensions)]
                else:
                    # functionnames = functionnames + remainingfilepath+path.replace(".","\\")+".java"
                    functionnames.append(path.rsplit(".",1)[-1])
        
        elif functionnames!=[]:
            # print("functionnames",functionnames)
            if any(ele in line for ele in functionnames):
                for functionname in functionnames:
                    if line.__contains__(functionname+"(") and line.__contains__("new") and line.__contains__("="):
                        filename = functionname+".java"
                        if filename.split(".")[0]!=filepath.split("\\")[-1].split(".")[0]:
                            tempdict = modaldict.copy()
                            tempdict["component_name"] = filepath.split("\\")[-1]
                            tempdict["component_type"] = [item["component_type"] for item in cursor if item["component_name"]==filepath.split("\\")[-1]][0]
                            tempdict["calling_app_name"] = [item["application"] for item in cursor if item["component_name"]==filepath.split("\\")[-1]][0]
                            tempdict["called_name"] = filename
                            if filename in [item["component_name"] for item in cursor]:
                                item = [item for item in cursor if item["component_name"]==filename][0] 
                                tempdict["called_type"] = item["component_type"]
                                tempdict["called_app_name"] = item["application"]
                            else:
                                print(line,filename,"called_type, called_app_name are not in the DB")
                                tempdict["called_type"] = "UNKNOWN"
                                tempdict["called_app_name"] = "UNKNOWN"   
                            output.append(tempdict.copy()) 
                            
        if line.__contains__('.getRequestDispatcher("'):            
            path = re.findall('"([^"]*)"', line.split('.getRequestDispatcher(')[1])[0].strip()
            # print("path",path)
            filename = path.split("/")[-1]
            tempdict = modaldict.copy()
            tempdict["component_name"] = filepath.split("\\")[-1]
            tempdict["component_type"] = [item["component_type"] for item in cursor if item["component_name"]==filepath.split("\\")[-1]][0]
            tempdict["calling_app_name"] = [item["application"] for item in cursor if item["component_name"]==filepath.split("\\")[-1]][0]
            if filename.lower().endswith(".jsp"):
                tempdict["called_name"] = filename
                if filename in [item["component_name"] for item in cursor]:
                    item = [item for item in cursor if item["component_name"]==filename][0] 
                    tempdict["called_type"] = item["component_type"]
                    tempdict["called_app_name"] = item["application"]             
                else:
                    tempdict["called_type"] = "JAVA_SERVER_PAGE"
                    if path.split("/")[-2]!="":
                        tempdict["called_app_name"] = path.split("/")[-2].upper()
                    else:
                        print("UNKNOWN app name")
                        tempdict["called_app_name"] = "UNKNOWN"
                    # print("appname",path.split("/")[-2].upper())
                
            elif filename+".java" in [item["component_name"] for item in cursor]:
                tempdict["called_name"] = filename+".java"
                item = [item for item in cursor if item["component_name"]==filename+".java"][0] 
                tempdict["called_type"] = item["component_type"]
                tempdict["called_app_name"] = item["application"]                                         
            else:                     
                print(line,filename,"called_type, called_app_name are not in the DB")
                tempdict["called_name"] = filename
                tempdict["called_type"] = "UNKNOWN"
                tempdict["called_app_name"] = "UNKNOWN"     

            output.append(tempdict.copy())                 
                
        temp = line.split()
        for value in temp:
            if value.startswith(tuple([item+"." for item in functionnames])) and value.endswith(");"):
                if value.strip().split(".")[0]!=filepath.split("\\")[-1].split(".")[0]:
                    filename = value.strip().split(".")[0]+".java"
                    # print(value,filename)
                    tempdict = modaldict.copy()
                    tempdict["component_name"] = filepath.split("\\")[-1]
                    tempdict["component_type"] = [item["component_type"] for item in cursor if item["component_name"]==filepath.split("\\")[-1]][0]
                    tempdict["calling_app_name"] = [item["application"] for item in cursor if item["component_name"]==filepath.split("\\")[-1]][0]
                    tempdict["called_name"] = filename
                    if filename in [item["component_name"] for item in cursor]:
                        item = [item for item in cursor if item["component_name"]==filename][0] 
                        tempdict["called_type"] = item["component_type"] 
                        tempdict["called_app_name"] = item["application"]  
                    else:
                        print(line,filename,"called_type, called_app_name are not in the DB")
                        tempdict["called_type"] = "UNKNOWN"
                        tempdict["called_app_name"] = "UNKNOWN"  
                        
                    output.append(tempdict.copy()) 
                      
    output = [i for n, i in enumerate(output) if i not in output[n + 1:]]
    return output

def getjspreport(filepath,cursor):
    output = []
    Lines = open(filepath).readlines()
    for line in Lines:#iterate through lines of file 
        nameslist = re.findall('"([^"]*)"', line)
        for functionname in nameslist:
            filename = functionname.split("//")[-1].split("\\")[-1].split("/")[-1]
            # if functionname in [item["component_name"] for item in cursor]:
            if functionname.lower().endswith(".jsp") or functionname.lower().endswith(".css"):
                
                tempdict = modaldict.copy()
                tempdict["component_name"] = filepath.split("\\")[-1]
                tempdict["component_type"] = [item["component_type"] for item in cursor if item["component_name"]==filepath.split("\\")[-1]][0]
                tempdict["calling_app_name"] = [item["application"] for item in cursor if item["component_name"]==filepath.split("\\")[-1]][0]
                tempdict["called_name"] = filename  
                
                if filename in [item["component_name"] for item in cursor]:  
                    item = [item for item in cursor if item["component_name"]==filename][0]
                    tempdict["called_type"] = item["component_type"]
                    tempdict["called_app_name"] = item["application"]  
                elif line.__contains__('href="http'):
                    if filename.lower().endswith(".jsp"):
                        tempdict["called_type"] = "JAVA_SERVER_PAGE"
                    elif filename.lower().endswith(".css"):
                        tempdict["called_type"] = "STYLE_SHEET"
                    else:
                        tempdict["called_type"] = "HYPER_LINK"
                    tempdict["called_app_name"] = "INTERNET"      
                elif not filename in [item["component_name"] for item in cursor]:
                    if filename.lower().endswith(".jsp"):
                        tempdict["called_type"] = "JAVA_SERVER_PAGE"
                    elif filename.lower().endswith(".css"):
                        tempdict["called_type"] = "STYLE_SHEET"
                    else:
                        tempdict["called_type"] = "HYPER_LINK"
                    if functionname.split("/")[-2] != "":
                        tempdict["called_app_name"] = functionname.split("/")[-2].upper()
                    else:
                        print("false app name")
                        tempdict["called_app_name"] = "INTERNET"                    
                else:
                    print(line,filename,"called_type, called_app_name are not in the DB")
                    tempdict["called_type"] = "UNKNOWN"
                    tempdict["called_app_name"] = "UNKNOWN"      
                    
                output.append(tempdict.copy())          
                    
            elif filename+".java" in [item["component_name"] for item in cursor]:
                tempdict = modaldict.copy()
                tempdict["component_name"] = filepath.split("\\")[-1]
                tempdict["component_type"] = [item["component_type"] for item in cursor if item["component_name"]==filepath.split("\\")[-1]][0]
                tempdict["calling_app_name"] = [item["application"] for item in cursor if item["component_name"]==filepath.split("\\")[-1]][0]
                tempdict["called_name"] = filename +".java" 
                item = [item for item in cursor if item["component_name"]==filename+".java"][0] 
                tempdict["called_type"] = item["component_type"]
                tempdict["called_app_name"] = item["application"]                  
        
                output.append(tempdict.copy())  

            # else:
            #     if filename in [item["component_name"].split(".")[0] for item in cursor]:
            #         print(filename)

    output = [i for n, i in enumerate(output) if i not in output[n + 1:]]
    return output
    
def getallreports(filespath):
    finaloutput = []
    cursor = list(col2.find({'type': {"$ne": "metadata"}},{"component_name":1,"component_type":1,"application":1,"_id":0}))
    for filepath in getallfiles(filespath,extensions):# iterate through every file
        # print('----------------filename :',filepath.split("\\")[-1],'----------------------')
        if filepath.lower().endswith(".java"):
            finaloutput = finaloutput+getjavareport(filepath,cursor)
        elif filepath.lower().endswith(".jsp"):
            finaloutput = finaloutput+getjspreport(filepath,cursor)
    return finaloutput

def dbinsertfunction(filespath,dbname,collectionname):
    col = client[dbname][collectionname]
    output = getallreports(filespath)    
    if output!=[]:   
        if col.count_documents({}) != 0 :
            col.drop()  
            print("Deleted the old",dbname,collectionname,"collection")
            
        col.insert_one({"type" : "metadata",
                        "headers" : ["component_name","component_type","calling_app_name",
                                     "called_name","called_type","called_app_name"]})        
        col.insert_many(output)
        print("Inserted the list of jsons of",dbname,collectionname)
    else:
        print("There are no jsons in the output to insert in the DB",dbname,collectionname)


        
if __name__ == '__main__':
    # output = getallreports(filespath)
    # if not os.path.exists("outputs//"):
    #     os.makedirs("outputs//")
    # json.dump(output , open('outputs\\cross_reference.json', 'w'), indent=4)
    # pd.DataFrame(output).to_excel("outputs\\cross_reference.xlsx", index=False)     
    dbinsertfunction(filespath,dbname,collectionname)
        
         