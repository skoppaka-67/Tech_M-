# -*- coding: utf-8 -*-
"""
@author: KN00636678

JAVA Process flow report

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
from difflib import SequenceMatcher

from pymongo import MongoClient
client = MongoClient('localhost', 27017)

filespath = config.filespath
dbname = config.dbname
collectionname = config.processflowcn
componentcollection = config.componenttypecn
col2 = client[dbname][componentcollection]

remainingfilepath = filespath + "\\Property_codedump\\src\\"

modaljson = {"component_name": "",
             "event_name": "",
             "nodes": [],
             "links": []}

extensions = ['.java', '.jsp', '.js', '.css']

tags = ['form', 'a']

def getallfiles(filespath,extensions):#function to return the file paths in the given directory with given extention
    filelist = []
    for root, dirs, files in os.walk(filespath):
        for file in files:
            if file.lower().endswith(tuple([item.lower() for item in extensions])):
                filelist.append(os.path.join(root, file))
    return filelist

def geteventtriggers(filespath):
    output = []
    output2 = []
    cursor = list(col2.find({'type': {"$ne": "metadata"}},{"component_name":1,"application":1,"_id":0}))
    for filepath in getallfiles(filespath,[".jsp"]):
        html  = open(filepath).read()#reads file
        if html.strip()!="":
            soup = BeautifulSoup(html,features="lxml")
            for tag in tags:
                listofsingletag = soup.find_all(tag) 
                # print(listofsingletag)
                for singletag in listofsingletag: 
                    eventtag = singletag.attrs
                    if tag == "form" and "action" in eventtag.keys():
                        filename = eventtag["action"]+".java"
                        if filename in [item["component_name"] for item in cursor]:
                        # if [item["component_type"] for item in cursor if item["component_name"]==filename][0]=="SERVLET":                            
                            tempdict = {}
                            tempdict["component_name"] = filepath.split("\\")[-1]
                            tempdict["application"] = [item["application"] for item in cursor if item["component_name"]==filepath.split("\\")[-1]][0]
                            tempdict["called_name"] = filename
                            if "method" in eventtag.keys():
                                if eventtag["method"].lower() == "get":
                                    tempdict["eventname"] = "doGet"
                                elif eventtag["method"].lower() == "post":
                                    tempdict["eventname"] = "doPost"                                    
                            else:
                                tempdict["eventname"] = "doGet"
                            # print(eventtag,tempdict)    
                            output.append(tempdict.copy())  
                        else:
                            filename = filename.split("/")[-1]
                            if filename.count(".")==1 and filename!=".java" and not filename.startswith("#"):
                                if "method" in eventtag.keys():
                                    if eventtag["method"].lower() == "get":
                                        eventname = "doGet"
                                    elif eventtag["method"].lower() == "post":
                                        eventname = "doPost"                                    
                                else:
                                    eventname = "doGet"                                
                                output2.append({"called_name":filename,"eventname":eventname})

                    elif tag == "a" and "href" in eventtag.keys():
                        filename = eventtag["href"]+".java"    
                        if filename in [item["component_name"] for item in cursor]:
                        # if [item["component_type"] for item in cursor if item["component_name"]==filename][0]=="SERVLET":
                            tempdict = {}
                            tempdict["component_name"] = filepath.split("\\")[-1]
                            tempdict["application"] = [item["application"] for item in cursor if item["component_name"]==filepath.split("\\")[-1]][0]
                            tempdict["called_name"] = filename
                            if "method" in eventtag.keys():
                                if eventtag["method"].lower() == "get":
                                    tempdict["eventname"] = "doGet"
                                elif eventtag["method"].lower() == "post":
                                    tempdict["eventname"] = "doPost"  
                            else:
                                tempdict["eventname"] = "doGet"
                            # print(eventtag,tempdict)     
                            output.append(tempdict.copy())
                        else:
                            filename = filename.split("/")[-1]
                            if filename.count(".")==1 and filename!=".java" and not filename.startswith("#"):
                                if "method" in eventtag.keys():
                                    if eventtag["method"].lower() == "get":
                                        eventname = "doGet"
                                    elif eventtag["method"].lower() == "post":
                                        eventname = "doPost"                                    
                                else:
                                    eventname = "doGet"                                
                                output2.append({"called_name":filename,"eventname":eventname})                          

    # print(output2)                        
    output = [i for n, i in enumerate(output) if i not in output[n + 1:]] 
    output = [i for n, i in enumerate(output) if not (i["called_name"]  in [item["called_name"] for item in output[:n]] and i["eventname"]  in [item["eventname"] for item in output[:n]])]                     
    return output,output2

def getnoa(line):
    # print(line)
    if line.split("(")[1].split(")")[0].strip()=="":
        return 0
    else:
        return line.split("(")[1].split(")")[0].count(",")+1
    
def getarguments(line):
    if line.split("(")[1].split(")")[0].strip()=="":
        return [],[]
    else:
        output1 = []
        output2 = []
        arglist = line.split("(")[1].split(")")[0].split(",")
        for item in arglist:
            output1.append(item.split()[0])
            output2.append(item.split()[-1])
        return output1,output2

def getfirstline(Lines,index):
    line = ""
    if "(" in Lines[index] and  ")" in Lines[index]:
        return Lines[index]
    if not ")" in Lines[index]:
        line = line+Lines[index]
        return line+getfirstline(Lines,index+1)
    if not "(" in Lines[index] and ")" in Lines[index]:
        return line+Lines[index]

def getfunctionreturn(line):
    if len(line.split(" ",1)[1].split("(")[0].rsplit(' ', 1))>1:
        return line.split(" ",1)[1].split("(")[0].rsplit(' ', 1)[0]
    else:
        return ""

def getfilefunctionlines(Lines):
    output = [] 
    flag = False
    functionflag = False
    functionflag2 = False
    for index,line in enumerate(Lines):
        # if (line.strip().startswith("public") or line.strip().startswith("private") or line.strip().startswith("protected")) and line.strip().endswith(";"):
        #     print(line)
        if flag:
            if (line.strip().startswith("public") or line.strip().startswith("private") or line.strip().startswith("protected")) and ("(" in line) and (not line.strip().endswith(";")):
                line2 = getfirstline(Lines,index)
                value1,value2 = getarguments(line2)
                
                dict1 = {"functionname"   :line2.split("(")[0].split()[-1],
                         "noa"            :getnoa(line2),
                         "functiontype"   :line2.strip().split()[0],
                         "inputformat"    :"("+line2.split("(")[1].split(")")[0].strip()+")",
                         "functionreturn" :getfunctionreturn(line2),
                         "arguments"      :value1,
                         "argumentvalues" :value2,
                         "label"          :(line2.split(")")[0]+")").strip()}
                
                functionlines = []
                functioncheck = []
                functionflag = True

            if functionflag2:
                if line.__contains__("{"):
                    functioncheck.extend([1]*line.count("{"))
                    # functioncheck.append(1)
                
                if line.__contains__("}"):
                    if len(functioncheck)!=0:
                        for i in range(line.count("}")):
                            functioncheck.pop()
                    else:
                        functionflag2 = False
                        functionflag = False
                        functionlines.append(line.split("}")[0])
                        dict1["functionlines"] = functionlines
                        output.append(copy.deepcopy(dict1))

            if functionflag2:
                functionlines.append(line)                        
                 
            if functionflag and not functionflag2:
                if line.__contains__("{"):
                    functionflag2 = True
                    functionlines.append(line.split("{")[1])
                    
                
        if line.strip().startswith("public interface") or line.strip().startswith("public class"):
            flag = True
       
    return output 

def getallfilefunctions(filespath):
    finaloutput = {}
    for filepath in getallfiles(filespath,[".java"]):# iterate through every file
        Lines = open(filepath).readlines()
        # print(filepath.split("\\")[-1])
        if filepath.split("\\")[-1] in finaloutput.keys():
            print(filepath.split("\\")[-1])
        finaloutput[filepath.split("\\")[-1]]= getfilefunctionlines(Lines)
    return finaloutput

def getfunctioncalls(filename,importfilefunctions,functionlines):
    # print(functionlines)
    output = []
    for index,line in enumerate(functionlines):
        nameslist = re.findall('"([^"]*)"', line)
        for name in nameslist:
            if name.lower().endswith(".jsp"):
                output.append({"functionname":name.split("//")[-1].split("\\")[-1].split("/")[-1],"component_name":filename})
        for function in importfilefunctions:
            if function["functionname"]+"(" in line and not "new "+function["functionname"]+"(" in line and function["noa"]==getnoa(line.split(function["functionname"])[1]):
                if "."+function["functionname"]+"(" in line:
                    alllist = [item for item in importfilefunctions if item["functionname"]==function["functionname"] and item["noa"]==function["noa"]]
                    if len(alllist)>1:  
                        match=[]
                        for same in alllist:
                            obj = line.split("."+same["functionname"]+"(")[0].split()[-1].split(",")[-1].split("(")[-1].split("=")[-1].lower()
                            match.append(SequenceMatcher(None, same["component_name"].split(".")[0].lower(),obj).ratio())
                            # print(obj,same["component_name"])
                        if max(match)>0.5:
                            function2 = alllist[match.index(max(match))] 
                            # print("answer",function2["component_name"],filename,max(match))
                            output.append(function2)
                    else:
                        output.append(function)
                        
                elif " "+function["functionname"]+"(" in (" "+line.strip()):
                    if filename==function["component_name"]:
                        output.append(function)      
    
    output = [i for n, i in enumerate(output) if i not in output[n + 1:]]
    tempoutput = copy.deepcopy(output)
    for item in [item for item in tempoutput if item["component_name"]==filename]:
        for item2 in tempoutput:
            if item2["component_name"]!=filename and item2["functionname"]==item["functionname"] and item2["noa"]==item["noa"] :
                output.remove(item2)
                # print(item2["functionname"],item2["component_name"],filename)
    return output

def getallcalls(filespath):
    output = []
    allfilefunctions = getallfilefunctions(filespath)
    for filepath in getallfiles(filespath,[".java"]):# iterate through every file
        Lines = open(filepath).readlines()  
        
        importfiles = []
        importfiles = importfiles + [item.split("\\")[-1] for item in
                                     getallfiles(filepath.rsplit("\\", 1)[0], [".java"])]
        for line in Lines:  # iterate through lines of file          
            if line.strip().startswith("import ") and line.strip().endswith(";") and not (line.strip().startswith("import java.") or line.strip().startswith("import javax.")):
                path = line.split("import ")[1].split(";")[0]
                if path.endswith("*"):
                    path = path.replace("*", "")
                    importfiles = importfiles + [item.split("\\")[-1] for item in
                                                 getallfiles(remainingfilepath + path.replace(".", "\\"),[".java"])]
                else:
                    importfiles.append(path.rsplit(".", 1)[-1]+".java")
                    
        importfilefunctions = []
        # importfiles.remove(filepath.split("\\")[-1])
        for importfile in importfiles:
            temp = allfilefunctions[importfile]
            for tempitem in temp:
                tempitem["component_name"] = importfile
                importfilefunctions.append(copy.deepcopy(tempitem))
            
        # filefunctionlines = getfilefunctionlines(Lines)
        filefunctionlines = allfilefunctions[filepath.split("\\")[-1]]
        for functionname in allfilefunctions[filepath.split("\\")[-1]]:
            tempdict = copy.deepcopy(functionname)
            tempdict["component_name"] = filepath.split("\\")[-1]

            functionlines = []
            for item in filefunctionlines:
                if functionname["functionname"] == item["functionname"]:              
                    functionlines = item["functionlines"]
      
            tempdict["allcalls"] = getfunctioncalls(filepath.split("\\")[-1],importfilefunctions,functionlines)
            
            output.append(tempdict.copy())
    return output

def getallnodeslinks(node,allcalls):
    nodes = []
    links = []
    endnodes=[] 
    
    functioncalls = node["allcalls"]
    source = "p_"+node["label"]+"["+node["component_name"]+"]"    
    for endnode in functioncalls:
        # print(endnode)      
        if endnode["functionname"].lower().endswith(".jsp"):
            endnodename = endnode["functionname"]
            endfilename = "(JAVA_SERVER_PAGE)"
        else:
            endnodename = endnode["label"]
            endfilename = "["+endnode["component_name"]+"]"
        
        if endnodename.lower().endswith(".jsp"):

            links.append({"source" : source,
                          "target" : "p_"+endnodename.split(".")[0]+endfilename,
                          "label"  : "External_Program"})
            nodes.append({"id"     : "p_"+endnodename.split(".")[0]+endfilename,
                          "label"  :      endnodename.split(".")[0]+endfilename}) 
            
        elif endnode["component_name"]!=node["component_name"]:
         
            links.append({"source" : source,
                          "target" : "p_"+endnodename+endfilename,
                          "label"  : "External_Program"})
            nodes.append({"id"     : "p_"+endnodename+endfilename,
                          "label"  :      endnodename+endfilename})
            endnodes.append(endnode)       

        else:
          
            links.append({"source" : source,
                          "target" : "p_"+endnodename+endfilename})
            nodes.append({"id"     : "p_"+endnodename+endfilename,
                          "label"  :      endnodename+endfilename})
            endnodes.append(endnode)                 
    
    if endnodes!=[]:
         for endnode in endnodes:
             if not (endnode["label"]==node["label"] and endnode["component_name"]==node["component_name"]):
                 # print(endnode)
                 # print("recursive",endnode["functionname"])
                 endfunctionnode = [item for item in allcalls if item["component_name"] == endnode["component_name"] and item["functionname"] == endnode["functionname"] and item["noa"] == endnode["noa"]][0]
                 nodes2,links2 = getallnodeslinks(endfunctionnode,allcalls)    
                 nodes = nodes + nodes2
                 links = links + links2
                 
    nodes = [i for n, i in enumerate(nodes) if i not in nodes[n + 1:]]   
    links = [i for n, i in enumerate(links) if i not in links[n + 1:]]          
    return nodes,links

def getallreports(filespath):
    finaloutput = []
    allcalls = getallcalls(filespath)
    alltriggers,remaintriggers = geteventtriggers(filespath)
    for eventjson in alltriggers:# iterate through every file
        startnode = [item for item in allcalls if item["component_name"] == eventjson["called_name"] and item["functionname"] == eventjson["eventname"]][0]
        tempdict = copy.deepcopy(modaljson)
        tempdict["component_name"] = startnode["component_name"]
        tempdict["event_name"] = startnode["functionname"]
        tempdict["nodes"]=[]
        label = startnode["label"]+"["+startnode["component_name"]+"]"
        tempdict["nodes"].append({"id"    : "p_"+label,
                                  "label" :      label})
        nodes2,tempdict["links"] = getallnodeslinks(startnode,allcalls)
        tempdict["nodes"] = tempdict["nodes"] + nodes2
        finaloutput.append(copy.deepcopy(tempdict))   
        
    for eventjson in remaintriggers:
        event = eventjson["eventname"]
        # print(eventjson["called_name"],event)
        tempdict = copy.deepcopy(modaljson)
        tempdict["component_name"] = eventjson["called_name"]
        tempdict["event_name"] = event
        tempdict["nodes"]=[]
        tempdict["links"] =[]
        finaloutput.append(copy.deepcopy(tempdict))        
    return finaloutput

def dbinsertfunction(filespath,dbname,collectionname):
    col = client[dbname][collectionname]
    output = getallreports(filespath)    
    if output!=[]:   
        if col.count_documents({}) != 0 :
            col.drop()  
            print("Deleted the old",dbname,collectionname,"collection")
        col.insert_many(output)
        print("Inserted the list of jsons of",dbname,collectionname)
    else:
        print("There are no jsons in the output to insert in the DB",dbname,collectionname)

if __name__ == '__main__':
    output =  getallreports(filespath)
    # if not os.path.exists("outputs//"):
    #     os.makedirs("outputs//")
    # json.dump(output , open('outputs\\process_flow.json', 'w'), indent=4)
    # pd.DataFrame(output).to_excel("outputs\\process_flow.xlsx", index=False)     
    # dbinsertfunction(filespath,dbname,collectionname)