SCRIPT_VERSION = 'Code display, edited for regular COBOL'
from pymongo import MongoClient
import timeit
import copy
import sys
import os
import re
import pytz
import datetime
import config_crst

# Setting Application timezone
time_zone = 'Asia/Calcutta'
tz = pytz.timezone(time_zone)

#Defining keywords for highlighting in blue [shelved for future enhancement]
keywords = ["ACCEPT",
"ACCESS",
"ADD",
"ADDRESS",
"ADVANCING",
"AFTER",
"ALL",
"ALPHABET",
"ALPHABETIC",
"ALPHABETIC-LOWER",
"ALPHABETIC-UPPER",
"ALPHANUMERIC",
"ALPHANUMERIC-EDITED",
"ALSO",
"ALTER",
"ALTERNATE",
"AND",
"ANY",
"APPLY",
"ARE",
"AREA",
"AREAS",
"ASCENDING",
"ASSIGN",
"AT",
"AUTHOR",
"BASIS",
"BEFORE",
"BEGINNING",
"BINARY",
"BLANK",
"BLOCK",
"BOTTOM",
"BY",
"CALL",
"CANCEL",
"CBL",
"CD",
"CF",
"CH",
"CHARACTER",
"CHARACTERS",
"CLASS",
"CLASS-ID",
"CLOCK-UNITS",
"CLOSE",
"COBOL",
"CODE",
"CODE-SET",
"COLLATING",
"COLUMN",
"COMMA",
"COMMON",
"COMMUNICATION",
"COMP",
"COMP-1",
"COMP-2",
"COMP-3",
"COMP-4",
"COMP-5",
"COMPUTATIONAL",
"COMPUTATIONAL-1",
"COMPUTATIONAL-2",
"COMPUTATIONAL-3",
"COMPUTATIONAL-4",
"COMPUTATIONAL-5",
"COMPUTE",
"COM-REG",
"CONFIGURATION",
"CONTAINS",
"CONTENT",
"CONTINUE",
"CONTROL",
"CONTROLS",
"CONVERTING",
"COPY",
"CORR",
"CORRESPONDING",
"COUNT",
"CURRENCY",
"DATA",
"DATE-COMPILED",
"DATE-WRITTEN",
"DAY",
"DAY-OF-WEEK",
"DBCS",
"DE",
"DEBUG-CONTENTS",
"DEBUGGING",
"DEBUG-ITEM",
"DEBUG-LINE",
"DEBUG-NAME",
"DEBUG-SUB-1",
"DEBUG-SUB-2",
"DEBUG-SUB-3",
"DECIMAL-POINT",
"DECLARATIVES",
"DELETE",
"DELIMITED",
"DELIMITER",
"DEPENDING",
"DESCENDING",
"DESTINATION",
"DETAIL",
"DISPLAY",
"DISPLAY-1",
"DIVIDE",
"DIVISION",
"DOWN",
"DUPLICATES",
"DYNAMIC",
"EGCS",
"EGI",
"EJECT",
"ELSE",
"EMI",
"ENABLE",
"END",
"END-ADD",
"END-CALL",
"END-COMPUTE",
"END-DELETE",
"END-DIVIDE",
"END-EVALUATE",
"END-IF",
"ENDING",
"END-INVOKE",
"END-MULTIPLY",
"END-OF-PAGE",
"END-PERFORM",
"END-READ",
"END-RECEIVE",
"END-RETURN",
"END-REWRITE",
"END-SEARCH",
"END-START",
"END-STRING",
"END-SUBTRACT",
"END-UNSTRING",
"END-WRITE",
"ENTER",
"ENTRY",
"ENVIRONMENT",
"EOP",
"EQUAL",
"ERROR",
"ESI",
"EVALUATE",
"EVERY",
"EXCEPTION",
"EXIT",
"EXTEND",
"EXTERNAL",
"FD",
"FILE",
"FILE-CONTROL",
"FILLER",
"FINAL",
"FIRST",
"FOOTING",
"FOR",
"FROM",
"FUNCTION",
"GENERATE",
"GIVING",
"GLOBAL",
"GO",
"GOBACK",
"GREATER",
"GROUP",
"HEADING",
"HIGH-VALUE",
"HIGH-VALUES",
"ID",
"IDENTIFICATION",
"IF",
"IN",
"INDEX",
"INDEXED",
"INDICATE",
"INHERITS",
"INITIAL",
"INITIALIZE",
"INITIATE",
"INPUT",
"INPUT-OUTPUT",
"INSERT",
"INSPECT",
"INSTALLATION",
"INTO",
"INVALID",
"INVOKE",
"I-O",
"I-O-CONTROL",
"IS",
"JUST",
"JUSTIFIED",
"KANJI",
"KEY",
"LABEL",
"LAST",
"LEADING",
"LEFT",
"LENGTH",
"LESS",
"LIMIT",
"LIMITS",
"LINAGE",
"LINAGE-COUNTER",
"LINE",
"LINE-COUNTER",
"LINES",
"LINKAGE",
"LOCAL-STORAGE",
"LOCK",
"LOW-VALUE",
"LOW-VALUES",
"MEMORY",
"MERGE",
"MESSAGE",
"METACLASS",
"METHOD",
"METHOD-ID",
"MODE",
"MODULES",
"MORE-LABELS",
"MOVE",
"MULTIPLE",
"MULTIPLY",
"NATIVE",
"NATIVE_BINARY",
"NEGATIVE",
"NEXT",
"NO",
"NOT",
"NULL",
"NULLS",
"NUMBER",
"NUMERIC",
"NUMERIC-EDITED",
"OBJECT",
"OBJECT-COMPUTER",
"OCCURS",
"OF",
"OFF",
"OMITTED",
"ON",
"OPEN",
"OPTIONAL",
"OR",
"ORDER",
"ORGANIZATION",
"OTHER",
"OUTPUT",
"OVERFLOW",
"OVERRIDE",
"PACKED-DECIMAL",
"PADDING",
"PAGE",
"PAGE-COUNTER",
"PASSWORD",
"PERFORM",
"PF",
"PH",
"PIC",
"PICTURE",
"PLUS",
"POINTER",
"POSITION",
"POSITIVE",
"PRINTING",
"PROCEDURE",
"PROCEDURE-POINTER",
"PROCEDURES",
"PROCEED",
"PROCESSING",
"PROGRAM",
"PROGRAM-ID",
"PURGE",
"QUEUE",
"QUOTE",
"QUOTES",
"RANDOM",
"RD",
"READ",
"READY",
"RECEIVE",
"RECORD",
"RECORDING",
"RECORDS",
"RECURSIVE",
"REDEFINES",
"REEL",
"REFERENCE",
"REFERENCES",
"RELATIVE",
"RELEASE",
"RELOAD",
"REMAINDER",
"REMOVAL",
"RENAMES",
"REPLACE",
"REPLACING",
"REPORT",
"REPORTING",
"REPORTS",
"REPOSITORY",
"RERUN",
"RESERVE",
"RESET",
"RETURN",
"RETURN-CODE",
"RETURNING",
"REVERSED",
"REWIND",
"REWRITE",
"RF",
"RH",
"RIGHT",
"ROUNDED",
"RUN",
"SAME",
"SD",
"SEARCH",
"SECTION",
"SECURITY",
"SEGMENT",
"SEGMENT-LIMIT",
"SELECT",
"SELF",
"SEND",
"SENTENCE",
"SEPARATE",
"SEQUENCE",
"SEQUENTIAL",
"SERVICE",
"SET",
"SHIFT-IN",
"SHIFT-OUT",
"SIGN",
"SIZE",
"SKIP1",
"SKIP2",
"SKIP3",
"SORT",
"SORT-CONTROL",
"SORT-CORE-SIZE",
"SORT-FILE-SIZE",
"SORT-MERGE",
"SORT-MESSAGE",
"SORT-MODE-SIZE",
"SORT-RETURN",
"SOURCE",
"SOURCE-COMPUTER",
"SPACE",
"SPACES",
"SPECIAL-NAMES",
"STANDARD",
"STANDARD-1",
"STANDARD-2",
"START",
"STATUS",
"STOP",
"STRING",
"SUB-QUEUE-1",
"SUB-QUEUE-2",
"SUB-QUEUE-3",
"SUBTRACT",
"SUM",
"SUPER",
"SUPPRESS",
"SYMBOLIC",
"SYNC",
"SYNCHRONIZED",
"TABLE",
"TALLY",
"TALLYING",
"TAPE",
"TERMINAL",
"TERMINATE",
"TEST",
"TEXT",
"THAN",
"THEN",
"THROUGH",
"THRU",
"TIME",
"TIMES",
"TITLE",
"TO",
"TOP",
"TRACE",
"TRAILING",
"TYPE",
"UNIT",
"UNSTRING",
"UNTIL",
"UP",
"UPON",
"USAGE",
"USE",
"USING",
"VALUE",
"VALUES",
"VARYING",
"WHEN",
"WHEN-COMPILED",
"WITH",
"WORDS",
"WORKING-STORAGE",
"WRITE",
"WRITE-ONLY",
"ZERO",
"ZEROES",
"ZEROS",
"FALSE",
"TRUE"]

