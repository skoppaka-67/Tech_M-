# -*- coding: utf-8 -*-
"""
Created on Wed Mar  3 13:42:59 2021

@author: naveen
"""
from os import walk
from os.path import join,isfile
import json
import config

from pymongo import MongoClient
client = MongoClient(config.database['hostname'], config.database['port'])
db = client[config.database['database_name']]
col = db["CRUD_Report"]

#with open("config.json") as f:#importing required data from config file
#    data = json.load(f)     
#path = data["path"]

modaldict = {"component_name" : "","component_type": "","Table" : "",
             "CRUD" : "", "Query" : "", "cursor" : "", "application" : ""}
funcstartline = "EXEC ADABAS" 
funcendline = "END-EXEC"
flag_changer = "PROCEDURE DIVISION"
Break = ["BEGIN","DBCLOSE","CONNECT","HOLD","OPEN","FETCH","CLOSE","COMMIT"]
table = [" FROM "," INTO "," UPDATE "," DELETE "] 
CRUD = ["INSERT","FIND", "UPDATE","DELETE","HISTOGRAM","READ"]
cursor1 = "DECLARE" 
cursor2 = "CURSOR" 

include = "++INCLUDE"
copy = "COPY"

base_location = config.codebase_information['code_location']
cobolfolder = config.codebase_information['COBOL']['folder_name']
includefolder = config.codebase_information['INCLUDE']['folder_name']
copybookfolder = config.codebase_information['COPYBOOK']['folder_name']
extention = "." + config.codebase_information['COBOL']['extension']
extention2 = "." + config.codebase_information['INCLUDE']['extension']
extention3 = "." + config.codebase_information['COPYBOOK']['extension']
path = base_location + '\\' + cobolfolder

def getextensionfiles(path,extention): #get all files in the given directory with given extention
    filelist = []
    for r, d, f in walk(path):
        for file in f:
            if file.endswith(extention):
                filepath =join(r, file)
                filelist.append(filepath)
                
    return filelist

def getCRUD(CRUD,line2):  #function to get CRUD property for json                                                   
    if line2.split()[0] == CRUD[0]:
        return "CREATE"
    elif line2.split()[0] == CRUD[1] or line2.split()[0] == CRUD[4] or line2.split()[0] == CRUD[5]:
        return "READ"
    elif line2.split()[0] == CRUD[2]:
        return "UPDATE"   
    elif line2.split()[0] == CRUD[3]: 
        return "DELETE"                    
    else:
        return ""

def gettable(table,line2): #function to get table property for json                 
    if table[0] in line2:
        return line2.split(table[0])[1].split()[0]
    elif table[1] in line2:
        return line2.split(table[1])[1].split()[0]                        
    elif table[2] in line2:
        return line2.split(table[2])[1].split()[0]
    elif table[3] in line2:
        return line2.split(table[3])[1].split()[0]    
    else:
        return ""

