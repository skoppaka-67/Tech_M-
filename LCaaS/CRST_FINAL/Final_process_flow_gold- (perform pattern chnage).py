Version="CRST V1"
import re , os ,glob ,copy , xlsxwriter, requests , json ,config_crst
from collections import OrderedDict
#PROGRAM VARIABLES
Program_Name=""
file_name=""
Goto_Name ="False"
Current_Division_Name=""
PGM_ID=[]
Old_Division_Name=""
add=""
Call_Name=[]
Module_Name=[]
modulelinenumberdict = {}
Module_Line_Number=[]
Copy_Name=[]
Variables=[]
Temp_Line=[]
Perform_St=[]
paravalue=[]
Index=0
Index_Val=0
line_Var=""
b=0
Key_List=[]
Value_list=[]
Temp_Mod=[]
Temp_Mod1=[]
Temp_List=[]

Prev_Mod=""
Current_Mod=""

Prev_Len=0
OutputDict={}
Module_Dict = {}
MainList=[]
MainDict={}
CallName=[]
CopyName=[]
TempCopyName=[]
TempCallName=[]
jsonDict={}
ParaList=[]
ProgramflowList=[]
finaldeadparalist2=[]
deaddict={}

DeadDictFinal={}
master_dead = set()
master_alive = set()


def External_program(paradict):
    Call_List = []

    for name in Call_Name:
        Call_List.append(name.replace("CALL","").replace(" ",""))
        Call_List.append(name.replace("CALL","").replace(" ",""))


    for k,v in paradict.items():
        for dict in v:
            if dict['to'] in Call_List:
                dict['to'] =  dict['to'].replace("'","")
                dict['name'] = "External_Program"



