import os
import re
import pandas as pd
import pymongo

path = 'C:\\Users\jiya\Desktop\Sachin Internship\internship notes\Day 6\Bookstore'
dbName='Csharp'
collectionName='screenfields'
client = pymongo.MongoClient('localhost', 27017)

list_of_attributes = ["Enabled", "Visible", "Comments",
                      "Tooltip", "MaxLength", "ReadOnly", "Required",
                      "Min-Max", "for_control", "Allowkeys", "Lable", "Length"
                         ,"ErrorMessage", "ControlToValidate", "ControlToCompare","MaximumValue"
                         , "MinimumValue", "ValidationExpression" ,"TextMode","DropdownValue"
                         ,"DataSource", "DataTextField", "DataValueField"]

def fetchAttribute(type):
    df = pd.read_excel("controls_list.xlsx")
    control = df['Control']
    for i in range(len(control)):
        if control[i] == type:
            attribute = df['Type'][i]
            return attribute
        else:
            if(i==len(control)-1):
                return ""

def checkSectionNameAndID(Type, screenfield,listOfSectionName,listOfSectionID,mark1,mark2):
    dictionary={}
    dictionary["SectionName"] = ""
    dictionary["SectionID"] = ""
    if "Panel" in Type and mark1 == False:
        dictionary["SectionName"] = Type
        dictionary["SectionID"] = screenfield
        listOfSectionName.append(Type)
        listOfSectionID.append(screenfield)
        mark2 =True

    if "Panel" not in Type and mark2 == True:

        if listOfSectionID !=[]:
            dictionary["SectionName"] = listOfSectionName[len(listOfSectionName) - 1]
            dictionary["SectionID"] = listOfSectionID[len(listOfSectionID) - 1]

    if "Panel" in Type and mark2 == True:

        if Type not in listOfSectionName and screenfield not in listOfSectionID:
            dictionary["SectionName"] = Type
            dictionary["SectionID"] = screenfield
            listOfSectionName.append(Type)
            listOfSectionID.append(screenfield)
    return dictionary, listOfSectionName,listOfSectionID, mark1,mark2

#---------------------------------------------------------------------------------------------------
"""Code to look for "With "+screenfield and some extra data inside an internal function declared inside the Page_Load function
   and defined in that same .aspx.cs files and fetch required data"""

def checkInternalFunc(internalFuncName, listaspxcslines,screenfield,count2,flagTemp2,flag4,flag5):
    if "." in internalFuncName:
        internalFuncName=internalFuncName.split(".")[1].split("(")[0]+"("
    else:
        internalFuncName=internalFuncName.split("(")[0]+"("
    dictionary={}
    for line in listaspxcslines:
        if ("Sub "+internalFuncName in line) or ("void"+internalFuncName in line):
            flag4=True
            continue
        if (("Sub "+internalFuncName not in line) or ("void"+internalFuncName not in line)) and (flag4==True) :
            if ("{" in line and "}" not in line):
                count2 += 1
                flagTemp2=True
            tempvar = " " + screenfield + "."
            if re.search(r'%s[a-zA-Z]+ ='% tempvar,line):
                l = re.split("=", line)[1].replace(" ", "").replace("\n","")
                b = re.split("=", line)[0].replace(" ", "").replace("\n","")
                c = b.split(".")
                dictionary[c[1]]=l
            if ("{" not in line and "}" in line):
                count2 -= 1
            if ("With "+screenfield in line):
                flag5=True
                continue
        if flag5==True:
            li = line.strip()
            if '=' in li and li.startswith('.'):
                dictionary[li.split(" ")[0].replace(".","")]= li.split(" ")[2]
        if "End With" in line and flag5==True:
            flag5=False
            continue
        if ("End Sub" in line) and flag4==True:
            flag4=False
            break
        if(count2==0) and(flag4==True) and flagTemp2==True:
            flag4=False
            break
    return dictionary, flag4,flag5

