numbers = [99, 44, 6, 2, 1, 5, 63, 87, 283, 4, 0]

def bubbleSort(list):


    for i in range(len(list)):
        for j in range(len(list)-1):
            if list[j] > list[j+1]:
                temp = list[j]
                list [j]  = list[j+1]
                list[j+1] = temp
    return (list)


    # print(list)
def selctionSort(list):

    for i in range(len(list)):
        for j in range(len(list)):
            if list[i] < list[j]:
                temp = list[i]
                list [i]  = list[j]
                list[j] = temp
    return (list)


def insertionSort(arr):
    # Traverse through 1 to len(arr)
    for i in range(1, len(arr)):

        key = arr[i]

        # Move elements of arr[0..i-1], that are
        # greater than key, to one position ahead
        # of their current position
        j = i - 1
        while j >= 0 and key < arr[j]:
            arr[j + 1] = arr[j]
            j -= 1
        arr[j + 1] = key


# print(bubbleSort(numbers))
# print(selctionSort(numbers))

import re

# initializing string
test_string = "Geeksforgeeks,  4  is best @# Computer Science Portal2.!!!"

# printing original string
print("The original string is : " + test_string)

# using regex( findall() )
# to extract words from string
res = re.findall(r'\d+', test_string)

# printing result
print("The list of words is : " + str(res))