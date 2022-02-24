import pymongo
import os
import re
import pathlib
import pandas as pd
from openpyxl.workbook import Workbook

client = pymongo.MongoClient('localhost', 27017)
path = 'C:\\Users\jiya\Desktop\Sachin Internship\internship notes\Day 6\Bookstore'
dbName = 'Csharp'
collectionName = 'master_inventory_report'

def getCommentLine(SingleLineComment,MultiLineStart,MultiLineEnd,line,multipleCommentLineFlag,MultiLineComment):

    if line.lstrip().startswith(SingleLineComment):
        return str(re.split(rf'{SingleLineComment}\s*',line.strip(),1)[1]),multipleCommentLineFlag,''
    if MultiLineStart in line.strip() and MultiLineEnd in line.strip():
        # requiredCommentedLine=str(re.findall(rf'{MultiLineStart} *(.+?) *{MultiLineEnd}',line)[0]).strip()
        requiredCommentedLine = str(line.split(MultiLineStart)[1].strip().split(MultiLineEnd)[0].strip())
        return requiredCommentedLine,multipleCommentLineFlag,''
    if MultiLineStart in line.strip() and MultiLineEnd not in line.strip():
        multipleCommentLineFlag=True # why?
        # MultiLineComment += str(re.findall(r'%s.*'%MultiLineStart,line.strip())[0]).split(MultiLineStart)[1]
        MultiLineComment += str(line.split(MultiLineStart)[1].strip())
    if MultiLineStart not in line.strip() and MultiLineEnd not in line.strip() and multipleCommentLineFlag==True:
        MultiLineComment += line.strip()+" "
    if MultiLineStart not in line.strip() and MultiLineEnd in line.strip() and multipleCommentLineFlag == True:
        multipleCommentLineFlag=False
        # MultiLineComment += str(re.findall(r'.*%s' % MultiLineEnd, line.strip())[0]).split(MultiLineEnd)[0]
        MultiLineComment += str(line.split(MultiLineEnd)[0].strip())
        return MultiLineComment, multipleCommentLineFlag,''
    return '',multipleCommentLineFlag,MultiLineComment

def CommentLineType(fileExtension,line,commentType,multipleCommentLineFlag,MultiLineComment):
    if fileExtension == ".Master":
        # print(getCommentLine('`~`','<%--',"--%>",line,multipleCommentLineFlag,MultiLineComment))
        return getCommentLine('`~`','<%--',"--%>",line,multipleCommentLineFlag,MultiLineComment)

    elif fileExtension == ".cs":
        return getCommentLine('//', '/*', "*/", line,multipleCommentLineFlag,MultiLineComment)

    elif fileExtension == ".aspx" or fileExtension == ".asax" or fileExtension == ".ascx" :
        if commentType == True:
            return getCommentLine('`~`', '<!--', "-->", line,multipleCommentLineFlag,MultiLineComment)

        else:
            return getCommentLine('`~`', '<%--', "--%>", line,multipleCommentLineFlag,MultiLineComment)


def neglectCommentedLines(completeCommentLine, cyclomaticComplexityCount):
    if re.findall(r' if ', completeCommentLine):
        length = len([*re.finditer(r' if ', completeCommentLine)])
        cyclomaticComplexityCount -= length
    if re.findall(r' for ', completeCommentLine):
        length = len([*re.finditer(r' for ', completeCommentLine)])
        cyclomaticComplexityCount -= length
    if re.findall(r' switch ', completeCommentLine):
        length = len([*re.finditer(r' switch ', completeCommentLine)])
        cyclomaticComplexityCount -= length
    if re.findall(r' while ', completeCommentLine):
        length = len([*re.finditer(r' while ', completeCommentLine)])
        cyclomaticComplexityCount -= length
    if re.findall(r' foreach ', completeCommentLine):
        length = len([*re.finditer(r' foreach ', completeCommentLine)])
        cyclomaticComplexityCount -= length
    return cyclomaticComplexityCount


