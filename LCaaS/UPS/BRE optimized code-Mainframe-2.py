import xlrd,os,copy,re,glob,xlsxwriter,openpyxl
from pymongo import MongoClient
import time,datetime ,pytz
import timeit
import config
from SortedSet.sorted_set import SortedSet
PGM_ID=[]
Current_Division_Name=""
time_zone = 'Asia/Calcutta'
tz = pytz.timezone(time_zone)

client = MongoClient(config.database['hostname'], config.database['port'])
db = client[config.database['database_name']]
# db=client["UPS_BRE"]

cobol_folder_name = config.codebase_information['COBOL']['folder_name']
cobol_extension_type = config.codebase_information['COBOL']['extension']
COPYBOOK = config.codebase_information['COPYBOOK']['folder_name']

code_location =config.codebase_information['code_location']
ConditionPath=config.codebase_information['condition_path']
CobolPath=code_location+'\\'+cobol_folder_name

version="fixed parent rule id for if and end-if in mainframe and fixed GE fix for mainframe. Latest of all BRE code and commenting all perform expanding statements. "
version1="Customized for TW , perform expansion is done for section also. and copy also changed."
version2="Perform regexx also changed to capture perform not starting from the first"
version3="Latest with only five perform levels."
version4="BNSF v1"
def main():
 Performparalist=[]
 Old_Division_Name = ""
 main_list=[]
 main_dict={}
 Key_Word_List=["USE","#########","#####","++INCLUDE","DISPLAY","ACCEPT","INITIALIZE","EXIT","EXIT.","IF","EVALUATE","INITIATE","ADD","SUBTRACT","DIVIDE","MULTIPLY","COMPUTE","MOVE","INSPECT","STRING","UNSTRING","SET","SEARCH",
                 "CONTINUE","END-IF.","END-IF","OPEN","END-RETURN","END-COMPUTE","TERMINATE","END-RETURN.","END-COMPUTE.","CLOSE","NEXT","END-EVALUATE.","END-EVALUATE","WHEN","READ","WRITE","END-IF.","END-PERFORM.","END-PERFORM","REWRITE","DELETE","START","CALL","PERFORM","GO","STOP","GOBACK.","SORT","MERGE","EXEC","ENTRY","ELSE"]
 main_list1 = []
 main_dict1 = {}

 temp_string=''
 string1='^\s*'
 string2='\s.*'
 string3='\s*'
 header=['cond','tag']
 wb = xlrd.open_workbook(ConditionPath)
 sheet = wb.sheet_by_index(0)
 row=sheet.nrows
 cols=sheet.ncols
 for index in range(row):
     temp_list=[]
     temp_list1=[]
     value=sheet.cell_value(index,0)
     TypeValue=sheet.cell_value(index,1)
     #print(TypeValue)
     if value=="YES" and TypeValue=="COBOL":
       for index1 in range(cols):

          value1=sheet.cell_value(index,index1)
          temp_list1.append(value1)
          temp_list.append(value1)
          #print(temp_list[1])
       del temp_list[0]
       del temp_list[0]
       del temp_list1[0]
       del temp_list1[0]

       temp_string=temp_list[0]
       #print(temp_string)
       temp_string1=temp_list1[0]
       temp_string=string1+temp_string.strip()+string2

       temp_string1=string1+temp_string1.strip()+string3
       #print(temp_string)

       temp_list[0]=temp_string
       temp_list1[0]=temp_string1
       #print(temp_string)

       for i in range(len(header)):
        main_dict[header[i]]=temp_list[i]
       temp_dict=copy.deepcopy(main_dict)
       main_list.append(temp_dict)

       for  j in range(len(header)):
           main_dict1[header[j]]=temp_list1[j]
       temp_dict1 = copy.deepcopy(main_dict1)
       main_list1.append(temp_dict1)
 i = 0
 j = 0
 ProgramNumber=0
 countvar=0
 empty = "                                                                  "
 METADATA = []
 currentmodule=""
 procFlag = False
 #Component = COMPONENT_NAME.split('\\')
 #componentlength = len(Component)
 #Name = Component[componentlength - 1]
 currentpara = []
 currentparastring = ""
 modulelist=[]
 performlist=[]
 CopyPath=code_location+'\\'+COPYBOOK
 counter=0
 # DB delete.

 # if db.bre_rules_report.delete_many(
 #         {"type": {"$ne": "metadata"}}).acknowledged:
 #    print("DB delete")

 wb1 = xlrd.open_workbook("D:\\WORK\\IMS\\sample.xlsx")
 sheet = wb1.sheet_by_index(0)
 row = sheet.nrows
 cols = sheet.ncols
 file_list = []
 for index in range(row):
     value = sheet.cell_value(index, 0)
     file_list.append(value)

 filelist=[]
 cursor = db.bre_rules_report.distinct("pgm_name")
 for data in cursor:
     filelist.append(data)
 for filename in glob.glob(os.path.join(CobolPath,'*.cbl')):

    filename1 = filename.split('\\')
    len_file = len(filename1)
    filename1 = filename1[len_file - 1][:-3]

    if filename1 in filelist:
        continue

    print(filename)
    if counter==1:
        counter=0
        #print("Metabta",METADATA)
        Db_Insert( METADATA)
        METADATA = []
    counter = counter + 1
    procFlag_copy = False
    Performparalist = []
    Id_Division(filename)
    i=i+1
    Program_Name = open(filename)
    flag=False
    flag1=False
    onelinebuffer=[]
    anotherparalist=[]
    onelineflag=False
    execflag1 = False
    end_dec_flag=True
    moduleflag = True
    section_flag=False
    module = []
    section_regexx_data=""
    Copy_file = ["appl-specific-batch-proc.", "appl-specific-online-proc.", "appl-specific-ttm-proc."]

    #with open(Name , "r+") as temp_file:
    for line in Program_Name.readlines():
          # print("Inside:",line)
          if not len(line) > 6:
              continue
          if line.strip()=="":
              continue
          line=line[6:72].upper()
          # print("First:", line)
          if line[0]=='*':
              continue

          line=line[1:]
          #print("sdf",line)
          if line.strip()=='' or  line[0]=='*' or line.strip()=="SKIP1" or line.strip()=="SKIP2" or line.strip()=='EJECT':
              continue
          else:
             try:
              with open("Copy_Expanded_Data" + '.txt', "a+") as copyfile:
                  line=line.upper()
                  line1 = line.split()
                  if len(line1) >= 2:
                      divisionline_copy = line1[1]
                      if divisionline_copy.__contains__('.'):
                          divisionlinelength1 = len(divisionline_copy)
                          divisionline_copy = divisionline_copy[0:divisionlinelength1 - 1]
                          # print(divisionline_copy)
                      if line1[0] == "PROCEDURE" and divisionline_copy == 'DIVISION':
                          procFlag_copy = True
                  dec_regexx= re.findall(r'^\s*DECLARATIVES[.]\s*',line)
                  end_dec_regexx=re.findall(r'^\s*END\s*DECLARATIVES[.]\s*',line)
                  if dec_regexx!=[]:
                      end_dec_flag = False
                  if end_dec_regexx!=[]:
                      end_dec_flag=True
                      continue
                  if procFlag_copy and end_dec_flag:
                      line_list = line.split()
                      # lines_list4=line.split()
                      for iter in line_list:
                          if iter.upper().__contains__("COPY"):
                              var = (len(line_list))

                              if var >= 2:
                                  # print(line_list[var - 1])
                                  if line_list[var - 1].__contains__('"'):

                                      copyname = line_list[var - 1].replace('"', "")
                                      copyname = copyname[:-1]
                                      # print("lll",file_location1)
                                      Copyfilepath = code_location + '\\' + "COPYBOOK" + '\\' + copyname+'.cpy'
                                      # print(Copyfilepath)

                                  else:
                                      copyname = line_list[1].replace('"', "")
                                      # copyname = copyname[:-1]
                                      Copyfilepath = code_location + '\\' + "COPYBOOK" + '\\' + copyname+'.cpy'

                                  # if copyname.__contains__(","):
                                  #     copyname_list = copyname.split(",")
                                  #
                                  #     var = len(copyname_list)
                                  #     copyname = copyname_list[var-1]
                                  #     copyname = copyname_list[var-1]

                                  if os.path.isfile(Copyfilepath):
                                      tempcopyfile = open(Copyfilepath, "r")
                                      #copyfile.write("        #########" + " " + "BEGIN" + " " + copyname + '\n')
                                      for copylines in tempcopyfile.readlines():
                                          copyfile.write(copylines[6:72] + '\n')

                                      continue
                                      #copyfile.write("         #####" + " " + " END" + "####" + '\n')

                      copyfile.write(line +'\n')

                  copyfile.close()

             except Exception:

                  pass



    with open("Copy_Expanded_Data" + '.txt', "r+") as expanded_file:
        for line in expanded_file.readlines():
            #print(line)
            if line.strip() == '' or line[0] == '*' or line.strip() == "skip" or line.strip() == "skip" or line.strip() == 'eject':
                continue
            else:
             with open("Duplicatefile0" + str(i) + '.txt', "a") as temp_file1:
               line1=line.split()
               if len(line1)>=2:
                   divisionline=line1[1]
                   if divisionline.__contains__('.'):
                       divisionlinelength=len(divisionline)
                       divisionline=divisionline[0:divisionlinelength-1]
                   if line1[0]=="PROCEDURE" and divisionline=='DIVISION':
                      procFlag=True
               if procFlag:
                   module = re.findall(r'^[A0-Z9].*[-]*.*[.]', line)
                   Proc_regexx=re.findall(r'^\s*PROCEDURE\s*DIVISION.*',line)
                   if currentpara!=[] and module!=[]:
                       currentpara.clear()
                   if module != [] or Proc_regexx:
                       if Proc_regexx!=[]:
                           module=Proc_regexx
                       module = module[0]
                       module = re.sub("\sSECTION.","&SECTION.", module)
                       if onelinebuffer!=[]:
                           line6 = ""
                           for data in range(len(onelinebuffer)):
                               line6 = line6 + onelinebuffer[data]

                           line6=line6+' ^'+anotherparalist[len(anotherparalist)-1]
                           temp_file1.write('\n')
                           temp_file1.write(line6)
                           onelinebuffer.clear()
                       if module.__contains__('.'):
                           temp_file1.write('\n')
                           temp_file1.write(module)
                           currentpara.append(module)
                           anotherparalist.append(module)
                           temp_file1.write('\n')
                           #print(module)
                       else:
                           temp_file1.write('\n')
                           module=module+'.'
                           temp_file1.write(module)
                           #print(module)
                           anotherparalist.append(module)
                           currentpara.append(module)
                           temp_file1.write('\n')

                   else:
                       if currentpara!=[]:
                         currentparastring=currentpara[0]
                         line=re.sub('\n','',line)
                         line=line+'         ^'+currentparastring
                       onelinesplit=line.split('^')
                       actualline=onelinesplit[0]
                       firstword=actualline.split()
                       firstword=firstword[0]
                       #print(firstword)
                       if firstword =="EXEC":
                           if onelinebuffer != []:
                               line6 = ""
                               for data in range(len(onelinebuffer)):
                                   line6 = line6 + onelinebuffer[data]
                               line6 = line6 + ' ^' + onelinesplit[1]
                               temp_file1.write('\n')
                               temp_file1.write(line6)
                               onelinebuffer.clear()
                           execflag1=True
                           temp_file1.write('\n')
                           temp_file1.write(line)
                           temp_file1.write('\n')
                           continue
                       elif execflag1:
                           temp_file1.write('\n')
                           temp_file1.write(line)
                           temp_file1.write('\n')
                           if firstword=="END-EXEC" or firstword=="END-EXEC.":
                            execflag1 = False
                           continue
                       #print(actualline)
                       #if firstword in Key_Word_List and actualline.__contains__('. ') :
                       if firstword in Key_Word_List and actualline.strip().endswith('.'):
                          if onelinebuffer != []:
                            line7=""
                            for data in range(len(onelinebuffer)):
                                         line7 =line7+ onelinebuffer[data]
                            line7 = line7 + ' ^' + onelinesplit[1]
                            temp_file1.write('\n')
                            temp_file1.write(line7)
                            temp_file1.write('\n')
                            temp_file1.write(line)
                            #print(line)
                            onelineflag = False
                            onelinebuffer=[]
                            continue
                          else:
                             temp_file1.write('\n')
                             temp_file1.write(line)

                             temp_file1.write('\n')
                             continue
                       elif firstword in Key_Word_List :

                          if onelinebuffer!=[]:
                            line5=""
                            for data in range(len(onelinebuffer)):
                                 line5 = line5 + onelinebuffer[data]
                                 onelineflag = False
                            line5=line5+' ^'+onelinesplit[1]
                            temp_file1.write('\n')
                            temp_file1.write(line5)
                            onelinebuffer=[]
                            if firstword in Key_Word_List and  actualline.__contains__('.'):
                                 temp_file1.write('\n')
                                 temp_file1.write(line)
                                 continue
                            else:
                                onelineflag = True
                                actualline = actualline + ' ' + '<br>' + ' '
                                onelinebuffer.append(actualline)
                                continue
                          else:
                                    onelineflag=True
                                    actualline = actualline +' '+'<br>'+ ' '
                                    onelinebuffer.append(actualline)
                                    continue
                       elif actualline.__contains__('.'):
                           if onelineflag:
                                     # print(actualline)
                                      onelineflag = False
                                      actualline = actualline + '           ^'+onelinesplit[1]
                                      onelinebuffer.append(actualline)
                                      line = ""
                                      for data in range(len(onelinebuffer)):
                                          line = line + onelinebuffer[data]
                                      temp_file1.write('\n')
                                      temp_file1.write(line)
                                      onelinebuffer=[]
                                      continue
                       elif onelineflag:
                                  actualline = actualline + ' ' + '<br>'+ ' '
                                  onelinebuffer.append(actualline)
                                  continue
                       onelinebuffer=[]
             temp_file1.close()
    expanded_file.close()    


    if_flag=False
    if_counter=0

    exists = os.path.isfile("Duplicatefile0" + str(i) + '.txt')

    if not exists:
        os.remove("Copy_Expanded_Data.txt")
        with open("Program_log.txt","a")as error_doc:
            filename=filename.split('\\')
            filename=filename[len(filename)-1]
            error_doc.write("Error on:")
            error_doc.write(filename)
            error_doc.write("\n")
        error_doc.close()
        continue
    # Replacing [.] with end if statement.

    with open("Duplicatefile0" + str(i) + '.txt', "r") as temp_file9:
     with open("Duplicatefile" + str(i) + '.txt', "a") as temp_file7:
      Fullstring=temp_file9.read()
      Fullstring=re.sub("<br>  ['^']",' ^',Fullstring)
      #print(Fullstring)
      section_line_list=[]
      for line in Fullstring.splitlines():
        # print("Second:",line)
        section_regexx=re.findall(r'^[^@][A0-Z9].*[-]*.*[&]SECTION[.]',line)

        if section_regexx!=[]:
            section_line_list.append(section_regexx[0].strip())

        line1=line.split('^')
        Replace_if_regexx=re.match('^\s*IF\s.*',line)
        endif_regexx=re.match('^\s*END-IF.*',line)

        if Replace_if_regexx!=None:
           if_flag=True
           if_counter=if_counter+1
           paravalue=line.split('^')
           paravalue=paravalue[1].strip()
        if if_flag:
          #print("line",line)
          # IF the dot is in next line then <br> will be must, if it sis in same line then line will have [0:65].
          dot_regexx=re.findall(r'.*[.]{1}$',line1[0].strip())
          #print(dot_regexx)
          dot_regexx1=re.findall(r'.*[<br>]*\s*[.]{1}$',line1[0].strip())
          #if (dot_regexx!=[] and endif_regexx==None) or (dot_regexx1!=[] and endif_regexx==None):
          if dot_regexx!=[] and endif_regexx==None:
              #print(line)
              Dot_line=re.sub('[.] ',' ',line)
              temp_file7.write("\n")
              temp_file7.write(Dot_line)
              temp_file7.write("\n")
              for data in range(if_counter):
               temp_file7.write("\n")
               temp_file7.write("       END-IF"+'                                                                ^'+paravalue)
               temp_file7.write("\n")
               if_flag = False
              if_counter=0
          else:
              temp_file7.write("\n")
              temp_file7.write(line)
              temp_file7.write("\n")
        else:
           temp_file7.write("\n")
           temp_file7.write(line)
           temp_file7.write("\n")
        if endif_regexx!=None:
           if if_counter==0:
            if_flag=False
           else:
               if_counter=if_counter-1
    
     temp_file7.close()
    temp_file9.close() 

     #with open("Duplicatefile" + str(i) + '.txt', "w") as temp_file7:
     # temp_file7.write(Fullstring)

    with open("Duplicatefile" + str(i) + '.txt', "r") as temp_file9:

      Fullstring = temp_file9.read()
      Fullstring = re.sub("<br>  ['^']", ' ^', Fullstring)

      with open("Duplicatefile0" + str(i) + '.txt', "w") as temp_file7:
          temp_file7.write(Fullstring)

      temp_file7.close() 
    temp_file9.close()  
    # Expanding the perform statements.

    with open("Duplicatefile0" + str(i) + '.txt',  'r') as PROC_DIV_CODE:
        current_para = ""
        para_names = []
        storage = []
        SectionRepository = {}
        for line_counter, line in enumerate(PROC_DIV_CODE):
            # print("TW_ELSE_Checking_Lines:",line)
            # Skip lines containing any of the below keywords
            if line.strip() == "" or line.strip().startswith('*'):
                continue
            if not re.match('.*eject.*', line, re.IGNORECASE):
                #if not re.match('.* exit *', line, re.IGNORECASE):
                    if not re.match('.* skip1.*', line, re.IGNORECASE):
                        if not re.match('.* skip2.*', line, re.IGNORECASE):
                            if not re.match('.* skip3.*', line, re.IGNORECASE):
                                # If the 8th position is not empty, it must the delcatation of a paragraph
                                # print("Line00000000000000:",line[0])
                                if line[1] != ' ' and not (line.__contains__("END-SECTION.")) and line.__contains__(
                                        '&SECTION'):
                                    if line[1:5] != "####":
                                        # print(prev_para)

                                        # future_para = line_counter(prev_para)+line

                                        prev_para = current_para
                                        # print("Current_para:",current_para)
                                        # print("Prev_para:",prev_para)

                                        # print("Future_para:",future_para)
                                        # print("Prev_paraaaa:",prev_para)
                                        current_para = line.split()[0].replace('&SECTION','')
                                        current_para = current_para.replace('.', '')

                                        para_names.append(current_para)
                                        # print("PARA_NAMES:",para_names)
                                        # print("Prev_paraaaaaa:",prev_para)
                                        # print("Current_paraaaaa:",current_para)
                                        # print("Storageeeeeee:",storage)
                                        if prev_para == '':
                                            SectionRepository[current_para] = copy.deepcopy(storage)
                                            storage.clear()

                                        else:

                                            SectionRepository[prev_para] = copy.deepcopy(storage)
                                            storage.clear()


                                else:
                                    # print(line)
                                    storage.append(line)
        SectionRepository[current_para] = copy.deepcopy(storage)
        list1 = []
        list2 = []
