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
from bs4 import BeautifulSoup

from pymongo import MongoClient

client = MongoClient('localhost', 27017)

filespath = config.filespath
dbname = config.dbname
collectionname = config.crossreferencecn
componentcollection = config.componenttypecn
col2 = client[dbname][componentcollection]

foldernames = ["src\\com\\masterofproperty\\", "WebContent"]
remainingfilepath = filespath + "\\Property_codedump\\src\\"

modaldict = {"filename": "",
             "component_name": "",
             "component_type": "",
             "calling_app_name": "",
             "called_name": "",
             "called_type": "",
             "called_app_name": "",
             "dd_name": "",
             "access_mode": "",
             "step_name": "",
             "Comments": ""}

extensions = ['.java', '.jsp', '.js', '.css']

csyntax = {".jsp":('<!--','-->','<%--','--%>'),#different comment syntax for different files
           ".css":('//','','/*','*/'),
           ".java":('//','','/*','*/'),
           ".js"  :('//','','/*','*/')}

tags = ['form', 'a']

def getallfiles(filespath, extensions):  # function to return the file paths in the given directory with given extention
    filelist = []
    for root, dirs, files in os.walk(filespath):
        for file in files:
            if file.lower().endswith(tuple([item.lower() for item in extensions])):
                filelist.append(os.path.join(root, file))
    return filelist

def getvariables(line):
    output = {}
    line = line.strip()
    if line.startswith(("private","public")):
        line = line.replace("private","").replace("public","")
    line = line.split(";")[0].split("=")[0].strip()
    variables = line.split()[-1]
    for item in variables.split(","):
        output[item]=line.split()[-2]
    return output

def removecommentlines(Lines,extension):
    start1,end1,start2,end2 = csyntax["."+extension.lower()]
    Lines = [line for line in Lines if not line.strip().startswith(start1)]
    commentflag = False
    for index, line in enumerate(Lines):#iterate through lines of file                      
        if commentflag:#between lines of multicomment line
            Lines[index] = ''
        if start2 in line:  
            Lines[index] = line.split(start2)[0].strip()                
            commentflag = True
        if end2 in line:#end of multicomment line
            Lines[index] = line.split(end2)[1].strip()
            commentflag = False                         
      
    Lines = [line for line in Lines if line.strip()!=""]    
    return Lines

