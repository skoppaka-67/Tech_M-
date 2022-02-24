from  pymongo import  MongoClient
import json ,glob,os,copy

file = {'D:\\WORK\\plsql\\PKB\\': '*.pkb',
        'D:\\WORK\\plsql\\PKS': '*.pks'}

client = MongoClient('localhost', 27017)
db = client['plsql']


# print(json.dumps(CRUD_DATA,indent=4))


def procedures_seperation(file):
    """

    This function is to return a dictionary with procedures in a pkb file

    :param files: take  file name as paramater from main function
    :return:
    """

    f = open(file, 'r')  ##opens file in a read mode
    METADATA = {}
    storage = []
    procedure_name = ''
    flag = False
    comment_flag = False

    for line in f.readlines():  ##access lines one by one from file
        if line.strip() == '':
            continue
        if line.strip().startswith('--'):
            continue
        if line.strip().startswith('/*'):
            comment_flag = True
        if line.strip().__contains__('*/'):
            comment_flag = False
        if comment_flag:
            continue

        if line.strip().startswith('PROCEDURE'):  ##access lines which are starting with procedure
            flag = True  ##changing flag to true untill the condition satisfies

            a = line.split()  ##splitting line using split() function so that each word seperated by a space will store in a list with proper indexes
            procedure_name = a[
                1]  ##line starts with procedure and the next word will be the procedure name, so we are storing a[1] in procedure name

        if flag and line.strip().startswith(
                'END' + ' ' + procedure_name):  ##access the lines which are starting with end followed by procedure name

            storage.append(line)  ##adding line to storage list
            flag = False  ##changing flag to false if condition satisfies

            METADATA[procedure_name] = copy.deepcopy(storage)

            storage.clear()

        if flag:  ##if line starts with procedure flag will be true
            storage.append(line)
    # print(json.dumps(METADATA, indent=4))

    return METADATA


def Proc_tagger(filename, Type):

    file_code_dict = procedures_seperation(filename)
    curd_cursy = db.crud_report.find({"component_name" : filename.split("\\")[-1].split(".")[0],})
    CRUD_DATA = [x for x in curd_cursy]
    for record in CRUD_DATA:
        search_string = " ".join(record['SQL'].split()[:3])

        for k in file_code_dict:
            for line in file_code_dict[k]:
                if line.__contains__(search_string):

                    db.crud_report.update({'_id':record['_id']},{"$set":{'Procedure': k}},upsert=False)



        print(record)







if __name__ == '__main__':

    for file_location, file_type in file.items():  ##taking key as file location and value as file type in file dictionary
        for filename in glob.glob(os.path.join(file_location,
                                               file_type)):  ##access files one by one that ends with .pkb, and joining file path with folder
            """
                            1.if file type is .pkb type becomes package body,
                            2.if file name ends with .pks it is package specification and if it is true we are printing failure
                            3.if file name ends with .prc it is procedure
                            4.if file name ends with .fnc it is function type
                            5.if file name ends with .trg it is trigger
                            6.we are calling programType function for each file type to count total number of lines , 
                            empty lines, comment lines , block comments and source lines of code 
                            """
            if file_type == "*.pkb":
                Type = "Package Body"
                Proc_tagger(filename, Type)




