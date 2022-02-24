SCRIPT_VERSION = 'v0.3 opening copybooks included'

from pymongo import MongoClient

import glob, copy, os, re
import json
import requests
import pandas as pd
from pandas import ExcelWriter
import linecache
from collections import OrderedDict
import ast
import config

sp_list = ""
case = "caseq"
begin ="DEFINE"
search_element=["begsr","exsr","caseq"]
end = "END-SUBROUTINE"
call_sub = "exsr"
begin_sr = []     #list of All begin subroutines
execute_sr = []   # list of all execute subroutines
lines=[]
to = []
From=" "
fun_repositary=OrderedDict()
child_fun = []
master_alive = set()
Dead_keys= set()
main_excsr = []
METADATA=OrderedDict()
count_of_dead_lines=[0]
dead_para_count=[]
dead_para_list=[]
dead_para_list1=" "
total_para_count=[]
tempfilename=''
dead_Metadata=OrderedDict()
output = {}
row = OrderedDict()



CopyPath = config.CopyPath
file = config.file

client = MongoClient('localhost', 27017)
db = client['BNSF_NAT_SSI']


# client = MongoClient(config1.database['mongo_endpoint_url'])
# db = client[config1.database['database_name']]

def is_empty(any_structure):
    if any_structure:
        #print('Structure is not empty.')
        return False
    else:
        #print('Structure is empty.')
        return True

def expand_copybooks(filename):
    #print(filename)
    file_handle = open(filename, "r")
    for line in file_handle:
        try:
            if line[6]== ("*") :
                continue
            else:
                line = line[6:]
                copyfile = open("copyexpanded.txt", "a")


            if re.search("INCLUDE.*",line):


                sp_list = line.split()

                copyname = sp_list[1]

                copyname = copyname + '.cpy'

                Copyfilepath = CopyPath + '\\' + copyname

                if os.path.isfile(Copyfilepath):
                    tempcopyfile = open(os.path.join(CopyPath, copyname), "r")
                    copyfile.write("#########" + " " + "BEGIN" + " " + line + '\n')
                    for copylines in tempcopyfile.readlines():
                        copyfile.write(copylines)
                        copyfile.write('\n')
                    copyfile.write("#####" + " " + "COPY END" + "####" + '\n')

            copyfile.write(line)

            copyfile.close()

        except Exception:

            pass





def read_lines(filename):

    dict = OrderedDict()
    dict_dead = OrderedDict()
    flag = False
    data = []
    file_handle = open(filename, "r")
    fun_name = ''
    count = 0
    storage = []
    begin_counter = 0
    for line in file_handle:

        try:

            if re.search(end, line) or re.search("RETURN", line):  # counting lines
                # print('end number', index)
                #print(dict)
                dict[fun_name] = copy.deepcopy(storage)
                storage.clear()
                fun_name = " "
                dict_dead[fun_name] = count
                count = 2

                flag = False
                #  print(line + '------------------------------------------')
            if flag:
                count = count + 1
                storage.append(line.strip())

            if re.search(begin, line) :

                if re.search("DEFINE DATA",line) or re.search("REDEFINE",line) or re.search ("END-DEFINE",line):
                    continue
                #print(line)
                else:
                    flag = True
                    if line.__contains__("/*"):
                        line = line.split("/*")[0]
                    new_line1 = line.split()
                    temp_fun_name = new_line1[-1]
                    if new_line1[-2].__contains__("/*"):
                        fun_name = new_line1[-3]

                    else:
                        fun_name = temp_fun_name


        except Exception:
            print("Error in ",filename)
            pass

    return dict

def findAliveChildren(ele):

   try:
    if fun_repositary[ele] == []:

        master_alive.add(ele)
        return
    else:
        for item in fun_repositary[ele]:
            master_alive.add(ele)
            if item in master_alive:

                continue
            else:

             master_alive.add(item)
             findAliveChildren(item)
   except KeyError :
       return

def find_the_main(filename):
    main_excsr.clear()
    file_handle = open(filename, "r")
    Lines_until_begsr=[]
    lines_List = []

    for line in file_handle.readlines():

        if re.search("DEFINE DATA", line) or re.search("REDEFINE", line) or re.search("END-DEFINE", line) or re.search("DEFINE WINDOW",line):
            continue

        # if re.search(begin, line):
        #     break
        # elif (re.search('\s\scas.*', line, re.IGNORECASE)):
        #     value_list1 = line.split()
        #     var = len(value_list1)
        #     fun_name = value_list1[var - 1]
        #     main_excsr.append(fun_name)
        else:
            Lines_until_begsr.append(line)

    for lines in Lines_until_begsr:
       if  re.search("PERFORM .*", lines):
            line = lines.split()
            try:
                if line[1].__contains__("PERFORM"):
                    index = line.index("PERFORM")
                    main_excsr.append(line[index + 1])

                elif line[0].__contains__("WHEN"):
                    index = line.index("PERFORM")
                    main_excsr.append(line[index + 1])

                elif line[0].__contains__("PERFORM"):
                    index = line.index("PERFORM")
                    main_excsr.append(line[index + 1])


                else:
                    main_excsr.append(line[1])
            except ValueError as e:
                pass




   # print(main_excsr)

    return main_excsr