def main(file_name):
    Module_Dict = {}
    declare=False
    Old_Division_Name = ""


    Program_Name=open(file_name)

    for line1 in Program_Name.readlines():
        line1=line1[6:].upper()
        line1 = line1.replace('\x0c', '')
        b= IsDivision(line1)
        #print("asdf",b)
        if b==0:

            break
        else:
            continue
    Program_Name.close()

    print("gg",filename)

    textfile = open(filename)
    another_file = open("another_file.txt", 'w')
    #Fixing the G-- module, Adding perform statements.

    lines = textfile.readlines()
    module_list = []
    for line in reversed(lines):
        line = line[6:72]
        module = re.findall(r'^\s[A0-Z9].*[-]*.*[.]', line, re.IGNORECASE)
        if module != []:
            if module[0].strip().startswith('G--'):
                module_list.append(module[0])
            else:
                for m in module_list:
                    another_file.write("     PERFORM " + m + '   ' + '\n')
                module_list = []
        another_file.write(line + '\n')
    textfile.close()
    another_file.close()


    with open("another_file.txt") as input_data:

                lines1 = input_data.readlines()
                for line in reversed(lines1):
                    line=line.upper()
                    line = line.replace('\x0c', '')
                    try:
                        if line.startswith("*"):
                            continue
                        else:
                            copyfile = open("Expanded_Data.txt", "a")

                            # if not line[5] == 'd' or line[5] == 'D':

                            line_list = line.split()

                            # lines_list4=line.split()
                            for iter in line_list:
                                if iter.upper().__contains__("COPY"):
                                    var = (len(line_list))

                                    if var >= 2:
                                        #print(line_list[var - 1])
                                        if line_list[var - 1].__contains__('"'):

                                            copyname = line_list[var - 1].replace('"', "")
                                            copyname = copyname[:-1]
                                            # print("lll",file_location1)
                                            Copyfilepath = code_location + '\\' + "COPYBOOK" + '\\' + copyname
                                            # print(Copyfilepath)

                                        else:
                                            copyname = line_list[1].replace('"', "")
                                            # copyname = copyname[:-1]
                                            Copyfilepath = code_location + '\\' + "COPYBOOK" + '\\' + copyname

                                        # if copyname.__contains__(","):
                                        #     copyname_list = copyname.split(",")
                                        #
                                        #     var = len(copyname_list)
                                        #     copyname = copyname_list[var-1]
                                        #     copyname = copyname_list[var-1]


                                        if os.path.isfile(Copyfilepath):
                                            tempcopyfile = open(Copyfilepath, "r")
                                            copyfile.write("#########" + " " + "BEGIN" + " " + copyname + '\n')
                                            for copylines in tempcopyfile.readlines():
                                                    if copylines[0]=='*':
                                                        continue
                                                    else:
                                                        copyfile.write(copylines[6:].replace('\x0c','') + '\n')
                                            copyfile.write("#####" + " " + " END" + "####" + '\n')

                            copyfile.write(line)

                        copyfile.close()

                    except Exception:

                        pass

    # Temp_File=open("Expanded_Data.txt", "w+")
    # Program_Name=open(file_name)
    # for line2 in Program_Name.readlines():
    #
    #     line2=Cut_Line(line2,b)
    #
    #     if isComment(line2):
    #          continue
    #     else:
    #         copy=re.findall(r'^\s*COPY\s.\S*',line2)
    #
    #         include=re.findall(r'^\s*[+][+]INCLUDE.*',line2)
    #         #print("include",include)
    #         if copy==[] and  include==[]:
    #             Copy_Expand(line2,Temp_File)
    #         elif copy!=[] or include!=[]:
    #
    #
    #
    #
    #
    #
    #
    #             # Index_Val = 0
    #             #
    #             # Copy_Fun(copy,include)
    #             # Temp_copy=line2.split()
    #             # copy_Name=Temp_copy[1]
    #             #
    #             # copywithdot=re.match(".*[.]",copy_Name)
    #             #
    #             # if copywithdot==None:
    #             #  copy_Name1=copy_Name+"."+"CPY"
    #             #  finalcopyname= os.path.exists(CopyPath)
    #             #
    #             # if copywithdot!=None:
    #             #  copy_Name1 = copy_Name+"CPY"
    #             #  finalcopyname=os.path.exists(CopyPath)
    #             #
    #             # #print(copy_Name1)
    #             #
    #             # try:
    #             #  Temp_File2= open(os.path.join(CopyPath,copy_Name1), "r")
    #             #
    #             #  for line3 in Temp_File2.readlines():
    #             #    # print(line3)
    #             #    Temp_File1=line3.split()
    #             #    #print(Temp_File1)
    #             #    if len(Temp_File1)==1:
    #             #        continue
    #             #    Temp_index=Temp_File1[1]
    #             #    #module = re.findall(r'^\s{1}[A0-Z9].*[-]*.*[.]', line)
    #             #    module=re.findall(r'^[A0-Z9]*[-].*[.]',Temp_File1[1])
    #             #    if Temp_File1[1]=="01":
    #             #        Temp_File1_Len=len(Temp_File1[0])
    #             #        Temp_String=line3[Temp_File1_Len:]
    #             #        Temp_String1=Temp_String.split()
    #             #        Index=Temp_String.index(Temp_String1[0])
    #             #        Index=Index+Temp_File1_Len-1
    #             #        Index_Val=Index
    #             #        Temp_Line1=line3[Index_Val:]
    #             #        break
    #             #    elif Temp_index[0]=="*":
    #             #        Index=line3.index(Temp_File1[1])
    #             #        Index_Val=Index
    #             #        Temp_Line1=line3[Index_Val:]
    #             #        break
    #             #    elif module!=[]:
    #             #        if(Temp_File1[1]=="END-EVALUATE."):
    #             #            continue
    #             #        else:
    #             #           Index=line3.index(Temp_File1[1])
    #             #           Index_Val=Index-1
    #             #           Temp_Line1=line3[Index_Val:]
    #             #           break
    #             #
    #             #  if Index_Val!=0:
    #             #     Temp_File1= open(os.path.join(CopyPath,copy_Name1), "r")
    #             #     Temp_File=open("Expanded_Data.txt", "a+")
    #             #     for line4 in Temp_File1.readlines():
    #             #        Temp_Line1=line4[Index_Val:]
    #             #        Temp_File.write(Temp_Line1)
    #             #        Temp_File.write("\n")
    #             # except IOError:
    #             #     continue
    # Temp_File.close()
    # Program_Name.close()
    input_data.close()
    Program_Name=open("Expanded_Data.txt")
    r=0
    flaggy = False
    rare_goto_list = []
    rare_goto_flag = False
    for number , line in enumerate(Program_Name):
            # print("Program Name:",Program_Name)

            if line.strip() =="":
                continue
            if rare_goto_flag:
                rare_goto_list.append(line)
                rare_goto_flag = False
                line = ' '.join(rare_goto_list)

                rare_goto_list.clear()

            if line.split()[-1] == "TO" and line.split()[-2] == "GO":
                rare_goto_flag = True
                rare_goto_list.append(line.replace('\n', ""))
                continue

            if isComment(line):
               continue
            else:

             Current_Division_Name = Current_Division(line)
             if Current_Division_Name==None:
               if Old_Division_Name=="IDENTIFICATION DIVISION" or Old_Division_Name=="ID DIVISION":

                   Id_Division(line,file_name)

               elif Old_Division_Name=="ENVIRONMENT DIVISION":
                   Envi_Division(line)

               elif Old_Division_Name =="DATA DIVISION":
                   Data_Division(line)

               elif Old_Division_Name=="PROCEDURE":

                   r=r+1
                   Declarative = re.findall(r'^\s*DECLARATIVES[.]\s*', line,re.IGNORECASE)
                   EndDeclarative = re.findall(r'^\s*END\s*DECLARATIVES[.]\s*', line,re.IGNORECASE)
                   if Declarative != []:
                       declare = True
                   if EndDeclarative != []:
                       declare = False
                   if declare:
                       continue
                   else:
                       if EndDeclarative == []:
                          #print("flagy")
                          flaggy=Proc_Division(line, r, number,flaggy)


             else:
               Old_Division_Name = Current_Division_Name

    if line!="":
       Module_Dict,sec_list = Output(line)
    Program_Name.close()
    #os.remove("Expanded_Data.txt")
    return Module_Dict,sec_list




