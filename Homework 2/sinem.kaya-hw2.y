%{
#include <stdio.h>
#include <stdlib.h>
#include "sinem.kaya-hw2.tab.h"
void yyerror(const char *msg) {
    return; }
%}

/* Tokens from the flex file */
%token tMAIL tENDMAIL tSCHEDULE tENDSCHEDULE tSEND tSET tTO tFROM tAT tCOMMA tCOLON
%token tLPR tRPR tLBR tRBR tIDENT tSTRING tDATE tTIME tADDRESS tNEWLINE
/* the start symbol for the parser */
%start Mail_Script_program 

%%

Mail_Script_program: /* An empty Mail_Script_program is valid */
    | Mail_Script_program operation
    ;

/* operation could be either a mail block or a set statement */
operation: mail_block
    | set_statement
    ;

/* structure for sending emails */
mail_block: tMAIL tFROM tADDRESS tCOLON statement_list tENDMAIL
    | tMAIL tFROM tADDRESS tCOLON tENDMAIL
    ;

/* one or more statements */
statement_list: statement
    | statement_list statement
    | statement_list tNEWLINE
    ;

/* a statement, which can be a set statement, send statement, or a schedule block */
statement: set_statement 
    | send_statement
    | schedule_block 
    ;

set_statement: tSET tIDENT tLPR tSTRING tRPR
;

/* schedule blocks can include only one or more send statements, thats why we used sendStatementList */
schedule_block: tSCHEDULE tAT tLBR tDATE tCOMMA tTIME tRBR tCOLON sendStatementList tENDSCHEDULE
;

/* can be one or more send statements */
sendStatementList: send_statement
    | sendStatementList send_statement
    ;

send_statement: tSEND tLBR tIDENT tRBR tTO recipient_list
    | tSEND tLBR tSTRING tRBR tTO recipient_list
    ;

/* recipient_list can include one or more recipients */
recipient_list: tLBR recipent_parse tRBR

recipent_parse: recipient
    | recipent_parse tCOMMA recipient

recipient: tLPR tADDRESS tRPR
    | tLPR tIDENT tCOMMA tADDRESS tRPR
    | tLPR tSTRING tCOMMA tADDRESS tRPR
    ;
%%


int main () 
{
    if (yyparse())
    {
      // parse error
      printf("ERROR\n");
      return 1;
    } 

    else
    {
      // successful parsing
      printf("OK\n");
      return 0; 
    }
}