SCRIPT_VERSION = 'Initial flowchart experiment v0.1'
import re,copy,glob,os
from pymongo import MongoClient
import pytz
import datetime
import json
import config1
end = "endsr"
begin = "begsr"
storage = []
variable = ""
sp_list = ""
global copy_file

#file_location = "D:\\AS400*"
CopyPath = "D:\AS400\Copybook"


client = MongoClient(config1.database['mongo_endpoint_url'])
db = client[config1.database['database_name']]
# client = MongoClient('localhost', 27017)
# db = client['as400']



# Setting Application timezone
time_zone = 'Asia/Calcutta'
tz = pytz.timezone(time_zone)

file ={ 'D:\AS400*\RPG': '*.RPG'}



def read_lines():

    functions_seprarated = {}
    dict_dead={}
    flag = False
    data = []
    file_handle = open("Copy_Expanded_Data" + '.txt', 'r')
    #print(filename)

    fun_name = ''
    count = 0
    storage = []

    for  line in file_handle:
        #print(line)


         try:
            if len(line) > 7:

                line = line[6:72]

                if line[0] == '*' or re.search("//", line):
                    #print(line)
                  continue

                else:

                    if re.search("endsr\s", line.casefold()):  # counting lines
                        # print('end number', index)

                        functions_seprarated[fun_name] = copy.deepcopy(storage)
                        storage.clear()
                        dict_dead[fun_name] = count
                        count = 2


                        flag = False
                        #  print(line + '------------------------------------------')
                    if flag:
                        count = count + 1
                        storage.append(line.strip().casefold())

                    if  line.casefold().__contains__(begin):
                        flag = True
                        if (re.search('.*begsr$',line,re.IGNORECASE)):
                            new_line1 = line.casefold().strip().split("begsr".casefold())
                            var = len(new_line1)
                            temp_fun_name = new_line1[var - 2]
                            temp_fun_name=temp_fun_name.strip().split()
                            var1 = len(temp_fun_name)
                            fun_name=temp_fun_name[var1-1].casefold().strip()
                            #print(fun_name)

                        else:

                            new_line=line.casefold().strip().split("begsr".casefold())

                            var = len(new_line)
                            fun_name = new_line[var-1].casefold().strip(';').strip()


         except Exception:
            # print(line)
            pass

    return functions_seprarated





#Variable definitions
total_individual_block_counter = 0
total_group_block_counter = 0
group_block_variable = ''
total_individual_block_counter = 0
node_sequence = []
node_code = {}
OUTPUT_DATA = []

# READ VARIABLE
read_variable = ''
read_flag = False

# DO VARIABLE
do_variable = ''
do_flag = False

# CALL VARIABLE
call_variable = ''

# WRITE VARIABLE
write_variable = ''

# OPEN VARIABLE
open_variable = ''

# CLOSE VARIABLE
close_variable = ''

# EXSR VARIABLE
exsr_variable = ''

# GOTO VARIABLE
goto_variable = ''

# EXFMT VARIABLE
exfmt_variable = ''

# UNLOCK VARIABLE
unlock_variable = ''

# EXCEPT VARIABLE
except_variable = ''

# CHAIN VARIABLE
chain_variable = ''

# ENDDO VARIABLE
enddo_variable = ''

# UPDATE VARIABLE
update_variable = ''

# RETURN VARIABLE
return_variable = ''

# SELECT VARIABLE
select_variable = ''
select_flag = False

# FOR VARIABLE
for_variable = ''
for_flag = False

# CAB VARIABLE
cab_variable = ''

# CAS VARIABLE
cas_variable = ''

# SETGT VARIABLE
setgt_variable = ''

# SETLL VARIABLE
setll_variable = ''

# SORTA VARIABLE
sorta_variable = ''

# TIME VARIABLE
time_variable = ''

keywords_for_if_delimiter = ['else','eval','exsr','if','movea','add','addur','cat','check','checkr','clear','define','delete','div','dump','dsply','evalr','extrct',
                                'in','iter','klist','leave','leavesr','lookup','monitor','move(p)','move','movel(p)','movel',
                                 'mvr','occur','onerror','out','plist','scan','setoff','seton','sub','subdur','subst',
                                'tag','xfoot','xlate','z-add','z-sub','call','callb','callp','close','do','dou','dow','except','excpt','exfmt','for','goto','open','read','readc',
                             'reade','readp','readpe','return','select','setgt','setll','sorta','time','unlock','update','write']

if_condition_variable = ''
total_if_counter = 0
if_condition_collector_flag = ''


discovered_node = ''

true_part_flag = ''
true_part_variable = ''

discovered_node = ''

false_part_variable = ''
false_part_flag = ''

# First level IFs true part tally logic helpers
truepart_ifs_tallied = True
truepart_if_opened_count = 0
truepart_if_closed_count = 0

