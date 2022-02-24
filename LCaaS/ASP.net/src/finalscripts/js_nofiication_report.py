import config
from pymongo import MongoClient
import glob,os,copy
import re
import json
import csv

mongoClient = MongoClient('localhost', 27017)
db = mongoClient['asp4']
vb = config.codebase_information['VB']['folder_name']
code_location =config.codebase_information['code_location']

vb_path=code_location+'\\'+vb

metadata = []
def main():
    output_json = {
        "lob_name": '',
        'file_name': '',
        "type_of_notification":"",
        "Message":""

    }
    for filename in glob.glob(os.path.join(vb_path,'*.js')):

        with open(filename, 'r') as js_file:
            var =''
            for line in js_file.readlines():
                if line.__contains__("notificationSection") and line.__contains__("CLAS.find"):
                    if not (line.__contains__("=") or line.__contains__("var")):
                        type_of_noti = line.split(").")[1].split(".add")[0]
                        noti_msg = line.split(").")[1].split(".add")[1].strip().replace('(','').replace(')','').replace(';','').replace("'",'').replace('"',"")
                        output_json['lob_name'] = "LobPF"
                        output_json['file_name'] = filename.split("\\")[-1]
                        output_json['type_of_notification'] = type_of_noti
                        output_json['Message'] = noti_msg
                        metadata.append(copy.deepcopy(output_json))
                        output_json.clear()

                    else:
                        if line.__contains__("=") and line.__contains__("notificationSection"):
                            var = line.split('=')[0].replace('var','').strip()
                            type_of_noti1 = line.split(").")[1].split(".add")[0].replace(";",'').strip()
                            # print(line)
                            with open(filename, 'r') as js_file:
                                for line1 in js_file.readlines():
                                    if line1.__contains__(var + '.') and var != '':
                                        # print(line1)
                                        if line1.__contains__(".add"):
                                            noti_msg1 = line1.split(".add")[1].strip().replace('(','').replace(')','').replace(';', '').replace("'", '').replace('"', "")
                                        elif line1.__contains__('.remove'):
                                            noti_msg1 = line1.split(".remove")[1].strip().replace('(','').replace(')','').replace(';', '').replace("'", '').replace('"', "")

                                        output_json['lob_name'] = "LobPF"
                                        output_json['file_name'] = filename.split("\\")[-1]
                                        output_json['type_of_notification'] = type_of_noti1
                                        output_json['Message'] = noti_msg1
                                        metadata.append(copy.deepcopy(output_json))
                                        output_json.clear()


main()
print(json.dumps(metadata,indent=4))
with open("notification_report" + '.csv', 'w', newline="") as output_file:
    Fields = ["lob_name", "file_name", "type_of_notification", "Message"]
    dict_writer = csv.DictWriter(output_file, fieldnames=Fields)
    dict_writer.writeheader()
    dict_writer.writerows(metadata)
if metadata != []:
    if db.drop_collection("notification_report"):
        print("notification report DB deleted")

    if db.notification_report.insert_many(metadata):
        print("notification report DB inserted")


