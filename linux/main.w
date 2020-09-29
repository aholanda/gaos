

@ The function |generate_data| linux kernel source files from 
the official repository, extract them and runs {\tt cflow}
program to parse its output to create a graph of function 
calls with the arc going from the callee to called function.

@d MAXCMD 512
@d MAXTOK 128 /* maximum size allowed for tokens */

@<static functions@>=
void generate_data() {
    /* command string to be executed */
    static char cmd[MAXCMD];
    static char graph_name[MAXTOK];
    int i;
    char *version;
   
    for (i=0; i<LNX_NVERS; i++) {
        version = versions[i];
        @<generate data files with the graph description@>@;
    }
}

@ The Linux versions to be processed are declared in a variable 
inside \&{CWEB} change file to substitute the next line:

@<internal data@>=
#define LNX_NVERS 0
static char *versions[];

@ The linux kernel version is appended to the linux 
repository URL |LNX_BASEURL| to retrieve information about the 
compressed files with the kernel. The information is 
retrieved by doing a {HTTP} request and only the 
files with extension ``{\tt tar.xz}'' are filtered using 
shell pipe and command {\tt grep}. Some reverse patterns are used 
 with {\tt grep} to exclude files other than the kernel ones. 
 The output is something like

{\bigskip\tt
   14. https://mirrors.edge.kernel.org/pub/linux/kernel/v1.0/linux-1.0.tar.xz
}

\noindent so {\tt awk} program is used to extract the URL part. 
The new line in the URL is removed by using the shell command {\tt tr}.
The filter command is defined as string in the macro |LNX_WGET_FILTER|.

@d LNX_BASEURL "https://mirrors.edge.kernel.org/pub/linux/kernel"
@d LNX_WGET_FILTER "| grep tar.xz | grep https | grep -v bdflush \
| grep -vi changelog | grep -vi modules | grep -v patches \
| grep -v v1.1.0 | awk '{print $2}' | tr -d '\n'"

@<generate data files with the graph description@>=
snprintf(cmd, MAXCMD,
    "lynx -dump %s/%s %s", LNX_BASEURL, version, LNX_WGET_FILTER);
f = popen(cmd, "r");
printf("%s\n", cmd);
while(fgets(buffer, MAXLINE, f)) {
    @<download...@>@;
    @<get the graph name@>@;
    @<unpack the kernel files@>@;
    @<run cflow and get the call traces@>@;
}
fclose(f);

@ @d MAXLINE 512

@<internal data@>=
static FILE *f, *ff;
static char buffer[MAXLINE];
static char *str; /* generic pointer to a string */

@ The compressed file with kernel source code is downloaded 
using the command {\tt wget}. The URL is stored in |buffer|
variable. All files are downloaded into directory |LNX_TMPDIR|. 

@d LNX_TMPDIR "/tmp"

@<download the compressed file@>=
str = &buffer[0]; 
snprintf(cmd, MAXCMD, "wget -q %s -P %s", str, LNX_TMPDIR);
fprintf(stderr, "%s\n", cmd);
system(cmd);

@ The graph name is extracted from the URL by getting its basename 
that represents the downloaded file, and removing the extension 
``{\tt tar.xz}''. In the URL used as an example before, 
the graph name would be ``linux-1.0''.

@<get the graph name@>=
snprintf(cmd, MAXCMD, "echo -n $(basename %s .tar.xz)", str);
printf("%s\n", cmd);
ff = popen(cmd, "r");
assert(fgets(graph_name, MAXTOK, ff));
fclose(ff);
fprintf(stderr, "G(%s)\n", graph_name);

@ @<unpack the kernel files@>=
snprintf(cmd, MAXCMD, "tar xfJ $(echo -n \"%s/$(basename %s)\") -C %s", 
         LNX_TMPDIR, str, LNX_TMPDIR);
fprintf(stderr, "%s\n", cmd);
system(cmd);
@<fix unversioned name@>@;

@ Some files are unpacked into directory base name ``linux''
without the version part. We add the version part to 
differentiate it.

@<fix unversioned...@>=
snprintf(cmd, MAXCMD, "[ -d %s/linux ] && mv -v %s/linux %s/%s", 
         LNX_TMPDIR, LNX_TMPDIR, LNX_TMPDIR, graph_name);
system(cmd);

@ @<run cflow and get the call traces@>=
snprintf(cmd, MAXCMD,
    "for c in $(find %s/%s -name \"*.c\"); do cflow $c; done", 
    LNX_TMPDIR, graph_name);
ff = popen(cmd, "r");
fprintf(stderr, "%s\n", cmd);
while(fgets(buffer, MAXLINE, ff)) {
    printf("%s", buffer);
}
fclose(ff);

@* The program.

@p
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
@#
@<internal data@>@;
@<static functions@>@;
@#
int main(int argc, char *argv) {
    generate_data();
    return 0;
}