def getreport(path,extention): #main function to get list of jsons of report of cobol files 
    alldict = []          
    for filepath in getextensionfiles(path,extention):# iterate through every file
        startline = 0# these three variables are used to capture the lines between EXEC ADABAS and END-EXEC
        endline = 0
        templines = []
        openFile = open(filepath)#,encoding="utf8")#opens file
        Lines = openFile.readlines()
        
        MainLines = Lines#lines are copied to to this variable
        flag = False
        for line in Lines:#iterate through lines of file
            if flag_changer in line: #this flag changer is for capture lines after PROCEDURE DIVISION
                flag = True
            if flag == True:
                indexline = line
                line = line[6:72]
                line = line.strip()
                if not line.startswith("*"):#if not a comment line
                    if include in line:# check for "++INCLUDE"
                        #print(True)
                        includefilename = line.split(include)[1].split()[0]+extention2 # splits line to get the include file name
                        if isfile(base_location+"\\"+includefolder+"\\"+includefilename):  #opens include file and add the line of file to the mainlines                         
                            openFile2 = open(base_location+"\\"+includefolder+"\\"+includefilename,encoding="utf8").readlines()
                            indexofline = MainLines.index(indexline)
                            del MainLines[MainLines.index(indexline)]
                            MainLines[indexofline: indexofline] = openFile2
                            
        Lines = MainLines
        flag = False
        for line in Lines:#iterate through lines of file
            if flag_changer in line: #this flag changer is for capture lines after PROCEDURE DIVISION
                flag = True
            if flag == True:
                indexline = line
                line = line[6:72]
                line = line.strip()
                if not line.startswith("*"):#if not a comment line
                    if copy in line:# check for "COPY"
                        if line.split()[0] == copy:
                            copybookfilename = line.split(copy)[1].split()[0]+extention3 # splits line to get the copy file name
                            if isfile(base_location+"\\"+copybookfolder+"\\"+copybookfilename):#opens copy file and add the line of file to the mainlines  
                                #print("True2")
                                openFile3 = open(base_location+"\\"+copybookfolder+"\\"+copybookfilename,encoding="utf8").readlines()
                                indexofline = MainLines.index(indexline)
                                del MainLines[MainLines.index(indexline)]
                                MainLines[indexofline: indexofline] = openFile3        
        
        Lines = MainLines
        flag = False
        for line in Lines:#iterate through lines of file
            if flag_changer in line: #this flag changer is for capture lines after PROCEDURE DIVISION
                flag = True
            if flag == True:           
                index = Lines.index(line)
                line = line[6:72]
                line = line.strip()
                
                if not line.startswith("*"):
                    if funcstartline in line:#capturing the startline index
                        startline = index
                    if funcendline in line: #capturing the endline index                 
                        endline = index
                    if startline != 0 and endline != 0:
                        templines = []
                        if Lines[startline][6:72].strip().split("EXEC ADABAS")[1]!='':#if first line is in EXEC ADABAS
                            templines.append(Lines[startline][6:72].strip().split("EXEC ADABAS")[1].strip()) # it will capture it
                        templines2 = Lines[startline+1:endline]
                        templines2 = [line3[6:72] for line3 in templines2]#trimming
                        templines2 = [line3.strip() for line3 in templines2]#removing empty spaces
                        templines2 = [line3  for line3 in templines2 if not line3.startswith("*")]
                        templines = templines + templines2
                        templines = [line3 for line3 in templines if line3 ]#removing empty lines
                        startline = 0
                        endline = 0
                        
                        rejectformat = True
                        tempdict = modaldict.copy() #copying the skeleton dictionary                 
                        tempdict["component_name"] = filepath.split("\\")[-1]
                        tempdict["component_type"] = "COBOL"
                        tempdict["Query"] = " ".join(templines)
                        
                        templine = " ".join(templines)
                        if templine.split()[0] in Break:# checking the format of query is desirable or not
                            rejectformat = False 
                        if cursor1 and cursor2 in templine:#this to capture the cursor 
                            tempdict["cursor"] = templine.split(cursor1)[1].split()[0]                               
                        tempdict["Table"] = gettable(table,templine)       
                        tempdict["CRUD"] = getCRUD(CRUD,templine)
                        
#                        for line2 in templines:
#                            if templines.index(line2) == 0 and line2.split()[0] in Break:# checking the format of query is desirable or not
#                                rejectformat = False 
#                            if cursor1 and cursor2 in line2:#this to capture the cursor 
#                                tempdict["cursor"] = line2.split(cursor1)[1].split()[0]                              
#                            if (table[0] in line2) or (table[1] in line2) or (table[2] in line2):#this to table the cursor 
#                                tempdict["Table"] = gettable(table,line2)       
#                            if templines.index(line2) == 0:
#                                tempdict["CRUD"] = getCRUD(CRUD,line2) 
                                
                        if rejectformat == True:            
                            alldict.append(tempdict.copy())

    return alldict



def insertfunc():
    if col.count() != 0 :
        col.drop()
        col.insert_many(getreport(path,extention))
    else:
        col.insert_many(getreport(path,extention))
        
json.dump(getreport(path,extention), open('output.json', 'w'), indent=4)
insertfunc()











