/*
 * Copyright (c) 2014-2017 Leidos.
 * 
 * License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
 */
/*
 * Developed under contract #FA8750-14-C-0241
 */
#include <stdio.h>
#include <tr1/unordered_set>
#include <string>
#include <string.h>
#include <algorithm>
#include <stdlib.h>

int main(int argc, char **argv)
{
  if (argc < 2)
    {
      fprintf(stderr, "Usage: filetypefilter <file with list of extensions>\n");
      exit(1);
    }

  FILE *extensions = fopen(argv[1], "r");
  if (!extensions)
    {
      fprintf(stderr, "Error opening %s:\n", argv[1]);
      perror(NULL);
      exit(1);
    }

  std::tr1::unordered_set<std::string> ext;
  
  char ext_string[BUFSIZ];
  while (fgets(ext_string, 1023, extensions))
    {
      char *nuline = strrchr(ext_string, '\n');
      if (nuline)
	*nuline = 0;

      if (strlen(ext_string))
	{
	  std::string str(ext_string);
	  std::transform(str.begin(), str.end(), str.begin(), ::tolower);
	  
	  ext.insert(str);
	}
    }
  
  
  char names[1024];
  while (fgets(names, 1023, stdin))
    {
      char *nuline = strrchr(names, '\n');
      if (nuline)
	*nuline = 0;

      char * dot = strrchr(names, '.');
      if (dot)
	{
	  dot++;

	  std::string dotstr(dot);
	  std::transform(dotstr.begin(), dotstr.end(),
			 dotstr.begin(), ::tolower);

	  if (ext.find(dotstr) != ext.end())
	    printf("%s\n", names);
	}
    }
}
