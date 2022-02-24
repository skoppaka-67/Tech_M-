"""
requirements:
* iterate through all files and fetch the total count of total lines, empty lines,commented lines
  and finally the executable lines
* make a json for each file
"""

import os
import pathlib
import pymongo

client = pymongo.MongoClient('localhost', 27017)
dbName='Csharp'
collectionName='master_inventory_report'

path = 'C:\\Users\jiya\Desktop\Sachin Internship\internship notes\Day 6\Bookstore'
#onlyfiles = [f for f in listdir(path) if isfile(join(path, f)) if f.endswith(".aspx")]

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

def getCommentCount(SingleLineComment,MultiLineStart,MultiLineEnd,line,commentedLines,multipleCommentLineFlag):

    if line.lstrip().startswith(SingleLineComment):
        commentedLines+=1
    if line.lstrip().startswith(MultiLineStart) and MultiLineEnd in line:
        commentedLines += 1
    elif line.lstrip().startswith(MultiLineStart) and MultiLineEnd not in line:
        commentedLines += 1
        multipleCommentLineFlag = True
    elif MultiLineEnd not in line and multipleCommentLineFlag == True and line.split() != []:
        commentedLines += 1
    elif MultiLineEnd in line and multipleCommentLineFlag == True:
        commentedLines += 1
        multipleCommentLineFlag = False

    return commentedLines,multipleCommentLineFlag
def getCommentLineType(fileExtension,line,commentType,commentLine,multipleCommentLineFlag):

    if fileExtension == ".Master":
        return getCommentCount('`~`','<%--',"--%>",line,commentLine,multipleCommentLineFlag)
    elif fileExtension == ".cs":
        return getCommentCount('//', '/*', "*/", line,commentLine,multipleCommentLineFlag)

    elif fileExtension == ".aspx" or fileExtension == ".asax" or fileExtension == ".ascx" :
        if commentType == True:
            return getCommentCount('`~`', '<!--', "-->", line,commentLine,multipleCommentLineFlag)
        else:
            return getCommentCount('`~`', '<%--', "--%>", line,commentLine,multipleCommentLineFlag)

def openFile(file, fileNameAndExtension,name_of_folder):
    empty_line_count=0
    total_lines=0
    commentType=False
    multipleCommentLineFlag=False
    commentLine=0
    requiredFileName= fileNameAndExtension.split(".")[0]
    requiredExtension1=fileNameAndExtension.split(".",1)[1]

    requiredExtensionType=fetchExtensionType(requiredExtension1)
    requiredExtension = pathlib.Path(fileNameAndExtension).suffix
    requiredFile = open(file, "r",encoding="utf8")

    for line in requiredFile: # code to calculate the number of total lines, empty lines and commented lines
        total_lines+=1
        if "<!--" in line :
            commentType=True
        if "<%--" in line:
            commentType=False
        commentLine,multipleCommentLineFlag=getCommentLineType(requiredExtension,line,commentType,commentLine,multipleCommentLineFlag)

        if len(line.strip())==0:
            empty_line_count += 1

    executableLines = total_lines - empty_line_count - commentLine

    case = {'component_name': requiredFileName, 'component_type': requiredExtensionType,
            'Loc': total_lines, 'commented_lines': commentLine,
            "blank_lines": empty_line_count, "Sloc": executableLines,
            "Path": file, 'application': name_of_folder, "orphan": "",
            "Active": "", "execution_details": "", "no_of_variables": "",
            "no_of_dead_lines": "", "cyclomatic_complexity": "",
            "dead_para_count": "", "dead_para_list": "",
            "total_para_count": "", "comments": ""
            }
    print(case)
    return case

def directoryFilesIteration(path):
    masterInventoryReport = []
    for subdir, dirs, files in os.walk(path):
        for filename in files:

            filepath = subdir + os.sep + filename
            a = os.path.normpath(subdir)
            name_of_folder = os.path.basename(a)
            without_extra_slash = os.path.normpath(filepath)
            fileNameAndExtension = os.path.basename(without_extra_slash)
            masterInventoryReport.append(openFile(filepath, fileNameAndExtension,name_of_folder))
    return masterInventoryReport


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

# openFile("C:\\Users\jiya\Desktop\Sachin Internship\internship notes\Day 6\Bookstore\Anonymous\Browsing2.aspx","Browsing2.aspx", "Anonymous")
# openFile("C:\\Users\jiya\Desktop\Sachin Internship\internship notes\Day 6\Bookstore\Anonymous\CheckOut.aspx","CheckOut.aspx", "Anonymous")
# openFile("C:\\Users\jiya\Desktop\Sachin Internship\internship notes\Day 6\Bookstore\Models\IdentityModels.cs","IdentityModels.cs", "Models")
# openFile("C:\\Users\jiya\Desktop\Sachin Internship\internship notes\Day 6\Bookstore\Main\\Site.Master","Site.Master", "Main")
# openFile("C:\\Users\jiya\Desktop\Sachin Internship\internship notes\Day 6\Bookstore\Main\\Global.asax.cs","Global.asax.cs", "Main")
# openFile("C:\\Users\jiya\Desktop\Sachin Internship\internship notes\Day 6\Bookstore\Main\\Site.Mobile.master.cs","Site.Mobile.master.cs", "Main")

