#Updated version of Natural CC on 4/12/2019

import os,re,glob
from collections import OrderedDict
import pandas as pd
from pymongo import MongoClient
import config

#client = MongoClient('localhost', 27017)
#db = client['BNSF_NAT_POC']
client = MongoClient(config.database['hostname'], config.database['port'])
db = client[config.database['database_name']]

#file_path = "D:\\bnsf\\NAT_POC\\NAT"
# file_path = "D:\\NAT"
file_path =config.codebase_information['code_location']+"\\"+"NAT"


#db.master_inventory_report.remove()


Decide_Flag = False

for filename in glob.glob(os.path.join(file_path, "*.NAT")):

    f = open(filename, "r")
    if_counts = 0
    condition_counts = 0
    for_count = 0
    find_count = 0
    read_count = 0
    repeatuntil_count = 0
    repeat_count = 0
    loop_count = 0
    value_count = 0
    when_count = 0
    r = 0
    CCData = []
    Decidefor_Flag = False
    Decide_Flag = False

    for line in f.readlines():
        if len(line) > 5:
            line = line[5:]
            if line[0] == "*":
                continue
            if line.__contains__("/*"):
                index_value = line.index("/*")
                filtered_liness = line[0:index_value]
            else:
                filtered_liness = line

            if re.search("IF .*", filtered_liness, re.IGNORECASE) and not re.search("END-IF.*", filtered_liness,
                                                                                   re.IGNORECASE):
                # print(line)
                if_counts = if_counts + 1

                condition_counts = if_counts
                continue
                #print(condition_counts)

            if re.search(".*FOR ", filtered_liness, re.IGNORECASE):
                # print("FOR:",filtered_liness)
                for_count = for_count + 1
            elif re.search(".*FIND ", filtered_liness, re.IGNORECASE):
                # print("FIND:",filtered_liness)
                find_count = find_count + 1
            elif re.search(".*READ ", filtered_liness, re.IGNORECASE):
                # print("READ:",filtered_liness)
                read_count = read_count + 1
            elif re.search(".*REPEAT UNTIL.*", filtered_liness, re.IGNORECASE):
                #print("REPEAT:", filtered_liness)
                repeatuntil_count = repeatuntil_count + 1
            elif re.search(".*REPEAT.*", filtered_liness, re.IGNORECASE):
                #print("REPEAT:", line)
                repeat_count = repeat_count + 1

            loop_count = for_count + find_count + read_count + repeatuntil_count + repeat_count
            #print("Loopcount:", loop_count)

            if re.search(".*DECIDE ON.*", filtered_liness, re.IGNORECASE):
                Decide_Flag = True

            if (Decide_Flag):
                # print(line)
                if (re.search(" VALUE .*", filtered_liness, re.IGNORECASE) or re.search("  NONE  ", filtered_liness,
                                                                             re.IGNORECASE)) and not re.search(
                        "FIRST VALUE.*", filtered_liness, re.IGNORECASE):
                    #print(line)
                    value_count = value_count + 1
                    continue

            if re.search("END-DECIDE", filtered_liness, re.IGNORECASE):
                Decide_Flag = False

            if re.search(".*DECIDE FOR.*", filtered_liness, re.IGNORECASE):
            #print("DECIDE:", line)
               Decidefor_Flag = True

            if Decidefor_Flag:
                if re.search(".*WHEN.*", filtered_liness, re.IGNORECASE):
                    when_count = when_count + 1
                    continue

            if re.search("END-DECIDE", filtered_liness, re.IGNORECASE):
                Decidefor_Flag = False



    r = condition_counts+loop_count+value_count+when_count
    CCData.append(r + 1)
    res = int("".join(map(str, CCData)))
    payload = ({"component_name": filename.split("\\")[-1]},
               {"$set": {"cyclomatic_complexity": res}})
    #print(payload)
    db.master_inventory_report.update_one(*payload)
