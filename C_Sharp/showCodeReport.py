import os
import pymongo

path = 'C:\\Users\jiya\Desktop\Sachin Internship\internship notes\Day 6\Bookstore'
dbName='Csharp'
collectionName='codebase'
client = pymongo.MongoClient('localhost', 27017)

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

def openFile(file, fileNameAndExtension):
    completeLineList = []
    completeLine = ""
    lineDictionary={}

    requiredFileName = fileNameAndExtension.split(".")[0]
    requiredExtension = fileNameAndExtension.split(".", 1)[1]
    requiredExtensionType = fetchExtensionType(requiredExtension)

    lineDictionary["component_name"]=requiredFileName
    lineDictionary["component_type"]=requiredExtensionType
    requiredFile = open(file, "r", encoding="utf8")
    for line in requiredFile:
        if line.split() !=[]:
            completeLineList.append(line.strip())

    if len(completeLineList)==0:
        completeLine = ""
    else:
        completeLine="<br>".join(completeLineList)

    lineDictionary["codeString"] = completeLine

    return lineDictionary


def directoryFilesIteration(path):
    listOfLines = []
    for subdir, dirs, files in os.walk(path):
        for filename in files:

            filepath = subdir + os.sep + filename
            without_extra_slash = os.path.normpath(filepath)
            fileNameAndExtension = os.path.basename(without_extra_slash)
            listOfLines.append(openFile(filepath, fileNameAndExtension))
    return listOfLines

def checkDBExistance(path, dbName,collectionName):
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
# openFile("C:\\Users\jiya\Desktop\Sachin Internship\internship notes\Day 6\Bookstore\Anonymous\CheckOut.aspx","CheckOut.aspx")
# openFile("C:\\Users\jiya\Desktop\Sachin Internship\internship notes\Day 6\Bookstore\Models\IdentityModels.cs","IdentityModels.cs")