#---------------------------------------------------------------------------------------------------
"""Code to look for "With "+screenfield and some extra data inside Page_Load function in corresponding .aspx.cs files and fetch required data"""
def checkcsFiles(screenfield,listaspxcslines,count1,flagtemp1,flag2,flag3):
    dictionary={}
    count2 = 0
    flagTemp2 = False
    flag4 = False
    flag5 = False
    for line in listaspxcslines:
        if "Sub Page_Load" in line or "void Page_Load" in line:
            flag2=True
            continue
        if (("Sub Page_Load" not in line )or ("void Page_Load" not in line))and (flag2==True) :
            #print(line)
            if( "{" in line and "}" not in line):
                count1+=1
                flagtemp1=True
            tempvar = " "+screenfield+"."
            if re.search(r'%s[a-zA-Z]+ ='% tempvar,line) :
                l = re.split("=", line)[1].replace(" ", "").replace("\n","")
                b = re.split("=", line)[0].replace(" ", "").replace("\n","")
                c = b.split(".")
                dictionary[c[1]]=l
            if re.findall(r" \w+\([a-zA-Z]*\);$", line):
                internalFuncName=re.findall(r" \w+\([a-zA-Z]*\);$", line)[0]
                tempDict1,flag4,flag5 = checkInternalFunc(internalFuncName,listaspxcslines,screenfield,count2,flagTemp2,flag4,flag5)
                dictionary.update(tempDict1)
            if re.findall(r".+\w+\([a-zA-Z]*\)$", line) and "=" not in line:
                internalFuncName = re.findall(r".+\w+\([a-zA-Z]*\)$", line)[0]
                tempDict2,flag4,flag5 = checkInternalFunc(internalFuncName,listaspxcslines,screenfield,count2,flagTemp2,flag4,flag5)
                dictionary.update(tempDict2)
            if ("{" not in line and "}" in line):
                count1 -= 1
            if ("With "+screenfield in line):
                flag3=True
                continue
        if flag3==True:
            li = line.strip()
            if '=' in li and li.startswith('.'):
                dictionary[li.split(" ")[0].replace(".","")]= li.split(" ")[2]
        if "End With" in line and flag3==True:
            flag3=False
            continue
        if ("End Sub" in line)and flag2==True:
            flag2 = False
        if count1==0 and flag2==True and flagtemp1==True:
            flag2=False
    return dictionary, flag2, flag3

#---------------------------------------------------------------------------------------------------
"""Code to check for "ID" in the <asp> tag and create "screenField" : valus as "key" : "Value" pair. Value is the value held by "ID" attribute
   Code to fetch "Type" and "Attribute" 
   Anything after <asp: before next attribute inside the <asp> becomes the value for the key "Type" 
   the "type" corresponding to the value of the key "Type" inside control_list.xlsx file becomes the value for the key "Attribute" """

def checkScreenFieldTypeAttribute(line,listaspxcslines,Type, screenfield,mark1,mark2,listOfSectionName,listOfSectionID):
    dictionary = {}
    count1 = 0
    flagtemp1 = False
    flag2 = False
    flag3 = False


    if "<asp" in line:
        if re.search(r'\bID=', line) or re.search(r'\bid=', line):
            if re.search(r'\bID=', line):
                screenfield = line.split(" ID=")[1].split()[0].replace('"', "")
                dictionary["ScreenField"] = screenfield
                tempDictt, flag2, flag3=checkcsFiles(screenfield, listaspxcslines,count1,flagtemp1,flag2,flag3)
                dictionary.update(tempDictt)
                # checkcsFiles(screenfield, listaspxcslines)
            else:
                screenfield = line.split(" id=")[1].split()[0].replace('"', "")
                dictionary["ScreenField"] = screenfield
                tempDictt, flag2, flag3 = checkcsFiles(screenfield, listaspxcslines, count1, flagtemp1, flag2, flag3)
                dictionary.update(tempDictt)
                # checkcsFiles(screenfield, listaspxcslines)
        else:
            dictionary["ScreenField"] = ""
        if re.search(r':', line):
            Type = line.split("<asp:")[1].split()[0].split(">")[0]
            dictionary["Type"] = Type
            attribute = fetchAttribute(Type)
            dictionary["Attributes"] = attribute
        tempDicttt,listOfSectionName,listOfSectionID, mark1,mark2=checkSectionNameAndID(Type,screenfield,listOfSectionName,listOfSectionID,mark1,mark2)
        dictionary.update(tempDicttt)
    if "</asp:" in line and "Panel":
        T= line.split("</asp:")[1].split()[0].split(">")[0]
        if "Panel" in T:
            # if len(listOfSectionName)and len(listOfSectionID)!=0:
            listOfSectionName.pop()
            listOfSectionID.pop()
    return dictionary,mark1,mark2,listOfSectionName,listOfSectionID
