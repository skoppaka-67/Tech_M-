import re
from builtins import print
import csv
import json
import glob, os
import os.path
from os import path
import requests
import shutil

pkg_org_path = "C:\\Users\\KS00561356\\PycharmProjects\\LCaaS\\plsql\\Source Document"

Query_file = pkg_org_path+"\\PACKAGE\\Query data.txt"

data = []
TARGET = ";"


#  Removing unwanted spaces and linebreaks in the lines.
def remove_space(item):
    # # Removing all space and linebreaks by one space
    # data_space_replace = re.sub(r"\s+", " ", item)
    # if item.lstrip().startswith("SELECT"):
    #     data_space_replace.replace("SELECT", program_name + ",")
    #     if item.__contains__(";"):
    #         data_line_break = re.sub(r";", ";\n", data_space_replace)
    #         return data_line_break
    # elif item.lstrip().startswith("INSERT"):
    #     data_space_replace.replace("INSERT", program_name + ",")
    #     if item.__contains__(";"):
    #         data_line_break = re.sub(r";", ";\n", data_space_replace)
    #         return data_line_break
    # elif item.lstrip().startswith("UPDATE"):
    #     data_space_replace.replace("UPDATE", program_name + ",")
    #     if item.__contains__(";"):
    #         data_line_break = re.sub(r";", ";\n", data_space_replace)
    #         return data_line_break
    # elif item.lstrip().startswith("DELETE"):
    #     data_space_replace.replace("DELETE", program_name + ",")
    #     if item.__contains__(";"):
    #         data_line_break = re.sub(r";", ";\n", data_space_replace)
    #         return data_line_break
    # return data_space_replace
    # Removing all space and linebreaks by one space
    data_space_replace = re.sub(r"\s+", " ", item)
    if item.__contains__(";"):
        # data_with_program_name = data_space_replace.replace(";", ";"+program_name+",")
        data_line_break = re.sub(r";", ";\n", data_space_replace)
        return data_line_break
    return data_space_replace


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


def process_for_extracting_query(STARTER, SourceFileName, ExceptFileName):
    with open(SourceFileName) as f:
        # value = None
        start_seen = False
        for line in f:
            # print(line)
            extracted_line = line.lstrip()
            if extracted_line.startswith("/") or extracted_line.startswith("-") or extracted_line.startswith(
                    "*") or extracted_line.startswith("\'") or extracted_line.startswith("--"):
                # print("hoi", ite)
                continue
            if line.strip().__contains__(STARTER) and line.__contains__(TARGET):
                start_seen = False
                if line.strip().__contains__("FROM"):
                    ite = remove_space(line)
                    with open(Query_file, "a") as temp_file:
                        temp_file.write(ite)
                continue
            if line.strip().__contains__(STARTER):
                start_seen = True
                print(start_seen)
                ite = remove_space(line)
                with open(Query_file, "a") as temp_file:
                    temp_file.write(ite)
                continue
            if start_seen:
                ite = remove_space(line)
                with open(Query_file, "a") as temp_file:
                    temp_file.write(ite)
            if TARGET in line and start_seen:
                # _,value = line.split('=')
                # value = line
                start_seen = False
            if start_seen is False:
                with open(ExceptFileName, "a") as temp_file:
                    temp_file.write(line)