#        print("Checking:", json.dumps(paraRepository, indent=4))
    PROC_DIV_CODE.close()
    with open("Duplicatefile0" + str(i) + '.txt', "r") as PROC_DIV_CODE:
        current_para = ""
        para_names = []
        storage = []
        paraRepository = {}
        for line_counter, line in enumerate(PROC_DIV_CODE):
         if line.strip()=="" or line.strip().startswith('*'):
            continue
         else:
            # print("TW_ELSE_Checking_Lines:",line)
            # Skip lines containing any of the below keywords
            if not re.match('.*eject.*', line, re.IGNORECASE):
                #if not re.match('.* exit *', line, re.IGNORECASE):
                    if not re.match('.* skip1.*', line, re.IGNORECASE):
                        if not re.match('.* skip2.*', line, re.IGNORECASE):
                            if not re.match('.* skip3.*', line, re.IGNORECASE):
                                # If the 8th position is not empty, it must the delcatation of a paragraph
                                # print("Line00000000000000:",line[0])
                                if line[1] != ' ' and not (line.__contains__("END-SECTION.")):
                                    if line[1:5] != "####":
                                        # print(prev_para)

                                        # future_para = line_counter(prev_para)+line

                                        prev_para = current_para
                                        # print("Current_para:",current_para)
                                        # print("Prev_para:",prev_para)

                                        # print("Future_para:",future_para)
                                        # print("Prev_paraaaa:",prev_para)
                                        current_para = line.split()[0]
                                        current_para = current_para.replace('.', '')

                                        para_names.append(current_para)
                                        # print("PARA_NAMES:",para_names)
                                        # print("Prev_paraaaaaa:",prev_para)
                                        # print("Current_paraaaaa:",current_para)
                                        # print("Storageeeeeee:",storage)
                                        if prev_para == '':
                                            paraRepository[current_para] = copy.deepcopy(storage)
                                            storage.clear()

                                        else:

                                            paraRepository[prev_para] = copy.deepcopy(storage)
                                            storage.clear()

                                else:
                                    # print(line)
                                    storage.append(line)
        paraRepository[current_para] = copy.deepcopy(storage)
        list1 = []
        list2 = []
    PROC_DIV_CODE.close()
    # import json
    # print("Checking:", json.dumps(paraRepository, indent=4))

    #For the first para the para reference is not taken while using the direct file
    # ,so two files are created and used for expansion.
    section_regexx_data=""
    total_time=0
    expans_time=0
    currentmodulevalue=""
    with open("Duplicatefile" + str(i) + '.txt', "r") as temp_file:
      with  open("FinalFile0" + str(i) + '.txt', "a") as temp_file1:
        start_time = time.time()
        for line in temp_file.readlines():
         if line[0]=='*'or line.strip()=="":
             continue
         else:

          #perform = re.findall(r'^.*\sPERFORM\s[A0-Z9].*', line, re.IGNORECASE)
          perform = re.findall(r'^\s*PERFORM.*', line, re.IGNORECASE)
          if perform!=[]:
           Temp_perform=perform[0]
           l=Temp_perform.index("PERFORM ")
           Temp_perform=Temp_perform[l:].split()
           Temp_perform=Temp_perform[1]

           if Temp_perform.__contains__('.'):
             Performparalist.append(Temp_perform)
           else:
               Temp_perform=Temp_perform.replace(',','')
               Temp_perform=Temp_perform.strip()+'.'
               Performparalist.append(Temp_perform)

          module = re.findall(r'^[A0-Z9].*[-]*.*[.]', line)
          modulelist.append(module)

          lenofmodulelist=len(modulelist)
          if module!=[]:
             currentmodule = modulelist[lenofmodulelist - 1]
             currentmodulevalue= currentmodule[0]
             currentmodulevalue = re.sub('PERFORM', '', currentmodulevalue)

          if perform!=[]:

              performlist.append(perform)
              performline=perform
              perform=perform[0]
              l = perform.index("PERFORM ")
              perform=perform[l:].split()
              perform=perform[1]

              if perform=="UNTIL" or perform=="VARYING":
                  performlistlen=len(performlist)-1
                  del performlist[performlistlen]

              if perform.__contains__('.'):
               perform=''+perform

               if perform=="":
                  temp_file1.write('\n')
               else:
                 performWrite = ' @' + performline[0] + '  ^' + currentmodulevalue
                 temp_file1.write('\n')
                 temp_file1.write(performWrite)
              else:
                    if perform=="^":
                        temp_file1.write('\n')
                    else:
                      perform = ''+ perform + '.'
                      temp_file1.write('\n')
                      performWrite = ' @' + performline[0] +'   ^'+ currentmodulevalue
                      temp_file1.write(performWrite)

              #print(perform,paraRepository)
              if perform[:-1] in paraRepository.keys():
                  temp_file1.write('\n')
                  temp_file1.write('\n'.join(paraRepository[perform[:-1]]))
              elif perform[:-1] in SectionRepository.keys():
                  temp_file1.write('\n')
                  temp_file1.write('\n'.join(SectionRepository[perform[:-1]]))

                  # with  open("Duplicatefile0" + str(i) + '.txt', "r+") as temp_file2:
              #     start_time1=time.time()
              #     for line in temp_file2.readlines():
              #         module = re.findall(r'^[A0-Z9].*[-]*.*[.]', line)
              #         section_regexx = re.findall(r'^[A0-Z9].*[-]*.*[&]SECTION[.]', line)
              #         if module!=[]:
              #           module = module[0]
              #         #checking whether to extend the section or para.
              #         #Section expansion.
              #         if perform.replace('.','')+'&SECTION.' in  section_line_list and section_regexx!=[]:
              #             section_flag=True
              #         if section_flag:
              #             section_regexx = re.findall(r'^[A0-Z9].*[-]*.*[&]SECTION[.]', line)
              #             if section_regexx!=[]:
              #                 section_regexx_data=section_regexx[0]
              #             else:
              #                 section_regexx_data=""
              #             if perform.replace('.','')+'&SECTION.' == section_regexx_data and perform != "":
              #                 flag1 = True
              #                 start_time3 = time.time()
              #             elif flag1:
              #                 section_regexx = re.findall(r'^[A0-Z9].*[-]*.*[&]SECTION[.]', line)
              #                 if section_regexx != []:
              #                     flag1 = False
              #                     expans_time = expans_time + (time.time() - start_time3)
              #                     section_flag=False
              #                     break
              #                 if flag1:
              #                         temp_file1.write('\n')
              #                         temp_file1.write(line)
              #         #Paragraph expansion.
              #
              #         if perform==module and perform!=[]:
              #             flag=True
              #             start_time3 = time.time()
              #         elif flag:
              #             module = re.findall(r'^[A0-Z9].*[-]*.*[.]', line)
              #             if module != []:
              #                 flag = False
              #                 expans_time=expans_time+(time.time()-start_time3)
              #                 break
              #             if flag:
              #                  temp_file1.write('\n')
              #                  temp_file1.write(line)
              #
              # total_time=total_time+(time.time()-start_time1)
              # temp_file2.close()
          else:
                  temp_file1.write('\n')
                  temp_file1.write(line)
      print("end_time",time.time()- start_time)
      print("loop_time",total_time)
      print("expan",expans_time)
      temp_file1.close()

    
    temp_file.close()
    modulelist=[]
    performlist=[]

    total_time = 0
    expans_time = 0
    start_time=0
    start_time3=0
    start_time1=0
    section_regexx_data=""
    currentmodulevalue = ""
    with open("FinalFile0" + str(i) + '.txt', "r") as temp_file:
      with  open("FinalFile1" + str(i) + '.txt', "a") as temp_file1:
        start_time = time.time()
        for line in temp_file.readlines():
         perform=[]
         if line[0]=='*'or line.strip()=="":
             continue
         else:

          if line.strip().startswith('@'):
              pass
          else:
               perform = re.findall(r'^.*\s*PERFORM\s[A0-Z9].*', line, re.IGNORECASE)
          if perform!=[]:
           Temp_perform=perform[0]
           l = Temp_perform.index("PERFORM ")
           Temp_perform = Temp_perform[l:].split()
           Temp_perform=Temp_perform[1]
           if Temp_perform.__contains__('.'):
             Performparalist.append(Temp_perform)
           else:
               Temp_perform=Temp_perform.replace(',','')
               Temp_perform=Temp_perform.strip()+'.'
               Performparalist.append(Temp_perform)


          module = re.findall(r'^[A0-Z9].*[-]*.*[.]', line)
          modulelist.append(module)

          lenofmodulelist=len(modulelist)
          if module!=[]:
             currentmodule = modulelist[lenofmodulelist - 1]
             currentmodulevalue= currentmodule[0]
             currentmodulevalue = re.sub('PERFORM', '', currentmodulevalue)

          if perform!=[]:

              performlist.append(perform)
              performline=perform
              perform=perform[0]

              l = perform.index("PERFORM ")
              perform = perform[l:].split()

              perform=perform[1]

              if perform=="UNTIL" or perform=="VARYING":
                  performlistlen=len(performlist)-1
                  del performlist[performlistlen]

              if perform.__contains__('.'):
               perform=''+perform

               if perform=="":
                  temp_file1.write('\n')
               else:

                 performWrite = ' @' + performline[0] + '  ^' + currentmodulevalue
                 temp_file1.write('\n')
                 #print(performWrite)
                 temp_file1.write(performWrite)

              else:
                    if perform=="^":
                        temp_file1.write('\n')
                    else:
                      perform = ''+ perform + '.'
                      temp_file1.write('\n')
                      performWrite = ' @' + performline[0] +'   ^'+ currentmodulevalue
                      temp_file1.write(performWrite)
                  #temp_file1.close()

              if perform[:-1] in paraRepository.keys():
                  temp_file1.write('\n')
                  temp_file1.write('\n'.join(paraRepository[perform[:-1]]))
              elif perform[:-1] in SectionRepository.keys():
                  temp_file1.write('\n')
                  temp_file1.write('\n'.join(SectionRepository[perform[:-1]]))


          else:

                  temp_file1.write('\n')
                  temp_file1.write(line)
      temp_file1.close()
    print("second loop")
    print("end_time", time.time() - start_time)
    print("loop_time", total_time)
    print("expan", expans_time)

    # temp_file1.close()
    temp_file.close()
    modulelist = []
    performlist = []

    section_regexx_data = ""
    currentmodulevalue = ""
    with open("FinalFile1" + str(i) + '.txt', "r") as temp_file:
      with  open("FinalFile2" + str(i) + '.txt', "a") as temp_file1:
          for line in temp_file.readlines():
              # print(line)
              # line=line[6:71]
              perform = []
              if line[0] == '*' or line.strip() == "":
                  continue
              else:
                  # line = line[0:65]
                  # perform=re.findall(r'^\s*PERFORM\s.*',line)
                  if line.strip().startswith('@'):
                      #  print("222",line)
                      pass
                  else:
                      perform = re.findall(r'^.*\s*PERFORM\s[A0-Z9].*', line, re.IGNORECASE)
                  if perform != []:
                      Temp_perform = perform[0]
                      # print(line,":::::::",perform)
                      l = Temp_perform.index("PERFORM ")
                      Temp_perform = Temp_perform[l:].split()
                      # Temp_perform=Temp_perform.split()
                      Temp_perform = Temp_perform[1]
                      # print(Temp_perform)
                      if Temp_perform.__contains__('.'):
                          Performparalist.append(Temp_perform)
                      else:
                          Temp_perform = Temp_perform.replace(',', '')
                          Temp_perform = Temp_perform.strip() + '.'
                          Performparalist.append(Temp_perform)

                  module = re.findall(r'^[A0-Z9].*[-]*.*[.]', line)
                  modulelist.append(module)

                  lenofmodulelist = len(modulelist)
                  if module != []:
                      currentmodule = modulelist[lenofmodulelist - 1]
                      currentmodulevalue = currentmodule[0]
                      # print(currentmodulevalue)
                      currentmodulevalue = re.sub('PERFORM', '', currentmodulevalue)

                  if perform != []:
                      # print(perform)
                      performlist.append(perform)
                      performline = perform
                      perform = perform[0]

                      l = perform.index("PERFORM ")
                      perform = perform[l:].split()

                      # perform=perform.split()
                      perform = perform[1]
                      # perform=re.sub('.','',perform)
                      if perform == "UNTIL" or perform == "VARYING":
                          performlistlen = len(performlist) - 1
                          del performlist[performlistlen]

                      if perform.__contains__('.'):
                          perform = '' + perform
                          #with  open("FinalFile2" + str(i) + '.txt', "a") as temp_file1:
                          if perform == "":
                              temp_file1.write('\n')
                          else:
                              # print(currentmodulevalue)
                              # performWrite='@'+perform +'  ^'+currentmodulevalue
                              performWrite = ' @' + performline[0] + '  ^' + currentmodulevalue
                              temp_file1.write('\n')
                              # print(performWrite)
                              temp_file1.write(performWrite)
                          #temp_file1.close()

                      else:

                          #with  open("FinalFile2" + str(i) + '.txt', "a") as temp_file1:
                              if perform == "^":
                                  temp_file1.write('\n')
                              else:

                                  perform = '' + perform + '.'
                                  temp_file1.write('\n')
                                  performWrite = ' @' + performline[0] + '   ^' + currentmodulevalue
                                  temp_file1.write(performWrite)

                          #temp_file1.close()
                      if perform[:-1] in paraRepository.keys():
                          temp_file1.write('\n')
                          temp_file1.write('\n'.join(paraRepository[perform[:-1]]))
                      elif perform[:-1] in SectionRepository.keys():
                          temp_file1.write('\n')
                          temp_file1.write('\n'.join(SectionRepository[perform[:-1]]))


                  else:
                      #with  open("FinalFile2" + str(i) + '.txt', "a") as temp_file1:
                          temp_file1.write('\n')
                          temp_file1.write(line)
                      #temp_file1.close()

      temp_file1.close()
    temp_file.close()
    # modulelist = []
    # performlist = []

    # section_regexx_data = ""
    # with open("FinalFile2" + str(i) + '.txt', "r") as temp_file:
    #   with  open("FinalFile3" + str(i) + '.txt', "a") as temp_file1:
    #     for line in temp_file.readlines():
    #         # print(line)
    #         # line=line[6:71]
    #         perform = []
    #         if line[0] == '*' or line.strip() == "":
    #             continue
    #         else:
    #             # line = line[0:65]
    #             # perform=re.findall(r'^\s*PERFORM\s.*',line)
    #             if line.strip().startswith('@'):
    #                 #  print("222",line)
    #                 pass
    #             else:
    #                 perform = re.findall(r'^.*\s*PERFORM\s[A0-Z9].*', line, re.IGNORECASE)
    #             if perform != []:
    #                 Temp_perform = perform[0]
    #                 # print(line,":::::::",perform)
    #                 l = Temp_perform.index("PERFORM ")
    #                 Temp_perform = Temp_perform[l:].split()
    #                 # Temp_perform=Temp_perform.split()
    #                 Temp_perform = Temp_perform[1]
    #                 # print(Temp_perform)
    #                 if Temp_perform.__contains__('.'):
    #                     Performparalist.append(Temp_perform)
    #                 else:
    #                     Temp_perform = Temp_perform.replace(',', '')
    #                     Temp_perform = Temp_perform.strip() + '.'
    #                     Performparalist.append(Temp_perform)
    #
    #             module = re.findall(r'^[A0-Z9].*[-]*.*[.]', line)
    #             modulelist.append(module)
    #
    #             lenofmodulelist = len(modulelist)
    #             if module != []:
    #                 currentmodule = modulelist[lenofmodulelist - 1]
    #                 currentmodulevalue = currentmodule[0]
    #                 # print(currentmodulevalue)
    #                 currentmodulevalue = re.sub('PERFORM', '', currentmodulevalue)
    #
    #             if perform != []:
    #                 # print(perform)
    #                 performlist.append(perform)
    #                 performline = perform
    #                 perform = perform[0]
    #
    #                 l = perform.index("PERFORM ")
    #                 perform = perform[l:].split()
    #
    #                 # perform=perform.split()
    #                 perform = perform[1]
    #                 # perform=re.sub('.','',perform)
    #                 if perform == "UNTIL" or perform == "VARYING":
    #                     performlistlen = len(performlist) - 1
    #                     del performlist[performlistlen]
    #
    #                 if perform.__contains__('.'):
    #                     perform = '' + perform
    #                     #with  open("FinalFile3" + str(i) + '.txt', "a") as temp_file1:
    #                     if perform == "":
    #                         temp_file1.write('\n')
    #                     else:
    #                         # print(currentmodulevalue)
    #                         # performWrite='@'+perform +'  ^'+currentmodulevalue
    #                         performWrite = ' @' + performline[0] + '  ^' + currentmodulevalue
    #                         temp_file1.write('\n')
    #                         # print(performWrite)
    #                         temp_file1.write(performWrite)
    #                     #temp_file1.close()
    #
    #                 else:
    #
    #                     #with  open("FinalFile3" + str(i) + '.txt', "a") as temp_file1:
    #                         if perform == "^":
    #                             temp_file1.write('\n')
    #                         else:
    #
    #                             perform = '' + perform + '.'
    #                             temp_file1.write('\n')
    #                             performWrite = ' @' + performline[0] + '   ^' + currentmodulevalue
    #                             temp_file1.write(performWrite)
    #
    #                 if perform[:-1] in paraRepository.keys():
    #                     temp_file1.write('\n')
    #                     temp_file1.write('\n'.join(paraRepository[perform[:-1]]))
    #                 elif perform[:-1] in SectionRepository.keys():
    #                     temp_file1.write('\n')
    #                     temp_file1.write('\n'.join(SectionRepository[perform[:-1]]))
    #
    #                     #temp_file1.close()
    #
    #
    #             else:
    #                 #with  open("FinalFile3" + str(i) + '.txt', "a") as temp_file1:
    #                 temp_file1.write('\n')
    #                 temp_file1.write(line)
    #
    #                 #temp_file1.close()
    #   temp_file1.close()
    # temp_file.close()
    # modulelist = []
    # performlist = []
    #
    # section_regexx_data = ""
    # with open("FinalFile3" + str(i) + '.txt', "r") as temp_file:
    #   with  open("FinalFile4" + str(i) + '.txt', "a") as temp_file1:
    #     for line in temp_file.readlines():
    #         # print(line)
    #         # line=line[6:71]
    #         perform = []
    #         if line[0] == '*' or line.strip() == "":
    #             continue
    #         else:
    #             # line = line[0:65]
    #             # perform=re.findall(r'^\s*PERFORM\s.*',line)
    #             if line.strip().startswith('@'):
    #                 #  print("222",line)
    #                 pass
    #             else:
    #                 perform = re.findall(r'^.*\s*PERFORM\s[A0-Z9].*', line, re.IGNORECASE)
    #             if perform != []:
    #                 Temp_perform = perform[0]
    #                 # print(line,":::::::",perform)
    #                 l = Temp_perform.index("PERFORM ")
    #                 Temp_perform = Temp_perform[l:].split()
    #                 # Temp_perform=Temp_perform.split()
    #                 Temp_perform = Temp_perform[1]
    #                 # print(Temp_perform)
    #                 if Temp_perform.__contains__('.'):
    #                     Performparalist.append(Temp_perform)
    #                 else:
    #                     Temp_perform = Temp_perform.replace(',', '')
    #                     Temp_perform = Temp_perform.strip() + '.'
    #                     Performparalist.append(Temp_perform)
    #
    #             module = re.findall(r'^[A0-Z9].*[-]*.*[.]', line)
    #             modulelist.append(module)
    #
    #             lenofmodulelist = len(modulelist)
    #             if module != []:
    #                 currentmodule = modulelist[lenofmodulelist - 1]
    #                 currentmodulevalue = currentmodule[0]
    #                 # print(currentmodulevalue)
    #                 currentmodulevalue = re.sub('PERFORM', '', currentmodulevalue)
    #
    #             if perform != []:
    #                 # print(perform)
    #                 performlist.append(perform)
    #                 performline = perform
    #                 perform = perform[0]
    #
    #                 l = perform.index("PERFORM ")
    #                 perform = perform[l:].split()
    #
    #                 # perform=perform.split()
    #                 perform = perform[1]
    #                 # perform=re.sub('.','',perform)
    #                 if perform == "UNTIL" or perform == "VARYING":
    #                     performlistlen = len(performlist) - 1
    #                     del performlist[performlistlen]
    #
    #                 if perform.__contains__('.'):
    #                     perform = '' + perform
    #                     #with  open("FinalFile4" + str(i) + '.txt', "a") as temp_file1:
    #                     if perform == "":
    #                         temp_file1.write('\n')
    #                     else:
    #                         # print(currentmodulevalue)
    #                         # performWrite='@'+perform +'  ^'+currentmodulevalue
    #                         performWrite = ' @' + performline[0] + '  ^' + currentmodulevalue
    #                         temp_file1.write('\n')
    #                         # print(performWrite)
    #                         temp_file1.write(performWrite)
    #
    #                 else:
    #
    #                     #with  open("FinalFile4" + str(i) + '.txt', "a") as temp_file1:
    #                     if perform == "^":
    #                         temp_file1.write('\n')
    #                     else:
    #
    #                         perform = '' + perform + '.'
    #                         temp_file1.write('\n')
    #                         performWrite = ' @' + performline[0] + '   ^' + currentmodulevalue
    #                         temp_file1.write(performWrite)
    #                     #temp_file1.close()
    #
    #                 if perform[:-1] in paraRepository.keys():
    #                     temp_file1.write('\n')
    #                     temp_file1.write('\n'.join(paraRepository[perform[:-1]]))
    #                 elif perform[:-1] in SectionRepository.keys():
    #                     temp_file1.write('\n')
    #                     temp_file1.write('\n'.join(SectionRepository[perform[:-1]]))
    #
    #
    #
    #             else:
    #                 #with  open("FinalFile4" + str(i) + '.txt', "a") as temp_file1:
    #                     temp_file1.write('\n')
    #
    #                     temp_file1.write(line)
    #
    #                 #temp_file1.close()
    #   temp_file1.close()
    # temp_file.close()
    # modulelist = []
    # performlist = []
    #
    # section_regexx_data = ""
    # with open("FinalFile4" + str(i) + '.txt', "r") as temp_file:
    #   with  open("FinalFile5" + str(i) + '.txt', "a") as temp_file1:
    #     for line in temp_file.readlines():
    #         # print(line)
    #         # line=line[6:71]
    #         perform = []
    #         if line[0] == '*' or line.strip() == "":
    #             continue
    #         else:
    #             # line = line[0:65]
    #             # perform=re.findall(r'^\s*PERFORM\s.*',line)
    #             if line.strip().startswith('@'):
    #                 #  print("222",line)
    #                 pass
    #             else:
    #                 perform = re.findall(r'^.*\s*PERFORM\s[A0-Z9].*', line, re.IGNORECASE)
    #             if perform != []:
    #                 Temp_perform = perform[0]
    #                 # print(line,":::::::",perform)
    #                 l = Temp_perform.index("PERFORM ")
    #                 Temp_perform = Temp_perform[l:].split()
    #                 # Temp_perform=Temp_perform.split()
    #                 Temp_perform = Temp_perform[1]
    #                 # print(Temp_perform)
    #                 if Temp_perform.__contains__('.'):
    #                     Performparalist.append(Temp_perform)
    #                 else:
    #                     Temp_perform = Temp_perform.replace(',', '')
    #                     Temp_perform = Temp_perform.strip() + '.'
    #                     Performparalist.append(Temp_perform)
    #
    #             module = re.findall(r'^[A0-Z9].*[-]*.*[.]', line)
    #             modulelist.append(module)
    #
    #             lenofmodulelist = len(modulelist)
    #             if module != []:
    #                 currentmodule = modulelist[lenofmodulelist - 1]
    #                 currentmodulevalue = currentmodule[0]
    #                 # print(currentmodulevalue)
    #                 currentmodulevalue = re.sub('PERFORM', '', currentmodulevalue)
    #
    #             if perform != []:
    #                 # print(perform)
    #                 performlist.append(perform)
    #                 performline = perform
    #                 perform = perform[0]
    #
    #                 l = perform.index("PERFORM ")
    #                 perform = perform[l:].split()
    #
    #                 # perform=perform.split()
    #                 perform = perform[1]
    #                 # perform=re.sub('.','',perform)
    #                 if perform == "UNTIL" or perform == "VARYING":
    #                     performlistlen = len(performlist) - 1
    #                     del performlist[performlistlen]
    #
    #                 if perform.__contains__('.'):
    #                     perform = '' + perform
    #                     #with  open("FinalFile5" + str(i) + '.txt', "a") as temp_file1:
    #                     if perform == "":
    #                         temp_file1.write('\n')
    #                     else:
    #                         # print(currentmodulevalue)
    #                         # performWrite='@'+perform +'  ^'+currentmodulevalue
    #                         performWrite = ' @' + performline[0] + '  ^' + currentmodulevalue
    #                         temp_file1.write('\n')
    #                         # print(performWrite)
    #                         temp_file1.write(performWrite)
    #                     #temp_file1.close()
    #
    #                 else:
    #
    #                    # with  open("FinalFile5" + str(i) + '.txt', "a") as temp_file1:
    #                         if perform == "^":
    #                             temp_file1.write('\n')
    #                         else:
    #
    #                             perform = '' + perform + '.'
    #                             temp_file1.write('\n')
    #                             performWrite = ' @' + performline[0] + '   ^' + currentmodulevalue
    #                             temp_file1.write(performWrite)
    #
    #                 if perform[:-1] in paraRepository.keys():
    #                     temp_file1.write('\n')
    #                     temp_file1.write('\n'.join(paraRepository[perform[:-1]]))
    #                 elif perform[:-1] in SectionRepository.keys():
    #                     temp_file1.write('\n')
    #                     temp_file1.write('\n'.join(SectionRepository[perform[:-1]]))
    #
    #                     #temp_file1.close()
    #
    #
    #             else:
    #                 #with  open("FinalFile5" + str(i) + '.txt', "a") as temp_file1:
    #                     temp_file1.write('\n')
    #                     temp_file1.write(line)
    #
    #   temp_file1.close()
    # temp_file.close()
    #
    # modulelist = []
    # performlist = []
    #
    # section_regexx_data = ""
    # with open("FinalFile5" + str(i) + '.txt', "r") as temp_file:
    #     with  open("FinalFile6" + str(i) + '.txt', "a") as temp_file1:
    #         for line in temp_file.readlines():
    #             # print(line)
    #             # line=line[6:71]
    #             perform = []
    #             if line[0] == '*' or line.strip() == "":
    #                 continue
    #             else:
    #                 # line = line[0:65]
    #                 # perform=re.findall(r'^\s*PERFORM\s.*',line)
    #                 if line.strip().startswith('@'):
    #                     #  print("222",line)
    #                     pass
    #                 else:
    #                     perform = re.findall(r'^.*\s*PERFORM\s[A0-Z9].*', line, re.IGNORECASE)
    #                 if perform != []:
    #                     Temp_perform = perform[0]
    #                     # print(line,":::::::",perform)
    #                     l = Temp_perform.index("PERFORM ")
    #                     Temp_perform = Temp_perform[l:].split()
    #                     # Temp_perform=Temp_perform.split()
    #                     Temp_perform = Temp_perform[1]
    #                     # print(Temp_perform)
    #                     if Temp_perform.__contains__('.'):
    #                         Performparalist.append(Temp_perform)
    #                     else:
    #                         Temp_perform = Temp_perform.replace(',', '')
    #                         Temp_perform = Temp_perform.strip() + '.'
    #                         Performparalist.append(Temp_perform)
    #
    #                 module = re.findall(r'^[A0-Z9].*[-]*.*[.]', line)
    #                 modulelist.append(module)
    #
    #                 lenofmodulelist = len(modulelist)
    #                 if module != []:
    #                     currentmodule = modulelist[lenofmodulelist - 1]
    #                     currentmodulevalue = currentmodule[0]
    #                     # print(currentmodulevalue)
    #                     currentmodulevalue = re.sub('PERFORM', '', currentmodulevalue)
    #
    #                 if perform != []:
    #                     # print(perform)
    #                     performlist.append(perform)
    #                     performline = perform
    #                     perform = perform[0]
    #
    #                     l = perform.index("PERFORM ")
    #                     perform = perform[l:].split()
    #
    #                     # perform=perform.split()
    #                     perform = perform[1]
    #                     # perform=re.sub('.','',perform)
    #                     if perform == "UNTIL" or perform == "VARYING":
    #                         performlistlen = len(performlist) - 1
    #                         del performlist[performlistlen]
    #
    #                     if perform.__contains__('.'):
    #                         perform = '' + perform
    #                         # with  open("FinalFile5" + str(i) + '.txt', "a") as temp_file1:
    #                         if perform == "":
    #                             temp_file1.write('\n')
    #                         else:
    #                             # print(currentmodulevalue)
    #                             # performWrite='@'+perform +'  ^'+currentmodulevalue
    #                             performWrite = ' @' + performline[0] + '  ^' + currentmodulevalue
    #                             temp_file1.write('\n')
    #                             # print(performWrite)
    #                             temp_file1.write(performWrite)
    #                         # temp_file1.close()
    #
    #                     else:
    #
    #                         # with  open("FinalFile5" + str(i) + '.txt', "a") as temp_file1:
    #                         if perform == "^":
    #                             temp_file1.write('\n')
    #                         else:
    #
    #                             perform = '' + perform + '.'
    #                             temp_file1.write('\n')
    #                             performWrite = ' @' + performline[0] + '   ^' + currentmodulevalue
    #                             temp_file1.write(performWrite)
    #
    #                     if perform[:-1] in paraRepository.keys():
    #                         temp_file1.write('\n')
    #                         temp_file1.write('\n'.join(paraRepository[perform[:-1]]))
    #                     elif perform[:-1] in SectionRepository.keys():
    #                         temp_file1.write('\n')
    #                         temp_file1.write('\n'.join(SectionRepository[perform[:-1]]))
    #
    #                         # temp_file1.close()
    #
    #
    #                 else:
    #                     # with  open("FinalFile5" + str(i) + '.txt', "a") as temp_file1:
    #                     temp_file1.write('\n')
    #                     temp_file1.write(line)
    #
    #     temp_file1.close()
    # temp_file.close()
    #
    # modulelist = []
    # performlist = []
    #
    # section_regexx_data = ""
    # with open("FinalFile6" + str(i) + '.txt', "r") as temp_file:
    #     with  open("FinalFile7" + str(i) + '.txt', "a") as temp_file1:
    #         for line in temp_file.readlines():
    #             # print(line)
    #             # line=line[6:71]
    #             perform = []
    #             if line[0] == '*' or line.strip() == "":
    #                 continue
    #             else:
    #                 # line = line[0:65]
    #                 # perform=re.findall(r'^\s*PERFORM\s.*',line)
    #                 if line.strip().startswith('@'):
    #                     #  print("222",line)
    #                     pass
    #                 else:
    #                     perform = re.findall(r'^.*\s*PERFORM\s[A0-Z9].*', line, re.IGNORECASE)
    #                 if perform != []:
    #                     Temp_perform = perform[0]
    #                     # print(line,":::::::",perform)
    #                     l = Temp_perform.index("PERFORM ")
    #                     Temp_perform = Temp_perform[l:].split()
    #                     # Temp_perform=Temp_perform.split()
    #                     Temp_perform = Temp_perform[1]
    #                     # print(Temp_perform)
    #                     if Temp_perform.__contains__('.'):
    #                         Performparalist.append(Temp_perform)
    #                     else:
    #                         Temp_perform = Temp_perform.replace(',', '')
    #                         Temp_perform = Temp_perform.strip() + '.'
    #                         Performparalist.append(Temp_perform)
    #
    #                 module = re.findall(r'^[A0-Z9].*[-]*.*[.]', line)
    #                 modulelist.append(module)
    #
    #                 lenofmodulelist = len(modulelist)
    #                 if module != []:
    #                     currentmodule = modulelist[lenofmodulelist - 1]
    #                     currentmodulevalue = currentmodule[0]
    #                     # print(currentmodulevalue)
    #                     currentmodulevalue = re.sub('PERFORM', '', currentmodulevalue)
    #
    #                 if perform != []:
    #                     # print(perform)
    #                     performlist.append(perform)
    #                     performline = perform
    #                     perform = perform[0]
    #
    #                     l = perform.index("PERFORM ")
    #                     perform = perform[l:].split()
    #
    #                     # perform=perform.split()
    #                     perform = perform[1]
    #                     # perform=re.sub('.','',perform)
    #                     if perform == "UNTIL" or perform == "VARYING":
    #                         performlistlen = len(performlist) - 1
    #                         del performlist[performlistlen]
    #
    #                     if perform.__contains__('.'):
    #                         perform = '' + perform
    #                         # with  open("FinalFile5" + str(i) + '.txt', "a") as temp_file1:
    #                         if perform == "":
    #                             temp_file1.write('\n')
    #                         else:
    #                             # print(currentmodulevalue)
    #                             # performWrite='@'+perform +'  ^'+currentmodulevalue
    #                             performWrite = ' @' + performline[0] + '  ^' + currentmodulevalue
    #                             temp_file1.write('\n')
    #                             # print(performWrite)
    #                             temp_file1.write(performWrite)
    #                         # temp_file1.close()
    #
    #                     else:
    #
    #                         # with  open("FinalFile5" + str(i) + '.txt', "a") as temp_file1:
    #                         if perform == "^":
    #                             temp_file1.write('\n')
    #                         else:
    #
    #                             perform = '' + perform + '.'
    #                             temp_file1.write('\n')
    #                             performWrite = ' @' + performline[0] + '   ^' + currentmodulevalue
    #                             temp_file1.write(performWrite)
    #
    #                     #print(perform,paraRepository)
    #                     #print(SectionRepository)
    #                     if perform[:-1] in paraRepository.keys():
    #                         temp_file1.write('\n')
    #                         temp_file1.write('\n'.join(paraRepository[perform[:-1]]))
    #                     elif perform[:-1] in SectionRepository.keys():
    #                         temp_file1.write('\n')
    #                         temp_file1.write('\n'.join(SectionRepository[perform[:-1]]))
    #
    #                         # temp_file1.close()
    #
    #
    #                 else:
    #                     # with  open("FinalFile5" + str(i) + '.txt', "a") as temp_file1:
    #                     temp_file1.write('\n')
    #                     temp_file1.write(line)
    #
    #     temp_file1.close()
    # temp_file.close()
    #
    # modulelist = []
    # performlist = []
    #
    # section_regexx_data = ""
    # with open("FinalFile7" + str(i) + '.txt', "r") as temp_file:
    #     with  open("FinalFile8" + str(i) + '.txt', "a") as temp_file1:
    #         for line in temp_file.readlines():
    #             # print(line)
    #             # line=line[6:71]
    #             perform = []
    #             if line[0] == '*' or line.strip() == "":
    #                 continue
    #             else:
    #                 # line = line[0:65]
    #                 # perform=re.findall(r'^\s*PERFORM\s.*',line)
    #                 if line.strip().startswith('@'):
    #                     #  print("222",line)
    #                     pass
    #                 else:
    #                     perform = re.findall(r'^.*\s*PERFORM\s[A0-Z9].*', line, re.IGNORECASE)
    #                 if perform != []:
    #                     Temp_perform = perform[0]
    #                     # print(line,":::::::",perform)
    #                     l = Temp_perform.index("PERFORM ")
    #                     Temp_perform = Temp_perform[l:].split()
    #                     # Temp_perform=Temp_perform.split()
    #                     Temp_perform = Temp_perform[1]
    #                     # print(Temp_perform)
    #                     if Temp_perform.__contains__('.'):
    #                         Performparalist.append(Temp_perform)
    #                     else:
    #                         Temp_perform = Temp_perform.replace(',', '')
    #                         Temp_perform = Temp_perform.strip() + '.'
    #                         Performparalist.append(Temp_perform)
    #
    #                 module = re.findall(r'^[A0-Z9].*[-]*.*[.]', line)
    #                 modulelist.append(module)
    #
    #                 lenofmodulelist = len(modulelist)
    #                 if module != []:
    #                     currentmodule = modulelist[lenofmodulelist - 1]
    #                     currentmodulevalue = currentmodule[0]
    #                     # print(currentmodulevalue)
    #                     currentmodulevalue = re.sub('PERFORM', '', currentmodulevalue)
    #
    #                 if perform != []:
    #                     # print(perform)
    #                     performlist.append(perform)
    #                     performline = perform
    #                     perform = perform[0]
    #
    #                     l = perform.index("PERFORM ")
    #                     perform = perform[l:].split()
    #
    #                     # perform=perform.split()
    #                     perform = perform[1]
    #                     # perform=re.sub('.','',perform)
    #                     if perform == "UNTIL" or perform == "VARYING":
    #                         performlistlen = len(performlist) - 1
    #                         del performlist[performlistlen]
    #
    #                     if perform.__contains__('.'):
    #                         perform = '' + perform
    #                         # with  open("FinalFile5" + str(i) + '.txt', "a") as temp_file1:
    #                         if perform == "":
    #                             temp_file1.write('\n')
    #                         else:
    #                             # print(currentmodulevalue)
    #                             # performWrite='@'+perform +'  ^'+currentmodulevalue
    #                             performWrite = ' @' + performline[0] + '  ^' + currentmodulevalue
    #                             temp_file1.write('\n')
    #                             # print(performWrite)
    #                             temp_file1.write(performWrite)
    #                         # temp_file1.close()
    #
    #                     else:
    #
    #                         # with  open("FinalFile5" + str(i) + '.txt', "a") as temp_file1:
    #                         if perform == "^":
    #                             temp_file1.write('\n')
    #                         else:
    #
    #                             perform = '' + perform + '.'
    #                             temp_file1.write('\n')
    #                             performWrite = ' @' + performline[0] + '   ^' + currentmodulevalue
    #                             temp_file1.write(performWrite)
    #
    #                     if perform[:-1] in paraRepository.keys():
    #                         temp_file1.write('\n')
    #                         temp_file1.write('\n'.join(paraRepository[perform[:-1]]))
    #                     elif perform[:-1] in SectionRepository.keys():
    #                         temp_file1.write('\n')
    #                         temp_file1.write('\n'.join(SectionRepository[perform[:-1]]))
    #
    #                         # temp_file1.close()
    #
    #
    #                 else:
    #                     # with  open("FinalFile5" + str(i) + '.txt', "a") as temp_file1:
    #                     temp_file1.write('\n')
    #                     temp_file1.write(line)
    #
    #     temp_file1.close()
    # temp_file.close()
    #
    # modulelist = []
    # performlist = []
    #
    # section_regexx_data = ""
    # with open("FinalFile8" + str(i) + '.txt', "r") as temp_file:
    #     with  open("FinalFile9" + str(i) + '.txt', "a") as temp_file1:
    #         for line in temp_file.readlines():
    #             # print(line)
    #             # line=line[6:71]
    #             perform = []
    #             if line[0] == '*' or line.strip() == "":
    #                 continue
    #             else:
    #                 # line = line[0:65]
    #                 # perform=re.findall(r'^\s*PERFORM\s.*',line)
    #                 if line.strip().startswith('@'):
    #                     #  print("222",line)
    #                     pass
    #                 else:
    #                     perform = re.findall(r'^.*\s*PERFORM\s[A0-Z9].*', line, re.IGNORECASE)
    #                 if perform != []:
    #                     Temp_perform = perform[0]
    #                     # print(line,":::::::",perform)
    #                     l = Temp_perform.index("PERFORM ")
    #                     Temp_perform = Temp_perform[l:].split()
    #                     # Temp_perform=Temp_perform.split()
    #                     Temp_perform = Temp_perform[1]
    #                     # print(Temp_perform)
    #                     if Temp_perform.__contains__('.'):
    #                         Performparalist.append(Temp_perform)
    #                     else:
    #                         Temp_perform = Temp_perform.replace(',', '')
    #                         Temp_perform = Temp_perform.strip() + '.'
    #                         Performparalist.append(Temp_perform)
    #
    #                 module = re.findall(r'^[A0-Z9].*[-]*.*[.]', line)
    #                 modulelist.append(module)
    #
    #                 lenofmodulelist = len(modulelist)
    #                 if module != []:
    #                     currentmodule = modulelist[lenofmodulelist - 1]
    #                     currentmodulevalue = currentmodule[0]
    #                     # print(currentmodulevalue)
    #                     currentmodulevalue = re.sub('PERFORM', '', currentmodulevalue)
    #
    #                 if perform != []:
    #                     # print(perform)
    #                     performlist.append(perform)
    #                     performline = perform
    #                     perform = perform[0]
    #
    #                     l = perform.index("PERFORM ")
    #                     perform = perform[l:].split()
    #
    #                     # perform=perform.split()
    #                     perform = perform[1]
    #                     # perform=re.sub('.','',perform)
    #                     if perform == "UNTIL" or perform == "VARYING":
    #                         performlistlen = len(performlist) - 1
    #                         del performlist[performlistlen]
    #
    #                     if perform.__contains__('.'):
    #                         perform = '' + perform
    #                         # with  open("FinalFile5" + str(i) + '.txt', "a") as temp_file1:
    #                         if perform == "":
    #                             temp_file1.write('\n')
    #                         else:
    #                             # print(currentmodulevalue)
    #                             # performWrite='@'+perform +'  ^'+currentmodulevalue
    #                             performWrite = ' @' + performline[0] + '  ^' + currentmodulevalue
    #                             temp_file1.write('\n')
    #                             # print(performWrite)
    #                             temp_file1.write(performWrite)
    #                         # temp_file1.close()
    #
    #                     else:
    #
    #                         # with  open("FinalFile5" + str(i) + '.txt', "a") as temp_file1:
    #                         if perform == "^":
    #                             temp_file1.write('\n')
    #                         else:
    #
    #                             perform = '' + perform + '.'
    #                             temp_file1.write('\n')
    #                             performWrite = ' @' + performline[0] + '   ^' + currentmodulevalue
    #                             temp_file1.write(performWrite)
    #
    #                     if perform[:-1] in paraRepository.keys():
    #                         temp_file1.write('\n')
    #                         temp_file1.write('\n'.join(paraRepository[perform[:-1]]))
    #                     elif perform[:-1] in SectionRepository.keys():
    #                         temp_file1.write('\n')
    #                         temp_file1.write('\n'.join(SectionRepository[perform[:-1]]))
    #
    #                         # temp_file1.close()
    #
    #
    #                 else:
    #                     # with  open("FinalFile5" + str(i) + '.txt', "a") as temp_file1:
    #                     temp_file1.write('\n')
    #                     temp_file1.write(line)
    #
    #     temp_file1.close()
    # temp_file.close()
    # Break_point="To separate code"


    os.remove("Copy_Expanded_Data.txt")

    file_operation(i,METADATA,filename)
 Db_Insert(METADATA)


