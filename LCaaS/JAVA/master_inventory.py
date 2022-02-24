"""
JAVA MASTER INVENTORY REPORT
Dependencies: config file with
filepath, collection name and dbname
which should be changed according to the user
***component_type file has to run before running this, so that we can fetch application name and component type from that***
"""
import os, glob, copy, json
from pymongo import MongoClient
import config
import pandas as pd
import openpyxl

client = MongoClient('localhost', 27017)
dbname = config.dbname
collectionname = config.masterinventorycn
colname_app =config.componenttypecn

filespath = config.filespath
extentions = [".jsp", ".java", ".css", ".js"]


def getallfiles(filespath, extentions):  # function to return the file paths in the given directory with given extention
    filelist = []
    for root, dirs, files in os.walk(filespath):
        for file in files:
            if file.lower().endswith(tuple([item.lower() for item in extentions])):
                filelist.append(os.path.join(root, file))
    return filelist

def fetch_application(file):                   ###function to fetch application name from database

    col = client[dbname][colname_app]
    #file=file.split('\\')[-1]
    application=list(col.find({"component_name" : file.split('\\')[-1]},{'_id':0}))
    application=application[0]['application']
    return application


def getExtensionType(file):             ##this function is to fetch component type from database

    col = client[dbname][colname_app]
    #file=file.split('\\')[-1]
    component_type=list(col.find({"component_name" : file.split('\\')[-1]},{'_id':0}))
    component_type=component_type[0]['component_type']
    return component_type



def total_para_count(file):
    """
    1.this function is to return total para count
    2.we need to fetch functions from java files, so we are searching functions starting private, public and protected in main class
    :return: returns total para count from the file
    """
    f=open(file,'r')
    total_para_count = 0
    #main_flag = False
    if file.endswith('.java'):
        for line in f.readlines():

            if line.strip().startswith('public class') or line.strip().startswith('public interface'):
                #print(line)
                continue
            if line.strip().startswith('public') or line.strip().startswith('private') or line.strip().startswith('protected'):
                if line.__contains__('(') and line.__contains__(')') and not line.__contains__(';'):
                    total_para_count=total_para_count+1

                #print(line)
    if total_para_count==0:
        total_para_count=''

    return total_para_count


def master_inventory(filespath):
    """
    1.this function is to fetch blank lines, comment lines, executable lines, total lines from all java, css, and jsp files
    :return: returns list of jsons for each file.
    """
    files = getallfiles(filespath, extentions)
    file = ''
    METADATA = []

    for file in files:
        comment_lines = 0
        blank_lines = 0
        comment_flag = False
        Sloc = 0
        Loc = 0
        total_lines = []
        block_comments = 0
        html_comment = 0
        html_comment_flag = False
        total_comment_lines = 0
        f = open(file, 'r')
        for line in f.readlines():

            total_lines.append(line)
            if line.strip() == '':
                blank_lines = blank_lines + 1
            if file.strip().endswith('.java'):

                if line.strip().startswith("//"):
                    comment_lines = comment_lines + 1
                if line.strip().__contains__('/*'):
                    comment_flag = True
                if line.strip().__contains__('*/'):
                    block_comments=block_comments+1
                    comment_flag = False
                if comment_flag:
                    block_comments = block_comments + 1
                if line.__contains__('/*') and line.__contains__('*/'):
                    block_comments=block_comments+1
            if file.strip().endswith('.css') or file.strip().endswith('.jsp'):

                if line.strip().__contains__("<!--"):
                    html_comment_flag = True
                if html_comment_flag and line.strip().__contains__("-->"):
                    html_comment_flag = False
                if line.__contains__('<!--') and line.__contains__('-->'):
                    html_comment=html_comment+1
                if html_comment_flag:
                    html_comment = html_comment + 1
        Loc = len(total_lines)
        total_comment_lines = block_comments + html_comment + comment_lines
        Sloc = Loc - total_comment_lines - blank_lines

        output = {"component_name": file.split('\\')[-1], "component_type": getExtensionType(file), "Loc": Loc, "commented_lines": total_comment_lines,
                  "blank_lines": blank_lines, "Sloc": Sloc, "Path": "", "application":fetch_application(file), "orphan": "",
                  "Active": "", "execution_details": "", "no_of_variables": "", "no_of_dead_lines":
                      "", "cyclomatic_complexity": "", "FP": "", "dead_para_count": "", "dead_para_list":
                      "", "total_para_count": total_para_count(file), "comments": ""}
        METADATA.append(copy.deepcopy(output))
        total_lines.clear()
    # print(json.dumps(METADATA,indent=4))
    return METADATA

def dbinsertfunction(dbname, collectionname,filespath):
    """
    this function is to update database by calling show code and getfiles functions
    :param dbname: database name from config file
    :param collectionname: collectionname from config file
    """
    output = master_inventory(filespath)

    #total_files = get_files(filespath,extentions)
    # print(output)
    col = client[dbname][collectionname]
    if output != []:
        if col.count_documents({}) != 0:
            col.drop()
            print("Deleted the old", dbname, collectionname, "collection")

        col.insert_one({"type": "metadata",
                        "headers": [
                            "component_name",
                            "application",
                            "component_type",
                            "total_para_count",
                            "dead_para_count",
                            "no_of_dead_lines",
                            "no_of_variables",
                            "Loc",
                            "Sloc",
                            "blank_lines",
                            "commented_lines",
                            "cyclomatic_complexity",
                            "comments"

                        ]})
        col.insert_many(output)
        print("Inserted the list of jsons of", dbname, collectionname)

    else:
        print("There are no jsons in the output to insert in the DB", dbname, collectionname)

if __name__ == '__main__':
    output = master_inventory(filespath)
    dbinsertfunction(dbname, collectionname,filespath)
    if not os.path.exists("outputs//"):
        os.makedirs("outputs//")
    json.dump(output, open('outputs\\master_inventory.json', 'w'), indent=4)
    pd.DataFrame(output).to_excel("outputs\\master_inventory.xlsx", index=False)
