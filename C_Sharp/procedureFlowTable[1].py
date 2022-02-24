import pymongo
import os
import re

client = pymongo.MongoClient('localhost', 27017)
path = 'E:\pycharm\REPORTS\Bookstore'
dbName = 'Csharp'
collectionName = 'procedure_flow_table'


def fetchFunctionsOfFile(filepath):
    global eachFunctionList
    listOfFunctions = []
    insideSubFunctionFlag = False
    insideNormalFunctionFlag = False
    curlyBracketFlag = False
    curlyBracketsCount = 0
    requiredFile = open(filepath, "r", encoding="utf8")
    for line in requiredFile:
        if "{" in line:
            curlyBracketFlag = True
        if re.search(r'(private|public|Protected)', line, re.IGNORECASE) and re.search(r'\(.*\)', line) and re.search(
                r'Sub', line, re.IGNORECASE):
            eachFunctionList = []
            eachFunctionList.append(line.strip())
            insideSubFunctionFlag = True
            continue
        if re.compile(r'(private)|(public)|(Protected)', re.IGNORECASE).match(line.strip()) and \
                re.search(r'\(.*\)',line) and not re.search(
            r'Sub', line, re.IGNORECASE) and curlyBracketFlag == True:
            eachFunctionList = []
            eachFunctionList.append(line.strip())
            insideNormalFunctionFlag = True
            continue
        if insideSubFunctionFlag == True and not re.search(r'End Sub', line, re.IGNORECASE):
            eachFunctionList.append(line.strip())
        if insideSubFunctionFlag == True and re.search(r'End Sub', line, re.IGNORECASE):
            eachFunctionList.append(line.strip())
            insideSubFunctionFlag = False
            listOfFunctions.append(eachFunctionList)

        if insideNormalFunctionFlag == True:
            if ("{" in line and "}" not in line):
                curlyBracketsCount += 1
                eachFunctionList.append(line.strip())
            if ("{" not in line and "}" in line):
                curlyBracketsCount -= 1
                eachFunctionList.append(line.strip())
            if "{" not in line and "}" not in line:
                eachFunctionList.append(line.strip())
        if insideNormalFunctionFlag == True and curlyBracketsCount == 0:
            insideNormalFunctionFlag = False
            listOfFunctions.append(eachFunctionList)
    return listOfFunctions


def fetchEventFunctions(dictionaryOfAllFunctions, setOfScreenfield):
    dictionaryOfEventFunctions = {}
    for path, element in zip(dictionaryOfAllFunctions, dictionaryOfAllFunctions.values()):
        listOfDictionaryOfEventFunctions = []
        if element != []:
            for item in element:
                firstLineOfFunction = item[0].split()
                for index in firstLineOfFunction:
                    if index.startswith(tuple(setOfScreenfield)):
                        listOfDictionaryOfEventFunctions.append(item)
        if listOfDictionaryOfEventFunctions != []:
            dictionaryOfEventFunctions[path] = listOfDictionaryOfEventFunctions
    return dictionaryOfEventFunctions


def fetchDictionaryOfFunctions(path):
    listOfDictionaryOfFunctions = []
    allFileNamesSet = set()
    for subdir, dirs, files in os.walk(path):
        for filename in files:
            filepath = subdir + os.sep + filename
            if filepath.endswith(".cs"):
                without_extra_slash = os.path.normpath(filepath)
                fileNameAndExtension = os.path.basename(without_extra_slash).split(".")[0]
                allFileNamesSet.add(fileNameAndExtension)
                dictionaryOfFunctions = {}
                dictionaryOfFunctions[filepath] = fetchFunctionsOfFile(filepath)
                listOfDictionaryOfFunctions.append(dictionaryOfFunctions)
    return listOfDictionaryOfFunctions, allFileNamesSet


def checkInternalFunction(eventPath, item, dictionaryOfAllFunctions):
    for allFunctions in dictionaryOfAllFunctions[eventPath]:

        for eachFunction in allFunctions:
            if eachFunction != '':
                if re.compile(r'(private)|(public)|(Protected)', re.IGNORECASE).match(
                        eachFunction) and item in eachFunction:
                    return True, allFunctions, item
                else:
                    continue
    return False, ["", ""], ''