client = MongoClient(config_crst.database['hostname'], config_crst.database['port'])
db = client[config_crst.database['database_name']]



def getFiles(file_type, file_extension,project_location) -> list:
    # Generating directory of COBOL files
    try:
        parent_folder =project_location + '/' + file_type
        files_w_extension = [x for x in os.listdir(parent_folder) if re.match('.+\.' + file_extension, x)]
    except (FileNotFoundError):
        print('Rename the folder to \'' + file_type + '\' and try again... ')
        sys.exit(0)
    except Exception as e:
        print(str(e))
        sys.exit(0)
    return files_w_extension

OUTPUT_DATA = []

#Location of the source code to be analyzed
code_location =config_crst.codebase_information['code_location']

component_types = {config_crst.codebase_information['COBOL']['folder_name']:config_crst.codebase_information['COBOL']['extension'],
                   config_crst.codebase_information['COPYBOOK']['folder_name']:config_crst.codebase_information['COPYBOOK']['extension'],
                   config_crst.codebase_information['PROC']['folder_name']:config_crst.codebase_information['PROC']['extension'],
                   config_crst.codebase_information['JCL']['folder_name']:config_crst.codebase_information['JCL']['extension'],
                   config_crst.codebase_information['SYSIN']['folder_name']:config_crst.codebase_information['SYSIN']['extension'],
                   config_crst.codebase_information['APS']['folder_name']:config_crst.codebase_information['APS']['extension'],
                   config_crst.codebase_information['BMS']['folder_name']:config_crst.codebase_information['BMS']['extension'],
   }