def Copy_Expand(line,Temp_File):
    Temp_File.write(line)
    Temp_File.write("\n")

def IsDivision(line1):
    Temp_Line = line1
    if Temp_Line[0:14] == "IDENTIFICATION" or Temp_Line[0:2]== "ID":
        Index=line1.index(Temp_Line[0:14])
        Index=Index
        return Index
    else:
        return False
def Cut_Line(line,b):
    line=line[b:]

    return line
def isComment(line):

    if line[0:1]=='*':
        return True
    else:
         return False
def Current_Division(line):

    if line[1:23]=="IDENTIFICATION DIVISION" or line[1:3]=="ID":
        Current_Division_Name="IDENTIFICATION DIVISION"

        return Current_Division_Name
    elif line[1:20]=="ENVIRONMENT DIVISION":
        Current_Division_Name="ENVIRONMENT DIVISION"
        return Current_Division_Name
    elif line[1:13]=="DATA DIVISION":
        Current_Division_Name="DATA DIVISION"
        return Current_Division_Name

    elif line[1:9]=="PROCEDURE" or line[1:10]=="PROCEDURE":
        Current_Division_Name="PROCEDURE"
        return Current_Division_Name
    else:
        Current_Division_Name=None
        return Current_Division_Name
def Id_Division(line,file_name):
    #print("ffffffffff",line)
    if line[1:11] == "PROGRAM-ID":
        print("Winnnnnn")
        Temp_ID = line[11:65]
        # TempID=Temp_ID.strip()
        # if TempID=="":
        file_name = file_name.split('\\')
        file_name = file_name[len(file_name) - 1]
        file_name = file_name.split('.')
        file_name = file_name[0]
        # print(file_name)
        PGM_ID.append(file_name)
        # if TempID!="":
        #     TempID = TempID.split('.')
        #     PGM_ID.append(TempID[0])
    elif line.__contains__("PROGRAM-ID"):

            print("JK:",line)
            line = line.strip()
            if line[0:10] == "PROGRAM-ID":
                file_name = file_name.split('\\')
                file_name = file_name[len(file_name) - 1]
                file_name = file_name.split('.')
                file_name = file_name[0]
                # print(file_name)
                PGM_ID.append(file_name)
        # print("Line:",line)
        # line = line.lstrip()
        # if line[0:10] ==
                print("Successs")

def Envi_Division(line):
    return None
def Data_Division(line):

    Temp_Variable=re.findall(r'.*PIC.*',line,re.IGNORECASE)
    if Temp_Variable!=[]:
       Temp_Variable1=re.findall(r'.*FILLER.*',line,re.IGNORECASE)
       if isFiller(Temp_Variable1):
           return
       else:
          Temp_Value=Temp_Variable[0]
          Temp_Value=Temp_Value[0:].strip()
          Variables.append(Temp_Value)
    copy=re.findall(r'^\s*COPY.\S*',line)
    include = re.findall(r'^\s*[+][+]INCLUDE.*', line)
    Copy_Fun(copy,include)
