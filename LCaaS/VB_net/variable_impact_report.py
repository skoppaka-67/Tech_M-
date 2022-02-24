# -*- coding: utf-8 -*-
"""
@author: naveen
"""

from os import walk
from os.path import join
import json

from pymongo import MongoClient
client = MongoClient('localhost', 27017)
db = client["Screenfields"]
col = db["variable_impact_codebase"]

path = "C:\\Users\\naveen\\Downloads\\WFH\\LMaas\\Glossary Task\\Comment Report\\Files"#path for all types of files present in the folder

extentions = {".aspx":['<!--,-->' , '<%--,--%>'],#differen comment syntax for different files
              ".aspx.vb":["',",","],
              ".vb":["',",","],
              ".js":['//,','/*,*/']}

vimodal = {"component_name" : "",#model json for showcode report
                "component_type": "",
                "sourcestatements" : ""}

def getextensionfiles(path,extention):#function to return the file paths in the given directory with given extention
    filelist = []
    count = extention.count(".")
    for r, d, f in walk(path):
        for file in f:
            if file.endswith(extention) and file.count(".") == count:
                filepath =join(r, file)
                filelist.append(filepath)
                
    return filelist

def getcomptype(extention):#function to get the component_type for each file
    if extention == ".aspx":
        return "CODEBEHIND"
    elif extention == ".vb" or extention == ".aspx.vb":
        return "VB"
    elif extention == ".js":
        return "JAVASCRIPT"
    else:
        return ""

def getremainstring(line,start,end):#this function is to get the remaining string ie other than between start and end
    return line.split(start)[0].strip()+line.split(end)[1].strip()

#def removemlcomments(Lines,extention,mlcommentflag,start2,end2):
#    for index, line in enumerate(Lines):#iterate through lines of file                      
#        if extention == '.js' or extention == '.aspx':
#            if start2 in line:                  
#                mlcommentflag = True
#            if end2 in line:
#                Lines[index] = line.split(end2)[1].strip()
#                mlcommentflag = False                         
#            if mlcommentflag == True:
#                if start2 in line:                  
#                    Lines[index] = line.split(start2)[0].strip()                          
#                else:
#                    Lines[index] = '' 
#                    
#    return Lines
#
#def removeslcomments(Lines,extention,start1,end1,start2,end2):
#    if extention == '.aspx':
#        Lines = [line if not (start1 in line and end1 in line) else getremainstring(line,start1,end1) for line in Lines ]
#        Lines = [line if not (start2 in line and end2 in line) else getremainstring(line,start2,end2) for line in Lines ]
#    elif extention == '.aspx.vb' or extention == '.vb':    
#        Lines = [line for line in Lines if not line.startswith(start1)]
#    elif extention == '.js':
#        Lines = [line if not start1 in line else line.split(start1)[0].strip() for line in Lines]              
#    return Lines

def getvireport(path,extentions):
    vilist = []
    for extention in extentions:
        #print(extention)
        start1 = extentions[extention][0].split(",")[0]#comment syntax for single and mutiline for the given file type
        end1 = extentions[extention][0].split(",")[1]
        start2 = extentions[extention][1].split(",")[0]
        end2 = extentions[extention][1].split(",")[1]
        mlcommentflag = False      
        for filepath in getextensionfiles(path,extention):#loop for all files
            #print('----------------filename :',filepath.split("\\")[-1],'----------------------')
            openFile = open(filepath,encoding="utf8")#reads file
            Lines = openFile.readlines()#opens file
            Lines = [line.strip() for line in Lines]  #remove empty spaces at the ends
            #Lines = removeslcomments(Lines,extention,start1,end1,start2,end2)
            #Lines = removemlcomments(Lines,extention,mlcommentflag,start2,end2)
            
            #following if elif conditions is to remove the single line comments
            if extention == '.aspx':
                Lines = [line if not (start1 in line and end1 in line) else getremainstring(line,start1,end1) for line in Lines ]
                Lines = [line if not (start2 in line and end2 in line) else getremainstring(line,start2,end2) for line in Lines ]
            elif extention == '.aspx.vb' or extention == '.vb':    
                Lines = [line for line in Lines if not line.startswith(start1)]
            elif extention == '.js':
                Lines = [line if not start1 in line else line.split(start1)[0].strip() for line in Lines]
            
            #following for ioop is to remove the multiple line comments
            for index, line in enumerate(Lines):#iterate through lines of file                      
                if extention == '.js' or extention == '.aspx':#start of multicomment line
                    if start2 in line:                  
                        mlcommentflag = True
                    if end2 in line:#end of multicomment line
                        Lines[index] = line.split(end2)[1].strip()
                        mlcommentflag = False                         
                    if mlcommentflag == True:#between lines of multicomment line
                        if start2 in line:                  
                            Lines[index] = line.split(start2)[0].strip() #capturing the syntax of line before the comment                         
                        else:
                            Lines[index] = '' 
                        
            Lines = [line for line in Lines if line]#removing the empty lines
            for line in Lines:              
                vidict = vimodal.copy()#showcode json format
                vidict["component_name"] = filepath.split("\\")[-1]#filename
                vidict["component_type"] = getcomptype(extention)            
                vidict["sourcestatements"] = line  
                vilist.append(vidict.copy())
    return vilist 
            
def insertfunc1():#insert the varible impact report function
    if col.count() != 0 :
        col.drop()
        col.insert_many(getvireport(path,extentions))
    else:
        col.insert_many(getvireport(path,extentions))

#getvireport(path,extentions)
        
json.dump(getvireport(path,extentions), open('variable_impact_output.json', 'w'), indent=4) 
insertfunc1()