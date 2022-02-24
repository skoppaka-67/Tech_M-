import glob, os, json
# import plsql_config
from collections import OrderedDict
import pandas as pd
# import requests
from pymongo import MongoClient

client = MongoClient("localhost", port=27017)  ##connecting to mongodb server

db = client["plsql"]  ##accessing database from mongodb
data = db.master_inventory_report  ##acessing collection in the database and calling it as data
# file = plsql_config


file = {'D:\\WORK\\plsql\\PKB\\': '*.pkb',
        'D:\\WORK\\plsql\\PKS': '*.pks'}  ##taking file location as key and filetype as key value
# file = {'D:\\plsql\\PKB': '*.pkb',
# 'D:\\plsql\\PKS': '*.pks'}
# print(file)

METADATA = []
exec_lines = 0
total_comment_lines = 0


def main():
    for file_location, file_type in file.items():  ##taking key as file location and value as file type in file dictionary
        for filename in glob.glob(os.path.join(file_location,
                                               file_type)):  ##access files one by one that ends with .pkb, and joining file path with folder
            """
                            1.if file type is .pkb type becomes package body,
                            2.if file name ends with .pks it is package specification and if it is true we are printing failure
                            3.if file name ends with .prc it is procedure
                            4.if file name ends with .fnc it is function type
                            5.if file name ends with .trg it is trigger
                            6.we are calling programType function for each file type to count total number of lines , 
                            empty lines, comment lines , block comments and source lines of code 
                            """
            if file_type == "*.pkb":
                Type = "Package Body"
                ProgramType(filename, Type, file_location)
                print("Success_pkb")
            elif file_type == "*.pks":
                Type = "Package Specification"
                ProgramType(filename, Type, file_location)
                print("Failure")
            elif file_type == "*.prc":
                Type = "Procedure"
                ProgramType(filename, Type, file_location)
                print("Procedure")
            elif file_type == "*.fnc":
                Type = "Function"
                ProgramType(filename, Type, file_location)
                print("Function")
            elif file_type == "*.trg":
                Type = "Trigger"
                ProgramType(filename, Type, file_location)
                print("Trigger")


def procedures(files, Type):
    """

    This function is to count empty lines, block comments, single line comments, blank lines, total number of lines,
    source lines of code between a procedure in a pkb file

    :param files: take  file name as paramater from main function
    :return:
    """
    f = open(files, 'r')  ##opens file in a read mode

    storage = []

    flag = False
    comment_flag = False
    total_lines = 0
    empty_lines = 0
    comment_lines = 0
    block_comment_counter = 0
    sloc = 0
    if_count = 0
    when = 0

    for_count = 0
    cyclomatic_complexity = 0
    procedure_name = ""
    block_comment_flag = False

    schema = ''

    for line in f.readlines():  ##access lines one by one from file
        if line.strip().startswith('CREATE') and line.__contains__('PACKAGE BODY') and Type == "Package Body":
            line.strip()
            b = line.split('PACKAGE BODY')
            schema_old = b[1]
            c = schema_old.split('.')
            schema = "".join(c[0])

        if line.strip().startswith('PROCEDURE'):  ##access lines which are starting with procedure
            flag = True  ##changing flag to true untill the condition satisfies

            a = line.split()  ##splitting line using split() function so that each word seperated by a space will store in a list with proper indexes
            procedure_name = a[
                1]  ##line starts with procedure and the next word will be the procedure name, so we are storing a[1] in procedure name

        if flag and line.strip().startswith(
                'END' + ' ' + procedure_name):  ##access the lines which are starting with end followed by procedure name

            storage.append(line)  ##adding line to storage list
            flag = False  ##changing flag to false if condition satisfies

            total_lines = len(storage)
            """
            we are adding every line from starting with procedure and ending with procedure name
            so we have every line between procedure in storage
            1.total lines(LOC) is nothing but length of the list storage
            2.to get main executable lines we are adding comment,block,empty lines and subtracting from total lines
            3.storing all information about every procedure in output dictionary

            """
            total_useless = comment_lines + empty_lines + block_comment_counter
            sloc = total_lines - total_useless
            cyclomatic_complexity = for_count + if_count + when
            if cyclomatic_complexity > 0:
                cyclomatic_complexity += 1
            else:
                cyclomatic_complexity = 0

            output = {
                "file_name": files.split("\\")[-1].split(".")[0],
                'schema': schema,
                "component_name": procedure_name,
                "component_type": "PROCEDURE",
                "Loc": total_lines,
                "commented_lines": comment_lines + block_comment_counter,
                "blank_lines": empty_lines,
                "Sloc": sloc,
                "application": "UNKNOWN",
                "cyclomatic_complexity": cyclomatic_complexity

            }

            METADATA.append(output)  ##adding procedures data into METADATA list

            empty_lines = 0  ##changing lines to 0 at the end of each procedure
            comment_lines = 0
            block_comment_counter = 0
            if_count = 0
            when = 0

            for_count = 0
            cyclomatic_complexity = 0
            storage.clear()

        if flag:  ##if line starts with procedure flag will be true
            """
            1.we are adding line by line inside procedure to storage list
            2.if line starts with -- then it is single line comment line and comment lines are counted and stored in comment lines
            3.if line starts with /*, we are changing block_comment_flag to True and line ends with */ we are changing to False
              until the block_comment_flag is false we count lines and stored in block_comment_counter
            4.if line is empty then that line is counted as empty line and stored in empty_lines
            5.accessing lines starting with for, when,if, and elsif 
            6.calculating cyclomatic complexity by adding if, for and when count
            7. we update all the information in output dictionary and append it to metadata
            """
            storage.append(line)
            if line.strip().startswith('IF ') or line.strip().startswith('ELSIF '):
                if_count += 1

            if line.strip().startswith('WHEN'):
                when += 1
                # print(line)

            if line.strip().startswith('FOR'):
                for_count += 1
                # print(line)

            if line.strip().startswith('--'):
                comment_lines += 1
            if line.strip().startswith("/*"):
                block_comment_flag = True

            if block_comment_flag:
                block_comment_counter = block_comment_counter + 1
            if line.strip().endswith("*/"):
                block_comment_flag = False

            if line.startswith('') and line.strip() == '':
                empty_lines += 1


