import pandas as pd

path = "D:\edi404.xlsx"
list = []


df = pd.read_excel(open(path, 'rb'),
              sheet_name='Sheet1')


def remove_duplicates(list):
    res = []
    for i in list:
        if i not in res:
            res.append(i)
    return res


import xlwt
from tempfile import TemporaryFile
book = xlwt.Workbook()
sheet1 = book.add_sheet('sheet1')



for index, row in df.iterrows():

    if not pd.isna(row["A"]):
        list.append(row["A"])
    if not pd.isna(row["B"]):
        list.append(row["B"])
    if not pd.isna(row["C"]):
        list.append(row["C"])
    if not pd.isna(row["D"]):
        list.append(row["D"])
    if not pd.isna(row["E"]):
        list.append(row["E"])
    if not pd.isna(row["F"]):
        list.append(row["F"])
    if not pd.isna(row["G"]):
        list.append(row["G"])

print(len(list))
new_list = remove_duplicates(list)
print(new_list)
print(len(new_list))

supersecretdata = new_list

for i,e in enumerate(supersecretdata):
    sheet1.write(i+1,1,e)
    # sheet1.write(,e)
#
name = "normalized1.xls"
book.save(name)
book.save(TemporaryFile())