#---------------------------------------------------------------------------------------------------
"""Code to check for existence of attributes given in the list inside the <asp> tag and create correspinding "key" : "Value" """
def checkListOfAttributes(line):
    # consider the example of visible=false and "....give condition for both cases..like sstring in side quotes or if no quotes are present
    dictionary = {}

    for i in list_of_attributes:
        dictionary[i] = ""
        if re.findall(r' %s *='%i,line):
        # if re.search(" "+i+"=", line):
            v=re.split(r'%s *= *'%i,line)[1][0]
            # val = line.split(i + "=")[1].split(" ")[0].replace('"/>', "").replace('"', "").replace("\n","")
            if (v == '"'):
                val = re.findall(r'"([^"]*)"', re.split(r'%s *= *'%i,line)[1])[0]
                dictionary[i] = val
            if (v == "'"):
                vall = re.findall(r"'([^']*)'", re.split(r'%s *= *'%i,line)[1])[0]
                dictionary[i] = vall
    return dictionary
#---------------------------------------------------------------------------------------------------
"""Code to check for "Width" in the <asp> tag and create "Length" : valus as "key" : "Value" pair. Value is the value held by "Width" attribute"""
def checkWidth(line):
    dictionary = {}

    dictionary["Length"] = ""
    if re.search(r'\bWidth\b', line):
        v = line.split("Width=")[1][0]
        if (v == '"'):
            val = re.findall(r'"([^"]*)"', line.split("Width=")[1])[0]
            dictionary["Length"] = val
        if (v == "'"):
            vall = re.findall(r"'([^']*)'", line)[0]
            dictionary["Length"] = vall
    return dictionary

#---------------------------------------------------------------------------------------------------
"""Code to check for "Text" in the <asp> tag and create "Label" : valus as "key" : "Value" pair. Value is the value held by "Text" attribute"""
def checkText(line):
    dictionary = {}

    dictionary["Label"] = ""
    if re.search(r'\bText\b', line):
        v = line.split("Text=")[1][0]
        if (v == '"'):
            val = re.findall(r'"([^"]*)"', line.split("Text=")[1])[0]
            dictionary["Label"] = val
        if (v == "'"):
            vall = re.findall(r"'([^']*)'", line)[0]
            dictionary["Label"] = vall
    return dictionary

