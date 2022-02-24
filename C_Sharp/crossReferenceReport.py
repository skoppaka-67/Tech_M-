"""
Iterate through each .aspx.cs and .cs files
search for lines having "new" keyword
if the class belongs to collections.generic or SqlClient package, ignore it
create json with called_name, called_type, component_name and component_type
"""
import os
import re
import pymongo
import pathlib
import pandas as pd
from openpyxl.workbook import Workbook


path = 'C:\\Users\jiya\Desktop\Sachin Internship\internship notes\Day 6\Bookstore'
dbName='Csharp'
collectionName='cross_reference_report'
client = pymongo.MongoClient('localhost', 27017)

dictionaryMasterPageFile = {}
dictionaryCodeBehind = {}
dictionaryHref = {}

listOfIgnorableClasses = ["HttpCookie","HttpContextWrapper"]
listOfClassesInCollectionsGeneric = ["Dictionary", "List", "Queue", "SortedList", "Stack", "HashSet", "LinkedList"]
listOfClassesInSqlClient = ["SqlCommand", "SqlConnection", "SqlClientPermission", "SqlException", "SqlBulkCopy"
    , "SqlBulkCopyColumnMapping", "SqlBulkCopyColumnMappingCollection", "SqlClientFactory",
                            "SqlClientMetaDataCollectionNames"
    , "SqlClientPermission", "SqlCommandBuilder", "SqlClientPermissionAttribute", "SqlConnectionStringBuilder",
                            "SqlCredential"
    , "SqlDataAdapter", "SqlDataReader", "SqlDependency", "SqlError", "SqlParameter", "SqlParameterCollection",
                            "SqlTransaction"]

def getDictionary(component_name,component_type,calling_app_name,called_name,called_type,called_app_name):
    tempDictionary={}
    tempDictionary["component_name"] = component_name
    tempDictionary["component_type"] = component_type
    tempDictionary["calling_app_name"] = calling_app_name
    tempDictionary["called_name"] = called_name
    tempDictionary["called_type"] = called_type
    tempDictionary["called_app_name"] = called_app_name
    tempDictionary["dd_name"] = ""
    tempDictionary["access_mode"] = ""
    tempDictionary["step_name"] = ""
    tempDictionary["comments"] = ""
    return tempDictionary


def fetchExtensionType(requiredExtension):
    if requiredExtension == "aspx" or requiredExtension == "asax" or requiredExtension == "ascx" :
        return "WEBFORM"
    elif requiredExtension == "aspx.cs" or requiredExtension == "asax.cs" or requiredExtension == "ascx.cs" :
        return "CODEBEHIND"
    elif requiredExtension == "Master":
        return "MASTERFILE"
    elif requiredExtension == "cs":
        return "CS"
    else:
        return requiredExtension.upper()

def fetchClassName(line,setOfClassName):
    if re.findall(r"= +new", line, re.IGNORECASE):
        className = \
            line.strip().split(re.findall(r"= +new", line, re.IGNORECASE)[0])[1].split("(")[0].split("<")[0].split(
                "[")[0].split()[0]
        if (className in listOfClassesInCollectionsGeneric) or (className in listOfClassesInSqlClient) or (
                className in listOfIgnorableClasses):
            pass
        else:
            setOfClassName.add(className)
    return setOfClassName


def fetchType2CrossReferencing(line,listOfFilesAndParentFolder,requiredFileName, requiredExtensionType, name_of_folder,CodeBehind,MasterPageFile,href,setOfExternalFileNames):
    completeCrossRefereneList=[]
    for elements in range(0, len(listOfFilesAndParentFolder)):
        externalFileNameAndParentFolderList = str(listOfFilesAndParentFolder[elements]).split()[0].split("\\")
        parentFolder = externalFileNameAndParentFolderList[0]

        externalFile = externalFileNameAndParentFolderList[1]
        searchFile = externalFile.split(".")[0]

        extensionOfExternalFile = externalFile.split(".", 1)[1]
        externalFileExtensionType = fetchExtensionType(extensionOfExternalFile)

        if " " + searchFile + "." in line:
            # if re.findall(rf' {searchFile}\.',line):
            if searchFile in setOfExternalFileNames:
                pass
            else:
                setOfExternalFileNames.add(searchFile)
                completeCrossRefereneList.append(getDictionary(requiredFileName, requiredExtensionType, name_of_folder,searchFile, externalFileExtensionType, parentFolder))

        if re.search(r'%s *=' % MasterPageFile, line, re.IGNORECASE):

            calName = line.split(re.findall(r'%s *=' % MasterPageFile, line, re.IGNORECASE)[0])[1].split()[0].replace(
                '"', "").replace("'", "").replace("~/", "")
            tempExtension = fetchExtensionType(calName.split(".", 1)[1])
            if re.findall(r'^%s$' % calName, externalFile, re.IGNORECASE):
                completeCrossRefereneList.append(getDictionary(requiredFileName, requiredExtensionType, name_of_folder,calName, tempExtension,parentFolder))

        if re.search(r'%s *=' % CodeBehind, line, re.IGNORECASE):

            calName = line.split(re.findall(r'%s *=' % CodeBehind, line, re.IGNORECASE)[0])[1].split()[0].replace(
                '"', "").replace("'", "").replace("~/", "")
            tempExtension = fetchExtensionType(calName.split(".", 1)[1])
            if re.findall(r'^%s$' % calName, externalFile, re.IGNORECASE):
                completeCrossRefereneList.append(getDictionary(requiredFileName, requiredExtensionType, name_of_folder, calName,tempExtension,parentFolder))

    if re.search(r'%s *=' % href, line, re.IGNORECASE):
        calName = re.findall(r'"([^"]*)"', line.split(re.findall(r'%s *=' % href, line, re.IGNORECASE)[0])[1])[0]
        completeCrossRefereneList.append(getDictionary(requiredFileName, requiredExtensionType, name_of_folder, calName, "HYPERLINK",name_of_folder))

    return completeCrossRefereneList


