import re
from builtins import print
import csv
import json
import glob, os
import os.path
from os import path
import requests,pytz,datetime
import shutil
import config
from pymongo import MongoClient

# cbl_org_path = "D:\\POC\\BNSF"
cbl_org_path = config.COBOL_codebase_information['code_location']
client = MongoClient(config.database_COBOL['hostname'], config.database_COBOL['port'])
db = client[config.database_COBOL['database_name']]
data = []
time_zone = 'Asia/Calcutta'
tz = pytz.timezone(time_zone)

#  Removing unwanted spaces and linebreaks in the lines.
def remove_space(item):
    # Removing all space and linebreaks by one space
    data_space_replace = re.sub(r"\s+", " ", item)
    # splitting it by line breaks
    data_line_break = re.sub(r"EXEC SQL", "\nEXEC SQL", data_space_replace)
    cleaned_line = data_line_break.replace("EXEC SQL ", program_name + ",")
    final_cleaned_line = cleaned_line.replace("END-EXEC.", "") or cleaned_line.replace("END-EXEC", "")
    temp_file.write(final_cleaned_line)


# writing a function to find between,before and after values
def between(value, a, b):
    # Find and validate before-part.
    pos_a = value.find(a)
    if pos_a == -1: return ""
    # Find and validate after part.
    pos_b = value.rfind(b)
    if pos_b == -1: return ""
    # Return middle part.
    adjusted_pos_a = pos_a + len(a)
    if adjusted_pos_a >= pos_b: return ""
    return value[adjusted_pos_a:pos_b]


def after(value, a):
    # Find and validate first part.
    pos_a = value.rfind(a)
    if pos_a == -1: return ""
    # Returns chars after the found string.
    adjusted_pos_a = pos_a + len(a)
    if adjusted_pos_a >= len(value): return ""
    return value[adjusted_pos_a:]


def before(value, a):
    # Find first part and return slice before it.
    pos_a = value.find(a)
    if pos_a == -1: return ""
    return value[0:pos_a]


def countOccurences(str, word):
    # split the string by spaces in a
    a = str.split(" ")
    # search for pattern in a
    count = 0
    for i in range(0, len(a)):
        # if match found increase count
        if (word == a[i]):
            count = count + 1
    return count


