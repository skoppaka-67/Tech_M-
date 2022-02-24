import xlrd,os,copy,re,glob,xlsxwriter,openpyxl
from pymongo import MongoClient
import time,datetime ,pytz
import timeit
import config,sys
import json
import pymongo
from collections import OrderedDict
from SortedSet.sorted_set import SortedSet
import datetime
PGM_ID=[]
Current_Division_Name=""
time_zone = 'Asia/Calcutta'
tz = pytz.timezone(time_zone)

client = MongoClient(config.database['hostname'], config.database['port'])
db = client[config.database['database_name']]


f = open(r'D:\bnsf\NAT_POC\NAT\one_clickerrors.txt', 'a')
f.seek(0)
# f.truncate()

cobol_folder_name = config.codebase_information['NAT']['folder_name']
cobol_extension_type = config.codebase_information['NAT']['extension']
COPYBOOK = config.codebase_information['COPYBOOK']['folder_name']
code_location =config.codebase_information['code_location']
ConditionPath=config.codebase_information['condition_path']
CobolPath=code_location+'\\'+cobol_folder_name

version="After perform expansion Version - (24-2-2020)"
version="Optimised Code - 16/6/2020"
version="Ran for BNSF latest 28/06/201"

def main():

 if os.path.exists("loop_file.txt"):
     os.remove("loop_file.txt")
 main_list=[]
 main_dict={}
 METADATA=[]
 #Key_Word_List=["++INCLUDE","DISPLAY","ACCEPT","INITIALIZE","EXIT.","IF","EVALUATE","INITIATE","ADD","SUBTRACT","DIVIDE","MULTIPLY","COMPUTE","MOVE","INSPECT","STRING","UNSTRING","SET","SEARCH",
 #                "CONTINUE","END-IF.","END-IF","OPEN","END-RETURN","END-COMPUTE","TERMINATE","END-RETURN.","END-COMPUTE.","CLOSE","NEXT","END-EVALUATE.","END-EVALUATE","WHEN","READ","WRITE","END-IF.","END-PERFORM.","END-PERFORM","REWRITE","DELETE","START","CALL","PERFORM","GO","STOP","GOBACK.","SORT","MERGE","EXEC","ENTRY","ELSE"]
 main_list1 = []
 main_dict1 = {}
 Key_Word_List =["SELECT","FIND","CALLNAT","END-REPEAT","RELEASE","INPUT","ESCAPE","END-IF","END-DECIDE","END-ERROR","ACCEPT","STORE","ANY","END-FOR","NONE","INCLUDE","VALUE","BACKOUT","END-REPEAT","WHEN","END-DECIDE","END-WORK","END-NOREC","END-IF","END-SUBROUTINE","END-FIND","USER-ID","TERMINAL-ID","DATE","TIME","MODEL-PCT","STACK","RESET","REDEFINE","UPDATE","INSERT","+TIME","+DATE","DELETE","MOVE","SET","READ","END-READ" ,"REPEAT","FOR","LOOP","OBTAIN","INPUT","ESCAPE", "IF","DO","DOEND","FETCH","CALL","COMPRESS","REINPUT","ASSIGN","ADD","ELSE","DO","DOEND","PERFORM", "EXAMINE","END TRANSACTION","RETURN" ,"DEFINE","FIND" ,"LOOP","END"  ,"COMPUTE","DECIDE","WRITE" ]
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
     ##print(TypeValue)
     if value=="YES" and TypeValue=="COBOL":
       for index1 in range(cols):
          value1=sheet.cell_value(index,index1)
          temp_list1.append(value1)
          temp_list.append(value1)
          ##print(temp_list[1])
       del temp_list[0]
       del temp_list[0]
       del temp_list1[0]
       del temp_list1[0]
       temp_string=temp_list[0]
       ##print(temp_string)
       temp_string1=temp_list1[0]
       temp_string=string1+temp_string.strip()+string2
       temp_string1=string1+temp_string1.strip()+string3
       temp_list[0]=temp_string
       temp_list1[0]=temp_string1
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
 modulelist=[]
 performlist=[]
 CopyPath=code_location+'\\'+COPYBOOK
 counter1=0
 #DB delete.

 # if db.bre_rules_report.delete_many(
 #         {"type": {"$ne": "metadata"}}).acknowledged:
 #    #print("DB delete")

 wb1 = xlrd.open_workbook(r"D:\bnsf\NAT_POC\NAT\one_click\Book2.xlsx")
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

 try:
     for filename in glob.glob(os.path.join(CobolPath,'*.nat')):
        #i = i + 1
        filename1 = filename.split('\\')
        len_file = len(filename1)
        filename1 = filename1[len_file - 1][:-4]
        # if not filename1 == "WBMPS417":
        #    continue
        print(filename)
        if counter1==1:
            counter1=0
            ##print("Metabta",METADATA)
            Db_Insert( METADATA)
            METADATA = []
        counter1 = counter1 + 1
        Performparalist = []
        Id_Division(filename)
        i=i+1
        Program_Name = open(filename)
        flag=False
        onelinebuffer=[]
        onelineflag=False
        module = []
        Copy_file = ["appl-specific-batch-proc.", "appl-specific-online-proc.", "appl-specific-ttm-proc."]

        for line in Program_Name.readlines():

              line = line[6:]
              if line.__contains__("/*") and not line.strip().startswith("*"):
                    line = line.split("/*")[0] + "\n"

              if line.strip()=='' or  line[0]=='*' or line.startswith('/*') or line.lstrip().startswith('/') :
                  continue
              else:
                  with open("Copy_Expanded_Data" + '.txt', "a+") as copy_file:

                      copy_regexx = re.findall(r'\s*COPY\s.*', line)

                      include = re.findall(r'^\s*INCLUDE.*', line)
                      if copy_regexx != [] or include!=[]:

                          if copy_regexx!=[]:
                             copyname = copy_regexx[0]
                             copyname = copyname.split()
                             copyname = re.sub('"', '', copyname[1])
                          elif include!=[]:
                              copyname = include[0]
                              copyname = copyname.split()
                              copyname = re.sub('"', '', copyname[1])
                          if copyname in Copy_file:
                              copy_file.write(line)
                              continue
                          else:

                              copyname = copyname +'.' +'cpy'
                              Copyfilepath = CopyPath + '\\' + copyname
                              if os.path.isfile(Copyfilepath):
                                  Temp_File2 = open(os.path.join(CopyPath, copyname), "r")
                                  copy_file.write("#########" + " " + "BEGIN" + " " + line.strip() + '\n')

                                  for copylines in Temp_File2.readlines():
                                      copylines = re.sub('\t', '     ', copylines)
                                      copy_file.write(copylines[8:])
                                      ##print(copylines)
                                      copy_file.write('\n')
                                  copy_file.write("#####" + " " + "COPY END" + "####" + '\n')
                              else:
                                  copy_file.write(line)

                      else:
                          ##print(line)
                          copy_file.write(line)
                          copy_file.write('\n')
                  copy_file.close()

        define_flag=False
        key_flag=False




        start_list=['SET','MOVE']
        end_define=[]
        with open("Copy_Expanded_Data" + '.txt', "r+") as expanded_file:
            for line in expanded_file.readlines():
                ##print(line)
                if line.strip()=='' or  line[0]=='*' or line.startswith('/*'):
                    continue
                else:
                 with open("Duplicatefile0" + str(i) + '.txt', "a") as temp_file1:
                     define_regexx= re.findall(r'^\s*DEFINE\s*DATA\s*', line)
                     if end_define!=[] and key_flag == False:
                         define_flag=True
                     if define_flag :
                         temp_file1.write(line)
                     if not define_flag:
                         if line.split()[0] in  start_list:
                            key_flag=True
                     if key_flag:
                            temp_file1.write(line)
                     end_define = re.findall(r'^\s*END-DEFINE\s*', line)
            temp_file1.close()

        # Create dict with para name.

        dict = read_lines(i)
        # Making the multi line to single statements.
        currentpara=["MAIN"]
        anotherparalist=['MAIN']
        with open("Duplicatefile0" + str(i)+ '.txt', "r+") as expanded_file:
            if_line_flag = False
            for line in expanded_file.readlines():
                variable_flag = False
                ##print(line)
                if line.strip() == '' or line[0] == '*' or line.strip() == "skip" or line.strip() == "skip" or line.strip() == 'eject':
                    continue
                else:

                 with open("Duplicatefile1" + str(i) + '.txt', "a") as temp_file1:

                   module = re.findall(r'^\s*DEFINE\s*SUBROUTINE\s.*', line)
                   module_1=re.findall(r'^\s*DEFINE\s*.*', line)
                   Proc_regexx=re.findall(r'^\sPROCEDURE\s*DIVISION.*',line)

                   if if_line_flag:
                       line7=line.split('/*')
                       if line7[0].strip().startswith("OR ") or line7[0].strip().startswith("AND ") or line7[0].strip().endswith(" OR") or line7[0].strip().endswith(" AND"):
                           None
                       else:


                           if onelinebuffer[len(onelinebuffer)-1].replace('<br>','').strip().endswith(' OR') or onelinebuffer[len(onelinebuffer)-1].replace('<br>','').strip().endswith(' AND'):

                               None
                           else:
                            if_line_flag=False

                   if onelinebuffer!=[]:
                       oneline_data = onelinebuffer[len(onelinebuffer) - 1].replace('<br>', '')

                       if line.strip().startswith('IF '):
                           if_line_flag = True

                       # Separating the line from 'IF' line , when it starts with the variable.

                       line9 = oneline_data.split('/*')
                       if line9[0].strip().endswith(' OR') or line9[0].strip().endswith(' AND') or line.strip().startswith(
                               'OR ') or line.strip().startswith('AND '):
                           None
                       else:

                           if line9[0].strip().startswith('IF'):
                                 variable_flag = True ### change to TRUE for variable
                           if_line_flag = False

                   if line.strip().startswith('IF '):
                       if_line_flag=True


                   if line.strip().startswith('D0 ') and if_line_flag:
                       if_line_flag=False


                   if currentpara!=[] and module!=[]:
                       currentpara.clear()
                   if module != [] or module_1!=[]:
                       if module!=[]:
                         module = module[0]
                       elif module_1!=[]:
                         module_1=module_1[0]
                       if onelinebuffer!=[]:
                           line6 = ""
                           for data in range(len(onelinebuffer)):
                               line6 = line6 + onelinebuffer[data]
                           line6=line6+' $'+anotherparalist[len(anotherparalist)-1]
                           temp_file1.write('\n')
                           temp_file1.write(line6)
                           onelinebuffer.clear()
                           if  module!=[]:

                               temp_file1.write('\n')
                               temp_file1.write(module)
                               module=module.split()
                               anotherparalist.append(module[2])
                               currentpara.append(module[2])
                               temp_file1.write('\n')
                           elif module_1!=[]:
                               temp_file1.write('\n')
                               temp_file1.write(module_1)
                               module = module_1.split()
                               anotherparalist.append(module_1[1])
                               currentpara.append(module_1[1])
                               temp_file1.write('\n')

                   else:
                       if currentpara!=[]:
                         currentparastring=currentpara[0]
                         line=re.sub('\n','',line)
                         line=line+'         $'+currentparastring
                       onelinesplit=line.split('$')
                       actualline=onelinesplit[0]
                       firstword=actualline.split()
                       firstword=firstword[0]
                       ##print(firstword)
                       # if firstword =="EXEC":
                       #     if onelinebuffer != []:
                       #         line6 = ""
                       #         for data in range(len(onelinebuffer)):
                       #             line6 = line6 + onelinebuffer[data]
                       #         line6 = line6 + ' $' + onelinesplit[1]
                       #         temp_file1.write('\n')
                       #         temp_file1.write(line6)
                       #         onelinebuffer.clear()
                       #     execflag1=True
                       #     temp_file1.write('\n')
                       #     temp_file1.write(line)
                       #     temp_file1.write('\n')
                       #     continue
                       # elif execflag1:
                       #     temp_file1.write('\n')
                       #     temp_file1.write(line)
                       #     temp_file1.write('\n')
                       #     if firstword=="END-EXEC" or firstword=="END-EXEC.":
                       #      execflag1 = False
                       #     continue
                       # if firstword in Key_Word_List and actualline.__contains__('...... '):
                       #    if onelinebuffer != []:
                       #      line7=""
                       #      for data in range(len(onelinebuffer)):
                       #                   line7 =line7+ onelinebuffer[data]
                       #      line7 = line7 + ' $' + onelinesplit[1]
                       #      temp_file1.write('\n')
                       #      temp_file1.write(line7)
                       #      temp_file1.write('\n')
                       #      temp_file1.write(line)
                       #      ##print(line)
                       #      onelineflag = False
                       #      onelinebuffer=[]
                       #      continue
                       #    else:
                       #       temp_file1.write('\n')
                       #       temp_file1.write(line)
                       #       temp_file1.write('\n')
                       #       continue

                       #if firstword in Key_Word_List or (firstword.startswith('#') and not if_line_flag) or variable_flag  :
                       if firstword in Key_Word_List or (firstword.startswith('#') and not if_line_flag) or variable_flag:

                          variable_flag=False
                          ##print(if_line_flag)
                          if onelinebuffer!=[]:
                            line6=""
                            for data in range(len(onelinebuffer)):
                                 line6 = line6 + onelinebuffer[data]
                                 onelineflag = False

                            # checking the local variable check in 'IF' line.


                            if line6.startswith("IF") and firstword.startswith('#') :
                                if line6.__contains__('/*'):
                                    split_line=line6.split('/*')[0]
                                    if split_line.strip().endswith("OR") or  split_line.strip().endswith("AND"):
                                        line6=line6+ '  <br>  '+line
                                else:
                                    split_line = line6.split('/*')[0]
                                    if split_line.strip().endswith("OR") or  split_line.strip().endswith("AND"):
                                        line6=line6+ '  <br>  '+line
                            ############################################################

                            line6=line6+' $'+onelinesplit[1]
                            temp_file1.write('\n')
                            temp_file1.write(line6)
                            onelinebuffer=[]
                            if firstword in Key_Word_List and  actualline.__contains__('...'):
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
                       # elif actualline.__contains__('.....'):
                       #     if onelineflag:
                       #                onelineflag = False
                       #                actualline = actualline + '           $'+onelinesplit[1]
                       #                onelinebuffer.append(actualline)
                       #                line = ""
                       #                for data in range(len(onelinebuffer)):
                       #                    line = line + onelinebuffer[data]
                       #                temp_file1.write('\n')
                       #                temp_file1.write(line)
                       #                onelinebuffer=[]
                       #                continue
                       elif onelineflag:
                                  actualline = actualline + ' ' + '<br>'+ ' '
                                  onelinebuffer.append(actualline)
                                  continue
                       onelinebuffer=[]

            with open("Duplicatefile1" + str(i) + '.txt', "a") as temp_file1:

                 temp_file1.write('\n'+' '.join(onelinebuffer)+ '  $'+currentparastring)


        with open("Duplicatefile1" + str(i) + '.txt', "r+") as space_line:
            with open("Duplicatefile2" + str(i) + '.txt', "a+") as space_line1:
                for lines in space_line.readlines():
                    space_line1.write(' '+lines)
        space_line1.close()
        space_line.close()



        # Adding END-IF for single line if statements.

        with open("Duplicatefile2" + str(i) + '.txt', "r+") as end_if_line:
          with open("Duplicatefile3" + str(i) + '.txt', "a") as end_if_line1:
            if_falg = False
            index_of_if = 0
            counter = 0
            if_counter=0
            prev_index = 0
            for line in end_if_line:
                data_flag = False
                split_line = line.split()
                if line.strip() == "":
                    continue
                index_of_if1 = line.find(split_line[0]+' ')
                if if_falg :
                    counter = counter + 1
                    if counter<2 and not line.strip().startswith('IF '):
                        data_flag=True
                        end_if_line1.write(line)

                if line.strip().startswith('IF ') and if_falg!=True and not line.__contains__("END-IF") and not line.__contains__("ELSE "):
                    if_counter=if_counter+1
                    ##print('2',line)
                    end_if_line1.write(line)
                    if_falg = True
                    data_flag = True
                    index_of_if = line.find("IF ")
                    ##print("index",index_of_if)
                    prev_index = index_of_if
                    if_para_value=line.split('$')[1]
                    # #print(index,line,index_of_if)

                elif line.strip().startswith('IF ') and if_falg and not line.__contains__("END-IF") and not line.__contains__("ELSE "):

                    if index_of_if1==prev_index and counter==2 :
                       # #print("end if")
                        if not line.__contains__('END-IF') and not line.__contains__("END-NOREC"):
                            end_if_line1.write("         END-IF <br> $"+if_para_value+'\n')
                    if_counter = if_counter + 1
                    ##print('4', line)
                    end_if_line1.write(line)
                    if_falg = True
                    data_flag = True
                    index_of_if = line.find("IF ")
                    ##print(index_of_if, index_of_if1, line,counter)
                    if_para_value = line.split('$')[1]
                    prev_index = index_of_if
                    #if if_counter<2:
                    counter=0


                line4=line.lstrip()
                if ( index_of_if == index_of_if1 or index_of_if1 < index_of_if or line.lstrip().startswith('MARK ') )and counter == 2:
                    ##print("end if")
                    if not line.__contains__('END-IF') and  not line.__contains__("END-NOREC"):

                        if line.__contains__("ELSE") and index_of_if == index_of_if1:
                            None
                        else:
                            end_if_line1.write("         END-IF  <br> $"+if_para_value+'\n')

                    end_if_line1.write(line)
                    if_falg=False
                    data_flag = True
                    counter = 0
                    index_of_if = 0
                    prev_index=0

                if counter > 2:
                  if_falg=False
                  counter=0
                  index_of_if=0

                if not data_flag :
                    ##print('6',line)
                    end_if_line1.write(line)

        # with open("Duplicatefile3" + str(i) + '.txt', "r+") as space_line:
        #     with open("Duplicatefile6" + str(i) + '.txt', "a+") as space_line1:
        #
        #          for line in space_line.readlines():
        #
        #             space_line1.write(line)
        #
        # space_line1.close()
        # space_line.close()

        with open("Duplicatefile3" + str(i) + '.txt', "r+") as space_line:
            with open("Duplicatefile4" + str(i) + '.txt', "a+") as space_line1:
                for lines in space_line.readlines():
                    space_line1.write(lines)
        space_line1.close()
        space_line.close()


        #Perform expansion.

        currentmodulevalue=""
        with open("Duplicatefile3" + str(i) + '.txt', "r") as temp_file:
         with  open("FinalFile0" + str(i) + '.txt', "a") as temp_file1:
            for line in temp_file.readlines():
             if line[0]=='*':
                 continue
             else:
              ##print(line)
              perform=re.findall(r'^\s*PERFORM.*',line)
              if perform!=[]:
               Temp_perform=perform[0]
               Temp_perform=Temp_perform.split()
               Temp_perform=Temp_perform[1]
               Performparalist.append(Temp_perform)


              #module = re.findall(r'^\s*DEFINE\s*SUBROUTINE\s.*', line)
              module_= re.findall(r'^\s*DEFINE\s*.*', line)

              modulelist.append(module)

              lenofmodulelist=len(modulelist)
              if module!=[]:
                 currentmodule = modulelist[lenofmodulelist - 1]
                 currentmodulevalue= currentmodule[0]
                 currentmodulevalue = re.sub('DEFINE', '', currentmodulevalue)
                 if currentmodulevalue.__contains__('SUBROUTINE'):
                     currentmodulevalue = re.sub('SUBROUTINE', '', currentmodulevalue.strip())

              if perform!=[]:
                  performlist.append(perform)
                  performline=perform
                  perform=perform[0]
                  perform=perform.split()
                  perform=perform[1]

                  #with  open("FinalFile0" + str(i) + '.txt', "a") as temp_file1:
                  if perform=="$":
                        temp_file1.write('\n')
                        #temp_file1.write("")
                  else:
                      ##print("perofrm",perform)
                      temp_file1.write('\n')
                      performWrite = '@' + performline[0] +'   $'+ currentmodulevalue
                      temp_file1.write(performWrite)

                  if perform in dict.keys():
                      #print("perofmr",perform)
                      temp_file1.write('\n')
                      temp_file1.write('\n'.join(dict[perform]))

              else:
                  #with  open("FinalFile0" + str(i) + '.txt', "a") as temp_file1:
                      temp_file1.write('\n')
                      temp_file1.write('   '+line)
        temp_file1.close()


        #Perform 2
        currentmodulevalue = ""
        with open("FinalFile0" + str(i) + '.txt', "r") as temp_file:
            with  open("FinalFile1" + str(i) + '.txt', "a") as temp_file1:
                for line in temp_file.readlines():
                    if line[0] == '*':
                        continue
                    else:
                        # #print(line)
                        perform = re.findall(r'^\s*PERFORM.*', line)
                        if perform != []:
                            Temp_perform = perform[0]
                            Temp_perform = Temp_perform.split()
                            Temp_perform = Temp_perform[1]
                            Performparalist.append(Temp_perform)

                        # module = re.findall(r'^\s*DEFINE\s*SUBROUTINE\s.*', line)
                        module_ = re.findall(r'^\s*DEFINE\s*.*', line)

                        modulelist.append(module)

                        lenofmodulelist = len(modulelist)
                        if module != []:
                            currentmodule = modulelist[lenofmodulelist - 1]
                            currentmodulevalue = currentmodule[0]
                            currentmodulevalue = re.sub('DEFINE', '', currentmodulevalue)
                            if currentmodulevalue.__contains__('SUBROUTINE'):
                                currentmodulevalue = re.sub('SUBROUTINE', '', currentmodulevalue.strip())

                        if perform != []:
                            performlist.append(perform)
                            performline = perform
                            perform = perform[0]
                            perform = perform.split()
                            perform = perform[1]

                            # with  open("FinalFile0" + str(i) + '.txt', "a") as temp_file1:
                            if perform == "$":
                                temp_file1.write('\n')
                                # temp_file1.write("")
                            else:
                                # #print("perofrm",perform)
                                temp_file1.write('\n')
                                performWrite = '@' + performline[0] + '   $' + currentmodulevalue
                                temp_file1.write(performWrite)

                            if perform in dict.keys():
                                ##print("perofmr", perform)
                                temp_file1.write('\n')
                                temp_file1.write('\n'.join(dict[perform]))

                        else:
                            # with  open("FinalFile0" + str(i) + '.txt', "a") as temp_file1:
                            temp_file1.write('\n')
                            temp_file1.write('   ' + line)
        temp_file1.close()

        #Perform 3.
        currentmodulevalue = ""
        with open("FinalFile1" + str(i) + '.txt', "r") as temp_file:
            with  open("FinalFile2" + str(i) + '.txt', "a") as temp_file1:
                for line in temp_file.readlines():
                    if line[0] == '*':
                        continue
                    else:
                        # #print(line)
                        perform = re.findall(r'^\s*PERFORM.*', line)
                        if perform != []:
                            Temp_perform = perform[0]
                            Temp_perform = Temp_perform.split()
                            Temp_perform = Temp_perform[1]
                            Performparalist.append(Temp_perform)

                        # module = re.findall(r'^\s*DEFINE\s*SUBROUTINE\s.*', line)
                        module_ = re.findall(r'^\s*DEFINE\s*.*', line)

                        modulelist.append(module)

                        lenofmodulelist = len(modulelist)
                        if module != []:
                            currentmodule = modulelist[lenofmodulelist - 1]
                            currentmodulevalue = currentmodule[0]
                            currentmodulevalue = re.sub('DEFINE', '', currentmodulevalue)
                            if currentmodulevalue.__contains__('SUBROUTINE'):
                                currentmodulevalue = re.sub('SUBROUTINE', '', currentmodulevalue.strip())

                        if perform != []:
                            performlist.append(perform)
                            performline = perform
                            perform = perform[0]
                            perform = perform.split()
                            perform = perform[1]

                            # with  open("FinalFile0" + str(i) + '.txt', "a") as temp_file1:
                            if perform == "$":
                                temp_file1.write('\n')
                                # temp_file1.write("")
                            else:
                                # #print("perofrm",perform)
                                temp_file1.write('\n')
                                performWrite = '@' + performline[0] + '   $' + currentmodulevalue
                                temp_file1.write(performWrite)

                            if perform in dict.keys():
                                ##print("perofmr", perform)
                                temp_file1.write('\n')
                                temp_file1.write('\n'.join(dict[perform]))

                        else:
                            # with  open("FinalFile0" + str(i) + '.txt', "a") as temp_file1:
                            temp_file1.write('\n')
                            temp_file1.write('   ' + line)
        temp_file1.close()

        #perform 4.
        currentmodulevalue = ""
        with open("FinalFile2" + str(i) + '.txt', "r") as temp_file:
            with  open("FinalFile3" + str(i) + '.txt', "a") as temp_file1:
                for line in temp_file.readlines():
                    if line[0] == '*':
                        continue
                    else:
                        # #print(line)
                        perform = re.findall(r'^\s*PERFORM.*', line)
                        if perform != []:
                            Temp_perform = perform[0]
                            Temp_perform = Temp_perform.split()
                            Temp_perform = Temp_perform[1]
                            Performparalist.append(Temp_perform)

                        # module = re.findall(r'^\s*DEFINE\s*SUBROUTINE\s.*', line)
                        module_ = re.findall(r'^\s*DEFINE\s*.*', line)

                        modulelist.append(module)

                        lenofmodulelist = len(modulelist)
                        if module != []:
                            currentmodule = modulelist[lenofmodulelist - 1]
                            currentmodulevalue = currentmodule[0]
                            currentmodulevalue = re.sub('DEFINE', '', currentmodulevalue)
                            if currentmodulevalue.__contains__('SUBROUTINE'):
                                currentmodulevalue = re.sub('SUBROUTINE', '', currentmodulevalue.strip())

                        if perform != []:
                            performlist.append(perform)
                            performline = perform
                            perform = perform[0]
                            perform = perform.split()
                            perform = perform[1]

                            # with  open("FinalFile0" + str(i) + '.txt', "a") as temp_file1:
                            if perform == "$":
                                temp_file1.write('\n')
                                # temp_file1.write("")
                            else:
                                # #print("perofrm",perform)
                                temp_file1.write('\n')
                                performWrite = '@' + performline[0] + '   $' + currentmodulevalue
                                temp_file1.write(performWrite)

                            if perform in dict.keys():
                                ##print("perofmr", perform)
                                temp_file1.write('\n')
                                temp_file1.write('\n'.join(dict[perform]))

                        else:
                            # with  open("FinalFile0" + str(i) + '.txt', "a") as temp_file1:
                            temp_file1.write('\n')
                            temp_file1.write('   ' + line)
        temp_file1.close()

        #perform 6.
        currentmodulevalue = ""
        with open("FinalFile3" + str(i) + '.txt', "r") as temp_file:
            with  open("FinalFile4" + str(i) + '.txt', "a") as temp_file1:
                for line in temp_file.readlines():
                    if line[0] == '*':
                        continue
                    else:
                        # #print(line)
                        perform = re.findall(r'^\s*PERFORM.*', line)
                        if perform != []:
                            Temp_perform = perform[0]
                            Temp_perform = Temp_perform.split()
                            Temp_perform = Temp_perform[1]
                            Performparalist.append(Temp_perform)

                        # module = re.findall(r'^\s*DEFINE\s*SUBROUTINE\s.*', line)
                        module_ = re.findall(r'^\s*DEFINE\s*.*', line)

                        modulelist.append(module)

                        lenofmodulelist = len(modulelist)
                        if module != []:
                            currentmodule = modulelist[lenofmodulelist - 1]
                            currentmodulevalue = currentmodule[0]
                            currentmodulevalue = re.sub('DEFINE', '', currentmodulevalue)
                            if currentmodulevalue.__contains__('SUBROUTINE'):
                                currentmodulevalue = re.sub('SUBROUTINE', '', currentmodulevalue.strip())

                        if perform != []:
                            performlist.append(perform)
                            performline = perform
                            perform = perform[0]
                            perform = perform.split()
                            perform = perform[1]

                            # with  open("FinalFile0" + str(i) + '.txt', "a") as temp_file1:
                            if perform == "$":
                                temp_file1.write('\n')
                                # temp_file1.write("")
                            else:
                                # #print("perofrm",perform)
                                temp_file1.write('\n')
                                performWrite = '@' + performline[0] + '   $' + currentmodulevalue
                                temp_file1.write(performWrite)

                            if perform in dict.keys():
                                ##print("perofmr", perform)
                                temp_file1.write('\n')
                                temp_file1.write('\n'.join(dict[perform]))

                        else:
                            # with  open("FinalFile0" + str(i) + '.txt', "a") as temp_file1:
                            temp_file1.write('\n')
                            temp_file1.write('   ' + line)
        temp_file1.close()

        #EPrform 6.

        currentmodulevalue = ""
        with open("FinalFile4" + str(i) + '.txt', "r") as temp_file:
            with  open("FinalFile6" + str(i) + '.txt', "a") as temp_file1:
                for line in temp_file.readlines():
                    if line[0] == '*':
                        continue
                    else:
                        # #print(line)
                        perform = re.findall(r'^\s*PERFORM.*', line)
                        if perform != []:
                            Temp_perform = perform[0]
                            Temp_perform = Temp_perform.split()
                            Temp_perform = Temp_perform[1]
                            Performparalist.append(Temp_perform)

                        # module = re.findall(r'^\s*DEFINE\s*SUBROUTINE\s.*', line)
                        module_ = re.findall(r'^\s*DEFINE\s*.*', line)

                        modulelist.append(module)

                        lenofmodulelist = len(modulelist)
                        if module != []:
                            currentmodule = modulelist[lenofmodulelist - 1]
                            currentmodulevalue = currentmodule[0]
                            currentmodulevalue = re.sub('DEFINE', '', currentmodulevalue)
                            if currentmodulevalue.__contains__('SUBROUTINE'):
                                currentmodulevalue = re.sub('SUBROUTINE', '', currentmodulevalue.strip())

                        if perform != []:
                            performlist.append(perform)
                            performline = perform
                            perform = perform[0]
                            perform = perform.split()
                            perform = perform[1]

                            # with  open("FinalFile0" + str(i) + '.txt', "a") as temp_file1:
                            if perform == "$":
                                temp_file1.write('\n')
                                # temp_file1.write("")
                            else:
                                # #print("perofrm",perform)
                                temp_file1.write('\n')
                                performWrite = '@' + performline[0] + '   $' + currentmodulevalue
                                temp_file1.write(performWrite)

                            if perform in dict.keys():
                                ##print("perofmr", perform)
                                temp_file1.write('\n')
                                temp_file1.write('\n'.join(dict[perform]))

                        else:
                            # with  open("FinalFile0" + str(i) + '.txt', "a") as temp_file1:
                            temp_file1.write('\n')
                            temp_file1.write('   ' + line)
        temp_file1.close()

        #Perform 7.

        currentmodulevalue = ""
        with open("FinalFile6" + str(i) + '.txt', "r") as temp_file:
            with  open("FinalFile6" + str(i) + '.txt', "a") as temp_file1:
                for line in temp_file.readlines():
                    if line[0] == '*':
                        continue
                    else:
                        # #print(line)
                        perform = re.findall(r'^\s*PERFORM.*', line)
                        if perform != []:
                            Temp_perform = perform[0]
                            Temp_perform = Temp_perform.split()
                            Temp_perform = Temp_perform[1]
                            Performparalist.append(Temp_perform)

                        # module = re.findall(r'^\s*DEFINE\s*SUBROUTINE\s.*', line)
                        module_ = re.findall(r'^\s*DEFINE\s*.*', line)

                        modulelist.append(module)

                        lenofmodulelist = len(modulelist)
                        if module != []:
                            currentmodule = modulelist[lenofmodulelist - 1]
                            currentmodulevalue = currentmodule[0]
                            currentmodulevalue = re.sub('DEFINE', '', currentmodulevalue)
                            if currentmodulevalue.__contains__('SUBROUTINE'):
                                currentmodulevalue = re.sub('SUBROUTINE', '', currentmodulevalue.strip())

                        if perform != []:
                            performlist.append(perform)
                            performline = perform
                            perform = perform[0]
                            perform = perform.split()
                            perform = perform[1]

                            # with  open("FinalFile0" + str(i) + '.txt', "a") as temp_file1:
                            if perform == "$":
                                temp_file1.write('\n')
                                # temp_file1.write("")
                            else:
                                # #print("perofrm",perform)
                                temp_file1.write('\n')
                                performWrite = '@' + performline[0] + '   $' + currentmodulevalue
                                temp_file1.write(performWrite)

                            if perform in dict.keys():
                                ##print("perofmr", perform)
                                temp_file1.write('\n')
                                temp_file1.write('\n'.join(dict[perform]))

                        else:
                            # with  open("FinalFile0" + str(i) + '.txt', "a") as temp_file1:
                            temp_file1.write('\n')
                            temp_file1.write('   ' + line)
        temp_file1.close()

        #perform 8.

        currentmodulevalue = ""
        with open("FinalFile6" + str(i) + '.txt', "r") as temp_file:
            with  open("FinalFile7" + str(i) + '.txt', "a") as temp_file1:
                for line in temp_file.readlines():
                    if line[0] == '*':
                        continue
                    else:
                        # #print(line)
                        perform = re.findall(r'^\s*PERFORM.*', line)
                        if perform != []:
                            Temp_perform = perform[0]
                            Temp_perform = Temp_perform.split()
                            Temp_perform = Temp_perform[1]
                            Performparalist.append(Temp_perform)

                        # module = re.findall(r'^\s*DEFINE\s*SUBROUTINE\s.*', line)
                        module_ = re.findall(r'^\s*DEFINE\s*.*', line)

                        modulelist.append(module)

                        lenofmodulelist = len(modulelist)
                        if module != []:
                            currentmodule = modulelist[lenofmodulelist - 1]
                            currentmodulevalue = currentmodule[0]
                            currentmodulevalue = re.sub('DEFINE', '', currentmodulevalue)
                            if currentmodulevalue.__contains__('SUBROUTINE'):
                                currentmodulevalue = re.sub('SUBROUTINE', '', currentmodulevalue.strip())

                        if perform != []:
                            performlist.append(perform)
                            performline = perform
                            perform = perform[0]
                            perform = perform.split()
                            perform = perform[1]

                            # with  open("FinalFile0" + str(i) + '.txt', "a") as temp_file1:
                            if perform == "$":
                                temp_file1.write('\n')
                                # temp_file1.write("")
                            else:
                                # #print("perofrm",perform)
                                temp_file1.write('\n')
                                performWrite = '@' + performline[0] + '   $' + currentmodulevalue
                                temp_file1.write(performWrite)

                            if perform in dict.keys():
                                ##print("perofmr", perform)
                                temp_file1.write('\n')
                                temp_file1.write('\n'.join(dict[perform]))

                        else:
                            # with  open("FinalFile0" + str(i) + '.txt', "a") as temp_file1:
                            temp_file1.write('\n')
                            temp_file1.write('   ' + line)
        temp_file1.close()

        #Perform 9.

        currentmodulevalue = ""
        with open("FinalFile7" + str(i) + '.txt', "r") as temp_file:
            with  open("FinalFile8" + str(i) + '.txt', "a") as temp_file1:
                for line in temp_file.readlines():
                    if line[0] == '*':
                        continue
                    else:
                        # #print(line)
                        perform = re.findall(r'^\s*PERFORM.*', line)
                        if perform != []:
                            Temp_perform = perform[0]
                            Temp_perform = Temp_perform.split()
                            Temp_perform = Temp_perform[1]
                            Performparalist.append(Temp_perform)

                        # module = re.findall(r'^\s*DEFINE\s*SUBROUTINE\s.*', line)
                        module_ = re.findall(r'^\s*DEFINE\s*.*', line)

                        modulelist.append(module)

                        lenofmodulelist = len(modulelist)
                        if module != []:
                            currentmodule = modulelist[lenofmodulelist - 1]
                            currentmodulevalue = currentmodule[0]
                            currentmodulevalue = re.sub('DEFINE', '', currentmodulevalue)
                            if currentmodulevalue.__contains__('SUBROUTINE'):
                                currentmodulevalue = re.sub('SUBROUTINE', '', currentmodulevalue.strip())

                        if perform != []:
                            performlist.append(perform)
                            performline = perform
                            perform = perform[0]
                            perform = perform.split()
                            perform = perform[1]

                            # with  open("FinalFile0" + str(i) + '.txt', "a") as temp_file1:
                            if perform == "$":
                                temp_file1.write('\n')
                                # temp_file1.write("")
                            else:
                                # #print("perofrm",perform)
                                temp_file1.write('\n')
                                performWrite = '@' + performline[0] + '   $' + currentmodulevalue
                                temp_file1.write(performWrite)

                            if perform in dict.keys():
                                ##print("perofmr", perform)
                                temp_file1.write('\n')
                                temp_file1.write('\n'.join(dict[perform]))

                        else:
                            # with  open("FinalFile0" + str(i) + '.txt', "a") as temp_file1:
                            temp_file1.write('\n')
                            temp_file1.write('   ' + line)
        temp_file1.close()

        #perform 10.

        currentmodulevalue = ""
        with open("FinalFile8" + str(i) + '.txt', "r") as temp_file:
            with  open("FinalFile9" + str(i) + '.txt', "a") as temp_file1:
                for line in temp_file.readlines():
                    if line[0] == '*':
                        continue
                    else:
                        # #print(line)
                        perform = re.findall(r'^\s*PERFORM.*', line)
                        if perform != []:
                            Temp_perform = perform[0]
                            Temp_perform = Temp_perform.split()
                            Temp_perform = Temp_perform[1]
                            Performparalist.append(Temp_perform)

                        # module = re.findall(r'^\s*DEFINE\s*SUBROUTINE\s.*', line)
                        module_ = re.findall(r'^\s*DEFINE\s*.*', line)

                        modulelist.append(module)

                        lenofmodulelist = len(modulelist)
                        if module != []:
                            currentmodule = modulelist[lenofmodulelist - 1]
                            currentmodulevalue = currentmodule[0]
                            currentmodulevalue = re.sub('DEFINE', '', currentmodulevalue)
                            if currentmodulevalue.__contains__('SUBROUTINE'):
                                currentmodulevalue = re.sub('SUBROUTINE', '', currentmodulevalue.strip())

                        if perform != []:
                            performlist.append(perform)
                            performline = perform
                            perform = perform[0]
                            perform = perform.split()
                            perform = perform[1]

                            # with  open("FinalFile0" + str(i) + '.txt', "a") as temp_file1:
                            if perform == "$":
                                temp_file1.write('\n')
                                # temp_file1.write("")
                            else:
                                # #print("perofrm",perform)
                                temp_file1.write('\n')
                                performWrite = '@' + performline[0] + '   $' + currentmodulevalue
                                temp_file1.write(performWrite)

                            if perform in dict.keys():
                                ##print("perofmr", perform)
                                temp_file1.write('\n')
                                temp_file1.write('\n'.join(dict[perform]))

                        else:
                            # with  open("FinalFile0" + str(i) + '.txt', "a") as temp_file1:
                            temp_file1.write('\n')
                            temp_file1.write('   ' + line)
        temp_file1.close()


        # Eliminating the perfomed para codes.

        # performlistflag = True
        # with open("FinalFile9" + str(i) + '.txt') as infile, open('output' + str(i) + '.txt', 'w') as outfile:
        #     for line in infile:
        #         if not line.strip():
        #             continue  # skip the empty line
        #         else:
        #
        #             module = re.findall(r'^\s*DEFINE\s*.*', line)
        #
        #             if module != []:
        #                 module = module[0].strip().split(" ")
        #                 if module[0]=="DEFINE" and module[1]=="SUBROUTINE":
        #                     module=module[2].split("/*")[0]
        #                 else:
        #                     module=module[1].split("/*")[0]
        #                 # print(Performparalist)
        #                 performlistflag = True
        #                 if module.lstrip() in Performparalist:
        #                     print(module)
        #                     performlistflag = False
        #                 if module.__contains__("EXIT."):
        #                     performlistflag = False
        #
        #             if performlistflag:
        #                 outfile.write(line)


        file_operation(i, METADATA, filename)
     Db_Insert(METADATA)
 except Exception as e:
     from datetime import datetime
     exc_type, exc_obj, exc_tb = sys.exc_info()
     fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
     print(exc_type, fname, exc_tb.tb_lineno)
     f.write(str(datetime.now()))
     f.write('\n' + str(exc_type) + '\n' + fname + '\n' + str(
         exc_tb.tb_lineno) + '\n' + '***********************************' + '\n')
     pass

