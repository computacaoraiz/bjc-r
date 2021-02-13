#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>
#include <ctype.h>
#include <sys/mman.h>
#include <regex.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>

size_t page_size;

char intro[]="<!DOCTYPE html>\n"
"<html lang=\"en\">\n"
"	<head>\n"
"		<meta http-equiv=\"content-type\" content=\"text/html; charset=utf-8\" />\n"
"		<script type=\"text/javascript\" src=\"/bjc-r/llab/loader.js\"></script>\n"
"		<script type=\"text/javascript\" src=\"/bjc-r/utilities/gifffer.min.js\"></script>\n"
"        <script type=\"text/javascript\">window.onload = function() {Gifffer();}</script>\n"
"        <link rel=\"stylesheet\" type=\"text/css\" href=\"/bjc-r/css/bjc-gifffer.css\">\n"
"		<title>Index</title>\n"
"	</head>\n"
"\n"
"	<body>\n"
;

char outro[]="</body>\n</html>\n";

int main(int argc, char **argv) {
    FILE *fin,*fout;
    char line[1000], old[1000], compare[1000], pages[1000];
    char *page, *comp, *p;
    int initem=0;
    char ch;

    fin=fopen("summaries/index-sorted","r");
    fout=fopen("summaries/vocab-index.html","w");

    fprintf(fout,"%s",intro);
    old[0] = '\0';
    fprintf(fout,"%s\n","<div class=\"index-letter-link\">");
    for (ch = 'A'; ch<='Z'; ch++) {
      fprintf(fout,"<a href=\"#%c\">%c</a>&nbsp;",ch,ch);
    }
    fprintf(fout,"%s\n\n\n%s\n","</div>","<div>");
    ch = 'A'-1;

    /* Read a line from the sorted index entries */

    while (fgets(line,1000,fin) != NULL) {
      if (line[strlen(line)-1] == '\n') {
        line[strlen(line)-1] = '\0';
      }

      /* If this starts a new initial letter... */

      if (tolower(ch) < tolower(line[0])) {
	if (tolower(line[0]) != 'a') {
	    fprintf(fout,"%s","\n</li>\n</ul>\n"); // Close out old list
	}
	initem=0;
      }

	/* Alphabet labels for missing letters before the new one */

	for (ch++; tolower(ch) < tolower(line[0]); ch++) {
	    fprintf(fout,"\n<a name=\"%c\">&nbsp;</a>\n",
			    toupper(ch));
	}
	if (tolower(ch) == tolower(line[0])) {
	    fprintf(fout,"\n<p><a name=\"%c\">&nbsp;</a>%c</p>\n\n<ul>",
			    toupper(ch),toupper(ch));
	}
	ch = toupper(line[0]);

	/* If this is a new entry, lowercase and print it, else just sect */

	page = strstr(line, " <a ");

	comp = compare;

	for (p = line; p < page; p++) {
	    while (!isalpha(*p)) {
		*comp++ = *p++;
	    }
	    if (isupper(*p) && isupper(*(p+1))) {   // acronym
		while (isalpha(*p)) {
		    *comp++ = *p++;
		}
	    } else if (!strncmp(p, "Boole", 5)) {
		while (isalpha(*p)) {
		    *comp++ = *p++;
		}
	    } else {
		while (isalpha(*p)) {
		    *comp++ = *p = tolower(*p);
		    p++;
		}
	    }
	}

	*comp = '\0';

	/* make singular */

	if (*(comp-1) == 's') {
	    if (!strncmp(comp-3, "ies", 3)) {
		strcpy(comp-3, "y");
	    } else {
		*(comp-1) = '\0';
	    }
	}

	if (strcmp(compare, old)) {
	    if (initem) {
		fprintf(fout,"</li>\n");
	    }
	    fprintf(fout,"<li>%s",line);
	    strcpy(pages, page);
	    strcpy(old, compare);
	} else if (!strstr(pages, page)) {
	    fprintf(fout,",&nbsp;%s",page);	// Just the page reference
	    strcat(pages, page);
	}

    }

    /* end of file */

    fprintf(fout,"</li>\n</ul>\n");
    ch++;
    while (toupper(ch) <= 'Z') {
	    fprintf(fout,"\n<p><a name=\"%c\">&nbsp;</a></p>\n",
		    toupper(ch));
	    ch++;
    }
    fprintf(fout,"%s\n\n","</div>");
    fprintf(fout,"%s",outro);
    fclose(fin);
    fclose(fout);
}