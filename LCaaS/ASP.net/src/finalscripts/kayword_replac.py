from pymongo import MongoClient
import glob, os, json, re
import pytz, datetime
import csv

mongoClient = MongoClient('localhost', 27017)
db = mongoClient['asp4']
db2 = mongoClient['Vbconfig']



time_zone = 'Asia/Calcutta'
tz = pytz.timezone(time_zone)
SCRIPT_VERSION = "Keyword DB load"
SCRIPT_VERSION1 = "Keyword DB load"
key_word_json_object=[]
js_key_word_json_object=[]
flowchart_json_objects = []
bre_json_objects = []
js_bre_json_objects = []

h = {"type": "metadata",
     "headers": ["pgm_name", "para_name", "source_statements", "rule_description", "Rule",
                 "rule_relation"]}


def main():
    collection3 = db2.keyword_lookup
    keyword_details = collection3.find({"type": {"$ne": "metadata"}}, {'_id': False})

    collection = db.rule_report
    bre_details = collection.find({"type": {"$ne": "metadata"}}, {'_id': False})

    collection2 = db.Bussiness_Rules
    js_BR_details = collection2.find({"type": {"$ne": "metadata"}}, {'_id': False})

    collection1 = db2.keyword_lookup_js
    js_keywords = collection1.find({"type": {"$ne": "metadata"}}, {'_id': False})


    for js_bre_data_iter in js_BR_details:
        js_bre_json_objects.append(js_bre_data_iter)
    # print(js_bre_json_objects)

    for bre_data_iter in bre_details:
        bre_json_objects.append(bre_data_iter)


    for key_word_iter in keyword_details:
        key_word_json_object.append(key_word_iter)
    for key_word_iter1 in js_keywords:
        js_key_word_json_object.append(key_word_iter1)

    for bre_i in bre_json_objects:
        try:
            bre_i['rule_statement'] = [x.replace("\n"," \n").replace('End If',"End If ") for x in bre_i['rule_statement']]

            bre_i['rule_description'] = "".join(bre_i['rule_statement'])
            bre_i['rule_statement'] = "".join(bre_i['rule_statement'])
            for dict in key_word_json_object:
                if bre_i['rule_description'].__contains__(dict['keyword']):

                    replaced1 = re.sub(dict['keyword']+" ", " "+dict['Meaning']+" ", bre_i['rule_description'])


                    bre_i['rule_description'] = replaced1

            # print(bre_i['rule_description'])

        except Exception as e:
            print(bre_i)



    try:
        db.rule_report.remove()


    except Exception as e:

            print('Error:' + str(e))
    #
    #     # Insert into DB
    try:
        db.rule_report.insert_one(h)
        # db.translated_flowchart.insert_many(flowchart_json_objects)
        db.rule_report.insert_many(bre_json_objects)

        with open("rule_report_annotated" + '.csv', 'w', newline="") as output_file:
            Fields = ["rule_id","file_name","lob","function_name","field_name","rule_statement","rule_description","rule_type","Lob","dependent_control","parent_rule_id","External_rule_id","Rule_Relation","_id"]
            dict_writer = csv.DictWriter(output_file, fieldnames=Fields)
            dict_writer.writeheader()
            dict_writer.writerows(bre_json_objects)



        # # updating the timestamp based on which report is called
        current_time = datetime.datetime.now(tz=tz).strftime("%A, %d. %B %Y %I:%M%p")
        if db.rule_report.update_one({"type": "metadata"}, {"$set": {"last_updated_on": current_time,
                                                                               "time_zone": time_zone,
                                                                               # "headers":["component_name","component_type"],
                                                                               "script_version": SCRIPT_VERSION
                                                                               }}, upsert=True).acknowledged:
            print('BRE-update sucess')



    except Exception as e:
        print('Error:' + str(e))


    for bre_js in js_bre_json_objects:
        try:
            bre_js['rules_statement'] = [x.replace("\n"," \n") for x in bre_js['rules_statement']]
            bre_js['rules_statement'] = [x.replace(")if", " ) if") for x in bre_js['rules_statement']]
            bre_js['rule_description'] = "".join(bre_js['rules_statement'])
            bre_js['rules_statement'] = "".join(bre_js['rules_statement'])
            for dict in js_key_word_json_object:
                if bre_js['rule_description'].__contains__(dict['keyword']):

                    replaced1 = re.sub(dict['keyword']+" ", " "+dict['Meaning']+" ", bre_js['rule_description'].strip())


                    bre_js['rule_description'] = replaced1

            # print(bre_js['rule_description'])

        except Exception as e:
            print(bre_js)



    try:
        db.Bussiness_Rules.remove()


    except Exception as e:

            print('Error:' + str(e))
    #
    #     # Insert into DB
    try:
        # db.Bussiness_Rules.insert_one(h)
        # db.translated_flowchart.insert_many(flowchart_json_objects)
        db.Bussiness_Rules.insert_many(js_bre_json_objects)

        with open("js_rule_report_annotated" + '.csv', 'w', newline="") as output_file:
            Fields = ["rule_id","file_name","function_name","feild_name","External_rule_id","rules_statement","Rule_Relation","rule_description","rule_type","type","Lob","dependent_control","partent_rule_id","Event_type","_id"]

            dict_writer = csv.DictWriter(output_file, fieldnames=Fields)
            dict_writer.writeheader()
            dict_writer.writerows(js_bre_json_objects)



        # # updating the timestamp based on which report is called
        current_time = datetime.datetime.now(tz=tz).strftime("%A, %d. %B %Y %I:%M%p")
        if db.Bussiness_Rules.update_one({"type": "metadata"}, {"$set": {"last_updated_on": current_time,
                                                                               "time_zone": time_zone,
                                                                               # "headers":["component_name","component_type"],
                                                                               "script_version": SCRIPT_VERSION
                                                                               }}, upsert=True).acknowledged:
            print('JS_BRE-update sucess')



    except Exception as e:
        print('Error:' + str(e))




main()