def fetchType1CrossReferencing(setOfClassName,listOfFilesAndParentFolder,requiredFileName, requiredExtensionType, name_of_folder):
    completeCrossRefereneList=[]
    for var in setOfClassName:
        for elements in range(0, len(listOfFilesAndParentFolder)):
            if "\\" + var + "." in str(listOfFilesAndParentFolder[elements]):
                externalFileNameAndParentFolderList = str(listOfFilesAndParentFolder[elements]).split()[0].split("\\")

                parentFolder = externalFileNameAndParentFolderList[0]
                externalFileExtension = externalFileNameAndParentFolderList[1].split(".")[1]
                externalFileExtensionType = fetchExtensionType(externalFileExtension)
                completeCrossRefereneList.append(getDictionary(requiredFileName, requiredExtensionType, name_of_folder, var,externalFileExtensionType, parentFolder))
    # print(completeCrossRefereneList)
    return completeCrossRefereneList

def openFile(file, fileNameAndExtension, name_of_folder,listOfFilesAndParentFolder):
    setOfClassName = set()
    setOfExternalFileNames = set()
    completeCrossRefereneList=[]
    requiredFileName=fileNameAndExtension.split(".")[0]
    requiredExtension=fileNameAndExtension.split(".",1)[1]
    requiredExtensionType=fetchExtensionType(requiredExtension)
    MasterPageFile = "MasterPageFile"
    CodeBehind = "CodeBehind"
    href = "href"
    reqFile = open(file, "r", encoding="utf8")
    for line in reqFile:

        setOfClassName=fetchClassName(line,setOfClassName)
        completeCrossRefereneList.append(fetchType2CrossReferencing(line,listOfFilesAndParentFolder,requiredFileName, requiredExtensionType, name_of_folder,CodeBehind,MasterPageFile,href,setOfExternalFileNames))

    if len(list(setOfClassName)) == 0:
        pass
    else:
        completeCrossRefereneList.append(fetchType1CrossReferencing(setOfClassName,listOfFilesAndParentFolder,requiredFileName, requiredExtensionType, name_of_folder))
    if completeCrossRefereneList!=[]:
        return completeCrossRefereneList
    else:
        return

def fetchFilesAndParentFolder():
    listOfFilesAndParentFolder = []
    for subdir, dirs, files in os.walk(path):
        for filename in files:
            filepath = subdir + os.sep + filename
            a = os.path.normpath(subdir)
            name_of_folder = os.path.basename(a)
            without_extra_slash = os.path.normpath(filepath)
            fileNameAndExtension = os.path.basename(without_extra_slash)
            listOfFilesAndParentFolder.append(name_of_folder + "\\" + fileNameAndExtension)
    return listOfFilesAndParentFolder

def directoryFilesIteration(path):
    crossReferenceReport=[]
    tempReport = []
    for subdir, dirs, files in os.walk(path):
        for filename in files:
            filepath = subdir + os.sep + filename
            a = os.path.normpath(subdir)
            name_of_folder = os.path.basename(a)
            without_extra_slash = os.path.normpath(filepath)
            fileNameAndExtension = os.path.basename(without_extra_slash)
            listOfFilesAndParentFolder=fetchFilesAndParentFolder()
            tempReport.append(openFile(filepath, fileNameAndExtension, name_of_folder,listOfFilesAndParentFolder))

    for item1 in tempReport:
        for item2 in item1:
            for item3 in item2:
                if item3!=[]:
                    crossReferenceReport.append(item3)
                    print(item3)

    return crossReferenceReport


def checkDBExistance(path,dbName, collectionName):
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


checkDBExistance(path,dbName, collectionName)

# openFile("C:\\Users\jiya\Desktop\Sachin Internship\internship notes\Day 6\Bookstore\Main\\Site.Mobile.Master","Site.Mobile.Master", "Main")
# openFile("C:\\Users\jiya\Desktop\Sachin Internship\internship notes\Day 6\Bookstore\Anonymous\\Receipt.aspx","Receipt.aspx", "Anonymous")
# openFile("C:\\Users\jiya\Desktop\Sachin Internship\internship notes\Day 6\Bookstore\BL_Component\\BusinessLogic.cs","BusinessLogic.cs", "BL_Component")


# df = pd.DataFrame(completeCrossRefereneList,index=[i for i in range(0,len(completeCrossRefereneList))])
# df.to_excel("CrossRef.xlsx")