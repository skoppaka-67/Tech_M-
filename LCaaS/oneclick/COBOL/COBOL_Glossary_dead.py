#
#
SCRIPT_VERSION = ""

import os, copy
import json
from pymongo import MongoClient
import pytz
import datetime
import collections
import config

# mongoClient = MongoClient('localhost', 27017)
# db = mongoClient['IMS_COBOL_NEW']
client = MongoClient(config.database_COBOL['hostname'], config.database_COBOL['port'])
db = client[config.database_COBOL['database_name']]

db.glossary.delete_many({})
h = {"type": "metadata", "headers": ["component_name", "Variable", "Business_Meaning", "Dead", "Group_Element"]}
db.glossary.insert_one(h)
time_zone = 'Asia/Calcutta'
tz = pytz.timezone(time_zone)
# path=r'D:\POC\BNSF\COBOL'
# path = r'D:\Lcaas\COBOL_IMS\source_files\COBOL'
path=config.COBOL_codebase_information['code_location']+'\\'+'COBOL'
file_name_var_dict = {}
procedure_divison_storage = []
procedure_divison_dict = {}
procedure_divison_lines = []
grouped_var = {}
dead_dict_list = []
file_result = {}
final_Metadata = []
Metadata = []
Dead_var_list = set()
Alive_Var = set()
file_list_master = []


def file_iterator(path):
    file_list = []
    with os.scandir(path) as files:
        for file in files:
            if file.is_file():
                full_path = path + '\\' + file.name
                file_list.append(full_path)
    return file_list


file_list = file_iterator(path)


def Remove(duplicate):
    final_list = []
    for list_iter in duplicate:
        if list_iter not in final_list:
            final_list.append(list_iter)
    return final_list


def varRelation(file_name):
    procedure_divison_lines = procedure_divison(file_name)
    # open_file = open(r'D:\TW -code\BNSF\DataD_lines.txt').readlines()
    open_file = open('DataD_lines.txt').readlines()

    METADATA = []
    for lines in range(len(open_file)):

        try:
            # print("coming isdie")
            # print(open_file[lines][6:72].strip().split())
            # print("lksdjfsdklf",(open_file[lines][6:72].strip().split()), lines)
            i = 1
            d = {}
            file_result = {"component_name": "",
                           "Variable": "",
                           'Business_Meaning': "",
                           'Dead': "Yes",
                           'Group_Element': ""}

            # if open_file[lines].strip().split()!=[]:
            #     print('###################', open_file[lines])
            #     continue

            if (open_file[lines][6:72].strip().split() != [] and type(
                    int(open_file[lines][6:72].strip().split()[0])) == int and open_file[lines][6:72].strip().split()[
                1].isnumeric() == False and open_file[lines][6:72].strip().split()[1] != 'FILLER'):
                out = []
                act_list = []
                while (i != 0):
                    # print(lines, i)
                    if (open_file[lines - i][6:72].strip().split() != []):
                        if (lines - i > 0):

                            # def fun88(lines):
                            #     if(open_file[lines+1][6:72].strip().split()[0]=="88"):
                            #         out.append(open_file[lines+1][6:72].strip().split()[1])

                            # print(open_file[lines][6:72].strip().split()[0], open_file[lines-i][6:72].strip().split()[0])
                            if (open_file[lines][6:72].strip().split()[0] > open_file[lines - i][6:72].strip().split()[
                                0] and open_file[lines - i][6:72].strip().split()[0] not in act_list and
                                    open_file[lines - i][6:72].strip().split()[0].isalnum()):
                                if (open_file[lines - i][6:72].strip().split() != [] and
                                        open_file[lines - i][6:72].strip().split()[1] != 'FILLER' and
                                        open_file[lines - i][6:72].strip().split()[1] != 'FILLER.'):
                                    # if()
                                    # print("going inside if")
                                    #     print(open_file[lines])
                                    x = open_file[lines - i][6:72].split()[1].strip().replace('.', '')
                                    if (x.isnumeric() != True and open_file[lines - i][6:72].strip().split()[0] != '02'):
                                        out.append(x)
                                    # print(open_file[lines])
                                    act_list.append(open_file[lines - i][6:72].strip().split()[0])
                                    # print("out",out)
                            if (open_file[lines - i][6:72].strip().split()[0] == '01'):
                                # print("going iniside 01")
                                i = 0
                                break
                            i += 1
                        else:
                            i = 0
                            break
                    else:
                        i += 1
                # out.append(open_file[0][9:].strip())
                d[open_file[lines][6:72]] = out
                file_result['component_name'] = file_name.split("\\")[-1]
                if (open_file[lines][6:72].split()[1] != 'FILLER.'):
                    # print(open_file[lines][6:72].split()[1])##= open_file[lines][6:72].split()[1].replace('.','')
                    y = open_file[lines][6:72].strip().split()[1].replace('.', '')
                    file_result['Variable'] = y
                file_result['Group_Element'] = str(out).strip("[").strip("]").replace("'", "")

                # print(json.dumps(procedure_divison_lines,indent=4))
                for k, v in procedure_divison_lines.items():
                    for line in v:
                        # print("line1",line)
                        if line.__contains__(file_result['Variable']):
                            # print(line)
                            file_result['Dead'] = "No"
                            Alive_Var.add(file_result['Variable'])
                            for xy in out:
                                # print(out)

                                # print('goingi inside')
                                Alive_Var.add(xy)
                        else:
                            for var in out:
                                if line.__contains__(var):
                                    # print("line2",line)
                                    file_result["Dead"] = "No"
                                    for xy in out:
                                        Alive_Var.add(xy)

                # print(Alive_Var)
                if file_result['Variable'] in Alive_Var:
                    # print("file result",file_result['Variable'])
                    file_result["Dead"] = "No"

                METADATA.append(file_result)

        except ValueError as e:


            pass
        except IndexError as i:
            print(i)

    # print(Alive_Var)
    # print(json.dumps(METADATA, indent=4))
    for result in METADATA:
        if (result['Variable'] in Alive_Var):
            result['Dead'] = 'No'
    # print(Alive_Var)
    return METADATA


