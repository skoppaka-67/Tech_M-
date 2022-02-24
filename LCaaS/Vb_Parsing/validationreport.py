# -*- coding: utf-8 -*-
"""
@author: naveen
"""
import codevalidation
import os
import pandas as pd
from flask import Flask, jsonify, request
from flask import send_from_directory
app = Flask(__name__)
from pymongo import MongoClient
client = MongoClient('localhost', 27017)
db = client["vb"]
col = db["validation_report"]


extentions = {".aspx.vb":["',",","]}#different comment synt

@app.route('/validationreport', methods=['GET'])
def validationreport():
    option = request.args.get('option')
    option1 = request.args.get('option1')
    cursor = col.find_one({},{"_id":0})
    output = cursor[option1.split(".")[0]+"+"+option]
    
#    output=[]
#    for item in cursor:
#        tempdict={}
#        tempdict["filename"]=item["filename"]
#        tempdict["Application"]=item["Application"]
#        tempdict["ScreenField"]=item["ScreenField"]
#        tempdict["Type"]=item["Type"]
#        tempdict["propertyvalidation"]="Allowkeys="+item["Allowkeys"]+","+"ReadOnly="+item["ReadOnly"]
#        if tempdict["Type"]=="RequiredFieldValidator":
#            tempdict["validators"]="type="+item["Type"].replace("Validator","")+","+"ErrorMessage="+ item["ErrorMessage"]+"," +"ControlToValidate="+item["ControlToValidate"]  
#        elif tempdict["Type"]=="CompareValidator":
#            tempdict["validators"]="type="+item["Type"].replace("Validator","")+","+"ControlToCompare="+item["ControlToCompare"]+"," +"ControlToValidate="+item["ControlToValidate"]
#        elif tempdict["Type"]=="RangeValidator":
#            tempdict["validators"]="type="+item["Type"].replace("Validator","")+","+"MinimumValue="+item["MinimumValue"]+","+"MaximumValue="+item["MaximumValue"]+","+"ErrorMessage="+ item["ErrorMessage"]+"," +"ControlToValidate="+item["ControlToValidate"]
#        elif tempdict["Type"]=="RegularExpressionValidator":
#            tempdict["validators"]="type="+item["Type"].replace("Validator","")+","+"ValidationExpression="+item["ValidationExpression"]+","+"ErrorMessage="+ item["ErrorMessage"]+"," +"ControlToValidate="+item["ControlToValidate"]  
# 
#        elif tempdict["Type"]=="CheckBox":
#            tempdict["validators"]="type="+item["Type"]
#        elif tempdict["Type"]=="ComboBox":
#            tempdict["validators"]="type="+item["Type"]
#        elif tempdict["Type"]=="TextBox":
#            tempdict["validators"]="type="+item["Type"]
#        elif tempdict["Type"]=="DropDownList":
#            tempdict["validators"]="type="+item["Type"]          
#        else:
#            tempdict["validators"]=""
#            
#        key = item["ScreenField"]+"+"+item["filename"].split(".")[0]+"+"+item["Application"]
#        if key in CVlist.keys():
#            tempdict["CodeValidation"]=CVlist[key]
#        else:
#            tempdict["CodeValidation"]=""
#        output.append(tempdict)
        
    return jsonify(output)
#    docs = pd.DataFrame(output)
#    docs.to_excel(base_path+"output_VR_Report.xlsx", index=False)  
#    return send_from_directory(base_path,"output_VR_Report.xlsx", as_attachment=True)


if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0',port=5030)
    
#http://127.0.0.1:5030/validationreport?option=ANONYMOUS&option1=BookDetails.aspx
#http://127.0.0.1:5030/validationreport?option=TESTING&option1=Mock.aspx
#http://127.0.0.1:5030/validationreport?option=ANONYMOUS&option1=Browsing2.aspx 