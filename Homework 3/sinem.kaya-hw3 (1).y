
%{
#include <stdio.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include "sinem.kaya-hw3.h"

void yyerror (const char *msg) /* Called by yyparse on error */ {
    return; }


int controlIdentifier(Identfier_Node); 
int controlRecip_Identifier(RecipList_Node *);

void createSetNodeIdent(Identfier_Node, String_Node);
Recip_Node * createRecipientNodeIdent(Identfier_Node, Adress_Node);
Recip_Node * crateRecipientNodeString(String_Node, Adress_Node);
Recip_Node * createRecipientNode(Adress_Node);

RecipList_Node * makeRecipList(Recip_Node *);
RecipList_Node * makeRecipList_List(Recip_Node * , RecipList_Node * );

Send_Node * createStringSendNode(String_Node, RecipList_Node *);
Send_Node * createIdentSendNode(Identfier_Node, RecipList_Node *);

SendListNode * makeSendList (Send_Node * );
SendListNode * makeSendList_List (Send_Node *, SendListNode *);

StatementNode * crateStatementNode(Send_Node *);
int checkIfIdentifier (Identfier_Node ident);

void printSendStatement(Adress_Node, Send_Node *);
//void printSendStatement2 (Adress_Node, SendListNode *);
void reportError(const char *error_msg);
bool validateTime(const char *time);
bool validateDate(const char *date);

Set_Node ** sets;
int sets_Size = 100;
int setPoint = 0;

int error = 0;

char ** errors;
int error_size = 100;
int errorPoint = 0;

%}


%union 
{
    String_Node string_Node;
    Identfier_Node ident_Node;
    DateNode date_Node;
    Set_Node * setNodePtr;
    int line_number;
    Recip_Node * recipNodePtr;
    Adress_Node adressNode;
    RecipList_Node * recipListNodePtr;
    Send_Node * sendNodePtr;
    SendListNode * sendListNodePtr;
    StatementNode * statementNodePtr;
}


%token <string_Node> tSTRING tTIME tDATE
%token <ident_Node> tIDENT
%token <adressNode> tADDRESS
//%token <date_Node> tDATE
%token tMAIL tENDMAIL tSCHEDULE tENDSCHEDULE tSEND tTO tFROM tSET tCOMMA tCOLON tLPR tRPR tLBR tRBR tAT
%start program


%type <setNodePtr> setStatement
%type <recipNodePtr> recipient;
%type <recipListNodePtr> recipientList;
%type <sendNodePtr> sendStatement;
%type <sendListNodePtr> sendStatements;
%type <statementNodePtr> statementList;
%type <ident_Node> identifier_tIDENT



%%

program : statements 
;

statements :                  
            | setStatement statements
            | mailBlock statements
;

mailBlock : tMAIL tFROM tADDRESS tCOLON statementList tENDMAIL {
                if ($5 != NULL && $5->type == TYPE_SEND_NODE) {
                    printSendStatement($3, $5->data.sendNode);
                }
            }
;

statementList : { $$ = NULL; }
                | setStatement statementList { /* Handle sendStatement */ }
                | sendStatement statementList {
                    $$ = crateStatementNode($1);
                }
                | scheduleStatement statementList { /* Handle sendStatement */ }
;

sendStatements : sendStatement {
                    $$ = makeSendList($1);
                }
                | sendStatement sendStatements
                {
                    $$ = makeSendList_List($1, $2);
                }
;


sendStatement : tSEND tLBR identifier_tIDENT tRBR tTO tLBR recipientList tRBR {
                    $$ = createIdentSendNode($3, $7);

                }
                | tSEND tLBR tSTRING tRBR tTO tLBR recipientList tRBR{
                    $$ = createStringSendNode($3,$7);
                }
;

identifier_tIDENT : tIDENT {
                controlIdentifier($1); 
                $$ = $1; 
            }
;

recipientList : recipient  {
                $$ = makeRecipList($1);
            }
            | recipientList tCOMMA recipient {
                $$ = makeRecipList_List($3,$1);
            }
;

recipient : tLPR tADDRESS tRPR {
                $$ = createRecipientNode($2);
            }
            | tLPR tSTRING tCOMMA tADDRESS tRPR{
                $$ = crateRecipientNodeString($2,$4);
            }
            | tLPR identifier_tIDENT tCOMMA tADDRESS tRPR {
                $$ = createRecipientNodeIdent($2,$4);
            }
;

