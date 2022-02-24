import json
import os, glob, copy
from pymongo import MongoClient
import pytz
import datetime
METADATA = []
# variable_name = ''
a = []
b = []
# file = {'D:\plsql\PKB': '*.pkb'}
file = {'D:\\WORK\\plsql\\PKB\\': '*.pkb',
        'D:\\WORK\\plsql\\PKS': '*.pks'}

mongoClient = MongoClient('localhost', 27017)
db = mongoClient['plsql']
time_zone = 'Asia/Calcutta'
tz = pytz.timezone(time_zone)

def PerPorcessDB():
    db.glossary.remove()
    h = {"type": "metadata", "headers": ["component_name", "Variable", "Business_Meaning"]}
    db.glossary.insert_one(h)

def main():
    for file_location, file_type in file.items():  ##taking key as file location and value as file type in file dictionary
        for filename in glob.glob(os.path.join(file_location,
                                               file_type)):  ##access files one by one that ends with .pkb, and joining file path with folder

            if file_type == "*.pkb":
                Type = "Package Body"

                glossary_pro(filename)
                glossary_As(filename)
                # #print(filename)

                # #print("Success_pkb")


def glossary_var(file):
    f = open(file, 'r')
    m = []
    variable_name = ''
    comment_flag = False
    flag = False
    for line in f.readlines():
        if line.strip().startswith('PROCEDURE'):
            flag = False
            break
        if line:
            flag = True

        if flag:
            if line.__contains__('VARCHAR') or line.__contains__('NUMBER') or line.__contains__('DATE'):
                # #print(line)
                line.strip()
                m = line.split()
                variable_name = m[0]
                # print(m[0])


def glossary_pro(file):
    flag = False
    flag_as = False
    variable_name = ''

    f = open(file, 'r')

    for line in f.readlines():

        if line.strip().endswith(')') and flag:
            line.strip()
            a = line.split()
            variable_name = a[0]
            output = {
                'variable': variable_name.replace("(",""),
                'component_name': file.split("\\")[-1],
                'Business_Meaning': ''
            }
            METADATA.append(copy.deepcopy(output))
            output.clear()
            ##print(json.dumps(output, indent=4))
            # print(variable_name)

            flag = False
            continue
        if line.strip().startswith('AS') or line.strip().startswith('IS'):
            flag_as = False
            flag = False
            continue

        # if line.strip().startswith('AS') or line.strip().startswith('IS'):
        #     flag=False
        #     continue
        if line.strip().startswith('PROCEDURE'):
            flag = True
            flag_as = True

        if flag and flag_as:
            if line.strip().startswith('--') or line.strip().startswith(':='):
                continue
            if line.strip().startswith('PROCEDURE') and line.__contains__(','):
                line.strip()
                b = line.split()
                variable_name = b[2]
                # print(variable_name)

                output = {
                    'variable': variable_name.replace("(",""),
                    'component_name': file.split("\\")[-1],
                    'Business_Meaning': ''

                }

                METADATA.append(copy.deepcopy(output))
                output.clear()
                ##print(json.dumps(output, indent=4))
                continue

            if line.strip().endswith(','):
                line.strip()
                a = line.split()
                variable_name = a[0]
                # print(variable_name)

                output = {
                    'variable': variable_name.replace("(",""),
                    'component_name': file.split("\\")[-1],
                    'Business_Meaning': ''
                }
                METADATA.append(copy.deepcopy(output))
                output.clear()
            # #print(json.dumps(METADATA,indent=4))


def glossary_As(file):
    flag = False
    flag_pro = False
    bloc_comnt_flag = False
    f = open(file, 'r')
    variable_name = ''
    Exception_List = ["TYPE","IS",":="]

    for line in f.readlines():



        if line.strip().startswith('--') or line.strip() =='':
            continue

        # if line.strip().startswith('/*'):
        #     bloc_comnt_flag = True
        #     continue
        #
        # if bloc_comnt_flag:
        #     continue
        # if line.strip().endswith('*/'):
        #     bloc_comnt_flag = False
        #     continue

        if line.strip().startswith('PROCEDURE'):
            flag_pro = True
        if line.strip().startswith('BEGIN') or line.strip().startswith('CURSOR'):
            flag = False
            flag_pro = False
            continue
        if (line.strip().startswith('AS') or line.strip().startswith('IS'))and flag_pro:
            flag = True
        if flag :

            if line.strip().split()[0] in Exception_List:
                continue


            if line.strip().startswith('--') or line.strip() == '/*' or line.strip() == ');' and line.strip() != '*/':
                continue

            if line.strip().endswith(';') or line.strip().endswith(','):
                line.strip()
                a = line.split()
                variable_name = a[0]


    output = {
        'variable': variable_name.replace("(",""),
        'component_name': file.split("\\")[-1],
        'Business_Meaning': ''
    }

    METADATA.append(copy.deepcopy(output))
        # print(json.dumps(output, indent=4))



# glossary_As('XXCTS_PR2S_ITEM_ORG_ASGN_PKG.pkb')
# glossary_pro('XXCTS_PR2S_ITEM_ORG_ASGN_PKG.pkb')
main()
# print(json.dumps(METADATA, indent=4))
PerPorcessDB()
try:

    db.glossary.insert_many(METADATA)
    # updating the timestamp based on which report is called
    current_time = datetime.datetime.now(tz=tz).strftime("%A, %d. %B %Y %I:%M%p")
    if db.glossary.update_one({"type": "metadata"}, {"$set": {"last_updated_on": current_time,
                                                              "time_zone": time_zone,
                                                              # "headers":["component_name","component_type"],
                                                              "script_version": "v1"
                                                              }}, upsert=True).acknowledged:
        print('update sucess')

except Exception as e:
    print('Errorqqqq:' + str(e))