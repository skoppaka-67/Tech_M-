import timeit
from threading import Thread
import pytz, openpyxl
from pymongo import MongoClient
import re, os, sys, copy, datetime
import time
import LocalUtils, config

# Loading the config json
# config = LocalUtils.loadConfig()
"Version   :   Latest with file xref added."
# Setting Application timezone
time_zone = 'Asia/Calcutta'
tz = pytz.timezone(time_zone)

log_directory = "./logs/"

client = MongoClient(config.database['hostname'], config.database['port'])
db = client[config.database['database_name']]


class XReferenceCobol(Thread):
    def __init__(self):
        Thread.__init__(self)

    def run(self):
        # CONSTANTS
        METADATA = []
        COBOL_FILE_LIST = []
        COBOL = config.codebase_information['COBOL']['folder_name']
        COPYBOOK = config.codebase_information['COPYBOOK']['folder_name']

        # Specify the folder where the workbook is present
        file_location = config.codebase_information['code_location']
        # Specify the file name
        file_name = "validation_output.xlsx"
        # Specify the sheet name that contains the data
        sheet_name = "Sheet1"

        # Excel Initialization
        # wb = load_workbook(file_location + file_name, data_only=True)
        wb = openpyxl.Workbook()
        sh = wb.create_sheet("Mysheet")

        # function
        def between(value, a, b):
            # Find and validate before-part.
            pos_a = value.find(a)
            if pos_a == -1: return ""
            # Find and validate after part.
            pos_b = value.rfind(b)
            if pos_b == -1: return ""
            # Return middle part.
            adjusted_pos_a = pos_a + len(a)
            if adjusted_pos_a >= pos_b: return ""
            return value[adjusted_pos_a:pos_b]

        def fetchNextWord(line_input, word):
            try:
                word_list1 = line_input.split()

                word_list = re.split(word, line_input, flags=re.IGNORECASE)

                position = word_list1.index(word)

                return word_list1[position + 1]
            except Exception as e:
                print('fetchNextWord failed due to' + e + 'on line' + line_input[:-1])
                return None

        def getFiles(file_type, file_extension) -> list:
            # Generating directory of COBOL files
            try:
                parent_folder = file_location + '\\' + file_type
                print(parent_folder)
                print('parent folder listing', os.listdir(parent_folder))
                files_w_extension = [x for x in os.listdir(parent_folder) if re.match('.+\.' + file_extension, x)]
            except (FileNotFoundError):
                print('Rename the folder to \'' + file_type + '\' and try again... ')
                sys.exit(0)
            except Exception as e:
                print(str(e))
                sys.exit(0)

            non_file_count = len(COBOL_FILE_LIST) - len(files_w_extension)
            if non_file_count > 0:
                print('WARNING: ' + (str(non_file_count)) + ' File(s) do not have a .cbl extension')

            return files_w_extension

        # Validating the project folder
        if LocalUtils.validateProject(file_location):

            # Fetch all the cobol files names from the project folder defined earlier
            # COBOL_FILE_LIST = copy.deepcopy(getFiles(COBOL, 'CO'))

            for file in getFiles(COBOL, 'cbl'):
                COBOL_FILE_LIST.append(file)

            COBOL_FILE_LIST5 = []
            print('List of cobol files to be processed', COBOL_FILE_LIST)
            for eachFile in COBOL_FILE_LIST5:
                # print('Processing file: ', eachFile)
                # print('Collected metadata:',json.dumps(METADATA,indent=4))

                # Setting the static COMPONENT NAME to be used while generating the output
                COMPONENT_NAME = eachFile
                print(COMPONENT_NAME)
                try:
                    file = open(file_location + '\\' + COBOL + '\\' + COMPONENT_NAME, 'r')
                except:
                    print('Could not open\n' + 'File location : ' + file_location)
                    print('Folder name : ' + COBOL)
                    print(COMPONENT_NAME)

                IN_IDENTIFICATION_DIVISION = False
                IN_ENVIRONMENT_DIVISION = False
                IN_DATA_DIVISION = False
                IN_WORKING_STORAGE_SECTION = False
                IN_LINKAGE_SECTION = False
                IN_PROCEDURE_DIVISION = False

                # Expanding the copybook for working storage section alone.

                PD_FlAG = False
                # print(filename)
                # file_handle = open(filename, errors="ignore")
                for line in file:
                    try:
                        line = line[6:72]
                        # print(line)
                        if line[0] == '*':
                            continue
                        if line.startswith("*"):
                            continue
                        else:
                            copyfile = open(file_location + '\\' + "DataD_lines.CO", "a")

                            # if not line[5] == 'd' or line[5] == 'D':
                            if line.__contains__("PROCEDURE") and line.__contains__("DIVISION"):
                                PD_FlAG = True

                            if PD_FlAG != True:

                                line_list = line.split()

                                for iter in line_list:
                                    if iter.__contains__("COPY") and line.strip().startswith('COPY '):

                                        var = (len(line_list))
                                        if var >= 2:
                                            copyname = line_list[1].replace('"', "")

                                            # if copyname.__contains__(","):
                                            #     copyname_list = copyname.split(",")
                                            #
                                            #     var = len(copyname_list)
                                            #     copyname = copyname_list[var-1]
                                            #
                                            copyname = copyname[:-1] + '.cpy'

                                            Copyfilepath = file_location + '\\' + "COPYBOOK" + '\\' + copyname

                                            if os.path.isfile(Copyfilepath):
                                                tempcopyfile = open(Copyfilepath, "r")
                                                copyfile.write("#########" + " " + "BEGIN" + " " + copyname + '\n')
                                                k = 0
                                                for lines in tempcopyfile.readlines():
                                                    k = k + 1
                                                    # print(k,lines[6:72])
                                                    if len(lines) > 7:
                                                        if lines[6] == "*":
                                                            continue
                                                        # print(k)
                                                        # print()
                                                        copyfile.write(lines[6:72])
                                                        copyfile.write('\n')
                                                copyfile.write("#####" + " " + " END" + "####" + '\n')
                                            # else:

                            copyfile.write(line + '\n')

                        copyfile.close()

                    except Exception:

                        pass

                try:

                    file1 = open(file_location + '\\' + "DataD_lines.CO", 'r')
                except:
                    print('Could not open\n' + 'File location : ' + file_location)
                    print('Folder name : ' + COBOL)
                    print(COMPONENT_NAME)

                INDIRECT_CALL_VARS = set()
                for index, line in enumerate(file1):
                    # print(line)
                    if len(line) > 4:
                        # print(line)
                        line = line
                    '''
                    This loop capture the following
                        * Direct call statements
                        * Indirect call statement variable names
                        * Capturing COPY statements
                        * Capturing CALL statements
                    '''
                    try:
                        # Skipping line if it is a comment
                        if line[0] == '*' or line[0] == '#':
                            continue
                        else:
                            # Check if the line conatins a call statement
                            if re.match('^\s*CALL\s.*', line, re.IGNORECASE) or re.match('^\s*call .*', line):

                                # Check if the line contains a direct call

                                if re.match('\'.*\'', line.split()[1]) or re.match('".*"', line.split()[1]):
                                    # print("fff",line)
                                    # Direct call within quotes found, hence adding to metadata directly
                                    METADATA.append(
                                        {'component_name': COMPONENT_NAME.split('.')[0], 'component_type': 'COBOL',
                                         'called_name': line.split()[1][1:-1].replace('"', "").replace('.', ''),
                                         'called_type': 'COBOL',
                                         'calling_app_name': 'UNKNOWN', 'called_app_name': 'UNKNOWN',
                                         'step_name': '', 'disp': '', 'comments': '', 'dd_name': '',
                                         'file_name': ''})
                                elif line.split()[1] == "PROGRAM":
                                    if re.match('\'.*\'', line.split()[2]) or re.match('".*"', line.split()[2]):

                                        # Direct call within quotes found, hence adding to metadata directly
                                        METADATA.append(
                                            {'component_name': COMPONENT_NAME.split('.')[0], 'component_type': 'COBOL',
                                             'called_name': line.split()[2][1:-1].replace('"', "").replace('.',
                                                                                                           '') + '.CO',
                                             'called_type': 'COBOL',
                                             'calling_app_name': 'UNKNOWN', 'called_app_name': 'UNKNOWN',
                                             'step_name': '', 'disp': '', 'comments': '', 'dd_name': '',
                                             'file_name': ''})
                                    else:
                                        INDIRECT_CALL_VARS.add(line.split()[2])


                                else:
                                    # Call statement is on a variable, storing for resovling later
                                    INDIRECT_CALL_VARS.add(line.split()[1])

                                    # print("iiiiiii",line,INDIRECT_CALL_VARS)

                            # Caputring COPY statements
                            if re.match('^\s*COPY\s.*', line, re.IGNORECASE) or re.match('.* copy .*', line):

                                # questionable contidion, probably not evne being checked??
                                if re.match('^\s*COPY\s.*', line, re.IGNORECASE) or re.match('.* copy[^\S\n\t]*\.',
                                                                                             line):

                                    linet = line.split()
                                    linet = linet[1].replace('"', "")
                                    if linet.strip().endswith('.'):
                                        linet = linet[:-1]

                                    # print("capu",linet)
                                    # #print('CAPY', line.split()[line.split().index("COPY") + 1][:-1])
                                    # METADATA.append({'component_name': COMPONENT_NAME, 'component_type': 'COBOL',
                                    #                  'called_name': line.split()[line.split().index("COPY") + 1][:-1],
                                    #                  'called_type': 'COPYBOOK', 'calling_app_name': 'UNKNOWN',
                                    #                  'called_app_name': 'UNKNOWN', 'step_name': '', 'disp': '',
                                    #                  'comments': '', 'dd_name': '', 'file_name': ''})

                                    METADATA.append(
                                        {'component_name': COMPONENT_NAME.split('.')[0], 'component_type': 'COBOL',
                                         'called_name': linet,
                                         'called_type': 'COPYBOOK', 'calling_app_name': 'UNKNOWN',
                                         'called_app_name': 'UNKNOWN', 'step_name': '', 'disp': '',
                                         'comments': '', 'dd_name': '', 'file_name': ''})

                                elif re.match('^\s*COPY\s.*', line) or re.match('^\s*copy.*', line):
                                    # print("ccccccccccccccccccccccccoooooooooooooooooooooooooooop")
                                    a = line.split()[line.split().index("COPY") + 1]
                                    if a[len(a) - 1] == '.':
                                        a = a[:-1]
                                        if a[len(a) - 1] == '"':
                                            a = a[1:-1]
                                    elif a[len(a) - 1] == '"':
                                        a = a[1:-1]

                                    METADATA.append(
                                        {'component_name': COMPONENT_NAME.split('.')[0], 'component_type': 'COBOL',
                                         'called_name': a.replace("'", ""),
                                         'called_type': 'COPYBOOK', 'calling_app_name': 'UNKNOWN',
                                         'called_app_name': 'UNKNOWN', 'step_name': '', 'disp': '',
                                         'comments': '',
                                         'dd_name': '', 'file_name': ''})
                            elif re.match('.*\sINCLUDE\s.*', line) or re.match('.*\sinclude.*', line):
                                # print(index,line[:-1],'PANDA')
                                if fetchNextWord(line, 'INCLUDE') is not None:
                                    included_component = fetchNextWord(line, 'INCLUDE')
                                    # print(
                                    #    'Successfully extracted the INCLUDED component :' + included_component)
                                    METADATA.append(
                                        {'component_name': COMPONENT_NAME.split('.')[0], 'component_type': 'COBOL',
                                         'called_name': included_component.replace("'", "").replace('.', ''),
                                         'called_type': 'DCLGEN', 'calling_app_name': 'UNKNOWN',
                                         'called_app_name': 'UNKNOWN', 'step_name': '', 'disp': '',
                                         'comments': '', 'dd_name': '', 'file_name': ''})

                            elif re.match('^\s*[+][+]INCLUDE.*', line):
                                Name = line.split()
                                METADATA.append(
                                    {'component_name': COMPONENT_NAME.split('.')[0], 'component_type': 'COBOL',
                                     'called_name': Name[1].strip(),
                                     'called_type': 'COPYBOOK', 'calling_app_name': 'UNKNOWN',
                                     'called_app_name': 'UNKNOWN', 'step_name': '', 'disp': '',
                                     'comments': '', 'dd_name': '', 'file_name': ''})



                    except Exception as e:
                        print('Bad line ' + str(index) + 'in ' + COMPONENT_NAME + '| Due to:' + str(e))

                # print('Indirect call variables, capture so far.',INDIRECT_CALL_VARS)
                file1.close()
                print("inderect", INDIRECT_CALL_VARS)

                WS_FLAG = True
                PDIV_FLAG = True
                MOVE_TRACK_VARS = []

                # Buffer Flag
                buffer_flag = False
                # Buffer Strig
                buffer_String = ''

                file = open(file_location + '\\' + "DataD_lines.CO", 'r')
                last_pos = file.tell()
                line = file.readline()

                index = 0
                # for index, line in enumerate(file):
                while line != '':
                    # print("ilne",line)
                    if buffer_flag:
                        if re.match(re.compile('.*\.*'), line):
                            # print('Closing the buffer')
                            line = ((buffer_String + line).replace('\n', '')).replace('\t', ' ')
                            # print('Proud colletion', line)
                            buffer_String = ''
                            buffer_flag = False
                            continue
                        else:
                            # print('Collecting lines')
                            buffer_String = buffer_String + line
                            index = index + 1
                            last_pos = file.tell()
                            line = file.readline()
                            continue

                    try:

                        if line.strip() == '':
                            index = index + 1
                            last_pos = file.tell()
                            line = file.readline()
                            continue

                        if len(line.strip()) < 3:
                            index = index + 1
                            last_pos = file.tell()
                            line = file.readline()
                            continue

                        if line[0] == '*':
                            index = index + 1
                            last_pos = file.tell()
                            line = file.readline()
                            continue
                        else:

                            # print(line.split()[0])
                            if line.split()[0] == 'WORKING-STORAGE' or line.split()[0] == 'working-storage':
                                # print("insed")
                                WS_FLAG = True
                            elif line.split()[0] == 'LINKAGE' or line.split()[0] == 'linkage':
                                WS_FLAG = False
                            if re.match('.*PROCEDURE\s*DIVISION.*', line) or re.match('.*procedure\s*division.*', line):
                                PDIV_FLAG = True

                        if WS_FLAG:
                            for var in INDIRECT_CALL_VARS:
                                # Capturing indirect CALL statements
                                # if re.match(re.compile('.*' + var + '.*PIC.*'), line):
                                #     print('Found declaration of indirect CALL statement('+var+') at line'+line[:-1])
                                #     # Checking if VALUE is assigned to varible
                                #     if re.match('.*PIC.*VALUE.*',line):
                                #         print('Declaration contains a default value')
                                #         # Fetching the constant value assigned to var
                                #         extracted_constant = re.search('\'.*\'', line.split()[len(line.split()) - 1])[0]
                                #         METADATA.append({'component_name': COMPONENT_NAME[:-4], 'component_type':COBOL,
                                #                          'called_name':extracted_constant,
                                #                          'called_type':COBOL,'application':'','step_name':'','disp':''})
                                #         if len(INDIRECT_CALL_VARS)>0:
                                #             INDIRECT_CALL_VARS.pop(0)
                                #         extracted_constant = ''
                                #     else:
                                #         print('This PIC does not have a constant VALUE defined, not processing'+line)
                                #         #TODO
                                # print("line",line)
                                if re.match(re.compile('.*\s' + var + '\s.*'), line):
                                    if re.match(re.compile('.*\s' + var + '\s.*\.'), line):
                                        print(var + ' declaration terminated in one line')
                                        # print("ooooooo",line)
                                        if re.match('.*\sVALUE\s.*', line) or re.match('.*value.*', line):
                                            print('Declaration contains a default value')

                                            # Fetching the constant value assigned to var
                                            # print('pppppppp',line)

                                            if ((line.split()[len(line.split()) - 1]) == "\'.") or (
                                                    (line.split()[len(line.split()) - 1]) == '\".'):
                                                # print("extra", line)
                                                extracted_constant = \
                                                    re.search('\'.*\'*', line.split()[len(line.split()) - 2])[0]
                                                # print("extra22",extracted_constant.replace(".","").replace("'",""))

                                            else:

                                                extracted_constant = \
                                                    re.search('\'.*\s*\'', line.split()[len(line.split()) - 1])[0]
                                                # print("in",extracted_constant)
                                            METADATA.append(
                                                {'component_name': COMPONENT_NAME.split('.')[0],
                                                 'component_type': COBOL,
                                                 'called_name': extracted_constant.replace(".", "").replace("'", ""),
                                                 'called_type': COBOL, 'calling_app_name': 'UNKNOWN',
                                                 'called_app_name': 'UNKNOWN', 'step_name': '', 'disp': '',
                                                 'comments': '', 'dd_name': '', 'file_name': ''})
                                            if len(INDIRECT_CALL_VARS) > 0:
                                                # print("iiii",INDIRECT_CALL_VARS[0])
                                                # INDIRECT_CALL_VARS.pop()
                                                INDIRECT_CALL_VARS.remove(var)
                                                # print("after")
                                            extracted_constant = ''
                                        else:
                                            print(
                                                'This PIC does not have a constant VALUE defined, not processing' + line)
                                            if len(INDIRECT_CALL_VARS) > 0:
                                                INDIRECT_CALL_VARS.remove(var)
                                                MOVE_TRACK_VARS.append(var)
                                    else:
                                        print(
                                            var + ' Appears to be a multiline fella, lets start collecting declaration!')
                                        buffer_String = buffer_String + line
                                        buffer_flag = True
                                        continue

                        elif PDIV_FLAG:
                            if re.match('.*INCLUDE.*', line) or re.match('.*include.*', line):
                                if fetchNextWord(line, 'INCLUDE') is not None:
                                    included_component = fetchNextWord(line, 'INCLUDE')
                                    print(
                                        'Successfully extracted the INCLUDED component : ' + included_component)
                                    # print("ffrrr", included_component)
                                    METADATA.append(
                                        {'component_name': COMPONENT_NAME.split('.')[0], 'component_type': 'COBOL',
                                         'called_name': included_component,
                                         'called_type': 'INCLUDE', 'calling_app_name': 'UNKNOWN',
                                         'called_app_name': 'UNKNOWN', 'step_name': '', 'disp': '',
                                         'comments': '', 'dd_name': '', 'file_name': ''})


                    except Exception as e:
                        print(
                            'Bad line encountered at ' + str(index) + 'in ' + COMPONENT_NAME + ' Due to ' + str(e))
                        print('Error on line {}'.format(sys.exc_info()[-1].tb_lineno))
                        print(line)
                    index = index + 1
                    last_pos = file.tell()
                    line = file.readline()
                file.close()

                list1 = []
                # print("move",MOVE_TRACK_VARS)
                for var1 in MOVE_TRACK_VARS:

                    file = open(file_location + '\\' + "DataD_lines.CO", 'r')
                    for line1 in file:

                        if re.search(' ' + var1 + ' ', line1):

                            if re.search(" MOVE ", line1) or re.search(" move ", line1):
                                list1.append(line1)
                                # print("MOVE", line1)
                                if re.match('.*\'.*\.*', line1):
                                    result = re.search(re.compile("\'.*\'"), line1)
                                    # print("move",result[0][1:-1])
                                    METADATA.append(
                                        {'component_name': COMPONENT_NAME.split('.')[0], 'component_type': 'COBOL',
                                         'called_name': result[0][1:-1],
                                         'called_type': 'COBOL', 'calling_app_name': 'UNKNOWN',
                                         'called_app_name': 'UNKNOWN', 'step_name': '', 'disp': '',
                                         'comments': '', 'dd_name': '', 'file_name': ''})

                    # extracted_constant = between(list[len(list) - 1], "MOVE", 'TO')
                    # METADATA.append({'component_name': COMPONENT_NAME[:-4], 'component_type': 'COBOL',
                    #                  'calling_name': extracted_constant.strip(),
                    #                  'calling_type
                    file.close()
                os.remove(file_location + '\\' + "DataD_lines.CO")

            # Fetch all the copybook files names from the project folder defined earlier
            COPYBK_FILE_LIST = copy.deepcopy(getFiles(COPYBOOK, '.cpy'))
            # print("copy",COPYBK_FILE_LIST)
            for file in getFiles(COPYBOOK, '*'):
                COPYBK_FILE_LIST.append(file)

            print('list of copybooks to be processed', COPYBK_FILE_LIST)

            for eachFile in COPYBK_FILE_LIST:

                COMPONENT_NAME = eachFile
                try:
                    file = open(file_location + '\\' + COPYBOOK + '\\' + COMPONENT_NAME, 'r')
                except:
                    print('Could not open\n' + 'File location : ' + file_location)
                    print('Folder name : ' + COPYBOOK)
                    print(COMPONENT_NAME)

                for index, line in enumerate(file):
                    if len(line) > 71:
                        line = line[6:]
                    '''
                    This loop capture the following
                        * Direct call statements
                        * Indirect call statement variable names
                        * Capturing COPY statements
                        * Capturing CALL statements
                    '''
                    try:
                        # Skipping line if it is a comment
                        if line[0] == '*':
                            continue
                        else:
                            # Check if the line conatins a call statement
                            if re.match('^\s*CALL\s.*', line) or re.match('^\s*call.*', line):
                                # Check if the line contains a direct call
                                if re.match('\'.*\'', line.split()[1]) or re.match('".*"', line.split()[1]):
                                    # Direct call within quotes found, hence adding to metadata directly
                                    METADATA.append(
                                        {'component_name': COMPONENT_NAME.split('.')[0], 'component_type': 'COPYBOOK',
                                         'called_name': line.split()[1][1:-1].replace('"', "").replace('.', ''),
                                         'called_type': 'COBOL',
                                         'calling_app_name': 'UNKNOWN', 'called_app_name': 'UNKNOWN',
                                         'step_name': '', 'disp': '', 'comments': '', 'dd_name': '',
                                         'file_name': ''})
                                elif line.split()[1] == "PROGRAM":
                                    if re.match('\'.*\'', line.split()[2]) or re.match('".*"', line.split()[2]):
                                        # Direct call within quotes found, hence adding to metadata directly
                                        METADATA.append(
                                            {'component_name': COMPONENT_NAME.split('.')[0], 'component_type': 'COBOL',
                                             'called_name': line.split()[2][1:-1].replace('"', "").replace('.', ''),
                                             'called_type': 'COBOL',
                                             'calling_app_name': 'UNKNOWN', 'called_app_name': 'UNKNOWN',
                                             'step_name': '', 'disp': '', 'comments': '', 'dd_name': '',
                                             'file_name': ''})
                                    else:
                                        INDIRECT_CALL_VARS.add(line.split()[2])
                                else:
                                    # Call statement is on a variable, storing for resovling later
                                    print("copy_call", line.split()[1])
                                    INDIRECT_CALL_VARS.add(line.split()[1])

                            # Caputring COPY statements
                            if re.match('.* COPY .*', line) or re.match('.* copy .*', line):

                                # questionable contidion, probably not evne being checked??
                                # if re.match('.* COPY .*\.', line) or re.match('.* copy .*\.', line):
                                #     # print('CAPY', line.split()[line.split().index("COPY") + 1][:-1])
                                #     METADATA.append({'component_name': COMPONENT_NAME[:-4], 'component_type': 'COPYBOOK',
                                #                      'called_name': line.split()[line.split().index("COPY") + 1][:-1],
                                #                      'called_type': 'COPYBOOK', 'calling_app_name': 'UNKNOWN',
                                #                      'called_app_name': 'UNKNOWN', 'step_name': '', 'disp': '',
                                #                      'comments': '', 'dd_name': '', 'file_name': ''})
                                if re.match('.*COPY.*', line) or re.match('.*copy.*', line):
                                    a = line.split()[line.split().index("copy") + 1]
                                    if a[len(a) - 1] == '.':
                                        a = a[:-1]
                                        if a[len(a) - 1] == '"':
                                            a = a[1:-1]
                                    elif a[len(a) - 1] == '"':
                                        a = a[1:-1]

                                    METADATA.append(
                                        {'component_name': COMPONENT_NAME.split('.')[0], 'component_type': 'COPYBOOK',
                                         'called_name': a.replace("'", "").replace('.', ''),
                                         'called_type': 'COPYBOOK', 'calling_app_name': 'UNKNOWN',
                                         'called_app_name': 'UNKNOWN', 'step_name': '', 'disp': '',
                                         'comments': '',
                                         'dd_name': '', 'file_name': ''})

                            elif re.match('^\s*INCLUDE.*', line.strip()) or re.match('.*\sinclude.*', line):
                                # print("zfsfVZVZVZVZVz",line)
                                # print(index,line[:-1],'PANDA')
                                if fetchNextWord(line, 'INCLUDE') is not None:
                                    included_component = fetchNextWord(line, 'INCLUDE')
                                    # print(
                                    #    'Successfully extracted the INCLUDED component :' + included_component)
                                    METADATA.append(
                                        {'component_name': COMPONENT_NAME.split('.')[0], 'component_type': 'COPYBOOK',
                                         'called_name': included_component.replace("'", "").replace('.', ''),
                                         'called_type': 'INCLUDE', 'calling_app_name': 'UNKNOWN',
                                         'called_app_name': 'UNKNOWN', 'step_name': '', 'disp': '',
                                         'comments': '', 'dd_name': '', 'file_name': ''})

                            elif re.match('^\s*[+][+]INCLUDE.*', line):

                                Name = line.split()
                                METADATA.append(
                                    {'component_name': COMPONENT_NAME.split('.')[0], 'component_type': 'COPYBOOK',
                                     'called_name': Name[1].strip(),
                                     'called_type': 'COPYBOOK', 'calling_app_name': 'UNKNOWN',
                                     'called_app_name': 'UNKNOWN', 'step_name': '', 'disp': '',
                                     'comments': '', 'dd_name': '', 'file_name': ''})
                    except Exception as e:
                        print('Bad line ' + str(index) + 'in ' + COMPONENT_NAME + '| Due to:' + str(e))

            print('List of all the copybooks to be processed', )

            temp_file_path = "D:\\DB-Python\\textfile"
            temp_text_file_path = "D:\\DB-Python\\textfile_spaced"
            i = 0
            j = 0
            COBOL_FILE_LIST = copy.deepcopy(getFiles(COBOL, 'cbl'))
            # print(getFiles(COBOL, 'cbl'))

            copy_metadata = []
            copy_metadata1 = []
            # copy_metadata1=cicsfun(COBOL_FILE_LIST,file_location,COBOL)

            file_metadata = process_cobol_file(COBOL_FILE_LIST, file_location, COBOL)
            # file_metadata=[]

            # print("file", file_metadata)

            # copy_metadata=cicsfun(COPYBK_FILE_LIST,file_location,COPYBOOK)

            # print("copy",copy_metadata)

            for data in range(len(copy_metadata)):
                METADATA.append(copy_metadata[data])

            # db_insert(METADATA)
            # METADATA.clear()

            for data1 in range(len(copy_metadata1)):
                METADATA.append(copy_metadata1[data1])
            # db_insert(METADATA)
            # METADATA.clear()

            for data2 in range(len(file_metadata)):
                METADATA.append(file_metadata[data2])
            #
            # db_insert(METADATA)
            # METADATA.clear()

            print("mea", METADATA)
            db_data = {"data": METADATA,
                       "headers": ["file_name", "component_name", "component_type", "calling_app_name", "called_name",
                                   "called_type", "called_app_name", "dd_name", "disp", "step_name", "comments"]}

            try:
                keys = list(db_data.keys())
                print('parent keys', keys)

                if 'data' in keys:
                    # fetching headers
                    x_COBOL_report_header_list = db_data['headers']
                    print('COBOL Report header list', x_COBOL_report_header_list)
                    # Adding header field to db_data
                    db_data['headers'] = x_COBOL_report_header_list

                    if len(db_data['data']) == 0:
                        print({"status": "failure", "reason": "data field is empty"})
                    else:
                        # Delete all COBOl associated records in the table
                        previousDeleted = False
                        try:
                            if db.cross_reference_report_file.delete_many(
                                    {"$or": [{"component_type": "COBOL"},
                                             {"component_type": "COPYBOOK"}]}).acknowledged:
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

                        if previousDeleted:

                            try:

                                db.cross_reference_report_file.insert_many(db_data['data'])
                                print('db inserteed bro')
                                # updating the timestamp based on which report is called
                                current_time = datetime.datetime.now(tz=tz).strftime("%A, %d. %B %Y %I:%M%p")
                                # Setting the time so that we know when each of the JCL and COBOLs were run

                                # db.cross_reference_report.insert_one({"type":"metadata", "JCL":{"last_updated_on":ct},"COBOL":{"last_updated_on":ct}})

                                if db.cross_reference_report_file.count_documents({"type": "metadata"}) > 0:
                                    print('meta happen o naw',
                                          db.cross_reference_report_file.update_one({"type": "metadata"},
                                                                               {"$set": {
                                                                                   "COBOL.last_updated_on": current_time,
                                                                                   "COBOL.time_zone": time_zone,
                                                                                   "headers": x_COBOL_report_header_list
                                                                               }},
                                                                               upsert=True).acknowledged)
                                else:
                                    db.cross_reference_report_file.insert_one(
                                        {"type": "metadata",
                                         "COBOL": {"last_updated_on": current_time, "time_zone": time_zone},
                                         "headers": x_COBOL_report_header_list})

                                print(current_time)
                                print({"status": "success", "reason": "Successfully inserted data and "})
                            except Exception as e:
                                print('Error' + str(e))
                                print({"status": "failed", "reason": str(e)})

            except Exception as e:
                print('Error: ' + str(e))
                print({"status": "failure", "reason": "Response json not in the required format"})
        else:
            print('Project folder validation FAILURE')


