import pandas as pd

in_dict = {'a': 1,

           'c': {'a': 2,
                 'b': {'x': 5,
                       'y': 10}},
           'd': [1, 2, 3]}

# for i,v in in_dict.items():
#     if type(v)== dict:
#         print(v.keys())
#     else:
#         print("nonN: ", v)
#
final_dict = {}
key_list = []

nest_key_list = []
def noramize(dict):
    for key, valu in dict.items():
        if type(valu) == type(dict):
            key_list.append(key)
            noramize(valu)

        else:
            key_list.append(key)
            final_dict["-".join(key_list)] = valu
            key_list.clear()



noramize(in_dict)
print(final_dict)
#
#
# list1=[6,7,22,19,1,2,33,6]
#
#
# for i in range(len(list1)):
#     for j in range(i+1,len(list1)):
#         if list1[i] > list1[j]:
#             list1[i],list1[j] = list1[j],list1[i]
#
#
# print(list1)