#Start the program execution timer
start_time=timeit.default_timer()


#Iterate through all the different available components, which are in scope for this particular technology
for component in component_types:

    #Check to determine the component_type to apply appropriate comment line identification logic
    if component == config_crst.codebase_information['COBOL']['folder_name'] or component == config_crst.codebase_information['COPYBOOK']['folder_name']:

        # Modify comment identification logic as per cobol standards
        FILE_LIST = copy.deepcopy(getFiles(component, component_types[component], code_location))
        print('List of ' + component + 'files to be processed', FILE_LIST)
        for eachFile in FILE_LIST:
            file = open(code_location + '\\' + component + '\\' + eachFile, 'r')
            god_string = ''
            for line in file:
                if len(line)>6:
                    if line[6]=='*':
                        #it is a comment line, modify the string
                        line = '<span style=\"color:green\">'+line+'</span>'
                        god_string = god_string + line.replace('\n', '<br>')
                        continue

                god_string = god_string + line.replace('\n', '<br>')

            OUTPUT_DATA.append({'component_name': eachFile, 'component_type': component, 'codeString': god_string})

    if component == 'APS':
        # Modify comment identification logic as per cobol standards
        FILE_LIST = copy.deepcopy(getFiles(component, component_types[component], code_location))
        print('List of ' + component + 'files to be processed', FILE_LIST)
        for eachFile in FILE_LIST:
            file = open(code_location + '\\' + component + '\\' + eachFile, 'r')
            god_string = ''
            for line in file:
                if line.strip().startswith("//*"):
                        #it is a comment line, modify the string
                        line = '<span style=\"color:green\">'+line+'</span>'
                        god_string = god_string + line.replace('\n', '<br>')
                        continue

                god_string = god_string + line.replace('\n', '<br>')

            OUTPUT_DATA.append({'component_name': eachFile, 'component_type': component, 'codeString': god_string})


    # Check to determine the component_type to apply appropriate comment line identification logic
    if component == 'JCL' or component == 'PROC':
        # Modify comment identification logic as per cobol standards
        FILE_LIST = copy.deepcopy(getFiles(component, component_types[component], code_location))
        print('List of ' + component + 'files to be processed', FILE_LIST)
        for eachFile in FILE_LIST:
            file = open(code_location + '\\' + component + '\\' + eachFile, 'r',encoding="ISO-8859-1")
            god_string = ''
            for line in file:
                if line.strip() == "":
                    continue
                if line.strip().startswith("//*"):
                        #it is a comment line, modify the string
                        line = '<span style=\"color:green\">'+line+'</span>'
                        god_string = god_string + line.replace('\n', '<br>')
                        continue

                god_string = god_string + line.replace('\n', '<br>')

            OUTPUT_DATA.append({'component_name': eachFile, 'component_type': component, 'codeString': god_string})

    if component == 'SYSIN':
        # Modify comment identification logic as per cobol standards
        FILE_LIST = copy.deepcopy(getFiles(component, component_types[component], code_location))
        print('List of ' + component + 'files to be processed', FILE_LIST)
        for eachFile in FILE_LIST:
            file = open(code_location + '\\' + component + '\\' + eachFile, 'r',encoding="ISO-8859-1")
            god_string = ''
            for line in file:
                if line.strip() == "":
                    continue
                if line.strip().startswith("//*"):
                    # it is a comment line, modify the string
                    line = '<span style=\"color:green\">' + line + '</span>'
                    god_string = god_string + line.replace('\n', '<br>')
                    continue

                god_string = god_string + line.replace('\n', '<br>')

            OUTPUT_DATA.append({'component_name': eachFile, 'component_type': component, 'codeString': god_string})

    if component == 'BMS':
        # Modify comment identification logic as per cobol standards
        FILE_LIST = copy.deepcopy(getFiles(component, component_types[component], code_location))
        print('List of ' + component + 'files to be processed', FILE_LIST)
        for eachFile in FILE_LIST:
            file = open(code_location + '\\' + component + '\\' + eachFile, 'r',encoding="ISO-8859-1")
            god_string = ''
            for line in file:
                if line.strip().startswith("*"):
                    # it is a comment line, modify the string
                    line = '<span style=\"color:green\">' + line + '</span>'
                    god_string = god_string + line.replace('\n', '<br>')
                    continue

                god_string = god_string + line.replace('\n', '<br>')

            OUTPUT_DATA.append({'component_name': eachFile, 'component_type': component, 'codeString': god_string})


    else:
        # Modify comment identification logic as per shell script standards
        FILE_LIST = copy.deepcopy(getFiles(component, component_types[component], code_location))
        print('List of ' + component + 'files to be processed', FILE_LIST)
        for eachFile in FILE_LIST:
            file = open(code_location + '\\' + component + '\\' + eachFile, 'r',encoding="ISO-8859-1")
            god_string = ''
            print(eachFile)
            for line in file:
                if line.find('#')!=-1:
                    split_line =  line.split('#')
                    line =split_line[0]+"<span style=\"color:green\">#"+split_line[1]+"</span>"
                god_string = god_string + line.replace('\n', '<br>')

            OUTPUT_DATA.append({'component_name': eachFile, 'component_type': component, 'codeString': god_string})



# Delete already existing data
try:
    db.codebase.delete_many({'type': {"$ne": "metadata"}})
except Exception as e:
    print('Error:' + str(e))

# Insert into DB
try:

    db.codebase.insert_many(OUTPUT_DATA)
    # updating the timestamp based on which report is called
    current_time = datetime.datetime.now(tz=tz).strftime("%A, %d. %B %Y %I:%M%p")
    if db.codebase.update_one({"type": "metadata"}, {"$set": {"last_updated_on": current_time,
                                                                         "time_zone": time_zone,
                                                                         # "headers":["component_name","component_type"],
                                                                         "script_version": SCRIPT_VERSION
                                                                         }}, upsert=True).acknowledged:
        print('Update was successful!')
except Exception as e:
    print('Error:' + str(e))

#Stop the program execution timer
stop_time=timeit.default_timer()


print('Codebase upload script completed in',stop_time-start_time,'second(s)')