def db_insert(METADATA):
    db_data = {"data": METADATA,
               "headers": ["file_name", "component_name", "component_type", "calling_app_name", "called_name",
                           "called_type", "called_app_name", "dd_name", "disp", "step_name", "comments"]}

    try:
        keys = list(db_data.keys())
        print('parent keys', keys)

        if 'data' in keys:
            # fetching headers
            x_COBOL_report_header_list = db_data['headers']
            print('COBOL Report header list', x_COBOL_report_header_list)
            # Adding header field to db_data
            db_data['headers'] = x_COBOL_report_header_list

            if len(db_data['data']) == 0:
                print({"status": "failure", "reason": "data field is empty"})
            else:
                # Delete all COBOl associated records in the table
                previousDeleted = False
                try:
                    if db.cross_reference_report_file.delete_many(
                            {"$or": [{"component_type": "COBOL"}, {"component_type": "COPYBOOK"}]}).acknowledged:
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

                if previousDeleted:

                    try:

                        print("lll", db_data['data'])
                        db.cross_reference_report_file.insert_many(db_data['data'])
                        print('db inserteed bro')
                        # updating the timestamp based on which report is called
                        current_time = datetime.datetime.now(tz=tz).strftime("%A, %d. %B %Y %I:%M%p")
                        # Setting the time so that we know when each of the JCL and COBOLs were run

                        # db.cross_reference_report.insert_one({"type":"metadata", "JCL":{"last_updated_on":ct},"COBOL":{"last_updated_on":ct}})

                        if db.cross_reference_report_file.count_documents({"type": "metadata"}) > 0:
                            print('meta happen o naw',
                                  db.cross_reference_report_file.update_one({"type": "metadata"},
                                                                       {"$set": {
                                                                           "COBOL.last_updated_on": current_time,
                                                                           "COBOL.time_zone": time_zone,
                                                                           "headers": x_COBOL_report_header_list
                                                                       }},
                                                                       upsert=True).acknowledged)
                        else:
                            db.cross_reference_report_file.insert_one(
                                {"type": "metadata",
                                 "COBOL": {"last_updated_on": current_time, "time_zone": time_zone},
                                 "headers": x_COBOL_report_header_list})

                        print(current_time)
                        print({"status": "success", "reason": "Successfully inserted data and "})
                    except Exception as e:
                        print('Error' + str(e))
                        print({"status": "failed", "reason": str(e)})

    except Exception as e:
        print('Error: ' + str(e))
        print({"status": "failure", "reason": "Response json not in the required format"})


