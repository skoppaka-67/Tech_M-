# -*- coding: utf-8 -*-
"""
@author: KN00636678

JAVA Screenfields report

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
collectionname = config.screenfieldcn
componentcollection = config.componenttypecn
col2 = client[dbname][componentcollection]

# all_keys = set().union(*(d.keys() for d in output))
all_keys = ["filename","application","Tagname",'action','alt','class','for','id',
            'maxlength','method','name','onsubmit','pattern','placeholder',
            'required','src','style','title','type','userid','value']
# all the attribute values

headers = list(all_keys)#headers for the UI
headers[headers.index("id")]="screenfield"

modaldict = dict.fromkeys(all_keys, "")#empty dictionary of a screenfield json

extensions = ['.java','.jsp','.js','.css']

all_tags = ['form','div','h1','img','label','b','input','br',
            'button','a','table','tr','td','span','textarea','h4','select','option']

tags = ['form','img','label','input','button','a','table','span','textarea','select','option']#list of tags to be captured

boolean_attr = ["allowfullscreen","allowpaymentrequest","async","autofocus","autoplay","checked","controls","default"
                "disabled","formnovalidate","hidden","ismap","itemscope","loop","multiple","muted","nomodule"
                "novalidate","open","playsinline","readonly","required","reversed","selected","truespeed"]
# list of boolean atrributes

def getallfiles(filespath,extensions):#function to return the file paths in the given directory with given extensions
    filelist = []
    for root, dirs, files in os.walk(filespath):
        for file in files:
            if file.lower().endswith(tuple([item.lower() for item in extensions])):
                filelist.append(os.path.join(root, file))
    return filelist

def gethtml(filepath):#function to return the formtag part of the file
    Lines  = open(filepath).readlines()#reads file
    flag = False
    output = ""
    for line in Lines:
        if line.__contains__("<form"):
            flag = True
        if flag:
             output = output + line            
        if line.__contains__("</form>"):
            flag = False      
            
    return output

def getallreports(filespath):#main function to get the list of jsons of screenfield jsons
    cursor = list(col2.find({'type': {"$ne": "metadata"}},{"component_name":1,"application":1,"_id":0}))
    output = []
    for filepath in getallfiles(filespath,[".jsp"]):#iterate through all the .jsp files
         # print('----------------filename :',filepath.split("\\")[-1],'----------------------')
         html = gethtml(filepath) #get the form tag of given file        
         if html.strip()!="":
             html = html.replace('("','(').replace('")',')')
             soup = BeautifulSoup(html,features="lxml")
             for tag in tags:#iterate through required tags
                 listofsingletag = soup.find_all(tag) 
                 # print(listofsingletag)
                 for singletag in listofsingletag:#iterate through all instances of that particular tag
                     # if singletag.attrs != {}:
                     # print(singletag,singletag.attrs)
                     tempdict = modaldict.copy()#screenfield json for each such instance
                     tempdict["filename"] = filepath.split("\\")[-1]
                     tempdict["application"] = [item["application"] for item in cursor if item["component_name"]==filepath.split("\\")[-1]][0]
                     tempdict["Tagname"] = tag
                     for key in singletag.attrs.keys():
                         if key in boolean_attr and singletag.attrs[key]=="":
                             tempdict[key] = True
                         else:
                             tempdict[key] = singletag.attrs[key]
                     
                     for key in boolean_attr :
                         if key in tempdict.keys():
                             if tempdict[key] == "":
                                 tempdict[key] = False
                             
                     tempdict["screenfield"] = tempdict.pop("id")
                        
                     output.append(tempdict.copy())
        
    return output

def dbinsertfunction(filespath,dbname,collectionname):#function to update or insert the headers and list of jsons in db
    col = client[dbname][collectionname]
    output = getallreports(filespath)    
    if output!=[]:   
        if col.count_documents({}) != 0 :
            col.drop()  
            print("Deleted the old",dbname,collectionname,"collection")
            
        col.insert_one({"type" : "metadata",
                        "headers" : headers})
        
        col.insert_many(output)
        print("Inserted the list of jsons of",dbname,collectionname)
    else:
        print("There are no jsons in the output to insert in the DB",dbname,collectionname)

if __name__ == '__main__':
    # output = getallreports(filespath)
    # if not os.path.exists("outputs//"):
    #     os.makedirs("outputs//")
    # json.dump(output , open('outputs\\screenfields.json', 'w'), indent=4)
    # pd.DataFrame(output).to_excel("outputs\\screenfields.xlsx", index=False)     
    dbinsertfunction(filespath,dbname,collectionname)