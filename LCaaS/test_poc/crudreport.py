# -*- coding: utf-8 -*-
"""
@author: KN00636678

IMS DB CRUD report

Dependencies: config file with
filepath, collectionname and dbname
which should be changed according to the user

"""
import glob
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
collectionname = config.crudcollectionname

modaldict = {"component_name" : "",
             "component_type" : "",
             "CRUD" : "",
             "IMS-Function" : "",
             "PCB" : "",
             "SEGMENT" : "",
             "condition" : ""}

def get_files(filespath):
    filenames_list = []
    for filename in glob.glob(os.path.join(filespath, '*.txt')):
        filenames_list.append(filename)
    return filenames_list

def getcrud(line):
    crud = line.split("EXEC DLI")[1].split()[0]
    if crud.upper() == "GU":
        return "GET_UNIQUE"
    elif crud.upper() == "GN":
        return "GET_NEXT"
    elif crud.upper() == "GNP":
        return "GET_NEXT_PARENT"
    elif crud.upper() == "REPL":
        return "UPDATE"
    elif crud.upper() == "DELETE" or crud.upper() == "DLET":
        return "DELETE"
    elif crud.upper() == "ISRT":
        return "INSERT"
    else:
        return crud.upper()

def getcondition(querylines):
    output = ""
    for line in querylines:
        if line.strip().startswith("WHERE"):
            output = line.split("WHERE")[1].strip().replace("(","").replace(")","")
    return output


def getws(tempdict,querylines):
    for line in querylines:
        if line.strip().startswith("FROM"):
            tempdict["fromworkingstorage"] = line.split("FROM")[1].strip().replace("(","").replace(")","")
        if line.strip().startswith("INTO"):
            tempdict["intoworkingstorage"] = line.split("INTO")[1].strip().replace("(","").replace(")","")  
    return tempdict

def getsegment(tempdict,querylines):
    cs1 = ""
    cs2 = ""
    for line in querylines:
        line = " "+line+" "
        if line.strip().startswith("SEGMENT"):
            cs1 = line.split(" SEGMENT ")[1].strip().replace("(","").replace(")","")
        if line.strip().startswith("CURRENT SEGMENT"):       
            cs2 = line.split(" CURRENT SEGMENT ")[1].strip().replace("(","").replace(")","")       
    if cs1 == "" and cs2 == "":
        tempdict["SEGMENT"]=""
    elif cs1==cs2:
        tempdict["SEGMENT"]=cs1
    else:
        tempdict["SEGMENT"]=cs1
        tempdict["CURRENT SEGMENT"]=cs2
    return tempdict

def getpcb(querylines):
    output = ""
    line = " ".join(querylines)
    if "USING" in line and "PCB" in line:
        output = " ".join(line.split("USING")[1].split()[0:2])   
    # for line in querylines:
    #     line = " "+line+" "
    #     if " USING " in line:
    #         output = line.split("USING")[1].strip()
    return output
       
def getreport(file):
    # print(file.split("\\")[-1])
    output = []
    Lines = open(file,encoding="utf8").readlines()
    Lines = [line[6:72] for line in Lines]
    Lines = [line for line in Lines if not line.strip().startswith("*")]
    Lines = [line for line in Lines if line.strip()]
    flag = False
    for line in Lines:
        if line.strip().startswith("EXEC DLI"):
            flag = True
            querylines = []
        if flag:
            querylines.append(line.replace("\n",""))            
        if line.strip().startswith("END-EXEC"):
            flag = False
            tempdict = copy.deepcopy(modaldict)
            tempdict["component_name"] = file.split("\\")[-1]
            tempdict["component_type"] = "COBOL_IMS"
            tempdict["CRUD"] = getcrud(querylines[0])
            tempdict["IMS-Function"] = " ".join(querylines).split(" ".join(querylines).split("EXEC DLI")[1].split()[0])[1].split("END-EXEC")[0]           
            tempdict["PCB"] = getpcb(querylines)
            tempdict["condition"] = getcondition(querylines)
            tempdict = getws(tempdict,querylines)
            tempdict = getsegment(tempdict,querylines)
            output.append(copy.deepcopy(tempdict))
            
    return output

def getallreports(filespath):
    finaloutput = []
    for file in get_files(filespath):
        finaloutput = finaloutput+getreport(file)
    return finaloutput

def dbinsertfunction(filespath,dbname,collectionname):
    col = client[dbname][collectionname]
    output = getallreports(filespath)    
    if output!=[]:   
        if col.count_documents({}) != 0 :
            col.drop()  
            print("Deleted the old",dbname,collectionname,"collection")
            
        col.insert_one({"type" : "metadata",
                        "headers" : ["component_name","component_type","CRUD","IMS-Function","PCB","condition",
                                     "fromworkingstorage","intoworkingstorage","SEGMENT","CURRENT SEGMENT"]})        
        col.insert_many(output)
        print("Inserted the list of jsons of",dbname,collectionname)
    else:
        print("There are no jsons in the output to insert in the DB",dbname,collectionname)
        
        
if __name__ == '__main__':
    output = getallreports(filespath)
    json.dump(output , open('output.json', 'w'), indent=4)
    pd.DataFrame(output).to_excel("output.xlsx", index=False)     
    dbinsertfunction(filespath,dbname,collectionname)
        
         