def cicsfun(COBOL_FILE_LIST1, file_location1, COBOL1):
    i = 0
    j = 0
    METADATA = []
    DATA = COBOL1
    for eachFile in COBOL_FILE_LIST1:
        i = i + 1
        # Setting the static COMPONENT NAME to be used while generating the output
        COMPONENT_NAME = eachFile
        print(COMPONENT_NAME)
        file = open(file_location1 + '\\' + DATA + '\\' + COMPONENT_NAME, 'r')
        # print("Asdf",file)
        in_exec_flag = False
        with open("textfile" + str(i) + '.txt', "a") as temp_file:
            temp_file.write(COMPONENT_NAME + '\n')
        for index, line in enumerate(file):
            j = j + 1
            line = line[6:72]
            if not len(line) > 0:
                continue
            if line[0] == "*":
                continue
            if line.__contains__("EXEC CICS") and line.__contains__("END-EXEC"):
                with open("textfile" + str(i) + '.txt', "a") as temp_file:
                    temp_file.write(line)
                    # string_bucket += line
            elif line.__contains__("EXEC CICS"):
                in_exec_flag = True
                string_bucket = ''
                string_bucket += line
                with open("textfile" + str(i) + '.txt', "a") as temp_file:
                    # temp_file.write(string_bucket)
                    temp_file.write(line)
                    # print(line)
            elif line.__contains__("END-EXEC"):
                in_exec_flag = False
                with open("textfile" + str(i) + '.txt', "a") as temp_file:
                    # temp_file.write(string_bucket)
                    # print("enummmm", line)
                    temp_file.write(line[7:71])
                    # string_bucket += ite
            elif in_exec_flag:
                with open("textfile" + str(i) + '.txt', "a") as temp_file:
                    temp_file.write(line[7:71])
                    # string_bucket += ite

        exists = os.path.isfile("textfile" + str(i) + '.txt')

        if exists:

            # Removing all spaces & linebreaks & EXEC SQL & END_EXEC
            with open("textfile" + str(i) + '.txt', "r+")as temp1_file:
                string_data = temp1_file.read()
                string_data = string_data
                # print("ooooo",string_data)
                dataspacereplace = re.sub(r"\s+", " ", string_data)
                # print(dataspacereplace)
                result = "    "
                # splitting it by line breaks
                datalinebreak = re.sub(r"EXEC CICS", "\nEXEC CICS", dataspacereplace)
                # print(datalinebreak)
                cleaned_line = datalinebreak.replace("EXEC CICS ", " ")
                # print(cleaned_line)
                final_cleaned_line = cleaned_line.replace("END-EXEC", "") or cleaned_line.replace("END-EXEC.",
                                                                                                  "")
                # print(final_cleaned_line)
                result = re.findall(r'send\s*map[^)-].*|receive\s*map.*', final_cleaned_line, re.IGNORECASE)
                result1 = re.findall(r'link\s*prog.*|xctl\s*prog.*|handle\s*abend.*', final_cleaned_line, re.IGNORECASE)
                Queue_List_TS = re.findall(r'writeq\s*ts.*|readq\s*ts.*|deleteq\s*ts.*', final_cleaned_line,
                                           re.IGNORECASE)
                Queue_List_TD = re.findall(r'writeq\s*td.*|readq\s*td.*|deleteq\s*td.*', final_cleaned_line,
                                           re.IGNORECASE)
                Other_List = re.findall(r'startbr\s.*|readnext\s.*|readprev\s.*|resetbr\s.*|endbr\s.*',
                                        final_cleaned_line, re.IGNORECASE)
                Operation_List = re.findall(r'read\s.*|write\s.*|rewrite\s.*|delete\s.*', final_cleaned_line,
                                            re.IGNORECASE)
                tran_list = re.findall(r'START\s*TRANSID\s*(\S*)', final_cleaned_line, re.IGNORECASE)

                # print("tran",tran_list,final_cleaned_line)

                if result != []:

                    for data in result:
                        print(data)
                        disp_para = data.split()
                        data = re.findall(r'\s*map\s*[(].*[)]', data, re.IGNORECASE)
                        if data == []:
                            continue
                        data = data[0]
                        data = re.sub(r"\s", "", data)
                        # print()
                        data = data.split(')')
                        data = data[0]
                        if ((data.__contains__('"')) or (data.__contains__("'"))):

                            data = data[5:]
                            length = len(data)
                            data = data[:length - 1]
                        else:
                            data = data[4:]
                        METADATA.append({'component_name': COMPONENT_NAME[:-4], 'component_type': 'COBOL',
                                         'called_name': data,
                                         'called_type': 'MAP', 'calling_app_name': 'UNKNOWN',
                                         'called_app_name': 'UNKNOWN', 'step_name': '', 'disp': disp_para[0],
                                         'comments': '', 'dd_name': '', 'file_name': ''})

                if tran_list != []:

                    for data in tran_list:
                        disp_para = data.replace("(", '').replace("'", "").replace(")", '')

                    METADATA.append({'component_name': COMPONENT_NAME[:-4], 'component_type': 'COBOL',
                                     'called_name': disp_para,
                                     'called_type': 'TRAN', 'calling_app_name': 'UNKNOWN', 'called_app_name': 'UNKNOWN',
                                     'step_name': '', 'disp': "",
                                     'comments': '', 'dd_name': '', 'file_name': ''})

                if result1 != []:

                    for data in result1:

                        data_dup = data
                        if data.__contains__('HANDLE') and data.__contains__("CANCEL"):
                            continue
                        disp_para = data.split()
                        data1 = data

                        data = re.findall(r'program\s*[(].*[)]', data, re.IGNORECASE)
                        if data == []:
                            data = re.findall(r'label\s*[(].*[)]', data1, re.IGNORECASE)
                        if data == []:
                            continue
                        data = data[0]
                        data = re.sub(r"\s", "", data)
                        data = data.split(')')
                        data = data[0]
                        if data_dup.__contains__('LABEL') or data_dup.__contains__('label'):
                            if ((data.__contains__('"')) or (data.__contains__("'"))):
                                data = data[7:]
                                length = len(data)
                                data = data[:length - 1]
                            else:
                                data = data[6:]
                        else:
                            if ((data.__contains__('"')) or (data.__contains__("'"))):
                                data = data[9:]
                                length = len(data)
                                data = data[:length - 1]
                            else:
                                data = data[8:]

                        # print(data)
                        # data=re.sub('[)]',"",data)
                        # print(data)
                        METADATA.append({'component_name': COMPONENT_NAME[:-4], 'component_type': 'COBOL',
                                         'called_name': data,
                                         'called_type': 'COBOL', 'calling_app_name': 'UNKNOWN',
                                         'called_app_name': 'UNKNOWN', 'step_name': '',
                                         'disp': disp_para[0],
                                         'comments': '', 'dd_name': '', 'file_name': ''})

                if Queue_List_TS != []:
                    for data in Queue_List_TS:
                        disp_para = data.split()

                        data = re.findall(r'queue\s*[(].*[)]', data, re.IGNORECASE)
                        if data == []:
                            continue
                        data = data[0]
                        data = re.sub(r"\s", "", data)
                        data = data.split(')')
                        # data = data.split()

                        data = data[0]
                        if ((data.__contains__('"')) or (data.__contains__("'"))):
                            data = data[7:]
                            length = len(data)
                            data = data[:length - 1]
                        else:
                            data = data[6:]

                        METADATA.append({'component_name': COMPONENT_NAME[:-4], 'component_type': 'COBOL',
                                         'called_name': data,
                                         'called_type': 'TSQ', 'calling_app_name': 'UNKNOWN',
                                         'called_app_name': 'UNKNOWN', 'step_name': '', 'disp': disp_para[0],
                                         'comments': '', 'dd_name': '', 'file_name': ''})
                if Queue_List_TD != []:
                    for data in Queue_List_TD:
                        disp_para = data.split()
                        data = re.findall(r'queue\s*[(].*[)]', data, re.IGNORECASE)
                        if data == []:
                            continue
                        data = data[0]
                        data = re.sub(r"\s", "", data)
                        data = data.split(')')
                        # data = data.split()
                        data = data[0]
                        if ((data.__contains__('"')) or (data.__contains__("'"))):
                            data = data[7:]
                            length = len(data)
                            data = data[:length - 1]
                        else:
                            data = data[6:]

                        METADATA.append({'component_name': COMPONENT_NAME[:-4], 'component_type': 'COBOL',
                                         'called_name': data,
                                         'called_type': 'TDQ', 'calling_app_name': 'UNKNOWN',
                                         'called_app_name': 'UNKNOWN', 'step_name': '',
                                         'disp': disp_para[0],
                                         'comments': '', 'dd_name': '', 'file_name': ''})
                if Other_List != []:
                    for data3 in Other_List:
                        print("hhh", data3)
                        disp_para = data3.split()
                        data = re.findall(r'file\s*[(].*[)]', data3, re.IGNORECASE)

                        if data != []:
                            data = data[0]
                            data = re.sub(r"\s", "", data)
                            data = data.split(')')
                            # data = data.split()
                            data = data[0]
                            if ((data.__contains__('"')) or (data.__contains__("'"))):
                                data = data[6:]
                                length = len(data)
                                data = data[:length - 1]
                            else:
                                data = data[5:]

                            METADATA.append({'component_name': COMPONENT_NAME[:-4], 'component_type': 'COBOL',
                                             'called_name': data,
                                             'called_type': 'FILE', 'calling_app_name': 'UNKNOWN',
                                             'called_app_name': 'UNKNOWN', 'step_name': '',
                                             'disp': '',
                                             'comments': '', 'dd_name': disp_para[0], 'file_name': ''})
                        else:
                            data = re.findall(r'DATASET\s*[(].*[)]', data3, re.IGNORECASE)
                            if data == []:
                                continue
                            data = data[0]
                            data = re.sub(r"\s", "", data)
                            data = data.split(')')
                            # data = data.split()
                            data = data[0]
                            if ((data.__contains__('"')) or (data.__contains__("'"))):
                                data = data[9:]
                                length = len(data)
                                data = data[:length - 1]
                            else:
                                data = data.split('(')[1]

                            METADATA.append({'component_name': COMPONENT_NAME[:-4], 'component_type': 'COBOL',
                                             'called_name': data,
                                             'called_type': 'FILE', 'calling_app_name': 'UNKNOWN',
                                             'called_app_name': 'UNKNOWN', 'step_name': '',
                                             'disp': '',
                                             'comments': '', 'dd_name': disp_para[0], 'file_name': ''})

                if Operation_List != []:

                    for data3 in Operation_List:

                        if not (data3.__contains__("FILE") or data3.__contains__("file") or data3.__contains__(
                                "DATASET")):
                            continue
                        disp_para = data3.split()
                        data = re.findall(r'file\s*[(].*[)]', data3, re.IGNORECASE)
                        if data != []:
                            data = data[0]
                            data = re.sub(r"\s", "", data)
                            data = data.split(')')
                            # data = data.split()
                            data = data[0]
                            if ((data.__contains__('"')) or (data.__contains__("'"))):
                                data = data[6:]
                                length = len(data)
                                data = data[:length - 1]
                            else:
                                data = data.split('(')[1]

                            METADATA.append({'component_name': COMPONENT_NAME[:-4], 'component_type': 'COBOL',
                                             'called_name': data,
                                             'called_type': 'FILE', 'calling_app_name': 'UNKNOWN',
                                             'called_app_name': 'UNKNOWN', 'step_name': '',
                                             'disp': disp_para[0],
                                             'comments': '', 'dd_name': '', 'file_name': ''})

                        else:

                            data = re.findall(r'DATASET\s*[(].*[)]', data3, re.IGNORECASE)
                            if data == []:
                                continue
                            data = data[0]
                            data = re.sub(r"\s", "", data)
                            data = data.split(')')
                            # data = data.split()
                            data = data[0]
                            if ((data.__contains__('"')) or (data.__contains__("'"))):
                                data = data[9:]
                                length = len(data)
                                data = data[:length - 1]
                            else:
                                data = data.split('(')[1]

                            METADATA.append({'component_name': COMPONENT_NAME[:-4], 'component_type': 'COBOL',
                                             'called_name': data,
                                             'called_type': 'FILE', 'calling_app_name': 'UNKNOWN',
                                             'called_app_name': 'UNKNOWN', 'step_name': '',
                                             'disp': '',
                                             'comments': '', 'dd_name': disp_para[0], 'file_name': ''})

                temp1_file.close()
                os.remove("textfile" + str(i) + '.txt')

                db_data = {"data": METADATA,
                           "headers": ["file_name", "component_name", "component_type", "calling_app_name",
                                       "called_name",
                                       "called_type", "called_app_name", "dd_name", "disp", "step_name", "comments"]}

    return METADATA


