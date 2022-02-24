import config
import os, re, sys
import requests
import os.path
from os import path
from copy import deepcopy
import copy
from pymongo import MongoClient
code_location = config.codebase_information['code_location']
pgm_list = []
mongoClient = MongoClient('localhost', 27017)
db = mongoClient['vb']

class process_flow():
    def startup(self):
        global pgm_data
        pgm_data = {}
        global metadata
        metadata=[]
        output_dict={}
        for path, subdirs, files in os.walk(code_location):
            for name in files:
                global output_list
                output_list=[]
                global event_dict
                event_dict={}
                global new_list
                new_list=[]
#                if not name == "Browsing2.aspx":
#                    continue
                filename = os.path.join(path, name)
                if filename.split("\\")[-1].split('.')[-1].upper() == "ASPX"  or filename.split("\\")[-1].split('.')[-1].upper() == "ASCX"\
                        or filename.split("\\")[-1].split('.')[-1].upper() == "MASTER" or filename.split("\\")[-1].split('.')[-1].upper() == "ASAX" :
                    process_flow.main(filename)
                    #print(filename)
        #print(pgm_data)

        r = requests.post('http://localhost:5020/api/v1/update/procedureFlow', json={"data": pgm_data})
        #print(r.status_code)
        #print(r.text)
        return pgm_data
    def main(filename):
        try:
            comment_line_flag = False
            db_data=list(db.public_fun.find())
            with open(filename,encoding='utf8') as input_file:
                for line in input_file:
                    if line.strip().startswith("'") or line.strip() == "":
                        continue
                    if line.strip().startswith("<!--"):
                        comment_line_flag = True
                    if comment_line_flag:
                        if line.strip().endswith("-->") or line.strip().__contains__('-->'):
                            comment_line_flag = False
                        continue
                    onclick_events_list=[]
                    if line.strip().startswith("<asp:"):
                        onclick_events_list = [x for x in line.split() if x.startswith("On")]
                    if onclick_events_list!=[]:
                      for events in onclick_events_list:
                          process_flow.code_behind_fun(events,filename,db_data)
                          output_list.append(call_dict)
                          event_dict[events.split("=")[1].replace('"','').replace(">","")]=[copy.deepcopy(metadata)]
                          output_list.clear()
                          new_list.append(copy.deepcopy(event_dict))
                          event_dict.clear()
                          metadata.clear()
                      result={}
                      for d in new_list:
                          result.update(d)
                      #print(result)
                      pgm_data[filename.split("\\")[-1]]=result

        except Exception as e:
            exc_type, exc_obj, exc_tb = sys.exc_info()
            fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
            print(exc_type, fname, exc_tb.tb_lineno)
        
        #print(pgm_data)
        return  pgm_data
           
    def code_behind_fun(events,filename,db_data):
        try: 
            global metadata
            metadata=[]           
            global call_dict
            call_dict={}
            global values_list
            values_list=[]
            global internal_list
            internal_list=[]
            global external_list
            external_list=[]
            global pub_shared_list
            pub_shared_list=[]
            global event_dict
            event_dict={}
            if path.isfile(filename+'.vb'):

                if events.strip().endswith(">") or events.strip().endswith("/"):
                    events=events[:-1]
                    if events.strip().endswith("/"):
                        events = events[:-1]

                call_details = [x for x in db_data if x["Function_name"]==events.split("=")[1].replace('"','').replace(">","").replace("/","") and  x["File_name"]==filename.split("\\")[-1]+".vb"]

                if len(call_details)==1:

                    if call_details[0]["Internal"] !=[]:
                        values_list.append(call_details[0]["Internal"])
                        call_dict[events.split("=")[1].replace('"','').replace(">","").replace("/","")]=values_list
                        for int_call in call_details[0]["Internal"]:                         
                            process_flow.internal_call(int_call,db_data)
                            metadata.append({"from":events.split("=")[1].replace('"','').replace(">","").replace("/",""),"to":int_call,"name":"internal"})
                            #print("metadata1",metadata)
                    if call_details[0]["Redirect"] !=[]:
                        values_list.append(call_details[0]["Redirect"])
                        call_dict[events.split("=")[1].replace('"','').replace(">","").replace("/","")]=values_list
                        for int_call in call_details[0]["Redirect"]:
                            #print(int_call)
                            process_flow.redirect_fun(int_call,db_data)
                            metadata.append({"from":events.split("=")[1].replace('"','').replace(">","").replace("/",""),"to":int_call,"name":"Webform","file" : int_call})
                            #print("metadata2",metadata)
