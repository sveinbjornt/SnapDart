/*
 Copyright (c) 2017, Sveinbjorn Thordarson <sveinbjorn@sveinbjorn.org>
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1. Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2. Redistributions in binary form must reproduce the above copyright notice, this
 list of conditions and the following disclaimer in the documentation and/or other
 materials provided with the distribution.
 
 3. Neither the name of the copyright holder nor the names of its contributors may
 be used to endorse or promote products derived from this software without specific
 prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 */

#import "CLI.h"
#import "NSWorkspace+Additions.h"

static void PrintHelp(void);

static const char optstring[] = "vhfp";

static struct option long_options[] = {
    {"version",                 no_argument,            0,  'v'},
    {"help",                    no_argument,            0,  'h'},
    {"force",                   no_argument,            0,  'f'},
    {"print",                   no_argument,            0,  'p'},
    {0,                         0,                      0,    0}
};

int main(int argc, const char * argv[]) { @autoreleasepool {
    int optch;
    int long_index = 0;
    
    BOOL force = NO;
    BOOL printOnly = NO;
    
    // parse getopt
    while ((optch = getopt_long(argc, (char *const *)argv, optstring, long_options, &long_index)) != -1) {
        switch (optch) {
                
            // print version
            case 'v':
                PrintProgramVersion();
                break;
                
            // ignore file limit
            case 'f':
                force = YES;
                break;
                
            case 'p':
                printOnly = YES;
                break;
                
            // print help with list of options
            case 'h':
            default:
            {
                PrintHelp();
                exit(EX_OK);
            }
                break;
        }
    }
    
    NSMutableArray *args = ReadRemainingArgs(argc, argv);
    NSString *commentArg;
    
    if (!printOnly) {
        if (![args count]) {
            PrintHelp();
            exit(EX_USAGE);
        }
        
        // First arg is label identifier
        commentArg = args[0];
        [args removeObjectAtIndex:0];
    }
    
    BOOL readStdin = ([args count] == 0);
    
    NSMutableArray *filePaths = [NSMutableArray array];
    
    if (readStdin) {
        filePaths = ReadPathsFromStandardInput(NO);
    } else {
        filePaths = ValidPathsInArguments(args);
        if ([filePaths count] < 1) {
            PrintHelp();
            exit(EX_USAGE);
        }
    }
    
    // Make sure Finder is running
    if ([[NSWorkspace sharedWorkspace] isFinderRunning] == NO) {
        NSPrintErr(@"Unable to set comment because Finder is not running.");
        exit(EX_UNAVAILABLE);
    }
    
    // Check if number of files exceeds limit
    if (([filePaths count] > DANGEROUS_FILE_LIMIT) && !force && !printOnly) {
        NSPrintErr(@"File count exceeds safety limit of %d. Use -f flag to override.",
                   DANGEROUS_FILE_LIMIT);
        exit(EX_USAGE);
    }
    
    // Set comment for files
    unsigned long count = 0;
    for (NSString *path in filePaths) {
        
        if (printOnly) {
            NSString *comment = [[NSWorkspace sharedWorkspace] finderCommentForFile:path];
            if (!comment) {
                comment = @"";
            }
            NSPrint(@"%@:\n%@\n", path, comment);
        }
        else {
        
            BOOL succ = [[NSWorkspace sharedWorkspace] setFinderComment:commentArg forFile:path];
            if (!succ) {
                NSPrintErr(@"Failed to set comment of '%@'", commentArg);
            } else {
                count += 1;
            }
        }
    }
    
    if (count && !printOnly) {
        NSPrint(@"Comment set on %d file%@", count, count > 1 ? @"s" : @"");
    }

    return EX_OK;
}}

#pragma mark -

static void PrintHelp(void) {
    NSPrint(@"usage: %@ [comment|-p] [file1 file2 ...]", [[NSProcessInfo processInfo] processName]);
}