def Db_Insert(METADATA):

    UpdateCounter = 0
    UpdateCounter = UpdateCounter + 1
    db_data = {"data": METADATA,
               "headers": ['s_no', 'pgm_name', 'fragment_Id', 'para_name', 'source_statements', 'statement_group',
                           'rule_category', 'parent_rule_id', 'business_documentation']}

    try:
        keys = list(db_data.keys())
        print('parent keys', keys)

        if 'data' in keys:
            # fetching headers
            x_BRE_report_header_list = db_data['headers']
            print('COBOL Report header list', x_BRE_report_header_list)
            # Adding header field to db_data
            db_data['headers'] = x_BRE_report_header_list

            if len(db_data['data']) == 0:
                print({"status": "failure", "reason": "data field is empty"})
            else:
                # Delete all COBOl associated records in the table
                previousDeleted = False
                try:
                  if UpdateCounter == 1000000:
                    if db.bre_rules_report.delete_many(
                            {"type": {"$ne": "metadata"}}).acknowledged:
                        print('Deleted all the COBOL components from the x-reference report')
                        previousDeleted = True
                        print('--------just deleted all de cobols')
                    else:
                        print('Something went wrong')
                        print({"status": "failed",
                               "reason": "unable to delete from database. Please check in with your Administrator"})
                        print('--------did not deleted all de cobols')
                except Exception as e:
                    print({"status": "failed", "reason": str(e)})

                # Update the database with the content from HTTP request body

                if previousDeleted  or UpdateCounter ==1:

                    try:

                        db.bre_rules_report.insert_many(db_data['data'])
                        print('db inserteed bro')
                        # updating the timestamp based on which report is called
                        current_time = datetime.datetime.now(tz=tz).strftime("%A, %d. %B %Y %I:%M%p")
                        # Setting the time so that we know when each of the JCL and COBOLs were run

                        # db.cross_reference_report.insert_one({"type":"metadata", "JCL":{"last_updated_on":ct},"COBOL":{"last_updated_on":ct}})

                        if db.bre_rules_report.count_documents({"type": "metadata"}) > 0:
                            print('meta happen o naw',
                                  db.bre_rules_report.update_one({"type": "metadata"},
                                                                  {"$set": {
                                                                      "BRE.last_updated_on": current_time,
                                                                      "BRE.time_zone": time_zone,
                                                                      "headers": x_BRE_report_header_list
                                                                  }},
                                                                  upsert=True).acknowledged)
                        else:
                            db.bre_rules_report.insert_one(
                                {"type": "metadata",
                                 "COBOL": {"last_updated_on": current_time, "time_zone": time_zone},
                                 "headers": x_BRE_report_header_list})

                        print(current_time)
                        print({"status": "success", "reason": "Successfully inserted data and "})
                    except Exception as e:
                        print('Error' + str(e))
                        print({"status": "failed", "reason": str(e)})

    except Exception as e:
        print('Error: ' + str(e))
        print({"status": "failure", "reason": "Response json not in the required format"})




