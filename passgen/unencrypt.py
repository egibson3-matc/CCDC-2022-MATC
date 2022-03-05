import sys
import json

oldpass = open('Passwords.json','r')

userandpass = json.load(oldpass)
print(userandpass)

#print(type(content))
#print(content)
for user in userandpass.keys():
    newpass=[]
    oldpass = userandpass[user]
    unencryptedPair = {}
    for i in oldpass:
        val = ord(i) - 3
        swing = chr(val)
        newpass.append(swing)
        encpass = ''.join(newpass)
    unencryptedPair[user] = encpass

print(unencryptedPair)
    