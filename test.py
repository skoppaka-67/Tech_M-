str = "hashed in technologies".lower()
word = "neuron"

str_list =[]
word_list = []

str_list[:0] = str
word_list[:0] = word
valuelist = []
def count_words(str_list,word_list):
    num_list = []

    for i in word_list:
        if i in str_list:
            index = str_list.index(i)
            num_list.append(str_list.pop(index))
    valuelist.append("".join(num_list))
    for i in word_list:
        if i in str_list:
            count_words(str_list,word_list)

count_words(str_list,word_list)


count = 0

for i in valuelist:
    if i == word:
        count +=1

print(count)

