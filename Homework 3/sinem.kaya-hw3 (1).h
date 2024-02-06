#ifndef __SINEM_H
#define __SINEM_H

 
typedef struct Set_Node
{
    char * value_num;
    char *identifier;
    int line_number;


} Set_Node;

typedef struct String_Node
{
    char * value_num;
    int line_number;

} String_Node;

typedef struct Identfier_Node
{
    char *value_num;
    int line_number;

} Identfier_Node;

typedef struct Recip_Node 
{
    char *name;
    char *mail;
    char *identifier;
} Recip_Node;

typedef struct Adress_Node
{
    char *mail;
} Adress_Node;

typedef struct RecipList_Node
{
    Recip_Node ** recipNode_recip;
    int RecipIndex;
    int RecipSize;
} RecipList_Node;

typedef struct Send_Node 
{
    RecipList_Node * recipNode_recip;
    char *identifier;
    char *value_num;
} Send_Node;

typedef struct SendListNode 
{
    Send_Node ** sends;
    int SendIndex;
    int SendSize;
}SendListNode;


typedef struct DateNode 
{
    char * day;
    char * month;
    char * year;
}DateNode;

typedef enum {
    TYPE_SET_NODE,
    TYPE_SEND_NODE,
    TYPE_RECIP_NODE,
    TYPE_RECIPLIST_NODE,
    TYPE_SENDLIST_NODE,
} StatementType;

typedef struct StatementNode 
{
    StatementType type; // An enum to indicate the type of statement
    union {
        Set_Node * setNode;
        Send_Node * sendNode;
        Recip_Node * recipNode;
        RecipList_Node * recipListNode;
        SendListNode * sendListNode;
    }data;

} StatementNode;

#endif