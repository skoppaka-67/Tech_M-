import copy, json, glob, os
from pymongo import MongoClient

client = MongoClient("localhost", port=27017)
db = client["plsql"]
data = db.codebase

METADATA = []
# file = {'D:/plsql/PKB': '*.pkb',
# 'D:/plsql/PkS': '*.pks'}
file = {'D:\\WORK\\plsql\\PKB\\': '*.pkb',
        'D:\\WORK\\plsql\\PKS\\': '*.pks'}
storage = []
storage_file = []
output = ""
output1 = ''


def main():
    for file_location, file_type in file.items():  ##taking key as file location and value as file type in file dictionary
        for filename in glob.glob(os.path.join(file_location,
                                               file_type)):  ##access files one by one that ends with .pkb, and joining file path with folder

            if file_type == "*.pkb":
                Type = "Package Body"
                code_string_procedure(filename)
                code_string_file(filename, Type)
            if file_type == "*.pks":
                Type = "Package Specification"
                code_string_file(filename, Type)


def code_string_procedure(file):
    procedure_name = ''
    f = open(file, 'r')
    a = []

    flag = False
    flag2 = False
    for line in f.readlines():
        if line.strip().startswith('END' + ' ' + procedure_name):
            # print(line)
            storage.append(line)
            output = '<br>'.join(storage)

            data = {

                'component_name': procedure_name,
                'componentype': 'Procedure',
                'codeString': output
            }
            METADATA.append(copy.deepcopy(data))
            storage.clear()
            flag = False
        if line.strip().startswith('PROCEDURE'):
            flag = True
            line.strip()
            a = line.split()
            procedure_name = a[1]
            # print(a[1])
        if line.strip().startswith('/*'):
            flag2 = True
        if line.__contains__('*/'):
            # storage.append('<span style=\"color:green\">' + line + '</span>')
            flag2 = False

        if flag2 and flag:
            storage.append('<span style=\"color:green\">' + line + '</span>')
        if flag and flag2 == False:
            storage.append(line)


def code_string_file(file, Type):
    f = open(file, 'r')
    flag_file = False

    for line in f.readlines():
        if line.strip().startswith('/*'):
            flag_file = True
        if line.__contains__('*/'):
            # storage.append('<span style=\"color:green\">' + line + '</span>')
            flag_file = False

        if flag_file:
            storage_file.append('<span style=\"color:green\">' + line + '</span>')
        if flag_file == False:
            storage_file.append(line)

    output1 = '<br>'.join(storage_file)

    data_file = {

        'component_name': file.split("\\")[-1].split(".")[0],
        'componen_type': Type,
        'codeString': output1
    }
    METADATA.append(copy.deepcopy(data_file))
    storage_file.clear()


# code_string_file('RC_BTS_CYCLE_ADH_PKG.pkb')
main()

print(json.dumps(METADATA, indent=4))
try:
    data.remove()  ## if insert function is executed, prints successful otherwise it will prints fail
    data.insert_one({"type": "metadata",
                     "headers": [
                         "component_name",
                         "component_type",
                         "codeString"

                     ]})
    data.insert_many(METADATA)

    print('data update successful')
except:
    print('fail')

