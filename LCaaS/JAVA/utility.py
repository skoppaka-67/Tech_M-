import os
from pymongo import MongoClient
client = MongoClient('localhost', 27017)


def getallfiles(filespath,extensions):#function to return the file paths in the given directory with given extention
    filelist = []
    for root, dirs, files in os.walk(filespath):
        for file in files:
            if file.lower().endswith(tuple([item.lower() for item in extensions])):
                filelist.append(os.path.join(root, file))
    return filelist

def getpropertyvalidation(document,List):
    propertyvalidation = []
    for item in List:
        if item in document.keys():
            if document[item]!="":
                propertyvalidation.append(item+"="+str(document[item]))
                
    return ",".join(propertyvalidation)

def dbinsertfunction(filespath, dbname, collectionname):
    col = client[dbname][collectionname]
    output = getallreports(filespath)
    if col.count_documents({}) != 0:
        col.drop()
        print("Deleted the old", dbname, collectionname, "collection")

    col.insert_one({"type": "metadata",
                    "headers": ["component_name", "component_type", "calling_app_name",
                                "called_name", "called_type", "called_app_name"]})    
    if output != []:
        col.insert_many(output)
        print("Inserted the list of jsons of", dbname, collectionname)
    else:
        print("There are no jsons in the output to insert in the DB", dbname, collectionname)

def dbinsertfunction(filespath,dbname,collectionname):
    col = client[dbname][collectionname]
    output = getallreports(filespath)    
    if output!=[]:   
        if col.count_documents({}) != 0 :
            col.drop()  
            print("Deleted the old",dbname,collectionname,"collection")
            
        col.insert_one({"type" : "metadata",
                        "headers" : ["component_name","component_type","calling_app_name",
                                     "called_name","called_type","called_app_name"]})        
        col.insert_many(output)
        print("Inserted the list of jsons of",dbname,collectionname)
    else:
        print("There are no jsons in the output to insert in the DB",dbname,collectionname)


if __name__ == '__main__':
    output = getallreports(filespath)
    if not os.path.exists("outputs//"):
        os.makedirs("outputs//")
    json.dump(output , open('outputs\\cross_reference.json', 'w'), indent=4)
    pd.DataFrame(output).to_excel("outputs\\cross_reference.xlsx", index=False)     
    dbinsertfunction(filespath,dbname,collectionname)