def fetchInternalFunctions(eventName, eventPath, nodesList, linksList, eachEventFunction, dictionaryOfAllFunctions,
                           allFileNamesSet):
    nodesDictionary = {}
    linksDictionary = {}
    for line in range(1, len(eachEventFunction) - 1):
        doubtfullListOfInternalFunctions = set(re.findall(r"\w+\([0-9a-zA-Z_]*\)", eachEventFunction[line]))
        if len(doubtfullListOfInternalFunctions) != 0:
            for item in doubtfullListOfInternalFunctions:
                functionExistance, recusiveIterativeFunction, item = checkInternalFunction(eventPath, item,
                                                                                           dictionaryOfAllFunctions)

                if functionExistance == True:
                    nodesDictionary["id"] = "p_" + item.split("(")[0]
                    nodesDictionary["label"] = item.split("(")[0]
                    linksDictionary["source"] = "p_" + eventName
                    linksDictionary["target"] = "p_" + item.split("(")[0]
                    if nodesDictionary not in nodesList:
                        nodesList.append(nodesDictionary)
                    if linksDictionary not in linksList:
                        linksList.append(linksDictionary)
                    # print(item, "---", recusiveIterativeFunction)
                    fetchExternalFunctions(item, eventPath, nodesList, linksList, recusiveIterativeFunction,
                                           dictionaryOfAllFunctions,
                                           allFileNamesSet)
                else:
                    pass
                if recusiveIterativeFunction != ["", ""]:
                    fetchInternalFunctions(item, eventPath, nodesList, linksList, recusiveIterativeFunction,
                                           dictionaryOfAllFunctions, allFileNamesSet)
    return nodesList, linksList


def checkExternalFunction(dictionaryOfAllFunctions, doubtfulExternalFileName, doubtfulExternalFunction):
    for filePath, allFunctionList in zip(dictionaryOfAllFunctions.keys(), dictionaryOfAllFunctions.values()):
        if doubtfulExternalFileName in filePath:
            for function in allFunctionList:
                if re.compile(r'(private)|(public)|(Protected)', re.IGNORECASE).match(
                        function[0]) and doubtfulExternalFunction in function[0]:
                    return True, function
                else:
                    continue
    return False, ["", ""]


def checkType1ExternalFunctions(eventName, param, fileName, dictionaryOfAllFunctions):
    nodesDictionary = {}
    linksDictionary = {}
    doubtfulExternalCall = re.findall(r'[^0-9a-zA-Z_\'\"/]%s\.\w+' % fileName, param)[0].strip()
    doubtfulExternalFileName = doubtfulExternalCall.split(".")[0]
    doubtfulExternalFunction = doubtfulExternalCall.split(".")[1].split("(")[0]
    functionExistance, recusiveIterativeFunction = checkExternalFunction(dictionaryOfAllFunctions,
                                                                         doubtfulExternalFileName,
                                                                         doubtfulExternalFunction)
    if functionExistance == True:
        nodesDictionary["id"] = "p_" + doubtfulExternalFunction
        nodesDictionary["label"] = doubtfulExternalFunction
        linksDictionary["source"] = "p_" + eventName
        linksDictionary["target"] = "p_" + doubtfulExternalFunction
        linksDictionary["label"] = "External_Program"
    return nodesDictionary, linksDictionary, functionExistance, recusiveIterativeFunction, doubtfulExternalFunction, \
           doubtfulExternalFileName


def checkType2ExternalFunctions(eventName, param, fileName, dictionaryOfAllFunctions):
    nodesDictionary = {}
    linksDictionary = {}
    doubtfulExternalCall = re.findall(r'^%s\.\w+' % fileName, param)[0].strip()
    doubtfulExternalFileName = doubtfulExternalCall.split(".")[0]
    doubtfulExternalFunction = doubtfulExternalCall.split(".")[1].split("(")[0]
    functionExistance, recusiveIterativeFunction = checkExternalFunction(dictionaryOfAllFunctions,
                                                                         doubtfulExternalFileName,
                                                                         doubtfulExternalFunction)
    if functionExistance == True:
        nodesDictionary["id"] = "p_" + doubtfulExternalFunction
        nodesDictionary["label"] = doubtfulExternalFunction
        linksDictionary["source"] = "p_" + eventName
        linksDictionary["target"] = "p_" + doubtfulExternalFunction
        linksDictionary["label"] = "External_Program"
    return nodesDictionary, linksDictionary, functionExistance, recusiveIterativeFunction, doubtfulExternalFunction,\
           doubtfulExternalFileName


