# -*- coding: utf-8 -*-
"""
@author: naveen
"""

import os
from os import walk
from os.path import join
from pymongo import MongoClient

client = MongoClient('localhost', 27017)
db = client["vb"]
col = db["screenfields"]
col2 = db["validation_report"]

base_path = os.path.dirname(os.path.realpath(__file__)) + "\\"
path = base_path + "files"
extentions = {".aspx.vb": ["',", ","]}  # different comment synt


def getextensionfiles(path,
                      extentions):  # function to return the file paths in the given directory with given extention
    filelist = []
    for r, d, f in walk(path):
        for file in f:
            for extention in extentions.keys():
                if file.endswith(extention) and file.count(".") == extention.count("."):
                    filepath = join(r, file)
                    filelist.append(filepath)
    return filelist


def getblockcode(string, Lines):
    blockflag = False
    blocklist = []
    indent = []
    for line in Lines:  # iterate through lines of file
        if line.strip().startswith("If ") and blockflag:
            indent.append(1)
        if line.strip().startswith("End If") and blockflag:
            indent.pop()
        if line.strip().upper().startswith("IF ") and line.__contains__(" " + string):
            print(string)
            blockflag = True
            indent.append(1)
        if blockflag:
            blocklist.append(line)
        if line.strip().startswith("End If") and indent == []:
            blockflag = False

    return blocklist


def getcvreport(path, extentions):
    cursor = list(col.find({}, {"filename": 1, "Application": 1, "ScreenField": 1, "_id": 0}))
    cursor.pop()
    CVlist = {}
    for filepath in getextensionfiles(path, extentions):  # iterate through every file
        print('----------------filename :', filepath.split("\\")[-1], '----------------------')
        Lines = open(filepath, encoding="utf8").readlines()
        file = filepath.split("\\")[-1].split(".")[0] + ".aspx"
        appname = filepath.split("\\")[-2].upper()
        idslist = [item["ScreenField"] for item in cursor if
                   item["filename"] == file and item["Application"] == appname and item["ScreenField"] != ""]
        # idslist =[item["ScreenField"] for item in cursor]
        for ids in idslist:
            # tempdict={}
            # if countstring(filepath,"If "+ids)>=1:
            # print("If "+ids, countstring(filepath,"If "+ids))
            # tempdict[ids]=getblockcode("If "+ids,Lines)
            CVlist[ids + "+" + file.split(".")[0] + "+" + appname] = getblockcode(ids, Lines)

    return CVlist


def validationreport():
    CVlist = getcvreport(path, extentions)
    sfcursor = list(col.find({},
                             {"filename": 1, "Application": 1, "ScreenField": 1, "Type": 1,
                              "Allowkeys": 1, "ReadOnly": 1, "ErrorMessage": 1,
                              "ControlToValidate": 1, "ControlToCompare": 1, "MaximumValue": 1,
                              "MinimumValue": 1, "ValidationExpression": 1, "_id": 0}))
    sfcursor.pop()
    cursorlist = list(col.find({}, {"filename": 1, "Application": 1, "_id": 0}))
    cursorlist.pop()
    cursorlist = list(set([item["filename"].split(".")[0] + "+" + item["Application"] for item in cursorlist]))

    validation_report = {}
    for doc in cursorlist:
        cursor = [item for item in sfcursor if
                  item["filename"].split(".")[0] == doc.split("+")[0] and item["Application"] == doc.split("+")[1]]
        singleoutput = []
        for item in cursor:
            tempdict = {}
            tempdict["filename"] = item["filename"]
            tempdict["Application"] = item["Application"]
            tempdict["ScreenField"] = item["ScreenField"]
            tempdict["Type"] = item["Type"]
            tempdict["propertyvalidation"] = "Allowkeys=" + item["Allowkeys"] + "," + "ReadOnly=" + item["ReadOnly"]
            if tempdict["Type"] == "RequiredFieldValidator":
                tempdict["validators"] = "type=" + item["Type"].replace("Validator", "") + "," + "ErrorMessage=" + item[
                    "ErrorMessage"] + "," + "ControlToValidate=" + item["ControlToValidate"]
            elif tempdict["Type"] == "CompareValidator":
                tempdict["validators"] = "type=" + item["Type"].replace("Validator", "") + "," + "ControlToCompare=" + \
                                         item["ControlToCompare"] + "," + "ControlToValidate=" + item[
                                             "ControlToValidate"]
            elif tempdict["Type"] == "RangeValidator":
                tempdict["validators"] = "type=" + item["Type"].replace("Validator", "") + "," + "MinimumValue=" + item[
                    "MinimumValue"] + "," + "MaximumValue=" + item["MaximumValue"] + "," + "ErrorMessage=" + item[
                                             "ErrorMessage"] + "," + "ControlToValidate=" + item["ControlToValidate"]
            elif tempdict["Type"] == "RegularExpressionValidator":
                tempdict["validators"] = "type=" + item["Type"].replace("Validator",
                                                                        "") + "," + "ValidationExpression=" + item[
                                             "ValidationExpression"] + "," + "ErrorMessage=" + item[
                                             "ErrorMessage"] + "," + "ControlToValidate=" + item["ControlToValidate"]
            elif tempdict["Type"] == "CheckBox":
                tempdict["validators"] = "type=" + item["Type"]
            elif tempdict["Type"] == "ComboBox":
                tempdict["validators"] = "type=" + item["Type"]
            elif tempdict["Type"] == "TextBox":
                tempdict["validators"] = "type=" + item["Type"]
            elif tempdict["Type"] == "DropDownList":
                tempdict["validators"] = "type=" + item["Type"]
            else:
                tempdict["validators"] = ""

            key = item["ScreenField"] + "+" + item["filename"].split(".")[0] + "+" + item["Application"]
            if key in CVlist.keys():
                tempdict["CodeValidation"] = CVlist[key]
            else:
                tempdict["CodeValidation"] = ""
            singleoutput.append(tempdict)

        validation_report[doc] = singleoutput

    return validation_report


def insertfunc():
    if col2.count_documents({}) != 0:
        col2.drop()
        col2.insert_one(validationreport())
    else:
        col2.insert_one(validationreport())


if __name__ == '__main__':
    #    json.dump(validationreport(), open('output_VR.json', 'w'), indent=4)
    insertfunc()
#    docs = pd.DataFrame(list(col2.find({},{"_id":0})))
#    docs.to_excel(base_path+"VR_output.xlsx", index=False)