def getjavareport(filepath, cursor):
    output = []
    cursor2 = [item for item in cursor if item["WebServlet"]!=None]
    Lines = open(filepath).readlines()
    Lines = removecommentlines(Lines,"java")
    functionnames = []
    functionnames = functionnames + [item.split("\\")[-1].rsplit(".",1)[0] for item in
                                     getallfiles(filepath.rsplit("\\", 1)[0], extensions)]
    for line in Lines:  # iterate through lines of file        
        # if all(ele in line for ele in ["(",")",";"]) and not "=" in line and not "." in line:
        #     print(line)
        if line.strip().startswith("import ") and line.strip().endswith(";"):
            if not (line.strip().startswith("import java.") or line.strip().startswith("import javax.")):
                path = line.split("import ",1)[1].split(";")[0]
                if path.endswith("*"):
                    path = path.replace("*", "")
                    functionnames = functionnames + [item.split("\\")[-1].rsplit(".",1)[0] for item in
                                                     getallfiles(remainingfilepath + path.replace(".", "\\"),
                                                                 extensions)]
                else:
                    # functionnames = functionnames + remainingfilepath+path.replace(".","\\")+".java"
                    functionnames.append(path.rsplit(".", 1)[-1])

        elif functionnames != []:
            for functionname in functionnames:
                if line.__contains__(functionname + "(") and line.__contains__("new") and line.__contains__("=") and line.strip().endswith(";"):
                    filename = functionname + ".java"
                    if filename.rsplit(".",1)[0] != filepath.split("\\")[-1].rsplit(".",1)[0]:
                        tempdict = modaldict.copy()
                        tempdict["component_name"] = filepath.split("\\")[-1]
                        tempdict["called_name"] = filename
                        output.append(tempdict.copy())

                if "=" in line and line.strip().endswith(";") and not " new " in line and len(line.strip().split("=")[0].split())>1 and all(ele not in line.strip().split("=")[0] for ele in ["+","."]):
                    variables = getvariables(line).values()
                    if functionname in variables:
                        tempdict = modaldict.copy()
                        tempdict["component_name"] = filepath.split("\\")[-1]
                        tempdict["called_name"] = functionname+".java"
                        output.append(tempdict.copy())

        if line.__contains__('.getRequestDispatcher("'):
            path = re.findall('"([^"]*)"', line.split('.getRequestDispatcher(',1)[1])[0].strip()
            # print(path)
            filename = path.split("/")[-1]
            tempdict = modaldict.copy()
            tempdict["component_name"] = filepath.split("\\")[-1]
            tempdict["called_name"] = filename
            output.append(tempdict.copy())       
        
        temp = line.split()
        for value in temp:
            if value.startswith(tuple([item + "." for item in functionnames])) and line.strip().endswith(");"):
                if value.strip().split(".",1)[0] != filepath.split("\\")[-1].split(".",1)[0]:
                    filename = value.strip().split(".",1)[0] + ".java"
                    # print(filepath.split("\\")[-1],filename,line)
                    tempdict = modaldict.copy()
                    tempdict["component_name"] = filepath.split("\\")[-1]
                    tempdict["called_name"] = filename
                    output.append(tempdict.copy())
    
    for crjson in output:
        ctajson = [item for item in cursor if item["component_name"] == crjson["component_name"]][0]
        crjson["component_type"]=ctajson["component_type"]
        crjson["calling_app_name"]=ctajson["application"]
        if crjson["called_name"] in [item["component_name"] for item in cursor]:
            ctajson2 = [item for item in cursor if item["component_name"] == crjson["called_name"]][0]
            crjson["called_type"] = ctajson2["component_type"]
            crjson["called_app_name"] = ctajson2["application"]
        elif crjson["called_name"] in [item["WebServlet"].split("/")[-1] for item in cursor2]:
            ctajson2 = [item for item in cursor2 if item["WebServlet"].split("/")[-1] == crjson["called_name"]][0]
            crjson["called_name"] = ctajson2["component_name"]
            crjson["called_type"] = ctajson2["component_type"]
            crjson["called_app_name"] = ctajson2["application"]            
        elif crjson["called_name"].lower().endswith(".jsp"):
            crjson["called_type"] = "JAVA_SERVER_PAGE"
            crjson["called_app_name"] = "UNKNOWN"           
        else:
            print(crjson["called_name"], "called_type, called_app_name are not in the DB")
            crjson["called_type"] = "UNKNOWN"
            crjson["called_app_name"] = "UNKNOWN"        
        
    output = [i for n, i in enumerate(output) if i not in output[n + 1:]]
    return output