def Proc_Division(line,r,number,Goto_Name):
    module = re.findall(r'^\s[A0-Z9].*[-]*.*[.]', line,re.IGNORECASE)
    #print(line)
    if(module!=[]):
     #print(module)
     #print("Module_Name:",module)
     Temp_Proc=module[0]
     #print("TEmp_Proc:",Temp_Proc)
     Temp_Val=Temp_Proc[0:].strip()
     #print("Temp_Val:",Temp_Val)
     if Temp_Val[0:1]=="D ":
        return
     else:
        splitwithspace=Temp_Val.split()
        Temp_Val=Temp_Val.split('.')
        Temp_Val=Temp_Val[0]

        # spliting with space and finding the section.

        if len(splitwithspace) != 1 and splitwithspace[1] == "SECTION.":
            Temp_Val=splitwithspace[0]+'@SECTION'
        Temp_Val = re.sub('["\s"]','-', Temp_Val)

        Module_Name.append(Temp_Val)
        Module_Line_Number.append(number)

        Perform_St.append(Temp_Val)


    elif(module==[]):
      call=re.findall(r'^\s*CALL\s.*',line,re.IGNORECASE)

      copy=re.findall(r'^\s*COPY.\S*',line,re.IGNORECASE)

      Perform = re.findall(r'^\s*PERFORM[\s]{1}\s*[A0-Z9].*', line,re.IGNORECASE)

      Goto=re.findall(r'.*\s*[^"].GO[\s]{1}\s*TO\s*.*',line,re.IGNORECASE)

      Inprocedure=re.findall(r'^\s*INPUT\s*PROCEDURE\s.*',line)

      Outprocedure=re.findall(r'^\s*OUTPUT\s*PROCEDURE\s.*',line)

      include = re.findall(r'^\s*[+][+]INCLUDE.*', line)

      if(call!=[]):

       Temp_Call=call[0].split()[1]
       if Temp_Call=="PROGRAM":
          Temp_Call=call[0].split()[2]
       Temp_Val=Temp_Call.replace('"',"")
       Temp_Val=Temp_Val.replace(',','')

      elif(copy!=[] or include!=[]):
        Copy_Fun(copy,include)
      elif(Perform!=[]):
         
          Temp_Perform=Perform[0]
          Temp_Per=Temp_Perform[0:].strip()

          l =Temp_Per.index("PERFORM ")

          Temp_Per=Temp_Per[l:]
          Temp_Per1=Temp_Per.split()

          if len(Temp_Per1)==1:
              return
          elif Temp_Per1[1]=="VARYING"or Temp_Per1[1]=="UNTIL":
              return
          else:

            if len(Temp_Per1)>2:
                if Temp_Per1[2]=="VARYING" :

                    Temp_Per=Temp_Per.split("VARYING")[0]


                elif Temp_Per1[2]=="UNTIL":

                    Temp_Per = Temp_Per.split("UNTIL")[0]


            Temp_Per=Temp_Per.split('.')

            Temp_Per=Temp_Per[0]

            Perform_St.append(Temp_Per.replace(',',''))

      elif(Goto!=[] or Goto_Name == "True"):
         if Goto_Name == "True":
              Goto_Value = line.strip()
              Perform_St.append(Goto_Value)
              Goto_Name = "False"
              return Goto_Name
         Temp_Goto=Goto[0]
         Temp_Goto = Temp_Goto[0:].strip()

         K = Temp_Goto.index("GO ")

         Temp_Goto = Temp_Goto[K:]

         Temp_Goto1 = Temp_Goto.split()
         if len(Temp_Goto1) == 1:
             return
         else:
             Temp_Goto = Temp_Goto.split('.')
             Temp_Goto = Temp_Goto[0]
             Temp_Goto_space=Temp_Goto.split()
             if len(Temp_Goto1) == 2 and (Temp_Goto_space[0] == "GO" and Temp_Goto_space[1] == "TO"):
                 Goto_Name = "True"
                 return Goto_Name
             if len(Temp_Goto1 ) > 2:
              if (Temp_Goto_space[0]=="GO" and Temp_Goto_space[1]=="TO"):
                 Temp_Goto_name=Temp_Goto_space[2]
                 #if Temp_Goto_name !="EOJ":
                 Temp_Goto_subtituted="PERFORM"+" "+Temp_Goto_name
                 Perform_St.append(Temp_Goto_subtituted.replace(',',''))

      elif(Inprocedure!=[]):
          Temp_inProcedure=Inprocedure[0]
          Temp_inProcedure=Temp_inProcedure.split()
          if len(Temp_inProcedure) == 1:
              return
          else:
              if(Temp_inProcedure[0]=="INPUT" and Temp_inProcedure[1]=="PROCEDURE"):
                 Temp_inProcedure_name=Temp_inProcedure[2]
                 Temp_inProcedure_name = "PERFORM" + " " + Temp_inProcedure_name
                 Perform_St.append(Temp_inProcedure_name)
      elif (Outprocedure!= []):
          Temp_outProcedure = Outprocedure[0]
          Temp_outProcedure = Temp_outProcedure.split()
          if len(Temp_outProcedure) == 1:
              return
          else:
              if (Temp_outProcedure[0] == "OUTPUT" and Temp_outProcedure[1] == "PROCEDURE"):
                  Temp_outProcedure_name = Temp_outProcedure[2]
                  Temp_outProcedure_name = "PERFORM" + " " + Temp_outProcedure_name
                  Perform_St.append(Temp_outProcedure_name)