def process(l, options):
    print("gomathioo")
    spilted_line = line.split("SELECT")
    print(spilted_line[0])
    for item in spilted_line:
        print(item)
        if item.__contains__("FROM") and item.__contains__("WHERE"):
            if item.__contains__("DELETE"):
                delete_string = between(item, " FROM ", " WHERE ")
                if delete_string.__contains__(" ") and delete_string.__contains__(","):
                    split_string = delete_string.split(",")

                    count_comma = delete_string.count(",")

                    for item in range(count_comma + 1):
                        if split_string[item] == " ":
                            print("space")
                        else:
                            if split_string[item].strip().__contains__(" "):
                                split_string_spaced = split_string[item].strip().split(" ")

                                data.append(
                                    dict(component_name=program_name, component_type=program_type,
                                         Table=split_string_spaced[0].replace(";",""), CRUD="READ",
                                         SQL=line.rstrip()))
                elif delete_string.__contains__(","):
                    sp_string = delete_string.split(",")

                    count_comma = delete_string.count(",")

                    for item in range(count_comma + 1):
                        if sp_string[item] == " ":
                            print("space")
                        else:
                            data.append(dict(component_name=program_name, component_type=program_type,
                                             Table=sp_string[item].strip().replace(";",""), CRUD="READ",
                                             SQL=line.rstrip()))

                elif delete_string.__contains__(" ") and not delete_string.__contains__(","):
                    split_string = delete_string.split(" ")

                    data.append(dict(component_name=program_name, component_type=program_type,
                                     Table=split_string[0].strip().replace(";",""), CRUD="DELETE",
                                     SQL=line.rstrip()))
                else:

                    data.append(dict(component_name=program_name, component_type=program_type,
                                     Table=delete_string.strip().replace(";",""), CRUD="DELETE",
                                     SQL=line.rstrip()))
                # if delete_string.__contains__(","):
                #     split_string = delete_string.split(",")
                #
                #     count = delete_string.count(",")
                #
                #     for item in range(count + 1):
                #
                #         if split_string[item] == " ":
                #             print("Space")
                #         else:
                #             data.append(dict(component_name=program_name, component_type=program_type,
                #                              Table=split_string[item].strip(), CRUD="DELETE",
                #                              SQL=line.rstrip()))
                #
                # else:
                #     data.append(dict(component_name=program_name, component_type=program_type,
                #                      Table=delete_string.strip(), CRUD="DELETE",
                #                      SQL=line.rstrip()))
            else:
                select_string = between(item, " FROM ", " WHERE ")

                if select_string.__contains__("JOIN"):
                    print("gomathi", select_string)
                    sp_string = select_string.split("LEFT")
                    print("sange", sp_string)
                    spilted_string = select_string.split(" ")
                    print("anish", spilted_string)
                    data.append(
                        dict(component_name=program_name, component_type=program_type,
                             Table=spilted_string[0].replace(";",""), CRUD="READ",
                             SQL=line.rstrip()))
                    if countOccurences(select_string,"JOIN") > 1:
                        spilted_string = select_string.split("JOIN")
                        print("goms", spilted_string)
                        for item in spilted_string:
                            print("bhuvana",item)
                            if item.__contains__("ON"):
                                spilted_string = before(item.strip(),"ON")
                                print("aathi",spilted_string)

                                if spilted_string.__contains__(" ") and spilted_string.__contains__(","):
                                    split_string = spilted_string.split(",")
                                    count_comma = spilted_string.count(",")

                                    for item in range(count_comma + 1):
                                        if split_string[item] == " ":
                                            print("space")
                                        else:
                                            if split_string[item].strip().__contains__(" "):
                                                split_string_spaced = split_string[item].strip().split(" ")
                                                data.append(
                                                    dict(component_name=program_name, component_type=program_type,
                                                         Table=split_string_spaced[0].replace(";",""), CRUD="READ",
                                                         SQL=line.rstrip()))

                                elif spilted_string.__contains__(",") and not spilted_string.__contains__(" "):
                                    sp_string = spilted_string.split(",")
                                    count_comma = spilted_string.count(",")
                                    for item in range(count_comma + 1):
                                        if sp_string[item] == " ":
                                            print("space")
                                        else:
                                            data.append(
                                                dict(component_name=program_name, component_type=program_type,
                                                     Table=sp_string[item].strip().replace(";",""), CRUD="READ",
                                                     SQL=line.rstrip()))

                                elif spilted_string.__contains__(" ") and not spilted_string.__contains__(","):
                                    split_string = spilted_string.split(" ")
                                    data.append(dict(component_name=program_name, component_type=program_type,
                                                     Table=split_string[0].strip().replace(";",""), CRUD="READ",
                                                     SQL=line.rstrip()))

                                else:
                                    data.append(dict(component_name=program_name, component_type=program_type,
                                                     Table=spilted_string.strip().replace(";",""), CRUD="READ",
                                                     SQL=line.rstrip()))

                elif countOccurences(select_string, "WHERE") < 1:

                    if select_string.__contains__(" ") and select_string.__contains__(","):
                        split_string = select_string.strip().split(",")
                        print(split_string)

                        count_comma = select_string.count(",")

                        for item in range(count_comma + 1):
                            if split_string[item] == " ":
                                print("space")
                            else:
                                if split_string[item].strip().__contains__(" "):
                                    split_string_spaced = split_string[item].strip().split(" ")

                                    data.append(
                                        dict(component_name=program_name, component_type=program_type,
                                             Table=split_string_spaced[0].replace(";",""), CRUD="READ",
                                             SQL=line.rstrip()))

                    elif select_string.__contains__(",") and not select_string.__contains__(" "):
                        sp_string = select_string.strip().split(",")
                        print(sp_string)

                        count_comma = select_string.count(",")
                        for item in range(count_comma + 1):
                            if sp_string[item] == " ":
                                print("space")
                            else:
                                data.append(dict(component_name=program_name, component_type=program_type,
                                                 Table=sp_string[item].strip().replace(";",""), CRUD="READ",
                                                 SQL=line.rstrip()))

                    elif select_string.__contains__(" ") and not select_string.__contains__(","):
                        split_string = select_string.strip().split(" ")
                        print(split_string)
                        data.append(dict(component_name=program_name, component_type=program_type,
                                         Table=split_string[0].strip().replace(";",""), CRUD="READ",
                                         SQL=line.rstrip()))

                    else:
                        data.append(dict(component_name=program_name, component_type=program_type,
                                         Table=select_string.strip().replace(";",""), CRUD="READ",
                                         SQL=line.rstrip()))
                else:
                    re_string = select_string.replace("WHERE", "WHERE PYTHON")
                    sp_string = re_string.split(" PYTHON ")
                    for str in sp_string:
                        if str.__contains__("FROM"):
                            spilted_string = after(str, " FROM ")
                            if spilted_string.__contains__(" ") and spilted_string.__contains__(","):
                                split_string = spilted_string.split(",")
                                count_comma = spilted_string.count(",")

                                for item in range(count_comma + 1):
                                    if split_string[item] == " ":
                                        print("space")
                                    else:
                                        if split_string[item].strip().__contains__(" "):
                                            split_string_spaced = split_string[item].strip().split(" ")
                                            data.append(
                                                dict(component_name=program_name, component_type=program_type,
                                                     Table=split_string_spaced[0].replace(";",""), CRUD="READ",
                                                     SQL=line.rstrip()))

                            elif spilted_string.__contains__(",") and not spilted_string.__contains__(" "):
                                sp_string = spilted_string.split(",")
                                count_comma = spilted_string.count(",")
                                for item in range(count_comma + 1):
                                    if sp_string[item] == " ":
                                        print("space")
                                    else:
                                        data.append(
                                            dict(component_name=program_name, component_type=program_type,
                                                 Table=sp_string[item].strip().replace(";",""), CRUD="READ",
                                                 SQL=line.rstrip()))

                            elif spilted_string.__contains__(" ") and not spilted_string.__contains__(","):
                                split_string = spilted_string.split(" ")
                                data.append(dict(component_name=program_name, component_type=program_type,
                                                 Table=split_string[0].strip().replace(";",""), CRUD="READ",
                                                 SQL=line.rstrip()))

                            else:
                                data.append(dict(component_name=program_name, component_type=program_type,
                                                 Table=spilted_string.strip().replace(";",""), CRUD="READ",
                                                 SQL=line.rstrip()))
                        elif str.__contains__("WHERE") and not str.__contains__("FROM"):
                            spilted_string = before(str, "WHERE")
                            if spilted_string.__contains__(" ") and spilted_string.__contains__(","):
                                split_string = spilted_string.split(",")
                                count_comma = spilted_string.count(",")

                                for item in range(count_comma + 1):
                                    if split_string[item] == " ":
                                        print("space")
                                    else:
                                        if split_string[item].strip().__contains__(" "):
                                            split_string_spaced = split_string[item].strip().split(" ")
                                            data.append(
                                                dict(component_name=program_name, component_type=program_type,
                                                     Table=split_string_spaced[0].replace(";", ""), CRUD="READ",
                                                     SQL=line.rstrip()))

                            elif spilted_string.__contains__(",") and not spilted_string.__contains__(" "):
                                sp_string = spilted_string.split(",")
                                count_comma = spilted_string.count(",")

                                for item in range(count_comma + 1):
                                    if sp_string[item] == " ":
                                        print("space")
                                    else:
                                        data.append(
                                            dict(component_name=program_name, component_type=program_type,
                                                 Table=sp_string[item].strip().replace(";",""), CRUD="READ",
                                                 SQL=line.rstrip()))

                            elif spilted_string.__contains__(" ") and not spilted_string.__contains__(","):
                                split_string = spilted_string.split(" ")
                                data.append(dict(component_name=program_name, component_type=program_type,
                                                 Table=split_string[0].strip().replace(";",""), CRUD="READ",
                                                 SQL=line.rstrip()))

                            else:
                                data.append(dict(component_name=program_name, component_type=program_type,
                                                 Table=spilted_string.strip().replace(";",""), CRUD="READ",
                                                 SQL=line.rstrip()))
                        elif str.__contains__("FROM") and str.__contains__("WHERE"):
                            spilted_string = between(str, " FROM ", " WHERE ")
                            if spilted_string.__contains__(" ") and spilted_string.__contains__(","):
                                split_string = spilted_string.split(",")
                                count_comma = spilted_string.count(",")

                                for item in range(count_comma + 1):
                                    if split_string[item] == " ":
                                        print("space")
                                    else:
                                        if split_string[item].strip().__contains__(" "):
                                            split_string_spaced = split_string[item].strip().split(" ")
                                            data.append(
                                                dict(component_name=program_name, component_type=program_type,
                                                     Table=split_string_spaced[0].replace(";",""), CRUD="READ",
                                                     SQL=line.rstrip()))

                            elif spilted_string.__contains__(",") and not spilted_string.__contains__(" "):
                                sp_string = spilted_string.split(",")

                                count_comma = spilted_string.count(",")
                                for item in range(count_comma + 1):
                                    if sp_string[item] == " ":
                                        print("space")
                                    else:
                                        data.append(
                                            dict(component_name=program_name, component_type=program_type,
                                                 Table=sp_string[item].strip().replace(";",""), CRUD="READ",
                                                 SQL=line.rstrip()))

                            elif spilted_string.__contains__(" ") and not spilted_string.__contains__(","):
                                split_string = spilted_string.split(" ")
                                data.append(dict(component_name=program_name, component_type=program_type,
                                                 Table=split_string[0].strip().replace(";",""), CRUD="READ",
                                                 SQL=line.rstrip()))

                            else:
                                data.append(dict(component_name=program_name, component_type=program_type,
                                                 Table=spilted_string.strip().replace(";",""), CRUD="READ",
                                                 SQL=line.rstrip()))
        elif item.__contains__("FROM") and item.__contains__("LEFT"):
            select_string = between(item, " FROM ", " LEFT ")

            if select_string.__contains__(" ") and select_string.__contains__(","):
                split_string = select_string.split(",")

                count_comma = select_string.count(",")

                for item in range(count_comma + 1):
                    if split_string[item] == " ":
                        print("space")
                    else:
                        if split_string[item].strip().__contains__(" "):
                            split_string_spaced = split_string[item].strip().split(" ")

                            data.append(
                                dict(component_name=program_name, component_type=program_type,
                                     Table=split_string_spaced[0].replace(";",""), CRUD="READ",
                                     SQL=line.rstrip()))
            elif select_string.__contains__(","):
                sp_string = select_string.split(",")

                count_comma = select_string.count(",")

                for item in range(count_comma + 1):
                    if sp_string[item] == " ":
                        print("space")
                    else:
                        data.append(dict(component_name=program_name, component_type=program_type,
                                         Table=sp_string[item].strip().replace(";",""), CRUD="READ",
                                         SQL=line.rstrip()))
            elif select_string.__contains__(" ") and not select_string.__contains__(","):
                split_string = select_string.split(" ")

                data.append(dict(component_name=program_name, component_type=program_type,
                                 Table=split_string[0].strip().replace(";",""), CRUD="READ",
                                 SQL=line.rstrip()))
            else:

                data.append(dict(component_name=program_name, component_type=program_type,
                                 Table=select_string.strip().replace(";",""), CRUD="READ",
                                 SQL=line.rstrip()))
            try:
                if item.__contains__("JOIN") and item.__contains__("ON"):
                    select_string = between(item, "JOIN", "ON")

                    if select_string.__contains__(","):
                        sp_string = select_string.split(",")

                        count_comma = select_string.count(",")

                        for item in range(count_comma + 1):
                            if sp_string[item] == " ":
                                print("space")
                            else:
                                data.append(dict(component_name=program_name, component_type=program_type,
                                                 Table=sp_string[item].strip().replace(";",""), CRUD="READ",
                                                 SQL=line.rstrip()))

                    elif select_string.__contains__(" ") and not select_string.__contains__(","):
                        split_string = select_string.split(" ")

                        data.append(dict(component_name=program_name, component_type=program_type,
                                         Table=split_string[1].strip().replace(";",""), CRUD="READ",
                                         SQL=line.rstrip()))

                    else:

                        data.append(dict(component_name=program_name, component_type=program_type,
                                         Table=select_string.strip().replace(";",""), CRUD="READ",
                                         SQL=line.rstrip()))
            except:
                continue
        elif item.__contains__("FROM") and item.__contains__("RIGHT"):
            select_string = between(item, " FROM ", " RIGHT ")

            if select_string.__contains__(" ") and select_string.__contains__(","):
                split_string = select_string.split(",")

                count_comma = select_string.count(",")

                for item in range(count_comma + 1):
                    if split_string[item] == " ":
                        print("space")
                    else:
                        if split_string[item].strip().__contains__(" "):
                            split_string_spaced = split_string[item].strip().split(" ")

                            data.append(
                                dict(component_name=program_name, component_type=program_type,
                                     Table=split_string_spaced[0].replace(";",""), CRUD="READ",
                                     SQL=line.rstrip()))

            elif select_string.__contains__(","):
                sp_string = select_string.split(",")

                count_comma = select_string.count(",")

                for item in range(count_comma + 1):
                    if sp_string[item] == " ":
                        print("space")
                    else:
                        data.append(dict(component_name=program_name, component_type=program_type,
                                         Table=sp_string[item].strip().replace(";",""), CRUD="READ",
                                         SQL=line.rstrip()))

            elif select_string.__contains__(" ") and not select_string.__contains__(","):
                split_string = select_string.split(" ")

                data.append(dict(component_name=program_name, component_type=program_type,
                                 Table=split_string[1].strip().replace(";",""), CRUD="READ",
                                 SQL=line.rstrip()))

            else:

                data.append(dict(component_name=program_name, component_type=program_type,
                                 Table=select_string.strip().replace(";",""), CRUD="READ",
                                 SQL=line.rstrip()))

            try:
                if item.__contains__("JOIN") and item.__contains__("ON"):
                    select_string = between(item, "JOIN", "ON")

                    if select_string.__contains__(","):
                        sp_string = select_string.split(",")

                        count_comma = select_string.count(",")

                        for item in range(count_comma + 1):
                            if sp_string[item] == " ":
                                print("space")
                            else:
                                data.append(dict(component_name=program_name, component_type=program_type,
                                                 Table=sp_string[item].strip().replace(";",""), CRUD="READ",
                                                 SQL=line.rstrip()))

                    elif select_string.__contains__(" ") and not select_string.__contains__(","):
                        split_string = select_string.split(" ")

                        data.append(dict(component_name=program_name, component_type=program_type,
                                         Table=split_string[1].strip().replace(";",""), CRUD="READ",
                                         SQL=line.rstrip()))

                    else:

                        data.append(dict(component_name=program_name, component_type=program_type,
                                         Table=select_string.strip().replace(";",""), CRUD="READ",
                                         SQL=line.rstrip()))
            except:
                continue
        elif item.__contains__("FROM") and item.__contains__("FULL"):
            select_string = between(item, " FROM ", " FULL ")

            if select_string.__contains__(" ") and select_string.__contains__(","):
                split_string = select_string.split(",")

                count_comma = select_string.count(",")

                for item in range(count_comma + 1):
                    if split_string[item] == " ":
                        print("space")
                    else:
                        if split_string[item].strip().__contains__(" "):
                            split_string_spaced = split_string[item].strip().split(" ")

                            data.append(
                                dict(component_name=program_name, component_type=program_type,
                                     Table=split_string_spaced[0].replace(";",""), CRUD="READ",
                                     SQL=line.rstrip()))

            elif select_string.__contains__(","):
                sp_string = select_string.split(",")

                count_comma = select_string.count(",")

                for item in range(count_comma + 1):
                    if sp_string[item] == " ":
                        print("space")
                    else:
                        data.append(dict(component_name=program_name, component_type=program_type,
                                         Table=sp_string[item].strip().replace(";",""), CRUD="READ",
                                         SQL=line.rstrip()))

            elif select_string.__contains__(" ") and not select_string.__contains__(","):
                split_string = select_string.split(" ")

                data.append(dict(component_name=program_name, component_type=program_type,
                                 Table=split_string[1].strip().replace(";",""), CRUD="READ",
                                 SQL=line.rstrip()))

            else:

                data.append(dict(component_name=program_name, component_type=program_type,
                                 Table=select_string.strip().replace(";",""), CRUD="READ",
                                 SQL=line.rstrip()))

            try:
                if item.__contains__("JOIN") and item.__contains__("ON"):
                    select_string = between(item, "JOIN", "ON")

                    if select_string.__contains__(","):
                        sp_string = select_string.split(",")

                        count_comma = select_string.count(",")

                        for item in range(count_comma + 1):
                            if sp_string[item] == " ":
                                print("space")
                            else:
                                data.append(dict(component_name=program_name, component_type=program_type,
                                                 Table=sp_string[item].strip().replace(";",""), CRUD="READ",
                                                 SQL=line.rstrip()))

                    elif select_string.__contains__(" ") and not select_string.__contains__(","):
                        split_string = select_string.split(" ")

                        data.append(dict(component_name=program_name, component_type=program_type,
                                         Table=split_string[1].strip().replace(";",""), CRUD="READ",
                                         SQL=line.rstrip()))

                    else:

                        data.append(dict(component_name=program_name, component_type=program_type,
                                         Table=select_string.strip().replace(";",""), CRUD="READ",
                                         SQL=line.rstrip()))
            except:
                continue
        elif item.__contains__("FROM") and item.__contains__("INNER"):
            select_string = between(item, " FROM ", " INNER ")

            if select_string.__contains__(" ") and select_string.__contains__(","):
                split_string = select_string.split(",")

                count_comma = select_string.count(",")

                for item in range(count_comma + 1):
                    if split_string[item] == " ":
                        print("space")
                    else:
                        if split_string[item].strip().__contains__(" "):
                            split_string_spaced = split_string[item].strip().split(" ")

                            data.append(
                                dict(component_name=program_name, component_type=program_type,
                                     Table=split_string_spaced[0].replace(";",""), CRUD="READ",
                                     SQL=line.rstrip()))

            elif select_string.__contains__(","):

                sp_string = select_string.split(",")

                count_comma = select_string.count(",")

                for item in range(count_comma + 1):
                    if sp_string[item] == " ":
                        print("space")
                    else:
                        data.append(dict(component_name=program_name, component_type=program_type,
                                         Table=sp_string[item].strip().replace(";",""), CRUD="READ",
                                         SQL=line.rstrip()))

            elif select_string.__contains__(" ") and not select_string.__contains__(","):

                split_string = select_string.split(" ")

                data.append(dict(component_name=program_name, component_type=program_type,
                                 Table=split_string[0].strip().replace(";",""), CRUD="READ",
                                 SQL=line.rstrip()))

            else:
                data.append(dict(component_name=program_name, component_type=program_type,
                                 Table=select_string.strip().replace(";",""), CRUD="READ",
                                 SQL=line.rstrip()))

            try:
                if item.__contains__("JOIN") and item.__contains__("ON"):
                    select_string = between(item, "JOIN", "ON")

                    if select_string.__contains__(","):
                        sp_string = select_string.split(",")

                        count_comma = select_string.count(",")

                        for item in range(count_comma + 1):
                            if sp_string[item] == " ":
                                print("space")
                            else:
                                data.append(dict(component_name=program_name, component_type=program_type,
                                                 Table=sp_string[item].strip().replace(";",""), CRUD="READ",
                                                 SQL=line.rstrip()))

                    elif select_string.__contains__(" ") and not select_string.__contains__(","):
                        split_string = select_string.split(" ")

                        data.append(dict(component_name=program_name, component_type=program_type,
                                         Table=split_string[1].strip().replace(";",""), CRUD="READ",
                                         SQL=line.rstrip()))

                    else:

                        data.append(dict(component_name=program_name, component_type=program_type,
                                         Table=select_string.strip().replace(";",""), CRUD="READ",
                                         SQL=line.rstrip()))
            except:
                continue
        elif item.__contains__("FROM") and item.__contains__("JOIN"):
            select_string = between(item, " FROM ", " JOIN ")

            if select_string.__contains__(" ") and select_string.__contains__(","):
                split_string = select_string.strip().split(",")

                count_comma = select_string.count(",")

                for item in range(count_comma + 1):
                    if split_string[item] == " ":
                        print("space")
                    else:
                        if split_string[item].strip().__contains__(" "):
                            split_string_spaced = split_string[item].strip().split(" ")

                            data.append(
                                dict(component_name=program_name, component_type=program_type,
                                     Table=split_string_spaced[0].replace(";",""), CRUD="READ",
                                     SQL=line.rstrip()))

            elif select_string.__contains__(","):
                sp_string = select_string.split(",")

                count_comma = select_string.count(",")

                for item in range(count_comma + 1):
                    if sp_string[item] == " ":
                        print("space")
                    else:
                        data.append(dict(component_name=program_name, component_type=program_type,
                                         Table=sp_string[item].strip().replace(";",""), CRUD="READ",
                                         SQL=line.rstrip()))

            elif select_string.__contains__(" ") and not select_string.__contains__(","):
                split_string = select_string.split(" ")

                data.append(dict(component_name=program_name, component_type=program_type,
                                 Table=split_string[1].strip().replace(";",""), CRUD="READ",
                                 SQL=line.rstrip()))

            else:

                data.append(dict(component_name=program_name, component_type=program_type,
                                 Table=select_string.strip().replace(";",""), CRUD="READ",
                                 SQL=line.rstrip()))

            try:
                if item.__contains__("JOIN") and item.__contains__("ON"):
                    select_string = between(item, "JOIN", "ON")

                    if select_string.__contains__(","):
                        sp_string = select_string.split(",")

                        count_comma = select_string.count(",")

                        for item in range(count_comma + 1):
                            if sp_string[item] == " ":
                                print("space")
                            else:
                                data.append(dict(component_name=program_name, component_type=program_type,
                                                 Table=sp_string[item].strip().replace(";",""), CRUD="READ",
                                                 SQL=line.rstrip()))

                    elif select_string.__contains__(" ") and not select_string.__contains__(","):
                        split_string = select_string.split(" ")

                        data.append(dict(component_name=program_name, component_type=program_type,
                                         Table=split_string[1].strip().replace(";",""), CRUD="READ",
                                         SQL=line.rstrip()))

                    else:

                        data.append(dict(component_name=program_name, component_type=program_type,
                                         Table=select_string.strip().replace(";",""), CRUD="READ",
                                         SQL=line.rstrip()))
            except:
                continue
        elif item.__contains__("FROM") and not item.__contains__("WHERE") and not item.__contains__(
                "ORDER BY") and not item.__contains__("GROUP BY"):

            select_string = after(item, " FROM ")
            print("-----", select_string)
            if select_string.strip() == " ":
                print("ok,-----")
            elif select_string.strip() == "(":
                print("bracket")
            elif select_string.__contains__(","):
                split_string = select_string.split(",")

                count = select_string.count(",")

                for item in range(count + 1):

                    if split_string[item] == " ":
                        print("Space")
                    else:
                        data.append(dict(component_name=program_name, component_type=program_type,
                                         Table=split_string[item].strip().replace(";",""), CRUD="READ",
                                         SQL=line))

            else:

                if select_string.__contains__("\n") and select_string.__contains__("."):
                    replaced_string = select_string.replace("\n", "") and select_string.replace(".", "")
                    data.append(dict(component_name=program_name, component_type=program_type,
                                     Table=replaced_string.replace("\n", "").strip().replace(";",""), CRUD="READ",
                                     SQL=line))


                else:
                    data.append(dict(component_name=program_name, component_type=program_type,
                                     Table=select_string.strip().replace(";",""), CRUD="READ",
                                     SQL=line))
            try:
                if item.__contains__("JOIN") and item.__contains__("ON"):
                    select_string = between(item, "JOIN", "ON")

                    if select_string.__contains__(","):
                        sp_string = select_string.split(",")

                        count_comma = select_string.count(",")

                        for item in range(count_comma + 1):
                            if sp_string[item] == " ":
                                print("space")
                            else:
                                data.append(dict(component_name=program_name, component_type=program_type,
                                                 Table=sp_string[item].strip().replace(";",""), CRUD="READ",
                                                 SQL=line))

                    elif select_string.__contains__(" ") and not select_string.__contains__(","):
                        split_string = select_string.split(" ")

                        data.append(dict(component_name=program_name, component_type=program_type,
                                         Table=split_string[1].strip().replace(";",""), CRUD="READ",
                                         SQL=line.rstrip()))

                    else:

                        data.append(dict(component_name=program_name, component_type=program_type,
                                         Table=select_string.strip().replace(";",""), CRUD="READ",
                                         SQL=line.rstrip()))
            except:
                continue
        elif options == "SELECT":
            continue
        elif options == "UPDATE":
            if " SET " in line:
                update_string = between(line, "UPDATE", "SET")

                if update_string.__contains__(","):
                    split_string = update_string.split(",")

                    count = update_string.count(",")

                    for item in range(count + 1):

                        if split_string[item] == " ":
                            print("Space")
                        else:
                            data.append(dict(component_name=program_name, component_type=program_type,
                                             Table=split_string[item].strip().replace(";",""), CRUD="UPDATE",
                                             SQL=line.rstrip()))

                else:
                    data.append(dict(component_name=program_name, component_type=program_type,
                                     Table=update_string.strip().replace(";",""), CRUD="UPDATE",
                                     SQL=line.rstrip()))
            else:
                print("there is no set")
        elif options == "INSERT":
            insert_string = after(line, " INTO ")

            spilted_insert_string = insert_string.split(" ")

            data.append(dict(component_name=program_name, component_type=program_type,
                             Table=spilted_insert_string[0].strip().replace(";",""), CRUD="CREATE",
                             SQL=line.rstrip()))
        elif options == "DELETE":
            print("it came here")
            delete_string = between(line, "FROM", "WHERE")

            if delete_string.__contains__(","):
                split_string = delete_string.split(",")

                count = delete_string.count(",")

                for item in range(count + 1):

                    if split_string[item] == " ":
                        print("Space")
                    else:
                        data.append(dict(component_name=program_name, component_type=program_type,
                                         Table=split_string[item].strip().replace(";",""), CRUD="DELETE",
                                         SQL=line.rstrip()))

            else:
                data.append(dict(component_name=program_name, component_type=program_type,
                                 Table=delete_string.strip().replace(";",""), CRUD="DELETE",
                                 SQL=line.rstrip()))


