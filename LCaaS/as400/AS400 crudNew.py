import glob, copy, os, re
import json

from pymongo import MongoClient
import config1
Path = 'D:\AS400*'
METADATA = []
sp_list = ""

contents =""
var=0

# client = MongoClient(config1.database['mongo_endpoint_url'])
# db = client[config1.database['database_name']]
client = MongoClient('localhost', 27017)
db = client['as400']



db.crud_report.delete_many({"type": {"$ne":"metadata"}})


dict = { 'Create' :['write'],
         'Read':['setll', 'setgt', 'read', 'readp', 'readpe', 'reade', 'chain'],
         'Update' : ['update'],
         'Delete' : ['delete'] }


file = config1.file
print(file)

def main():
    for file_location, file_type in file.items():
        for filename in glob.glob(os.path.join(file_location, file_type)):
            file_handle = open(filename, "r")
            for line in file_handle.readlines():

                for keys, values in dict.items():
                    sp_list = line.split()
                    var = len(sp_list)
                    #print(values)
                    for value_items in values:
                        #print(type(value_items))
                        #print(value_items)
                        if value_items.casefold() in sp_list:
                            if line[6].__contains__("*") or re.search("//",line) :
                                continue
                            else:
                                index = sp_list.index(value_items.casefold())
                                if (index + 1 < var):
                                    table = sp_list[index + 1].strip(";")
                                    if (table.__contains__("(")):
                                        table = sp_list[index + 2].strip(';')
                                METADATA.append({'component_name': filename.strip(file_location).replace(" ","_").strip("."),
                                                 'component_type': file_type.strip("*."),
                                                 'Table': table,
                                                 'CRUD': crud_value(value_items),
                                                 'SQL': value_items
                                                 })
                                print(json.dumps(METADATA, indent=4))

                                # df = pd.DataFrame(METADATA)
                                # writer = pd.ExcelWriter('NewCrudOutput1.xlsx', engine='xlsxwriter')
                                # df.to_excel(writer, 'Sheet1', index=False)
                                # writer.save()

            #print(type(METADATA))
            # for i in METADATA:
            #     db.CRUD.insert_one(i)


        h = {"type": "metadata", "headers": [ "component_name", "component_type","Table","CRUD","SQL"]}

        db.crud_report.insert_many(METADATA)
        #db.crud_report.insert_one(h)
        #print(json.dumps(METADATA,indent=4))
        METADATA.clear()


def crud_value(value_items):
    result = ''
    for it in dict:
        if value_items in dict[it]:
            result = it
        else:
            continue
    return result









main()