def isFiller(Temp_Variable1):
    if(Temp_Variable1!=[]):
          return True
    else:
          return False
def Copy_Fun(copy,include):
    if(copy!=[]):
        Temp_Copy=copy[0]
        Temp_Val=Temp_Copy[0:].strip()
        Copy_Name.append(Temp_Val)
    elif(include!=[]):
        Temp_include= include[0]
        Temp_Val = Temp_include[0:].strip()
        Copy_Name.append(Temp_Val)


def isContinue(line):
    if(line[6]=='-'):
        return True
    else:
        return False
def Last_Pt(c):


    if c==len(Module_Name):

        Temp_List[c-1]=Value_list.copy()
        Value_list.clear()





def Output(line):
  #  print()
    for numbers in range(len(Module_Name)):
        modulelinenumberdict[Module_Name[numbers]] = Module_Line_Number[numbers]
    empty_list=[]
    ProgNameLen=len(PGM_ID)-1
    # print(ProgNameLen)
    #print('Program_ID:',PGM_ID[ProgNameLen])
 #  print()
    for element in Module_Name:
          None
    for element in Copy_Name:
        element=element.split()
    TempCopyName=copy.deepcopy(CopyName)
    for element in Call_Name:
        element=element.split()
    TempCallName=copy.deepcopy(CallName)
    c=0
    Current_Mod=""
    print("GGGGGGGGGGGG",Perform_St)
    if Perform_St!=[]:
     Temp_perform=Perform_St[0]
     Temp_perform=Temp_perform.split()
     if Temp_perform[0]=="PERFORM":
         Perform_St.insert(0,"00-MAIN")
         Module_Name.insert(0,"00-MAIN")
     for element in range(len(Module_Name)):
         empty_list = []
         Temp_List.append(empty_list)

     for element in Module_Name:
         d=0
         for element1 in Perform_St:
           Temp_Mod = element1.split()
           if Module_Name[c]==Perform_St[d] or Module_Name[c]==Current_Mod:
              if Module_Name[c]==Perform_St[d]:
                Current_Mod=Perform_St[d]
              elif Temp_Mod[0]=="PERFORM":
                 Value_list.append(Temp_Mod[1])
              elif len(Temp_Mod)==1:
                  Temp_List[c]=Value_list.copy()
                  Value_list.clear()
                  break
           d=d+1
         c=c+1
         Last_Pt(c)
    # print( "gggggggggggggggggggggggggggggggg",Temp_List)
    outputlist=[]
    outputlist1=[]

  ######################################################################################
  # Deleting the duplicates in the list.

    for listvalue  in Temp_List:
        outputlist=[]
        if listvalue == []:
            outputlist1.append(listvalue)
            continue
        for x in listvalue:
            if x not in outputlist and x!=[]:
                outputlist.append(x)
            copylist=copy.deepcopy(outputlist)
        outputlist1.append(copylist)
    print(outputlist1)

  #########################################################################################

    i=iter(Module_Name)
    j=iter(outputlist1)
    k=list(zip(i,j))
    #print("KKKKKKKKKKKKK:",k)

    Module_Dict1={}
    for (x,y) in k:
            Module_Dict1[x]=y

    list1=[]
    list2=[]
    list4=[]
    list5=[]

    for i,j in Module_Dict1.items():
        list4.append(i)
        list5.append(j)


    section_dict={}
    #first_section_name=list4[0]
    para_list_in_section=[]
    section_name=""
    len_of_list4=len(list4)
    r=0
    for data1 in list4:

        r=r+1
        # Added SXIT logic for CRST.

        if data1.__contains__('@SECTION') or data1.__contains__('--SXIT'):
            if section_name!="" :
                section_dict[section_name]=para_list_in_section

            section_name=data1
            para_list_in_section=[]
            continue
        else:
            if data1.startswith('G--'):
                continue
            para_list_in_section.append(data1)

        if r==len_of_list4:
            section_dict[section_name] = para_list_in_section


    for my,value in section_dict.items():

        if my=="":
            continue

        if Module_Dict1[my]!=[]:
          i = Module_Dict1[my]

          Module_Dict1[my]=value+i
        else:
            Module_Dict1[my]=value


    for i, j in Module_Dict1.items():
        if i.__contains__('@SECTION'):
             i=i.replace("@SECTION","")
        list1.append(i)
        list2.append(j)

    print("List1:",list1)
    print("List2:",list2)
    #
    # print("dicy1",Module_Dict1)

    perform_file2=open("Expanded_Data.txt")

    # finding and eliminating the dead section data.

    eliminate_list=[]

    section_list=[]

    rare_goto_flag=False

    rare_goto_list=[]
    pd_flag=False
    for t in perform_file2.readlines():
        if t.strip()=="":
            continue

        if rare_goto_flag:
            rare_goto_list.append(t)
            rare_goto_flag = False
            t = ' '.join(rare_goto_list)

            rare_goto_list.clear()

        if t.split()[-1] == "TO" and t.split()[-2] == "GO":
            rare_goto_flag = True
            rare_goto_list.append(t.replace('\n', ""))
            continue

        Perform = re.findall(r'^\s*PERFORM[\s]{1}\s*[A0-Z9].*', t,re.IGNORECASE)

        Goto = re.findall(r'.*\s*[^"].GO[\s]{1}\s*TO\s.*', t,re.IGNORECASE)
        module = re.findall(r'^[A0-Z9].*[-]*.*[.]', t,re.IGNORECASE)


        if Perform!=[]:

            if t.split()[1]!="VARYING" or t.split()[1]!="UNTIL":

                     l = Perform[0].index("PERFORM ")

                     perform=Perform[0][l:].strip().split()[1]

                     if perform.strip().endswith('.'):

                        eliminate_list.append(perform[:-1])
                     else:
                         eliminate_list.append(perform)
        if Goto != []:

            if len(t.split())>2:

                l = Goto[0].index("GO ")

                goto=Goto[0][l:].strip().split()[2]

                if goto.strip().endswith('.'):

                     eliminate_list.append(goto[:-1])
                else:
                    eliminate_list.append(goto)



        if t.__contains__("PROCEDURE") and t.__contains__("DIVISION"):
            pd_flag=True
        if module!=[] and pd_flag:
            if module[0].__contains__(" SECTION"):

                section_list.append(t.strip().split()[0])


    outp_is=set(section_list)-set(eliminate_list)


    perform_file2.close()


    Module_Dict2 = dict(zip(list1,list2))


    for h in outp_is:

        if h!="MAIN-LOGIC":
          try:

            del Module_Dict2[h]
            #print("deleed")
          except Exception:
              continue 
              
    #Module_Dict = {k: v for k, v in Module_Dict2.items() if  ((len(k) > 4) or (len(k) == 4 and k.isalpha()))}


    print("gg", Module_Dict2)
    ParaList.append(Module_Dict2)
    #print(Module_Dict)
    data(TempCallName,TempCopyName, Module_Dict2)
    NoOfPrg=len(PGM_ID)
    print(PGM_ID)
    NoOfPrg=NoOfPrg-1
    MainList.append(empty_list)
    print("jjjjjjjjjjjjjjjjjj",MainList,NoOfPrg)
    MainList[NoOfPrg]=copy.deepcopy(OutputDict)
    OutputDict.clear()
    return Module_Dict2,section_list