scheduleStatement : tSCHEDULE tAT tLBR tDATE tCOMMA tTIME tRBR tCOLON sendStatements tENDSCHEDULE {
    if (!validateDate($4.value_num)) {
        char *error_msg;
        asprintf(&error_msg, "ERROR at line %d: date object is not correct (%s)\n", $4.line_number, $4.value_num);
        reportError(error_msg);
        free(error_msg);
    }
    if (!validateTime($6.value_num)) {
        char *error_msg;
        asprintf(&error_msg, "ERROR at line %d: time object is not correct (%s)\n", $6.line_number, $6.value_num);
        reportError(error_msg);
        free(error_msg);
    }
}


setStatement : tSET tIDENT tLPR tSTRING tRPR { 
        createSetNodeIdent($2, $4);
    }
;


%%

char* stripQuotes(char* str) {
    if (str == NULL) return NULL;
    size_t len = strlen(str);
    if (len > 2 && str[0] == '"' && str[len - 1] == '"') {
        char* newStr = malloc(len - 1);
        if (!newStr) return NULL;
        strncpy(newStr, str + 1, len - 2);
        newStr[len - 2] = '\0';
        return newStr;
    }
    return strdup(str);
}




void createSetNodeIdent(Identfier_Node ident, String_Node currString) {
    Set_Node * newNode = (Set_Node *)malloc(sizeof(Set_Node));
    if (newNode == NULL) {
        // Handle memory allocation failure
        return;
    }

    newNode->identifier = ident.value_num;
    char *strippedValue = stripQuotes(currString.value_num);
    newNode->value_num = strippedValue;
    newNode->line_number = ident.line_number;

    if (setPoint < sets_Size) {
        sets[setPoint] = newNode;
        setPoint += 1;
    } else {
        sets_Size = sets_Size + sets_Size;
        sets = realloc(sets, sets_Size);
        if (!sets) {
            // Handle memory allocation failure
            free(newNode);
            return;
        }
        sets[setPoint] = newNode;
        setPoint += 1;
    }
}


Recip_Node * createRecipientNodeIdent(Identfier_Node ident2, Adress_Node adress) {
    Recip_Node * newNode = (Recip_Node *)malloc(sizeof(Recip_Node));
    if (newNode == NULL) {
        // Handle memory allocation failure
        return NULL;
    }

    newNode->identifier = ident2.value_num;
    newNode->mail = adress.mail;

    int found = 0;
    int i;
    for (i = 0; i < setPoint; i++) {
        if (strcmp(ident2.value_num, sets[i]->identifier) == 0) {
            char *value_num = sets[i]->value_num;
            // Check if the value_num is a string literal with quotes
            if (value_num[0] == '"' && value_num[strlen(value_num) - 1] == '"') {
                newNode->name = stripQuotes(value_num);
            } else {
                newNode->name = strdup(value_num);
            }
            found = 1;
            break;
        }
    }
    if (!found) {
        newNode->name = strdup(ident2.value_num); // Use the identifier as the name
    }

    return newNode;
}


Recip_Node * crateRecipientNodeString(String_Node string, Adress_Node adress) {
    Recip_Node * newNode = (Recip_Node *)malloc(sizeof(Recip_Node));
    if (newNode == NULL) {
        // Handle memory allocation failure
        return NULL;
    }

    char * strippedName = stripQuotes(string.value_num);
    newNode->name = strippedName; // Assign the stripped name
    newNode->mail = adress.mail;
    newNode->identifier = NULL;
    return newNode;

}

Recip_Node * createRecipientNode(Adress_Node adress) {
    Recip_Node * new_Node = (Recip_Node *)malloc(sizeof(Recip_Node));
    if (new_Node == NULL) {
        // Handle memory allocation failure
        return NULL;
    }

    new_Node->name = NULL;
    new_Node->mail = adress.mail;
    new_Node->identifier = NULL;
    return new_Node;

}

RecipList_Node * makeRecipList(Recip_Node * recip) 
{
    RecipList_Node * newNode = (RecipList_Node *)malloc(sizeof(RecipList_Node));
    
    newNode->RecipIndex = 0;
    newNode->RecipSize = 100;
    int RecipSize = newNode->RecipSize;
    newNode->recipNode_recip = (Recip_Node**)malloc(RecipSize * sizeof(Recip_Node*));

    int index = newNode->RecipIndex;

    newNode->recipNode_recip[index] = recip;
    index += 1;
    newNode->RecipIndex = index;

    return newNode;
}


