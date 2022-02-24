# Python3 code to Check for
# balanced parentheses in an expression
open_list = ["[","{","("]
close_list = ["]","}",")"]

# Function to check parentheses
def check(myStr):
    stack = []
    for i in myStr:
        if i in open_list:
            stack.append(i)
        elif i in close_list:
            pos = close_list.index(i)
            if len(string)>0 and open_list[pos] == stack[-1]:
                stack.pop()
            else:
                return "unbalanced"
    if len(stack) == 0:
        return "Balanced"
    else:
        return "unbalanced"



# Driver code
string = "{[]{()}}"
print(string,"-", check(string))

string = "[{}{})(]"
print(string,"-", check(string))

string = "((()"
print(string,"-",check(string))