#  Getting all .cbl files in a particular folder.
try:
    Xinsert_filedata = "Except insert.txt"

    Xinsert_Update_filedata = "Except insert update.txt"

    Xinsert_Update_Delete_filedata = "Except insert update delete.txt"

    Xinsert_Update_Delete_Select_filedata = "Except insert update delete select.txt"

    source_temp_file = "source data.txt"

    program_type = ""
    os.path.exists(pkg_org_path+"\\"+"PACKAGE")
    os.chdir(pkg_org_path+"\\"+"PACKAGE")
    path, dirs, files = next(os.walk(pkg_org_path+"\\"+"PACKAGE"))
    file_count = len(files)
    if file_count == 0:
        print("There is no file inside PACKAGE folder")
    pkgCounter = len(glob.glob1(pkg_org_path+"\\"+"PACKAGE", "*.*"))
    if pkgCounter == 0:
        print("There is no .pkb file inside the folder.")
    else:
        print("Out of " + str(file_count) + " files only " + str(pkgCounter) + " are PKB files.Processing those files.")
    i = 0
    os.chdir(pkg_org_path+"\\"+"PACKAGE")
    for file in glob.glob("*.*"):
        print("CRUD processing the ", file)
        i = i + 1
        filename, file_extension = os.path.splitext(file)
        print(file, "gomathi")
        program_name = filename
        if file_extension == ".pkb":
            program_type = "PACKAGE BODY"
        elif file_extension == ".prc":
            program_type = "PROCEDURE"
        elif file_extension == ".fnc":
            program_type = "FUNCTION"
        elif file_extension == ".trg":
            program_type = "TRIGGER"

        # program_type = "PACKAGE BODY"

        # opening a file
        with open(file, "r") as file1:
            filedata = file1.readlines()

        for l in filedata:
            with open("source data.txt", "a")as file2:
                file2.write(l)

        # Extracting the all sql queries inside a file and writing it into a temp_file
        process_for_extracting_query("INSERT ", source_temp_file, Xinsert_filedata)
        process_for_extracting_query("UPDATE ", Xinsert_filedata, Xinsert_Update_filedata)
        process_for_extracting_query("DELETE ", Xinsert_Update_filedata, Xinsert_Update_Delete_filedata)
        process_for_extracting_query("SELECT ", Xinsert_Update_Delete_filedata, Xinsert_Update_Delete_Select_filedata)

        exists = os.path.isfile(Xinsert_Update_Delete_Select_filedata)
        if exists:
            # Reading a file and keeping it into a data_file variable
            with open(Query_file, "r") as temp_file_spaced1:
                data_file = temp_file_spaced1.readlines()
                print(type(data_file))

                # Iterating over all the cbl files in the folder
            for line in data_file:

                # Selecting the lines containing only a "SELECT" and extracting the details.
                if line.__contains__("SELECT") and not line.__contains__("UPDATE") and not line.__contains__(
                        "INSERT") and not line.__contains__("DELETE"):

                    process(line, "SELECT")

                # Selecting the lines containing only a "INSERT" and extracting the details.
                elif line.__contains__("INSERT") and not line.__contains__("SELECT") and not line.__contains__(
                        "UPDATE") and not line.__contains__("DELETE"):
                    insert_string = after(line, " INTO ")

                    spilted_insert_string = insert_string.split(" ")

                    data.append(dict(component_name=program_name, component_type=program_type,
                                     Table=spilted_insert_string[0].strip().replace(";", ""), CRUD="CREATE",
                                     SQL=line.rstrip()))

                #  Selecting the lines containing only a "UPDATE" and extracting the details.
                elif line.__contains__("UPDATE") and not line.__contains__("SELECT") and not line.__contains__(
                        "INSERT") and not line.__contains__("DELETE"):

                    update_string = between(line, "UPDATE ", "SET")
                    if update_string.__contains__(","):
                        split_string = update_string.split(",")
                        count = update_string.count(",")
                        for item in range(count + 1):
                            if split_string[item] == " ":
                                print("Space")
                            else:
                                data.append(dict(component_name=program_name, component_type=program_type,
                                                 Table=split_string[item].strip().replace(";", ""), CRUD="UPDATE",
                                                 SQL=line))
                    else:
                        data.append(dict(component_name=program_name, component_type=program_type,
                                         Table=update_string.strip().replace(";", ""), CRUD="UPDATE",
                                         SQL=line.rstrip()))

                #  Selecting the lines containing only a "DELETE" and extracting the details.
                elif line.__contains__("DELETE") and not line.__contains__("SELECT") and not line.__contains__(
                        "INSERT") and not line.__contains__("UPDATE"):
                    print("yes")
                    if "WHERE" in line:
                        delete_string = between(line, "FROM", "WHERE")
                        if delete_string.__contains__(","):
                            split_string = delete_string.split(",")
                            count = delete_string.count(",")
                            for item in range(count + 1):
                                if split_string[item] == " ":
                                    print("Space")
                                else:
                                    data.append(dict(component_name=program_name, component_type=program_type,
                                                     Table=split_string[item].strip().replace(";", ""), CRUD="DELETE",
                                                     SQL=line.rstrip()))
                        else:
                            data.append(dict(component_name=program_name, component_type=program_type,
                                             Table=delete_string.strip().replace(";", ""), CRUD="DELETE",
                                             SQL=line.rstrip()))
                    else:
                        delete_string = after(line, " FROM ")
                        if delete_string.__contains__(","):
                            split_string = delete_string.split(",")

                            count = delete_string.count(",")

                            for item in range(count + 1):

                                if split_string[item] == " ":
                                    print("Space")
                                else:
                                    data.append(dict(component_name=program_name, component_type=program_type,
                                                     Table=split_string[item].strip().replace(";", ""), CRUD="DELETE",
                                                     SQL=line.rstrip()))

                        else:
                            data.append(dict(component_name=program_name, component_type=program_type,
                                             Table=delete_string.strip().replace(";", ""), CRUD="DELETE",
                                             SQL=line.rstrip()))

                #  Selecting the lines containing only a "UPDATE"& "SELECT" and extracting the details.
                elif line.__contains__("UPDATE") and line.__contains__("SELECT"):
                    process(line, "UPDATE")

                #  Selecting the lines containing only a "INSERT" & "SELECT" and extracting the details.
                elif line.__contains__("INSERT") and line.__contains__("SELECT"):
                    process(line, "INSERT")

                #  Selecting the lines containing only a "DELETE" & "SELECT" and extracting the details.
                elif line.__contains__("DELETE") and line.__contains__("SELECT"):
                    print("yes")
                    process(line, "DELETE")


        else:
            print(file + " - doesn't containing SQL statements")
        os.chdir("./")
        read_files = glob.glob("*.txt")
        with open(".././Result.txt", "a") as outfile:
            for f in read_files:
                if f == "Query data.txt":
                    with open(f, "r") as infile:
                        outfile.write(program_name+"\n")
                        outfile.write(infile.read())
                        outfile.write("\n--------------------------------------------------------------------------------\n")
                os.remove(f)
        # with os.scandir("./") as entries:
        #     for entry in entries:
        #         if entry.is_file():
        #             if entry.name =="Query data.txt"
        #             print(entry.name)