# First level IFs false part tally logic helpers
falsepart_ifs_tallied = True
falsepart_if_opened_count = 0
falsepart_if_closed_count = 0



keywords_for_group_variables = ['ADD','ADDDUR','CAT','CHECK','CHECKR','CLEAR','DEFINE','DELETE','DIV','DUMP','DSPLY','DUMP','EVAL','EVALR','EXTRCT',
                                'IN','ITER','KLIST','LEAVE','LEAVESR','LOOKUP','MONITOR','MOVE(P)','move','MOVEL(P)','movel',
                                 'MULT','MVR','OCCUR','ONERROR','OUT','PLIST','SCAN','SETOFF','SETON','SUB','SUBDUR','SUBST',
                                'TAG','XFOOT','XLATE','Z-ADD','Z-SUB']



for file_location, file_type in file.items():
    for filename in glob.glob(os.path.join(file_location,file_type)):
        ModuleName = filename
        #print(ModuleName)
        f = open(ModuleName, "r")
        i = 1
        for line in f.readlines():
            if line.strip() == '' or line[5:].strip() == '' or line[6] == '*':
                #print("asf",line)
                continue
            else:
                with open("Copy_Expanded_Data" + '.txt', "a+") as copy_file:
                    # if line[5] == 'c' or line[5] == 'C':
                    #     command_section = True
                    # if command_section:
                        copy_regexx = re.findall(r'\s*/COPY\s.*', line,re.IGNORECASE)

                        if copy_regexx != []:
                            #print(copy_regexx)
                            if copy_regexx != []:
                                copyname = copy_regexx[0]
                                copyname = copyname.split()
                                copyname = copyname[1]

                                if copyname.__contains__(","):
                                    copyname = copyname.split(',')
                                    copyname = copyname[1]
                                copyname = copyname + '.cpy'
                                #print(copyname)
                                Copyfilepath = CopyPath + '\\' + copyname
                                #print(Copyfilepath)
                                if os.path.isfile(Copyfilepath):
                                    #print(Copyfilepath)
                                    Temp_File2 = open(os.path.join(CopyPath, copyname), "r")
                                    #print(Temp_File2)
                                    copy_file.write("#########" + " " + "BEGIN" + " " + line.strip() + '\n')
                                    for copylines in Temp_File2.readlines():
                                        copylines = re.sub('\t', '     ', copylines)
                                        copy_file.write(copylines)
                                        #copy_file.write('\n')
                                        #print(copy_file)
                                    copy_file.write("#####" + " " + "COPY END" + "####" + '\n')
                                else:
                                    copy_file.write(line)
                        else:
                            copy_file.write(line)
                            # print(line)
                            #copy_file.write('\n')

        #f1 = open("Copy_Expanded_Data" + '.txt', 'r')
        #copy_file.close()

        functions_seprarated = read_lines()
        #print(functions_seprarated)
        #print( json.dumps( functions_seprarated,indent=4))
        list_of_functions = list(functions_seprarated.keys())
        #print('Functions list',list_of_functions)

        for function in list_of_functions:
                for line in functions_seprarated[function]:
                    discovered_node = ''
                    #print(line)
                    if select_flag:
                        if re.match('endsl.*', line, re.IGNORECASE):
                            select_variable = select_variable + '\n' + line
                            node_sequence.append('S' + str(total_individual_block_counter))
                            node_code['S' + str(total_individual_block_counter)] = select_variable
                            select_variable = ''
                            select_flag = False
                            continue

                        else:
                            select_variable = select_variable + '\n' + line
                            continue

                    if for_flag:
                        if re.match('endfor.*', line, re.IGNORECASE):
                            for_variable = for_variable + '\n' + line
                            node_sequence.append('S' + str(total_individual_block_counter))
                            node_code['S' + str(total_individual_block_counter)] = for_variable
                            for_variable = ''
                            for_flag = False
                            continue

                        else:
                            for_variable = for_variable + '\n' + line

                            continue

                    if if_condition_collector_flag:
                        if any(ext in line for ext in keywords_for_if_delimiter):
                            # stop collecting the IF conditional statement and continue
                            discovered_node = 'C' + str(
                                total_if_counter) + ' =>condition:' + if_condition_variable + ' | approved\n'
                            node_sequence.append('C' + str(total_if_counter))
                            node_code['C' + str(total_if_counter)] = if_condition_variable
                            # print(if_condition_variable)
                            if_condition_collector_flag = False

                            true_part_flag = True

                            true_part_variable = ''
                            # true_part_variable = true_part_variable + line + '\n'

                            # if re.match('if *', line, re.IGNORECASE):
                            #     # make sure if execution knows that IFs are no longer tallied
                            #     truepart_ifs_tallied = False
                            #     # Increment the count of opened if statements
                            #     truepart_if_opened_count += 1
                            #     continue
                            # else:
                            #     true_part_variable = true_part_variable + '\n' + line

                        else:
                            if_condition_variable = if_condition_variable + '\n' + line
                            continue

                    if true_part_flag:

                        # if re.match('end', line, re.IGNORECASE):
                        #     truepart_if_opened_count, truepart_if_closed_count = 0, 0
                        #     node_sequence.append('T' + str(total_if_counter))
                        #     node_code['T' + str(total_if_counter)] = true_part_variable + '\n' + line
                        #     node_sequence.append('F' + str(total_if_counter))
                        #     node_code['F' + str(total_if_counter)] = ''
                        #     true_part_flag = False
                        #     continue

                        if re.match('if\s+.*', line, re.IGNORECASE):
                            # make sure if execution knows that IFs are no longer tallied
                            #true_part_variable = ''
                            truepart_ifs_tallied = False
                            # Increment the count of opened if statements
                            truepart_if_opened_count += 1
                            true_part_variable = true_part_variable + '\n' + line
                            continue

                        if (not truepart_ifs_tallied) and (
                                re.match('endif', line, re.IGNORECASE)or re.match('end', line,
                                                                                                re.IGNORECASE)):
                            truepart_if_closed_count += 1
                            true_part_variable = true_part_variable + '\n' + line
                            if truepart_if_opened_count == truepart_if_closed_count:
                                truepart_ifs_tallied = True
                                truepart_if_opened_count, truepart_if_closed_count = 0, 0
                            continue

                        # else:
                        #     true_part_variable = ''
                        #     true_part_variable = true_part_variable + '\n' + line
                        #     continue
                        # close the true part
                        # true_part_variable = true_part_variable + '\n' + line
                        # discovered_node = 'T' + str(
                        #     total_if_counter) + ' =>operation:' + true_part_variable + ' | rejected\n'
                        # node_sequence.append('T' + str(total_if_counter))
                        # node_code['T' + str(total_if_counter)] = true_part_variable

                        if (re.match('else', line) or re.match('endif', line)or re.match('end', line)) and truepart_ifs_tallied:

                            if re.match('endif', line, re.IGNORECASE)or re.match('end', line, re.IGNORECASE):
                                node_sequence.append('T' + str(total_if_counter))
                                node_code['T' + str(total_if_counter)] = true_part_variable + '\n' + line
                                node_sequence.append('F' + str(total_if_counter))
                                node_code['F' + str(total_if_counter)] = ''
                                true_part_variable = ''
                                true_part_flag = False

                                continue
                            else:
                                if re.match('else', line, re.IGNORECASE):
                                # print(line)
                                    discovered_node = 'T' + str(
                                    total_if_counter) + ' =>operation:' + true_part_variable + ' | rejected\n'
                                    node_sequence.append('T' + str(total_if_counter))
                                    node_code['T' + str(total_if_counter)] = true_part_variable
                                    node_sequence.append('F' + str(total_if_counter))
                                    node_code['F' + str(total_if_counter)] = ''
                                    # print(true_part_variable)
                                    # Clear the true part variable
                                    true_part_variable = ''
                                    # Set true part flag to false
                                    true_part_flag = False
                                    false_part_flag = True
                                    false_part_variable = ''
                                    # false_part_variable = false_part_variable + line + '\n'
                                    continue

                        else:
                            true_part_variable = true_part_variable + '\n' + line
                            continue

                    if false_part_flag:

                        if re.match('if\s+.*', line, re.IGNORECASE):
                            # make sure if execution knows that IFs are no longer tallied
                            falsepart_ifs_tallied = False
                            # Increment the count of opened if statements
                            falsepart_if_opened_count += 1
                            false_part_variable = false_part_variable + '\n' + line
                            continue

                        if (not falsepart_ifs_tallied) and (
                                re.match('endif', line, re.IGNORECASE)or re.match('end', line,re.IGNORECASE)):

                            falsepart_if_closed_count += 1
                            false_part_variable = false_part_variable + '\n' + line
                            if falsepart_if_opened_count == falsepart_if_closed_count:
                                falsepart_ifs_tallied = True
                                falsepart_if_opened_count, falsepart_if_closed_count = 0, 0
                            continue

                        if (re.match('endif', line, re.IGNORECASE)or re.match('end', line,
                                                                                            re.IGNORECASE)) and falsepart_ifs_tallied:
                            # if any one of the above is true
                            false_part_variable = false_part_variable + line + '\n'
                            discovered_node = 'F' + str(
                                total_if_counter) + ' =>operation:' + false_part_variable + ' | rejected\n'
                            # print(discovered_node)
                            node_sequence.append('F' + str(total_if_counter))
                            node_code['F' + str(total_if_counter)] = false_part_variable
                            # print('false',false_part_variable)
                            false_part_flag = False
                            group_block_flag = True
                            total_group_block_counter = total_group_block_counter + 1

                            continue
                        else:

                            false_part_variable = false_part_variable + '\n' + line
                            continue

                    if re.match('if\s+.*', line, re.IGNORECASE):
                        # print(line)
                        # if not re.match('endif.*', line, re.IGNORECASE):
                        # print(line)
                        if_condition_variable = " "
                        total_if_counter = total_if_counter + 1
                        if_condition_variable = line
                        if_condition_collector_flag = True
                        group_block_flag = False
                        if group_block_variable != '':
                            total_group_block_counter = total_group_block_counter + 1
                            node_sequence.append('G' + str(total_group_block_counter))
                            node_code['G' + str(total_group_block_counter)] = group_block_variable
                            group_block_variable = ''
                        continue

                    if re.match('.*read .*', line, re.IGNORECASE):
                        #print(line)
                        if group_block_variable != '':
                            total_group_block_counter = total_group_block_counter + 1
                            node_sequence.append('G' + str(total_group_block_counter))
                            node_code['G' + str(total_group_block_counter)] = group_block_variable
                            group_block_variable = ''
                        read_variable = ''
                        total_individual_block_counter = total_individual_block_counter + 1
                        read_variable = line + '\n'
                        #print(read_variable)
                        node_sequence.append('S' + str(total_individual_block_counter))
                        node_code['S' + str(total_individual_block_counter)] = read_variable
                        read_variable = ''
                        continue

                    if re.search(r'^\s*call.*', line, re.IGNORECASE):
                        #print(line)
                        if group_block_variable != '':
                            total_group_block_counter = total_group_block_counter + 1
                            node_sequence.append('G' + str(total_group_block_counter))
                            node_code['G' + str(total_group_block_counter)] = group_block_variable
                            group_block_variable = ''
                        call_variable = ''
                        total_individual_block_counter = total_individual_block_counter + 1
                        call_variable = line + '\n'
                        #print(read_variable)
                        node_sequence.append('S' + str(total_individual_block_counter))
                        node_code['S' + str(total_individual_block_counter)] = call_variable
                        call_variable = ''
                        continue

                    if re.search(r'^\s*cab.*', line, re.IGNORECASE):
                        #print(line)
                        if group_block_variable != '':
                            total_group_block_counter = total_group_block_counter + 1
                            node_sequence.append('G' + str(total_group_block_counter))
                            node_code['G' + str(total_group_block_counter)] = group_block_variable
                            group_block_variable = ''
                        cab_variable = ''
                        total_individual_block_counter = total_individual_block_counter + 1
                        cab_variable = line + '\n'
                        #print(read_variable)
                        node_sequence.append('S' + str(total_individual_block_counter))
                        node_code['S' + str(total_individual_block_counter)] = cab_variable
                        cab_variable = ''
                        continue


                    if re.search(r'^\s*cas.*', line, re.IGNORECASE):
                        #print(line)
                        if group_block_variable != '':
                            total_group_block_counter = total_group_block_counter + 1
                            node_sequence.append('G' + str(total_group_block_counter))
                            node_code['G' + str(total_group_block_counter)] = group_block_variable
                            group_block_variable = ''
                        cas_variable = ''
                        total_individual_block_counter = total_individual_block_counter + 1
                        cas_variable = line + '\n'
                        #print(read_variable)
                        node_sequence.append('S' + str(total_individual_block_counter))
                        node_code['S' + str(total_individual_block_counter)] = cas_variable
                        cas_variable = ''
                        continue


                    if re.match('.*write.*', line, re.IGNORECASE):
                        #print(line)
                        if group_block_variable != '':
                            total_group_block_counter = total_group_block_counter + 1
                            node_sequence.append('G' + str(total_group_block_counter))
                            node_code['G' + str(total_group_block_counter)] = group_block_variable
                            group_block_variable = ''
                        write_variable = ''
                        total_individual_block_counter = total_individual_block_counter + 1
                        write_variable = line + '\n'
                        #print(read_variable)
                        node_sequence.append('S' + str(total_individual_block_counter))
                        node_code['S' + str(total_individual_block_counter)] = write_variable
                        write_variable = ''
                        continue

                    if re.match('.*open\s\s.*', line, re.IGNORECASE):
                        #print(line)
                        if group_block_variable != '':
                            total_group_block_counter = total_group_block_counter + 1
                            node_sequence.append('G' + str(total_group_block_counter))
                            node_code['G' + str(total_group_block_counter)] = group_block_variable
                            group_block_variable = ''
                        open_variable = ''
                        total_individual_block_counter = total_individual_block_counter + 1
                        open_variable = line + '\n'
                        #print(read_variable)
                        node_sequence.append('S' + str(total_individual_block_counter))
                        node_code['S' + str(total_individual_block_counter)] = open_variable
                        open_variable = ''
                        continue

                    if re.match('.*close\s\s.*', line, re.IGNORECASE):
                        #print(line)
                        if group_block_variable != '':
                            total_group_block_counter = total_group_block_counter + 1
                            node_sequence.append('G' + str(total_group_block_counter))
                            node_code['G' + str(total_group_block_counter)] = group_block_variable
                            group_block_variable = ''
                        close_variable = ''
                        total_individual_block_counter = total_individual_block_counter + 1
                        close_variable = line + '\n'
                        #print(read_variable)
                        node_sequence.append('S' + str(total_individual_block_counter))
                        node_code['S' + str(total_individual_block_counter)] = close_variable
                        close_variable = ''
                        continue

                    if re.match('.*exsr .*', line, re.IGNORECASE):
                        #print(line)
                        if group_block_variable != '':
                            total_group_block_counter = total_group_block_counter + 1
                            node_sequence.append('G' + str(total_group_block_counter))
                            node_code['G' + str(total_group_block_counter)] = group_block_variable
                            group_block_variable = ''
                        exsr_variable = ''
                        total_individual_block_counter = total_individual_block_counter + 1
                        exsr_variable = line + '\n'
                        #print(read_variable)
                        node_sequence.append('S' + str(total_individual_block_counter))
                        node_code['S' + str(total_individual_block_counter)] = exsr_variable
                        exsr_variable = ''
                        continue

                    if re.match('.*goto .*', line, re.IGNORECASE):
                        #print(line)
                        if group_block_variable != '':
                            total_group_block_counter = total_group_block_counter + 1
                            node_sequence.append('G' + str(total_group_block_counter))
                            node_code['G' + str(total_group_block_counter)] = group_block_variable
                            group_block_variable = ''
                        goto_variable = ''
                        total_individual_block_counter = total_individual_block_counter + 1
                        goto_variable = line + '\n'
                        # print(read_variable)
                        node_sequence.append('S' + str(total_individual_block_counter))
                        node_code['S' + str(total_individual_block_counter)] = goto_variable
                        goto_variable = ''
                        continue

                    if re.match('do.*', line, re.IGNORECASE):
                        #print(line)
                        #if not re.match('.*enddo.*', line, re.IGNORECASE):
                            if group_block_variable != '':
                                total_group_block_counter = total_group_block_counter + 1
                                node_sequence.append('G' + str(total_group_block_counter))
                                node_code['G' + str(total_group_block_counter)] = group_block_variable
                                group_block_variable = ''
                            do_variable = ''
                            total_individual_block_counter = total_individual_block_counter + 1
                            do_variable = line + '\n'
                            # print(read_variable)
                            node_sequence.append('S' + str(total_individual_block_counter))
                            node_code['S' + str(total_individual_block_counter)] = do_variable
                            do_variable = ''
                            continue

                    if re.match('enddo.*', line, re.IGNORECASE):
                        #print(line)
                        #if not re.match('.*enddo.*', line, re.IGNORECASE):
                            if group_block_variable != '':
                                total_group_block_counter = total_group_block_counter + 1
                                node_sequence.append('G' + str(total_group_block_counter))
                                node_code['G' + str(total_group_block_counter)] = group_block_variable
                                group_block_variable = ''
                            enddo_variable = ''
                            total_individual_block_counter = total_individual_block_counter + 1
                            enddo_variable = line + '\n'
                            # print(read_variable)
                            node_sequence.append('S' + str(total_individual_block_counter))
                            node_code['S' + str(total_individual_block_counter)] = enddo_variable
                            enddo_variable = ''
                            continue

                    if re.match('chain .*', line, re.IGNORECASE):
                        #print(line)
                        if group_block_variable != '':
                            total_group_block_counter = total_group_block_counter + 1
                            node_sequence.append('G' + str(total_group_block_counter))
                            node_code['G' + str(total_group_block_counter)] = group_block_variable
                            group_block_variable = ''
                        chain_variable = ''
                        total_individual_block_counter = total_individual_block_counter + 1
                        chain_variable = line + '\n'
                        # print(read_variable)
                        node_sequence.append('S' + str(total_individual_block_counter))
                        node_code['S' + str(total_individual_block_counter)] = chain_variable
                        chain_variable = ''
                        continue

                    if re.match('except.*', line, re.IGNORECASE):
                        #print(line)
                        if group_block_variable != '':
                            total_group_block_counter = total_group_block_counter + 1
                            node_sequence.append('G' + str(total_group_block_counter))
                            node_code['G' + str(total_group_block_counter)] = group_block_variable
                            group_block_variable = ''
                        except_variable = ''
                        total_individual_block_counter = total_individual_block_counter + 1
                        except_variable = line + '\n'
                        # print(read_variable)
                        node_sequence.append('S' + str(total_individual_block_counter))
                        node_code['S' + str(total_individual_block_counter)] = except_variable
                        except_variable = ''
                        continue

                    if re.match('unlock.*', line, re.IGNORECASE):
                        #print(line)
                        if group_block_variable != '':
                            total_group_block_counter = total_group_block_counter + 1
                            node_sequence.append('G' + str(total_group_block_counter))
                            node_code['G' + str(total_group_block_counter)] = group_block_variable
                            group_block_variable = ''
                        unlock_variable = ''
                        total_individual_block_counter = total_individual_block_counter + 1
                        unlock_variable = line + '\n'
                        # print(read_variable)
                        node_sequence.append('S' + str(total_individual_block_counter))
                        node_code['S' + str(total_individual_block_counter)] = unlock_variable
                        unlock_variable = ''
                        continue

                    if re.match('exfmt.*', line, re.IGNORECASE):
                        #print(line)
                        if group_block_variable != '':
                            total_group_block_counter = total_group_block_counter + 1
                            node_sequence.append('G' + str(total_group_block_counter))
                            node_code['G' + str(total_group_block_counter)] = group_block_variable
                            group_block_variable = ''
                        exfmt_variable = ''
                        total_individual_block_counter = total_individual_block_counter + 1
                        exfmt_variable = line + '\n'
                        # print(read_variable)
                        node_sequence.append('S' + str(total_individual_block_counter))
                        node_code['S' + str(total_individual_block_counter)] = exfmt_variable
                        exfmt_variable = ''
                        continue

                    if re.match('update.*', line, re.IGNORECASE):
                        # print(line)
                        if group_block_variable != '':
                            total_group_block_counter = total_group_block_counter + 1
                            node_sequence.append('G' + str(total_group_block_counter))
                            node_code['G' + str(total_group_block_counter)] = group_block_variable
                            group_block_variable = ''
                        update_variable = ''
                        total_individual_block_counter = total_individual_block_counter + 1
                        update_variable = line + '\n'
                        # print(read_variable)
                        node_sequence.append('S' + str(total_individual_block_counter))
                        node_code['S' + str(total_individual_block_counter)] = update_variable
                        update_variable = ''
                        continue

                    if re.match('return .*', line, re.IGNORECASE):
                        # print(line)
                        if group_block_variable != '':
                            total_group_block_counter = total_group_block_counter + 1
                            node_sequence.append('G' + str(total_group_block_counter))
                            node_code['G' + str(total_group_block_counter)] = group_block_variable
                            group_block_variable = ''
                        return_variable = ''
                        total_individual_block_counter = total_individual_block_counter + 1
                        return_variable = line + '\n'
                        # print(read_variable)
                        node_sequence.append('S' + str(total_individual_block_counter))
                        node_code['S' + str(total_individual_block_counter)] = return_variable
                        return_variable = ''
                        continue



                    if re.match(' select ', line, re.IGNORECASE):
                        if not re.match('endsl.*', line, re.IGNORECASE):
                            select_variable = ''
                            total_individual_block_counter = total_individual_block_counter + 1
                            select_variable = line + '\n'
                            select_flag = True
                            if group_block_variable != '':
                                total_group_block_counter = total_group_block_counter + 1
                                node_sequence.append('G' + str(total_group_block_counter))
                                node_code['G' + str(total_group_block_counter)] = group_block_variable
                                group_block_variable = ''
                            continue
                        else:
                            select_variable = ''
                            total_individual_block_counter = total_individual_block_counter + 1
                            node_sequence.append('S' + str(total_individual_block_counter))
                            node_code['S' + str(total_individual_block_counter)] = line
                            group_block_flag = False
                            if group_block_variable != '':
                                total_group_block_counter = total_group_block_counter + 1
                                node_sequence.append('G' + str(total_group_block_counter))
                                node_code['G' + str(total_group_block_counter)] = group_block_variable
                                group_block_variable = ''
                            continue



                    if re.match(' for ', line, re.IGNORECASE):
                        if not re.match('endfor.*', line, re.IGNORECASE):
                            for_variable = ''
                            total_individual_block_counter = total_individual_block_counter + 1
                            for_variable = line + '\n'
                            for_flag = True
                            if group_block_variable != '':
                                total_group_block_counter = total_group_block_counter + 1
                                node_sequence.append('G' + str(total_group_block_counter))
                                node_code['G' + str(total_group_block_counter)] = group_block_variable
                                group_block_variable = ''
                            continue
                        else:
                            for_variable = ''
                            total_individual_block_counter = total_individual_block_counter + 1
                            node_sequence.append('S' + str(total_individual_block_counter))
                            node_code['S' + str(total_individual_block_counter)] = line
                            group_block_flag = False
                            if group_block_variable != '':
                                total_group_block_counter = total_group_block_counter + 1
                                node_sequence.append('G' + str(total_group_block_counter))
                                node_code['G' + str(total_group_block_counter)] = group_block_variable
                                group_block_variable = ''
                            continue

                    if re.match('setgt .*', line, re.IGNORECASE):
                        # print(line)
                        if group_block_variable != '':
                            total_group_block_counter = total_group_block_counter + 1
                            node_sequence.append('G' + str(total_group_block_counter))
                            node_code['G' + str(total_group_block_counter)] = group_block_variable
                            group_block_variable = ''
                        setgt_variable = ''
                        total_individual_block_counter = total_individual_block_counter + 1
                        setgt_variable = line + '\n'
                        # print(read_variable)
                        node_sequence.append('S' + str(total_individual_block_counter))
                        node_code['S' + str(total_individual_block_counter)] = setgt_variable
                        setgt_variable = ''
                        continue

                    if re.match('.*setll .*', line, re.IGNORECASE):
                        # print(line)
                        if group_block_variable != '':
                            total_group_block_counter = total_group_block_counter + 1
                            node_sequence.append('G' + str(total_group_block_counter))
                            node_code['G' + str(total_group_block_counter)] = group_block_variable
                            group_block_variable = ''
                        setll_variable = ''
                        total_individual_block_counter = total_individual_block_counter + 1
                        setll_variable = line + '\n'
                        # print(read_variable)
                        node_sequence.append('S' + str(total_individual_block_counter))
                        node_code['S' + str(total_individual_block_counter)] = setll_variable
                        setll_variable = ''
                        continue

                    if re.match('sorta .*', line, re.IGNORECASE):
                        # print(line)
                        if group_block_variable != '':
                            total_group_block_counter = total_group_block_counter + 1
                            node_sequence.append('G' + str(total_group_block_counter))
                            node_code['G' + str(total_group_block_counter)] = group_block_variable
                            group_block_variable = ''
                        sorta_variable = ''
                        total_individual_block_counter = total_individual_block_counter + 1
                        sorta_variable = line + '\n'
                        # print(read_variable)
                        node_sequence.append('S' + str(total_individual_block_counter))
                        node_code['S' + str(total_individual_block_counter)] = sorta_variable
                        sorta_variable = ''
                        continue

                    if re.match(' time .*', line, re.IGNORECASE):
                        # print(line)
                        if group_block_variable != '':
                            total_group_block_counter = total_group_block_counter + 1
                            node_sequence.append('G' + str(total_group_block_counter))
                            node_code['G' + str(total_group_block_counter)] = group_block_variable
                            group_block_variable = ''
                        time_variable = ''
                        total_individual_block_counter = total_individual_block_counter + 1
                        time_variable = line + '\n'
                        # print(read_variable)
                        node_sequence.append('S' + str(total_individual_block_counter))
                        node_code['S' + str(total_individual_block_counter)] = time_variable
                        time_variable = ''
                        continue


                    if line.strip() != '':
                        if line.strip() != '.':
                          group_block_variable = group_block_variable + line + '\n'
                          continue

                if group_block_variable != '':
                    total_group_block_counter = total_group_block_counter + 1
                    node_sequence.append('G' + str(total_group_block_counter))
                    node_code['G' + str(total_group_block_counter)] = group_block_variable
                    group_block_variable = ''

                node_string = 'st=>start: START | past\ne=>end: END | past \n'
                links_string = 'st'
                try:
                    for i in range(0, len(node_sequence)):
                        # Make sure the leading line breaks are STRIPPED
                        node_code[node_sequence[i]] = node_code[node_sequence[i]].lstrip('\n')
                        node_code[node_sequence[i]] = node_code[node_sequence[i]].replace('=>', '= >')

                        if re.match('^S.*', node_sequence[i]) or re.match('^G.*', node_sequence[i]):
                            links_string = links_string + '->' + node_sequence[i] + '\n' + node_sequence[i]
                            node_string = node_string + node_sequence[i] + '=>operation: ' + node_code[
                                node_sequence[i]] + ' | approved\n'
                        if re.match('^C.*', node_sequence[i]):
                            node_string = node_string + node_sequence[i] + '=>condition: ' + node_code[
                                node_sequence[i]] + ' | rejected\n'

                            # If condition is the last block, end it with the (e) node
                            if (i + 3) >= len(node_sequence):

                                if node_code[node_sequence[i + 2]] == '':
                                    # If else part does nto exist
                                    links_string = links_string + '->' + node_sequence[i] + '\n' + node_sequence[
                                        i] + '(yes)->' + node_sequence[i + 1]
                                    links_string = links_string + '\n' + node_sequence[i + 1] + '->e'
                                    links_string = links_string + '\n' + node_sequence[i] + '(no)'

                                    # links_string = links_string + '\n' + node_sequence[i] + '(no)'
                                    # links_string = links_string + node_sequence[i + 2]
                                else:
                                    # Else parts
                                    links_string = links_string + '->' + node_sequence[i] + '\n' + node_sequence[
                                        i] + '(yes)->' + node_sequence[i + 1] + '\n' + node_sequence[i] + '(no)->' + \
                                                   node_sequence[i + 2] + '\n' + node_sequence[i + 1] + '->e' + '\n' + \
                                                   node_sequence[i + 2]

                                    # links_string = links_string + '\n' + node_sequence[i] + '(no)'



                            else:
                                # If the conditions is not the last, check if has ELSE part
                                if node_code[node_sequence[i + 2]] == '':
                                    # If there is not else part
                                    links_string = links_string + '->' + node_sequence[i] + '\n' + node_sequence[
                                        i] + '(yes)'
                                    links_string = links_string + '->' + node_sequence[i + 1] + '\n' + node_sequence[
                                        i] + '(no)'
                                    links_string = links_string + '->' + node_sequence[i + 3] + '\n' + node_sequence[i + 1]

                                else:
                                    # If there is an else part, behave normally
                                    links_string = links_string + '->' + node_sequence[i] + '\n' + node_sequence[
                                        i] + '(yes)'
                                    links_string = links_string + '->' + node_sequence[i + 1] + '\n' + node_sequence[
                                        i] + '(no)'
                                    links_string = links_string + '->' + node_sequence[i + 2]
                                    links_string = links_string + '\n' + node_sequence[i + 1] + '->' + node_sequence[i + 3]
                                    links_string = links_string + '\n' + node_sequence[i + 2] + '->' + node_sequence[i + 3]
                                    # links_string =  links_string + '\n'+node_sequence[i + 1]+ '->' +node_sequence[i + 3]
                                    # links_string = '\n'+ node_sequence[i + 2]

                            # try:
                            #     links_string = links_string + node_sequence[i + 1] + '->' + node_sequence[i + 3] + '\n'
                            #     links_string = links_string + node_sequence[i + 2] + '->' + node_sequence[i + 3]
                            # except:
                            #     links_string = links_string + node_sequence[i + 1] + '->e' + '\n'
                            #     links_string = links_string + node_sequence[i + 2]
                            #     # print('List terminated. No more nodes')
                            #
                            #

                        if re.match('^T.*', node_sequence[i]):
                            node_string = node_string + node_sequence[i] + '=>operation: ' + node_code[
                                node_sequence[i]] + ' | approved \n'
                            continue
                        if re.match('^F.*', node_sequence[i]):
                            # links_string = links_string+ '\n' + node_sequence[i]
                            # Experimental remove IF condition if it fails
                            if not node_code[node_sequence[i]].strip() == '':
                                node_string = node_string + node_sequence[i] + '=>operation: ' + node_code[
                                    node_sequence[i]] + ' | approved \n'

                            continue

                except Exception as e:
                    print(str(e))
                # Concat the end link
                links_string = links_string + '->e'

                # print(node_sequence)
                # print(node_string)
                # print(links_string)
                # print({"option": node_string + '\n' + links_string,"component_name":COMPONENT_NAME,"para_name":paragraph_name.split('.')[0]})
                OUTPUT_DATA.append({"option": node_string + '\n' + links_string, "component_name": filename.strip(file_location).replace(" ","_")+file_type.strip(".*"),
                                    "para_name": function.casefold()})
                # print(node_sequence)
                node_sequence.clear()
                node_string = ''
                links_string = ''
                #print(json.dumps(OUTPUT_DATA,indent=4))


        #print(OUTPUT_DATA)

        os.remove("Copy_Expanded_Data" + '.txt')

        try:
            db.para_flowchart_data.delete_many({'type': {"$ne": "metadata"}})
        except Exception as e:
            print('Error:' + str(e))

        # Insert into DB
        try:

            db.para_flowchart_data.insert_many(OUTPUT_DATA)
            # updating the timestamp based on which report is called
            current_time = datetime.datetime.now(tz=tz).strftime("%A, %d. %B %Y %I:%M%p")
            if db.para_flowchart_data.update_one({"type": "metadata"}, {"$set": {"last_updated_on": current_time,
                                                                                 "time_zone": time_zone,
                                                                                 # "headers":["component_name","component_type"],
                                                                                 "script_version": SCRIPT_VERSION
                                                                                 }}, upsert=True).acknowledged:
                print('update sucess')

        except Exception as e:
            print('Error:' + str(e))


