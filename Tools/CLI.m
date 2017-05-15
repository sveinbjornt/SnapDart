/*
 Copyright (c) 2017, Sveinbjorn Thordarson <sveinbjornt@gmail.com>
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

NSString *ReadStandardInput(void) {
    NSData *inData = [[NSFileHandle fileHandleWithStandardInput] readDataToEndOfFile];
    if (!inData) {
        return nil;
    }
    return [[NSString alloc] initWithData:inData encoding:NSUTF8StringEncoding];
}

NSMutableArray *ReadRemainingArgs(int argc, const char **argv) {
    NSMutableArray *remainingArgs = [NSMutableArray array];
    while (optind < argc) {
        NSString *argStr = @(argv[optind]);
        optind += 1;
        [remainingArgs addObject:argStr];
    }
    return remainingArgs;
}

#pragma mark - 

NSMutableArray *ReadPathsFromStandardInput(void) {
    NSString *input = ReadStandardInput();
    NSMutableSet *set = [PathParser parse:input];
    return [NSMutableArray arrayWithArray:[set allObjects]];
}

NSMutableArray *ValidPathsInArguments(NSArray *args) {
    NSMutableArray *paths = [NSMutableArray array];
    
    for (NSString *a in args) {
        NSString *absPath = [PathParser makeAbsolutePath:a];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:absPath] == NO) {
            NSPrintErr(@"no such file, skipping: %@", absPath);
            continue;
        }
        
        [paths addObject:absPath];
    }
    return paths;
}

#pragma mark -

void PrintProgramVersion(void) {
    NSPrint(@"%@ version %@ (%@)",
            [[NSProcessInfo processInfo] processName],
            PROGRAM_VERSION,
            PROGRAM_NAME);
    exit(EX_OK);
}

#pragma mark - 

// print NSString to stdout
void NSPrint(NSString *format, ...) {
    va_list args;
    
    va_start(args, format);
    NSString *string  = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    fprintf(stdout, "%s\n", [string UTF8String]);
}

// print NSString to stderr
void NSPrintErr(NSString *format, ...) {
    va_list args;
    
    va_start(args, format);
    NSString *string  = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    fprintf(stderr, "%s\n", [string UTF8String]);
}

