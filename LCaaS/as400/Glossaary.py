SCRIPT_VERSION = "Glossary V.01,Author - Kiran"

import  glob,os,re,copy,json
from pymongo import MongoClient
import config1
import pytz
import datetime

Rpg_file = config1.RPG_Path
Cl_file = config1.CL_Path
variable_list_dup= []
variable_list = []
Metadata =[]

#print(Rpg_file)
#
# mongoClient = MongoClient('localhost', 27017)
# db = mongoClient['as400']
# db.glossary.remove()
# h= {"type": "metadata", "headers": ["component_name", "Variable", "Business_Meaning"]}
# db.glossary.insert_one(h)
time_zone = 'Asia/Calcutta'
tz = pytz.timezone(time_zone)



def Remove(duplicate):
    final_list = []
    for list_iter in duplicate:
        if list_iter not in final_list:
            final_list.append(list_iter)
    return final_list





def main():
    for filename in glob.glob(os.path.join(Rpg_file, '*.RPG')):


        companent_name = open(filename, "r")
        for line in companent_name.readlines():

            try:
                if (  not  (line[6].__contains__("*") or re.search("//", line))):
                    if (line[5].__contains__("d") or line[5].__contains__("D")):

                        declaration_line = line[5:].split(" ")
                        #print(declaration_line)
                        #print(declaration_line[2])
                        if declaration_line[1] != " ":
                            variable_list_dup.append(declaration_line[2] )
                            variable_list_dup.append(declaration_line[1])

            except Exception:
                pass

        variable_list = copy.deepcopy(Remove(variable_list_dup))
        variable_list_dup.clear()
        if variable_list[0] == "":

            del variable_list[0]

        for i in variable_list:
            if i !="":
                component_name = filename.split("\\")[-1].split(".")[0]

                var = i
                BM = ""

                Glossary_json = {"component_name": component_name, "Variable":var, "Business_Meaning": BM}


                Metadata.append(Glossary_json)
        variable_list.clear()
    print(json.dumps(Metadata, indent=4))

    # db.glossary.insert_many(Metadata)

    # try:
    #     db.glossary.delete_many({'type': {"$ne": "metadata"}})
    # except Exception as e:
    #     print('Error:' + str(e))
    #
    # # Insert into DB
    # try:
    #
    #     db.glossary.insert_many(Metadata)
    #     # updating the timestamp based on which report is called
    #     current_time = datetime.datetime.now(tz=tz).strftime("%A, %d. %B %Y %I:%M%p")
    #     if db.glossary.update_one({"type": "metadata"}, {"$set": {"last_updated_on": current_time,
    #                                                                  "time_zone": time_zone,
    #                                                                  # "headers":["component_name","component_type"],
    #                                                                  "script_version": SCRIPT_VERSION
    #                                                                  }}, upsert=True).acknowledged:
    #         print('update sucess')
    #
    # except Exception as e:
    #     print('Error:' + str(e))


main()
