import os
import re
import pathlib
import pandas as pd
import pymongo
from openpyxl.workbook import Workbook

"""Testting COmmit from IDE"""


path = 'C:\\Users\jiya\Desktop\Sachin Internship\internship notes\Day 6\Bookstore'
dbName='Csharp'
collectionName='crud_report'
client = pymongo.MongoClient('localhost', 27017)


# completeCrudDictionary=[]
def fetchSQLQuery(querytype, line):
    if re.findall(r'\" *%s ' % querytype, line, re.IGNORECASE):
        tempList = (re.findall(r'"([^"]*)"', line))
        for item in tempList:
            if re.search(r"%s " % querytype, item, re.IGNORECASE):
                return item

    elif re.findall(r'\' *%s ' % querytype, line, re.IGNORECASE):
        tempList = (re.findall(r"'([^']*)'", line))
        for item in tempList:
            if re.search(r"%s " % querytype, item, re.IGNORECASE):
                return item

def fetchTableName(query):

    if re.findall(r"from", query, re.IGNORECASE):
        tableName = re.split(r"(from|FROM|From) ", query, re.IGNORECASE)[2].split()[0].split("(")[0]
        result = re.findall(r"\[([A-Za-z0-9_]+)\]", tableName)
        if result!=[]:
            tableName=result[0]
        return tableName
    if re.findall(r"into", query, re.IGNORECASE):
        tableName = re.split(r"(into|INTO|Into) ", query, re.IGNORECASE)[2].split()[0].split("(")[0]
        result = re.findall(r"\[([A-Za-z0-9_]+)\]", tableName)
        if result != []:
            tableName = result[0]
        return tableName
    if re.findall(r"update", query, re.IGNORECASE):
        tableName = re.split(r"(update|UPDATE|Update) ", query, re.IGNORECASE)[2].split()[0].split("(")[0]
        result = re.findall(r"\[([A-Za-z0-9_]+)\]", tableName)
        if result != []:
            tableName = result[0]
        return tableName
"""    if re.findall(r"Delete", query, re.IGNORECASE):
        tableName = re.split(r"(delete|DELETE|Delete) ", query, re.IGNORECASE)
        print(tableName)
        # return tableName"""

def selectQuery(line, name_of_file, name_of_folder):
    # global completeCrudDictionary
    crudDictionary = {}
    crudDictionary["Component_name"] = name_of_file
    crudDictionary["Component_type"] = pathlib.Path(name_of_file).suffix
    crudDictionary["Calling_app_name"] = name_of_folder
    SQLQuery = fetchSQLQuery("select", line)
    crudDictionary["SQL"] = SQLQuery
    TableName=fetchTableName(SQLQuery)
    crudDictionary["Table"] = TableName
    crudDictionary["Crud"] = "READ"
    crudDictionary["application"]="UNKNOWN"
    # completeCrudDictionary.append(crudDictionary)
    # print(crudDictionary)
    return crudDictionary

def updateQuery(line, name_of_file, name_of_folder):
    # global completeCrudDictionary
    crudDictionary = {}
    crudDictionary["Component_name"] = name_of_file
    crudDictionary["Component_type"] = pathlib.Path(name_of_file).suffix
    crudDictionary["Calling_app_name"] = name_of_folder
    SQLQuery = fetchSQLQuery("update", line)
    crudDictionary["SQL"] = SQLQuery
    TableName=fetchTableName(SQLQuery)
    crudDictionary["Table"]=TableName
    crudDictionary["Crud"] = "UPDATE"
    crudDictionary["application"] = "UNKNOWN"
    # completeCrudDictionary.append(crudDictionary)
    # print(crudDictionary)
    return crudDictionary

def insertQuery(line, name_of_file, name_of_folder):
    crudDictionary = {}
    crudDictionary["Component_name"] = name_of_file
    crudDictionary["Component_type"] = pathlib.Path(name_of_file).suffix
    crudDictionary["Calling_app_name"] = name_of_folder
    SQLQuery = fetchSQLQuery("insert", line)
    crudDictionary["SQL"] = SQLQuery
    TableName=fetchTableName(SQLQuery)
    crudDictionary["Table"] = TableName
    crudDictionary["Crud"]="CREATE"
    crudDictionary["application"] = "UNKNOWN"
    return crudDictionary

def deleteQuery(line, name_of_file, name_of_folder):
    # global completeCrudDictionary
    crudDictionary = {}
    crudDictionary["Component_name"] = name_of_file
    crudDictionary["Component_type"] = pathlib.Path(name_of_file).suffix
    crudDictionary["Calling_app_name"] = name_of_folder
    SQLQuery = fetchSQLQuery("delete", line)
    crudDictionary["SQL"] = SQLQuery
    TableName=fetchTableName(SQLQuery)
    crudDictionary["Table"] = TableName
    crudDictionary["Crud"] = "DELETE"
    crudDictionary["application"] = "UNKNOWN"
    return crudDictionary


def openFile(file, name_of_file, name_of_folder):
    crudOfEachFile=[]
    reqFile = open(file, "r", encoding="utf8")
    for line in reqFile:
        if re.findall(r'\" *select ', line, re.IGNORECASE) or re.findall(r'\' *select ', line, re.IGNORECASE):
            crudOfEachFile.append(selectQuery(line, name_of_file, name_of_folder))
        if re.findall(r'\" *update ', line, re.IGNORECASE) or re.findall(r'\' *update ', line, re.IGNORECASE):
            crudOfEachFile.append(updateQuery(line, name_of_file, name_of_folder))
        if re.findall(r'\" *insert ', line, re.IGNORECASE) or re.findall(r'\' *insert ', line, re.IGNORECASE):
            crudOfEachFile.append(insertQuery(line, name_of_file, name_of_folder))
        if re.findall(r'\" *delete ', line, re.IGNORECASE) or re.findall(r'\' *delete ', line, re.IGNORECASE):
            crudOfEachFile.append(deleteQuery(line, name_of_file, name_of_folder))

    return crudOfEachFile

def directoryFilesIteration(path):
    completeCrudReport=[]
    tempReport=[]
    for subdir, dirs, files in os.walk(path):
        for filename in files:
            filepath = subdir + os.sep + filename
            a = os.path.normpath(subdir)
            name_of_folder = os.path.basename(a)
            without_extra_slash = os.path.normpath(filepath)
            fileNameAndExtension = os.path.basename(without_extra_slash)
            if openFile(filepath, fileNameAndExtension,name_of_folder) !=[]:
                tempReport.append(openFile(filepath, fileNameAndExtension,name_of_folder))
    for item1 in tempReport:
        for item2 in item1:
            completeCrudReport.append(item2)
    print(completeCrudReport)
    return completeCrudReport

def checkDBExistance(path,dbName,collectionName):
    global information

    dbnames = client.list_database_names()
    if dbName in dbnames:
        db = client[dbName]
        if collectionName in str(db.list_collection_names()):
            information = db[collectionName].drop()
            information = db[collectionName]
            information.insert_many(directoryFilesIteration(path))
        else:
            information = db[collectionName]
            information.insert_many(directoryFilesIteration(path))
    else:
        db = client[dbName]
        information = db[collectionName]
        information.insert_many(directoryFilesIteration(path))

checkDBExistance(path, dbName,collectionName)

# for elements in completeCrudDictionary:
#     print(elements)

# df = pd.DataFrame(completeCrudDictionary,index=[i for i in range(0,len(completeCrudDictionary))])
#df.to_excel("Crud.xlsx")



