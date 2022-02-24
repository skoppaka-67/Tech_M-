import pymongo

client = pymongo.MongoClient('localhost', 27017)
db = client['Csharp']
dbName='Csharp'
collectionName='orphan_report'

def orphanReportJson(orphanReports,masterInventoryReport):
    orphanReportList=[]
    for item in orphanReports:
        for data in masterInventoryReport:
            fileName = item.split("!")[0]
            extensionType = item.split("!")[1]

            if data['component_name'] == fileName and data['component_type'] == extensionType:
                orphanReportDictionary = {}
                orphanReportDictionary["component_name"] = fileName
                orphanReportDictionary["component_type"] = extensionType
                orphanReportDictionary["application"] = data["application"]
                print(orphanReportDictionary)
                orphanReportList.append(orphanReportDictionary)
    return orphanReportList


def fetchOrphanReports(setMasterInventoryFiles,setCrossRefFiles,masterInventoryReport):
    orphanReports = []
    for item in setMasterInventoryFiles:
        if item not in setCrossRefFiles:
            orphanReports.append(item)
    return orphanReportJson(orphanReports,masterInventoryReport)


def getRecordsFromDB(masterInventory,crossReference):
    setMasterInventoryFiles = set()
    setCrossRefFiles = set()
    masterInventoryReport=[]
    for data in masterInventory:
        setMasterInventoryFiles.add(data['component_name'] + "!" + data['component_type'])
        masterInventoryReport.append(data)
    for data in crossReference:
        if data["called_type"] != "HYPERLINK":
            setCrossRefFiles.add(data['called_name'] + "!" + data['called_type'])
    return fetchOrphanReports(setMasterInventoryFiles,setCrossRefFiles,masterInventoryReport)

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
