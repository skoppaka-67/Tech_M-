"""
Write a program that accepts a sentence and calculate the number of letters and digits.Suppose the
 following input is supplied to the program:hello world! 123Then, the output should be:LETTERS 10DIGITS 3
"""

# input_str = str(input("Enter the String"))

letter_count =0
digit_count = 0
spcl_char_count = 0
letter_list = []
digit_list = []
spcl_list = []


# for i in input_str:
#     if i.isalpha():
#         letter_count = letter_count + 1
#         letter_list.append(i)
#         continue
#     if i.isnumeric():
#         digit_count = digit_count + 1
#         digit_list.append(i)
#         continue
#     else:
#         if i == " ":
#             continue
#         spcl_char_count += 1
#         spcl_list.append(i)


# print(letter_list,digit_list)
# print(letter_count,digit_count)
#
# print("".join(letter_list) +": "+ str(letter_count))
# print("".join(digit_list) +":"+ str(digit_count))
# print("".join(spcl_list)+str(spcl_char_count))

"""

Please write a binary search function which searches an item in a sorted list. 
The function should return the index of element to be searched in the list

"""

def binary_search(sortd_list,key):

    mid = len(sortd_list)//2

    if key == sortd_list[mid]:
        return sortd_list[mid]

    if key < sortd_list[mid]:

        return binary_search(sortd_list[:mid],key)

    if key > sortd_list[mid]:

        return binary_search(sortd_list[mid:],key)



    return "Not Found"

# print(binary_search([1,2,3,4,5,6],5))

sample_list = [1,2,3,4,4,5,6]

print(sample_list.index(4))
#
# for i in sample_list:
#      if i == ""