def process(l, options):

    spilted_line = line.split("SELECT ")
    #print(spilted_line,"Splitted line from process")
    for item in spilted_line:
        if options == "UPDATE":
            if " SET " in line:
                update_string = between(line, "UPDATE", " SET ")

                if update_string.__contains__(","):
                    split_string = update_string.split(",")

                    count = update_string.count(",")

                    for item in range(count + 1):

                        if split_string[item] == " ":
                            #print("Space")
                            pass
                        else:
                            data.append(dict(component_name=program_name, component_type=program_type,
                                             Table=split_string[item].strip(), CRUD="UPDATE",
                                             SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))

                else:
                    data.append(dict(component_name=program_name, component_type=program_type,
                                     Table=update_string.strip(), CRUD="UPDATE",
                                     SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))
            else:
                # print("there is no set")
                pass
        elif options == "INSERT":
            insert_string = after(line, " INTO ")

            spilted_insert_string = insert_string.split(" ")

            data.append(dict(component_name=program_name, component_type=program_type,
                             Table=spilted_insert_string[0].strip(), CRUD="CREATE",
                             SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))
        elif options == "DELETE":
            delete_string = between(line, " FROM ", " WHERE ")

            if delete_string.__contains__(","):
                split_string = delete_string.split(",")

                count = delete_string.count(",")

                for item in range(count + 1):

                    if split_string[item].strip() == "":
                        # print("Space")
                        pass
                    else:
                        data.append(dict(component_name=program_name, component_type=program_type,
                                         Table=split_string[item].strip(), CRUD="DELETE",
                                         SQL=line.rstrip().replace(program_name, "").replace("END-EXEC","")))

            else:
                if delete_string.strip() == "":
                    #print("Space")
                    pass
                else:
                    data.append(dict(component_name=program_name, component_type=program_type,
                                 Table=delete_string.strip(), CRUD="DELETE",
                                 SQL=line.rstrip().replace(program_name, "").replace("END-EXEC","")))

        elif item.__contains__("FROM") and item.__contains__("WHERE"):
            select_string = between(item, " FROM ", " WHERE ")
            select_string= select_string.strip()
            #print(select_string, "item contains From and where")
            if select_string.__contains__("JOIN"):
                #print("Select String", select_string)
                sp_string = select_string.strip().split("LEFT")
                #print("Sp_string", sp_string)
                spilted_string = select_string.split(" ")
                #print("Splited String", spilted_string)
                if spilted_string[0].strip() != "":

                    data.append(
                    dict(component_name=program_name, component_type=program_type,
                         Table=spilted_string[0], CRUD="READ",
                         SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))
                if countOccurences(select_string,"JOIN") > 1:
                    spilted_string = select_string.split("JOIN")
                    #print(spilted_string)
                    for item in spilted_string:
                        #print(item)
                        if item.__contains__("ON"):
                            spilted_string = before(item.strip(),"ON")
                            #print(spilted_string)

                            if spilted_string.__contains__(" ") and spilted_string.__contains__(","):
                                split_string = spilted_string.split(",")
                                count_comma = spilted_string.count(",")

                                for item in range(count_comma + 1):
                                    if split_string[item].strip() == "":
                                        #print("space")
                                        pass
                                    else:
                                        if split_string[item].strip().__contains__(" "):
                                            split_string_spaced = split_string[item].strip().split(" ")
                                            if split_string_spaced[0] != "" and split_string_spaced[0] != "(":
                                                data.append(
                                                dict(component_name=program_name, component_type=program_type,
                                                     Table=split_string_spaced[0], CRUD="READ",
                                                     SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))

                            elif spilted_string.__contains__(",") and not spilted_string.__contains__(" "):
                                sp_string = spilted_string.split(",")
                                count_comma = spilted_string.count(",")
                                for item in range(count_comma + 1):
                                    if sp_string[item].strip() == "":
                                        # print("space")
                                        pass
                                    else:
                                        data.append(
                                            dict(component_name=program_name, component_type=program_type,
                                                 Table=sp_string[item].strip(), CRUD="READ",
                                                 SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))

                            elif spilted_string.__contains__(" ") and not spilted_string.__contains__(","):
                                split_string = spilted_string.split(" ")
                                if split_string[0].strip() != "" and split_string[0].strip() != "(":
                                    data.append(dict(component_name=program_name, component_type=program_type,
                                                 Table=split_string[0].strip(), CRUD="READ",
                                                 SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))

                            else:
                                if split_string_spaced.strip() != "" and split_string_spaced.strip() != "(":
                                    data.append(dict(component_name=program_name, component_type=program_type,
                                                 Table=spilted_string.strip(), CRUD="READ",
                                                 SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))

            elif countOccurences(select_string, " WHERE ") < 1:
                #print(select_string, "inside from & where")
                if select_string.__contains__(" ") and select_string.__contains__(","):
                    split_string = select_string.strip().split(",")
                    #print(split_string)

                    count_comma = select_string.count(",")

                    for item in range(count_comma + 1):
                        if split_string[item].strip() == "":
                            #print("space")
                            pass
                        else:
                            if split_string[item].strip().__contains__(" "):
                                split_string_spaced = split_string[item].strip().split(" ")
                                if split_string_spaced[0].strip() != "" and split_string_spaced[0].strip() != "(":
                                    data.append(
                                    dict(component_name=program_name, component_type=program_type,
                                         Table=split_string_spaced[0], CRUD="READ",
                                         SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))

                elif select_string.__contains__(",") and not select_string.__contains__(" "):
                    sp_string = select_string.strip().split(",")
                    #print(sp_string)

                    count_comma = select_string.count(",")
                    for item in range(count_comma + 1):
                        if sp_string[item].strip() == "":
                            #print("space")
                            pass
                        else:
                            data.append(dict(component_name=program_name, component_type=program_type,
                                             Table=sp_string[item].strip(), CRUD="READ",
                                             SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))

                elif select_string.__contains__(" ") and not select_string.__contains__(","):
                    split_string = select_string.strip().split(" ")
                    #print(split_string)
                    if split_string[0].strip() == "":
                        #print("Space")
                        pass
                    else:
                        data.append(dict(component_name=program_name, component_type=program_type,
                                     Table=split_string[0].strip(), CRUD="READ",
                                     SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))

                else:
                    #print("Yes it came to else part")
                    #print(select_string.strip())
                    if select_string.strip() == "":
                        #print("Space")
                        pass
                    else:
                        data.append(dict(component_name=program_name, component_type=program_type,
                                     Table=select_string.strip(), CRUD="READ",
                                     SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))
            else:
                re_string = select_string.replace("WHERE", "WHERE PYTHON")
                sp_string = re_string.split(" PYTHON ")
                #print(sp_string,"Splitted string in Multi where")
                for str in sp_string:
                    if str.__contains__("FROM"):
                        spilted_string = after(str, " FROM ")
                        if spilted_string.__contains__(" ") and spilted_string.__contains__(","):
                            split_string = spilted_string.split(",")
                            count_comma = spilted_string.count(",")

                            for item in range(count_comma + 1):
                                if split_string[item].strip() == "":
                                    #print("space")
                                    pass
                                else:
                                    if split_string[item].strip().__contains__(" "):
                                        split_string_spaced = split_string[item].strip().split(" ")
                                        data.append(
                                            dict(component_name=program_name, component_type=program_type,
                                                 Table=split_string_spaced[0], CRUD="READ",
                                                 SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))

                        elif spilted_string.__contains__(",") and not spilted_string.__contains__(" "):
                            sp_string = spilted_string.split(",")
                            count_comma = spilted_string.count(",")
                            for item in range(count_comma + 1):
                                if sp_string[item].strip() == "":
                                    #print("space")
                                    pass
                                else:
                                    data.append(
                                        dict(component_name=program_name, component_type=program_type,
                                             Table=sp_string[item].strip(), CRUD="READ",
                                             SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))

                        elif spilted_string.__contains__(" ") and not spilted_string.__contains__(","):
                            split_string = spilted_string.split(" ")
                            if split_string[0].strip() == "":
                                #print("space")
                                pass
                            else:
                                data.append(dict(component_name=program_name, component_type=program_type,
                                             Table=split_string[0].strip(), CRUD="READ",
                                             SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))

                        else:
                            if spilted_string.strip() == "":
                                # print("space")
                                pass
                            else:
                                data.append(dict(component_name=program_name, component_type=program_type,
                                             Table=spilted_string.strip(), CRUD="READ",
                                             SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))
                    elif str.__contains__("WHERE") and not str.__contains__("FROM"):
                        spilted_string = before(str, "WHERE")
                        if spilted_string.__contains__(" ") and spilted_string.__contains__(","):
                            split_string = spilted_string.split(",")
                            count_comma = spilted_string.count(",")

                            for item in range(count_comma + 1):
                                if split_string[item].strip() == "":
                                    # print("space")
                                    pass
                                else:
                                    if split_string[item].strip().__contains__(" "):
                                        split_string_spaced = split_string[item].strip().split(" ")
                                        data.append(
                                            dict(component_name=program_name, component_type=program_type,
                                                 Table=split_string_spaced[0], CRUD="READ",
                                                 SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))

                        elif spilted_string.__contains__(",") and not spilted_string.__contains__(" "):
                            sp_string = spilted_string.split(",")
                            count_comma = spilted_string.count(",")

                            for item in range(count_comma + 1):
                                if sp_string[item].strip() == "":
                                    # print("space")
                                    pass
                                else:
                                    data.append(
                                        dict(component_name=program_name, component_type=program_type,
                                             Table=sp_string[item].strip(), CRUD="READ",
                                             SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))

                        elif spilted_string.__contains__(" ") and not spilted_string.__contains__(","):
                            split_string = spilted_string.split(" ")
                            if split_string[0].strip() == "":
                                pass
                                # print("Space")
                            else:
                                data.append(dict(component_name=program_name, component_type=program_type,
                                             Table=split_string[0].strip(), CRUD="READ",
                                             SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))

                        else:
                            if spilted_string.strip() =="":
                                # print("Space")
                                pass
                            else:
                                data.append(dict(component_name=program_name, component_type=program_type,
                                             Table=spilted_string.strip(), CRUD="READ",
                                             SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))
                    elif str.__contains__("FROM") and str.__contains__("WHERE"):
                        spilted_string = between(str, " FROM ", " WHERE ")
                        if spilted_string.__contains__(" ") and spilted_string.__contains__(","):
                            split_string = spilted_string.split(",")
                            count_comma = spilted_string.count(",")

                            for item in range(count_comma + 1):
                                if split_string[item].strip() == "":
                                    # print("space")
                                    pass
                                else:
                                    if split_string[item].strip().__contains__(" "):
                                        split_string_spaced = split_string[item].strip().split(" ")
                                        if split_string_spaced[0].strip() == "":
                                            pass
                                            # print("Space")
                                        else:
                                            data.append(
                                            dict(component_name=program_name, component_type=program_type,
                                                 Table=split_string_spaced[0], CRUD="READ",
                                                 SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))

                        elif spilted_string.__contains__(",") and not spilted_string.__contains__(" "):
                            sp_string = spilted_string.split(",")

                            count_comma = spilted_string.count(",")
                            for item in range(count_comma + 1):
                                if sp_string[item] == " ":
                                    # print("space")
                                    pass
                                else:
                                    data.append(
                                        dict(component_name=program_name, component_type=program_type,
                                             Table=sp_string[item].strip(), CRUD="READ",
                                             SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))

                        elif spilted_string.__contains__(" ") and not spilted_string.__contains__(","):
                            split_string = spilted_string.split(" ")
                            if split_string[0].strip()=="":
                                # print("Space")
                                pass
                            else:
                                data.append(dict(component_name=program_name, component_type=program_type,
                                             Table=split_string[0].strip(), CRUD="READ",
                                             SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))

                        else:
                            if spilted_string.strip() =="":
                                # print("Space")
                                pass
                            else:
                                data.append(dict(component_name=program_name, component_type=program_type,
                                             Table=spilted_string.strip(), CRUD="READ",
                                             SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))
            # try:
            #     if item.__contains__("JOIN") and item.__contains__("ON"):
            #         select_string = between(item, " JOIN ", " ON ")
            #         if select_string.__contains__(","):
            #             sp_string = select_string.strip().split(",")
            #             count_comma = select_string.count(",")
            #
            #             for item in range(count_comma + 1):
            #                 if sp_string[item] == " ":
            #                     print("space")
            #                 else:
            #                     data.append(dict(component_name=program_name, component_type=program_type,
            #                                      Table=sp_string[item].strip(), CRUD="READ",
            #                                      SQL=line.rstrip().replace((program_name + ","), "")))
            #
            #         elif select_string.__contains__(" ") and not select_string.__contains__(","):
            #             split_string = select_string.strip().split(" ")
            #             data.append(dict(component_name=program_name, component_type=program_type,
            #                              Table=split_string[0].strip(), CRUD="READ",
            #                              SQL=line.rstrip().replace((program_name + ","), "")))
            #
            #         else:
            #             data.append(dict(component_name=program_name, component_type=program_type,
            #                              Table=select_string.strip(), CRUD="READ",
            #                              SQL=line.rstrip().replace((program_name + ","), "")))
            # except:
            #     continue
        elif item.__contains__("FROM") and item.__contains__("LEFT"):
            select_string = between(item, " FROM ", " LEFT ")
            select_string = select_string.strip()
            if select_string.__contains__(" ") and select_string.__contains__(","):
                split_string = select_string.split(",")

                count_comma = select_string.count(",")

                for item in range(count_comma + 1):
                    if split_string[item] == " ":
                        # print("space")
                        pass
                    else:
                        if split_string[item].strip().__contains__(" "):
                            split_string_spaced = split_string[item].strip().split(" ")

                            data.append(
                                dict(component_name=program_name, component_type=program_type,
                                     Table=split_string_spaced[0], CRUD="READ",
                                     SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))
            elif select_string.__contains__(","):
                sp_string = select_string.split(",")

                count_comma = select_string.count(",")

                for item in range(count_comma + 1):
                    if sp_string[item] == " ":
                        # print("space")
                        pass
                    else:
                        data.append(dict(component_name=program_name, component_type=program_type,
                                         Table=sp_string[item].strip(), CRUD="READ",
                                         SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))
            elif select_string.__contains__(" ") and not select_string.__contains__(","):
                split_string = select_string.split(" ")

                data.append(dict(component_name=program_name, component_type=program_type,
                                 Table=split_string[0].strip(), CRUD="READ",
                                 SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))
            else:

                data.append(dict(component_name=program_name, component_type=program_type,
                                 Table=select_string.strip(), CRUD="READ",
                                 SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))
            try:
                if item.__contains__("JOIN") and item.__contains__("ON"):
                    select_string = between(item, "JOIN", "ON")

                    if select_string.__contains__(","):
                        sp_string = select_string.split(",")

                        count_comma = select_string.count(",")

                        for item in range(count_comma + 1):
                            if sp_string[item] == " ":
                                # print("space")
                                pass
                            else:
                                data.append(dict(component_name=program_name, component_type=program_type,
                                                 Table=sp_string[item].strip(), CRUD="READ",
                                                 SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))

                    elif select_string.__contains__(" ") and not select_string.__contains__(","):
                        split_string = select_string.split(" ")

                        data.append(dict(component_name=program_name, component_type=program_type,
                                         Table=split_string[1].strip(), CRUD="READ",
                                         SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))

                    else:

                        data.append(dict(component_name=program_name, component_type=program_type,
                                         Table=select_string.strip(), CRUD="READ",
                                         SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))
            except:
                continue
        elif item.__contains__("FROM") and item.__contains__("RIGHT"):
            select_string = between(item, " FROM ", " RIGHT ")
            select_string = select_string.strip()
            if select_string.__contains__(" ") and select_string.__contains__(","):
                split_string = select_string.split(",")

                count_comma = select_string.count(",")

                for item in range(count_comma + 1):
                    if split_string[item] == " ":
                        # print("space")
                        pass
                    else:
                        if split_string[item].strip().__contains__(" "):
                            split_string_spaced = split_string[item].strip().split(" ")

                            data.append(
                                dict(component_name=program_name, component_type=program_type,
                                     Table=split_string_spaced[0], CRUD="READ",
                                     SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))

            elif select_string.__contains__(","):
                sp_string = select_string.split(",")

                count_comma = select_string.count(",")

                for item in range(count_comma + 1):
                    if sp_string[item] == " ":
                        # print("space")
                        pass
                    else:
                        data.append(dict(component_name=program_name, component_type=program_type,
                                         Table=sp_string[item].strip(), CRUD="READ",
                                         SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))


            elif select_string.__contains__(" ") and not select_string.__contains__(","):
                split_string = select_string.split(" ")

                data.append(dict(component_name=program_name, component_type=program_type,
                                 Table=split_string[1].strip(), CRUD="READ",
                                 SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))

            else:

                data.append(dict(component_name=program_name, component_type=program_type,
                                 Table=select_string.strip(), CRUD="READ",
                                 SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))

            try:
                if item.__contains__("JOIN") and item.__contains__("ON"):
                    select_string = between(item, "JOIN", "ON")

                    if select_string.__contains__(","):
                        sp_string = select_string.split(",")

                        count_comma = select_string.count(",")

                        for item in range(count_comma + 1):
                            if sp_string[item] == " ":
                                # print("space")
                                pass
                            else:
                                data.append(dict(component_name=program_name, component_type=program_type,
                                                 Table=sp_string[item].strip(), CRUD="READ",
                                                 SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))

                    elif select_string.__contains__(" ") and not select_string.__contains__(","):
                        split_string = select_string.split(" ")

                        data.append(dict(component_name=program_name, component_type=program_type,
                                         Table=split_string[1].strip(), CRUD="READ",
                                         SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))

                    else:

                        data.append(dict(component_name=program_name, component_type=program_type,
                                         Table=select_string.strip(), CRUD="READ",
                                         SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))
            except:
                continue
        elif item.__contains__("FROM") and item.__contains__("FULL"):
            select_string = between(item, " FROM ", " FULL ")
            select_string = select_string.strip()
            if select_string.__contains__(" ") and select_string.__contains__(","):
                split_string = select_string.split(",")

                count_comma = select_string.count(",")

                for item in range(count_comma + 1):
                    if split_string[item] == " ":
                        # print("space")
                        pass
                    else:
                        if split_string[item].strip().__contains__(" "):
                            split_string_spaced = split_string[item].strip().split(" ")

                            data.append(
                                dict(component_name=program_name, component_type=program_type,
                                     Table=split_string_spaced[0], CRUD="READ",
                                     SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))

            elif select_string.__contains__(","):
                sp_string = select_string.split(",")

                count_comma = select_string.count(",")

                for item in range(count_comma + 1):
                    if sp_string[item] == " ":
                        # print("space")
                        pass
                    else:
                        data.append(dict(component_name=program_name, component_type=program_type,
                                         Table=sp_string[item].strip(), CRUD="READ",
                                         SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))


            elif select_string.__contains__(" ") and not select_string.__contains__(","):
                split_string = select_string.split(" ")

                data.append(dict(component_name=program_name, component_type=program_type,
                                 Table=split_string[1].strip(), CRUD="READ",
                                 SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))

            else:

                data.append(dict(component_name=program_name, component_type=program_type,
                                 Table=select_string.strip(), CRUD="READ",
                                 SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))

            try:
                if item.__contains__("JOIN") and item.__contains__("ON"):
                    select_string = between(item, "JOIN", "ON")

                    if select_string.__contains__(","):
                        sp_string = select_string.split(",")

                        count_comma = select_string.count(",")

                        for item in range(count_comma + 1):
                            if sp_string[item] == " ":
                                # print("space")
                                pass
                            else:
                                data.append(dict(component_name=program_name, component_type=program_type,
                                                 Table=sp_string[item].strip(), CRUD="READ",
                                                 SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))

                    elif select_string.__contains__(" ") and not select_string.__contains__(","):
                        split_string = select_string.split(" ")

                        data.append(dict(component_name=program_name, component_type=program_type,
                                         Table=split_string[1].strip(), CRUD="READ",
                                         SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))

                    else:

                        data.append(dict(component_name=program_name, component_type=program_type,
                                         Table=select_string.strip(), CRUD="READ",
                                         SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))
            except:
                continue
        elif item.__contains__("FROM") and item.__contains__("INNER"):
            select_string = between(item, " FROM ", " INNER ")
            select_string = select_string.strip()
            if select_string.__contains__(" ") and select_string.__contains__(","):
                split_string = select_string.split(",")

                count_comma = select_string.count(",")

                for item in range(count_comma + 1):
                    if split_string[item] == " ":
                        # print("space")
                        pass
                    else:
                        if split_string[item].strip().__contains__(" "):
                            split_string_spaced = split_string[item].strip().split(" ")

                            data.append(
                                dict(component_name=program_name, component_type=program_type,
                                     Table=split_string_spaced[0], CRUD="READ",
                                     SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))

            elif select_string.__contains__(","):

                sp_string = select_string.split(",")

                count_comma = select_string.count(",")

                for item in range(count_comma + 1):
                    if sp_string[item] == " ":
                        # print("space")
                        pass
                    else:
                        data.append(dict(component_name=program_name, component_type=program_type,
                                         Table=sp_string[item].strip(), CRUD="READ",
                                         SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))

            elif select_string.__contains__(" ") and not select_string.__contains__(","):

                split_string = select_string.split(" ")

                data.append(dict(component_name=program_name, component_type=program_type,
                                 Table=split_string[0].strip(), CRUD="READ",
                                 SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))

            else:
                data.append(dict(component_name=program_name, component_type=program_type,
                                 Table=select_string.strip(), CRUD="READ",
                                 SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))

            try:
                if item.__contains__("JOIN") and item.__contains__("ON"):
                    select_string = between(item, "JOIN", "ON")

                    if select_string.__contains__(","):
                        sp_string = select_string.split(",")

                        count_comma = select_string.count(",")

                        for item in range(count_comma + 1):
                            if sp_string[item] == " ":
                                # print("space")
                                pass
                            else:
                                data.append(dict(component_name=program_name, component_type=program_type,
                                                 Table=sp_string[item].strip(), CRUD="READ",
                                                 SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))

                    elif select_string.__contains__(" ") and not select_string.__contains__(","):
                        split_string = select_string.split(" ")

                        data.append(dict(component_name=program_name, component_type=program_type,
                                         Table=split_string[1].strip(), CRUD="READ",
                                         SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))

                    else:

                        data.append(dict(component_name=program_name, component_type=program_type,
                                         Table=select_string.strip(), CRUD="READ",
                                         SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))
            except:
                continue
        elif item.__contains__("FROM") and item.__contains__("JOIN"):
            select_string = between(item, " FROM ", " JOIN ")
            select_string = select_string.strip()
            if select_string.__contains__(" ") and select_string.__contains__(","):
                split_string = select_string.strip().split(",")

                count_comma = select_string.count(",")

                for item in range(count_comma + 1):
                    if split_string[item] == " ":
                        # print("space")
                        pass
                    else:
                        if split_string[item].strip().__contains__(" "):
                            split_string_spaced = split_string[item].strip().split(" ")

                            data.append(
                                dict(component_name=program_name, component_type=program_type,
                                     Table=split_string_spaced[0], CRUD="READ",
                                     SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))

            elif select_string.__contains__(","):
                sp_string = select_string.split(",")

                count_comma = select_string.count(",")

                for item in range(count_comma + 1):
                    if sp_string[item] == " ":
                        # print("space")
                        pass
                    else:
                        data.append(dict(component_name=program_name, component_type=program_type,
                                         Table=sp_string[item].strip(), CRUD="READ",
                                         SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))


            elif select_string.__contains__(" ") and not select_string.__contains__(","):
                split_string = select_string.split(" ")

                data.append(dict(component_name=program_name, component_type=program_type,
                                 Table=split_string[1].strip(), CRUD="READ",
                                 SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))

            else:

                data.append(dict(component_name=program_name, component_type=program_type,
                                 Table=select_string.strip(), CRUD="READ",
                                 SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))

            try:
                if item.__contains__("JOIN") and item.__contains__("ON"):
                    select_string = between(item, "JOIN", "ON")

                    if select_string.__contains__(","):
                        sp_string = select_string.split(",")

                        count_comma = select_string.count(",")

                        for item in range(count_comma + 1):
                            if sp_string[item] == " ":
                                # print("space")
                                pass
                            else:
                                data.append(dict(component_name=program_name, component_type=program_type,
                                                 Table=sp_string[item].strip(), CRUD="READ",
                                                 SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))

                    elif select_string.__contains__(" ") and not select_string.__contains__(","):
                        split_string = select_string.split(" ")

                        data.append(dict(component_name=program_name, component_type=program_type,
                                         Table=split_string[1].strip(), CRUD="READ",
                                         SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))

                    else:

                        data.append(dict(component_name=program_name, component_type=program_type,
                                         Table=select_string.strip(), CRUD="READ",
                                         SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))
            except:
                continue
        elif item.__contains__("FROM") and item.__contains__("WITH UR"):
            select_string = between(item, " FROM ", " WITH UR ")
            select_string = select_string.strip()
            if select_string.__contains__(" ") and select_string.__contains__(","):
                split_string = select_string.split(",")

                count_comma = select_string.count(",")

                for item in range(count_comma + 1):
                    if split_string[item] == " ":
                        # print("space")
                        pass
                    else:
                        if split_string[item].strip().__contains__(" "):
                            split_string_spaced = split_string[item].strip().split(" ")

                            data.append(
                                dict(component_name=program_name, component_type=program_type,
                                     Table=split_string_spaced[0], CRUD="READ",
                                     SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))
            elif select_string.__contains__(","):
                sp_string = select_string.split(",")

                count_comma = select_string.count(",")

                for item in range(count_comma + 1):
                    if sp_string[item] == " ":
                        # print("space")
                        pass
                    else:
                        data.append(dict(component_name=program_name, component_type=program_type,
                                         Table=sp_string[item].strip(), CRUD="READ",
                                         SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))
            elif select_string.__contains__(" ") and not select_string.__contains__(","):
                split_string = select_string.split(" ")

                data.append(dict(component_name=program_name, component_type=program_type,
                                 Table=split_string[0].strip(), CRUD="READ",
                                 SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))
            else:

                data.append(dict(component_name=program_name, component_type=program_type,
                                 Table=select_string.strip(), CRUD="READ",
                                 SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))
            try:
                if item.__contains__("JOIN") and item.__contains__("ON"):
                    select_string = between(item, "JOIN", "ON")

                    if select_string.__contains__(","):
                        sp_string = select_string.split(",")

                        count_comma = select_string.count(",")

                        for item in range(count_comma + 1):
                            if sp_string[item] == " ":
                                # print("space")
                                pass
                            else:
                                data.append(dict(component_name=program_name, component_type=program_type,
                                                 Table=sp_string[item].strip(), CRUD="READ",
                                                 SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))

                    elif select_string.__contains__(" ") and not select_string.__contains__(","):
                        split_string = select_string.split(" ")

                        data.append(dict(component_name=program_name, component_type=program_type,
                                         Table=split_string[1].strip(), CRUD="READ",
                                         SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))

                    else:

                        data.append(dict(component_name=program_name, component_type=program_type,
                                         Table=select_string.strip(), CRUD="READ",
                                         SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))
            except:
                continue
        elif item.__contains__("FROM") and item.__contains__("END-EXEC"):
            select_string = between(item, " FROM ", " END-EXEC ")
            select_string = select_string.strip()
            if select_string.__contains__("END-EXEC"):
                if select_string.__contains__(" ") and select_string.__contains__(","):
                    split_string = select_string.split(",")

                    count_comma = select_string.count(",")

                    for item in range(count_comma + 1):
                        if split_string[item] == " ":
                            # print("space")
                            pass
                        else:
                            if split_string[item].strip().__contains__(" "):
                                split_string_spaced = split_string[item].strip().split(" ")

                                data.append(
                                    dict(component_name=program_name, component_type=program_type,
                                         Table=split_string_spaced[0], CRUD="READ",
                                         SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))
                elif select_string.__contains__(","):
                    sp_string = select_string.split(",")

                    count_comma = select_string.count(",")

                    for item in range(count_comma + 1):
                        if sp_string[item] == " ":
                            # print("space")
                            pass
                        else:
                            data.append(dict(component_name=program_name, component_type=program_type,
                                             Table=sp_string[item].strip(), CRUD="READ",
                                             SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))
                elif select_string.__contains__(" ") and not select_string.__contains__(","):
                    split_string = select_string.split(" ")

                    data.append(dict(component_name=program_name, component_type=program_type,
                                     Table=split_string[0].strip(), CRUD="READ",
                                     SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))
                else:

                    data.append(dict(component_name=program_name, component_type=program_type,
                                     Table=select_string.strip(), CRUD="READ",
                                     SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))
                try:
                    if item.__contains__("JOIN") and item.__contains__("ON"):
                        select_string = between(item, "JOIN", "ON")

                        if select_string.__contains__(","):
                            sp_string = select_string.split(",")

                            count_comma = select_string.count(",")

                            for item in range(count_comma + 1):
                                if sp_string[item] == " ":
                                    # print("space")
                                    pass
                                else:
                                    data.append(dict(component_name=program_name, component_type=program_type,
                                                     Table=sp_string[item].strip(), CRUD="READ",
                                                     SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))

                        elif select_string.__contains__(" ") and not select_string.__contains__(","):
                            split_string = select_string.split(" ")

                            data.append(dict(component_name=program_name, component_type=program_type,
                                             Table=split_string[1].strip(), CRUD="READ",
                                             SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))

                        else:

                            data.append(dict(component_name=program_name, component_type=program_type,
                                             Table=select_string.strip(), CRUD="READ",
                                             SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))
                except:
                    continue
            else:
                if select_string.__contains__(" ") and select_string.__contains__(","):
                    split_string = select_string.split(",")

                    count_comma = select_string.count(",")

                    for item in range(count_comma + 1):
                        if split_string[item] == " ":
                            # print("space")
                            pass
                        else:
                            if split_string[item].strip().__contains__(" "):
                                split_string_spaced = split_string[item].strip().split(" ")

                                data.append(
                                    dict(component_name=program_name, component_type=program_type,
                                         Table=split_string_spaced[0], CRUD="READ",
                                         SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))
                elif select_string.__contains__(","):
                    sp_string = select_string.split(",")

                    count_comma = select_string.count(",")

                    for item in range(count_comma + 1):
                        if sp_string[item] == " ":
                            # print("space")
                            pass
                        else:
                            data.append(dict(component_name=program_name, component_type=program_type,
                                             Table=sp_string[item].strip(), CRUD="READ",
                                             SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))
                elif select_string.__contains__(" ") and not select_string.__contains__(","):
                    split_string = select_string.split(" ")

                    data.append(dict(component_name=program_name, component_type=program_type,
                                     Table=split_string[0].strip(), CRUD="READ",
                                     SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))
                else:

                    data.append(dict(component_name=program_name, component_type=program_type,
                                     Table=select_string.strip(), CRUD="READ",
                                     SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))
                try:
                    if item.__contains__("JOIN") and item.__contains__("ON"):
                        select_string = between(item, "JOIN", "ON")

                        if select_string.__contains__(","):
                            sp_string = select_string.split(",")

                            count_comma = select_string.count(",")

                            for item in range(count_comma + 1):
                                if sp_string[item] == " ":
                                    # print("space")
                                    pass
                                else:
                                    data.append(dict(component_name=program_name, component_type=program_type,
                                                     Table=sp_string[item].strip(), CRUD="READ",
                                                     SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))

                        elif select_string.__contains__(" ") and not select_string.__contains__(","):
                            split_string = select_string.split(" ")

                            data.append(dict(component_name=program_name, component_type=program_type,
                                             Table=split_string[1].strip(), CRUD="READ",
                                             SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))

                        else:

                            data.append(dict(component_name=program_name, component_type=program_type,
                                             Table=select_string.strip(), CRUD="READ",
                                             SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))
                except:
                    continue
        elif item.__contains__("FROM") and item.__contains__("FOR UPDATE OF"):
            select_string = between(item, " FROM ", " FOR UPDATE OF ")
            select_string = select_string.strip()
            if select_string.__contains__("FOR UPDATE OF"):
                if select_string.__contains__(" ") and select_string.__contains__(","):
                    split_string = select_string.split(",")

                    count_comma = select_string.count(",")

                    for item in range(count_comma + 1):
                        if split_string[item] == " ":
                            # print("space")
                            pass
                        else:
                            if split_string[item].strip().__contains__(" "):
                                split_string_spaced = split_string[item].strip().split(" ")

                                data.append(
                                    dict(component_name=program_name, component_type=program_type,
                                         Table=split_string_spaced[0], CRUD="READ",
                                         SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))
                elif select_string.__contains__(","):
                    sp_string = select_string.split(",")

                    count_comma = select_string.count(",")

                    for item in range(count_comma + 1):
                        if sp_string[item] == " ":
                            # print("space")
                            pass
                        else:
                            data.append(dict(component_name=program_name, component_type=program_type,
                                             Table=sp_string[item].strip(), CRUD="READ",
                                             SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))
                elif select_string.__contains__(" ") and not select_string.__contains__(","):
                    split_string = select_string.split(" ")

                    data.append(dict(component_name=program_name, component_type=program_type,
                                     Table=split_string[0].strip(), CRUD="READ",
                                     SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))
                else:

                    data.append(dict(component_name=program_name, component_type=program_type,
                                     Table=select_string.strip(), CRUD="READ",
                                     SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))
                try:
                    if item.__contains__("JOIN") and item.__contains__("ON"):
                        select_string = between(item, "JOIN", "ON")

                        if select_string.__contains__(","):
                            sp_string = select_string.split(",")

                            count_comma = select_string.count(",")

                            for item in range(count_comma + 1):
                                if sp_string[item] == " ":
                                    # print("space")
                                    pass
                                else:
                                    data.append(dict(component_name=program_name, component_type=program_type,
                                                     Table=sp_string[item].strip(), CRUD="READ",
                                                     SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))

                        elif select_string.__contains__(" ") and not select_string.__contains__(","):
                            split_string = select_string.split(" ")

                            data.append(dict(component_name=program_name, component_type=program_type,
                                             Table=split_string[1].strip(), CRUD="READ",
                                             SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))

                        else:

                            data.append(dict(component_name=program_name, component_type=program_type,
                                             Table=select_string.strip(), CRUD="READ",
                                             SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))
                except:
                    continue
            else:
                if select_string.__contains__(" ") and select_string.__contains__(","):
                    split_string = select_string.split(",")

                    count_comma = select_string.count(",")

                    for item in range(count_comma + 1):
                        if split_string[item] == " ":
                            # print("space")
                            pass
                        else:
                            if split_string[item].strip().__contains__(" "):
                                split_string_spaced = split_string[item].strip().split(" ")

                                data.append(
                                    dict(component_name=program_name, component_type=program_type,
                                         Table=split_string_spaced[0], CRUD="READ",
                                         SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))
                elif select_string.__contains__(","):
                    sp_string = select_string.split(",")

                    count_comma = select_string.count(",")

                    for item in range(count_comma + 1):
                        if sp_string[item] == " ":
                            # print("space")
                            pass
                        else:
                            data.append(dict(component_name=program_name, component_type=program_type,
                                             Table=sp_string[item].strip(), CRUD="READ",
                                             SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))
                elif select_string.__contains__(" ") and not select_string.__contains__(","):
                    split_string = select_string.split(" ")

                    data.append(dict(component_name=program_name, component_type=program_type,
                                     Table=split_string[0].strip(), CRUD="READ",
                                     SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))
                else:

                    data.append(dict(component_name=program_name, component_type=program_type,
                                     Table=select_string.strip(), CRUD="READ",
                                     SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))
                try:
                    if item.__contains__("JOIN") and item.__contains__("ON"):
                        select_string = between(item, "JOIN", "ON")

                        if select_string.__contains__(","):
                            sp_string = select_string.split(",")

                            count_comma = select_string.count(",")

                            for item in range(count_comma + 1):
                                if sp_string[item] == " ":
                                    # print("space")
                                    pass
                                else:
                                    data.append(dict(component_name=program_name, component_type=program_type,
                                                     Table=sp_string[item].strip(), CRUD="READ",
                                                     SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))

                        elif select_string.__contains__(" ") and not select_string.__contains__(","):
                            split_string = select_string.split(" ")

                            data.append(dict(component_name=program_name, component_type=program_type,
                                             Table=split_string[1].strip(), CRUD="READ",
                                             SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))

                        else:

                            data.append(dict(component_name=program_name, component_type=program_type,
                                             Table=select_string.strip(), CRUD="READ",
                                             SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))
                except:
                    continue
        elif item.__contains__("FROM") and not item.__contains__("WHERE") and not item.__contains__(
                "ORDER BY") and not item.__contains__("GROUP BY"):
            #print(item)
            select_string = after(item, " FROM ")
            select_string = select_string.strip()
            #print("ok it entered into from condition", select_string)
            if select_string.strip() == "":
                # print("ok")
                pass
            elif select_string.strip() == "(":
                # print("bracket")
                pass
            elif select_string.__contains__(","):
                split_string = select_string.split(",")
                #print(split_string,"Split string..... comma bracket")
                count = select_string.count(",")
                for item in range(count + 1):

                    if split_string[item].strip() == " ":
                        # print("Space")
                        pass
                    elif split_string[item].strip()=="(":
                        # print("Bracket")
                        pass
                    else:
                        data.append(dict(component_name=program_name, component_type=program_type,
                                         Table=split_string[item].strip(), CRUD="READ",
                                         SQL=line.replace((program_name + ","), "").replace("END-EXEC","")))

            else:

                if select_string.__contains__("\n") and select_string.__contains__("."):
                    replaced_string = select_string.replace("\n", "") and select_string.replace(".", "")
                    if replaced_string.strip()=="":
                        # print("Space")
                        pass
                    else:
                        data.append(dict(component_name=program_name, component_type=program_type,
                                     Table=replaced_string.replace("\n", "").strip(), CRUD="READ",
                                     SQL=line.replace((program_name + ","), "").replace("END-EXEC","")))


                else:
                    if select_string.strip() == "":
                        # print("Space")
                        pass
                    else:
                        data.append(dict(component_name=program_name, component_type=program_type,
                                     Table=select_string.strip(), CRUD="READ",
                                     SQL=line.replace((program_name + ","), "").replace("END-EXEC","")))
            try:
                if item.__contains__("JOIN") and item.__contains__("ON"):
                    select_string = between(item, "JOIN", "ON")

                    if select_string.__contains__(","):
                        sp_string = select_string.split(",")

                        count_comma = select_string.count(",")

                        for item in range(count_comma + 1):
                            if sp_string[item] == " ":
                                # print("space")
                                pass
                            else:
                                data.append(dict(component_name=program_name, component_type=program_type,
                                                 Table=sp_string[item].strip(), CRUD="READ",
                                                 SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))

                    elif select_string.__contains__(" ") and not select_string.__contains__(","):
                        split_string = select_string.split(" ")

                        data.append(dict(component_name=program_name, component_type=program_type,
                                         Table=split_string[1].strip(), CRUD="READ",
                                         SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))

                    else:

                        data.append(dict(component_name=program_name, component_type=program_type,
                                         Table=select_string.strip(), CRUD="READ",
                                         SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))
            except:
                continue
        elif options == "SELECT":
            continue
        # elif options == "UPDATE":
        #     if " SET " in line:
        #         update_string = between(line, "UPDATE", " SET ")
        #
        #         if update_string.__contains__(","):
        #             split_string = update_string.split(",")
        #
        #             count = update_string.count(",")
        #
        #             for item in range(count + 1):
        #
        #                 if split_string[item] == " ":
        #                     print("Space")
        #                 else:
        #                     data.append(dict(component_name=program_name, component_type=program_type,
        #                                      Table=split_string[item].strip(), CRUD="UPDATE",
        #                                      SQL=line.rstrip().replace((program_name + ","), "")))
        #
        #         else:
        #             data.append(dict(component_name=program_name, component_type=program_type,
        #                              Table=update_string.strip(), CRUD="UPDATE",
        #                              SQL=line.rstrip().replace((program_name + ","), "")))
        #     else:
        #         print("there is no set")
        # elif options == "INSERT":
        #     insert_string = after(line, " INTO ")
        #
        #     spilted_insert_string = insert_string.split(" ")
        #
        #     data.append(dict(component_name=program_name, component_type=program_type,
        #                      Table=spilted_insert_string[0].strip(), CRUD="CREATE",
        #                      SQL=line.rstrip().replace((program_name + ","), "")))
        # elif options == "DELETE":
        #     delete_string = between(line, " FROM ", " WHERE ")
        #
        #     if delete_string.__contains__(","):
        #         split_string = delete_string.split(",")
        #
        #         count = delete_string.count(",")
        #
        #         for item in range(count + 1):
        #
        #             if split_string[item].strip() == "":
        #                 print("Space")
        #             else:
        #                 data.append(dict(component_name=program_name, component_type=program_type,
        #                                  Table=split_string[item].strip(), CRUD="DELETE",
        #                                  SQL=line.rstrip().replace(program_name, "")))
        #
        #     else:
        #         if delete_string.strip() == "":
        #             print("Space")
        #         else:
        #             data.append(dict(component_name=program_name, component_type=program_type,
        #                          Table=delete_string.strip(), CRUD="DELETE",
        #                          SQL=line.rstrip().replace(program_name, "")))


