
import pymongo

client = pymongo.MongoClient('localhost', 27017)
dbName='Csharp'
collectionName='missing_components_report'

def missingReportJson(missingReports):
    missingReportsList=[]
    for item in missingReports:
        missingReportDictionary = {}
        fileName = item.split("!")[0]
        extensionType = item.split("!")[1]
        missingReportDictionary["component_name"] = fileName
        missingReportDictionary["component_type"] = extensionType
        print(missingReportDictionary)
        missingReportsList.append(missingReportDictionary)
    return missingReportsList

def fetchMissingReport(setMasterInventoryFiles,setCrossRefFiles):
    missingReports = []
    for item in setCrossRefFiles:
        if item not in setMasterInventoryFiles:
            missingReports.append(item)
    return missingReportJson(missingReports)


def getRecordsFromDB(masterInventory,crossReference):
    setMasterInventoryFiles = set()
    setCrossRefFiles = set()
    for data in masterInventory:
        setMasterInventoryFiles.add(data['component_name'] + "!" + data['component_type'])
    for data in crossReference:
        if data["called_type"] != "HYPERLINK":
            setCrossRefFiles.add(data['called_name'] + "!" + data['called_type'])
    return fetchMissingReport(setMasterInventoryFiles,setCrossRefFiles)

def checkDBExistance(dbName,collectionName):
    global information
    dbnames = client.list_database_names()
    if dbName in dbnames:
        db = client[dbName]
        masterInventory = db['master_inventory_report'].find()
        crossReference = db['cross_reference_report'].find()
        if collectionName in str(db.list_collection_names()):
            information = db[collectionName].drop()
            information = db[collectionName]
            information.insert_many(getRecordsFromDB(masterInventory,crossReference))
        else:
            information = db[collectionName]
            information.insert_many(getRecordsFromDB(masterInventory,crossReference))
    else:
        db = client[dbName]
        masterInventory = db['master_inventory_report'].find()
        crossReference = db['cross_reference_report'].find()
        information = db[collectionName]
        information.insert_many(getRecordsFromDB(masterInventory,crossReference))

checkDBExistance(dbName,collectionName)