#                            print({"from":events.split("=")[1].replace('"','').replace(">","").replace("/",""),"to":int_call,"name":"Webform","file" : int_call})
#                            return {"from":events.split("=")[1].replace('"','').replace(">","").replace("/",""),"to":int_call,"name":"Webform","file" : int_call}
                    if call_details[0]["External"][0]!=[]:
                        values_list.append(list(call_details[0]["External"][0].keys()))
                        call_dict[events.split("=")[1].replace('"', '').replace("/","")] = values_list
                        for ext_fun in list(call_details[0]["External"][0].keys()):
                            #print("------------",ext_fun, db_data,call_details[0]["External"][0][ext_fun][0])
                            process_flow.external_call(ext_fun, db_data,call_details[0]["External"][0][ext_fun][0])
                            metadata.append(
                                {"from": events.split("=")[1].replace('"', '').replace(">","").replace("/",""), "to": ext_fun, "name": "External","file" : call_details[0]["External"][0][ext_fun][0]})
                            
                            #print("metadata3",metadata)
                            #return {"from": events.split("=")[1].replace('"', '').replace(">","").replace("/",""), "to": ext_fun, "name": "External","file" : call_details[0]["External"][0][ext_fun][0]}
                    if call_details[0]["Pub_shared"]!=[]:
                        values_list.append(list(call_details[0]["Pub_shared"][0].keys()))
                        call_dict[events.split("=")[1].replace('"', '').replace("/","")] = values_list
                        for pub_shr in list(call_details[0]["Pub_shared"][0].keys()):
                            #print(True)
                            process_flow.pub_shared_call(pub_shr, db_data,call_details[0]["Pub_shared"][0][pub_shr][0])
                            metadata.append(
                                {"from": events.split("=")[1].replace('"', '').replace(">","").repalce("/",""), "to": pub_shr, "name": "External","file" : call_details[0]["Pub_shared"][0][pub_shr][0]})
                            #print("metadata4",metadata)

                # elif len(call_details)==0:
                #     call_dict[events.split("=")[1].replace('"', '')] = ""
               
            else:
                # call_dict[events.split("=")[1].replace('"', '')] = ""
                print("code behind file "+filename+" not found")      

        except Exception as e:
            exc_type, exc_obj, exc_tb = sys.exc_info()
            fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
            print(exc_type, fname, exc_tb.tb_lineno)
            #print(filename)

        return metadata

    def internal_call(k,db_data):
#        print(k)
        global metadata
#        metadata=[] 
        call_data = [x for x in db_data if x["Function_name"] == k ]
        if call_data!=[]:
             if call_data[0]["Internal"] != []:
                 internal_list.append(call_data[0]["Internal"])
                 call_dict[k]=internal_list
                 for data in call_data[0]["Internal"]:
                    process_flow.internal_call(data,db_data)
                    metadata.append(
                        {"from": k.replace("/",""), "to": data, "name": "Internal"})
             if call_data[0]["Redirect"] != []:
                 internal_list.append(call_data[0]["Redirect"])
                 call_dict[k]=internal_list
                 for data in call_data[0]["Redirect"]:
                    process_flow.internal_call(data,db_data)
                    metadata.append(
                        {"from": k.replace("/",""), "to": data, "name": "Webform","file" : data})
             if call_data[0]["External"] != []:
                 internal_list.append(list(call_data[0]["External"][0].keys()))
                 call_dict[k] = internal_list
                 for data in list(call_data[0]["External"][0].keys()):
                     process_flow.internal_call(data, db_data)
                     metadata.append(
                         {"from": k.replace("/",""), "to": data, "name": "External","file" : call_data[0]["External"][0][data][0]})
             if call_data[0]["Pub_shared"] != []:
                 internal_list.append(list(call_data[0]["Pub_shared"][0].keys()))
                 call_dict[k] = internal_list
                 for data in list(call_data[0]["Pub_shared"][0].keys()):
                     process_flow.internal_call(data, db_data)
                     metadata.append(
                         {"from": k.replace("/",""), "to": data, "name": "External","file" : call_data[0]["Pub_shared"][0][data][0]})
