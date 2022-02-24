"""
JAVA CYCLOMATIC COMPLEXITY
Dependencies: config file with
filepath, collection name and dbname
which should be changed according to the user
***we are updating cyclomatic complexity part of master inventory collection***
"""



import os, glob, copy, json,sys
from os import walk
from os.path import join
from pymongo import MongoClient
import config

client = MongoClient('localhost', 27017)
dbname = config.dbname
db=client[dbname]
collectionname = config.masterinventorycn
filespath = config.filespath
extensions = [".jsp", ".java", ".css", ".js"]


def get_files(filespath, extensions):  # function to return the file paths in the given directory with given extention
    filelist = []
    for r, d, f in walk(filespath):
        for file in f:
            for extension in extensions:
                if file.endswith(extension) and file.count(".") == extension.count("."):
                    filepath = join(r, file)
                    filelist.append(filepath)
    return filelist


def cyclomatic_complexity(filespath):
    """
    1.this function is to fetch lines with if, for, else, switch, do-while, default, while.
    2.cyclomatic complexity will be total count of if, for, else, do-while, default, while lines
    :return: returns cyclomatic complexity for each file
    """
    files = get_files(filespath, extensions)

    METADATA=[]
    cyclomatic_complexity=0
    for file in files:
        loop_count = 0
        condition_count = 0
        doFlag=False
        whileFlag=False
        do_while_count=0

        cyclomatic_complexity = 0
        f = open(file, 'r')
        if file.endswith('.java'):
            for line in f.readlines():
                if line.strip().startswith('for') or line.strip().startswith('while'):
                    #print(line)
                    loop_count=loop_count+1
                if line.strip().startswith('if') or line.strip().startswith('else') or line.strip().startswith('switch') or line.strip().startswith('default'):
                    #print(line)
                    condition_count = condition_count+1
                if line.strip().startswith('do '):
                    #print(line)
                    doFlag=True
                if doFlag and line.strip().startswith('while'):
                    #print(line)
                    whileFlag=True
                if whileFlag and doFlag:
                    do_while_count=do_while_count+1


        cyclomatic_complexity=condition_count+loop_count+do_while_count
        if cyclomatic_complexity==0:
            cyclomatic_complexity=1
        else:
            cyclomatic_complexity=cyclomatic_complexity+1

        output = ({"component_name": file.split('\\')[-1]},
                   {"$set": {"cyclomatic_complexity": cyclomatic_complexity}})
        try:
            db.master_inventory_report.update_one(*output)
            METADATA.append(copy.deepcopy(output))
        except Exception as e:
            exc_type, exc_obj, exc_tb = sys.exc_info()
            fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
            print(exc_type, fname, exc_tb.tb_lineno)

    #print(json.dumps(METADATA,indent=4))



cyclomatic_complexity(filespath)