def data(TempCallName,TempCopyName, Module_Dict):

    ItemsToDisplayList=["ModuleName","CallStatements","CopyBooks","PerformStatements"]
    # print(json.dumps(Module_Dict, indent=4))

    ItemsFromProgram=[Module_Name,TempCallName,TempCopyName,Module_Dict]
    i=iter(ItemsToDisplayList)
    j=iter(ItemsFromProgram)
    k=list(zip(i,j))
    for (x,y) in k:
            OutputDict[x]=y




def Program_Flow(Module_Name,Module_Dict):
    firstdict={}
    seconddict={}
    thirddict={}

    for element in Module_Name:
        for element1 in Module_Dict:

            Module=Module_Dict.get(element1)

            for element2 in Module:
                 thirddict[element2]=Module_Dict[element2]

        firstdict[element]=thirddict

    print("first",firstdict)


def ExcelWriting():
    ProgNameLen=len(PGM_ID)-1
    workbook = xlsxwriter.Workbook('Demo.xlsx')
    worksheet = workbook.add_worksheet(PGM_ID[ProgNameLen])

    row=0
    col=0
    for Key in (Module_Dict):
         row += 1
         worksheet.write(row, col, Key)
         for item in Module_Dict[Key]:
            worksheet.write(row, col, "Perform Statements")
            worksheet.write(row, col+1, item)
            worksheet.write(row ,col , Key)
            row+=1

