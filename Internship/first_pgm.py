class Solution:
   temp_l = []
   def countSubstrings(self, s):
      counter = 0
      for i in range(len(s)):
         for j in range(i+1,len(s)+1):
            temp = s[i:j]
            if temp == temp[::-1]:
               temp_l.append()


               counter+=1
      return counter
ob1 = Solution()
print(ob1.countSubstrings("aaaa"))