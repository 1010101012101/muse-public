%option noyywrap
%option yyclass="CommentScanner"
%{
#include <arpa/inet.h>
#include <fstream>
#include "CommentScanner.h"

   using namespace Fossometry;
%}

%%
\'.\'		    { /* a character in single quotes */ }
\'\\.\'		    { /* an escaped character in single quotes */ }
\"                  { eatString(); }
"/*"                { comment(); }
\/\/(.)*            { addComment(yytext); }
\n		    { incrementLines(); }
.                   {}
%%

namespace Fossometry {
  CommentScanner::
  CommentScanner():
     m_lineCount(1)
  {}

  void 
  CommentScanner::
  setInput(std::istream & input)
  {
      switch_streams(&input);
  }

  void 
  CommentScanner::
  addString(const std::string & str)
  {
     m_strings.push_back(std::make_pair(m_lineCount, str));
  }

  void 
  CommentScanner::
  addComment(const std::string & str)
  {
     m_comments.push_back(std::make_pair(m_lineCount, str));
  }

  const CommentScanner::StringTable &
  CommentScanner::comments() const
  {
     return m_comments;
  }

  const CommentScanner::StringTable &
  CommentScanner::strings() const
  {
     return m_strings;
  }
   
  void CommentScanner::incrementLines()
  {
     m_lineCount++;
  }



  void CommentScanner::eatString()
  {
    std::ostringstream cstr;
     
     int c;
     bool escape = false;
     	  
     while ( !( (c = yyinput()) == '"' && !escape)  && c > 0)
     {
	 if (c == '\n')
	   incrementLines();
	 
	 cstr << (unsigned char)c;
	 if (c == '\\')
	   escape = !escape;
	 else
	   escape = false;
     }

     addString(cstr.str());
  }


  void CommentScanner::comment()
  {

     int c, c1;
     
     std::ostringstream cstr;
     unsigned firstLine = m_lineCount;
     
     bool done = false;
     
     while(!done)
     {
       while ((c = yyinput()) != '*' && c > 0)
       {
	 if (c == '\n')
	   incrementLines();
	 
	 cstr << (char)(c);
       }
       
       if ((c1 = yyinput()) != '/' && c > 0 && c1 > 0)
       {
	 unput(c1);
	 cstr << '*';
	 cstr << '*' << (char)(c1);
       }
       else
       {
	 done = true;
       }
     }    

     m_comments.push_back(std::make_pair(firstLine, cstr.str()));
   }
}

//#define TESTME
#ifdef TESTME
using namespace Fossometry;

int main(int argc, char **argv)
{
   CommentScanner scanner;

   std::fstream input;
   input.open(argv[1], std::fstream::in);
   if (input.fail())
   {
      fprintf(stderr, "Failed to open %s: ", argv[1]);
      perror(NULL);
      fputc('\n', stderr);
      return false;
   }

   scanner.switch_streams(&input);
   scanner.yylex();

   input.close();

   const CommentScanner::StringTable & comments = scanner.comments();


   std::cout << "Comments:\n";
   for (unsigned i = 0; i < comments.size(); i++)
   {
      std::cout << "Line " << comments[i].first << " =======\n";	
      std::cout << comments[i].second << "\n";
   }
}
#endif