def procedure_divison(file_entry):
    with open(file_entry, 'r') as f:
        content = f.readlines()

        start_falg = False
        procedure_divison_dict.clear()
        procedure_divison_storage.clear()
        for line in content:

            # print(line)
            temp_line = line
            # line = line[6:72]
            if temp_line.replace(" ", "").__contains__("PROCEDUREDIVISION"):
                start_falg = True
                # continue
            try:
                if start_falg:
                    if line[7] == "*" or line.strip() == " ":
                        continue

                    procedure_divison_storage.append(line.strip())
                    # f = open("temp.txt", "w+")
                    # f.write(line.strip)
            except IndexError as e:
                # print(e)
                pass

        procedure_divison_dict[file_entry.split("\\")[-1].strip(".cbl")] = copy.deepcopy(procedure_divison_storage)

        return procedure_divison_dict


def grouping(file_entry):
    with open(file_entry, 'r') as f:
        f1 = open("DataD_lines.txt", "w+")
        file_name_var_dict.clear()
        content = f.readlines()
        start_falg = False
        pre_var = ''
        # read_falg =
        counter = 0
        var_dict = {}
        child_var_list = []

        for line in content:
            temp_line = line
            # line = line[6:72]
            if temp_line.replace(" ", "").__contains__("LINKAGESECTION.") or temp_line.replace(" ", "").__contains__(
                    "PROCEDUREDIVISION"):
                break

            if temp_line.replace(" ", "").__contains__("DATADIVISION."):
                start_falg = True
                continue

            if start_falg:

                # print(line[6:72])
                try:
                    if line[6:72].strip().split()[0] == '77':
                        # print("before ", line)
                        line = line[:6] + line[6:72].replace('77', "01")
                    if line[6:72].strip().split()[0] == '88':
                        # print("before ", line)
                        line = line[:6] + line[6:72].replace('88', "02")

                        # print("after", line)
                        # print(line)
                except Exception as e:
                    pass

                f1.write(line)
                # try:
                #     sp_list = line.split()
                #
                #     if sp_list[0].isnumeric():
                #
                #         if sp_list[1] == "FILLER":
                #             continue
                #
                #         if sp_list[0] == "01" :
                #             counter += 1
                #             var_name = sp_list[1]
                #             if counter > 1:
                #                 var_dict[pre_var] = copy.deepcopy(child_var_list)
                #             pre_var = var_name
                #             child_var_list.clear()
                #             var_name = ""
                #         else:
                #             var = str(sp_list[:2]).replace("[", "").replace("]", "").replace(",", "").replace("'", "")
                #             child_var_list.append(var)
                #             var = ""
                #
                # except Exception as e:
                #         # print(e)
                #         pass

        file_name_var_dict[file_entry.split("\\")[-1].strip(".cbl")] = copy.deepcopy(var_dict)
        # deadVar(file_name_var_dict)
        f1.close()
        return file_name_var_dict


for file_entry in file_list:
    grouped_var = grouping(file_entry)  # creats temp file with var declartion part

    final_Metadata.extend(varRelation(file_entry))
    # print (final_Metadata,file_entry)
    # os.remove(r'D:\TW -code\BNSF\DataD_lines.txt')
    os.remove('DataD_lines.txt')

    # print(json.dumps(final_Metadata,indent=4))
    # print(file_entry.split('\\')[-1])
    file_list_master.append(file_entry.split('\\')[-1])

for d in final_Metadata:
    if d['Dead'] == "Yes":
        dead_dict_list.append(d)
# print(dead_dict_list)

count = collections.Counter([d['component_name'] for d in final_Metadata])
# print (json.dumps(count,indent=4))

count1 = collections.Counter([d['component_name'] for d in dead_dict_list])
# print("DEad_var:",json.dumps(count1,indent=4))


for dict, values in count.items():
    db.master_inventory_report.update_one({"component_name": dict}, {
        "$set": {"no_of_variables": values}})
    # print("no_of_variables Updated")
for dict, values in count1.items():
    db.master_inventory_report.update_one({"component_name": dict}, {
        "$set": {"no_of_dead_variables": values}})
    # print("no_of_dead_variables Updated")

try:
    db.glossary.delete_many({'type': {"$ne": "metadata"}})
except Exception as e:
    print('Error:' + str(e))

# Insert into DB
try:

    db.glossary.insert_many(final_Metadata)
    # updating the timestamp based on which report is called
    current_time = datetime.datetime.now(tz=tz).strftime("%A, %d. %B %Y %I:%M%p")
    if db.glossary.update_one({"type": "metadata"}, {"$set": {"last_updated_on": current_time,
                                                              "time_zone": time_zone,
                                                              # "headers":["component_name","component_type"],
                                                              "script_version": SCRIPT_VERSION
                                                              }}, upsert=True).acknowledged:
        # print('update sucess')
        pass

except Exception as e:
    print('Error:' + str(e))
