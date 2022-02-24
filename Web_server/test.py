str = "This is a test string".lower()
word = "tsit"
ans = len(str)
for i in word:
    ans = min(ans,str.count(i)//word.count(i))

print(ans)