RecipList_Node * makeRecipList_List(Recip_Node * recip, RecipList_Node * recipList) {
    // Check for duplicate recipient
    int j;
    for (j = 0; j < recipList->RecipIndex; j++) {
        if (strcmp(recipList->recipNode_recip[j]->mail, recip->mail) == 0) {
            return recipList;
        }
    }

    // Check if the list needs resizing
    if (recipList->RecipIndex >= recipList->RecipSize) {
        int newRecipSize = recipList->RecipSize * 2;
        Recip_Node **newRecips = realloc(recipList->recipNode_recip, newRecipSize * sizeof(Recip_Node *));
        if (newRecips == NULL) {
            // Handle memory allocation failure
            return recipList;
        }
        recipList->recipNode_recip = newRecips;
        recipList->RecipSize = newRecipSize;
    }

    recipList->recipNode_recip[recipList->RecipIndex] = recip;
    recipList->RecipIndex += 1;

    return recipList;
}

SendListNode * makeSendList (Send_Node * send) 
{
    SendListNode * newNode = (SendListNode *)malloc(sizeof(SendListNode));

    newNode->SendIndex = 0;
    newNode->SendSize = 100;
    int SendSize = newNode->SendSize;
    newNode->sends = (Send_Node**)malloc(SendSize * sizeof(Send_Node*));

    int index = newNode->SendIndex;
    newNode->sends[index] = send;
    index += 1;
    newNode->SendIndex = index;

    return newNode;
}

SendListNode * makeSendList_List (Send_Node * send, SendListNode * sendList){
    int index = sendList->SendIndex;
    sendList->sends[index] = send;
    index += 1;
    sendList->SendIndex = index;

    return sendList;
}

Send_Node * createStringSendNode(String_Node currString, RecipList_Node * recipList) {
    Send_Node * newNode = (Send_Node *)malloc(sizeof(Send_Node));

    newNode->recipNode_recip = recipList;
    newNode->value_num = currString.value_num;
    newNode->identifier = NULL;

    return newNode;
}

Send_Node * createIdentSendNode(Identfier_Node ident, RecipList_Node * recipList) {
    Send_Node * newNode = (Send_Node *)malloc(sizeof(Send_Node));

    newNode->recipNode_recip = recipList;
    newNode->identifier = ident.value_num;

    int i = 0;

    Set_Node * newIdentNode = (Set_Node *)malloc(sizeof(Set_Node));
    newIdentNode->identifier = ident.value_num;
    newIdentNode->line_number = ident.line_number;

    for(;i<setPoint;i++) 
    {
        if(strcmp(newIdentNode->identifier, sets[i]->identifier) == 0) {
            newNode->value_num = sets[i]->value_num;
        }
    }

    return newNode;


}


StatementNode * crateStatementNode(Send_Node * currSend) 
{
    StatementNode *newNode = calloc(1, sizeof(StatementNode));
    if (newNode == NULL) {
        // Handle memory allocation failure
        return NULL;
    }
    newNode->type = TYPE_SEND_NODE;
    newNode->data.sendNode = currSend;
    return newNode;
}



void printSendStatement(Adress_Node address, Send_Node *statement) {
    if (statement == NULL || statement->recipNode_recip == NULL) {
        return; // No statement or recipients to process
    }

    char * message = statement->value_num;

    // Check if message is an identifier
    if (message == NULL || strcmp(message, "-1") == 0) {
        Identfier_Node ident_Node;
        ident_Node.value_num = statement->identifier;
        int identifierIndex = checkIfIdentifier(ident_Node);
        if (identifierIndex == -1) 
        {
            // Identifier not found
            return;
        }
        
        message = sets[identifierIndex]->value_num;
    }
    
    
    RecipList_Node *recipients = statement->recipNode_recip;
    int i;
    for (i = 0; i < recipients->RecipIndex; i++) {
        Recip_Node *recipient = recipients->recipNode_recip[i];
        if (recipient == NULL) {
            continue;
        }

        const char *recipientEmail = recipient->mail;
        const char *recipientName = recipient->name;
        // If the recipient name is not available, use the email

        if (recipientName == NULL || strcmp(recipientName, "-1") == 0) {
            recipientName = recipientEmail;
        }

        if (controlRecip_Identifier(recipients) != -1)
        {
            printf("E-mail sent from %s to %s: %s\n", address.mail, recipientName, message);
        }
    }
}

