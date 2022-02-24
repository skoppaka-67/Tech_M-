"""

owner : Bhavya JS

JAVA Variable_impact report

Dependencies: config file with
filepath, collectionname and dbname
which should be changed according to the user

"""

from pymongo import MongoClient
import copy,config,os,json
import pandas as pd


client = MongoClient("localhost", port=27017)
dbname = config.dbname
collectionname=config.variableimpactcn


filespath=config.filespath
extentions=['.jsp','.java','.css','.js']


def getallfiles(filespath, extensions):  # function to return the file paths in the given directory with given extention
    filelist = []
    for root, dirs, files in os.walk(filespath):
        for file in files:
            if file.lower().endswith(tuple([item.lower() for item in extensions])):
                filelist.append(os.path.join(root, file))
    return filelist

def getcomponenttype(file):
    """
    this function is to find extension type for files
    :param filename: passing filename to fetch extension type
    :return: we are returning extension type based on file type
    """
    colname = config.componenttypecn
    col = client[dbname][colname]
    #print(col)
    # file=file.split('\\')[-1]
    component_type = list(col.find({"component_name":file.split('\\')[-1]}, {'_id': 0}))
    component_type = component_type[0]['component_type']
    return component_type


def getallreports(filespath):

     """This function inserts each line into seperate Json by eliminating comment lines. """

     comment_flag=False
     METADATA = []
     files=getallfiles(filespath,extentions)
     #leng=len(files)
     #print(leng)
     for fi in files:
             f=open(fi,"r")
             #print(f)
             for line in f.readlines():
                if line.strip()=="":
                    continue

                if fi.endswith(".js"):
                    if line.strip().__contains__("//"):
                        continue
                    if line.strip().__contains__("/*"):
                        comment_flag = True
                    if line.strip().__contains__("*/"):
                        comment_flag = False
                        continue

                if fi.endswith(".css"):
                    if line.strip().__contains__("/*"):
                          comment_flag=True
                    if line.strip().__contains__("*/"):
                          comment_flag=False
                          continue

                if fi.endswith(".java"):
                    if line.strip().endswith("*/"):
                          comment_flag=False
                          continue
                    if line.strip().startswith("//"):
                          continue
                    if line.strip().startswith("/*"):
                          comment_flag=True


                if fi.endswith('.html') or fi.endswith(".jsp"):
                    if line.strip().startswith("<!--"):
                          comment_flag=True
                    if line.strip().startswith("-->"):
                          comment_flag=False
                          continue
                    if line.strip().__contains__("<!--") and line.__contains__("-->"):
                          continue

                if comment_flag:
                    continue

                vimodal = {"component_name": fi.split("\\")[-1],
                             "component_type": getcomponenttype(fi),
                             "sourcestatements": line
                           }
                METADATA.append(copy.deepcopy(vimodal))
                #print(json.dumps(METADATA, indent=4))
     return METADATA


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
                        "headers": ["component_name", "component_type", "sourcestatements"]})
        col.insert_many(output)
        print("Inserted the list of jsons of", dbname, collectionname)
    else:
        print("There are no jsons in the output to insert in the DB", dbname, collectionname)


if __name__ == '__main__':
     # output = getallreports(filespath)
     # if not os.path.exists("outputs//"):
     #       os.makedirs("outputs//")
     #  #json.dump(output , open('outputs\\variable_impact report.json', 'w'), indent=4)
     # pd.DataFrame(output).to_excel("outputs\\variable_impact report.xlsx", index=False)
     dbinsertfunction(filespath, dbname, collectionname)

