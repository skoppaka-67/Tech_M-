

import xlrd,glob,os
import  pandas as pd

vb_path = "D:\\BNSF_1"
def get_files():
    filenames_list = []
    for filename1 in glob.glob(os.path.join(vb_path, '*.xlsx')):
        filenames_list.append(filename1)

    return  filenames_list

def remove_duplicates(list):
        res = []
        for i in list:
            if i not in res:
                res.append(i)
        return res

fn_list = get_files()

all_list = []

for file in fn_list:
    xls = xlrd.open_workbook(file, on_demand=True)

    all_list.extend(xls.sheet_names())

print(remove_duplicates(all_list))
print(len(remove_duplicates(all_list)))

dct = {
    "Seq": [x for x in range(1, len(remove_duplicates(all_list)) )],
    "list_of_files" : remove_duplicates(all_list)[1:]
}
df_1 = pd.DataFrame(dct)
with pd.ExcelWriter("D:\\BNSF_1\\file_name_list"+'.xlsx') as writer1:
    df_1.to_excel(writer1, sheet_name="file_name_list", index=False)