def main():
    for file_location, file_type in file.items():
        for filename in glob.glob(os.path.join(file_location, file_type)):
            tempfilename = filename


            filename = filename.split("\\")[-1]
            #print(filename)


            expand_copybooks(tempfilename)

            METADATA[filename]=[]

            output = (read_lines('copyexpanded.txt'))
            #print(json.dumps(output,indent=4))



            fun_repositary.clear()

            master_alive.clear()

            count_of_dead_lines.clear()
            #print(json.dumps(output,indent=4))
            for key in output:

                for i in output[key]:

                    # value_list =i.split()

                    # if  (value_list.__contains__("PERFORM")):
                    #     index_exsr = value_list.index("PERFORM")
                    if re.search("PERFORM .*", i):
                        line = i.split()
                        try:
                            if line[1].__contains__("PERFORM"):
                                index = line.index("PERFORM")
                                child_fun.append(line[index + 1])
                            else:
                                child_fun.append(line[1])
                        except ValueError as e:
                            pass

                        #child_fun.append(value_list[index_exsr+1].strip(';')) #values of assocative function names which are having exsr in output dict values


                #print(child_fun)

                fun_repositary[key ] =copy.deepcopy(child_fun)
                #print(json.dumps(fun_repositary,indent=4))

                child_fun.clear()
                find_the_main('copyexpanded.txt')

            for ele in main_excsr:
                findAliveChildren(ele)


            Dead_keys = (set(fun_repositary.keys() - master_alive))
            while (" " in Dead_keys) :
                Dead_keys.remove(" ")

            while ("" in Dead_keys) :
                Dead_keys.remove("")

            for item2 in main_excsr:

                row ={"from": "Main","to" : item2,"Name":"Main" }

                METADATA[filename].append(row)


            for item1 in master_alive:
                try:
                    for i in fun_repositary[item1]:
                        name = item1
                        to = i
                        row = {"from": name, "to": to, "Name": name}
                        METADATA[filename].append(row)
                except KeyError as ky:
                    print("Perform with out def found",ky)

            #print(json.dumps(METADATA, indent=4))
            #dead_lines_count = 0
            for item3 in Dead_keys:

                dead_lines_count=2
                for i in output[item3]:
                    #print(item3)
                    dead_lines_count = dead_lines_count+1
                count_of_dead_lines.append(dead_lines_count)
               # print(dead_lines_count)

            if Dead_keys != {""}:
                dead_para_count=len(Dead_keys)
            else:
                dead_para_count = 0

            dead_para_list= list(Dead_keys)
            dead_para_list1 = ",".join(dead_para_list)

            #print(dead_para_list1)

            if is_empty(output):
                total_para_count = 0
            else:

                total_para_count = len(output.keys())
            no_of_dead_lines = sum(count_of_dead_lines)
            component_name = filename
            #print(component_name)RESET

            #print(no_of_dead_lines)

            payload ={"component_name": component_name}, {
                "$set": {"dead_para_count": dead_para_count,"dead_para_list":dead_para_list1,
                         "no_of_dead_lines": no_of_dead_lines, 'total_para_count': total_para_count}}

            #payload = json.dumps(payload)
           # print(json.dumps(payload,indent=4))



            db.master_inventory_report.update_many({"component_name": component_name}, {
                "$set": {"dead_para_count": dead_para_count,"dead_para_list":dead_para_list1,
                         "no_of_dead_lines": no_of_dead_lines, 'total_para_count': total_para_count}})
            # print(dead_para_list)

            os.remove('copyexpanded.txt')
            output.clear()
            fun_repositary.clear()
            master_alive.clear()
            main_excsr.clear()
            master_alive.clear()
            #print("-------------------------")

            #print(json.dumps(payload, indent=4))
        print(json.dumps(METADATA,indent = 4 ))
        # j = json.dumps(METADATA,indent = 4)
        # f = open("ProcessFlow.txt ", "w")
        # f.write(j)
        # f.close()




main()

r = requests.post('http://localhost:5008/api/v1/update/procedureFlow',json={"data":METADATA})
print(r.status_code)
print(r.text)

#
#
#
#