def file_operation(i,METADATA,filename):
    try:
        RC1 = 0
        RC2 = 0
        RC3 = 0
        RC4 = 0
        RC6 = 0
        RC6 = 0
        Old_Division_Name = ""
        main_list2 = []
        main_dict2 = {}
        main_list3 = []
        main_dict3 = {}
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
                ##print(main_list3)
        j = 0
        bufferline=[]
        cicsbufferline=[]
        TEMP_METADATA=[]
        ifcounter=0
        parent_rule_id_list=[]
        else_flag=False
        doend_flag=False
        value_counter=0
        #with open('Duplicatefile4'+str(i)+'.txt', 'r+') as outfile:
        with open("FinalFile9" + str(i) + '.txt', 'r+') as outfile:
         linenumber=0
         rule_number=0
         exec_flag=False
         cics_flag=False
         else_flag_1 = False
         decide_flag = False
         firstparavalue=""
         p_rule_id=""
         do_counter=0
         for line in outfile.readlines():
           loop_line=line
           if_flag=False
           when_flag = False
           if line.strip()=="":
               continue
           if line.__contains__('$'):
               None
           else:
               line = re.sub('\n', ' ', line)
               line = line + ' $' + "PERFORM"
           templine=line.split('$')
           templine1=templine[0].strip()
           if templine1.strip()=="EJECT":
                continue
           else:
            if templine1!='':
              templine1 =' '.join(templine1.split())
            if templine1.__contains__("EXEC SQL") and templine1.__contains__('END-EXEC'):
                line=templine1 + '           $' +templine[1]
            elif templine1.__contains__("EXEC SQL"):
                exec_flag = True
                templine1=templine1+' '+'<br>'
                bufferline.append(templine1)
                continue
            elif templine1.__contains__("END-EXEC") or templine1.__contains__("END-EXEC."):
              if exec_flag:
                exec_flag = False
                templine1 = templine1 + '           $' +templine[1]
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
                line=templine1 + '           $' +templine[1]
            elif templine1.__contains__("EXEC CICS"):
                cics_flag = True
                templine1=templine1+' '+'<br>'
                cicsbufferline.append(templine1)
                continue
            elif templine1.__contains__("END-EXEC") or templine1.__contains__("END-EXEC."):
              if cics_flag:
                cics_flag = False
                templine1 = templine1 + '           $' +templine[1]
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


              linenumber = linenumber + 1
              module = re.findall(r'^\s{1}[A0-Z9].*[-]*.*[.]', line)

              # CICS statement

              beforesub=line.split()
              if beforesub[0]=='@' and beforesub[1]=="PERFORM":
                  line = re.sub('@\s', ' ', line)
              elif  beforesub[0]=='@':
                line=re.sub('@\s','PERFORM ',line)
              loopNumber=0
              for item in main_list3:
               loopNumber=loopNumber+1
               Reg_ex = item.get('cond')
               line = re.sub(r"\s+", " ", line)

               programName = PGM_ID[i - 1]
               lengthofprogramName=len(programName)-1
               programName=programName[0:lengthofprogramName]
               Open_Rex = re.match(Reg_ex, line)
               endifregexx = re.match('\s*END-IF.*', line)
               endevaluregexx = re.match('.*\sEND-EVALUATE.*\s', line)
               end_rec_regexx = re.match('\s*END-NOREC\s*.*', line)
               doend_regexx=re.match('^\s*DOEND\s*',line)
               if (Open_Rex != None ):
                 splitline = line.split('$')
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

                 decide_regexx=re.match('^\s*DECIDE\s*.*',line)
                 value_regexx=re.match('^\s*VALUE\s*.*',line)
                 end_decide_regexx=re.match('^\s*END-DECIDE\s*',line.strip())
                 ifregexx=re.match('^\s*IF\s.*',line)
                 endifregexx=re.match('\s*END-IF.*',line)
                 else_if_regexx=re.match('\s*ELSE\s*IF.*',line)
                 evaluateregexx=re.match('.*\sEVALUATE\s.*',line)
                 when_regexx=re.match('.*\sWHEN\s.*',line)
                 none_regexx=re.match('^\s*NONE\s*.*',line)
                 #end_rec_regexx=re.match('\s*END-NOREC\s*.*',line)


                 # IF statemensts.


                 if ifregexx!=None or else_if_regexx!=None:

                     if ifcounter==0:
                      firstparavalue=paravalue

                      ifcounter = ifcounter + 1
                      #parent_rule_id_list.append(rule_id)
                     else:
                      #parent_rule_id_list.append(rule_id)
                      ifcounter = ifcounter + 1



                 if (tag_value == "RC1"):
                     else_flag_1 = False
                     if doend_flag:
                         doend_flag=False
                         firstparavalue = firstparavalue.strip()
                         paravalue = paravalue.strip()

                         if firstparavalue == paravalue:

                             if ifcounter == 1:
                                 p_rule_id = ""
                                 ifcounter = 0
                                 period_flag = False
                                 p_id_list_len2 = len(parent_rule_id_list)
                                 if parent_rule_id_list != []:
                                     del parent_rule_id_list[p_id_list_len2 - 1]

                             else:

                                 p_id_list_len2 = len(parent_rule_id_list)
                                 if parent_rule_id_list != []:
                                     del parent_rule_id_list[p_id_list_len2 - 1]
                                 ifcounter = ifcounter - 1
                         else:

                             p_id_list_len2 = len(parent_rule_id_list)
                             if parent_rule_id_list != []:
                                 del parent_rule_id_list[p_id_list_len2 - 1]
                             ifcounter = ifcounter - 1


                         #TEMP_METADATA[0]["parent_rule_id"]=",".join(parent_rule_id_list)
                         #METADATA.append(TEMP_METADATA[0])

                         if TEMP_METADATA != []:

                             for temp_data in TEMP_METADATA:
                                 METADATA.append(temp_data.copy())
                         TEMP_METADATA.clear()

                     loopNumber = 0
                     ##print("1",line)
                     paravaluesplit=paravalue.split()
                     if paravalue.__contains__("PERFORM"):
                         paravalue=re.sub("PERFORM" , " ",paravalue )

                     METADATA.append({'s_no':'', 'pgm_name':programName ,
                                       'fragment_Id':rule_id,
                                      'para_name':paravalue,'source_statements':line,'statement_group':statement_value,'rule_category':catg_value,
                                      'parent_rule_id':",".join(parent_rule_id_list),'business_documentation':''})
                     RC1 = RC1 + 1
                     continue
                 elif (tag_value == "RC2"):

                     else_flag_1=False
                     if doend_flag:
                         doend_flag = False
                         firstparavalue = firstparavalue.strip()
                         paravalue = paravalue.strip()

                         if firstparavalue == paravalue:

                             if ifcounter == 1:
                                 p_rule_id = ""
                                 ifcounter = 0
                                 period_flag = False
                                 p_id_list_len2 = len(parent_rule_id_list)
                                 if parent_rule_id_list != []:
                                     del parent_rule_id_list[p_id_list_len2 - 1]

                             else:

                                 p_id_list_len2 = len(parent_rule_id_list)
                                 if parent_rule_id_list != []:
                                     del parent_rule_id_list[p_id_list_len2 - 1]
                                 ifcounter = ifcounter - 1
                         else:

                             p_id_list_len2 = len(parent_rule_id_list)
                             if parent_rule_id_list != []:
                                 del parent_rule_id_list[p_id_list_len2 - 1]
                             ifcounter = ifcounter - 1

                         #TEMP_METADATA[0]["parent_rule_id"] = ",".join(parent_rule_id_list)
                         #METADATA.append(TEMP_METADATA[0])
                         if TEMP_METADATA != []:

                             for temp_data in TEMP_METADATA:
                                 METADATA.append(temp_data.copy())
                         TEMP_METADATA.clear()

                     ##print("2", line)
                     loopNumber = 0
                     paravaluesplit = paravalue.split()

                     if paravalue.__contains__("PERFORM"):
                             paravalue = re.sub("PERFORM", " ", paravalue)

                     METADATA.append({'s_no': '', 'pgm_name': programName,
                                      'fragment_Id': rule_id,
                                      'para_name': paravalue, 'source_statements': line, 'statement_group': statement_value,
                                      'rule_category': catg_value,
                                      'parent_rule_id': ",".join(parent_rule_id_list), 'business_documentation': ''})
                     ##print('22', line)
                     RC2 = RC2 + 1
                     continue
                 elif (tag_value == "RC3"):
                     #print(line)
                     if doend_flag :

                         if line.__contains__('ELSE'):
                            doend_flag=False
                            METADATA.append(TEMP_METADATA[0])
                            TEMP_METADATA.clear()
                            else_flag=True
                            else_flag_1=True

                         else:
                             doend_flag = False
                             firstparavalue = firstparavalue.strip()
                             paravalue = paravalue.strip()
                             if firstparavalue == paravalue:

                                 if ifcounter == 2 and line.__contains__("IF ") and not line.__contains__("END-IF "):
                                     p_rule_id = ""

                                     period_flag = False
                                     p_id_list_len2 = len(parent_rule_id_list)

                                     if parent_rule_id_list != []:
                                         del parent_rule_id_list[p_id_list_len2 - 1]
                                         #del parent_rule_id_list[0]

                                         #del parent_rule_id_list[ifcounter - 1]
                                     ifcounter = ifcounter - 1

                                 else:


                                     p_id_list_len2 = len(parent_rule_id_list)
                                     if parent_rule_id_list != []:
                                         del parent_rule_id_list[p_id_list_len2 - 1]
                                         #del parent_rule_id_list[0]
                                         #del parent_rule_id_list[ifcounter-1]
                                     ifcounter = ifcounter - 1

                             else:


                                 p_id_list_len2 = len(parent_rule_id_list)
                                 if parent_rule_id_list != []:
                                     del parent_rule_id_list[p_id_list_len2 - 1]
                                     #del parent_rule_id_list[0]
                                 ifcounter = ifcounter - 1

                             # if not TEMP_METADATA[0]["parent_rule_id"]=="":
                             #
                             #     TEMP_METADATA[0]["parent_rule_id"] = ",".join(parent_rule_id_list)
                             # else:
                             #     TEMP_METADATA[0]["parent_rule_id"]=""


                             #METADATA.append(TEMP_METADATA[0])
                             if TEMP_METADATA != []:

                                 for temp_data in TEMP_METADATA:
                                     METADATA.append(temp_data.copy())
                             TEMP_METADATA.clear()

                     # else:
                     #
                     #     if TEMP_METADATA != []:
                     #
                     #         for temp_data in TEMP_METADATA:
                     #             METADATA.append(temp_data.copy())
                     #     TEMP_METADATA.clear()
                     loopNumber = 0
                     paravaluesplit = paravalue.split()


                     if else_flag_1 and ifregexx!=None:
                         else_flag_1 = False
                         p_id_list_len2 = len(parent_rule_id_list)
                         if parent_rule_id_list != []:
                             del parent_rule_id_list[p_id_list_len2 - 1]
                             # del parent_rule_id_list[0]
                         ifcounter = ifcounter - 1

                     if else_if_regexx!=None:


                         p_id_list_len2 = len(parent_rule_id_list)
                         if parent_rule_id_list != []:
                             del parent_rule_id_list[p_id_list_len2 - 1]
                             # del parent_rule_id_list[0]
                         ifcounter = ifcounter - 1



                     if ifregexx!=None :

                        parent_rule_id_list.append(rule_id)

                     if decide_regexx!=None:

                         decide_flag=True
                         parent_rule_id_list.append(rule_id)

                     if value_regexx!=None:
                         if decide_flag==False:
                             p_id_list_len2 = len(parent_rule_id_list)
                             if parent_rule_id_list != []:
                                 del parent_rule_id_list[p_id_list_len2 - 1]

                         decide_flag = False
                         value_counter-=value_counter+1
                         parent_rule_id_list.append(rule_id)

                     if when_regexx!=None:

                         if decide_flag==False:

                             p_id_list_len2 = len(parent_rule_id_list)
                             if parent_rule_id_list != []:
                                 del parent_rule_id_list[p_id_list_len2 - 1]

                         decide_flag = False
                         value_counter = value_counter + 1
                         parent_rule_id_list.append(rule_id)

                     if none_regexx!=None:
                          p_id_list_len2 = len(parent_rule_id_list)
                          if parent_rule_id_list != []:
                              del parent_rule_id_list[p_id_list_len2 - 1]
                          parent_rule_id_list.append(rule_id)
                     ##print('3',line)

                     if paravalue.__contains__("PERFORM"):
                         paravalue = re.sub("PERFORM", " ", paravalue)

                     METADATA.append({'s_no': '', 'pgm_name': programName,
                                          'fragment_Id': rule_id,
                                          'para_name': paravalue, 'source_statements': line,
                                          'statement_group': statement_value,
                                          'rule_category': catg_value,
                                          'parent_rule_id': ",".join(parent_rule_id_list), 'business_documentation': ''})
                     RC3 = RC3 + 1

                     loop_regexx = re.match('^\s{1}LOOP.*', loop_line)

                     if loop_regexx != None:

                         parent_rule_id_list = []
                     continue
                 elif (tag_value == "RC4"):
                     else_flag_1 = False
                     if doend_flag:
                         doend_flag = False
                         firstparavalue = firstparavalue.strip()
                         paravalue = paravalue.strip()

                         if firstparavalue == paravalue:

                             if ifcounter == 1:
                                 p_rule_id = ""
                                 ifcounter = 0
                                 period_flag = False
                                 p_id_list_len2 = len(parent_rule_id_list)
                                 if parent_rule_id_list != []:
                                     del parent_rule_id_list[p_id_list_len2 - 1]

                             else:

                                 p_id_list_len2 = len(parent_rule_id_list)
                                 if parent_rule_id_list != []:
                                     del parent_rule_id_list[p_id_list_len2 - 1]
                                 ifcounter = ifcounter - 1
                         else:

                             p_id_list_len2 = len(parent_rule_id_list)
                             if parent_rule_id_list != []:
                                 del parent_rule_id_list[p_id_list_len2 - 1]
                             ifcounter = ifcounter - 1

                         #TEMP_METADATA[0]["parent_rule_id"] = ",".join(parent_rule_id_list)
                         #METADATA.append(TEMP_METADATA[0])
                         if TEMP_METADATA != []:

                             for temp_data in TEMP_METADATA:
                                 METADATA.append(temp_data.copy())
                         TEMP_METADATA.clear()
                     loopNumber = 0
                     ##print("4", line)
                     paravaluesplit = paravalue.split()

                     if paravalue.__contains__("PERFORM"):
                         paravalue = re.sub("PERFORM", " ", paravalue)
                     METADATA.append({'s_no': '', 'pgm_name': programName,
                                      'fragment_Id': rule_id,
                                      'para_name': paravalue, 'source_statements': line, 'statement_group': statement_value,
                                      'rule_category': catg_value,
                                      'parent_rule_id': ",".join(parent_rule_id_list), 'business_documentation': ''})
                     ##print('44', line)
                     RC4 = RC4 + 1
                     continue
                 elif (tag_value == "RC6"):
                     else_flag_1 = False
                     if doend_flag:
                         doend_flag = False
                         firstparavalue = firstparavalue.strip()
                         paravalue = paravalue.strip()

                         if firstparavalue == paravalue:

                             if ifcounter == 1:
                                 p_rule_id = ""
                                 ifcounter = 0
                                 period_flag = False
                                 p_id_list_len2 = len(parent_rule_id_list)
                                 if parent_rule_id_list != []:
                                     del parent_rule_id_list[p_id_list_len2 - 1]

                             else:

                                 p_id_list_len2 = len(parent_rule_id_list)
                                 if parent_rule_id_list != []:
                                     del parent_rule_id_list[p_id_list_len2 - 1]
                                 ifcounter = ifcounter - 1
                         else:

                             p_id_list_len2 = len(parent_rule_id_list)
                             if parent_rule_id_list != []:
                                 del parent_rule_id_list[p_id_list_len2 - 1]
                             ifcounter = ifcounter - 1

                         #TEMP_METADATA[0]["parent_rule_id"] = ",".join(parent_rule_id_list)
                         #METADATA.append(TEMP_METADATA[0])
                         if TEMP_METADATA != []:
                             for temp_data in TEMP_METADATA:
                                 METADATA.append(temp_data.copy())
                         TEMP_METADATA.clear()
                     ##print("6", line)
                     loopNumber = 0
                     paravaluesplit = paravalue.split()

                     if paravalue.__contains__("PERFORM"):
                             paravalue = re.sub("PERFORM", " ", paravalue)

                     METADATA.append({'s_no': '', 'pgm_name': programName,
                                      'fragment_Id': rule_id,
                                      'para_name': paravalue, 'source_statements': line, 'statement_group': statement_value,
                                      'rule_category': catg_value,
                                      'parent_rule_id': ",".join(parent_rule_id_list), 'business_documentation': ''})
                     ##print('66',line)
                     RC6 = RC6 + 1
                     continue
                 elif (tag_value == "RC6"):
                     else_flag_1 = False
                     end_sub_regexx = re.match('^END-SUBROUTINE\s*', loop_line)
                     return_regexx = re.match('^\s*RETURN\s*', loop_line)

                     if doend_flag:
                         doend_flag = False
                         firstparavalue = firstparavalue.strip()
                         paravalue = paravalue.strip()
                         METADATA.append(TEMP_METADATA[0])
                         if firstparavalue == paravalue:

                             if ifcounter == 1:
                                 p_rule_id = ""
                                 ifcounter = 0
                                 period_flag = False
                                 p_id_list_len2 = len(parent_rule_id_list)
                                 if parent_rule_id_list != []:
                                     del parent_rule_id_list[p_id_list_len2 - 1]

                             else:

                                 p_id_list_len2 = len(parent_rule_id_list)
                                 if parent_rule_id_list != []:
                                     del parent_rule_id_list[p_id_list_len2 - 1]
                                 ifcounter = ifcounter - 1
                         else:

                             p_id_list_len2 = len(parent_rule_id_list)
                             if parent_rule_id_list != []:
                                 del parent_rule_id_list[p_id_list_len2 - 1]
                             ifcounter = ifcounter - 1

                         #TEMP_METADATA[0]["parent_rule_id"] = ",".join(parent_rule_id_list)
                         # METADATA.append(TEMP_METADATA[0])
                         if TEMP_METADATA != []:
                             for temp_data in TEMP_METADATA:
                                 METADATA.append(temp_data.copy())
                         TEMP_METADATA.clear()
                     ##print("6",line)
                     loopNumber = 0
                     paravaluesplit = paravalue.split()

                     if paravalue.__contains__("PERFORM"):
                             paravalue = re.sub("PERFORM", " ", paravalue)
                             paravalue=paravalue.split()
                             if paravalue!=[]:
                                 paravalue=paravalue[0]
                     METADATA.append({'s_no': '', 'pgm_name': programName,
                                      'fragment_Id': rule_id,
                                      'para_name': paravalue, 'source_statements': line, 'statement_group': statement_value,
                                      'rule_category': catg_value,
                                      'parent_rule_id': ",".join(parent_rule_id_list), 'business_documentation': ''})
                     ##print('66',line)
                     RC6 = RC6 + 1

                     if  end_sub_regexx != None:

                         parent_rule_id_list = []

                     if return_regexx!=None:

                         p_id_list_len2 = len(parent_rule_id_list)
                         if parent_rule_id_list != []:
                             del parent_rule_id_list[p_id_list_len2 - 1]

                     continue
               elif(loopNumber==96):
                   ##print('7',line)
                   Group=""
                   statement=""
                   else_flag_1 = False
                   splitline = line.split('$')
                   line = splitline[0]
                   Other_Action="Other Action"

                   if line.__contains__("END-IF") or line.__contains__("END-NOREC") or line.__contains__("END ") or line.__contains__("DO ") or line.__contains__("DOEND"):
                       statement= "Technical Action"
                       Group="No Operation"

                   elif line.__contains__(":="):
                       statement="Business Action"
                       Group="Assignment"

                   if len(splitline) == 1:
                       paravalue = ""
                   else:
                       paravalue = splitline[1]

                   paravalue = paravalue.strip()
                   if doend_regexx!=None or doend_flag:

                       if doend_regexx!=None and doend_flag:
                           None
                       else:
                           do_counter = do_counter + 1

                       if doend_flag and doend_regexx!=None:


                           if (doend_regexx != None):


                               firstparavalue = firstparavalue.strip()
                               paravalue = paravalue.strip()

                               if firstparavalue == paravalue:

                                   if ifcounter == 1:
                                       p_rule_id = ""
                                       ifcounter = 0
                                       p_id_list_len2 = len(parent_rule_id_list)
                                       if parent_rule_id_list != []:
                                           del parent_rule_id_list[p_id_list_len2 - 1]

                                   else:

                                       p_id_list_len2 = len(parent_rule_id_list)
                                       if parent_rule_id_list != []:
                                           del parent_rule_id_list[p_id_list_len2 - 1]
                                       ifcounter = ifcounter - 1
                               else:

                                   p_id_list_len2 = len(parent_rule_id_list)
                                   if parent_rule_id_list != []:
                                       del parent_rule_id_list[p_id_list_len2 - 1]
                                   ifcounter = ifcounter - 1

                       elif doend_flag:

                                   p_id_list_len2 = len(parent_rule_id_list)
                                   if parent_rule_id_list != []:
                                       del parent_rule_id_list[p_id_list_len2 - 1]
                                   ##print(parent_rule_id_list)
                                   ifcounter = ifcounter - 1

                       doend_flag = True

                       TEMP_METADATA.append({'s_no': '', 'pgm_name': programName,
                                        'fragment_Id': '',
                                        'para_name': paravalue, 'source_statements': line, 'statement_group': Group,
                                        'rule_category': statement,
                                        'parent_rule_id': ",".join(parent_rule_id_list), 'business_documentation': ''})

                       continue

                   if TEMP_METADATA!=[]:

                       for  temp_data in TEMP_METADATA:
                          METADATA.append(temp_data.copy())


                   # if TEMP_METADATA!=[]:
                   #     #db.bre_rules_report.insert_many(TEMP_METADATA)
                   #     METADATA.append(TEMP_METADATA[0])


                   if paravalue.__contains__("PERFORM"):
                       paravalue = re.sub("PERFORM", " ", paravalue)
                   paravalue = paravalue.strip()
                   METADATA.append({'s_no': '', 'pgm_name': programName,
                                    'fragment_Id': '',
                                    'para_name': paravalue, 'source_statements': line, 'statement_group': Group,
                                    'rule_category': statement,
                                    'parent_rule_id': ",".join(parent_rule_id_list), 'business_documentation': ''})

                   # parent ID


                   if endifregexx != None or end_rec_regexx!=None or (doend_regexx!=None and else_flag):
                       else_flag=False
                       firstparavalue = firstparavalue.strip()
                       paravalue = paravalue.strip()

                       if firstparavalue == paravalue:

                           if ifcounter == 1:
                               p_rule_id = ""
                               ifcounter = 0
                               period_flag = False
                               p_id_list_len2 = len(parent_rule_id_list)
                               if parent_rule_id_list != []:
                                   del parent_rule_id_list[p_id_list_len2 - 1]

                           else:

                               p_id_list_len2 = len(parent_rule_id_list)
                               if parent_rule_id_list != []:
                                   del parent_rule_id_list[p_id_list_len2 - 1]
                               ifcounter = ifcounter - 1
                       else:

                           p_id_list_len2 = len(parent_rule_id_list)
                           if parent_rule_id_list != []:
                               del parent_rule_id_list[p_id_list_len2 - 1]
                           ifcounter = ifcounter - 1


                   end_decide_regexx1 = re.match('^\s*END-DECIDE\s*', line)

                   if end_decide_regexx1!=None:

                        p_id_list_len2 = len(parent_rule_id_list)
                        if parent_rule_id_list != []:
                            del parent_rule_id_list[p_id_list_len2 - 1]

                        if parent_rule_id_list != []:
                            del parent_rule_id_list[p_id_list_len2 - 2]

                   loop_regexx=re.match('^\s{1}LOOP.*',loop_line)


                   if loop_regexx !=None :

                       parent_rule_id_list=[]

         if TEMP_METADATA != []:
             for temp_data in TEMP_METADATA:
                 METADATA.append(temp_data.copy())
         TEMP_METADATA.clear()

        #
        os.remove("Copy_Expanded_Data.txt")
        os.remove("Duplicatefile1" + str(i) + '.txt')
        os.remove("Duplicatefile0" + str(i) + '.txt')
        os.remove("Duplicatefile2" + str(i) + '.txt')
        os.remove("Duplicatefile3" + str(i) + '.txt')
        os.remove("Duplicatefile4" + str(i) + '.txt')
        #os.remove("output" + str(i) + '.txt')

        times = 10
        for num in range(times):
            os.remove("FinalFile" + str(num) + str(i) + '.txt')
    except Exception as e:
        from datetime import datetime
        exc_type, exc_obj, exc_tb = sys.exc_info()
        fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
        print(exc_type, fname, exc_tb.tb_lineno)
        f.write(str(datetime.now()))
        f.write('\n' + str(exc_type) + '\n' + fname + '\n' + str(
            exc_tb.tb_lineno) + '\n' + '***********************************' + '\n')
        pass

