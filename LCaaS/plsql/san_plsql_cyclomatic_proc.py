files=[r"D:\PLSQL\PKB\EPIC_ORDERS_SPEC_CHECKS_PKG.pkb",r"D:\PLSQL\PKS\EPIC_ORDERS_SPEC_CHECKS_PKG.pkb", r"D:\PLSQL\PKS\EPIC_ORDERS_SPEC_CHECKS_PKG.pks"]
import pandas as pd
output=[]
for file in files:
    print(file)
    d = {}
    d['component_type'] = file.split('\\')[-1].split('.')[1]
    flag=False
    if_count = 0
    for_count = 0
    flag = False
    case_count = 0
    case_flag = False
    except_flag = False
    except_count = 0
    proc_flag=False

    if (d['component_type'] != 'pks'):
        open_file=open(file).readlines()
        if(open_file[0].upper().__contains__("PACKAGE")):
            for lines in open_file:
                if lines.strip().startswith('/*'):
                    # print(lines)
                    flag = True
                if (flag == True):
                    if (lines.strip().endswith('*/')):
                        # print(lines)
                        flag = False
                        continue
                if(lines.strip().upper().startswith('PROCEDURE') and flag==False):
                    proc_name=lines.strip().split()[1]
                    # print("lines",lines,"procname", proc_name)
                    d={}
                    d['component_name'] = file.split('\\')[-1].split('.')[0]
                    d['component_type'] = file.split('\\')[-1].split('.')[1]
                    d['procedure_name']= proc_name
                    proc_flag=True
                    # flag=True
                if (lines.strip() != '' and proc_flag==True):
                    if (flag == False):

                        if (lines.lower().strip().startswith('if') or lines.lower().strip().startswith('elsif')):
                            # print(lines)
                            if_count += 1
                        if (lines.lower().strip().split()[0] == 'for' or lines.lower().strip().split()[
                            0] == 'forall' or lines.lower().strip().split()[0] == 'while'):
                            # print(lines)
                            for_count += 1
                        if (lines.lower().strip().startswith('case')):
                            case_flag = True
                        if (case_flag == True):
                            if (lines.lower().strip().startswith('when')):
                                # print(lines)
                                case_count += 1
                            if (lines.lower().strip().__contains__('end case;')):
                                # print(lines)
                                case_flag = False
                        if (lines.lower().strip().startswith('exception')):
                            except_flag = True
                            # print(lines)
                        if (except_flag == True):
                            if (lines.lower().strip().startswith('when')):
                                # print(lines)
                                except_count += 1
                            if (lines.strip().lower().startswith('end') and lines.strip().lower().endswith(';')):
                                # print(lines)
                                except_flag = False
                        if(lines.strip().lower().startswith('end') and lines.__contains__(proc_name) and lines.__contains__(';')):
                            total = if_count + for_count + except_count + case_count + 1
                            # print(if_count,for_count,except_count,case_count,total)
                            d['cyclomatic_complexity']=total
                            output.append(d)
                            # print(output)
                            # print(d)
                            flag = False
                            if_count = 0
                            for_count = 0
                            flag = False
                            case_count = 0
                            case_flag = False
                            except_flag = False
                            except_count = 0
                            proc_flag = False

print(output)
df = pd.DataFrame(data=output)
df.to_excel('cyclomatic_complexity_procedurewise.xlsx')
