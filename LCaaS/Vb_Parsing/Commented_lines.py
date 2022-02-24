# -*- coding: utf-8 -*-
"""
Created on Wed Mar 17 09:58:29 2021

@author: naveen
"""

from os import walk
from os.path import join
import json

from pymongo import MongoClient

client = MongoClient('localhost', 27017)
db = client["vb_update"]
col = db["cobol_output111"]
col2 = db["codebase"]

path = "D:\\WORK\\VB_IMP"  # path for all types of files present in the folder

extentions = {".aspx": ['<!--,-->', '<%--,--%>'],  # different comment syntax for different files
              ".aspx.vb": ["',", ","],
              ".vb": ["',", ","],
              ".js": ['//,', '/*,*/']}

modeldict = {"application": "",  # model json for comment report
             "component_name": "",
             "codeString": ""}

showcodedict = {"component_name": "",  # model json for showcode report
                "component_type": "",
                "codeString": ""}


def getextensionfiles(path, extention):  # function to return the file paths in the given directory with given extention
    filelist = []
    count = extention.count(".")
    for r, d, f in walk(path):
        for file in f:
            if file.endswith(extention) and file.count(".") == count:
                filepath = join(r, file)
                filelist.append(filepath)

    return filelist


def getcomptype(extention):
    if extention == ".aspx":
        return "CODEBEHIND"
    elif extention == ".vb" or extention == ".aspx.vb":
        return "VB"
    elif extention == ".js":
        return "JAVASCRIPT"
    else:
        return ""


def getmultipleline(Lines, index, start2,
                    end2):  # a recursive function to get full commented line if it not present in single line
    line = Lines[index]
    # print(line)
    output = ""
    if end2 in line:
        output = output + " " + line.split(end2)[0].strip()
    else:
        if start2 in line:
            output = output + " " + line.split(start2)[1].strip()
        else:
            output = output + " " + line.strip()
        index = index + 1
        output = output + " " + getmultipleline(Lines, index, start2, end2)
    return output.strip()


def getbothreports(path, extentions):
    alldict = []
    showcodelist = []
    for extention in extentions:
        # print(extention)
        start1 = extentions[extention][0].split(",")[
            0]  # comment syntax for single and mutiline for the given file type
        end1 = extentions[extention][0].split(",")[1]
        start2 = extentions[extention][1].split(",")[0]
        end2 = extentions[extention][1].split(",")[1]
        for filepath in getextensionfiles(path, extention):
            # print('----------------filename :',filepath.split("\\")[-1],'----------------------')
            openFile = open(filepath, encoding="utf8")  # reads file
            Lines = openFile.readlines()

            showcodelines = [line for line in Lines]
            # showcodelines = [line for line in Lines if line]
            showcodelines = list(filter(None, showcodelines))
            if extention == '.aspx':
                # showcodelines = [line for line in showcodelines]
                showcodelines = [line.replace("<","").replace(">","") if showcodelines.index(line)==0 else line.replace("<","").replace(">","") for line in showcodelines]

                showcodelines = [line.replace("<","").replace(">","") for line in showcodelines]
            else:
                showcodelines = [line for line in showcodelines]
            showcode = showcodedict.copy()  # showcode json format
            showcode["component_name"] = filepath.split("\\")[-1]  # filename
            showcode["component_type"] = getcomptype(extention)
            showcode["codeString"] = "<br>".join(showcodelines)
            showcodelist.append(showcode.copy())

            commentlines = []
            Lines = [line.strip() for line in Lines]
            for index, line in enumerate(Lines):  # iterate through lines of file
                if extention == '.aspx':
                    if (start1 in line) or (start2 in line):
                        # print(line)
                        if (start1 in line) and (
                                end1 in line):  # capturing comments based on the single and multiline comments
                            commentlines.append(line.split(start1)[1].split(end1)[0].strip())

                        if (start2 in line) and (end2 in line):
                            commentlines.append(line.split(start2)[1].split(end2)[0].strip())

                        if (start2 in line) and not (end2 in line):
                            commentlines.append(getmultipleline(Lines, index, start2, end2))

                elif extention == '.aspx.vb' or extention == '.vb':
                    if line.startswith(start1):  # capturing comments based on the single and multiline comments
                        # print(line)
                        commentlines.append(line.split(start1)[1].strip())

                elif extention == '.js':  # capturing comments based on the single and multiline comments
                    if (start1 in line) or (start2 in line):
                        # print(line)
                        if start1 in line:
                            commentlines.append(line.split(start1)[1].strip())

                        if (start2 in line) and (end2 in line):
                            commentlines.append(line.split(start2)[1].split(end2)[0].strip())

                        if (start2 in line) and not (end2 in line):
                            commentlines.append(getmultipleline(Lines, index, start2, end2))

            jsondict = modeldict.copy()
            jsondict["component_name"] = filepath.split("\\")[-1]  # filename
            jsondict["application"] = filepath.split("\\")[-2].upper()  # foldername
            jsondict["codeString"] = "<br>".join(commentlines)
            alldict.append(jsondict.copy())

    return {"comment_report": alldict, "showcodelist": showcodelist}


def insertfunc1():  # insert the comment report function
    if col.count() != 0:
        col.drop()
        col.insert_many(getbothreports(path, extentions)["comment_report"])
    else:
        col.insert_many(getbothreports(path, extentions)["comment_report"])


def insertfunc2():  # insert the Showcode report function
    if col2.count() != 0:
        col2.drop()
        col2.insert_many(getbothreports(path, extentions)["showcodelist"])
    else:
        col2.insert_many(getbothreports(path, extentions)["showcodelist"])


# getbothreports(path,extentions)["comment_report"]
# getbothreports(path,extentions)["showcodelist"]

json.dump(getbothreports(path, extentions)["comment_report"], open('Comment_Report_output.json', 'w'), indent=4)
json.dump(getbothreports(path, extentions)["showcodelist"], open('Showcode_Report_output.json', 'w'), indent=4)
insertfunc1()
insertfunc2()