def flowData(Module_Dict):

    Keys=['from','to','name']
    Values=[]
    Newlist=[]
    Dict={}
    newdict={}
    templist=[]
    templist1=[]
    # print("Module_Dicttttt:",Module_Dict)
    # print("calllist,",Call_Name)
    for Key in (Module_Dict):
        for item in Module_Dict[Key]:
           Values.append(Key)
           Values.append(item)
           Values.append(Key)
           templist = Values.copy()
           #print(templist)
           for i in range(len(Keys)):
              Dict[Keys[i]] = templist[i]
           newdict=copy.deepcopy(Dict)
           Newlist.append(newdict)
           Dict.clear()
           Values.clear()
    templist1 = Newlist.copy()
    ProgramflowList.append(templist1)
    Newlist.clear()

def Dead_Code(filename):

    DeadDict = {}
    moduledead=[]
    finaldeadparalist = []
    TotalNoOfDeadLine = 0
    PerformParaList=[]
    FullParaList=[]
    DeadParaList=[]
    lines=[]
    ModuleName=[]
    for para in Perform_St:
        para=para.split()
        if para[0]=="PERFORM":
            Temp_para=para[1]
            PerformParaList.append(Temp_para)
    r=0

    print("1",Module_Dict1)
    print(Module_Dict)

    for elements in Module_Dict:
        Module = Module_Dict.get(elements)
        if Module==[] and r==0:
            continue
        else:
            r=r+1
            FullParaList.append(elements)
    if FullParaList!=[]:
     del FullParaList[0]
    for element1 in FullParaList:
       if element1 in PerformParaList:
           continue
       else:
           DeadParaList.append(element1)
    Program_Name = open("Expanded_Data.txt")
    for line1 in Program_Name.readlines():
        b = IsDivision(line1)
        if b != 0:
            break
        else:
            continue
    lenOfFullparalist=len(FullParaList)
    Program_Name = open("Expanded_Data.txt")
    r=0
    CurtModule=""
    paravalue=[]
    test_dict={}
    for line in Program_Name.readlines():
        line = Cut_Line(line, b)

        module = re.findall(r'^\s[A0-Z9].*[-]*.*[.]', line,re.IGNORECASE)


        if module!=[]:
         module=module[0].split('.')
         module=module[0].strip()
         CurtModule=module
        if CurtModule!=[] and  CurtModule != module :
            r=r+1
        else:
            lines.append(r)
            ModuleName.append(module)
            r=0
    lines.append(r)
    Program_Name.close()
    os.remove("Expanded_Data.txt")
    os.remove("another_file.txt")
    del lines[0]
    temp_line=lines.copy()

    temp_Module=ModuleName.copy()
    #print(len(temp_line), len(temp_Module))
    for i in range(len(temp_line)):
        DeadDict[temp_Module[i]] = temp_line[i]

    #print("hhhhhhhhhhhh",Module_Dict)
    for data2 in Module_Dict:
         paravalue=Module_Dict.get(data2)
         if paravalue!=[]:
             master_alive.add(data2)
             break

    for elemente in paravalue:
        # print("ele",elemente)
        findAliveChildren(elemente)
    for elements1 in paravalue:
        master_alive.add(elements1)

    first_para=""
    c=0
    for j,o in Module_Dict.items():
        c=c+1
        first_para=o
        if c==1:
            break


    #print("para", master_alive)
    # print("asli",Module_Dict)
    # print("ggggggg",DeadParaList)
    # print("section",sec_list)

    module_dict_keys=[]
    module_dict_keys=list(Module_Dict.keys())
    #print("module_dict_keys",module_dict_keys)
    #print("modiel",master_alive)
    Latest_dead_output=(set(module_dict_keys)-set(master_alive))

    Latest_dead_output=set(Latest_dead_output)-set(sec_list)

    print("Latest_dead_output", Latest_dead_output)
    # deleting the first para section.
    DeadParaList_update=[]
    for d in list(Latest_dead_output):
        if d in first_para or d =="MAIN-LOGIC":
            continue
        if d.endswith('-EXIT') or d.__contains__('-EXIT') or d.__contains__('EXIT-') or d.endswith('-X') or d.endswith('-SXIT'):
            continue
        DeadParaList_update.append(d)
    #print("para_lisr",DeadParaList_update)
    print("de_dcit",DeadDict)
    for i in DeadParaList_update:
        para=DeadDict.get(i.strip())
        if(para==None):
          para=0
        TotalNoOfDeadLine=TotalNoOfDeadLine+para
    notalivepara=[]
    for item in Module_Name:
        if item in master_alive:
            continue
        else:
            notalivepara.append(item)
    master_alive.clear()
    for alivepara1 in notalivepara:
      try:
        del Module_Dict[alivepara1]
      except KeyError:
          continue

    dictfilt = lambda x, y: dict([(i, x[i]) for i in x if i in set(y)])
    wanted_keys = DeadParaList_update
    result = dictfilt(DeadDict, wanted_keys)

    temp_result=copy.deepcopy(result)
    finaldeadparalist.append(len(temp_result))
    finaldeadparalist.append(DeadParaList_update)
    finaldeadparalist.append(TotalNoOfDeadLine)
    finaldeadparalist.append(len(Module_Name))
    finaldeadparalist1=copy.deepcopy(finaldeadparalist)

    HeaderParalist=["dead_para_count","dead_para_list","total_dead_lines","total_para_count"]
    deaddict1 = copy.deepcopy(deaddict)
    for m in range(len(HeaderParalist)):
        deaddict1[HeaderParalist[m]]=finaldeadparalist1[m]
    finaldeadparalist2.append(deaddict1)
    print("dead",deaddict1)
    for k in range(len(PGM_ID)):
        DeadDictFinal[PGM_ID[k]] = finaldeadparalist2[k]
    print(DeadDictFinal)