except:
    print("There is no folder,named PACKAGE")


print(json.dumps(data,indent=4))
print(len(data))

# Writing the data into the CSV file
keys = data[0].keys()

with open('../CRUD.csv', 'w', newline="") as output_file:
    dict_writer = csv.DictWriter(output_file, keys)
    dict_writer.writeheader()
    dict_writer.writerows(data)
json_file = {'headers': ['component_name', 'component_type', 'Table', 'CRUD', 'SQL'], 'data': data}
json_val = json.dumps(json_file)
print(json_val)

# # posting a request
r = requests.post('http://localhost:5009/api/v1/update/CRUD',
                  json={"data": data, "headers": ['component_name', 'component_type', 'Table', 'CRUD', 'SQL']})
print(r.status_code)
print(r.text)

# os.chdir("./")
# read_files = glob.glob("*.txt")
# with open(".././Result.txt", "wb") as outfile:
#     for f in read_files:
#         with open(f, "rb") as infile:
#             outfile.write(infile.read())
#         os.remove(f)

cwd = os.getcwd()
print(cwd)

# for root, dirs, files in os.walk("."):
#     for filename in files:
#         os.remove(filename)
# try:
#     # shutil.rmtree(cwd)
#     os.rmdir(cwd)
# except OSError as e:
#     print("Error: %s - %s." % (e.filename, e.strerror))