def file_operation(i,METADATA,filename):
    RC1 = 0
    RC2 = 0
    RC3 = 0
    RC4 = 0
    RC5 = 0
    RC6 = 0
    Old_Division_Name = ""
    main_list2 = []
    main_dict2 = {}
    main_list3 = []
    main_dict3 = {}
    temp_string = ''
    string1 = '^\s*'
    string2 = '\s.*'
    string3 = '\s.*'
    header = ['cond', 'tag','category','statement']
    wb = xlrd.open_workbook(ConditionPath)
    sheet = wb.sheet_by_index(0)
    row = sheet.nrows
    cols = sheet.ncols
    for index in range(row):
        temp_list = []
        temp_list1 = []
        value = sheet.cell_value(index, 0)
        TypeValue = sheet.cell_value(index, 1)
        category = sheet.cell_value(index, 2)
        state_group = sheet.cell_value(index, 3)
        if value == "YES" and TypeValue == "COBOL":
            for index1 in range(cols):
                value1 = sheet.cell_value(index, index1)
                temp_list1.append(value1)
                temp_list.append(value1)
            del temp_list[0]
            del temp_list[0]
            del temp_list1[0]
            del temp_list1[0]
            temp_string = temp_list[0]
            temp_string1 = temp_list1[0]
            temp_string = string1 + temp_string.strip() + string2
            temp_string1 = string1 + temp_string1.strip() + string3
            temp_list[0] = temp_string
            temp_list1[0] = temp_string1
            for a in range(len(header)):
                main_dict2[header[a]] = temp_list[a]
            temp_dict = copy.deepcopy(main_dict2)
            main_list2.append(temp_dict)
            for j in range(len(header)):
                main_dict3[header[j]] = temp_list1[j]
            temp_dict1 = copy.deepcopy(main_dict3)
            main_list3.append(temp_dict1)
    j = 0
    ProgramNumber = 0
    countvar = 0
    #worksheet1, workbook1 = ExcelWriting1()
    empty = "                                                                 "
    Key_Word_List = ["++INCLUDE","DISPLAY", "ACCEPT", "INITIALIZE", "EXIT", "IF", "EVALUATE", "ADD", "SUBTRACT", "DIVIDE",
                     "MULTIPLY", "COMPUTE", "MOVE", "INSPECT", "STRING", "UNSTRING", "SET", "SEARCH",
                     "END-IF", "OPEN", "CLOSE", "READ", "WRITE", "REWRITE", "DELETE", "START", "CALL", "PERFORM",
                     "GO", "STOP RUN", "GOBACK", "SORT", "MERGE", "EXEC", "ENTRY","CONTINUE","NEXT","ELSE","WHEN","@"]
    main_list2 = []
    bufferline=[]
    cicsbufferline=[]
    Onelinebuffer=[]
    ifcounter=0


    with open('FinalFile2'+ str(i)+'.txt', 'r+') as outfile:
     linenumber=0
     rule_number=0
     done=0
     perform_flag = False
     exec_flag=False
     Perform_paravalue=""
     cics_flag=False
     period_find_flag=False
     onelineflag=False
     Nested_Evaluate=False
     period_flag=False
     evalute_flag = False
     parent_rule_id_list = []
     firstparavalue=""
     endevaluregexx=""
     p_id_value=""
     p_rule_id=""
     when_counter=0
     evaluate_counter=0

     for line in outfile.readlines():
       # print("Check:",line)
       if_flag=False
       when_flag=False
       if line.__contains__('^'):
           None
       elif line.strip()=="":
           continue
       else:
           line = re.sub('\n', ' ', line)
           line = line + ' ^' + "PERFORM"
       templine=line.split('^')
       templine1=templine[0].strip()
       if templine1.strip()=="EJECT":
            continue
       else:
        if templine1!='':

          templine1 =' '.join(templine1.split())
        if templine1.__contains__("EXEC SQL") and templine1.__contains__('END-EXEC'):
            line=templine1 + '           ^' +templine[1]
        elif templine1.__contains__("EXEC SQL"):
            exec_flag = True
            templine1=templine1+' '+'<br>'
            bufferline.append(templine1)
            continue
        elif templine1.__contains__("END-EXEC") or templine1.__contains__("END-EXEC."):
          if exec_flag:
            exec_flag = False
            templine1 = templine1 + '           ^' +templine[1]
            bufferline.append(templine1)
            line = ""
            for data in range(len(bufferline)):
                line=line+bufferline[data]
        elif exec_flag:
            templine1 = templine1 +' '+'<br>'
            bufferline.append(templine1)
            continue
        bufferline = []

        # CICS code expansion.

        if templine1.__contains__("EXEC CICS") and templine1.__contains__('END-EXEC'):
            line=templine1 + '           ^' +templine[1]
        elif templine1.__contains__("EXEC CICS"):
            cics_flag = True
            templine1=templine1+' '+'<br>'
            cicsbufferline.append(templine1)
            continue
        elif templine1.__contains__("END-EXEC") or templine1.__contains__("END-EXEC."):
          if cics_flag:
            cics_flag = False
            templine1 = templine1 + '           ^' +templine[1]
            cicsbufferline.append(templine1)
            line = ""
            for data in range(len(cicsbufferline)):
                line=line+cicsbufferline[data]
        elif cics_flag:
            templine1 = templine1 +' '+'<br>'
            cicsbufferline.append(templine1)
            continue
        cicsbufferline = []
        if isComment(line):
            continue
        else:
         j = j + 1
         Current_Division_Name = Current_Division(line)
         if Current_Division_Name == None:
          if Old_Division_Name == "IDENTIFICATION DIVISION" or Old_Division_Name=="ID DIVISION":
            None
          elif Old_Division_Name == "ENVIRONMENT DIVISION":
           Envi_Division(line)
          elif Old_Division_Name == "DATA DIVISION":
           Data_Division(line)
          elif Old_Division_Name == "PROCEDURE":

                  linenumber = linenumber + 1
                  module = re.findall(r'^[A0-Z9].*[-]*.*[.]', line)

                  # CICS statement

                  beforesub=line.split()
                  if beforesub[0]=='@' and beforesub[1]=="PERFORM":
                      line = re.sub('@\s', ' ', line)
                  elif  (beforesub[0]=='@' and beforesub[1]=='IF') or  (beforesub[0]=='@' and beforesub[1]=='ELSE'):
                   
                    line=re.sub('@\s',' ',line)
                    print(line)
                  elif     beforesub[0]=='@' and (beforesub[1]!='IF' or beforesub[1]!='ELSE'):
                    
                      line = re.sub('@\s', 'PERFORM ', line)


                  loopNumber=0
                  for item in main_list3:
                   loopNumber=loopNumber+1
                   Reg_ex = item.get('cond')
                   line = re.sub(r"\s+", " ", line)
                   #CICSNSQL = re.match('.*EXEC\s*', Reg_ex)

                   programName = PGM_ID[i - 1]
                   #lengthofprogramName=len(programName)-1
                   lengthofprogramName = len(programName)
                   #if programName.__contains__('.'):
                   #    programName=re.sub('.','',programName)
                   programName=programName[0:lengthofprogramName]
                   Open_Rex = re.match(Reg_ex, line)
                   endifregexx = re.match('\s*END-IF.*', line)
                   endevaluregexx = re.match('.*\s*END-EVALUATE.*\s*', line)
                   if (Open_Rex != None ):
                     splitline = line.split('^')
                     line = splitline[0]
                     stripline=line.strip()
                     if len(splitline) == 1:
                        paravalue = ""
                     else:
                        paravalue = splitline[1]
                     paravalue=paravalue.strip()
                     rule_number=rule_number+1
                     lengthofprogramname=len(programName)
                     if programName.__contains__('.'):
                      rule_id=programName[0:lengthofprogramname-1]+'-'+str(rule_number)
                     else:
                      rule_id = programName+ '-' + str(rule_number)
                     tag_value = item.get('tag')
                     catg_value=item.get('category')
                     statement_value=item.get('statement')

                     # Parent rule id:

                     ifregexx=re.match('^\s*[^\S]IF\s.*',line)
                     endifregexx=re.match('\s*END-IF.*',line,re.IGNORECASE)
                     periodregexx=re.match('.*[....]{4}.*',line)
                     evaluateregexx=re.match('.*\sEVALUATE\s.*',line)
                     whenregexx=re.match('.*\sWHEN\s.*',line)
                     elif_regexx=re.match('^\s*ELSE\s*IF\s.*',line)


                     # IF statemensts.
                     if evalute_flag:
                         evaluateregexx1 = re.match('.*\sEVALUATE\s.*', line)
                         if evaluateregexx1!=None:
                             Nested_Evaluate=True


                     if elif_regexx!=None:
                        
                         p_id_list_len2 = len(parent_rule_id_list)
                         if parent_rule_id_list != []:
                             del parent_rule_id_list[p_id_list_len2 - 1]
                         parent_rule_id_list.append(rule_id)
                    

                     if ifregexx!=None:
                         if ifcounter==0:
                          firstparavalue=paravalue
                          ifcounter = ifcounter + 1
                          p_rule_id = rule_id
                          parent_rule_id_list.append(rule_id)
                          period_flag=True
                          if_flag=True
                         else:
                          ifcounter = ifcounter + 1
                          parent_rule_id_list.append(rule_id)
                     if periodregexx!=None and period_flag:
                          firstparavalue = firstparavalue.strip()
                          paravalue = paravalue.strip()
                          if firstparavalue == paravalue :
                              if line.__contains__("PERFORM "):
                                  perform_flag = True
                                  Perform_paravalue=paravalue
                              if ifcounter==1:
                                 p_rule_id = ""
                                 period_find_flag=False
                                 ifcounter = 0
                                 period_flag = False
                                 if_flag=True
                              elif perform_flag !=True:
                                  ifcounter=ifcounter-1
                                  p_id_list_len2 = len(parent_rule_id_list)
                                  if parent_rule_id_list != []:
                                     del parent_rule_id_list[p_id_list_len2 - 1]

                     # Evaluate Statements.



                     if evaluateregexx != None:
                         evaluate_counter = evaluate_counter + 1
                         evalute_flag = True

                     if evalute_flag :

                         if whenregexx!=None:
                             if ifcounter>0 or when_counter >0:
                                 if ifcounter == 0 and when_counter > 0:
                                     if Nested_Evaluate!=True:

                                        p_id_list_len2 = len(parent_rule_id_list)
                                        if  parent_rule_id_list != []:
                                             del parent_rule_id_list[p_id_list_len2 - 1]
                                 None
                             else:
                                try:
                                 p_id_list_len = len(parent_rule_id_list)
                                 del parent_rule_id_list[p_id_list_len - 1]
                                except:
                                    None
                             if Nested_Evaluate:
                                None
                             else:
                                 if when_counter>0 and ifcounter > 0 :

                                     p_id_list_len = len(parent_rule_id_list)
                                     del parent_rule_id_list[p_id_list_len - 1]
                             Nested_Evaluate=False

                             when_counter=when_counter+1
                             p_rule_id=rule_id
                             parent_rule_id_list.append(rule_id)
                             #del parent_rule_id_list[0]
                             when_flag=True


                     if (tag_value == "RC1"):
                         p_id_value=""
                         loopNumber = 0
                         paravaluesplit=paravalue.split()
                         if len(paravaluesplit) >= 2:
                          if paravaluesplit[0] == "PROCEDURE" and paravaluesplit[1] == "DIVISION." or paravaluesplit[1] == "DIVISION":
                             paravalue = ""
                         if paravalue.__contains__("PERFORM"):
                             paravalue=re.sub("PERFORM" , " ",paravalue )
                         line1 = re.sub('<br>', '\n', line)
                         # worksheet1.write(linenumber, 1,line1)
                         # worksheet1.write(linenumber, 0,rule_id)
                         # worksheet1.write(linenumber, 2, paravalue)
                         # worksheet1.write(linenumber,4,catg_value)
                         # worksheet1.write(linenumber, 3, statement_value)

                         for data in range(len(parent_rule_id_list)):
                             if p_id_value == "":

                                 p_id_value = p_id_value + parent_rule_id_list[data]
                             else:
                                 p_id_value = p_id_value + ',' + parent_rule_id_list[data]

                         METADATA.append({'s_no':'', 'pgm_name':programName,
                                           'fragment_Id':rule_id,
                                          'para_name':paravalue.replace('&S',' S'),'source_statements':line,'statement_group':statement_value,'rule_category':catg_value,
                                          'parent_rule_id':p_id_value,'business_documentation':'',"application":""})
                         if period_find_flag:
                             p_id_list_len2 = len(parent_rule_id_list)
                             if parent_rule_id_list != []:
                                 del parent_rule_id_list[p_id_list_len2 - 1]
                             period_find_flag=False

                         RC1 = RC1 + 1
                         continue
                     elif (tag_value == "RC2"):
                         p_id_value=""
                         loopNumber = 0
                         paravaluesplit = paravalue.split()
                         if len(paravaluesplit) >= 2:
                             if paravaluesplit[0] == "PROCEDURE" and paravaluesplit[1] == "DIVISION." or paravaluesplit[
                                 1] == "DIVISION":
                                 paravalue = ""
                         if paravalue.__contains__("PERFORM"):
                                 paravalue = re.sub("PERFORM", " ", paravalue)
                         #period_flag = Code_Extraction(line, i)
                         line1 = re.sub('<br>', '\n', line)
                         # worksheet1.write(linenumber, 1, line1)
                         # worksheet1.write(linenumber, 2, paravalue)
                         # worksheet1.write(linenumber, 0,rule_id)
                         # worksheet1.write(linenumber, 4, catg_value)

                         for data in range(len(parent_rule_id_list)):
                             if p_id_value == "":

                                 p_id_value = p_id_value + parent_rule_id_list[data]
                             else:
                                 p_id_value = p_id_value + ',' + parent_rule_id_list[data]

                         METADATA.append({'s_no': '', 'pgm_name': programName,
                                          'fragment_Id': rule_id,
                                          'para_name': paravalue.replace('&S',' S'), 'source_statements': line, 'statement_group': statement_value,
                                          'rule_category': catg_value,
                                          'parent_rule_id': p_id_value, 'business_documentation': '',"application":""})
                         #print('22', line)
                         RC2 = RC2 + 1
                         if period_find_flag:
                             p_id_list_len2 = len(parent_rule_id_list)
                             if parent_rule_id_list != []:
                                 del parent_rule_id_list[p_id_list_len2 - 1]
                             period_find_flag=False
                         continue
                     elif (tag_value == "RC3"):

                         p_id_value=""
                         loopNumber = 0
                         paravaluesplit = paravalue.split()
                         if len(paravaluesplit) >= 2:
                             if paravaluesplit[0] == "PROCEDURE" and paravaluesplit[1] == "DIVISION." or paravaluesplit[
                                 1] == "DIVISION":
                                 paravalue = ""
                         if paravalue.__contains__("PERFORM"):
                             paravalue = re.sub("PERFORM", " ", paravalue)
                         line1 = re.sub('<br>', '\n', line)
                         # worksheet1.write(linenumber, 1, line1)
                         # worksheet1.write(linenumber, 2, paravalue)
                         # worksheet1.write(linenumber, 0, rule_id)
                         # worksheet1.write(linenumber, 4, catg_value)
                         # worksheet1.write(linenumber, 3, statement_value)
                         if if_flag and when_counter  == 0 or (when_flag and ifcounter == 0 and evaluate_counter==1):
                             for data in range(len(parent_rule_id_list)):
                                 if p_id_value == "":
                                     p_id_value = p_id_value + parent_rule_id_list[data]
                                 else:
                                     p_id_value = p_id_value + ',' + parent_rule_id_list[data]

                             METADATA.append({'s_no': '', 'pgm_name': programName,
                                          'fragment_Id': rule_id,
                                          'para_name': paravalue.replace('&S',' S'), 'source_statements': line, 'statement_group': statement_value,
                                          'rule_category': catg_value,
                                          'parent_rule_id': p_id_value, 'business_documentation': '',"application":""})
                             p_id_value = ""
                         else:

                             if ifcounter>0 and when_counter>0:
                                 for data in range(len(parent_rule_id_list)):
                                     if p_id_value == "":
                                         p_id_value = p_id_value + parent_rule_id_list[data]
                                     else:
                                         p_id_value = p_id_value + ',' + parent_rule_id_list[data]
                                 METADATA.append({'s_no': '', 'pgm_name': programName,
                                                  'fragment_Id': rule_id,
                                                  'para_name': paravalue.replace('&S',' S'), 'source_statements': line,
                                                  'statement_group': statement_value,
                                                  'rule_category': catg_value,
                                                  'parent_rule_id': p_id_value, 'business_documentation': '',"application":""})
                                 p_id_value=""

                             else:
                              if len(parent_rule_id_list) >0 and evaluateregexx==None:

                               for data in range(len(parent_rule_id_list)):
                                 if p_id_value=="":

                                    p_id_value=p_id_value+parent_rule_id_list[data]
                                 else:
                                    p_id_value = p_id_value + ','+parent_rule_id_list[data]

                              else:
                                  for data in range(len(parent_rule_id_list)):
                                      if p_id_value == "":

                                          p_id_value = p_id_value + parent_rule_id_list[data]
                                      else:
                                          p_id_value = p_id_value + ',' + parent_rule_id_list[data]



                              METADATA.append({'s_no': '', 'pgm_name': programName,
                                              'fragment_Id': rule_id,
                                              'para_name': paravalue.replace('&S',' S'), 'source_statements': line,
                                              'statement_group': statement_value,
                                              'rule_category': catg_value,
                                              'parent_rule_id': p_id_value, 'business_documentation': '',"application":""})
                              p_id_value = ""

                              if period_find_flag:
                                  p_id_list_len2 = len(parent_rule_id_list)
                                  if parent_rule_id_list != []:
                                      del parent_rule_id_list[p_id_list_len2 - 1]
                                  period_find_flag = False

                         RC3 = RC3 + 1
                         continue
                     elif (tag_value == "RC4"):
                         p_id_value=""
                         loopNumber = 0
                         paravaluesplit = paravalue.split()
                         if len(paravaluesplit) >= 2:
                             if paravaluesplit[0] == "PROCEDURE" and paravaluesplit[1] == "DIVISION." or paravaluesplit[
                                 1] == "DIVISION":
                                 paravalue = ""

                         if paravalue.__contains__("PERFORM"):
                             paravalue = re.sub("PERFORM", " ", paravalue)
                         #period_flag = Code_Extraction(line, i)
                         #print("line",line)
                         line1 = re.sub('<br>', '\n', line)
                         # worksheet1.write(linenumber, 1, line1)
                         # worksheet1.write(linenumber, 2, paravalue)
                         # worksheet1.write(linenumber, 0, rule_id)
                         # worksheet1.write(linenumber, 4, catg_value)
                         # worksheet1.write(linenumber, 3, statement_value)

                         for data in range(len(parent_rule_id_list)):

                             if p_id_value == "":

                                 p_id_value = p_id_value + parent_rule_id_list[data]
                             else:
                                 p_id_value = p_id_value + ',' + parent_rule_id_list[data]

                         METADATA.append({'s_no': '', 'pgm_name': programName,
                                          'fragment_Id': rule_id,
                                          'para_name': paravalue.replace('&S',' S'), 'source_statements': line, 'statement_group': statement_value,
                                          'rule_category': catg_value,
                                          'parent_rule_id': p_id_value, 'business_documentation': '',"application":""})
                         #print('44', line)
                         RC4 = RC4 + 1
                         if period_find_flag:
                             p_id_list_len2 = len(parent_rule_id_list)
                             if parent_rule_id_list != []:
                                 del parent_rule_id_list[p_id_list_len2 - 1]
                             period_find_flag=False
                         continue
                     elif (tag_value == "RC5"):
                         p_id_value=""
                         loopNumber = 0
                         paravaluesplit = paravalue.split()
                         if len(paravaluesplit) >= 2:
                             if paravaluesplit[0] == "PROCEDURE" and paravaluesplit[1] == "DIVISION." or paravaluesplit[
                                 1] == "DIVISION":
                                 paravalue = ""
                         if paravalue.__contains__("PERFORM"):
                                 paravalue = re.sub("PERFORM", " ", paravalue)
                         line1=re.sub('<br>','\n',line)
                         # worksheet1.write(linenumber, 1, line1)
                         # worksheet1.write(linenumber, 2, paravalue)
                         # worksheet1.write(linenumber, 0, rule_id)
                         # worksheet1.write(linenumber, 4, catg_value)
                         # worksheet1.write(linenumber, 3, statement_value)

                         for data in range(len(parent_rule_id_list)):
                             if p_id_value == "":

                                 p_id_value = p_id_value + parent_rule_id_list[data]
                             else:
                                 p_id_value = p_id_value + ',' + parent_rule_id_list[data]

                         METADATA.append({'s_no': '', 'pgm_name': programName,
                                          'fragment_Id': rule_id,
                                          'para_name': paravalue.replace('&S',' S'), 'source_statements': line, 'statement_group': statement_value,
                                          'rule_category': catg_value,
                                          'parent_rule_id': p_id_value, 'business_documentation': '',"application":""})
                         #print('55',line)
                         RC5 = RC5 + 1
                         if period_find_flag:
                             p_id_list_len2 = len(parent_rule_id_list)
                             if parent_rule_id_list != []:
                                 del parent_rule_id_list[p_id_list_len2 - 1]
                             period_find_flag=False
                         continue
                     elif (tag_value == "RC6"):
                         p_id_value=""
                         #print(line)
                         loopNumber = 0
                         paravaluesplit = paravalue.split()
                         if len(paravaluesplit)>=2:
                          if paravaluesplit[0] == "PROCEDURE" and paravaluesplit[1] == "DIVISION." or paravaluesplit[1] == "DIVISION":
                             paravalue = ""
                         if paravalue.__contains__("PERFORM"):
                                 paravalue = re.sub("PERFORM", " ", paravalue)
                                 paravalue=paravalue.split()
                                 paravalue=paravalue[0]
                         #period_flag = Code_Extraction(line, i)
                         line1 = re.sub('<br>', '\n', line)
                         #print(line)
                         # worksheet1.write(linenumber,1, line1)
                         # worksheet1.write(linenumber, 2, paravalue)
                         # worksheet1.write(linenumber,0, rule_id)
                         # worksheet1.write(linenumber, 4, catg_value)
                         # worksheet1.write(linenumber, 3, statement_value)

                         for data in range(len(parent_rule_id_list)):
                             if p_id_value == "":

                                 p_id_value = p_id_value + parent_rule_id_list[data]
                             else:
                                 p_id_value = p_id_value + ',' + parent_rule_id_list[data]

                         METADATA.append({'s_no': '', 'pgm_name': programName,
                                          'fragment_Id': rule_id,
                                          'para_name': paravalue.replace('&S',' S'), 'source_statements': line, 'statement_group': statement_value,
                                          'rule_category': catg_value,
                                          'parent_rule_id': p_id_value, 'business_documentation': '',"application":""})
                         #print('66',line)
                         RC6 = RC6 + 1
                         if period_find_flag:
                             p_id_list_len2 = len(parent_rule_id_list)
                             if parent_rule_id_list != []:
                                 del parent_rule_id_list[p_id_list_len2 - 1]
                             period_find_flag=False
                         continue
                   elif(loopNumber==69):

                       splitline = line.split('^')
                       line = splitline[0]
                       Other_Action="Other Action"

                       statement_g=""
                       rule_catg=""
                       if line.__contains__("END-IF"):
                           statement_g = "Technical Action"
                           rule_catg = "No Operation"

                       if len(splitline) == 1:
                           paravalue = ""
                       else:
                           paravalue = splitline[1]

                           # parent ID
                           """
                           if endifregexx != None:
                               firstparavalue=firstparavalue.strip()
                               paravalue=paravalue.strip()

                               if firstparavalue == paravalue:
                                   if ifcounter == 1:
                                       p_rule_id = ""
                                       p_id_value = ""
                                       if when_counter>0:
                                           p_id_value = ""
                                           p_id_list_len = len(parent_rule_id_list)
                                           del parent_rule_id_list[p_id_list_len - 1]

                                       else:
                                          parent_rule_id_list=[]
                                       ifcounter = 0
                                       period_flag = False
                                   else:
                                       #if when_counter > 0:
                                           p_id_value = ""
                                           p_id_list_len = len(parent_rule_id_list)
                                           if parent_rule_id_list!=[]:
                                              del parent_rule_id_list[p_id_list_len - 1]
                                           ifcounter = ifcounter - 1

                               else:
                                   p_id_value = ""
                                   p_id_list_len = len(parent_rule_id_list)
                                   if parent_rule_id_list != []:
                                      del parent_rule_id_list[p_id_list_len - 1]
                                   ifcounter = ifcounter - 1

                           """

                           if endevaluregexx!=None :
                                evaluate_counter = evaluate_counter - 1
                                if evaluate_counter == 0:
                                    when_counter = 0
                                    evalute_flag = False
                                if ifcounter>0 or evaluate_counter>0:
                                    p_id_value=""
                                    p_id_list_len = len(parent_rule_id_list)
                                    if parent_rule_id_list != []:
                                      del parent_rule_id_list[p_id_list_len - 1]

                                else:
                                  p_id_value=""
                                  parent_rule_id_list = []


                       paravalue = paravalue.strip()
                       if paravalue == "PROCEDURE DIVISION." or paravalue ==".":
                           paravalue= ""
                       if paravalue.__contains__("PERFORM"):
                           paravalue = re.sub("PERFORM", " ", paravalue)
                       paravalue = paravalue.strip()
                       line1 = re.sub('<br>', '\n', line)


                       # worksheet1.write(linenumber, 1, line1)
                       # worksheet1.write(linenumber,4,Other_Action)


                       for data in range(len(parent_rule_id_list)):
                           if p_id_value == "":
                               p_id_value = p_id_value + parent_rule_id_list[data]
                           else:
                               p_id_value = p_id_value + ',' + parent_rule_id_list[data]

                       if line.__contains__("END-PERFORM") or line.__contains__("COPY ") or line.__contains__(
                               "END-RETURN") or line.__contains__("END-COMPUTE"):
                             p_id_value = ""
                             p_id_value_set = set(parent_rule_id_list)
                             SortedSet(p_id_value_set)
                             p_id_value_set = list(p_id_value_set)
                             p_id_value_set.sort()


                             for data in range(len(p_id_value_set)):
                                 if p_id_value == "":
                                     p_id_value = p_id_value + p_id_value_set[data]
                                 else:
                                     p_id_value = p_id_value + ',' + p_id_value_set[data]

                             METADATA.append({'s_no': '', 'pgm_name': programName,
                                        'fragment_Id': '',
                                        'para_name': paravalue, 'source_statements': line, 'statement_group': '',
                                        'rule_category': '',
                                        'parent_rule_id': p_id_value, 'business_documentation': '',"application":""})

                             if line.__contains__("STOP "):
                                 None
                             else:
                                 if period_find_flag:
                                     p_id_list_len2 = len(parent_rule_id_list)
                                     if parent_rule_id_list != []:
                                         del parent_rule_id_list[p_id_list_len2 - 1]
                                     period_find_flag = False
                       else:
                           p_id_value = ""
                           #print(parent_rule_id_list)
                           # p_id_value_set = set(parent_rule_id_list)
                           # SortedSet(p_id_value_set)
                           # p_id_value_set = list(p_id_value_set)
                           # #print(p_id_value_set)
                           # p_id_value_set.sort()

                           #print(p_id_value_set )
                           for data in range(len(parent_rule_id_list)):
                               if p_id_value == "":
                                   p_id_value = p_id_value + parent_rule_id_list[data]
                               else:
                                   p_id_value = p_id_value + ',' + parent_rule_id_list[data]



                           METADATA.append({'s_no': '', 'pgm_name': programName,
                                            'fragment_Id': '',
                                            'para_name': paravalue.replace('&S',' S'), 'source_statements': line.replace('&S',' S'), 'statement_group': rule_catg,
                                            'rule_category': statement_g,
                                            'parent_rule_id': p_id_value, 'business_documentation': '',"application":""})
                           if line.__contains__("STOP "):
                               None
                           else:
                               if period_find_flag:
                                   p_id_list_len2 = len(parent_rule_id_list)
                                   if parent_rule_id_list != []:
                                       del parent_rule_id_list[p_id_list_len2 - 1]
                                   period_find_flag = False


                           if endifregexx != None:
                               firstparavalue = firstparavalue.strip()
                               paravalue = paravalue.strip()

                               if firstparavalue == paravalue:
                                   if ifcounter == 1:
                                       p_rule_id = ""
                                       p_id_value = ""
                                       if when_counter > 0:
                                           p_id_value = ""
                                           p_id_list_len = len(parent_rule_id_list)
                                           del parent_rule_id_list[p_id_list_len - 1]

                                       else:
                                           if len(parent_rule_id_list)>0:
                                               p_id_value = ""
                                               p_id_list_len = len(parent_rule_id_list)
                                               del parent_rule_id_list[p_id_list_len - 1]
                                           #print(parent_rule_id_list)
                                           #parent_rule_id_list = []
                                       ifcounter = 0
                                       period_flag = False
                                   else:
                                       # if when_counter > 0:
                                       p_id_value = ""
                                       p_id_list_len = len(parent_rule_id_list)
                                       if parent_rule_id_list != []:
                                           del parent_rule_id_list[p_id_list_len - 1]
                                       ifcounter = ifcounter - 1

                               else:
                                   p_id_value = ""
                                   p_id_list_len = len(parent_rule_id_list)
                                   if parent_rule_id_list != []:
                                       del parent_rule_id_list[p_id_list_len - 1]
                                   ifcounter = ifcounter - 1


         else:

           Old_Division_Name = Current_Division_Name

     #workbook1.close()

  # Removing the temp files.

    #os.remove("output" + str(i) + '.txt')
    os.remove("Duplicatefile"+str(i)+'.txt')
    os.remove("Duplicatefile0" + str(i) + '.txt')
    times=3
    for num  in range(times):
       os.remove("FinalFile"+str(num) + str(i) + '.txt')


    print(RC1)
    print(RC2)
    print(RC3)
    print(RC4)
    print(RC5)
    print(RC6)

