/*
 *  The scanner definition for COOL.
 */
%option noyywrap

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

int comment_count = 0;
int str_count = 0;

%}

%x COMMENT_STATE
%x STRING_STATE
%x STRING_ERROR

/*
 * Define names for regular expressions here.
 */


/*    INTEGERS AND ID's     */
INTEGER         [0-9]+
OBJ_ID          [a-z]([a-zA-Z_0-9])*
TYPE_ID         [A-Z]([a-zA-Z_0-9])*


/*         STRINGS         */
QUOTE           \"
CHAR_ANY        .
CHAR_ESC        \\[^\\tfbn]
ESC_TAB         \\t
ESC_FF          \\f
ESC_BS          \\b
ESC_NL          \\n
ESC_BSS         \\\\
ESC_NEWLINE     \\\n


/*         COMMENTS         */
OPEN_COMMENT    \(\*
CLOSE_COMMENT   \*\)
LINE_COMMENT    --.*


/*         KEYWORDS         */
FALSE           f(?i:alse)
TRUE            t(?i:rue)
CLASS           (?i:class)
ELSE            (?i:else)
FI              (?i:fi)
IF              (?i:if)
IN              (?i:in)
INHERITS        (?i:inherits)
ISVOID          (?i:isvoid)
LET             (?i:let)
LOOP            (?i:loop)
POOL            (?i:pool)
THEN            (?i:then)
WHILE           (?i:while)
CASE            (?i:case)
ESAC            (?i:esac)
NEW             (?i:new)
OF              (?i:of)
NOT             (?i:not)

/*      WHITESPACE          */
WHITESPACE      [ \n\f\r\t\v]
NEWLINE         \n

/*         OPERATORS        */
DARROW          =>
ASSIGN          <-

PLUS            "+"
MINUS           "-"
TIMES           "*"
DIV             "/"

EQUAL           "="
LESS            "<"
LESS_EQ         <=

/*          SYMBOLS          */
L_PAREN         \(
R_PAREN         \)
L_BRACKET       "{"
R_BRACKET       "}"

SEMI_COLON      ;
COLON           :
COMMA           ,
DOT             "."
NEG             "~"
AT              "@"


%%
 /* -----------------------
  *  NEWLINES AND COMMENTS
  * -----------------------
  */
<INITIAL,COMMENT_STATE>{NEWLINE}      { curr_lineno++; }

<INITIAL,COMMENT_STATE>{OPEN_COMMENT} { comment_count++; BEGIN(COMMENT_STATE); }
<INITIAL>{CLOSE_COMMENT}              { cool_yylval.error_msg = "Unmatched *)"; return (ERROR); }
<COMMENT_STATE>{CLOSE_COMMENT}        { if (comment_count > 0) { comment_count--; }
                                        if (comment_count == 0){ BEGIN(INITIAL);  } }
<COMMENT_STATE>{CHAR_ANY}             { }
<COMMENT_STATE><<EOF>>                { cool_yylval.error_msg = "EOF in comment"; BEGIN(INITIAL); return (ERROR); }
{LINE_COMMENT}                        { }

 /* ------------------------
  *  OPERATORS AND SYMBOLS
  * ------------------------
  */
{DARROW}		              { return (DARROW); }
{ASSIGN}		              { return (ASSIGN); }

{PLUS}		                { return ('+'); }
{MINUS}		                { return ('-'); }
{TIMES}		                { return ('*'); }
{DIV}		                  { return ('/'); }

{EQUAL}		                { return ('='); }
{LESS_EQ}		              { return (LE);  }
{LESS}		                { return ('<'); }

{L_PAREN}		              { return ('('); }
{R_PAREN}		              { return (')'); }
{L_BRACKET}		            { return ('{'); }
{R_BRACKET}		            { return ('}'); }

{SEMI_COLON}		          { return (';'); }
{COLON}		                { return (':'); }
{COMMA}		                { return (','); }
{DOT}		                  { return ('.'); }
{NEG}		                  { return ('~'); }
{AT}		                  { return ('@'); }


 /* -----------------------
  *        KEYWORDS
  * -----------------------
  */
{FALSE}		                { cool_yylval.boolean = false; return(BOOL_CONST); }
{TRUE}		                { cool_yylval.boolean = true;  return(BOOL_CONST); }

{CLASS}		                { return (CLASS);     }
{ELSE}		                { return (ELSE);      }
{FI}		                  { return (FI);        }
{IF}		                  { return (IF);        }
{IN}		                  { return (IN);        }
{INHERITS}		            { return (INHERITS);  }
{ISVOID}		              { return (ISVOID);    }
{LET}		                  { return (LET);       }
{LOOP}		                { return (LOOP);      }
{POOL}		                { return (POOL);      }
{THEN}		                { return (THEN);      }
{WHILE}		                { return (WHILE);     }
{CASE}		                { return (CASE);      }
{ESAC}		                { return (ESAC);      }
{NEW}		                  { return (NEW);       }
{OF}		                  { return (OF);        }
{NOT}		                  { return (NOT);       }


 /* -----------------------
  *        STRINGS
  * -----------------------
  */
