files=[r"D:\PLSQL\PKB\EPIC_ORDERS_SPEC_CHECKS_PKG.pkb",r"D:\PLSQL\PKB\sample.txt", r"D:\PLSQL\PKS\EPIC_ORDERS_SPEC_CHECKS_PKG.pks"]

output=[]
import pandas as pd
for file in files:
    # print(file)
    d = {}
    d['component_name'] = file.split('\\')[-1].split('.')[0]
    d['component_type'] = file.split('\\')[-1].split('.')[1]
    if(d['component_type']!='pks'):
        print(d['component_name'])
        open_file=open(file).readlines()
        if_count=0
        for_count=0
        flag=False
        case_count=0
        case_flag=False
        except_flag=False
        except_count=0
        for lines in open_file:
            # print(lines)
            if(lines.strip()!=''):
                if lines.strip().startswith('/*'):
                    # print(lines)
                    flag=True
                if(flag==True):
                    if(lines.strip().endswith('*/')):
                        # print(lines)
                        flag=False
                        continue
                if(flag==False):
                    if(lines.lower().strip().startswith('if') or lines.lower().strip().startswith('elsif')):
                        # print(lines)
                        if_count+=1
                    if(lines.lower().strip().split()[0]=='for' or lines.lower().strip().split()[0]=='forall' or lines.lower().strip().split()[0]=='while'):
                        # print(lines)
                        for_count+=1
                    if(lines.lower().strip().startswith('case')):
                        case_flag=True
                    if(case_flag==True):
                        if(lines.lower().strip().startswith('when')):
                            # print(lines)
                            case_count+=1
                        if(lines.lower().strip().__contains__('end case;')):
                            # print(lines)
                            case_flag=False
                    if (lines.lower().strip().startswith('exception')):
                        except_flag = True
                        # print(lines)
                    if (except_flag == True):
                        if (lines.lower().strip().startswith('when')):
                            # print(lines)
                            except_count += 1
                        if (lines.strip().lower().startswith('end')and lines.strip().lower().endswith(';')):
                            # print(lines)
                            except_flag = False
        total=if_count+ for_count+ except_count+case_count+1
        print("if_count-",if_count, "for_count-",for_count, "except_count-",except_count, "case_count-",case_count)
        d['cyclomatic_complexity']=total
        output.append(d)
        # print(output)
# df = pd.DataFrame(data=output)
# # df = (df.T)
# df.to_excel('dict1.xlsx')
