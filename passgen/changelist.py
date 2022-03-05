from subprocess import Popen, PIPE
import sys
import os

with open('usernames.txt', 'r') as usernames:
    unames = usernames.read().splitlines()
    for username in unames:
        os.system(f'python3 passgensudo.py {username}')

