"""

owner : Bhavya JS

JAVA Rules_report

Dependencies: config file with
filepath, collectionname and dbname
which should be changed according to the user

"""


import json,os,copy
import config
from pymongo import MongoClient
import pandas as pd

client=MongoClient("localhost",port=27017)
dbname=config.dbname
collectionname=config.brecn

filespath = config.filespath
extensions = [".jsp", ".java", ".css", ".js"]

class bre():
    def getallfiles(self):  # function to return the file paths in the given directory with given extention
        filespath = config.filespath
        extensions = [".jsp", ".java", ".css", ".js"]

        filelist = []
        for root, dirs, files in os.walk(filespath):
            for file in files:
                if file.lower().endswith(tuple([item.lower() for item in extensions])):
                    filelist.append(os.path.join(root, file))
        return filelist

    def fetch_application(self,file):
      colname = config.componenttypecn
      col = client[dbname][colname]
      application = list(col.find({"component_name": file.split('\\')[-1]}, {'id': 0}))
      application = application[0]['application']
      return application

    def createdict(self,file):

        """This function reads all files and captures each function from the files
         and creates dictionary for each function with key as function name and value as
         list of lines in that function
         :param filename:passing file name to get the dictionary of functions
         :return:different dictionary will be returned for each function
         """

        functionname=""
        flag=False
        flag1=False
        count=0
        funlist=[]
        dictionary={}
        f=open(file,"r")
        fi=file.split("\\")[-1]
        if fi.endswith (".java"):           ##opens files of java extension and runs through the functions.
            for line in f.readlines():
                if (line.strip().startswith("protected") or line.strip().startswith("public") or line.strip().startswith("private")) and line.strip().__contains__("(") and line.strip().__contains__(")"):
                        functionname=line.split("(")[0].split()[-1]
                        flag=True
                if flag and line.strip().__contains__("{"):         ## count is used inorder to capture the entire function from start till end eventhough "{" found inbetween
                    count+=1
                    flag1 = True
                if flag and line.strip().__contains__("}"):
                    count-=1

                if flag and flag1 and count==0:
                    flag=False
                    flag1=False
                    funlist.append(line)
                    dictionary[functionname]=copy.deepcopy(funlist)         ## this creates dictionary with key function name and value as list of lines.
                    funlist.clear()
                if flag:
                    funlist.append(line)            ##when flag is true it appends lines to list
        #print(json.dumps(dictionary,indent=4))
        return dictionary


    def getallreports(self,filespath,extensions):

        """1.The first method here is it captures the conditonal statements parallely ignores commentlines
           from each function and stores in list.
           2.After fetching the conditional statements the list is read again to find the number of conditional statements.
           3.If the conditional statements count increases to 2 then seperate jsons will be created for
           nested conditions,else the conditional statements count remains 1 then it directly forms json
           and appends the json to METADATA."""

        files=self.getallfiles()

        conditions=""
        count=0
        brac_flag=False
        brac_counter=0
        flag=False
        flag1=False
        condition_list=[]
        condition_count=0
        functionname=""
        function=""
        comment_flag=False
        METADATA = []

        for file in files:

            f=self.createdict(file)          ##calling the function and storing it.
            countRule = 0

            for item in f:              ##iterating through dictionary
                for line in f[item]:    ##reading each line from each dictionary

                    if (line.strip().startswith("protected") or line.strip().startswith("public") or line.strip().startswith("private")) and line.strip().__contains__("(") and line.strip().__contains__(")"):
                        function = line.strip().split(")")[0]
                        functionname=function+")"

                    if line.strip().startswith("default") or line.strip().startswith("if") or line.strip().startswith("else if") or line.strip().startswith("else") or line.strip().startswith("while") or line.strip().startswith("for") or line.strip().startswith("switch") or line.strip().startswith("case") or line.strip().startswith("do "):
                        flag = True
                    if line.strip().endswith("*/"):         ##ignoring block comments and single line comments
                        comment_flag = False
                        flag=False
                        continue
                    if line.strip().startswith("//"):
                        comment_flag=False
                        continue
                    if line.strip().startswith("/*"):
                        comment_flag = True



                    if comment_flag==False and flag and line.strip().__contains__("{"):         ##captures entire conditional statement block
                        condition_count += 1
                        flag1 = True
                    if comment_flag==False and flag and line.strip().__contains__("}"):
                        condition_count -= 1
                    if comment_flag==False and flag and flag1 and condition_count == 0:
                        condition_list.append(line.replace("\t", " "))
                        flag = False
                        flag1 = False
                    if flag and comment_flag==False:
                            condition_list.append(line.replace("\t", " "))



                    if not flag and not flag1 and condition_list!=[]:           ##iterating through list again and finding count of conditional statements
                            if_count = 0
                            for line in condition_list:
                                if line.strip().startswith("default") or line.strip().startswith("if") or line.strip().startswith("else if") or line.strip().startswith("else") or line.strip().startswith("while") or line.strip().startswith("for") or line.strip().startswith("switch") or line.strip().startswith("case") or line.strip().startswith("do "):
                                    if_count += 1           ##after reading the condition list we get the count of th conditional statements

                            if if_count == 1:            ##if ifcount remains one, itcreates a string for that list of lines and stores in json
                                if condition_list != "":
                                    countRule += 1

                                    for line in condition_list:
                                        conditions = conditions + "\n" + line.strip().replace("\t", " ")
                                    output = ({"fragment_Id": file.split("\\")[-1] +"-"+str(countRule),
                                               "pgm_name": file.split("\\")[-1],
                                               "para_name": functionname,
                                               "Rule":"RULE-" + str(countRule),
                                               "source_statements": conditions,
                                               "rule_relation": "RULE-" + str(countRule),
                                               "rule_description": "",
                                               "rule_category":"",
                                               "application":self.fetch_application(file)})

                                    METADATA.append(copy.deepcopy(output))
                                    conditions = ""
                                    output.clear()
                                    condition_list.clear()


                            else:           ##if if_count becomes 2 then splits all the nested conditons and adds to seperate json
                                parent_rules = []
                                for line in condition_list:

                                    if line.strip().startswith("default") or line.strip().startswith("if") or line.strip().startswith("else if") or line.strip().startswith("else") or line.strip().startswith("while") or line.strip().startswith("for") or line.strip().startswith("switch") or line.strip().startswith("case") or line.strip().startswith("do "):
                                        count += 1
                                        brac_flag = True

                                    if brac_flag and line.strip().__contains__("{"):
                                        brac_counter += 1

                                    if brac_flag and line.strip().__contains__("}"):
                                        brac_counter -= 1
                                        if brac_counter == 0:
                                            conditions = conditions + line.strip().replace("\t", " ")+"\n"
                                            brac_flag = False
                                            condition_list.clear()

                                    if count == 2 or line.strip().__contains__("}"):
                                        if conditions != "":

                                            """the below code creates json and also generates parent rule id for each conditions.
                                            1.parent rule id remains same as rule id for first conditional statement
                                            2.if second nested condition is found it appends the current rule id to the exsisting parent rule id
                                            3.if third nested condition is found it appends the current rule id to the exsisting parent rule id
                                            4.if the third nested condition ends then it removes its rule id from the parent rule id.
                                            5.similarly for second and first conditions."""

                                            if conditions.startswith("if") or conditions.startswith("else if") or conditions.startswith("else") or conditions.startswith("switch") or conditions.startswith("case") or conditions.startswith("default") or conditions.startswith("while") or conditions.startswith("do") or conditions.startswith("for"):
                                                countRule += 1
                                                Rule="RULE-" + str(countRule)
                                            else:
                                                Rule=""

                                            if conditions.startswith("}") and (conditions.__contains__("else") or conditions.__contains__("case") or conditions.__contains__("if") or conditions.__contains__("switch") or conditions.__contains__("else") or conditions.__contains__("for") or conditions.__contains__("else if") or conditions.__contains__("switch") or conditions.__contains__("while") or conditions.__contains__("do")):
                                                parent_rules.pop()
                                                parent_rules.append("RULE-" + str(countRule))

                                            elif conditions.startswith("}")or conditions.endswith("}") or conditions.endswith("break"):
                                                if conditions.endswith("break"):
                                                    parent_rules.pop()
                                                    parent_rules.append("RULE-" + str(countRule))
                                                else:
                                                    parent_rules.pop()

                                            else:
                                                parent_rules.append("RULE-" + str(countRule))

                                            parent = str(parent_rules)

                                            output = ({"fragment_Id": file.split("\\")[-1] +"-"+str(countRule),
                                                       "pgm_name": file.split("\\")[-1],
                                                       "para_name": functionname,
                                                       "Rule": Rule,
                                                       "source_statements": conditions,
                                                       "rule_relation":(parent.replace("[", "").replace("]", "")) ,
                                                       "rule_description": "",
                                                       "rule_category":"",
                                                       "application":self.fetch_application(file)})
                                            if conditions.__contains__("default") and conditions.__contains__("break"):
                                                parent_rules.pop()

                                            METADATA.append(copy.deepcopy(output))
                                            conditions = ""
                                            output.clear()

                                            if line.strip().startswith("if") or line.strip().startswith("else if") or line.strip().startswith("else") or line.strip().startswith("while") or line.strip().startswith("for") or line.strip().startswith("switch") or line.strip().startswith("case") or line.strip().startswith("do "):
                                                count = 1
                                            else:
                                                count = 0

                                    if count == 1 or (brac_counter != 0 and brac_flag):
                                        conditions = conditions +line.strip().replace("\t", " ")+"\n"
        return METADATA

    def dbinsertfunction(self,filespath, dbname, collectionname):
        """
                this function is to update database by calling show code and getfiles functions
                :param dbname: database name from config file
                :param collectionname: collectionname from config file
                """

        col = client[dbname][collectionname]
        output = self.getallreports(filespath,extensions)
        if output != []:
            if col.count_documents({}) != 0:
                col.drop()
                print("Deleted the old", dbname, collectionname, "collection")

            col.insert_one({"type": "metadata",
                            "headers": ["fragment_Id","pgm_name", "para_name","Rule",
                                        "source_statements","rule_relation",
                                        "rule_description","rule_category"]})
            col.insert_many(output)
            print("Inserted the list of jsons of", dbname, collectionname)
        else:
            print("There are no jsons in the output to insert in the DB", dbname, collectionname)

if __name__ == '__main__':
        # output = getallreports(filespath)
        # if not os.path.exists("outputs//"):
        #       os.makedirs("outputs//")
        #  #json.dump(output , open('outputs\\variable_impact report.json', 'w'), indent=4)
        # pd.DataFrame(output).to_excel("outputs\\variable_impact report.xlsx", index=False)
        reports=bre()
        reports.dbinsertfunction(filespath, dbname, collectionname)

