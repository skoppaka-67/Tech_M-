SCRIPT_VERSION = "BRE-translated-report - Author - Saikiran "
SCRIPT_VERSION1 = "Flowchart-translated- Author - Saikiran"

from pymongo import MongoClient
import glob, os, json, re
import pytz, datetime

# RPG_Path = r'D:\PROD\Cobol'
mongoClient = MongoClient('localhost', 27017)
db = mongoClient['bnsf_new']

flowchart_json_objects = []
bre_json_objects = []
glossary_json_objects = []
temp_component_list = []
component_list = []
god_dict = {}
gol_tup = []
output = []
time_zone = 'Asia/Calcutta'
tz = pytz.timezone(time_zone)


h = {"type": "metadata",
     "headers": ["pgm_name", "para_name", "source_statements", "rule_description", "Rule",
                 "rule_relation"]}

def Remove(duplicate):
    final_list = []
    for list_iter in duplicate:
        if list_iter not in final_list:
            final_list.append(list_iter)
    return final_list


def glossary_extrection():
    component_list = []
    collection3 = db.glossary
    glossary_details = collection3.find({'$and':[{"type": {"$ne": "metadata"}},{"Business_Meaning": {"$ne": ""}}]})
    for glossary_data_iter in glossary_details:
        glossary_json_objects.append(glossary_data_iter)

        # for filename in glob.glob(os.path.join(RPG_Path, '*.RPG')):
        #     component_list.append(filename.strip("D:\AS400\RPG1").strip("."))

    for i in glossary_json_objects:
        component_list.append(i['component_name'])
    component_list = Remove(component_list)
    # print(component_list)

    for index, comp in enumerate(component_list):
        res = [{i['Variable']: i['Business_Meaning']} for i in glossary_json_objects if i['component_name'] == comp]

        output.append(res)
        god_dict[comp] = output[index] = res

    return  god_dict


def main():
    bre2_copm_list =db.bre_report2.distinct("pgm_name")
    flow_com_list = db.para_flowchart_data.distinct("component_name")
    glossary_comp_list = db.glossary.distinct("component_name",{'$and':[{"type": {"$ne": "metadata"}},{"Business_Meaning": {"$ne": ""}}]})
    #
    for comp in glossary_comp_list:
        comp = comp.split(".")[0]

        collection = db.bre_report2
        bre_details = collection.find({"pgm_name":comp}, {'_id': False}).sort('_id')
        #db.bre_report2.remove()
        #print ("dbdeleted ")
        # db.collection.find({}, {'_id': False})

        for bre_data_iter in bre_details:
            bre_json_objects.append(bre_data_iter)

        god_dict = glossary_extrection()
        for bre_i in bre_json_objects:
            for i, v in god_dict.items():
                if bre_i['pgm_name'] == i.split(".")[0]:
                    for value in v:
                        for key in value:
                            New_Key = key + " "
                            if value[key] != "":
                                if type(value[key]) == str:

                                    replaced = re.sub(New_Key, " "+value[key]+" ", bre_i['rule_description'], flags=re.IGNORECASE)
                                    print(replaced)
                                    bre_i['rule_description'] = replaced

        # print(json.dumps(bre_json_objects, indent=4))

        try:
            db.bre_report2.delete_many({"pgm_name":comp})

        except Exception as e:

                print('Error:' + str(e))

            # Insert into DB
        try:
            # db.bre_report2.insert_one(h)
            db.bre_report2.insert_many(bre_json_objects)

            # updating the timestamp based on which report is called
            current_time = datetime.datetime.now(tz=tz).strftime("%A, %d. %B %Y %I:%M%p")
            if db.bre_report2.update_one({"type": "metadata"}, {"$set": {"last_updated_on": current_time,
                                                                                   "time_zone": time_zone,
                                                                                   # "headers":["component_name","component_type"],
                                                                                   "script_version": SCRIPT_VERSION
                                                                                   }}, upsert=True).acknowledged:
                print('BRE-update sucess for comp',comp)


        except Exception as e:
            print('Error:' + str(e))

        bre_json_objects.clear()
        flowchart_json_objects.clear()
        glossary_json_objects.clear()
        component_list.clear()
    # god_dict = glossary_extrection()
    # for comp2 in flow_com_list:
    #     print(comp2,"is processing")
    #     collection2 = db.para_flowchart_data
    #     flowchart_details = collection2.find({"component_name":comp2}, {'_id': False})
    #     print("db fetched")
    #     for flowchart_data_iter in flowchart_details:
    #         flowchart_json_objects.append(flowchart_data_iter)
    #         for flo_i in flowchart_json_objects:
    #             for i, v in god_dict.items():
    #                 if flo_i['component_name'] == i:
    #                     for value in v:
    #                         for key in value:
    #                             New_Key = " " + key
    #                             if value[key] != "":
    #                                 if type(value[key]) == str:
    #                                     # print(value[key])
    #                                     if flo_i['option'].__contains__(key.lower()) or flo_i['option'].__contains__(key.upper()):
    #
    #                                         replaced = re.sub(New_Key, " " + value[key]+" ", flo_i['option'],
    #                                                           flags=re.IGNORECASE)
    #                                         flo_i['option'] = replaced
    #                                     # flo_i['option'] = replaced1
    #     try:
    #
    #         db.translated_flowchart.delete_many({"component_name":comp2})
    #
    #     except Exception as e:
    #
    #         print('Error:' + str(e))
    #
    #         # Insert into DB
    #     try:
    #
    #         db.translated_flowchart.insert_many(flowchart_json_objects)
    #
    #         # updating the timestamp based on which report is called
    #         current_time = datetime.datetime.now(tz=tz).strftime("%A, %d. %B %Y %I:%M%p")
    #
    #         if db.translated_flowchart.update_one({"type": "metadata"}, {"$set": {"last_updated_on": current_time,
    #                                                                               "time_zone": time_zone,
    #                                                                               # "headers":["component_name","component_type"],
    #                                                                               "script_version": SCRIPT_VERSION1
    #                                                                               }}, upsert=True).acknowledged:
    #             print('flowchart-update sucess for ',comp2)
    #
    #     except Exception as e:
    #         print('Error:' + str(e))
    #
    #     bre_json_objects.clear()
    #     flowchart_json_objects.clear()
    #     glossary_json_objects.clear()
    #     component_list.clear()

main()