# -*- coding: utf-8 -*-
"""
@author: naveen
"""

from flask import Flask, jsonify, request
app = Flask(__name__)
from pymongo import MongoClient
client = MongoClient('localhost', 27017)
db = client["vb"]
col = db["screenfields"]

@app.route('/showvrdata', methods=['GET'])
def showvrdata():
    option = request.args.get('option')
    option1 = request.args.get('option1')
    cursor = list(col.find({"filename":option1,"Application":option,},
                           {"filename":1,"Application":1,"ScreenField":1,"Type":1,
                            "Allowkeys":1,"ReadOnly":1,"ErrorMessage":1,
                            "ControlToValidate":1,"ControlToCompare":1,"MaximumValue":1,
                            "MinimumValue":1,"ValidationExpression":1,"_id":0}))
    output=[]
    for item in cursor:
        tempdict={}
        tempdict["filename"]=item["filename"]
        tempdict["Application"]=item["Application"]
        tempdict["ScreenField"]=item["ScreenField"]
        tempdict["Type"]=item["Type"]
        tempdict["propertyvalidation"]="Allowkeys="+item["Allowkeys"]+","+"ReadOnly="+item["ReadOnly"]
        if tempdict["Type"]=="RequiredFieldValidator":
            tempdict["validators"]="type="+item["Type"].replace("Validator","")+","+"ErrorMessage="+ item["ErrorMessage"]+"," +"ControlToValidate="+item["ControlToValidate"]  
        elif tempdict["Type"]=="CompareValidator":
            tempdict["validators"]="type="+item["Type"].replace("Validator","")+","+"ControlToCompare="+item["ControlToCompare"]+"," +"ControlToValidate="+item["ControlToValidate"]
        elif tempdict["Type"]=="RangeValidator":
            tempdict["validators"]="type="+item["Type"].replace("Validator","")+","+"MinimumValue="+item["MinimumValue"]+","+"MaximumValue="+item["MaximumValue"]+","+"ErrorMessage="+ item["ErrorMessage"]+"," +"ControlToValidate="+item["ControlToValidate"]
        elif tempdict["Type"]=="RegularExpressionValidator":
            tempdict["validators"]="type="+item["Type"].replace("Validator","")+","+"ValidationExpression="+item["ValidationExpression"]+","+"ErrorMessage="+ item["ErrorMessage"]+"," +"ControlToValidate="+item["ControlToValidate"]  
        else:
            tempdict["validators"]=""
        output.append(tempdict)
    return jsonify(output)

if __name__ == '__main__':
    app.run()
    
#http://127.0.0.1:5000/Anonymous/BookDetails.aspx
#http://127.0.0.1:5000/showvrdata?option=ANONYMOUS&option1=BookDetails.aspx
#http://127.0.0.1:5000/showvrdata?option=TESTING&option1=Mock.aspx