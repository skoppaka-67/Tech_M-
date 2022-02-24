import glob ,os
file_path = "D:\\WORK\\POC's\\BNSF\\SSI\\COBOL"

for filename in glob.glob(os.path.join(file_path, '*.cbl')):
    filename1 = filename.split('\\')
    len_file = len(filename1)
    filename2 = filename1[len_file - 1][:-4]
    print(filename2)
    Program_Name = open(filename)
    count=0
    an_co=0
    li_co=0
    for line in Program_Name.readlines():
        path = "D:\\WORK\\POC's\\BNSF\\SSI\\COBOL\\new\\" + filename1[-1]
        with open(path, "a+") as file:
            file.write(line[1:])

