"""
owner : Bhavya JS

JAVA missing report

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
collectionname=config.missingreportcn

filespath=config.filespath
extentions=['.jsp','.java','.css','.js']

def getallreports(filespath):

    """This function fetches masterinventory and crossreference
       from DB and stores as list."""

    colname_master = config.masterinventorycn
    colname_xref=config.crossreferencecn
    col_master = client[dbname][colname_master]
    col_xref=client[dbname][colname_xref]

    masterinventory = list(col_master.find({'type': {"$ne": "metadata"}},{"component_name":1,"component_type":1, "_id":0}))
    crossref = list(col_xref.find({'type': {"$ne": "metadata"}},{"called_name":1,"called_type":1,"_id":0}))

    return Missingreport(masterinventory,crossref)


def Missingreport(masterinventory,crossref):

    """This function compares masterinventory with crossreference
        and finds the missing data and stores it in list. """

    Missingreports=[]
    master = set()
    Xref = set()
    for i in masterinventory:
        master.add(i["component_name"] + "," + i["component_type"])
    for j in crossref:
        Xref.add(j["called_name"] + "," + j["called_type"])

    for item in Xref:
        if item not in master:
            Missingreports.append(item)
    return Missingreport_json(Missingreports)

def Missingreport_json(Missingreports):
     """This function stores all missing reports in a dictionary"""


     MissingreportJson=[]
     for item in Missingreports:
         MissingreportDict={ }
         called_name = item.split(",")[0]
         called_type = item.split(",")[1]

         MissingreportDict["component_name"] = called_name
         MissingreportDict["component_type"] = called_type
         #print(MissingreportDict)
         MissingreportJson.append(MissingreportDict)
     return MissingreportJson


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
                        "headers": ["component_name", "component_type"]})
        col.insert_many(output)
        print("Inserted the list of jsons of", dbname, collectionname)
    else:
        print("There are no jsons in the output to insert in the DB", dbname, collectionname)


if __name__ == '__main__':
     # output = getallreports(filespath)
     # if not os.path.exists("outputs//"):
     #      os.makedirs("outputs//")
     # #json.dump(output , open('outputs\\ missing report.json', 'w'), indent=4)
     # pd.DataFrame(output).to_excel("outputs\\missing report.xlsx", index=False)
     dbinsertfunction(filespath, dbname, collectionname)