def Code_Extraction(line,i):
    if line.__contains__("."):
        with open("textfile" + str(i) + '.txt', "a") as temp_file:
            # temp_file.write(string_bucket)
            temp_file.write('\n')
            line = ' '.join(line.split())
            temp_file.write(line)
            temp_file.write('\n')
    else:
        with open("textfile" + str(i) + '.txt', "a") as temp_file:
            temp_file.write('\n')
            line = ' '.join(line.split())
            temp_file.write(line)

        period_flag = True
        return period_flag




def Current_Division(line):

    
    if line[0:22]=="IDENTIFICATION DIVISION" or line[0:3]=="ID":

        Current_Division_Name="IDENTIFICATION DIVISION"
        return Current_Division_Name
    elif line[0:21]=="ENVIRONMENT DIVISION":

        Current_Division_Name="ENVIRONMENT DIVISION"
        return Current_Division_Name
    elif line[0:14]=="DATA DIVISION":
        Current_Division_Name="DATA DIVISION"
        return Current_Division_Name
    elif line[0:9]=="PROCEDURE":
       
        Current_Division_Name="PROCEDURE"
        return Current_Division_Name
    else:
        Current_Division_Name=None
        return Current_Division_Name
def Id_Division(filename):
    #if line=="PROCEDURE DIVISION.":
        filename=filename.split('\\')
        filelength=len(filename)
        Temp_ID=filename[filelength-1]
        print(Temp_ID[:-3])
        PGM_ID.append(Temp_ID[:-3])