def fetchCyclomaticComplexityCount(path):
    CyclomaticComplexityCountList = []
    global flagFor, flagNext, flagIf,cyclomaticComplexityCount,flagDo,flagWhile
    for subdir, dirs, files in os.walk(path):
        for filename in files:
            filepath = subdir + os.sep + filename
            cyclomaticComplexityCount = 0
            requiredFile = open(filepath, "r", encoding="utf8")

            flagFor = False
            flagNext = False
            flagIf = False
            flagDo=False
            flagWhile=False

            completeCommentLine = ''
            multipleCommentLineFlag = False
            commentType = False
            MultiLineComment = ''
            extensionForCommentType = pathlib.Path(filepath).suffix

            for line in requiredFile:
                if "<!--" in line:
                    commentType = True
                if "<%--" in line:
                    commentType = False
                tempCommentLine, multipleCommentLineFlag, MultiLineComment = CommentLineType(extensionForCommentType,
                                                                                             line, commentType,
                                                                                             multipleCommentLineFlag,
                                                                                             MultiLineComment)
                if tempCommentLine != '' and tempCommentLine != None:
                    completeCommentLine += " " + tempCommentLine
                if (re.search(r'\bif\b', line) or re.search(r'\bIf\b', line)) and ("End If" not in line) and (
                        "else if" not in line and "Else If" not in line):
                    cyclomaticComplexityCount += 1
                    tempString = " ".join(re.findall(r'"([^"]*)"', line.strip()))
                    if re.search(r'\bif\b', tempString):
                        cyclomaticComplexityCount -= 1
                if extensionForCommentType == ".cs":
                    if (" for " in line or " For " in line):
                        flagFor = True
                        cyclomaticComplexityCount += 1
                        tempString = " ".join(re.findall(r'"([^"]*)"', line.strip()))
                        if (" for " in tempString or " For " in tempString):
                            cyclomaticComplexityCount -= 1
                    if (" do " in line or " Do " in line):
                        flagDo = True
                    if (" while " in line or " While " in line):
                        flagWhile = True
                    if flagDo == True and flagWhile == True:
                        cyclomaticComplexityCount += 1
                        flagDo = flagWhile = False
                elif extensionForCommentType == ".aspx":
                    if (" for " in line or " For " in line):
                        flagFor = True
                    if re.search(r' Next ', line, re.IGNORECASE):
                        flagNext = True
                    if flagFor == True and flagNext == True:
                        cyclomaticComplexityCount += 1
                        flagFor = flagNext = False
                else:
                    if (" for " in line or " For " in line):
                        flagFor = True
                        cyclomaticComplexityCount += 1
                        tempString = " ".join(re.findall(r'"([^"]*)"', line.strip()))
                        if (" for " in tempString or " For " in tempString):
                            cyclomaticComplexityCount -= 1
                if (" Switch " in line or " switch " in line):
                    cyclomaticComplexityCount += 1
                    tempString = " ".join(re.findall(r'"([^"]*)"', line.strip()))
                    if (" Switch " in tempString or " switch " in tempString):
                        cyclomaticComplexityCount -= 1
                if (" foreach " in line or " Foreach " in line or " ForEach " in line):
                    cyclomaticComplexityCount += 1
                    tempString = " ".join(re.findall(r'"([^"]*)"', line.strip()))
                    if (" foreach " in tempString or " Foreach " in tempString or " ForEach " in tempString):
                        cyclomaticComplexityCount -= 1
                if (" while " in line or " While " in line):
                    cyclomaticComplexityCount += 1
                    tempString = " ".join(re.findall(r'"([^"]*)"', line.strip()))
                    if (" while " in tempString or " While " in tempString):
                        cyclomaticComplexityCount -= 1

            cyclomaticComplexityCount = neglectCommentedLines(completeCommentLine, cyclomaticComplexityCount)
            CyclomaticComplexityCountList.append(cyclomaticComplexityCount + 1)
    return CyclomaticComplexityCountList


def masterInventoryReportJson(masterInventoryCollection, masterInventory, path):
    tempList = []
    cyclomaticComplexityList = fetchCyclomaticComplexityCount(path)
    for data,count in zip(masterInventory,cyclomaticComplexityList):
        correspondingID={"_id":data['_id']}
        correspondingValue={"$set": {"cyclomatic_complexity": count }}
        masterInventoryCollection.update_one(correspondingID,correspondingValue)

        tempList.append(data)
    df = pd.DataFrame(tempList,index=[i for i in range(0,len(tempList))])
    df.to_excel("CC.xlsx")



def fetchMasterInventoryDB(dbName, collectionName, path):
    db = client[dbName]
    masterInventory = db[collectionName].find()
    masterInventoryCollection = db[collectionName]
    masterInventoryReportJson(masterInventoryCollection, masterInventory, path)

fetchMasterInventoryDB(dbName, collectionName, path)
