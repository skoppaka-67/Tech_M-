from pymongo import MongoClient
import glob, os, json, re
import pytz, datetime

mongoClient = MongoClient('localhost', 27017)
db = mongoClient['CRST_FULLV1']
# db2 = mongoClient['bnsf1']

print("1")

time_zone = 'Asia/Calcutta'
tz = pytz.timezone(time_zone)
SCRIPT_VERSION = "Keyword DB load"
SCRIPT_VERSION1 = "Keyword DB load"
key_word_json_object=[]
flowchart_json_objects = []
bre_json_objects = []
h = {"type": "metadata",
     "headers": ["pgm_name", "para_name", "source_statements", "rule_description", "Rule",
                 "rule_relation"]}
print("2")

def main():
    collection3 = db.keyword_lookup
    keyword_details = collection3.find({"type": {"$ne": "metadata"}}, {'_id': False})
    print("3")
    # collection = db.bre_report2
    # bre_details = collection.find({"type": {"$ne": "metadata"}}, {'_id': False})
    # print("4")

    collection2 = db.para_flowchart_data
    flowchart_details = collection2.find({"type": {"$ne": "metadata"}}, {'_id': False})
    print("5")
    # for bre_data_iter in bre_details:
    #     bre_json_objects.append(bre_data_iter)
    # print("6")
    for flowchart_data_iter in flowchart_details:
        flowchart_json_objects.append(flowchart_data_iter)
    print("7")
    for key_word_iter in keyword_details:
        key_word_json_object.append(key_word_iter)
    print("8")
    # for bre_i in bre_json_objects:
    #     try:
    #         bre_i['rule_description'] = bre_i['source_statements']
    #
    #         for dict in key_word_json_object:
    #             if bre_i['rule_description'].__contains__(dict['keyword']):
    #                 replaced1 = re.sub(" "+ dict['keyword']+" ", " "+dict['Meaning']+" ", bre_i['rule_description'],
    #                                    flags=re.IGNORECASE) #sourcestatements will starts with space so every cobol keyword will have one space before
    #                 bre_i['rule_description'] = replaced1
    #               # bre_i['rule_description'] =  bre_i['rule_description'].replace(dict['keyword']+" ",dict['Meaning']+" ")
    #                 # print(bre_i['rule_description'])
    #     # print(json.dumps(bre_json_objects,indent=4))
    #     except Exception as e:
    #         print(bre_i)

    # print("9")
    for flo_i in flowchart_json_objects:
        for dict in key_word_json_object:
            if dict['keyword']=="START":
                replaced1 = re.sub(" " + dict['keyword'], " " + dict['Meaning']+" ", flo_i['option'][17:])
                flo_i['option'] = flo_i['option'] [:17] +replaced1
                # print(flo_i['option'])

            else:
                replaced1 = re.sub(" "+dict['keyword'], " " + dict['Meaning']+" ", flo_i['option'])
                flo_i['option'] = replaced1

    print(json.dumps(flowchart_json_objects,indent=4))
    print("9")
    try:
        # db.bre_report2.remove()
        db.translated_flowchart.delete_many({'type': {"$ne": "metadata"}})

    except Exception as e:

            print('Error:' + str(e))
    #
    #     # Insert into DB
    try:
        # db.bre_report2.insert_one(h)
        db.translated_flowchart.insert_many(flowchart_json_objects)
        # db.bre_report2.insert_many(bre_json_objects)



        # # updating the timestamp based on which report is called
        current_time = datetime.datetime.now(tz=tz).strftime("%A, %d. %B %Y %I:%M%p")
        # if db.bre_report2.update_one({"type": "metadata"}, {"$set": {"last_updated_on": current_time,
        #                                                                        "time_zone": time_zone,
        #                                                                        # "headers":["component_name","component_type"],
        #                                                                        "script_version": SCRIPT_VERSION
        #                                                                        }}, upsert=True).acknowledged:
        #     print('BRE-update sucess')


        if db.translated_flowchart.update_one({"type": "metadata"}, {"$set": {"last_updated_on": current_time,
                                                                                   "time_zone": time_zone,
                                                                                   # "headers":["component_name","component_type"],
                                                                                   "script_version": SCRIPT_VERSION1
                                                                                   }}, upsert=True).acknowledged:


            print('flowchart-update sucess')

    except Exception as e:
        print('Error:' + str(e))


main()