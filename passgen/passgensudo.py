import sys
import random
from subprocess import Popen, PIPE
import json
from textwrap import indent

count = 0
password = []

while count < 11:
    chrVar = random.randint(40,122)
    password.append(chr(chrVar))
    count+=1

finalPassword = ''.join(password)
        
if sys.argv[1]:
    username = sys.argv[1]
else:
    print("Please provide a username as an argument!")
    exit()

with open('Passwords.json','a') as passfile:
    usapass = {}
    newpass=[]
    for i in finalPassword:
        val = ord(i) + 3
        swing = chr(val)
        newpass.append(swing)
    encpass = ''.join(newpass)
    usapass[username]=encpass
    json.dump(usapass,passfile,indent=1)
    print(finalPassword)
    print(usapass)

proc = Popen(['passwd', f'{username}'], stdin=PIPE, stdout=PIPE, stderr=PIPE)
proc.stdin.write(bytes(f'{finalPassword}\n', encoding='utf8'))
proc.stdin.write(bytes(f'{finalPassword}', encoding='utf8'))
stdout,stderr=proc.communicate()
print(stdout)
print(stderr)
exit()

