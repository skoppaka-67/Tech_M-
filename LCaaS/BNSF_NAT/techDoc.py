from docxtpl import DocxTemplate
from docx import *
from docx import Document
from docxtpl import InlineImage
from docx.shared import Mm
from flask_cors import CORS
from flask import Flask, request, send_file
from pymongo import MongoClient
import time
from jinja2 import Environment, FileSystemLoader
import datetime
import pythoncom
import os,win32com,csv
from docx.shared import Inches


Version="Version 3, Adding some more features.(map, comment lines etc. "

hostname = 'localhost'
database_name = 'bnsf1'
#database_name1='COBOL'
port=27017
client = MongoClient(hostname, port)
db = client[database_name]

# @app.route('/api/v1/generateDocument', methods=['GET'])
# def generateDocument():
#    try:
doc1=Document()
localtime = time.asctime( time.localtime(time.time()) )
import win32com.client as win32

x=datetime.datetime.now()

#Name= request.args.get('option')
Name="EDOSC050.cbl"

pgm_name=db.master_inventory_report.find({"type": {"$ne": "metadata"}})

pgm_list=[]

for values in pgm_name:
    if values["component_type"]=="COBOL":
        pgm_list.append(values["component_name"])


# Creating Excel for screen reports.

# map_list=set()
# map_name_list=[]
# check_map_list=[]
#
# Screen_pgm=db.cross_reference_report.find({"$and":[{"component_name" : Name}, {"called_type" : "MAP"}]})
#
# for data in Screen_pgm:
#     if data in check_map_list:
#         continue
#     map_list.add(data['called_name'])
#     check_map_list.append(data['called_name'])
#     map_name_list.append({"mapname":data['called_name']})
#
# screen_data=db.cics_rule_report.find({"program_name":Name},{"_id":0})
# screen_list=[]
# number=0
#
#
# for i in screen_data:
#     screen_list.append(i)
#
# import csv
# keys=["program_name",
#         "map_name",
#         "field_name",
#         "validation_rule",
#         "rule_number"]
#
# if os.path.exists('C:\\New folder\\CICS\\'+Name+'.csv'):
#     os.remove('C:\\New folder\\CICS\\'+Name+'.csv')
#
# with open('C:\\New folder\\CICS\\'+Name+'.csv', 'w') as output_file:
#     dict_writer = csv.DictWriter(output_file, keys)
#     dict_writer.writeheader()
#     dict_writer.writerows(screen_list)


# Create excel for glossary report.

#Create glossary excel.

glossary_list=[]
key = [
        "component_name",
        "Variable",
        "Business_Meaning","Group_Element","Dead"
    ]

glossary=db.glossary.find({"component_name" : Name},{"_id":0})

for data in glossary:
    glossary_list.append(data)

if glossary_list==[]:

    if os.path.exists('C:\\New folder\\glossary\\' + Name + '.csv'):
        os.remove('C:\\New folder\\glossary\\' + Name + '.csv')

else:

    if os.path.exists('C:\\New folder\\glossary\\'+Name+'.csv'):
        os.remove('C:\\New folder\\glossary\\'+Name+'.csv')

    with open('C:\\New folder\\glossary\\'+Name+'.csv', 'w') as output_file:
        dict_writer = csv.DictWriter(output_file, key)
        dict_writer.writeheader()
        dict_writer.writerows(glossary_list)

# Create Bre-1 Excel.


bre_data_list=[]
key = ["_id",
        "pgm_name",
        "fragment_Id",
        "para_name",
        "source_statements",
        "statement_group",
        "rule_category",
        "parent_rule_id",
        "application"
    ]

bre_data=db.bre_rules_report.find({"pgm_name" : Name.split('.')[0]+'.'},{"s_no":0,"business_documentation":0})

for data in bre_data.sort('_id'):
    bre_data_list.append(data)

if bre_data_list==[]:

    if os.path.exists('C:\\New folder\\bre\\' + Name + '.csv'):
        os.remove('C:\\New folder\\bre\\' + Name + '.csv')

else:

    if os.path.exists('C:\\New folder\\bre\\'+Name+'.csv'):
        os.remove('C:\\New folder\\bre\\'+Name+'.csv')

    with open('C:\\New folder\\bre\\'+Name+'.csv', 'w') as output_file:
        print(bre_data_list)
        dict_writer = csv.DictWriter(output_file, key)
        dict_writer.writeheader()
        dict_writer.writerows(bre_data_list)


