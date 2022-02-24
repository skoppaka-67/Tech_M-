"""

owner : Bhavya JS

JAVA crud_report

Dependencies: config file with
filepath, collectionname and dbname
which should be changed according to the user
component_type file has to run before running this, so that we can fetch application name and component type from that

"""


from pymongo import MongoClient
import copy,config,os,json
import pandas as pd


client = MongoClient("localhost", port=27017)
dbname = config.dbname
collectionname=config.crudcn
componentcollection = config.componenttypecn
col2 = client[dbname][componentcollection]

filespath=config.filespath
extentions=['.jsp','.java','.css','.js']

def getallfiles(filespath, extentions):  # function to return the file paths in the given directory with given extention
    filelist = []
    for root, dirs, files in os.walk(filespath):
        for file in files:
            if file.lower().endswith(tuple([item.lower() for item in extentions])):
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
    # file=file.split('\\')[-1]
    component_type = list(col.find({"component_name":file.split('\\')[-1]}, {'_id': 0}))
    component_type = component_type[0]['component_type']
    return component_type


def createFunToDic(file,extentions):

    """This function is used to create a dictionary for each methods in DAO files
      with key as function name and values as list of method lines."""

    output = {}
    function_name = ""
    functions = []
    flag = False
    flag1 = False
    count = 0
    f = open(file, "r")
    fi = file.split("\\")[-1].split(".")[0]
    if fi.endswith("DAO"):

        for line in f.readlines():

            if (line.strip().startswith("protected") or line.strip().startswith("public") or line.strip().startswith("private")) and line.strip().__contains__("(") and line.strip().__contains__(")"):

                    function_name = line.split("(")[0].split()[-1]
                    #print(function_name)
                    flag=True
            if flag and line.strip().__contains__("{"):
                    count += 1
                    flag1 = True
            if flag and line.strip().__contains__("}"):

                    count -= 1

            if flag and flag1 and count == 0:
                    flag=False
                    flag1=False
                    output[function_name]=copy.deepcopy(functions)

                    functions.clear()
            if flag:
                    functions.append(line)
    #print(json.dumps(output,indent=4))
    return output



def identifysql(i,variable):

    """This function captures the sql query from the methods"""

    sql=""
    for line in i:

            if (line.strip().__contains__(variable) and line.strip().__contains__("=")and line.strip().__contains__('"') )or(line.strip().__contains__(variable) and line.strip().__contains__("=")and line.strip().__contains__('"')and line.strip().__contains__('+')):
                sql=sql+line.split(variable)[1].split(";")[0]
                sql=sql.replace("=","",1)
    return sql


def identifyCRUD(sql):

    """This function finds the CRUD operation in the found sql query and returns "READ" if
    select is found in query,similarly "UPDATE" for update query,"CREATE" for insert query,
     "DELETE" for delete query."""

    crud=""
    sql=sql.split('"')[1]

    if sql.strip().lower().startswith("select"):
        crud="READ"
    elif sql.strip().lower().startswith("update"):
        crud="UPDATE"
    elif sql.strip().lower().startswith("insert"):
        crud="CREATE"
    else:
        crud="DELETE"
    return crud

def tablename(sql):

    """This function captures the table name from the given sql query
    i.e. if select is found in sql query then the word next to from will be the table name,
    similarly for update the word next to update will be the table name."""

    table_name=""
    sql = sql.split('"')[1]

    if sql.strip().lower().startswith("select") or sql.strip().lower().startswith("delete"):
        table_name=sql.lower().split("from")[-1].split()[0]
        if table_name.__contains__("("):
            table_name=table_name.split("(")[0]
    elif sql.strip().lower().startswith("insert"):
        table_name=sql.lower().split("into")[-1].split()[0]
        if table_name.__contains__("("):
            table_name=table_name.split("(")[0]
    else:
        table_name = sql.lower().split("update")[-1].split()[0]
    return table_name

def dao_files(filespath,extentions):

   """This function captures the sql query,crud,tablename and function name
   and creates a list of json for DAO files. """

   files=getallfiles(filespath,extentions)
   METADATA = []
   for  file in files:
      items=createFunToDic(file,extentions)
      sql=""
      for item in items:
          for line in items[item]:
              if line.strip().__contains__("prepareStatement") or line.strip().__contains__("executeQuery"):
                  variable = line.split(")")[0].split("(")[-1]
                  if variable.startswith('"'):
                    sql=variable
                  else:
                    i = items[item]
                    sql = identifysql(i,variable)
                    break

          if sql!="":
              output=({"component_name":file.split("\\")[-1].split(".")[0],"component_type":getcomponenttype(file),
                       "function_name":item,
                       "SQL":sql,
                       "CRUD":identifyCRUD(sql),"Table_name":tablename(sql)})
              METADATA.append(copy.deepcopy(output))
              output.clear()
              sql=""
   return METADATA


def getallreports(filespath,extentions):

    """This function reads all the servlet files and finds
    the DAO files triggering point and creates a database for all the files. """
    cursor = list(col2.find({'type': {"$ne": "metadata"}},{"component_name":1,"component_type":1,"application":1,"_id":0}))
    metadata=[]
    crud=dao_files(filespath,extentions)
    files=getallfiles(filespath,extentions)
    name=""
    names=""
    for file in files:
        f=open(file,"r")
        fi = file.split("\\")[-1].split(".")[0]
        if fi.endswith("DAO"):
           continue
        else:
            for line in f.readlines():
                for name in crud:
                    funName = name["function_name"]
                    fName = name["component_name"]
                    fileName = fName.split(".")[0]
                    if line.strip().__contains__(fileName)and line.strip().__contains__("new"):
                            names=line.split("=")[0].split()[-1]

                    if line.strip().__contains__(names +"."+funName+"(") and line.strip().__contains__(")") and line.strip().__contains__(";"):
                            output1=({"component_name":file.split("\\")[-1],
                                      "component_type":getcomponenttype(file),
                                      "calling_app_name" : [item["application"] for item in cursor if item["component_name"] == file.split("\\")[-1]][0],
                                      "CRUD":name["CRUD"],
                                      "SQL":name["SQL"],
                                      "Table":name["Table_name"]})

                            if output1 not in metadata:
                                metadata.append(copy.deepcopy(output1))
                                output1.clear()
                                break
    #print(json.dumps(metadata,indent=4))
    return metadata


def dbinsertfunction(filespath, dbname, collectionname):
    """
    this function is to update database by calling show code and getfiles functions
    :param dbname: database name from config file
    :param collectionname: collectionname from config file
    """

    col = client[dbname][collectionname]
    output = getallreports(filespath,extentions)
    if col.count_documents({}) != 0:
        col.drop()
        print("Deleted the old", dbname, collectionname, "collection")

    col.insert_one({"type": "metadata",
                    "headers": ["component_name", "component_type", "calling_app_name", "CRUD", "SQL","Table"]})
    if output != []:
        col.insert_many(output)
        print("Inserted the list of jsons of", dbname, collectionname)
    else:
        print("There are no jsons in the output to insert in the DB", dbname, collectionname)


if __name__ == '__main__':
    # output = getallreports(filespath,extentions)
    # if not os.path.exists("outputs//"):
    #        os.makedirs("outputs//")
    # # json.dump(output , open('outputs\\crud_report.json', 'w'), indent=4)
    # pd.DataFrame(output).to_excel("outputs\\crud_report.xlsx", index=False)
    dbinsertfunction(filespath, dbname, collectionname)


