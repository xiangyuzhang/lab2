__author__ = 'xiangyuzhang'
from subprocess import call
import os



cmmd = "yacc -d circuit.y"
call(cmmd, shell=True)
cmmd = "bison -d circuit.y"
call(cmmd, shell=True)
cmmd = "flex co-token.l"
call(cmmd, shell=True)
cmmd = "g++ -g -o object lex.yy.c circuit.tab.c"
call(cmmd, shell=True)

os.remove("circuit.tab.c")
os.remove("circuit.tab.h")
os.remove("lex.yy.c")
os.remove("y.tab.c")
os.remove("y.tab.h")

