/*
 * Copyright (c) 2014-2017 Leidos.
 * 
 * License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
 */
/*
 * Developed under contract #FA8750-14-C-0241
 */
#include <ios>
#include <sstream>
#include <fstream>
#include <cctype>
#include <algorithm>
#include <string.h>
#include <wchar.h>


/**********************************************
 *
 *  FlexLexer.h belongs in CommentScanner.h but
 * we can't put it there because it's not protected
 * against being included twice, and we need to
 * include CommentScanner.h in CommentScanner.ll, which
 * automatically gets an include of FlexLexer.h added
 * to it.
 *
 *---------------------------------------------*/
#include <FlexLexer.h>
#include "CommentScanner.h"

using namespace Fossometry;

/* Hacker's delight number of leading zeros. */
static unsigned int nlz8(unsigned char x) {
  unsigned int b = 0;

  if (x & 0xf0) {
    x >>= 4;
  } else {
    b += 4;
  }

  if (x & 0x0c) {
    x >>= 2;
  } else {
    b += 2;
  }

  if (! (x & 0x02) ) {
    b++;
  }

  return b;
}

std::string 
escapeJson(const std::string & str)
{
  // The input is in utf-8 pretending to be a sequence of bytes. We have to
  // escape certain ascii characters, but we also have to make sure we don't
  // escape a byte that's part of multibyte sequence, even if we would have
  // to escape it if it were a single byte.

  std::stringstream result;
   
  const char * theString = str.c_str();
  const char * current = theString;
  unsigned length = strlen(theString);

  
  while (1)
    {
      unsigned unisize = nlz8(~(unsigned char)(*current));

      if (unisize == 0)
	{
	  // ascii character

	  char c_narrow = static_cast<char>(*current);

	  switch (c_narrow)
	    {	      
	    case '\b': 
	      result << "\\b";
	      break;
	    case '\f': 
	      result << "\\f";
	      break;
	    case '\n': 
	      result << "\\n";
	      break;
	    case '\r': 
	      result << "\\r";
	      break;
	    case '\t': 
	      result << "\\t";
	      break;
	    case '\v': 
	      result << "\\v";
	      break;
	    case '"': 
	      result << "\\\"";
	      break;
	    case '\\': 
	      result << "\\\\";
	      break;
	    default:
	      result << c_narrow;
	    }

	  current++;
	}
      else if (unisize == 1)
	{
	  /********************************
	   * 
	   *  This is a one-byte character with the high bit set (e.g.,
	   * it starts with '10'. Whether this is legal utf-8 apparently
	   * depends on who you ask, but jq crashes.
	   *
	   *****/
	  
	  result << (unsigned char)(0xc2) << *current;
	  current++;
	}
      else
	{

	  /*****************************************
	   *
	   *   json parsers can crash if you feed them a non-utf-8 character,
	   * but we have no guarantees at all about what kind of data we'll
	   * see here. If UTF-8 says this should be the start of a multi-byte
	   * character, we need to make sure it can really be interpreted as
	   * one.
	   *
	   ****/

	  bool looksValid = true;

	  for(unsigned i = 1; i < unisize; i++)
	  {
	    if (!current[i] || current[i] < 0x80 || current[i] > 0xbf)
	      {
		looksValid = false;
		break;
	      }
	  }

	  if (!looksValid)
	    {
	      
	      /**********************************
	       *
	       *  If we get here, the first two bits of the character must
	       * be 1. We can treat it as the corresponding ascii-8 character
	       * converted to UTF-8, though there's not way to know if that
	       * was the intent.
	       *
	       ********/

	      result << (unsigned char)(0xc3) << (unsigned char)(*current & ~0x40);
	      current++;
	    }
	  else
	    {
	      uint32_t num = 0;
	      for (unsigned i = 0; i < unisize; i++)
		{
		  result << (unsigned char)*current;
		  current++;
		  
		}
	    }
	}
      
      if (current >= theString + length)
	break;
    }
  
  return result.str();
  
}


  void analyze_one(const std::string &filename)
  {
    CommentScanner cscanner;
    std::fstream input;
    input.open(filename.c_str(), std::fstream::in);
    if (input.fail())
    {
      fprintf(stderr, "Failed to open %s: ", filename.c_str());
      perror(NULL);
      fputc('\n', stderr);
      return;
    }
    
    cscanner.switch_streams(&input);
    cscanner.yylex();
    
    input.close();

    printf("\t{\n\t\t\"file\": \"%s\",\n", escapeJson(filename).c_str());
    printf("\t\t\"comments\": [\n");
    bool first = true;
    const CommentScanner::StringTable & comments = cscanner.comments();
    for (unsigned i = 0; i < comments.size(); i++)
      {
	if (first)
	  first = false;
	else
	  printf(",\n");
	
	printf("\t\t\t{\n");
	printf("\t\t\t\t \"line\": %d,\n", comments[i].first);
	printf("\t\t\t\t \"comment\": \"%s\"\n", escapeJson(comments[i].second).c_str());
	printf("\t\t\t}");
      }

    printf("\n");
    printf("\t\t],\n");
    printf("\t\t\"strings\": [\n");
    const CommentScanner::StringTable & strings = cscanner.strings();
    first = true;
    for (unsigned i = 0; i < strings.size(); i++)
      {
	if (first)
	  first = false;
	else
	  printf(",\n");
	
	printf("\t\t\t{\n");
	printf("\t\t\t\t \"line\": %d,\n", strings[i].first);
	printf("\t\t\t\t \"string\": \"%s\"\n", escapeJson(strings[i].second).c_str());
	printf("\t\t\t}");
      }	

    printf("\n");
    printf("\t\t]\n");
    printf("\t}\n");


  }


  int main(int argc, char **argv)
  {
    bool printOuter = true;
    if (argc > 1 && !strcmp(argv[1], "-b"))
      printOuter = false;

    char buffer[1024];

    if (printOuter)
      printf("[\n");

    bool first = true;
    while (fgets(buffer, 1023, stdin))
      {
	if (first)
	  first = false;
	else
	  printf(",");
	char *end = strchr(buffer, '\n');
	if (end) *end = 0;
	analyze_one(buffer);
      }

    if (printOuter)
      printf("\n]\n");
 
  }

