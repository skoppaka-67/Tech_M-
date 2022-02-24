import glob,re,os,json,requests,config
ProgramNameList=[]
CCData=[]
Dict={}
jsondict={}

code_location =config.codebase_information['code_location']

def main():
 for path, subdirs, files in os.walk(code_location):
  for name in files:
    r=0
    select_flag=False
    filename=os.path.join(path, name)
    if not filename.split('\\')[-1].endswith('.vb') or  filename.split('\\')[-1].upper().__contains__(".DESIGNER."):
        continue
    Program_Name = open(filename)
    for line in Program_Name.readlines():
        if line.lstrip().startswith("'"):

            continue
        else:

            If_Rex = re.findall(r'^\s*If\s*', line)
            if(If_Rex!=[]):
                if not re.search('.*End If.*', line):
                     r=r+1
                continue

            if select_flag:
                if re.search('.*End Select.*', line, re.IGNORECASE):
                    select_flag = False
                    continue
                if re.search('.*Case.*', line, re.IGNORECASE):
                    r = r + 1
                    continue

            if re.search('.*Select Case.*', line, re.IGNORECASE):
                select_flag = True
                continue

            if re.search('.*For\s.*', line):
                r = r + 1
                continue

            if re.search('.*Do\s.*', line):
                r = r + 1
                continue

    CCData.append(r+1)
    program_name(filename)

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
print(Dict)


r = requests.post('http://localhost:5020/api/v1/augment/cycloMetric',json=Dict)
print(r.status_code)
print(r.text)
