# class SpclNum:
#
#     def __init__(self):
#         self.arr = {22,121}
#         self.print_spcl_ele(self.arr)

data = []
def print_spcl_ele(arr):
    for i in range(0,len(arr)):
        if arr[i]%11 == 0:
           data.append(arr[i])
           continue

        if arr[i]%2 == 0:
            data.append(arr[i])


arr = [12,3]
print_spcl_ele(arr)
print(len(data))
print(data)