"""
JAVA validation Report
Dependencies: config file with
filepath, collection name and dbname
which should be changed according to the user
"""

import os, copy, json
import config
from pymongo import MongoClient
import pandas as pd
import openpyxl

client = MongoClient('localhost', 27017)

dbname = config.dbname
collectionname = config.validationreportcn
validation_tags = ['required', 'maxlength', 'pattern']
# test_path=r"D:\Lcaas_java\Requirements\test_files\validation"


filespath = config.filespath
extentions = [".jsp", ".js"]


def getallfiles(filespath, extentions):  # function to return the file paths in the given directory with given extention
    filelist = []
    for root, dirs, files in os.walk(filespath):
        for file in files:
            if file.lower().endswith(tuple([item.lower() for item in extentions])):
                filelist.append(os.path.join(root, file))
    return filelist


def get_screenfield_data():
    """
    1.In this function we are getting screenfield data from database
    2.If screenfield is not empty then we are creating json for validation report
    :return: returns validation report json's for non empty screen fields
    """
    col = client[dbname]['screenfields']
    validation_dict = {}
    output = []
    screenfields_list = []
    screenfileds_data = list(col.find({'type': {"$ne": "metadata"}},
                                      {'_id': 0, 'application': 1, 'filename': 1,'Tagname':1,'screenfield': 1, 'required': 1,
                                       'maxlength': 1, 'pattern': 1}))
    for data in screenfileds_data:
        if data['screenfield'] != '':
            # print(data['screenfield'])
            screenfields_list.append(data)
            validation_dict['filename'] = data['filename']
            validation_dict['application'] = data['application']
            validation_dict['Tagname'] = data['Tagname']
            validation_dict['screenfield'] = data['screenfield']
            validation_dict['propertyvalidation'] = property_validation(data,validation_tags)
            validation_dict['CodeValidation'] = code_validators(data)
            output.append(copy.deepcopy(validation_dict))
            validation_dict.clear()
    #
    # print(json.dumps(output, indent=4))
    # print(len(output))
    # print(len(screenfields_list))
    return output


# def property_validation(record):
#     """
#     In this function we are adding non empty validation properties.
#     :param record: record is a non empty screenfield json
#     :return: returns a string by adding validation properties
#     """
#     validation_property = ''
#     if record['pattern'] == '' and record['maxlength'] == '' and record['required'] == '':
#         validation_property = ''
#     if record['pattern'] != '' and record['maxlength'] != '' and record['required'] != '':
#         validation_property = "pattern=" + record["pattern"] + "," + 'maxlength=' + record[
#             'maxlength'] + "required=" + str(record["required"])
#
#     if record['pattern'] != '' and record['maxlength'] != '' and record['required'] == '':
#         validation_property = "pattern=" + record["pattern"] + "," + "malength=" + record[
#             'maxlength']
#
#     if record['pattern'] != '' and record['maxlength'] == '' and record['required'] != '':
#         validation_property = "pattern=" + record["pattern"] + "," + "required=" + str(
#             record["required"])
#
#     if record['pattern'] == '' and record['maxlength'] != '' and record['required'] != '':
#         validation_property = "maxlength=" + record["maxlength"] + "," + "required=" + str(
#             record["required"])
#
#     if record['pattern'] != '' and record['maxlength'] == '' and record['required'] == '':
#         validation_property = "pattern=" + record["pattern"]
#
#     if record['pattern'] == '' and record['maxlength'] != '' and record['required'] == '':
#         validation_property = "maxlength=" + record["maxlength"]
#
#     if record['pattern'] == '' and record['maxlength'] == '' and record['required'] != '':
#         validation_property = "required=" + str(record["required"])
#     return validation_property


def property_validation(document, List):
    propertyvalidation = []
    for item in List:
        if item in document.keys():
            if document[item] != "":
                propertyvalidation.append(item + "=" + str(document[item]))

    return ",".join(propertyvalidation)


def code_validation(id, file):
    """
    This function searches for script tag and src attribute in jsp files and if there is any if block with screenfiled id then
    we are fetching that if block.
    :param id: id is creenfield
    :param file: jsp file having that screenfield
    :return: returns a list of if block , if present otherwise it returns a empty string
    """
    f = open(file, 'r')
    screenfield = id
    js_files = getallfiles(filespath, extentions=['.js'])
    codeValidation = []
    script_flag = False
    if_flag = False
    if_script_list=[]
    count = 0
    for line in f.readlines():
        if line.__contains__('<script>'):
            script_flag = True
            # print(line,file)

        if line.__contains__('</script'):
            # print(line)
            script_flag = False
        if script_flag:
            if line.__contains__('if') and line.__contains__(screenfield):
                print(line)
                if_flag = True
            if if_flag:
                if_script_list.append(line)
                if line.__contains__('{'):
                    count += 1
                if line.__contains__('}'):
                    count -= 1

                    if count == 0 and if_flag:
                        if_flag = False
                        codeValidation = if_script_list


        if line.__contains__('script') and line.__contains__('src'):
            if_js_flag = False
            if_js_count = 0
            if_js_list = []
            for js_file in js_files:
                # print(js_file)
                if line.__contains__('js/' + js_file.split("\\")[-1]) and not line.__contains__('http'):
                    file_js = open(js_file)
                    for line in file_js.readlines():
                        if line.strip().startswith('if') and line.__contains__(screenfield):
                            # print(line)
                            if_js_flag = True
                        if if_js_flag:
                            if_js_list.append(line)
                            if line.__contains__('{'):
                                if_js_count += 1
                            if line.__contains__('}'):
                                if_js_count -= 1
                                if if_js_count == 0 and if_js_flag:
                                    if_js_flag = False
                                    if if_js_list == []:
                                        codeValidation = ''
                                    else:
                                        codeValidation = if_js_list

    return codeValidation


def code_validators(record):
    """
    this function is to take non empty screenfield and fetching particular file where screenfield is present
    :param record: non empty screenfiled json
    :return: returns a code validation list or empty string if not present
    """
    result = []
    validation_code = []
    files = getallfiles(filespath, extentions)

    if record['screenfield'] != '':
        for file in files:
            if file.split("\\")[-1] == record['filename']:
                result = code_validation(record['screenfield'], file)
                if result != []:
                    validation_code = result

                if result == []:
                    validation_code = str('')
    return validation_code


def dbinsertfunction(dbname, collectionname):
    """
    this function is to update database by calling show code and getfiles functions
    :param dbname: database name from config file
    :param collectionname: collectionname from config file
    """
    output = get_screenfield_data()

    # print(output)
    col = client[dbname][collectionname]
    if output != []:
        if col.count_documents({}) != 0:
            col.drop()
            print("Deleted the old", dbname, collectionname, "collection")

        col.insert_one({"type": "metadata",
                        "headers": [
                            "filename",
                            "application",
                            "Tagname",
                            "screenfield",
                            "propertyvalidation",
                            "CodeValidation"

                        ]})
        col.insert_many(output)
        print("Inserted the list of jsons of", dbname, collectionname)

    else:
        print("There are no jsons in the output to insert in the DB", dbname, collectionname)


if __name__ == '__main__':
    #output = get_screenfield_data()
    dbinsertfunction(dbname, collectionname)
    #pd.DataFrame(output).to_excel("outputs\\validation_report.xlsx", index=False)
    #json.dump(output, open('outputs\\validation_report.json', 'w'), indent=4)