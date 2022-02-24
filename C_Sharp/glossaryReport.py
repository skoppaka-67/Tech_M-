"""
requirements:
* fetch all variables inside all .cs files.
* make a json for each variable
"""

import os
import re
import pymongo

path = 'C:\\Users\jiya\Desktop\Sachin Internship\internship notes\Day 6\Bookstore'
dbName='Csharp'
collectionName='glossary'
client = pymongo.MongoClient('localhost', 27017)


def glossaryJson(setOfVariables,name_of_file):
    glossaryList=[]
    if len(list(setOfVariables)) == 0:
        variableDictionary = {}
        variableDictionary["filename"] = name_of_file
        variableDictionary["variable"] = ""
        variableDictionary["Business_Meaning"] = ""
        glossaryList.append(variableDictionary)

    else:
        for var in setOfVariables:
            variableDictionary = {}
            variableDictionary["filename"] = name_of_file
            variableDictionary["variable"] = var
            variableDictionary["Business_Meaning"] = ""
            glossaryList.append(variableDictionary)
    return glossaryList


def checkEqualTo(reqdFile,name_of_file):
    classObject=set()
    setOfVariables=set()
    # glossaryList=[]
    for line in reqdFile:

        if re.findall(r'\"(.+ += +.+)\"', line): # ignore variables inside quotes
            continue
        """if re.findall(r'\"(.+?)\"',line) !=[]:"""
        if re.findall(r'\w+\.\w+ *= *', line): # aa.bb=cc
            variable = re.findall(r'\w+\.\w+ *=', line)[0].split("=")[0].split(".")[1]
            setOfVariables.add(variable)

        if re.findall(r' \w+ *=',line): # aa bb = cc
            if "For" not in line and "for" not in line : # do not take i in "for i=0; i<10; i++' kind of things

                if re.findall(r'= *new', line,re.IGNORECASE): # Book b = new Book()
                    classObject.add(line.split("=")[0].strip())
                    continue
                else:
                    variable = line.split("=")[0].strip()
                    if len(variable.split()) == 1:
                        if variable in classObject: # b = something
                            pass
                        else:
                            setOfVariables.add(variable)
                    if len(variable.split()) > 1:
                        variable = variable.split()[len(variable.split())-1]
                        if variable in classObject:
                            pass
                        else:
                            setOfVariables.add(variable)
    return glossaryJson(setOfVariables,name_of_file)

def openFile(file, fileNameAndExtension):
    glossaryList=[]
    tempList=[]
    requiredFileName= fileNameAndExtension.split(".")[0]
    reqdFile = open(file, "r", encoding="utf8")
    tempList.append(checkEqualTo(reqdFile,requiredFileName))
    for list1 in tempList:
        for list2 in list1:
            glossaryList.append(list2)
    return glossaryList

def directoryFilesIteration(path):
    completeGlossaryList=[]
    tempGlossaryList=[]
    for subdir, dirs, files in os.walk(path):
        for filename in files:
            filepath = subdir + os.sep + filename
            a = os.path.normpath(subdir)
            name_of_folder = os.path.basename(a)
            without_extra_slash = os.path.normpath(filepath)
            fileNameAndExtension = os.path.basename(without_extra_slash)
            if filepath.endswith(".cs"):
                tempGlossaryList.append(openFile(filepath, fileNameAndExtension))
    for item1 in tempGlossaryList:
        for item2 in item1:
            completeGlossaryList.append(item2)
    print(completeGlossaryList)
    return completeGlossaryList
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

checkDBExistance(path,dbName,collectionName)

# openFile("C:\\Users\jiya\Desktop\Sachin Internship\internship notes\Day 6\Bookstore\Models\IdentityModels.cs", "IdentityModels.cs")

# openFile("C:\\Users\jiya\Desktop\Sachin Internship\internship notes\Day 6\Bookstore\Owner\OwnerAddBook.aspx.cs", "OwnerAddBook.aspx.cs")