def fetch_filename(line):
    """
      Get a line and returns the file name and component name.

    Parameters
    ----------
    line: str
        A SELECT line from COBOL FILE-CONTROL.

    Returns
    -------
    called_name: str
        A flat file name SELECTED in the COBOL FILE-CONTROL.
    dd_name: str
        A ASSIGNED name given to the SELECTED flat file [Data Defination].

    Exception
    ---------
    error: str
        Print and Return Exception
    """
    try:

        # called_name = line[18:48].strip()
        # dd_name = line[55:].strip()
        # print("line",line)
        line = line.split()
        if line[1] == 'SELECT':
            if line[2] == "OPTIONAL":

                called_name = line[3]
            else:
                called_name = line[2]
            if line[4] == 'TO':
                dd_name = line[5]
            else:
                dd_name = line[4]
        elif line[0] == 'SELECT':
            if line[1] == "OPTIONAL":
                called_name = line[2]
            else:
                called_name = line[1]
            if line[3] == 'TO' and line[4] == "DISK":
                dd_name = line[5]
            elif line[3] == 'TO' and not line[4] == 'DISK':
                dd_name = line[4]
            elif line[1] == "OPTIONAL":
                dd_name = line[5]
            else:
                dd_name = line[3]

        if dd_name.startswith("UT-S-"):
            dd_name = dd_name.replace("UT-S-", "")

        if dd_name.endswith("."):
            dd_name = dd_name.replace(".", "")

        return called_name, dd_name

    except Exception as error:
        print(error)
        return str(error)