/*
void printSendStatement2(Adress_Node address, SendListNode *sendList) {

    if (sendList == NULL) {
        printf("No sends to process\n");
        return; // No sends to process
    }
    int i;
    for (i = 0; i < sendList->SendIndex; i++) {
        Send_Node *sendNode = sendList->sends[i];
        if (sendNode == NULL) {
            continue;
        }

        char *message = sendNode->value_num;
        printf("Processing Send_Node with message: %s\n", message ? message : "NULL");
        // Check if message is an identifier
        if (message == NULL || strcmp(message, "-1") == 0) {
            Identfier_Node ident_Node;
            ident_Node.value_num = sendNode->identifier;
            int identifierIndex = checkIfIdentifier(ident_Node);
            if (identifierIndex == -1) {
                // Identifier not found, consider handling this differently
                continue;
            }
            message = sets[identifierIndex]->value_num;
        }

        RecipList_Node *recipients = sendNode->recipNode_recip;
        int j;
        for (j = 0; j < recipients->RecipIndex; j++) {
            Recip_Node *recipient = recipients->recipNode_recip[j];
            if (recipient == NULL) {
                continue;
            }

            const char *recipientEmail = recipient->mail;
            const char *recipientName = recipient->name ? recipient->name : recipientEmail;

            printf("E-mail sent from %s to %s: %s\n", address.mail, recipientName, message);
        }
    }
}
*/


int controlIdentifier(Identfier_Node ident) {
    
    int i = 0;

    Set_Node * newNode = (Set_Node *)malloc(sizeof(Set_Node));
    newNode->identifier = ident.value_num;
    newNode->line_number = ident.line_number;

    for(;i<setPoint;i++) {
        if(strcmp(newNode->identifier, sets[i]->identifier) == 0) 
        {
            return i;
        }   
    }
    error = 1;

    char * src = "ERROR at line %d: %s is undefined\n";
    char * dest = (char *)malloc(strlen(src) + strlen(ident.value_num) + ident.line_number + 10);
    sprintf(dest, src, ident.line_number, ident.value_num);

    if(errorPoint < error_size) 
    {
        errors[errorPoint] = dest;
        errorPoint += 1;
    }
    else {
        error_size = error_size + error_size;
        errors = realloc(errors, error_size * sizeof(char *)); // Adjusted for correct size calculation
        errors[errorPoint] = dest;
        errorPoint += 1;
    }
    return -1;
}



int controlRecip_Identifier(RecipList_Node *recipList) {
    if (recipList == NULL) {
        return 0; // No recipients to check
    }

    int i;
    for (i = 0; i < recipList->RecipIndex; i++) {
        Recip_Node *recipNode = recipList->recipNode_recip[i];
        if (recipNode != NULL && recipNode->identifier != NULL && strcmp(recipNode->identifier, "-1") != 0) {
            Identfier_Node ident_Node;
            ident_Node.value_num = recipNode->identifier;
            if (checkIfIdentifier(ident_Node) == -1) {
                return -1; // Unidentified identifier found
            }
        }
    }
    return 0; // All identifiers are defined
}




bool validateDate(const char *date) {
    int day, month, year;
    if (sscanf(date, "%d/%d/%d", &day, &month, &year) != 3) {
        return false; // Format error
    }

    if (year < 1 || month < 1 || month > 12 || day < 1) {
        return false; // Basic range check
    }

    // Days in each month
    int daysInMonth[] = {31, (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)) ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};
    if (day > daysInMonth[month - 1]) {
        return false; // Day is out of range for the month
    }

    return true;
}

bool validateTime(const char *time) {
    int hours, minutes;
    if (sscanf(time, "%d:%d", &hours, &minutes) != 2) {
        return false; // Format error
    }

    if (hours < 0 || hours > 23 || minutes < 0 || minutes > 59) {
        return false; // Time range check
    }

    return true;
}

int checkIfIdentifier (Identfier_Node ident)
{
    int i = 0;
    int count = 0;
    Set_Node * newNode = (Set_Node *)malloc(sizeof(Set_Node));
    newNode->identifier = ident.value_num;
    newNode->line_number = ident.line_number;

    for(;i<setPoint;i++) 
    {
        if(strcmp(newNode->identifier, sets[i]->identifier) == 0) 
        {
            return i;
        }
    }
    return -1;
}

void reportError(const char *error_msg) {
    printf("%s", error_msg);
}


int main () 
{   

   sets = (Set_Node**)malloc(sets_Size * sizeof(Set_Node*)); 
   errors = (char**)malloc(error_size * sizeof(char*));

   if (yyparse())
   {
      // parse error
      printf("ERROR\n");
      return 1;
    } 
    else 
    {
        // successful parsing
    
        if (error != 0){
            int i = 0;
            for(;i<errorPoint;i++) {
                printf(errors[i]);
            }
        }
        return 0;
    } 
}






