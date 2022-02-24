# Reading an excel file using Python
import xlrd, copy
import pandas as pd, re

# Give the location of the  source file
loc = ("D:\Excel_Automation\Cabot_Ticket_Analysis_data-AppMapping.xlsx")

# To open Workbook
wb = xlrd.open_workbook(loc)
SR_sheet = wb.sheet_by_index(0)
App_sheet = wb.sheet_by_index(1)



data = []


def app_list_maker(App_sheet):
    """

    Function will collect Aliases name of apps and store them as list of dictionary's

    :param App_sheet:
    :return:
    """
    APP_LIST = []

    for i in range(1,App_sheet.nrows):
        app_dict = {}
        if App_sheet.row_values(i)[1].__contains__("/"):

            app_dict[App_sheet.row_values(i)[0]] = " ".join(App_sheet.row_values(i)[1].split("/"))
            APP_LIST.append(copy.deepcopy(app_dict))

            continue

        elif App_sheet.row_values(i)[1].__contains__("_"):
            app_dict[App_sheet.row_values(i)[0]] = " ".join(App_sheet.row_values(i)[1].split("_"))
            APP_LIST.append(copy.deepcopy(app_dict))
            continue
        elif App_sheet.row_values(i)[1].__contains__("("):
            app_dict[App_sheet.row_values(i)[0]] = " ".join(App_sheet.row_values(i)[1].split("(")).replace(")", "")
            APP_LIST.append(copy.deepcopy(app_dict))
            continue

        else:
            app_dict[App_sheet.row_values(i)[0]] = App_sheet.row_values(i)[1]
            APP_LIST.append(copy.deepcopy(app_dict))
    return APP_LIST


def app_mapper(App_list, SR_sheet):
    mul_value_list = []
    """
    Add values in ignore_list to avoid unwanted matches 
    """
    ignore_list = ['for', 'Access', 'Request', "access", "request","New","new"]
    for i in range(1,SR_sheet.nrows):
        for app in App_list:
            for k, v in app.items():
                if v == '-' or v in ignore_list:
                    continue

                if re.match("\s?" + v + ' ', "".join(SR_sheet.row_values(i)[1]), re.IGNORECASE):
                    mul_value_list.append(k)
                    # data.append(
                    #     [SR_sheet.row_values(i)[0], SR_sheet.row_values(i)[1], ",".join(copy.deepcopy(mul_value_list))])

                elif len(v.split()) > 1:
                    value_list = v.split()
                    for val in value_list:
                        if val == '-' or len(val) <= 2 or val in ignore_list:
                            continue
                        if re.match("\s?" + val +' ', "".join(SR_sheet.row_values(i)[1]), re.IGNORECASE):
                            mul_value_list.append(k)
        data.append([SR_sheet.row_values(i)[0], SR_sheet.row_values(i)[1], ",".join(copy.deepcopy(mul_value_list))])
        mul_value_list.clear()


App_list = app_list_maker(App_sheet)
app_mapper(App_list, SR_sheet)

"""
Add custom column names below
"""
df = pd.DataFrame(data, columns=['ServiceReqNumber', 'Subject OwnerTeam', 'APP'])
df.to_excel("output.xlsx",index=False)
