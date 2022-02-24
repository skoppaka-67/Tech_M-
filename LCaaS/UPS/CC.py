import glob,re,os,json,requests,config
import xlsxwriter
import pandas as pd
ProgramNameList=[]
CCData=[]
Dict={}
jsondict={}

cobol_folder_name = config.codebase_information['COPYBOOK']['folder_name']
cobol_extension_type = config.codebase_information['COBOL']['extension']
code_location =config.codebase_information['code_location']
CobolPath=code_location+'\\'+cobol_folder_name
# print(CobolPath)
# CobolPath="C:\\UPS_APS\\APS\\"

def main():
 Evalute = False
 Perform=False
 c=0

 for filename in glob.glob(os.path.join(CobolPath,"*.aps")):
    print(filename)
    Program_Name = open(filename,errors='ignore',encoding="ISO-8859-1")

    r=0
    for line1 in Program_Name.readlines():
        b = IsDivision(line1)
        print(b)
        if b != 0:
            break
        else:
            continue
    Program_Name = open(filename)
    for line in Program_Name.readlines():
        line = Cut_Line(line, b)
        if isComment(line):

            continue
        else:

            Eval_Rex = re.findall(r'^\s*EVALUATE.*', line)
            End_Eval_Rex = re.findall(r'^.*\sEND-EVALUATE.*', line)
            if (Eval_Rex != []):
                Evalute = True

            if (Evalute):
                When_Rex = re.findall(r'^.*\sWHEN.*', line)
                if (When_Rex != []):
                    r = r + 1
                    continue

            if (End_Eval_Rex != []):
                Evalute = False

            If_Rex = re.findall(r'^\s*IF\s*', line)
            if (If_Rex != []):
                r = r + 1
                continue

            If_Rex = re.findall(r'^\s*ELSE-IF\s*', line)
            if (If_Rex != []):
                r = r + 1
                continue
            If_Rex = re.findall(r'^\s*UNTIL\s*', line)
            if (If_Rex != []):
                r = r + 1
                continue

            Perform_Rex = re.findall(r'^\s*PERFORM\s*', line)
            if Perform_Rex != [] or Perform:
                Performvarying_Rex = re.findall(r'^\s*PERFORM\s.*VARYING', line)
                if (Performvarying_Rex != []):
                    print(line)
                    r = r + 1
                    continue

                PerformUntil_Rex = re.findall(r'^\s*PERFORM\s.*UNTIL', line)
                if (PerformUntil_Rex != []):
                    Performvarying_Rex1 = re.findall(r'^\s*PERFORM\s.*VARYING', line)
                    if (Performvarying_Rex1 == []):
                        r = r + 1
                        continue

                PerformTimes_Rex = re.findall(r'^\s*PERFORM\s.*TIMES', line)
                if (PerformTimes_Rex != []):
                    r = r + 1
                    continue

                if (Perform):
                    varying_Rex = re.findall('^\s.*VARYING', line)
                    Until_Rex = re.findall('^\s.*UNTIL', line)
                    if (varying_Rex != [] or Until_Rex != []):

                        r = r + 1

                        Perform = False
                        continue
                    else:
                        continue
                Perform = True

            Search_Rex = re.findall(r'^\s*SEARCH\s.*', line)
            if (Search_Rex != []):
                r = r + 1
                continue

    CCData.append(r + 1)
    program_name(filename)

    # workbook = xlsxwriter.Workbook('Cyclomatic Complexity Report .xlsx')
    # worksheet = workbook.add_worksheet("Cyclomatic Complexity Report ")
    # worksheet.write('Component Name',filename )
    # worksheet.write('Component Type', CCData)
    # workbook.close()

# def IsDivision(line1):
#     Temp_Line = line1
#     if Temp_Line[0:14] == "IDENTIFICATION" or Temp_Line[7:9] == "ID":
#         Index = line1.index(Temp_Line[7:21])
#         Index = Index - 1
#         return Index
#     else:
#         return False
def IsDivision(line1):
    Temp_Line = line1
    Index = 1
    return Index

def Cut_Line(line, b):
    line = line[b:]
    return line


def isComment(line):
    if len(line) > 0:
        if line[0:2] == '/*':
            return True
        else:
            return False

# def Cut_Line(line,b):
#     line=line[6:]
#     return line
# def isComment(line):
#     if line[0]=='*':
#         # print("Comment:",line)
#         return True
#     else:
#          return False


def program_name(file_name):
    file_name = file_name.split('\\')
    file_name = file_name[len(file_name) - 1]
    #file_name = file_name.split('.')
    #file_name = file_name[0]
    ProgramNameList.append(file_name)



main()


for i in range(len(ProgramNameList)):
    Dict[ProgramNameList[i]]=CCData[i]

jsondict["data"]=Dict
print(json.dumps(Dict,indent=4))

import pandas as pd

# Create a Pandas dataframe from the data.
df = pd.DataFrame({'Data': Dict})

# Create a Pandas Excel writer using XlsxWriter as the engine.
writer = pd.ExcelWriter('copybook.xlsx', engine='xlsxwriter')

# Convert the dataframe to an XlsxWriter Excel object.
df.to_excel(writer, sheet_name='Sheet1')

# Close the Pandas Excel writer and output the Excel file.
writer.save()


r = requests.Session()
r.trust_env = False

rs =r.post('http://localhost:5000/api/v1/augment/cycloMetric',json=Dict)
print(rs.status_code)
print(rs.text)


