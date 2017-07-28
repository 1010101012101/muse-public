/*
 * Copyright (c) 2014-2017 Leidos.
 * 
 * License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
 */
/*
 * Developed under contract #FA8750-14-C-0241
 */
#pragma once
/*********************************************
 *
 *  This is a simple flex++ lexer for extracting comments from C/C++
 * files (or any other language that uses the same commenting conventions).
 *
 **********************************************/

#include <stdint.h>
#include <vector>
#include <string>
#include <sstream>

namespace Fossometry
{
  class CommentScanner: public yyFlexLexer
  {
  public:
    
    typedef std::vector< std::pair<unsigned, std::string> > StringTable;
    
    CommentScanner();
    
    int yylex();
    
    void incrementLines();
    void addString(const std::string & str);
    void addComment(const std::string & str);
    void setInput(std::istream & input);

    const StringTable & comments() const;
    const StringTable & strings() const;
    
  private:
    void comment();
    void eatString();

    StringTable m_strings;
    StringTable m_comments;
    unsigned m_lineCount;
};
}