<INITIAL>{QUOTE}                  {BEGIN(STRING_STATE); string_buf[0] = '\0'; string_buf_ptr = string_buf; }
<STRING_STATE>{QUOTE}             { *string_buf_ptr = '\0'; 
                                    cool_yylval.symbol = new StringEntry(string_buf, string_buf_ptr - string_buf, str_count++); 
                                    BEGIN(INITIAL); 
                                    return (STR_CONST); 
                                  }

<STRING_STATE>{ESC_TAB}            {
                                    if (string_buf_ptr - string_buf >= MAX_STR_CONST - 1) {
                                      cool_yylval.error_msg = "String constant too long";
                                      BEGIN(STRING_ERROR);
                                      return (ERROR);
                                    }
                                    *string_buf_ptr = '\t';
                                    string_buf_ptr++;
                                  }
<STRING_STATE>{ESC_FF}            {
                                    if (string_buf_ptr - string_buf >= MAX_STR_CONST - 1) {
                                      cool_yylval.error_msg = "String constant too long";
                                      BEGIN(STRING_ERROR);
                                      return (ERROR);
                                    }
                                    *string_buf_ptr = '\f';
                                    string_buf_ptr++;
                                  }
<STRING_STATE>{ESC_BS}            {
                                    if (string_buf_ptr - string_buf >= MAX_STR_CONST - 1) {
                                      cool_yylval.error_msg = "String constant too long";
                                      BEGIN(STRING_ERROR);
                                      return (ERROR);
                                    }
                                    *string_buf_ptr = '\b';
                                    string_buf_ptr++;
                                  }
<STRING_STATE>{ESC_NL}            {
                                    if (string_buf_ptr - string_buf >= MAX_STR_CONST - 1) {
                                      cool_yylval.error_msg = "String constant too long";
                                      BEGIN(STRING_ERROR);
                                      return (ERROR);
                                    }
                                    *string_buf_ptr = '\n';
                                    string_buf_ptr++;
                                  }

<STRING_STATE>{ESC_BSS}            {
                                    if (string_buf_ptr - string_buf >= MAX_STR_CONST - 1) {
                                      cool_yylval.error_msg = "String constant too long";
                                      BEGIN(STRING_ERROR);
                                      return (ERROR);
                                    }
                                    *string_buf_ptr = '\\';
                                    string_buf_ptr++;
                                  }

<STRING_STATE>{CHAR_ESC}          { 
                                    if (string_buf_ptr - string_buf >= MAX_STR_CONST - 1) {
                                      cool_yylval.error_msg = "String constant too long";
                                      BEGIN(STRING_ERROR);
                                      return (ERROR);
                                    }
                                    if (yytext[1] == '\0') {
                                      cool_yylval.error_msg = "String contains null character";
                                      BEGIN(STRING_ERROR);
                                      return(ERROR);
                                    }
                                    *string_buf_ptr = yytext[1];
                                    string_buf_ptr++;
                                  }

<STRING_STATE>{CHAR_ANY}          { 
                                    if (string_buf_ptr - string_buf >= MAX_STR_CONST - 1) {
                                      cool_yylval.error_msg = "String constant too long";
                                      BEGIN(STRING_ERROR);
                                      return (ERROR);
                                    }
                                    if (yytext[0] == '\0') {
                                      cool_yylval.error_msg = "String contains null character";
                                      BEGIN(STRING_ERROR);
                                      return(ERROR);
                                    }
                                    *string_buf_ptr = yytext[0]; 
                                    string_buf_ptr++;
                                  }

<STRING_STATE>{NEWLINE}           {
                                    curr_lineno++; 
                                    BEGIN(INITIAL); 
                                    *string_buf_ptr = '\0'; 
                                    cool_yylval.error_msg = "Unterminated string constant"; 
                                    return (ERROR);
                                  }
<STRING_STATE>{ESC_NEWLINE}       {
                                    curr_lineno++; 
                                    *string_buf_ptr = '\n'; 
                                    string_buf_ptr++;
                                  }
<STRING_STATE><<EOF>>             {
                                    cool_yylval.error_msg = "EOF in string constant";
                                    BEGIN(INITIAL);
                                    return (ERROR);
                                  }


<STRING_ERROR>{NEWLINE}           { BEGIN(INITIAL); }
<STRING_ERROR>{QUOTE}             { BEGIN(INITIAL); }
<STRING_ERROR>{CHAR_ANY}          {  }



 /* -----------------------
  *    INTEGER AND ID's
  * -----------------------
  */
{INTEGER}                 { cool_yylval.symbol = new IntEntry(yytext, MAX_STR_CONST, str_count++); return (INT_CONST); }
{TYPE_ID}                 { cool_yylval.symbol = new IdEntry(yytext, MAX_STR_CONST,  str_count++); return (TYPEID); }
{OBJ_ID}                  { cool_yylval.symbol = new IdEntry(yytext, MAX_STR_CONST,  str_count++); return (OBJECTID); }

 /* ----------------------------
  *    WHITESPACE AND ERRORS
  * ----------------------------
  */

{WHITESPACE}              { }

{CHAR_ANY}                {cool_yylval.error_msg = yytext; return (ERROR); }

%%