# Create BRE-2 report excel.


bre2_data_list=[]
key = ["fragment_id",
    "pgm_name",
        "para_name",
        "source_statements",
        "rule_description",
       "rule_category",
        "Rule",
        "rule_relation"
    ]

bre2_data=db.bre_report2.find({"pgm_name" : Name.split('.')[0]},{"_id":0})

for data in bre2_data:
    bre2_data_list.append(data)

if bre2_data_list==[]:

    if os.path.exists('C:\\New folder\\bre2\\' + Name + '.csv'):
        os.remove('C:\\New folder\\bre2\\' + Name + '.csv')

else:

    if os.path.exists('C:\\New folder\\bre2\\'+Name+'.csv'):
        os.remove('C:\\New folder\\bre2\\'+Name+'.csv')

    with open('C:\\New folder\\bre2\\'+Name+'.csv', 'w') as output_file:
        dict_writer = csv.DictWriter(output_file, key)
        dict_writer.writeheader()
        dict_writer.writerows(bre2_data_list)




pythoncom.CoInitialize()
#for Name in pgm_list:
    #Name=Name.split('.')

#Name=Name[0]
flow_path="D:\\pf\\"+Name+".pdf"
#spider_path="C:\\cobol\\"+Name+".pdf"
bre_path="C:\\New folder\\bre\\"+Name+".csv"
bre2_path="C:\\New folder\\bre2\\"+Name+".csv"
glossary_path='C:\\New folder\\glossary\\' + Name + '.csv'
#cics_path='C:\\New folder\\CICS\\' + Name + '.xlsx'
word = win32.gencache.EnsureDispatch('Word.Application')
doc=word.Documents.Open("D:\\lcaas_tech_doc\\Tech Mahindra_BRE_Template-TW.docx")
word.Visible = False


# if os.path.exists(cics_path):
#     doc.InlineShapes.AddOLEObject(FileName=cics_path, DisplayAsIcon=1, Range=doc.Paragraphs(310).Range,
#                                   IconLabel=Name,
#                                   IconFileName=Name, LinkToFile=True)
if os.path.exists(flow_path):
    doc.InlineShapes.AddOLEObject(FileName=flow_path, DisplayAsIcon=1, Range=doc.Paragraphs(279).Range, IconLabel=Name,
                                  IconFileName=Name,LinkToFile =True)
# if  os.path.exists(spider_path):
#     doc.InlineShapes.AddOLEObject(FileName=spider_path,DisplayAsIcon=1,Range=doc.Paragraphs(342).Range,IconLabel=Name,IconFileName=Name,LinkToFile =True)
if os.path.exists(bre_path):

    doc.InlineShapes.AddOLEObject(FileName=bre_path, DisplayAsIcon=1, Range=doc.Paragraphs(311).Range, IconLabel=Name,
                                  IconFileName=Name,LinkToFile =True)
if os.path.exists(bre2_path):
    doc.InlineShapes.AddOLEObject(FileName=bre2_path, DisplayAsIcon=1, Range=doc.Paragraphs(314).Range, IconLabel=Name,
                                  IconFileName=Name,LinkToFile =True)
if os.path.exists(glossary_path):
    doc.InlineShapes.AddOLEObject(FileName=glossary_path, DisplayAsIcon=1, Range=doc.Paragraphs(319).Range, IconLabel=Name,
                                  IconFileName=Name, LinkToFile=True)


word.ActiveDocument.SaveAs("D:\\res_tect_doc\\Tech Mahindra_BRE_Template11.docx")
doc.Close()

# hostname1="localhost"
# port1=27017
# client1 = MongoClient(hostname1, port1)
# db1 = client1[database_name1]

comment_line=db.cobol_output.find({"component_name" : Name})
comment_data=""
comment_data1=[]
for data in comment_line:

    comment_data= data['codeString']
    comment_data=comment_data.split('<br>')
    for com_data in comment_data:
        comment_data1.append({"data":com_data+'\n'})


invoking_list=[]
invoking_pgm= db.cross_reference_report.find({"$and":[{"called_name" : Name.split('.')[0]}, {"called_type" : "COBOL"},{"component_type":"COBOL"}]})

for data in invoking_pgm:
    invoking_list.append(data["component_name"])

called_list=[]

called_pgm = db.cross_reference_report.find({"$and":[{"component_name" : Name.split('.')[0]}, {"called_type" : "COBOL"}]})

for data in called_pgm:
 called_list.append(data)

