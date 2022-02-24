import glob,os
import re

filepath = "C:\\Lcaas\\APS\\TPL262B.aps"

f = open(filepath,'r',errors='ignore',)
print(f)
file_list = []

file_write_flag = False

for line in f.readlines():
    # with open("out.txt", "w") as f1:
    print(line)


    if re.search('.*DATA SET:.*',line) and re.search('.*MEMBER:.*',line):
        file_name = line.split()[-1]
        writefile = open('C:\\Lcaas\\APS\\'+file_name + ".txt", "a", encoding="utf-8",)
        print(file_name)
        # writefile.write(line)
        if file_name in file_list:
            continue
        continue
    if re.search('.*DATE:.*',line) and re.search('.*TIME:.*',line):
        continue
    # if line.strip() == "":
    #     continue
    # if re.search('.*DATA SET:.*',line) and re.search('.*PDS DIRECTORY:.*',line):
    #     writefile.close()
    # else:

    writefile.write(line)