#---------------------------------------------------------------------------------------------------
"""Code to open .aspx files and corresponding .aspx.cs files"""
def openFile(file, name_of_file, name_of_folder):
    listaspxcslines = []
    listOFDictionary = []

    listOfSectionName = []
    listOfSectionID = []
    flag1 = False
    mark1 = False
    mark2 = False
    Type=''
    screenfield=''
    csFile = file.split(".")[0] + ".aspx.cs"
    aspxfile = open(file, "r", encoding="utf8")
    aspxcsfile = open(csFile, "r", encoding="utf8")
    for index in aspxcsfile:
        listaspxcslines.append(index)
    tempDict={}
    for line in aspxfile:
        dictionary = {}

        if("<asp" in line and ">" in line):

            dictionary["filename"] = name_of_file
            dictionary["application"] = name_of_folder
            dictionary.update(checkListOfAttributes(line))

            dictionary.update(checkWidth(line))
            dictionary.update(checkText(line))

        if("<asp" in line and ">" not in line):
            tempDict["filename"] = name_of_file
            tempDict["application"] = name_of_folder
            tempDict.update(checkListOfAttributes(line))
            aa,mark1,mark2,listOfSectionName,listOfSectionID=checkScreenFieldTypeAttribute(line,listaspxcslines,Type, screenfield,mark1, mark2,listOfSectionName,listOfSectionID)
            tempDict.update(aa)
            tempDict.update(checkWidth(line))
            tempDict.update(checkText(line))

            for i in list_of_attributes:
                tempDict[i] = ""
                if re.search(i, line):
                    if (line.split(i + "=")[0] in i):
                        val = line.split(i + "=")[1].split(" ")[0].replace('"/>', "").replace('"', "")
                        tempDict[i] = val
            flag1=True
            continue
        if("<asp" not in line and flag1==True):
            tempDict["filename"] = name_of_file
            tempDict["application"] = name_of_folder
            tempDict.update(checkListOfAttributes(line))
            #tempDict.update(checkScreenFieldTypeAttribute(line, listaspxcslines))
            tempDict.update(checkText(line))
            tempDict.update(checkWidth(line))
            for i in list_of_attributes:
                if re.search(i, line):
                    v = line.split(i+"=")[1][0]
                    if (v == '"'):
                        val = re.findall(r'"([^"]*)"', line.split(i+"=")[1])[0]
                        tempDict[i]=val
                    if (v == "'"):
                        vall = re.findall(r"'([^']*)'", line)[0]
                        tempDict[i] = vall
            if(">"in line):
                flag1=False
                dictionary.update(tempDict)
        aa,mark1,mark2,listOfSectionName,listOfSectionID=checkScreenFieldTypeAttribute(line,listaspxcslines,Type, screenfield,mark1, mark2,listOfSectionName,listOfSectionID)

        dictionary.update(aa)

        if dictionary != {}:

            print(dictionary) # this is the required dictionary of key value pairs
            listOFDictionary.append(dictionary)
    return listOFDictionary

def directoryFilesIteration(path):
    completeScreenFieldList=[]
    tempScreenFieldList=[]
    for subdir, dirs, files in os.walk(path):
        for filename in files:
            filepath = subdir + os.sep + filename
            a = os.path.normpath(subdir)
            name_of_folder = os.path.basename(a)
            if filepath.endswith(".aspx"):
                without_extra_slash = os.path.normpath(filepath)
                fileNameAndExtension = os.path.basename(without_extra_slash)
                tempScreenFieldList.append(openFile(filepath, fileNameAndExtension, name_of_folder))

    for item1 in tempScreenFieldList:
        for item2 in item1:
            # print(item2)
            completeScreenFieldList.append(item2)
    return completeScreenFieldList

def checkDBExistance(path,dbName,collectionName):
    global information
    dbnames = client.list_database_names()
    if dbName in dbnames:
        db = client[dbName]
        if collectionName in str(db.list_collection_names()):
            information = db[collectionName].drop()
            information = db[collectionName]
            information.insert_many(directoryFilesIteration(path))
        else:
            information = db[collectionName]
            information.insert_many(directoryFilesIteration(path))
    else:
        db = client[dbName]
        information = db[collectionName]
        information.insert_many(directoryFilesIteration(path))

checkDBExistance(path,dbName,collectionName)


# openFile('C:\\Users\jiya\Desktop\Sachin Internship\internship notes\Day 6\Bookstore\Anonymous\BookDetails.aspx', "BookDetails.aspx", "Anonymous")
# openFile('C:\\Users\jiya\Desktop\Sachin Internship\internship notes\Day 6\Bookstore\Anonymous\Browsing2.aspx', "Browsing2.aspx", "Anonymous")
# openFile('C:\\Users\jiya\Desktop\Sachin Internship\internship notes\Day 6\Bookstore\Anonymous\CheckOut.aspx', "CheckOut.aspx", "Anonymous")
# openFile('C:\\Users\jiya\Desktop\Sachin Internship\internship notes\Day 6\Bookstore\Owner\OwnerAddBook.aspx', "OwnerAddBook.aspx", "Owner")

#--------------------------------------------------------------------------------------------------
"""code to insert the required data into the CSV file"""
# df = pd.DataFrame(listOFDictionary,index=[i for i in range(0,len(listOFDictionary))])
# #df.to_excel("CSFile.xlsx")