#  Getting all .cbl files in a particular folder.
try:
    program_type = ""
    os.path.exists(cbl_org_path+"\\"+"COBOL")
    os.chdir(cbl_org_path+"\\"+"COBOL")
    path, dirs, files = next(os.walk(cbl_org_path+"\\"+"COBOL"))
    file_count = len(files)
    if file_count == 0:
        print("There is no file inside COBOL folder")
    cblCounter = len(glob.glob1(cbl_org_path+"\\"+"COBOL", "*.cbl"))
    if cblCounter == 0:
        print("There is no .CBL file inside the folder.")
    else:
        # print("Out of " + str(file_count) + " files only " + str(cblCounter) + " are CBL files.Processing those files.")
        pass
    i = 0
    os.chdir(cbl_org_path+"\\"+"COBOL")
    for file in glob.glob("*.cbl"):
        #print("CRUD processing the ", file)
        i = i + 1
        filename, file_extension = os.path.splitext(file)
        #print(file,"file")
        program_name = filename
        if file_extension == ".CBL":
            program_type = "COBOL"
        program_type = "COBOL"  
        # opening a file
        with open(file, 'r') as f2:
            file_data = f2.readlines()

        string_bucket = ''
        in_exec_flag = False
        # Extracting the all sql queries inside a file and writing it into a temp_file
        for ite in file_data:

            extracted_line = ite[6:72]
            if extracted_line.startswith("*"):
                continue
            else:
                if ite.__contains__("EXEC SQL") and ite.__contains__("END-EXEC"):
                    with open("text_file" + str(i) + '.txt', "a") as temp_file:
                        remove_space(ite[6:72])

                elif ite.__contains__("EXEC SQL"):
                    in_exec_flag = True
                    string_bucket = ''
                    string_bucket += ite
                    with open("text_file" + str(i) + '.txt', "a") as temp_file:
                        remove_space(ite[6:72])

                elif ite.__contains__("END-EXEC"):
                    in_exec_flag = False
                    with open("text_file" + str(i) + '.txt', "a") as temp_file:
                        remove_space(ite[6:72])

                elif in_exec_flag:
                    with open("text_file" + str(i) + '.txt', "a") as temp_file:
                        remove_space(ite[6:72])

        exists = os.path.isfile("text_file" + str(i) + '.txt')
        if exists:
            # Reading a file and keeping it into a data_file variable
            with open("text_file" + str(i) + '.txt', "r") as temp_file_spaced1:
                data_file = temp_file_spaced1.readlines()
                #print(type(data_file))

                # Iterating over all the cbl files in the folder
            for line in data_file:

                # Selecting the lines containing only a "SELECT" and extracting the details.
                if line.__contains__(" SELECT ") and not line.__contains__(" UPDATE ") and not line.__contains__(
                        "INSERT") and not line.__contains__("DELETE"):

                    process(line, "SELECT")

                # Selecting the lines containing only a "INSERT" and extracting the details.
                elif line.__contains__(" INSERT ") and not line.__contains__(" SELECT ") and not line.__contains__(
                        " UPDATE ") and not line.__contains__(" DELETE "):
                    insert_string = after(line, " INTO ")

                    spilted_insert_string = insert_string.split(" ")

                    data.append(dict(component_name=program_name, component_type=program_type,
                                     Table=spilted_insert_string[0].strip(), CRUD="CREATE",
                                     SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))

                #  Selecting the lines containing only a "UPDATE" and extracting the details.
                elif line.__contains__(" UPDATE ") and not line.__contains__(" SELECT ") and not line.__contains__(
                        " INSERT ") and not line.__contains__(" DELETE "):
                    update_string = between(line, "UPDATE ", " SET ")
                    if update_string.__contains__(","):
                        split_string = update_string.split(",")
                        count = update_string.count(",")
                        for item in range(count + 1):
                            if split_string[item].strip() == "":
                                # print("Space")
                                pass
                            else:
                                data.append(dict(component_name=program_name, component_type=program_type,
                                                 Table=split_string[item].strip(), CRUD="UPDATE",
                                                 SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))
                    else:
                        if update_string.strip() == "":
                            # print("Space")
                            pass
                        else:
                            data.append(dict(component_name=program_name, component_type=program_type,
                                         Table=update_string.strip(), CRUD="UPDATE",
                                         SQL=line.rstrip().replace((program_name + ","), "").replace("END-EXEC","")))

                #  Selecting the lines containing only a "DELETE" and extracting the details.
                elif line.__contains__(" DELETE ") and not line.__contains__(" SELECT ") and not line.__contains__(
                        " INSERT ") and not line.__contains__(" UPDATE "):

                    if "WHERE" in line:
                        delete_string = between(line, "FROM", "WHERE")
                        if delete_string.__contains__(","):
                            split_string = delete_string.split(",")
                            count = delete_string.count(",")
                            for item in range(count + 1):
                                if split_string[item].strip() == "":
                                    # print("Space")
                                    pass
                                else:
                                    data.append(dict(component_name=program_name, component_type=program_type,
                                                     Table=split_string[item].strip(), CRUD="DELETE",
                                                     SQL=line.rstrip().replace((program_name + ","), "").replace(
                                                         (program_name + " - "), "").replace("END-EXEC","")))
                        else:
                            if delete_string.strip() == "":
                                # print("Space")
                                pass
                            else:
                                data.append(dict(component_name=program_name, component_type=program_type,
                                             Table=delete_string.strip(), CRUD="DELETE",
                                             SQL=line.rstrip().replace((program_name + ","), "").replace((program_name + " - "),
                                                                                                         "").replace("END-EXEC","")))
                    else:
                        delete_string = after(line, " FROM ")
                        if delete_string.__contains__(","):
                            split_string = delete_string.split(",")

                            count = delete_string.count(",")

                            for item in range(count + 1):

                                if split_string[item].strip() == "":
                                    # print("Space")
                                    pass
                                else:
                                    data.append(dict(component_name=program_name, component_type=program_type,
                                                     Table=split_string[item].strip(), CRUD="DELETE",
                                                     SQL=line.rstrip().replace((program_name + ","), "").replace(
                                                         (program_name + " - "), "").replace("END-EXEC","")))

                        else:
                            if delete_string.strip() == "":
                                # print("Space")
                                pass
                            else:
                                data.append(dict(component_name=program_name, component_type=program_type,
                                             Table=delete_string.strip(), CRUD="DELETE",
                                             SQL=line.rstrip().replace((program_name + ","), "").replace(
                                                 (program_name + " - "), "").replace("END-EXEC","")))

                #  Selecting the lines containing only a "UPDATE"& "SELECT" and extracting the details.
                elif line.__contains__(" UPDATE ") and line.__contains__(" SELECT "):
                    process(line, "UPDATE")

                #  Selecting the lines containing only a "INSERT" & "SELECT" and extracting the details.
                elif line.__contains__(" INSERT ") and line.__contains__(" SELECT "):
                    process(line, "INSERT")

                #  Selecting the lines containing only a "DELETE" & "SELECT" and extracting the details.
                elif line.__contains__(" DELETE ") and line.__contains__(" SELECT "):
                    process(line, "DELETE")

        else:
            print(file + " - doesn't containing SQL statements")
