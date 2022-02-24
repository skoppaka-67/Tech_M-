"""
Problem Sum of any two number in a given list is equal to  the input sum value

sample input:[1,2,3,9] sum -8 return true if sum of any tw numbers in a list == 8
sample op : Flase

[1,2,3,4,4]
 sum - 8



 op - True

"""

list = [1,2,4,4]

frst_index = 0
last_index = len(list)-1

for i in list:
    if list[frst_index] + list[last_index] == 8:
        print(True)
        break
    else:
        frst_index += 1
        last_index -= 1




sum = 8



# print(checksum(list,sum))

def checksum1(list,sum):
    lookupset = []
    for i in range(0 ,len(list)):
        if list[i] not in lookupset:
            lookupset.append(sum - list[i])
        else:
            print(lookupset)
            return True



print(checksum1( [4,4,2,3],sum))