def ProgramType(filename, Type, file_location):
    """

    Bhavya
    1.this function will open file in read mode and count total lines, empty lines, comment lines and executable lines
    2.we are calling procedures function for counting data between procedures for each file
    :param filename: file name from main function
    :param Type:accessing type of a file from main function
    :param file_location: accessing file location from main function
    :return:
    """
    ModuleName = filename
    ModuleType = Type
    # print("Module:",ModuleName)
    f = open(ModuleName, "r")  ##opening file in read mode
    comment_lines = 0
    empty_lines = 0
    total_lines = 0
    if_count = 0
    when = 0
    schema = ""

    for_count = 0
    cyclomatic_complexity = 0

    comment_flag = False
    block_comment_counter = 1
    total_count = 0
    for line in f.readlines():  ##accessing line by line from file
        """
        1.if line starts with -- then it is comment line
        2.if line starts with /*  we are changing comment_flag to true and ends with */ it will be false
        until the comment flag is false we are counting the lines and storing in block_comment_counter
        3.if line is empty then we are adding into empty_lines  
        5.accessing lines starting with for, when,if, and elsif 
        6.calculating cyclomatic complexity by adding if, for and when count
        7. we update all the information in output dictionary and append it to metadata
        """

        line = line.strip()  ##removing blank spaces in starting and ending of the line if consists
        total_lines = total_lines + 1  ##counting lines in a file and storing in total lines
        # print(line)
        if line.strip().startswith('CREATE') and line.__contains__('PACKAGE BODY') and Type == "Package Body":
            line.strip()
            b = line.split('PACKAGE BODY')
            schema_old = b[1]
            c = schema_old.split('.')
            schema = "".join(c[0])
        if line.strip().startswith('CREATE') and line.__contains__('PACKAGE') and Type == "Package Specification":
            line.strip()
            d = line.split('PACKAGE')
            # print(b)
            schema_old = d[1]
            e = schema_old.split('.')
            # print(schema_old)
            schema = ''.join(e[0])

        if line.strip().startswith('IF ') or line.strip().startswith('ELSIF '):
            if_count += 1

        if line.strip().startswith('WHEN'):
            when += 1
            # print(line)

        if line.strip().startswith('FOR'):
            for_count += 1
            # print(line)
        if line.endswith("*/"):
            total_count += block_comment_counter + 1  ##the ending line of block comment and lines between block are adding and storing in total count
            block_comment_counter = 1
            comment_flag = False
        if comment_flag:
            block_comment_counter = block_comment_counter + 1
            continue
        if line.startswith("/*"):
            # print(line)
            comment_flag = True

        if line.startswith("--"):
            comment_lines = comment_lines + 1

        if line == "":
            empty_lines = empty_lines + 1

    total_comment_lines = total_count + comment_lines  ##to get executable lines(SLOC) we are subtracting block comments,single line comments and empty lines
    exec_lines = total_lines - (total_comment_lines + empty_lines)

    # print("Total_lines:",total_lines)
    # print("Comment_lines:",comment_lines)
    # print("Bound_lines:",total_count)
    # print("Empty_lines:",empty_lines)
    # print("Exec_lines:",exec_lines)
    # print("Total_comment_lines:",total_comment_lines)
    cyclomatic_complexity = for_count + if_count + when
    if cyclomatic_complexity > 0:
        cyclomatic_complexity += 1
    else:
        cyclomatic_complexity = 0

    METADATA.append({
        "file_name":ModuleName.split("\\")[-1].split(".")[0],
        'component_name': ModuleName.split("\\")[-1].split(".")[0],
        'schema': schema,
        'component_type': ModuleType,
        'Loc': total_lines,
        'commented_lines': total_comment_lines,
        'blank_lines': empty_lines,
        'Sloc': exec_lines,
        'application': 'UNKNOWN',
        'cyclomatic_complexity': cyclomatic_complexity,
        # 'no_of_dead_lines':'',
        # 'dead_para_count':'',
        # 'total_para_count': ''
    })  ##adding all the information about lines into a list, METADATA.

    procedures(filename, Type)
    """
    takes file name as parameter and provides information about procedures in a file
    """


main()

df = pd.DataFrame(METADATA)
writer = pd.ExcelWriter('MasterInventory11.xlsx', engine='xlsxwriter')
df.to_excel(writer, 'Sheet1', index=False)
writer.save()
print(json.dumps(METADATA, indent=4))
try:
    data.remove()  ## if insert function is executed, prints successful otherwise it will prints fail
    data.insert_one({"type": "metadata",
                     "headers": [
                         "file_name",
                         "schema",
                         "component_name",
                         "component_type",
                         "Loc",
                         "commented_lines",
                         "blank_lines",
                         "Sloc",
                         "application",
                         "cyclomatic_complexity"
                     ]})
    data.insert_many(METADATA)

    print('data update successful')
except:
    print('fail')

# print(json.dumps(METADATA,indent=4))

# r = requests.post('http://localhost:5009/api/v1/update/masterInventory', json={"data":METADATA,"headers":["component_name","component_type","Loc","commented_lines","blank_lines","Sloc","application", "cyclomatic_complexity"]})
# print(r.status_code)
# print(r.text)
