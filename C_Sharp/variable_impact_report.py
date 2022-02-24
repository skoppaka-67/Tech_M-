"""
requirements:
* make a json for each non- empty line
* do not take full commented lines
"""



import os
import re
import pathlib
import pymongo

path = 'C:\\Users\jiya\Desktop\Sachin Internship\internship notes\Day 6\Bookstore'
dbName='Csharp'
collectionName='variable_impact_codebase'
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
def getCommentLine(SingleLineComment,MultiLineStart,MultiLineEnd,line,multipleCommentLineFlag):
    if (line.lstrip().startswith(SingleLineComment)): # single line comment for example: // sdfassagfg
        return '',multipleCommentLineFlag
    if MultiLineStart in line.strip() and MultiLineEnd in line.strip(): # single line comment for example: /* dfasdasg */
        # completeComment="".join(re.split(rf'{MultiLineStart} *.* *{MultiLineEnd}',line.strip()))
        completeComment1= (str(line.strip().split(MultiLineStart)[0]))
        completeComment2=str(line.strip().split(MultiLineEnd)[1])
        completeComment=completeComment1+completeComment2
        return completeComment,multipleCommentLineFlag
    if MultiLineStart in line.strip() and MultiLineEnd not in line.strip():# Multiline comment, for example: /* adsdf \n dfsd */
        multipleCommentLineFlag=True
        completeComment="".join(re.split(rf'{MultiLineStart}.*',line.strip()))
        return completeComment,multipleCommentLineFlag
    if MultiLineStart not in line.strip() and MultiLineEnd not in line.strip() and multipleCommentLineFlag==True:
        return '',multipleCommentLineFlag
    if MultiLineStart not in line.strip() and MultiLineEnd in line.strip() and multipleCommentLineFlag == True:
        multipleCommentLineFlag=False
        completeComment="".join(re.split(rf'.* *{MultiLineEnd}',line.strip()))
        return completeComment, multipleCommentLineFlag
    return line.strip(),multipleCommentLineFlag

def CommentLineType(fileExtension,line,commentType,multipleCommentLineFlag):
    if fileExtension == ".Master":
        return getCommentLine('`~`','<%--',"--%>",line,multipleCommentLineFlag)
    elif fileExtension == ".cs":
        return getCommentLine('//', '/*', "*/", line,multipleCommentLineFlag)
    elif fileExtension == ".aspx" or fileExtension == ".asax" or fileExtension == ".ascx" :
        if commentType == 2:
            return getCommentLine('`~`', '<!--', "-->", line,multipleCommentLineFlag)
        else:
            return getCommentLine('`~`', '<%--', "--%>", line,multipleCommentLineFlag)

def openFile(file, fileNameAndExtension):
    nonCommentLineList=[]
    commentType =1
    multipleCommentLineFlag=False
    requiredFileName = fileNameAndExtension.split(".")[0]
    requiredExtension = fileNameAndExtension.split(".", 1)[1]
    requiredExtensionType = fetchExtensionType(requiredExtension)
    extensionForCommentType = pathlib.Path(fileNameAndExtension).suffix
    requiredFile = open(file, "r", encoding="utf8")
    for line in requiredFile:
        if "<!--" in line :
            commentType=2
        if "<%--" in line:
            commentType=1
        if "/*" in line:
            commentType=3
        if line.split() != []:
            requiredLine,multipleCommentLineFlag=CommentLineType(extensionForCommentType,line,commentType,multipleCommentLineFlag)
            if requiredLine!='':
                nonCommentedLineDictionary = {}
                nonCommentedLineDictionary["component_name"] = requiredFileName
                nonCommentedLineDictionary["component_type"] = requiredExtensionType
                nonCommentedLineDictionary["sourcestatements"]=requiredLine
                nonCommentLineList.append(nonCommentedLineDictionary)
    return nonCommentLineList
def directoryFilesIteration(path):
    completeNonCommentLineList=[]
    nonCommentLines=[]
    for subdir, dirs, files in os.walk(path):
        for filename in files:
            filepath = subdir + os.sep + filename
            # a = os.path.normpath(subdir)
            # name_of_folder = os.path.basename(a)
            without_extra_slash = os.path.normpath(filepath)
            fileNameAndExtension = os.path.basename(without_extra_slash)
            nonCommentLines.append(openFile(filepath, fileNameAndExtension))

    for item1 in nonCommentLines :
        for item2 in item1:
            print(item2)
            completeNonCommentLineList.append(item2)
    return completeNonCommentLineList

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

# openFile("C:\\Users\jiya\Desktop\Sachin Internship\internship notes\Day 6\Bookstore\Main\\Site.Master","Site.Master")
# openFile("C:\\Users\jiya\Desktop\Sachin Internship\internship notes\Day 6\Bookstore\Models\IdentityModels.cs","IdentityModels.cs")
#
# openFile("C:\\Users\jiya\Desktop\Sachin Internship\internship notes\Day 6\Bookstore\Anonymous\Browsing2.aspx","Browsing2.aspx")
# openFile("C:\\Users\jiya\Desktop\Sachin Internship\internship notes\Day 6\Bookstore\Anonymous\CheckOut.aspx","CheckOut.aspx")