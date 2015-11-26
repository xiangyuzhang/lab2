%{
/* DEFINITIONS */
//extern "C"
//{
//}
#include <stdio.h>
#include "y.tab.h"

//int yylex(void);
//}
char fromvar[] = "from";
int count=0;
%}
/*STATES*/
%start S1 S2 S3 S4 S5 S6 S7


%%
[\n\t]|">"      {/*NO ACTIONS*/}

"*".*         {BEGIN S1;}   
<S1>[0-9]+  {  /*DIGITS: NET NUMBER STATE*/
    yylval.val = atoi(yytext); 
    BEGIN S2;
    return NETNO;
      }


<S2>[0-9]+|[a-zA-Z0-9]+|[a-zA-Z]+ {   /*DIGIT OR ALPHANUMERIC:  ASCII NAME OF NET*/
          yylval.name=yytext;
          BEGIN S3;return NETNAME;
          }


<S3>[a-zA-Z]+   { /*ALPHA: GATETYPE*/
    yylval.name=yytext;
    if (strcmp(yytext,fromvar)==0) {BEGIN S4;return GATETYPE;}
    else {BEGIN S5; return GATETYPE;}
    }


<S4>[0-9]+|[a-zA-Z0-9]+|[a-zA-Z]+ {     /*DIGITS OR ALPHANUMERIC: FROM NET ASCIINAME*/
          yylval.name=yytext; 
          BEGIN S1;
          return FROMNAME;
           }

<S5>[0-9]+  { /*DIGITS: NO OF FANOUT*/
      yylval.val = atoi(yytext);
        BEGIN S6; 
      return FANOUT;
    }


<S6>[0-9]+ {   /*DIGITS: NO OF FANIN*/
      yylval.val = atoi(yytext);
      if(atoi(yytext)>0) {count=atoi(yytext); BEGIN S7;return FANIN;}
      else {BEGIN S1;return FANIN;}   
      }


<S7>[0-9]+ {  /*DIGITS: INPUT NETS*/
        yylval.val = atoi(yytext);
        count=count-1;
        if(count==0) { BEGIN S1;}
        return FANINNET;
       }
 

"sa0" {yylval.val = 0; return FAULT;} /*STRUCK AT FAULT*/    
"sa1" {yylval.val = 1; return FAULT;} /*STRUCK AT FAULT*/       
%%
int yywrap(void) {
return 1;
}