def process_cobol_file(COBOL_FILE_LIST1, file_location1, COBOL1):
    """
      Get the file path and return called_name, dd_name, access_mode within a dictionary.

          Parameters
    ----------
    file_path: str
        A location of the cobol file

    Returns
    -------
    complete_details: dict
        A dictionary with details of file operation through the COBOL code.
    """

    i = 0
    j = 0
    METADATA2 = []
    DATA = COBOL1
    complete_details = ""
    procFlag = False

    Key_Word_List = ["++INCLUDE", "DISPLAY", "ACCEPT", "INITIALIZE", "EXIT.", "IF", "EVALUATE", "INITIATE", "ADD",
                     "SUBTRACT", "DIVIDE", "MULTIPLY", "COMPUTE", "MOVE", "INSPECT", "STRING", "UNSTRING", "SET",
                     "SEARCH",
                     "CONTINUE", "END-IF.", "END-IF", "END-RETURN", "END-COMPUTE", "TERMINATE", "END-RETURN.",
                     "END-COMPUTE.", "CLOSE", "NEXT", "END-EVALUATE.", "END-EVALUATE", "WHEN", "READ", "WRITE",
                     "END-IF.", "END-PERFORM.", "END-PERFORM", "REWRITE", "DELETE", "START", "CALL", "PERFORM", "GO",
                     "STOP", "GOBACK.", "SORT", "MERGE", "EXEC", "ENTRY", "ELSE", "RETURN", "OPEN", "INPUT", "OUTPUT",
                     "I-O", "EXTEND"]

    for eachFile in COBOL_FILE_LIST1:
        complete_details = []
        i = i + 1
        # Setting the static COMPONENT NAME to be used while generating the output
        COMPONENT_NAME = eachFile

        file = file_location1 + '\\' + DATA + '\\' + COMPONENT_NAME

        print("file_location4", file_location1, file)
        """
          Get the file path and return called_name, dd_name, access_mode within a dictionary.

              Parameters
        ----------
        file_path: str
            A location of the cobol file

        Returns
        -------
        complete_details: dict
            A dictionary with details of file operation through the COBOL code.
        """

        # num_of_lines = sum(1 for line in open(file))

        ####################################################### copy expand

        # Making single line.
        currentpara = []
        onelinebuffer = []
        anotherparalist = []
        execflag1 = False
        onelineflag = False
        procFlag = False
        with open(file, "r+") as expanded_file:
            sql_flag = False
            for line in expanded_file.readlines():
                # print(line)
                line = line[6:72]
                if line.strip() == '' or line[
                    0] == '*' or line.strip() == "skip" or line.strip() == "skip" or line.strip() == 'eject':
                    continue
                else:
                    with open("Duplicatefile0" + '.txt', "a") as temp_file1:
                        line1 = line.split()

                        if line.strip().__contains__('EXEC SQL') or line.strip().__contains__('EXEC  SQL'):
                            sql_flag = True
                        if sql_flag:
                            if line.strip().__contains__('END-EXEC'):
                                sql_flag = False
                            continue

                        if len(line1) >= 2:
                            divisionline = line1[1]
                            if divisionline.__contains__('.'):
                                divisionlinelength = len(divisionline)
                                divisionline = divisionline[0:divisionlinelength - 1]
                            if line1[0] == "PROCEDURE" and divisionline == 'DIVISION':
                                procFlag = True
                                # open_flag = False
                        if procFlag:

                            # if line.strip().startswith("OPEN") and (line.strip().split()[1]=="INPUT"or line.strip().split()[1]=="OUTPUT"):
                            #     open_flag=True
                            # print(line)

                            module = re.findall(r'^\s[A0-Z9].*[-]*.*[.]', line)
                            Proc_regexx = re.findall(r'^\s*PROCEDURE\s*DIVISION.*', line)
                            if currentpara != [] and module != []:
                                currentpara.clear()
                            if module != [] or Proc_regexx:
                                if Proc_regexx != []:
                                    module = Proc_regexx
                                module = module[0]
                                module = re.sub("\sSECTION.", " SECTION.", module)
                                if onelinebuffer != []:
                                    line6 = ""
                                    for data in range(len(onelinebuffer)):
                                        line6 = line6 + onelinebuffer[data]

                                    line6 = line6
                                    temp_file1.write('\n')
                                    temp_file1.write(line6)
                                    onelinebuffer.clear()
                                if module.__contains__('.'):
                                    temp_file1.write('\n')
                                    temp_file1.write(module)
                                    currentpara.append(module)
                                    anotherparalist.append(module)
                                    temp_file1.write('\n')
                                    # print(module)
                                else:
                                    temp_file1.write('\n')
                                    module = module + '.'
                                    temp_file1.write(module)
                                    # print(module)
                                    anotherparalist.append(module)
                                    currentpara.append(module)
                                    temp_file1.write('\n')

                            else:
                                if currentpara != []:
                                    currentparastring = currentpara[0]
                                    line = re.sub('\n', '', line)
                                    line = line
                                onelinesplit = line.split('^')
                                actualline = onelinesplit[0]
                                firstword = actualline.split()
                                firstword = firstword[0]
                                # print(firstword)
                                if firstword == "EXEC":
                                    if onelinebuffer != []:
                                        line6 = ""
                                        for data in range(len(onelinebuffer)):
                                            line6 = line6 + onelinebuffer[data]
                                        line6 = line6
                                        temp_file1.write('\n')
                                        temp_file1.write(line6)
                                        onelinebuffer.clear()
                                    execflag1 = True
                                    temp_file1.write('\n')
                                    temp_file1.write(line)
                                    temp_file1.write('\n')
                                    continue
                                elif execflag1:
                                    temp_file1.write('\n')
                                    temp_file1.write(line)
                                    temp_file1.write('\n')
                                    if firstword == "END-EXEC" or firstword == "END-EXEC.":
                                        execflag1 = False
                                    continue
                                # print(line)
                                # if firstword in Key_Word_List and actualline.__contains__('. ') :
                                if firstword in Key_Word_List and actualline.strip().endswith('.'):
                                    if onelinebuffer != []:
                                        # print(line,line7 )
                                        line7 = ""
                                        for data in range(len(onelinebuffer)):
                                            line7 = line7 + onelinebuffer[data]
                                        line7 = line7
                                        temp_file1.write('\n')
                                        temp_file1.write(line7)
                                        temp_file1.write('\n')
                                        # if line.strip().startswith("INPUT ") or line.strip().startswith("OUTPUT "):

                                        temp_file1.write(line)
                                        # print(line)
                                        onelineflag = False
                                        onelinebuffer = []
                                        continue
                                    else:
                                        temp_file1.write('\n')
                                        temp_file1.write(line)
                                        temp_file1.write('\n')
                                        continue
                                elif firstword in Key_Word_List:
                                    if onelinebuffer != []:
                                        line5 = ""
                                        for data in range(len(onelinebuffer)):
                                            line5 = line5 + onelinebuffer[data]
                                            onelineflag = False
                                        line5 = line5
                                        temp_file1.write('\n')
                                        temp_file1.write(line5)
                                        onelinebuffer = []
                                        if firstword in Key_Word_List and actualline.__contains__('.'):
                                            temp_file1.write('\n')
                                            temp_file1.write(line)
                                            continue
                                        else:
                                            onelineflag = True
                                            actualline = actualline + ' ' + ' '
                                            onelinebuffer.append(actualline)
                                            continue
                                    else:
                                        onelineflag = True
                                        actualline = actualline.replace("\n", "") + ' '
                                        # print("actua;",actualline)
                                        onelinebuffer.append(actualline)
                                        continue
                                elif actualline.__contains__('.'):
                                    if onelineflag:
                                        # print(actualline)
                                        onelineflag = False
                                        actualline = actualline + '           '
                                        onelinebuffer.append(actualline)
                                        line = ""
                                        for data in range(len(onelinebuffer)):
                                            line = line + onelinebuffer[data]
                                        temp_file1.write('\n')
                                        temp_file1.write(line)
                                        onelinebuffer = []
                                        continue
                                elif onelineflag:
                                    actualline = actualline + ' ' + ' '
                                    onelinebuffer.append(actualline)
                                    continue
                                onelinebuffer = []
                        else:
                            # print(line)
                            temp_file1.write(line + '\n')
                    temp_file1.close()
        expanded_file.close()

        with open("Duplicatefile0.txt", 'r+') as input_data:
            # with open(file, "r+") as input_data:
            file_flag = False
            line_flag1 = False
            lines = ""
            for line in input_data:
                try:
                    if line.strip().startswith("*") or len(line.strip()) == 0:
                        continue
                    else:
                        #
                        copyfile = open(file_location1 + '\\' + "DataD_lines.CO", "a")

                        # if not line[5] == 'd' or line[5] == 'D':

                        line_list = line.split()

                        # lines_list4=line.split()
                        for iter in line_list:
                            # print("iter",iter)
                            if iter.upper().strip().startswith("COPY"):
                                var = (len(line_list))

                                if var >= 2:
                                    # print(iter)
                                    if line_list[var - 1].__contains__('"'):
                                        copyname = line_list[var - 1].replace('"', "")
                                        copyname = copyname[:-1]
                                        Copyfilepath = file_location1 + '\\' + "COPYBOOK" + '\\' + copyname + 'cpy'
                                    else:
                                        copyname = line_list[1].replace('"', "")
                                        # copyname = copyname[:-1]
                                        Copyfilepath = file_location1 + '\\' + "COPYBOOK" + '\\' + copyname + 'cpy'

                                    # if copyname.__contains__(","):
                                    #     copyname_list = copyname.split(",")
                                    #
                                    #     var = len(copyname_list)
                                    #     copyname = copyname_list[var-1]
                                    #

                                    if os.path.isfile(Copyfilepath):
                                        tempcopyfile = open(Copyfilepath, "r")
                                        copyfile.write("#########" + " " + "BEGIN" + " " + copyname + '\n')
                                        lines = ""
                                        line_flag = False

                                        for copylines in tempcopyfile.readlines():
                                            copylines = copylines[6:72]
                                            if copylines.strip().startswith("SELECT ") and copylines.strip().endswith(
                                                    '.'):
                                                copyfile.write(copylines + '\n')
                                                copyfile.write('\n')
                                                continue
                                            elif copylines.strip().startswith(
                                                    "SELECT ") and not copylines.strip().endswith('.'):
                                                line_flag = True
                                                lines = lines + copylines.replace("\n", "")
                                                continue
                                            elif line_flag and copylines.strip().endswith('.'):
                                                lines = lines + copylines + "\n"
                                                # print("1",lines)
                                                copyfile.write(lines)
                                                lines = ""
                                                line_flag = False
                                                continue
                                            elif line_flag:
                                                lines = lines + copylines.replace("\n", "")
                                                continue

                                            else:
                                                # print("2",copylines)
                                                copyfile.write(copylines + '\n')
                                                continue

                                        copyfile.write("#####" + " " + " END" + "####" + '\n')
                                    # else:

                        file_control_regexx = re.findall(r'^\s*FILE-CONTROL.*', line)
                        data_division_regexx = re.findall(r'^\s*DATA\s*DIVISION.*', line)

                        if file_control_regexx != []:
                            # print("yyy",line)
                            file_flag = True

                        if file_flag:

                            # print("jjjjjjjjj",line_flag1,line.strip().endswith('.'))
                            if line.strip().startswith("SELECT ") and line.strip().endswith('.'):
                                copyfile.write(line + '\n')
                                # print(line)
                                # copyfile.write('\n')
                                continue
                            elif line.lstrip().startswith("SELECT ") and not line.strip().endswith('.'):
                                # print("kkk",line)
                                line_flag1 = True
                                lines = lines + line.replace("\n", "")
                                continue
                            elif (line_flag1 and line.strip().endswith('.')):
                                # print("kkk1", line)
                                lines = lines + line + "\n"
                                copyfile.write(lines)
                                lines = ""
                                line_flag1 = False
                                continue
                            elif line_flag1:
                                # print("kkk2",line)
                                lines = lines + line.replace("\n", "")
                                continue

                            else:

                                if line.strip() == "OPEN":
                                    continue

                                if line.strip().startswith("OPEN "):
                                    line = line.split(" OPEN")
                                    line = line[1]

                                if (line.strip().startswith("INPUT ") or line.strip().startswith(
                                        "OUTPUT ") or line.strip().startswith("I-O ") or line.strip().startswith(
                                        "EXTEND ")) and not line.split()[1] == "PROCEDURE":

                                    if len(line.strip().split()) == 2 and line.strip().split()[1].endswith('.'):
                                        copyfile.write("      OPEN " + line + '\n')
                                        continue

                                    elif len(line.strip().split()) == 2 and not line.strip().split()[1].endswith('.'):

                                        copyfile.write("      OPEN " + line + '\n')
                                        continue

                                    elif len(line.strip().split()) > 2:

                                        if line.strip().startswith("INPUT ") or line.strip().startswith(
                                                "OUTPUT ") or line.strip().startswith(
                                                'I-O ') or line.strip().startswith("EXTEND ") or line.strip.startswith(
                                                "OPEN "):

                                            mode_list = ["INPUT", "OUTPUT", "I-O", "EXTEND"]

                                            check_line = line.split()

                                            for split_data in check_line:
                                                if split_data in mode_list:
                                                    mode = split_data
                                                else:
                                                    copyfile.write("       OPEN " + mode + ' ' + split_data + '\n')

                                        # data5=line.split()
                                        # for k in range(len(data5)):
                                        #     copyfile.write("    OPEN "+data5[0]+' '+data5[k+1]+'\n')
                                        #     if k+2==len(data5):
                                        #         break
                                        # continue

                                copyfile.write(line + '\n')
                                # print('pppppppppppppppp', line)
                                # if line.strip()=="OPEN":
                                #     open_flag==True
                                #     open_line=line
                                # if open_flag and (line.strip() =="INUPUT" or line.strip()=="OUTPUT"):
                                #     open_line=open_line+' '+line

                                continue

                        # print(data_division_regexx)
                        if data_division_regexx != []:
                            # print("ggggggggggggggggggggggggg",data_division_regexx)
                            file_flag = False
                            line_flag1 = False
                        # print("4",line)
                        copyfile.write(line + '\n')

                    copyfile.close()

                except Exception as e:
                    print("except", e)
                    pass

        ##################################

        num_of_lines = sum(1 for line in open(file_location1 + '\\'"DataD_lines.CO"))
        current_line = 0

        sample_line = ""
        mul_flag = False
        details = {}
        open_flag = False
        second_flag = False
        # print("hhhhhhhhhhhhh",file_location1+'\\'+"DataD_lines.CO")

        with open(file_location1 + '\\' + "DataD_lines.CO", 'r') as input_data:

            for line in input_data:
                # print(line)
                line = line.replace("&", " ")
                current_line += 1
                cleaned_line = line.strip()
                regex_line = re.search("FILE-CONTROL", cleaned_line)
                if regex_line != None:
                    break

            for line in input_data:
                # line = line.replace("&", " ")
                # print("jjjjjj",line)
                current_line += 1
                if re.search("SELECT", line):
                    control = {"file_name": "",
                               "component_name": "",
                               "called_name": "",
                               "component_type": "COBOL",
                               "comments": "",
                               "step_name": "",
                               "called_type": "FILE",
                               "dd_name": "",
                               "access_mode": "",
                               "calling_app_name": "",
                               "called_app_name": "",
                               "temp_file_name": ""
                               }

                    called_name, dd_name = fetch_filename(line)

                    control["file_name"] = file.split("\\")[-1]
                    # print("fffffffff",file.split("\\")[-1] )
                    file_data = file.split("\\")[-1]
                    control["component_name"] = file_data[:-4]
                    control["called_name"] = called_name
                    control["dd_name"] = dd_name
                    details.update({called_name: control})
                cleaned_line = line.strip()
                regex_line = re.search("DATA DIVISION", cleaned_line)

                if regex_line != None:
                    break

            lines_list = ""
            flag = True

            # SECTION TO GET INPUT MODES
            sql_flag = False
            while flag == True:
                for line in input_data:
                    current_line += 1
                    # to avoid open statement:
                    if line.strip() == "":
                        continue
                    if line.strip().__contains__('EXEC SQL') or line.strip().__contains__('EXEC  SQL'):
                        sql_flag = True
                    if sql_flag:
                        if line.strip().__contains__('END-EXEC'):
                            sql_flag = False
                        continue

                    # To handle Multiline added by mothi.
                    # #
                    # if (line.split()[0]=="OPEN" and len(line.split()==1)) or mul_flag:
                    #     sample_line =sample_line+line.replace('\n','')
                    #     mul_flag=True
                    #     split_line=line.split()
                    #     if len(split_line)==3:
                    #         mul_flag=False
                    #         line=sample_line+'\n'
                    #         open_flag=True
                    #         sample_line=""
                    #     if mul_flag:
                    #       continue
                    # #
                    # if open_flag and (line.strip().startswith("INPUT") or line.strip().startswith("OUTPUT")):
                    #
                    #     if line.strip().endswith('.') and len(line.split())>1:
                    #         open_flag=False
                    #         line="OPEN "+line
                    #         #print("here",line)
                    #     else:
                    #         second_flag=True
                    #         sample_line=sample_line+line.replace('\n','')
                    #
                    # if second_flag and line.strip().endswith('.'):
                    #     sample_line=sample_line+line
                    #     line=sample_line
                    #     second_flag=False

                    # print(line)
                    # current_line += 1
                    regex_line = re.search("^\s*OPEN ", line.strip())

                    # regex_line=re.findall(r'^\s*OPEN\s.*',line)

                    if regex_line != None:
                        trimmed_line = line.strip()

                        if trimmed_line.startswith("OPEN"):
                            lines_list += trimmed_line + "\n"
                            # print(trimmed_line)
                            break
                    # break
                # print("llll",line)
                # Added by me.
                # print(line)
                # if line=='\n' or line.strip()=='.':
                #     break

                for line in input_data:
                    current_line += 1
                    trimmed_line = line.strip()
                    if trimmed_line.strip() == "" or trimmed_line[0] == '*':
                        continue
                    # if trimmed_line.split()[0].replace('.','') in Key_Word_List :
                    #     break
                    print("tri", trimmed_line)
                    lines_list += trimmed_line.replace(".", "") + "\n"
                    if trimmed_line.endswith("."):
                        # print(current_line,num_of_lines)
                        break

                if current_line == num_of_lines:
                    flag = False

            file_operations = []
            lines_list1 = ""
            for line in lines_list.split("\n"):

                if (line.strip().startswith('OPEN ') or line.strip().startswith("CLOSE ")) and (
                        line.strip().split()[1] == "INPUT" or line.strip().split()[1] == "OUTPUT"):
                    lines_list1 = lines_list1 + line + '\n'

                else:
                    continue

            for line in lines_list.split("\n"):
                # print(line)
                words = line.split()

                if words == [] or len(words) == 1:
                    # print("eordds", words)
                    continue

                if not words[1] == "INPUT" and not words[1] == "OUTPUT" and not words[1] == "I-O" and not words[
                                                                                                              1] == "EXTEND":
                    # print("eordds33", words)
                    continue

                # if words[0]=="OPEN" and len(words)==2:
                #     continue
                if len(words) == 3:
                    # print(words)
                    action = words[0]
                    mode = words[1]
                    f_name = words[2]
                    if f_name.__contains__('.'):
                        f_name = f_name[:-1]
                    if f_name == "OUTPUT" or f_name == "INPUT" or f_name == "I-O" or f_name == "EXTEND":
                        continue
                    file_operations.append((action, mode, f_name))
                if len(words) == 2:
                    mode = words[0]
                    f_name = words[1]
                    if f_name.__contains__('.'):
                        f_name = f_name[:-1]
                    if f_name == "OUTPUT" or f_name == "INPUT" or f_name == "I-O" or f_name == "EXTEND":
                        continue
                    file_operations.append((action, mode, f_name))
                if len(words) == 1:
                    f_name = words[0]
                    if f_name.__contains__('.'):
                        f_name = f_name[:-1]
                    if f_name == "OUTPUT" or f_name == "INPUT" or f_name == "I-O" or f_name == "EXTEND":
                        continue
                    file_operations.append((action, mode, f_name))

            print("opera", file_operations)
            print(details)
            for operation in file_operations:
                faction, fmode, fname = operation[0], operation[1], operation[2].replace(',', '')
                print("details", f_name, details)
                oper_dict = details[fname]
                oper_dict["access_mode"] = fmode
                complete_details.append(oper_dict)
                print("mmmmmmmmmmmm", oper_dict)
                if oper_dict.get('_id'):
                    del oper_dict['_id']

                db.cross_reference_report_file.insert_one(oper_dict)
                oper_dict = {}
                print("hhhhhhh", oper_dict)
                # print("oper_fidt",complete_details)

        input_data.close()
        # input_data.close()
        copyfile.close()
        # os.close(int(file_location1 + '\\' + "DataD_lines.CO"))
        os.remove(file_location1 + '\\' + "DataD_lines.CO")
        os.remove("Duplicatefile0.txt")

        for meta in complete_details:
            METADATA2.append(meta)
        # METADATA.append(complete_details)

    return METADATA2


worker = XReferenceCobol()
worker.daemon = True

start = timeit.default_timer()

worker.start()

while True:
    time.sleep(2)
    if not (worker.is_alive()):
        end = timeit.default_timer()
        print('total time taken = ', end - start)
        sys.exit(7)
