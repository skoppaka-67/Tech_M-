# -*- coding: utf-8 -*-
"""
Created on Fri Apr  9 10:32:35 2021

@author: naveen
"""

from pymongo import MongoClient
client = MongoClient('localhost', 27017)
db = client["vb_update"]
col1 = db["master_inventory_report"]
col2 = db["cross_reference_report"]
col3 = db["missing_components_report"]
col4 = db["orphan_report"]

cursor1 = col1.find({},{"component_name":1,"component_type":1,"_id":0})
cursor2 = col2.find({},{"called_name":1,"called_type":1,"_id":0})
cursor11 = col1.find({},{"component_name":1,"application":1,"_id":0})

def getmissingorphanreports(cursor1,cursor2,cursor11):

    collection1 = []
    for doc in cursor1:
        if "component_name" and "component_type" in doc.keys():
            collection1.append(doc["component_name"].split(".")[0]+"+"+doc["component_type"])
     
    collection2 = []
    for doc in cursor2:
        if "called_name" and "called_type" in doc.keys():
            collection2.append(doc["called_name"]+"+"+doc["called_type"])
     
    collection11 = []
    for doc in cursor11:
        if "component_name" and "application" in doc.keys():
            collection11.append({"component_name":doc["component_name"].split(".")[0], "application":doc["application"]})
     
    #collection11= set(collection11)
          
    MissingList = list(set(collection2)-set(collection1))
    missingreport=[]
    for item in MissingList:
        missingdict = {}
        missingdict["component_name"]=item.split("+")[0]
        missingdict["component_type"]=item.split("+")[1]
        missingreport.append(missingdict)
    
     
    OrphanList = list(set(collection1)-set(collection2))
    orphanreport=[]
    for item in OrphanList:
        orphandict = {}
        orphandict["component_name"]=item.split("+")[0]
        orphandict["component_type"]=item.split("+")[1]
        for temp in collection11:
            if temp["component_name"]==item.split("+")[0]:
                orphandict["application"] = temp["application"]
        orphanreport.append(orphandict)
    
    return missingreport,orphanreport

def insertfunc():#insert the comment report function
    missingreport,orphanreport = getmissingorphanreports(cursor1,cursor2,cursor11)
    if col3.count() != 0 :
        col3.drop()
        col3.insert_many(missingreport)
        col3.insert_one({"type" : "metadata",
                "headers" : ["component_name","component_type"]})
   
    else:
        col3.insert_many(missingreport)
        col3.insert_one({"type" : "metadata",
                "headers" : ["component_name","component_type"]})

    
    if col4.count() != 0 :
        col4.drop()
        col4.insert_many(orphanreport)
        col4.insert_one({"type" : "metadata",
                "headers" : ["component_name","component_type","application"]})         
    else:
        col4.insert_many(orphanreport)
        col4.insert_one({"type" : "metadata",
                "headers" : ["component_name","component_type","application"]})
    
insertfunc()