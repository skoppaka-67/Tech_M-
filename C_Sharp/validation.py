import pymongo
import os
import re

client = pymongo.MongoClient('localhost', 27017)
path = 'C:\\Users\jiya\Desktop\Sachin Internship\internship notes\Day 6\Bookstore'
dbName = 'Csharp'
collectionName = 'validation_report'


def propertyValidation(data):
    if data['Allowkeys'] != '' and data['ReadOnly'] != '':
        reqdString = "Allowkeys=" + data['Allowkeys'] + "," + "ReadOnly=" + data['ReadOnly']
        return reqdString
    elif data['Allowkeys'] != '' and data['ReadOnly'] == '':
        reqdString = "Allowkeys=" + data['Allowkeys']
        return reqdString
    elif data['Allowkeys'] == '' and data['ReadOnly'] != '':
        reqdString = "ReadOnly=" + data['ReadOnly']
        return reqdString
    else:
        return ''


def validators(data):
    if data["ControlToValidate"] == data["ScreenField"]:
        reqdStringList = []
        if data["Type"] == "RequiredFieldValidator":
            reqdStringList.append(str(data['Type']).split("Validator")[0])
            if data["ErrorMessage"]!='':
                reqdStringList.append(data["ErrorMessage"])
            return ",".join(reqdStringList)
        elif data["Type"] == "CompareValidator":
            reqdStringList.append(str(data['Type']).split("Validator")[0])
            if data["ControlToCompare"]!='':
                reqdStringList.append(data["ControlToCompare"])
            return ",".join(reqdStringList)
        elif data["Type"] == "RangeValidator":
            reqdStringList.append(str(data['Type']).split("Validator")[0])
            if data["ErrorMessage"]!='':
                reqdStringList.append(data["ErrorMessage"])
            if data["MinimumValue"]!='':
                reqdStringList.append((data["MinimumValue"]))
            if data["MaximumValue"]!='':
                reqdStringList.append((data["MaximumValue"]))
            return ",".join(reqdStringList)
        elif data["Type"] == "RegularExpressionValidator":
            reqdStringList.append(str(data['Type']).split("Validator")[0])
            if data["ErrorMessage"]!='':
                reqdStringList.append(data["ErrorMessage"])
            if data["ValidationExpression"]!='':
                reqdStringList.append(data["ValidationExpression"])
            return ",".join(reqdStringList)
    else:
        return ''


def fetchCSFile(name_of_file, application,path):
    for subdir, dirs, files in os.walk(path):
        for filename in files:
            filepath = subdir + os.sep + filename
            if application+"\\"+name_of_file+".cs" in str(filepath):
                # print(filepath)
                return filepath

def CSFileIteration(CSFilePath,screenfield): # add the code for if ---- EndIf
    reqdFile = open(CSFilePath, "r", encoding="utf8")
    reqdString = []
    countIfBlock = 0
    countElseBlock = 0
    countIfBlock2 = 0
    flagEndIf = False
    flagIf = flagElse = False
    bridgeFlag = False
    listOfLinesInCSFile = []
    for line in reqdFile:
        listOfLinesInCSFile.append(line.strip())
    for line in listOfLinesInCSFile:
        if re.findall(r'if %s' % screenfield, line, re.IGNORECASE):
            reqdString.append(line.strip())
            flagIf = True
            if "End If" in listOfLinesInCSFile:
                flagEndIf = True
                countIfBlock2 += 1
            if "{" in line and "}" not in line:
                countIfBlock += 1
            continue
        if flagEndIf == True:
            if "If" in line and "End If" in listOfLinesInCSFile and "End If" not in line:
                countIfBlock2 += 1
                reqdString.append(line.strip())
            if "End If" in line:
                countIfBlock2 -= 1
                reqdString.append(line.strip())
            if "If" not in line and "End If" in listOfLinesInCSFile:
                reqdString.append(line.strip())
        if flagIf == True:
            if ("{" in line and "}" not in line):
                countIfBlock += 1
                reqdString.append(line.strip())
            if ("{" not in line and "}" in line):
                countIfBlock -= 1
                reqdString.append(line.strip())
            if "{" not in line and "}" not in line and "End If" not in listOfLinesInCSFile:
                reqdString.append(line.strip())
        if flagIf == True and countIfBlock == 0:
            if flagEndIf == True and countIfBlock2 == 0 and "End If" in line:
                flagEndIf = False
            elif "End If" not in listOfLinesInCSFile:
                reqdString.append(line.strip())
                bridgeFlag = True
                flagIf = False
        ################
        if re.findall(r'else', line, re.IGNORECASE) and bridgeFlag == True and "End If" not in listOfLinesInCSFile:
            reqdString.append(line.strip())
            flagElse = True
            if "{" in line and "}" not in line:
                countElseBlock += 1
            continue
        if flagElse == True:
            if ("{" in line and "}" not in line):
                countElseBlock += 1
                reqdString.append(line.strip())
            if ("{" not in line and "}" in line):
                countElseBlock -= 1
            if "{" not in line and "}" not in line:
                reqdString.append(line.strip())
        if flagElse == True and countElseBlock == 0:
            reqdString.append(line.strip())
            flagElse = False
            bridgeFlag = False
    if reqdString==[]:
        return ''
    return "<br>".join(reqdString)


def validationReportJson(screenfieldReport,path):
    validationJsonList=[]
    for data in screenfieldReport:
        validationReportDictionary = {}
        validationReportDictionary["filename"] = str(data['filename'])
        validationReportDictionary["Application"] = str(data['application']).upper()
        CSFilePath = fetchCSFile(data['filename'],data['application'],path )
        validationReportDictionary["ScreenField"] = str(data['ScreenField'])
        validationReportDictionary["Type"] = str(data['Type'])
        validationReportDictionary["propertyvalidation"] = propertyValidation(data)
        validationReportDictionary["validators"] =validators(data)
        validationReportDictionary['CodeValidation']=CSFileIteration(CSFilePath,data['ScreenField'])
        # print(validationReportDictionary)
        validationJsonList.append(validationReportDictionary)

    return validationJsonList

def getRecordsFromDB(screenfields,path):
    screenfieldReport = []
    for data in screenfields:
        if data['ScreenField'] != '':
            screenfieldReport.append(data)
    return validationReportJson(screenfieldReport,path)

def checkDBExistence(dbName, collectionName,path):
    global information
    dbnames = client.list_database_names()
    if dbName in dbnames:
        db = client[dbName]
        screenfields = db['screenfields'].find()
        if collectionName in str(db.list_collection_names()):
            information = db[collectionName].drop()
            information = db[collectionName]
            information.insert_many(getRecordsFromDB(screenfields,path))
        else:
            information = db[collectionName]
            information.insert_many(getRecordsFromDB(screenfields,path))
    else:
        db = client[dbName]
        screenfields = db['screenfields'].find()
        information = db[collectionName]
        information.insert_many(getRecordsFromDB(screenfields,path))

checkDBExistence(dbName, collectionName,path)
