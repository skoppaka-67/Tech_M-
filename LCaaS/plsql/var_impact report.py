from pymongo import MongoClient
import json,copy,glob,os
METADATA=[]
client = MongoClient("localhost", port=27017)
db = client["plsql"]
data = db.varimpactcodebase
#file = {'D:\plsql\PKB': '*.pkb'}
file = {'D:\\WORK\\plsql\\PKB\\': '*.pkb'}

def main():
    for file_location, file_type in file.items():  ##taking key as file location and value as file type in file dictionary
        for filename in glob.glob(os.path.join(file_location,
                                               file_type)):  ##access files one by one that ends with .pkb, and joining file path with folder

            if file_type == "*.pkb":

                var_impact(filename)




def var_impact(file):
    f = open(file,'r')

    for line in f.readlines():
        if line.strip()!='':


            output = {
                    'component_name':file.split("\\")[-1].split(".")[0],
                    'component_type':'Package Body',
                    "source_statements":line.strip()
                }
            METADATA.append(copy.deepcopy(output))




main()

try:
    data.remove()  ## if insert function is executed, prints successful otherwise it will prints fail
    data.insert_one({"type": "metadata",
                         "headers": [
                             "component_name",
                             "component_type",
                             "source_statements"

                         ]})
    data.insert_many(METADATA)

    print('data update successful')
except:
    print('fail')



#var_impact('RC_BTS_CYCLE_ADH_PKG.pkb')
#print(json.dumps(METADATA,indent=4))