#        print(metadata)
        return metadata
                     
    def redirect_fun(k,db_data):
        #global metadata
        #metadata=[]
        call_data = [x for x in db_data if x["Function_name"] == k ]
        if call_data!=[]:
             if call_data[0]["Internal"] != []:
                 internal_list.append(call_data[0]["Internal"])
                 call_dict[k]=internal_list
                 for data in call_data[0]["Internal"]:
                    process_flow.internal_call(data,db_data)
                    metadata.append(
                        {"from": k.replace("/",""), "to": data, "name": "Internal"})
                    #print({"from": k.replace("/",""), "to": data, "name": "Internal"})
             if call_data[0]["Redirect"] != []:
                 internal_list.append(call_data[0]["Redirect"])
                 call_dict[k]=internal_list
                 for data in call_data[0]["Redirect"]:
                    process_flow.internal_call(data,db_data)
                    metadata.append(
                        {"from": k.replace("/",""), "to": data, "name": "Webform","file" : data})
                    #print({"from": k.replace("/",""), "to": data, "name": "Webform","file" : data})
             if call_data[0]["External"] != []:
                 internal_list.append(list(call_data[0]["External"][0].keys()))
                 call_dict[k] = internal_list
                 for data in list(call_data[0]["External"][0].keys()):
                     process_flow.internal_call(data, db_data)
                     metadata.append(
                         {"from": k.replace("/",""), "to": data, "name": "External","file" : call_data[0]["External"][0][data][0]})
                     #print({"from": k.replace("/",""), "to": data, "name": "External","file" : call_data[0]["External"][0][data][0]})
             if call_data[0]["Pub_shared"] != []:
                 internal_list.append(list(call_data[0]["Pub_shared"][0].keys()))
                 call_dict[k] = internal_list
                 for data in list(call_data[0]["Pub_shared"][0].keys()):
                     process_flow.internal_call(data, db_data)
                     metadata.append(
                         {"from": k.replace("/",""), "to": data, "name": "External","file" : call_data[0]["Pub_shared"][0][data][0]})
                     #print({"from": k.replace("/",""), "to": data, "name": "External","file" : call_data[0]["Pub_shared"][0][data][0]})
        #print(k,metadata)
        return metadata

    def external_call(k,db_data,file_name):      
#        global metadata
#        metadata=[]
        call_data = [x for x in db_data if x["Function_name"] == k and x["File_name"]==file_name  ]
        if call_data!=[]:
            if call_data[0]["Internal"] != []:
                 external_list.append(call_data[0]["Internal"])
                 call_dict[k] = external_list
                 for data in call_data[0]["Internal"]:
                    process_flow.external_call(data, db_data,file_name)
                    metadata.append(
                        {"from": k.replace("/",""), "to": data, "name": "internal"})
            if call_data[0]["Redirect"] != []:
                 external_list.append(call_data[0]["Redirect"])
                 call_dict[k] = external_list
                 for data in call_data[0]["Redirect"]:
                    process_flow.external_call(data, db_data,file_name)
                    metadata.append(
                        {"from": k.replace("/",""), "to": data, "name": "Webform","file" : data})
            if call_data[0]["External"] != []:
                 external_list.append(list(call_data[0]["External"][0].keys()))
                 call_dict[k]=external_list
                 for data in list(call_data[0]["External"][0].keys()):
                    process_flow.external_call(data,db_data,file_name)
                    metadata.append(
                        {"from": k.replace("/",""), "to": data, "name": "External","file" : call_data[0]["External"][0][data][0]})
            if call_data[0]["Pub_shared"] != []:
                 external_list.append(list(call_data[0]["Pub_shared"][0].keys()))
                 call_dict[k] = external_list
                 for data in list(call_data[0]["Pub_shared"][0].keys()):
                     process_flow.external_call(data, db_data,file_name)
                     metadata.append(
                         {"from": k.replace("/",""), "to": data, "name": "External","file" : call_data[0]["Pub_shared"][0][data][0]})
        #print(k,file_name,metadata)
        return metadata

    def pub_shared_call(k, db_data,file_name):
        call_data = [x for x in db_data if x["Function_name"] == k and x["File_name"]==file_name]
        if call_data != []:
            if call_data[0]["Internal"] != []:
                pub_shared_list.append(call_data[0]["Internal"])
                call_dict[k] = pub_shared_list
                for data in call_data[0]["Internal"]:
                    process_flow.pub_shared_call(data, db_data,file_name)
                    metadata.append(
                        {"from": k.replace("/",""), "to": data, "name": "internal"})
            if call_data[0]["Redirect"] != []:
                pub_shared_list.append(call_data[0]["Redirect"])
                call_dict[k] = pub_shared_list
                for data in call_data[0]["Redirect"]:
                    process_flow.pub_shared_call(data, db_data,file_name)
                    metadata.append(
                        {"from": k.replace("/",""), "to": data, "name": "Webform","file" : data})
            if call_data[0]["External"] != []:
                pub_shared_list.append(list(call_data[0]["External"][0].keys()))
                call_dict[k] = pub_shared_list
                for data in list(call_data[0]["External"][0].keys()):
                    process_flow.pub_shared_call(data, db_data,file_name)
                    metadata.append(
                        {"from": k.replace("/",""), "to": data, "name": "External","file" : call_data[0]["External"][0][data][0]})
            if call_data[0]["Pub_shared"] != []:
                pub_shared_list.append(list(call_data[0]["Pub_shared"][0].keys()))
                call_dict[k] = pub_shared_list
                for data in list(call_data[0]["Pub_shared"][0].keys()):
                    process_flow.pub_shared_call(data, db_data,file_name)
                    metadata.append(
                        {"from": k.replace("/",""), "to": data, "name": "External","file" : call_data[0]["Pub_shared"][0][data][0]})
        #print(k,file_name,metadata)
        return metadata

if __name__ == '__main__':
    process_flow_object=process_flow()
    process_flow_object.startup()