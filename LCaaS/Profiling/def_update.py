SCRIPT_VERSION = "BRE-translated-report - Author - Saikiran "
SCRIPT_VERSION1 = "Flowchart-translated- Author - Saikiran"

from pymongo import MongoClient
import glob, os, json, re
import pytz, datetime

# RPG_Path = r'D:\PROD\Cobol'
mongoClient = MongoClient('localhost', 27017)
db = mongoClient['CRST_FULLDB']

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
# db2 = mongoClient['config']

key_word_json_object = []
def keyword_rep(rule_desc):
    for dict in key_word_json_object:
        if rule_desc.__contains__(dict['keyword']):
            replaced1 = re.sub(" " + dict['keyword'] + " ", " " + dict['Meaning'] + " ", rule_desc,
                               flags=re.IGNORECASE)  # sourcestatements will starts with space so every cobol keyword will have one space before
            rule_desc = replaced1


    return rule_desc


def fetch_keyword_db():
    collection3 = db.keyword_lookup
    keyword_details = collection3.find({"type": {"$ne": "metadata"}}, {'_id': False})
    for key_word_iter in keyword_details:
        key_word_json_object.append(key_word_iter)

def Remove(duplicate):
    final_list = []
    for list_iter in duplicate:
        if list_iter not in final_list:
            final_list.append(list_iter)
    return final_list


def glossary_extrection(app_name,component_name):
    component_list = []
    collection3 = db.glossary
    glossary_details = collection3.find({'$and':[{"type": {"$ne": "metadata"}},{"Business_Meaning": {"$ne": ""}},{"component_name":component_name}]})
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


def main(app_name,component_name):
    fetch_keyword_db()
    glossary_comp_list = []
    glossary_comp_list.append(component_name.split(".")[0])
    #
    for comp in glossary_comp_list:
        # comp = comp.split(".")[0]

        collection = db.bre_report2
        bre_details = collection.find({"pgm_name":comp}, {'_id': False}).sort('_id')
        #db.bre_report2.remove()
        #print ("dbdeleted ")
        # db.collection.find({}, {'_id': False})

        for bre_data_iter in bre_details:
            bre_json_objects.append(bre_data_iter)

        god_dict = glossary_extrection(app_name,component_name)
        for bre_i in bre_json_objects:
            bre_i['rule_description'] = bre_i['source_statements']
            bre_i['rule_description'] = keyword_rep(bre_i['rule_description'])

            for i, v in god_dict.items():
                if bre_i['pgm_name'] == i.split(".")[0]:
                    for value in v:
                        for key in value:
                            New_Key = key
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
                print('BRE-update sucess for comp',component_name)


        except Exception as e:
            print('Error:' + str(e))

        bre_json_objects.clear()
        flowchart_json_objects.clear()
        glossary_json_objects.clear()
        component_list.clear()
    god_dict = glossary_extrection(app_name,component_name)

    for comp2 in glossary_comp_list:
        print(comp2,"is processing")
        collection2 = db.para_flowchart_data
        flowchart_details = collection2.find({"component_name":component_name}, {'_id': False})


        for flowchart_data_iter in flowchart_details:
            flowchart_json_objects.append(flowchart_data_iter)
        print("db fetched")




        for flo_i in flowchart_json_objects:
            for i, v in god_dict.items():
                if flo_i['component_name'] == i:
                    for value in v:
                        for key in value:
                            New_Key =  key
                            if value[key] != "":
                                if type(value[key]) == str:
                                    # print(value[key])
                                    if flo_i['option'].__contains__(key.lower()) or flo_i['option'].__contains__(key.upper()):

                                        replaced = re.sub(New_Key, " " + value[key]+" ", flo_i['option'],
                                                          flags=re.IGNORECASE)
                                        flo_i['option'] = replaced
                                        # flo_i['option'] = replaced1
        for flo_i in flowchart_json_objects:
            for dict in key_word_json_object:
                re.sub(' +', ' ', flo_i['option'])
                if dict['keyword'] == "START":

                    replaced1 = re.sub(" " + dict['keyword'], " " + dict['Meaning'] + " ", flo_i['option'][17:],
                                       flags=re.IGNORECASE)
                    flo_i['option'] = flo_i['option'][:17] + replaced1
                    # print(flo_i['option'])

                else:
                    replaced1 = re.sub(" "+ dict['keyword'], " " + dict['Meaning'] + " ", flo_i['option'],
                                       flags=re.IGNORECASE)
                    flo_i['option'] = replaced1
        try:

            db.translated_flowchart.delete_many({"component_name":component_name})

        except Exception as e:

            print('Error:' + str(e))

            # Insert into DB
        try:

            db.translated_flowchart.insert_many(flowchart_json_objects)

            # updating the timestamp based on which report is called
            current_time = datetime.datetime.now(tz=tz).strftime("%A, %d. %B %Y %I:%M%p")

            if db.translated_flowchart.update_one({"type": "metadata"}, {"$set": {"last_updated_on": current_time,
                                                                                  "time_zone": time_zone,
                                                                                  # "headers":["component_name","component_type"],
                                                                                  "script_version": SCRIPT_VERSION1
                                                                                  }}, upsert=True).acknowledged:
                print('flowchart-update sucess for ',component_name)

        except Exception as e:
            print('Error:' + str(e))

        bre_json_objects.clear()
        flowchart_json_objects.clear()
        glossary_json_objects.clear()
        component_list.clear()

# main()