calling_list=[]
calling_pgm=db.cross_reference_report.find({"$and":[{"called_name" : Name.split('.')[0]}, {"called_type" : "COBOL"}]})
for data in calling_pgm:
    calling_list.append(data)

copy_list=[]
calling_pgm=db.cross_reference_report.find({"$and":[{"component_name" : Name.split('.')[0]}, {"called_type" : "COPYBOOK"}]})
for data in calling_pgm:
    copy_list.append(data)

curd_pgm=db.crud_report.find({"component_name":Name.split('.')[0]})
dict_list=[]
for data in curd_pgm:
    dict_list.append(data)
Bre_pgm=db.bre_report2.find({"pgm_name" : Name.split('.')[0]})

jcl_list=[]
jcl_pgm=db.cross_reference_report.find({"$and":[{"called_name" : Name.split('.')[0]}, {"called_type" : "COBOL"}]})
job_name=""

for data in jcl_pgm:

    if data["component_type"] == "JCL":
        jcl_list.append(data["component_name"])
        job_name=data["component_name"]

    elif data["component_type"] == "Proc":
        job_name=""
        jcl_list.append( data["component_name"])
        proc_pgm = db.cross_reference_report.find({"$and": [{"called_name": data["component_name"]},{"called_type": "Proc"}]})
        for data in proc_pgm:
         jcl_list.append(data["component_name"])

        for i in range(len(jcl_list)):
            if job_name=="":
                job_name = job_name+ jcl_list[i]
            else:
              job_name=job_name+','+jcl_list[i]


app_name_list=[]
app_name_string=db.master_inventory_report.find({ "component_name" : Name})

for data in app_name_string:
    app_name_list.append(data["application"])
app_name_data=app_name_list[0]


step_name=""
file_name_list=[]
disp_list=[]
step_name_list=db.cross_reference_report.find({"called_name" : Name.split('.')[0]})
for data in step_name_list:
    step_name=data["step_name"]
    file_name=db.cross_reference_report.find({"step_name" : step_name, "called_type" : "File"})
    for data in file_name:
        for key in data.keys():

            if key=="access_mode":
                line=data["access_mode"]
                line=line.replace('\n','')
                if line.__contains__("SHR"):
                   data["access_mode"]="Read"
                elif line.__contains__("NEW") or line.__contains__("OLD") or line.__contains__("MOD") :
                    data["access_mode"]="Write"
        file_name_list.append(data)


Bre_list=[]
my_key ="source_statements"
for data in Bre_pgm:

   for key in data.keys():
       if key==my_key:
           line=data[key]
           line=line.replace("<br>","\n")
           data[key]=line
           Bre_list.append(data)


map_list=set()
map_name_list=[]
check_map_list=[]

Screen_pgm=db.cross_reference_report.find({"$and":[{"component_name" : Name.split('.')[0]}, {"called_type" : "MAP"}]})

for data in Screen_pgm:

    if data['called_name'] in check_map_list:
        continue
    map_list.add(data['called_name'])
    check_map_list.append(data['called_name'])

    map_name_list.append({"mapname":data['called_name']})


screen_data=db.cics_field.find({"type": {"$ne": "metadata"}})
screen_list1=[]
number=0
for map in map_list:

     for screen_line in screen_data:

        if map==screen_line['map_name']:

              if screen_line["field_name"] =="" and screen_line["type"]=="":
                   continue
              else:
                  number = number + 1
                  screen_line['No'] = number
                  screen_list1.append(screen_line)



file_loader = FileSystemLoader('templates')

env = Environment(loader=file_loader)

doc = DocxTemplate( "D:\\res_tect_doc\\Tech Mahindra_BRE_Template11.docx")


doc.render({'called_pgm':",".join(invoking_list),'Program_Name' : Name,"date":x.strftime("%x"),"Customer_Name":"Tech Mahindra","Project_Name":"Modernization",
    'called_name':["called name","desc"]
,"app_name":app_name_data,"comment_lines":comment_data1,"col_data":called_list,"job":job_name,"calling_data":calling_list,"copy_data":copy_list, "file_data":file_name_list,"dict":dict_list,"bre":Bre_list,"screen":screen_list1,"map":map_name_list})

doc.save("D:\\res_tect_doc\\Tech Mahindra_BRE_Template11.docx"+Name.split('.')[0]+'.docx')
pythoncom.CoUninitialize()

   #      return { "status": "success"}
   #
   # except Exception as error:
   #
   #     return {"status": "failure"}