"""

owner : Bhavya JS

JAVA comment_line

Dependencies: config file with
filepath, collectionname and dbname
which should be changed according to the user
component_type file has to run before running this, so that we can fetch application name and component type from that

"""

#testing azure push
from pymongo import MongoClient
import copy,config,os,json
import pandas as pd

client = MongoClient("localhost", port=27017)
dbname = config.dbname
collectionname=config.commentreportcn

filespath=config.filespath
extentions=['.jsp','.java','.css','.js']

def getallfiles(filespath, extensions):  # function to return the file paths in the given directory with given extention
    filelist = []
    for root, dirs, files in os.walk(filespath):
        for file in files:
            if file.lower().endswith(tuple([item.lower() for item in extensions])):
                filelist.append(os.path.join(root, file))
    return filelist

def fetch_application(file):
    colname=config.componenttypecn
    col=client[dbname][colname]
    application=list(col.find({"component_name":file.split('\\')[-1]},{'id':0}))
    #print(application)
    application=application[0]['application']
    #print(application)
    return application


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


def getallreports(filespath):
    """ thi function collects all comment lines form a file and
adds it into seperate json"""


    #print(compoCollec)
    METADATA = []
    output1=''
    comment_lines=[]
    comment_flag=False
    files = getallfiles(filespath, extentions)
    for fi in files:
        f = open(fi, "r")
        #print(f)
        for line in f.readlines():

            #print(line)
            if line.strip() == "":
                continue

            if fi.endswith(".js"):
                #print(fi)
                if (line.strip().__contains__('*/') and line.strip().__contains__('/*')):
                    comment_lines.append(line)
                    comment_flag = False
                if line.strip().endswith("*/"):
                    comment_lines.append(line)
                    comment_flag = False
                if comment_flag:
                    comment_lines.append(line)
                    continue
                if line.strip().startswith("/*"):
                    comment_lines.append(line)
                    comment_flag = True
                if line.strip().startswith("//"):
                    comment_lines.append(line)
                    comment_flag = False

            if fi.endswith(".css"):
                 if line.strip().__contains__("*/"):
                     comment_lines.append(line)
                     comment_flag= False
                 if comment_flag:
                     comment_lines.append(line)
                     continue
                 if line.strip().__contains__("/*"):
                     comment_lines.append(line)
                     comment_flag = True


            if fi.endswith(".java"):
                if line.strip().endswith("*/") :
                    comment_lines.append(line)
                    comment_flag = False
                if comment_flag:
                    comment_lines.append(line)
                    continue
                if line.strip().startswith("/*"):
                    comment_lines.append(line)
                    comment_flag = True
                if line.strip().startswith("//"):
                    comment_lines.append(line)
                    comment_flag = False

            if fi.endswith('.html') or fi.endswith(".jsp"):

                  if line.strip().__contains__("<!--") and line.__contains__("-->"):
                     comment_lines.append(line)
                     comment_flag=False

        output1="<br>".join(comment_lines)

        output1={
                "component_type" : getcomponenttype(fi),
                "component_name" : fi.split("\\")[-1],
                "codeString" :output1,
                "application": fetch_application(fi)}

        METADATA.append(copy.deepcopy(output1))

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
                        "headers": ["component_name", "component_type","codeString", "application"]})
        col.insert_many(output)
        print("Inserted the list of jsons of", dbname, collectionname)
    else:
        print("There are no jsons in the output to insert in the DB", dbname, collectionname)


if __name__ == '__main__':
    # output = getallreports(filespath)
    # if not os.path.exists("outputs//"):
    #        os.makedirs("outputs//")
    # # json.dump(output , open('outputs\\cobol_report.json', 'w'), indent=4)
    # pd.DataFrame(output).to_excel("outputs\\cobol_report.xlsx", index=False)
    dbinsertfunction(filespath, dbname, collectionname)


