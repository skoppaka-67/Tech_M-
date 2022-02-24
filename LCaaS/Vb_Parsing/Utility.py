import glob, os
import Vb_Parsing.config as config
from xlsxwriter import Workbook

vb_path = config.vb_path
vb_component_path = config.vb_component_path


class PreProcessing:

    @staticmethod
    def get_files():
        filenames_list = []
        for filename1 in glob.glob(os.path.join(vb_component_path, '*.frm')):
            filenames_list.append(filename1)
        for filename1 in glob.glob(os.path.join(vb_component_path, '*.bas')):
            filenames_list.append(filename1)
        for filename2 in glob.glob(os.path.join(vb_component_path, '*.Dsr')):
            filenames_list.append(filename2)
        for filename2 in glob.glob(os.path.join(vb_component_path, '*.vbp')):
            filenames_list.append(filename2)
        for filename2 in glob.glob(os.path.join(vb_component_path, '*.vbw')):
            filenames_list.append(filename2)

        # return ["D:\Lcaas_imp\WebApplications\LobPF\PFPolicyInput.aspx.vb"]
        return filenames_list

    @staticmethod
    def remove_duplicates(list):
        res = []
        for i in list:
            if i not in res:
                res.append(i)
        return res

    @staticmethod
    def fetch_parametres_count(fun_lines_list, calling_fun_name):
        try:
            line_collector_variable = ''
            line_collector_flag = False

            for line in fun_lines_list:

                if line_collector_flag:
                    if line.rstrip().endswith(")") or line.__contains__(")"):
                        line_collector_variable = line_collector_variable + '\n' + line
                        parameters_list = line_collector_variable.replace(")", "").replace("\n", "").split(",")
                        parameters_count = len(parameters_list)
                        return parameters_count, parameters_list

                    else:
                        line_collector_variable = line_collector_variable + '\n' + line
                        continue

                if line.__contains__(calling_fun_name):
                    if line.rstrip().endswith(")") or line.__contains__(")"):
                        para_name_collection = line.split("(")
                        para_name_list = para_name_collection[0].split()
                        parameters_list = para_name_collection[1].split(")")[0].replace("\n", "").split(",")
                        if parameters_list == [""]:
                            parameters_count = 0
                        else:
                            parameters_count = len(parameters_list)
                        para_name = para_name_list[-1]
                        return parameters_count, parameters_list
                    else:

                        line_collector_variable = line.split("(")[1] + '\n'

                        line_collector_flag = True
                        continue
            return "", ""
        except IndexError as e:
            print(e)

    @staticmethod
    def write_to_excel(Wb_name, metadata, ordered_list):

        try:
            wb = Workbook(Wb_name)
            ws = wb.add_worksheet("Sheet1")
            first_row = 0
            # list object calls by index but dict object calls items randomly

            for header in ordered_list:
                col = ordered_list.index(header)  # we are keeping order.
                ws.write(first_row, col, header)
            row = 1
            for records in metadata:
                for _key, _value in records.items():
                    col = ordered_list.index(_key)
                    ws.write(row, col, _value)
                row += 1  # enter the next row
            wb.close()
        except Exception as e:
            print("Errpr:", e, metadata[0])