def findAliveChildren(ele):

   try:
    if Module_Dict[ele] == []:

        master_alive.add(ele)
        return
    else:
        for item in Module_Dict[ele]:

            if item in master_alive:

                continue
            else:

             master_alive.add(item)
             findAliveChildren(item)
   except KeyError :
       return

# cobol_folder_name = config.codebase_information['COBOL']['folder_name']
# # print(cobol_folder_name)
# cobol_extension_type = config.codebase_information['COBOL']['extension']

cobol_folder_name = config_crst.codebase_information['COBOL']['folder_name']
# print(cobol_folder_name)
cobol_extension_type = config_crst.codebase_information['COBOL']['extension']
COPYBOOK = config_crst.codebase_information['COPYBOOK']['folder_name']

code_location =config_crst.codebase_information['code_location']
# print(code_location)
CobolPath=code_location+'\\'+cobol_folder_name
#CobolPath=code_location+'/'+cobol_folder_name+'/'
# print(CobolPath)
CopyPath=code_location+'\\'+COPYBOOK
#CopyPath=code_location+'/'+COPYBOOK+'/'
#workbook = xlsxwriter.Workbook('Demo.xlsx')
# print("failure")
# /Users/Sivan/PROD/Cobol
for filename in glob.glob(os.path.join(CobolPath,'*.cbl')):
    # print("Pass:",CobolPath)
    # print("success")
    # print("File passed:",filename)
    Module_Dict1={}
    New_Dict={}
    second_list=[]
    Copy_Name.clear()
    Module_Name.clear()
    Perform_St.clear()
    CallName.clear()
    CopyName.clear()
    Module_Dict,sec_list=main(filename)
    Dead_Code(filename)
    flowData(Module_Dict)
    # print("M:",Module_Dict)
    #second_list = []
    main_list = []

    #ExcelWriting()

#workbook.close()

paradict={}
for i in range(len(PGM_ID)):
    MainDict[PGM_ID[i]]=MainList[i]

for i in range(len(PGM_ID)):
    jsonDict[PGM_ID[i]]=ParaList[i]


for i in range(len(PGM_ID)):
    paradict[PGM_ID[i]]=ProgramflowList[i]


print("prg",PGM_ID)
JsonDict1={}
flowDict={}



flowDict["data"]=paradict
External_program(paradict)
Call_Name.clear()
# r = requests.post('http://localhost:5000/api/v1/update/procedureFlow',json={"data":paradict})
# print(r.status_code)
# print(r.text)
# #
r = requests.post('http://localhost:5000/api/v1/augment/masterInventory',json=DeadDictFinal)
print(r.status_code)
print(r.text)


