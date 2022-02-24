"""

JAVA dead para

Dependencies: config file with
filepath, collectionname and dbname
which should be changed according to the user
component_type file,master inventory has to run before running this, so that we can fetch application name and component type from that
this updates the dead_para_count,dead_para_list,no_of_deadlines in master inventory file.
"""
from pymongo import MongoClient
import copy,config,os,json
import pandas as pd

client = MongoClient("localhost", port=27017)
dbname = config.dbname
db=client[dbname]
collectionname=config.masterinventorycn

filespath=config.filespath
extentions=['.jsp','.java','.css','.js']

def getallfiles(filespath, extensions):
    """
    function to return the file paths in the given directory with given extention
    """
    filelist = []
    for root, dirs, files in os.walk(filespath):
        for file in files:
            if file.lower().endswith(tuple([item.lower() for item in extensions])):
                filelist.append(os.path.join(root, file))
    return filelist


def deadpara_count():
    """This function counts total number of unused private function counts"""
    files = getallfiles(filespath, extentions)
    for file in files:
        functions = []
        dead_para_list = []

        functions.clear()
        dead_para_list.clear()
        no_of_deadlines = 0
        f = open(file, "r")
        if file.endswith(".java"):
            #print(f)
            for line in f.readlines():         ##this loop finds private functions and adds to list
                if line.__contains__("private") and line.__contains__("(") and line.__contains__(")"):
                    private=line
                    functions.append(private)


            for names in functions:              ##this loop finds the dead para functions and their count
                name = names.split("(")[0].split("void")[-1].strip()
                #print(name)
                f.seek(0)
                flag=False
                for line in f.readlines():
                    line=" "+line.strip()
                    if line.__contains__(" "+name+"(") and line.strip().__contains__(",") and line.strip().__contains__(")") and line.strip().__contains__(";"):
                        flag = True
                        break
                if flag==False:
                    dead_para_list.append(name)

            if len(dead_para_list)==0:
                no_of_deadlines=0

            else:
                    f.seek(0)
                    deadflag = False
                    for name in dead_para_list:              ##this function counts no of dead lines
                        count=0
                        #print(name)
                        for line in f.readlines():
                             if line.__contains__("}") and deadflag:
                                 no_of_deadlines+=1
                                 deadflag=False
                             if line.__contains__(name)and line.__contains__("{"):
                                 #print(line)
                                 deadflag=True
                             if deadflag:
                                 no_of_deadlines += 1
        #print(dead_para_list)

        dead_para_count=len(dead_para_list)
        if dead_para_count==0 or dead_para_list==[] or no_of_deadlines==0:
            dead_para_count=""
            dead_para_list=""
            no_of_deadlines=""

        output = ({"component_name": file.split('\\')[-1]},
                  {"$set": {"no_of_dead_lines": no_of_deadlines, "dead_para_count": dead_para_count,
                            "dead_para_list": dead_para_list}})
        db.master_inventory_report.update_one(*output)
        #print(output)

deadpara_count()