def Db_Insert(METADATA):
    ##print(METADATA)
    UpdateCounter = 0
    UpdateCounter = UpdateCounter + 1
    db_data = {"data": METADATA,
               "headers": ['s_no', 'pgm_name', 'fragment_Id', 'para_name', 'source_statements', 'statement_group',
                           'rule_category', 'parent_rule_id', 'business_documentation']}

    try:
        keys = list(db_data.keys())
        #print('parent keys', keys)

        if 'data' in keys:
            # fetching headers
            x_BRE_report_header_list = db_data['headers']
            #print('COBOL Report header list', x_BRE_report_header_list)
            # Adding header field to db_data
            db_data['headers'] = x_BRE_report_header_list

            if len(db_data['data']) == 0:
                #print({"status": "failure", "reason": "data field is empty"})
                pass
            else:
                # Delete all COBOl associated records in the table
                previousDeleted = False
                try:
                  if UpdateCounter == 1000000:
                    if db.bre_rules_report.delete_many(
                            {"type": {"$ne": "metadata"}}).acknowledged:
                        #print('Deleted all the COBOL components from the x-reference report')
                        previousDeleted = True
                        #print('--------just deleted all de cobols')
                    else:
                        #print('Something went wrong')
                        #print({"status": "failed",
                               #"reason": "unable to delete from database. Please check in with your Administrator"})
                        #print('--------did not deleted all de cobols')
                        pass
                except Exception as e:
                    from datetime import datetime
                    exc_type, exc_obj, exc_tb = sys.exc_info()
                    fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
                    print(exc_type, fname, exc_tb.tb_lineno)
                    f.write(str(datetime.now()))
                    f.write('\n' + str(exc_type) + '\n' + fname + '\n' + str(
                        exc_tb.tb_lineno) + '\n' + '***********************************' + '\n')
                    pass





                if previousDeleted  or UpdateCounter ==1:

                    try:

                        db.bre_rules_report.insert_many(db_data['data'])
                        #print('db inserteed bro')
                        import datetime
                        # updating the timestamp based on which report is called
                        current_time = datetime.datetime.now(tz=tz).strftime("%A, %d. %B %Y %I:%M%p")
                        # Setting the time so that we know when each of the JCL and COBOLs were run

                        # db.cross_reference_report.insert_one({"type":"metadata", "JCL":{"last_updated_on":ct},"COBOL":{"last_updated_on":ct}})

                        if db.bre_rules_report.count_documents({"type": "metadata"}) > 0:
                            #print('meta happen o naw',
                                  db.bre_rules_report.update_one({"type": "metadata"},
                                                                  {"$set": {
                                                                      "BRE.last_updated_on": current_time,
                                                                      "BRE.time_zone": time_zone,
                                                                      "headers": x_BRE_report_header_list
                                                                  }},upsert=True)
                        else:
                            db.bre_rules_report.insert_one(
                                {"type": "metadata",
                                 "COBOL": {"last_updated_on": current_time, "time_zone": time_zone},
                                 "headers": x_BRE_report_header_list})

                        #print(current_time)
                        #print({"status": "success", "reason": "Successfully inserted data and "})
                    except Exception as e:
                        from datetime import datetime
                        exc_type, exc_obj, exc_tb = sys.exc_info()
                        fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
                        print(exc_type, fname, exc_tb.tb_lineno)
                        f.write(str(datetime.now()))
                        f.write('\n' + str(exc_type) + '\n' + fname + '\n' + str( exc_tb.tb_lineno) + '\n' + '***********************************' + '\n')
                        pass

    except Exception as e:
        from datetime import datetime

        exc_type, exc_obj, exc_tb = sys.exc_info()
        fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
        print(exc_type, fname, exc_tb.tb_lineno)
        f.write(str(datetime.now()))
        f.write('\n' + str(exc_type) + '\n' + fname + '\n' + str(
            exc_tb.tb_lineno) + '\n' + '***********************************' + '\n')
        pass

