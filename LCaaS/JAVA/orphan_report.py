"""
owner : Bhavya JS

JAVA orphan report

Dependencies: config file with
filepath, collectionname and dbname
which should be changed according to the user
cross_ref,Master_inventory,component_type files has to run before running this,
 so that we can fetch application name and component type from that
"""

from pymongo import MongoClient
import copy,config,os,json
import pandas as pd

client = MongoClient("localhost", port=27017)
dbname = config.dbname
collectionname=config.orphanreportcn

filespath=config.filespath
extentions=['.jsp','.java','.css','.js']


def getallreports(filespath):
    """This function fetches masterinventory and crossreference
    from DB and stores as list."""

    colname_master = config.masterinventorycn
    colname_xref=config.crossreferencecn
    col_master = client[dbname][colname_master]
    col_xref=client[dbname][colname_xref]

    masterinventory = list(col_master.find({'type': {"$ne": "metadata"}},{"component_name":1,"component_type":1,"application":1,"_id":0}))
    crossref = list(col_xref.find({'type': {"$ne": "metadata"}},{"called_name":1,"called_type":1,"called_app_name":1,"_id":0}))

    return orphanreport(masterinventory,crossref)

def orphanreport(masterinventory,crossref):

    """This function compares crossreference with masterinventory
    and finds the missing data and stores it in list. """

    orphanreports=[]
    master = set()
    Xref=set()
    for i in masterinventory:

        master.add(i["component_name"]+"," +  i["component_type"] + "," +i["application"])
    for j in crossref:
        Xref.add(j["called_name"] +"," +  j["called_type"] + "," +j["called_app_name"])

    for item in master:
        if item not in Xref:
            orphanreports.append(item)
    return orphanreport_json(orphanreports)

def orphanreport_json(orphanreports):

     """This function stores all missing reports in a dictionary"""

     orphanreportJson=[]
     for item in orphanreports:
         orphanreportDict={ }
         component_name=item.split(",")[0]
         component_type=item.split(",")[1]
         application=item.split(",")[2]
         orphanreportDict["called_name"] = component_name
         orphanreportDict["called_type"] = component_type
         orphanreportDict["called_app_name"] = application
         #print(orphanreportDict)
         orphanreportJson.append(orphanreportDict)
     return orphanreportJson


def dbinsertfunction(filespath, dbname, collectionname):
    """
            this function is to update database by calling show code and getfiles functions
            :param dbname: database name from config file
            :param collectionname: collectionname from config file
            """

    col = client[dbname][collectionname]
    output = getallreports(filespath)
    if output != []:
        if col.count_documents({}) != 0:
            col.drop()
            print("Deleted the old", dbname, collectionname, "collection")

        col.insert_one({"type": "metadata",
                        "headers": ["called_name","called_type" ,"called_app_name" ]})
        col.insert_many(output)
        print("Inserted the list of jsons of", dbname, collectionname)
    else:
        print("There are no jsons in the output to insert in the DB", dbname, collectionname)


if __name__ == '__main__':
     # output = getallreports(filespath)
     # if not os.path.exists("outputs//"):
     #      os.makedirs("outputs//")
     # #json.dump(output , open('outputs\\orphan report.json', 'w'), indent=4)
     # pd.DataFrame(output).to_excel("outputs\\orphan report.xlsx", index=False)
     dbinsertfunction(filespath, dbname, collectionname)