def fetchExternalFunctions(eventName, eventPath, nodesList, linksList, eachEventFunction, dictionaryOfAllFunctions,
                           allFileNamesSet):
    recusiveIterativeFunction = ["", ""]
    for fileName in allFileNamesSet:
        for line in eachEventFunction:
            if re.search(r'[^\w_\'\"/]%s\.\w+' % fileName, line.strip()):
                nodesDictionary, linksDictionary, functionExistance, recusiveIterativeFunction, \
                doubtfulExternalFunction, doubtfulExternalFileName = checkType1ExternalFunctions(
                    eventName, line.strip(), fileName, dictionaryOfAllFunctions)

                if nodesDictionary not in nodesList:
                    nodesList.append(nodesDictionary)
                if linksDictionary not in linksList:
                    linksList.append(linksDictionary)
                nodesList, linksList = fetchExternalFunctions(doubtfulExternalFunction, eventPath, nodesList, linksList,
                                                              recusiveIterativeFunction, dictionaryOfAllFunctions,
                                                              allFileNamesSet)
                for requiredPath in dictionaryOfAllFunctions:
                    if "\\" + doubtfulExternalFileName in requiredPath:
                        nodesList, linksList = fetchInternalFunctions(doubtfulExternalFunction, requiredPath, nodesList,
                                                                      linksList, recusiveIterativeFunction,
                                                                      dictionaryOfAllFunctions, allFileNamesSet)

            if re.search(r'^%s\.\w+' % fileName, line):
                nodesDictionary, linksDictionary, functionExistance, recusiveIterativeFunction, \
                doubtfulExternalFunction, doubtfulExternalFileName = checkType2ExternalFunctions(
                    eventName, line.strip(), fileName, dictionaryOfAllFunctions)
                if nodesDictionary not in nodesList:
                    nodesList.append(nodesDictionary)
                if linksDictionary not in linksList:
                    linksList.append(linksDictionary)
                nodesList, linksList = fetchExternalFunctions(doubtfulExternalFunction, eventPath, nodesList, linksList,
                                                              recusiveIterativeFunction, dictionaryOfAllFunctions,
                                                              allFileNamesSet)
                for requiredPath in dictionaryOfAllFunctions:
                    if "\\" + doubtfulExternalFileName in requiredPath:
                        nodesList, linksList = fetchInternalFunctions(doubtfulExternalFunction, requiredPath, nodesList,
                                                                      linksList, recusiveIterativeFunction,
                                                                      dictionaryOfAllFunctions, allFileNamesSet)
    return nodesList, linksList


def makeProcedureFlowTable(dictionaryOfEventFunctions, dictionaryOfAllFunctions, allFileNamesSet):
    procedureFlowTable = []
    for eventPath, eventFunctionsList in zip(dictionaryOfEventFunctions, dictionaryOfEventFunctions.values()):
        without_extra_slashOfEvents = os.path.normpath(eventPath)
        fileNameAndExtensionOfEvents = os.path.basename(without_extra_slashOfEvents)
        for eachEventFunction in eventFunctionsList:
            tempProcedureFlowTable = {}
            nodesList = []
            linksList = []
            tempProcedureFlowTable["component_name"] = fileNameAndExtensionOfEvents
            firstLineOfFunction = eachEventFunction[0]
            eventName = re.findall(r'[0-9a-zA-Z_]+\(.*\)', firstLineOfFunction)[0].strip().split("(")[0]
            tempProcedureFlowTable["event_name"] = eventName
            nodesDictionary = {}
            nodesDictionary["id"] = "p_" + eventName
            nodesDictionary["label"] = eventName
            nodesList.append(nodesDictionary)
            nodesList, linksList = fetchInternalFunctions(eventName, eventPath, nodesList, linksList, eachEventFunction,
                                                          dictionaryOfAllFunctions, allFileNamesSet)
            nodesList, linksList = fetchExternalFunctions(eventName, eventPath, nodesList, linksList, eachEventFunction,
                                                          dictionaryOfAllFunctions, allFileNamesSet)
            tempProcedureFlowTable["nodes"] = nodesList
            tempProcedureFlowTable["links"] = linksList
            procedureFlowTable.append(tempProcedureFlowTable)
            print(tempProcedureFlowTable)
    return procedureFlowTable


def procedure_flow_table(setOfScreenfield, path):
    listOfDictionaryOfFunctions, allFileNamesSet = fetchDictionaryOfFunctions(path)
    dictionaryOfAllFunctions = {}
    for element in listOfDictionaryOfFunctions:
        dictionaryOfAllFunctions.update(element)

    dictionaryOfEventFunctions = fetchEventFunctions(dictionaryOfAllFunctions, setOfScreenfield)
    procedureFlowTableJson = makeProcedureFlowTable(dictionaryOfEventFunctions, dictionaryOfAllFunctions,
                                                    allFileNamesSet)
    return procedureFlowTableJson


def getRecordsFromDB(screenfields, path):
    setOfScreenfield = set()
    for data in screenfields:
        if data['ScreenField'] != '':
            setOfScreenfield.add(data['ScreenField'])
    return procedure_flow_table(setOfScreenfield, path)


def checkDBExistence(dbName, collectionName, path):
    global information
    dbnames = client.list_database_names()
    if dbName in dbnames:
        db = client[dbName]
        screenfields = db['screenfields'].find()
        if collectionName in str(db.list_collection_names()):
            information = db[collectionName].drop()
            information = db[collectionName]
            information.insert_many(getRecordsFromDB(screenfields, path))
        else:
            information = db[collectionName]
            information.insert_many(getRecordsFromDB(screenfields, path))
    else:
        db = client[dbName]
        screenfields = db['screenfields'].find()
        information = db[collectionName]
        information.insert_many(getRecordsFromDB(screenfields, path))


checkDBExistence(dbName, collectionName, path)