def Id_Division(filename):
    try:

            filename=filename.split('\\')
            filelength=len(filename)
            Temp_ID=filename[filelength-1]
            #print(Temp_ID[:-3])
            PGM_ID.append(Temp_ID[:-3])
    except Exception as e:
        from datetime import datetime
        exc_type, exc_obj, exc_tb = sys.exc_info()
        fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
        print(exc_type, fname, exc_tb.tb_lineno)
        f.write(str(datetime.now()))
        f.write('\n' + str(exc_type) + '\n' + fname + '\n' + str(
            exc_tb.tb_lineno) + '\n' + '***********************************' + '\n')
        pass

def isComment(line):
   try:
     if line[0:1] == '*':
      return True
     else:
      return False
   except Exception as e:
       from datetime import datetime
       exc_type, exc_obj, exc_tb = sys.exc_info()
       fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
       print(exc_type, fname, exc_tb.tb_lineno)
       f.write(str(datetime.now()))
       f.write('\n' + str(exc_type) + '\n' + fname + '\n' + str(
           exc_tb.tb_lineno) + '\n' + '***********************************' + '\n')
       pass

def read_lines(i):
    begin="DEFINE"
    end="END-SUBROUTINE"
    dict = OrderedDict()
    dict_dead = OrderedDict()
    flag = False
    data = []
    file_handle = open("Duplicatefile0"+str(i)+".txt", "r")
    fun_name = ''
    count = 0
    define_counter = 0
    storage = []
    begin_counter = 0
    for line in file_handle:
        ##print("Copy_expanded lines:",line)
        try:
            #if len(line) > 8:

                #line = line[:72]
                ##print("Copy_expanded lines:", line)
                if line[0] == '*':
                    ##print("Commented_lines:",line)
                    continue
                if line.strip().startswith('/*'):
                    continue
                if line.strip() =="":
                    continue


                else:

                    ##print("Copy_expanded lines:", line)
                    if (re.search(end, line)  or re.search("DEFINE SUBROUTINE.*",line)) : # counting lines
                        if (re.search("DEFINE SUBROUTINE.*",line) and define_counter >= 1):

                                pass
                        # if define_counter == 1:
                        #     continue

                        # #print('end number', index)
                        ##print(dict)
                        else:

                            storage.append(line.replace('\n','')+"               $"+fun_name)
                            dict[fun_name] = copy.deepcopy(storage)

                            storage.clear()
                            define_counter = define_counter + 1
                            fun_name = " "
                            dict_dead[fun_name] = count
                            count = 2

                            flag = False
                            #  #print(line + '------------------------------------------')
                    if flag:
                        count = count + 1
                        storage.append(line.replace('\n','').rstrip()+"               $"+fun_name)

                    if (re.search(begin, line)):

                        if re.search("DEFINE DATA",line) or re.search("REDEFINE",line) or re.search("DEFINE WINDOW",line) :
                            continue
                        ##print(line)
                        else:
                            flag = True
                            new_line1 = line.split()
                            temp_fun_name = new_line1[-1]
                            if new_line1[-2].__contains__("/*"):
                                fun_name = new_line1[-3]

                            else:
                                fun_name = temp_fun_name



        except Exception as e:
            from datetime import datetime
            exc_type, exc_obj, exc_tb = sys.exc_info()
            fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
            print(exc_type, fname, exc_tb.tb_lineno)
            f.write(str(datetime.now()))
            f.write('\n' + str(exc_type) + '\n' + fname + '\n' + str(
                exc_tb.tb_lineno) + '\n' + '***********************************' + '\n')
            pass
    #print("Correct:", json.dumps(dict, indent=4))
    return dict

main()
f.close()