except:
    print("There is no folder,named COBOL")


# print(data)
# print(len(data))

# Writing the data into the CSV file
keys = data[0].keys()
with open('.././CRUD.csv', 'w', newline="") as output_file:
    dict_writer = csv.DictWriter(output_file, keys)
    dict_writer.writeheader()
    dict_writer.writerows(data)
json_file = {'headers': ['component_name', 'component_type', 'Table', 'CRUD', 'SQL'], 'data': data}
json_val = json.dumps(json_file)
# print(json_val)

# # posting a request
# r = requests.post('http://localhost:5000/api/v1/update/CRUD',
#                   json={"data": data, "headers": ['component_name', 'component_type', 'Table', 'CRUD', 'SQL']})
#print(r.status_code)
#print(r.text)
final_dict={"data": data, "headers": ['component_name', 'component_type', 'Table', 'CRUD', 'SQL']}

def updateCRUD(final_dict):
    data = final_dict
    # JSON document for db upload
    db_data = {}
    # CRUD Report headers extracted from the 'data' field
    x_CRUD_report_header_list = []

    # check if it is json
    # JsonVerified, verification_payload = jsonVerify(data)
    # if JsonVerified:
    #     db_data = verification_payload
    # else:
    #     return verification_payload
    db_data=data
    # Must have a key "data"
    try:
        keys = list(db_data.keys())
        # print('parent keys', keys)

        if 'data' in keys:
            # fetching headers
            x_CRUD_report_header_list = db_data['headers']
            # print('CRUD Report header list', x_CRUD_report_header_list)
            # Adding header field to db_data
            db_data['headers'] = x_CRUD_report_header_list

            if len(db_data['data']) == 0:
                pass
                # return jsonify({"status": "failure", "reason": "data field is empty"})
            else:
                # Delete all existing rows (Nuking all data from the old database)
                previousDeleted = False
                try:
                    # print('crd remove operation', db.crud_report.remove({}))
                    if db.crud_report.delete_many({}):  # Mongodb syntax to delete all records
                        # print('Deleted all the CRUD components from the report')
                        previousDeleted = True
                    else:
                        pass
                        # print('Something went wrong')
                        # return jsonify(
                        #     {"status": "failed",
                        #      "reason": "unable to delete from database. Please check in with your Administrator"})

                except Exception as e:
                    pass
                    # return jsonify({"status": "failed", "reason": str(e)})
                if previousDeleted:
                    # print('Entering the insert block')
                    try:

                        db.crud_report.insert_many(db_data['data'])
                        print('it has happened')
                        # updating the timestamp based on which report is called
                        current_time = datetime.datetime.now(tz=tz).strftime("%A, %d. %B %Y %I:%M%p")
                        # Setting the time so that we know when each of the JCL and COBOLs were run

                        # db.cross_reference_report.insert_one({"type":"metadata", "JCL":{"last_updated_on":ct},"COBOL":{"last_updated_on":ct}})

                        if db.crud_report.count_documents({"type": "metadata"}) > 0:
                            print(db.crud_report.update_one({"type": "metadata"},
                                                                                 {"$set": {
                                                                                     "last_updated_on": current_time,
                                                                                     "time_zone": time_zone,
                                                                                     "headers": x_CRUD_report_header_list
                                                                                 }},
                                                                                 upsert=True).acknowledged)
                        else:
                            db.crud_report.insert_one(
                                {"type": "metadata", "last_updated_on": current_time, "time_zone": time_zone,
                                 "headers": x_CRUD_report_header_list})

                        print(current_time)
                        # return jsonify({"status": "success", "reason": "Successfully inserted data yay. "})
                    except Exception as e:
                        print('Error' + str(e))
                        # return jsonify({"status": "failed", "reason": str(e)})

    except Exception as e:
        print('Error: ' + str(e))
        # return jsonify({"status": "failure", "reason": "Response json not in the required format"})

updateCRUD(final_dict)
os.chdir("./")
read_files = glob.glob("*.txt")
with open(".././Result.txt", "wb") as outfile:
    for f in read_files:
        with open(f, "rb") as infile:
            outfile.write(infile.read())
        os.remove(f)

cwd = os.getcwd()
#print(cwd)

# for root, dirs, files in os.walk("."):
#     for filename in files:
#         os.remove(filename)
try:
    # shutil.rmtree(cwd)
    os.rmdir(cwd)
except OSError as e:
    pass
    # print("Error: %s - %s." % (e.filename, e.strerror))