def Id_Division1(line):
    if line[0:11]=="PROGRAM-ID":
        Temp_ID=line[11:65]
        TempID=Temp_ID.strip()
        #PGM_ID.append(TempID)
def Envi_Division(line):
    return None
def Data_Division(line):
    return None


def IsDivision(line1):
 #Temp_Line = line1.split()
 Temp_Line = line1

 if Temp_Line[7:21] == "IDENTIFICATION" or Temp_Line[7:9] == "ID":

     Index = line1.index(Temp_Line[7:21])
     Index = Index - 1
     return Index
 else:
     return False


def Cut_Line(line, b):
 line = line[b:]
 return line


def isComment(line):
 if line[0] == '*':
  return True
 else:
  return False



def ExcelWriting1():
    #print("second excel")
    workbook1 = xlsxwriter.Workbook('BRE.xlsx')
    #print(workbook1)
    worksheet1 = workbook1.add_worksheet("'SHEET1")
    Format=workbook1.add_format({'bold': True,'bg_color':'yellow','border_color':'black'})
    worksheet1.write('A1','Fragment_Id',Format)
    worksheet1.write('B1','Rule',Format)
    worksheet1.write('E1','Rule Category',Format)
    worksheet1.write('C1','Para Name',Format)
    worksheet1.write('D1', 'Statement Group', Format)


    return worksheet1,workbook1


main()

