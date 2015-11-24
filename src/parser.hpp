#ifndef ZIG_PARSER_HPP
#define ZIG_PARSER_HPP

#include "list.hpp"
#include "buffer.hpp"
#include "tokenizer.hpp"

struct AstNode;

enum NodeType {
    NodeTypeRoot,
    NodeTypeFnDecl,
    NodeTypeParamDecl,
    NodeTypeType,
    NodeTypePointerType,
    NodeTypeBlock,
    NodeTypeStatement,
    NodeTypeExpressionStatement,
    NodeTypeReturnStatement,
    NodeTypeExpression,
    NodeTypeFnCall,
};

struct AstNodeRoot {
    ZigList<AstNode *> fn_decls;
};

struct AstNodeFnDecl {
    Buf name;
    ZigList<AstNode *> params;
    AstNode *return_type;
    AstNode *body;
};

struct AstNodeParamDecl {
    Buf name;
    AstNode *type;
};

enum AstNodeTypeType {
    AstNodeTypeTypePrimitive,
    AstNodeTypeTypePointer,
};

struct AstNodeType {
    AstNodeTypeType type;
    Buf primitive_name;
    AstNode *child_type;
    bool is_const;
};

struct AstNodeBlock {
    ZigList<AstNode *> statements;
};

enum AstNodeStatementType {
    AstNodeStatementTypeExpression,
    AstNodeStatementTypeReturn,
};

struct AstNodeStatementExpression {
    AstNode *expression;
};

struct AstNodeStatementReturn {
    AstNode *expression;
};

struct AstNodeStatement {
    AstNodeStatementType type;
    union {
        AstNodeStatementExpression expr;
        AstNodeStatementReturn retrn;
    } data;
};

enum AstNodeExpressionType {
    AstNodeExpressionTypeNumber,
    AstNodeExpressionTypeString,
    AstNodeExpressionTypeFnCall,
};

struct AstNodeExpression {
    AstNodeExpressionType type;
    union {
        Buf number;
        Buf string;
        AstNode *fn_call;
    } data;
};

struct AstNodeFnCall {
    Buf name;
    ZigList<AstNode *> params;
};

struct AstNode {
    enum NodeType type;
    AstNode *parent;
    int line;
    int column;
    union {
        AstNodeRoot root;
        AstNodeFnDecl fn_decl;
        AstNodeType type;
        AstNodeParamDecl param_decl;
        AstNodeBlock block;
        AstNodeStatement statement;
        AstNodeExpression expression;
        AstNodeFnCall fn_call;
    } data;
};

__attribute__ ((format (printf, 2, 3)))
void ast_token_error(Token *token, const char *format, ...);
void ast_invalid_token_error(Buf *buf, Token *token);


// This function is provided by generated code, generated by parsergen.cpp
AstNode * ast_parse(Buf *buf, ZigList<Token> *tokens);

const char *node_type_str(NodeType node_type);

void ast_print(AstNode *node, int indent);

#endif