def getjspreport(filepath, cursor):
    cursor2 = [item for item in cursor if item["WebServlet"]!=None]
    output = []
    html  = open(filepath).read()#reads file
    soup = BeautifulSoup(html,features="lxml")
    for tag in tags:
        listofsingletag = soup.find_all(tag) 
        # print(listofsingletag)
        for singletag in listofsingletag: 
            eventtag = singletag.attrs
            if tag == "form" and "action" in eventtag.keys():
                filename = eventtag["action"]#+".java"
                filename = filename.split("/")[-1]
                # print(filename)
                if filename in [item["WebServlet"].split("/")[-1] for item in cursor2]:
                    tempdict = modaldict.copy()
                    tempdict["component_name"] = filepath.split("\\")[-1]
                    tempdict["called_name"] = filename   
                    output.append(tempdict.copy())
                elif filename.split("/")[-1].count(".") == 0:
                    tempdict = modaldict.copy()
                    tempdict["component_name"] = filepath.split("\\")[-1]
                    tempdict["called_name"] =   filename    
                    output.append(tempdict.copy())
                # else:
                #     print(filename)
            elif tag == "a" and "href" in eventtag.keys():
                filename = eventtag["href"]#+".java" 
                filename = filename.split("/")[-1] 
                # print(filename)            
                if filename in [item["component_name"] for item in cursor]:
                    tempdict = modaldict.copy()
                    tempdict["component_name"] = filepath.split("\\")[-1]
                    tempdict["called_name"] = filename    
                    output.append(tempdict.copy())
                elif filename in [item["WebServlet"].split("/")[-1] for item in cursor2]:
                    tempdict = modaldict.copy()
                    tempdict["component_name"] = filepath.split("\\")[-1]
                    tempdict["called_name"] = filename 
                    output.append(tempdict.copy())                                     
                # else:
                #     print(filename)
                    
    for crjson in output:
        ctajson = [item for item in cursor if item["component_name"] == crjson["component_name"]][0]
        crjson["component_type"]=ctajson["component_type"]
        crjson["calling_app_name"]=ctajson["application"]
        if crjson["called_name"] in [item["component_name"] for item in cursor]:
            ctajson2 = [item for item in cursor if item["component_name"] == crjson["called_name"]][0]
            crjson["called_type"] = ctajson2["component_type"]
            crjson["called_app_name"] = ctajson2["application"]
        elif crjson["called_name"] in [item["WebServlet"].split("/")[-1] for item in cursor2]:
            ctajson2 = [item for item in cursor2 if item["WebServlet"].split("/")[-1] == crjson["called_name"]][0]
            crjson["called_name"] = ctajson2["component_name"]
            crjson["called_type"] = ctajson2["component_type"]
            crjson["called_app_name"] = ctajson2["application"]            
        elif crjson["called_name"].lower().endswith(".jsp"):
            crjson["called_type"] = "JAVA_SERVER_PAGE"
            crjson["called_app_name"] = "UNKNOWN"           
        else:
            print(crjson["called_name"], "called_type, called_app_name are not in the DB")
            crjson["called_type"] = "UNKNOWN"
            crjson["called_app_name"] = "UNKNOWN"  
                
    Lines = open(filepath).readlines()
    for index, line in enumerate(Lines):  # iterate through lines of file
        nameslist = re.findall('"([^"]*)"', line)
        for functionname in nameslist:
            filename = functionname.split("//")[-1].split("\\")[-1].split("/")[-1]
            if filename.lower().endswith(".jsp") or filename.lower().endswith(".css") or filename.lower().endswith(".js"):
                tempdict = modaldict.copy()
                tempdict["component_name"] = filepath.split("\\")[-1]
                ctype = [item for item in cursor if item["component_name"] == filepath.split("\\")[-1]][0]
                tempdict["component_type"] = ctype["component_type"]
                tempdict["calling_app_name"] = ctype["application"]
                tempdict["called_name"] = filename
                if filename.lower().endswith(".jsp"):
                    tempdict["called_type"] = "JAVA_SERVER_PAGE"
                elif filename.lower().endswith(".css"):
                    tempdict["called_type"] = "STYLE_SHEET"
                elif filename.lower().endswith(".js"):
                    tempdict["called_type"] = "JAVA_SCRIPT"

                if filename in [item["component_name"] for item in cursor]:
                    item = [item for item in cursor if item["component_name"] == filename][0]
                    tempdict["called_app_name"] = item["application"]
                elif functionname.__contains__('https:'):
                    tempdict["called_app_name"] = "INTERNET"
                elif functionname.split("/")[-2] != "":
                    if ">" in functionname:
                        tempdict["called_app_name"] = functionname.split("/")[-2].split(">")[1].upper()
                    else:
                        tempdict["called_app_name"] = functionname.split("/")[-2].upper()
                else:
                    print("false app name")
                    tempdict["called_app_name"] = "UNKNOWN"

                output.append(tempdict.copy())
            # else:
            #     print(filename)

    output = [i for n, i in enumerate(output) if i not in output[n + 1:]]
    return output


def getallreports(filespath):
    finaloutput = []
    cursor = list(col2.find({'type': {"$ne": "metadata"}},{"component_name": 1, "component_type": 1, "application": 1,"WebServlet":1, "_id": 0}))
    for filepath in getallfiles(filespath, extensions):  # iterate through every file
        # print('----------------filename :',filepath.split("\\")[-1],'----------------------')
        if filepath.lower().endswith(".java"):
            finaloutput = finaloutput + getjavareport(filepath, cursor)
        elif filepath.lower().endswith(".jsp"):
            finaloutput = finaloutput + getjspreport(filepath, cursor)
    return finaloutput


def dbinsertfunction(filespath, dbname, collectionname):
    col = client[dbname][collectionname]
    output = getallreports(filespath)
    if col.count_documents({}) != 0:
        col.drop()
        print("Deleted the old", dbname, collectionname, "collection")

    col.insert_one({"type": "metadata",
                    "headers": ["component_name", "component_type", "calling_app_name",
                                "called_name", "called_type", "called_app_name"]})    
    if output != []:
        col.insert_many(output)
        print("Inserted the list of jsons of", dbname, collectionname)
    else:
        print("There are no jsons in the output to insert in the DB", dbname, collectionname)


if __name__ == '__main__':
    #output = getallreports(filespath)
    # if not os.path.exists("outputs//"):
    #     os.makedirs("outputs//")
    # json.dump(output , open('outputs\\cross_reference.json', 'w'), indent=4)
    # pd.DataFrame(output).to_excel("outputs\\cross_reference.xlsx", index=False)     
    dbinsertfunction(filespath, dbname, collectionname)
