import os, glob,json,copy
from pymongo import MongoClient
import datetime
import pytz
client= MongoClient('localhost', 27017)
db=client['BNSF_NAT1']
OUTPUT=[]
METADATA=[]
input_lines= []

def screenVarLength(lines):
    collect_flag = False
    var_dict = {}
    for line in lines:
        if line.__contains__("DEFINE DATA PARAMETER"):
            collect_flag = True
            continue
        if line.__contains__("END-DEFINE"):
            collect_flag = False
            break
        if collect_flag:
            var_dict[line[6:].split("(")[0].strip()[1:].strip()] =line[6:].split("(")[1].split("/")[0][1:].replace(")","").strip()

    return var_dict
for files in glob.glob(r"D:\BNSF\POC\MAP\*.MAP"):

    lines=open(files, encoding="utf-8").readlines()
    screenVarLength_dict = screenVarLength(lines)
    print(screenVarLength_dict)
    Read_flag = False
    d = {}
    d1 = {}
    d['bms_name'] = ''
    d['mapset_name'] = ''
    d['map_name'] = ''
    d['length'] = ''
    d['type'] = ''
    d['attribute'] = ''
    d['field_name'] = ''
    d['position'] = ''
    flag = 0
    row_count=1
    str_lit=''
    # print(files)
    for line in lines:
        if line[8] == "*":
            continue
        else:
            if line.__contains__("INPUT"):
                Read_flag = True


            if Read_flag:
                # d['bms_name'] = files.split("\\")[-1]
                # d['mapset_name'] =files.split("\\")[-1].split(".")[0]
                # d['map_name'] = files.split("\\")[-1].split(".")[0]

                if line[6] == "/":
                    row_count = row_count + 1
                if line[7].isnumeric():


                    d['bms_name'] = files.split("\\")[-1]
                    d['mapset_name'] = files.split("\\")[-1].split(".")[0]
                    d['map_name'] = files.split("\\")[-1].split(".")[0]
                    d['position'] = str(row_count).zfill(3) +","+ line[7:10].replace("T","")
                    if not(line[12:].__contains__("#")):
                        mul_val = 0
                        mul_val_flag = False
                        if line[12:].__contains__('(TU)'):
                            line1 = line[12:]
                            print(line1.split('(')[1].replace(")",""))
                            if line[12:].split('(')[1].replace(")","").isnumeric() or line[12:].split('(')[1].isdigit():
                                mul_val = line1.split('(')[1].replace(")","")
                                mul_val_flag = True
                        for i in line[13:]:

                            if not i =="'":
                                # if mul_val_flag:

                                    str_lit = str_lit + i
                            else:
                                break
                        if mul_val_flag:
                            d['field_name'] = str_lit * int(mul_val)
                        else:
                            d['field_name'] = str_lit
                        d['type']= "Screen Literal"
                        d['length'] = len(str_lit)
                        str_lit = ''
                    else:
                        for i in line[12:]:


                            if not i =="(":
                                str_lit = str_lit + i

                            else:
                                break

                            # if line[12:].__contains__("/*."):
                            #     lenght =line.strip().split("/*.")[-1].strip(" .").strip()[6:]
                            #     d['length'] = lenght
                        d['length'] = screenVarLength_dict[str_lit.strip()]

                        d['field_name'] = str_lit

                        d['type'] = "Screen Variable"

                        str_lit = ''

                    d1 = copy.deepcopy(d)
                # print(line.split())
                    OUTPUT.append(d1)
#
print(json.dumps(OUTPUT,indent=4))
#

time_zone = 'Asia/Calcutta'
tz = pytz.timezone(time_zone)
try:
    db.cics_field.delete_many({})
except Exception as e:
    print('Error while deleting orphan components report:'+str(e))
try:
    current_time = datetime.datetime.now(tz=tz).strftime("%A, %d. %B %Y %I:%M%p")
    if db.cics_field.update_one({"type": "metadata"}, {"$set": {"last_updated_on": current_time,
                                                                   "time_zone": time_zone,
                                                                   "headers": ["bms_name", "mapset_name", "map_name", "field_name", "type", "position", "length", "attribute"],
                                                                   }}, upsert=True).acknowledged:
        print('update metadata sucess')
    if db.cics_field.insert_many(OUTPUT):
        print('update sucess')

except Exception as e:
    print('Error while inserting into orphan components:'+str(e))

