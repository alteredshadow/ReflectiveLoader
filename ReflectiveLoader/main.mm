//
//  main.m
//  customLoader
//

#import <stdio.h>
#import <stdlib.h>
#import <Foundation/Foundation.h>
#import <signal.h>
#import <dispatch/dispatch.h>

#import "custom_dlfcn.h"

void signal_handler(int sig) {
    exit(1);
}

int main(int argc, const char * argv[]) {
    signal(SIGSEGV, signal_handler);
    signal(SIGBUS, signal_handler);
    signal(SIGILL, signal_handler);
    signal(SIGABRT, signal_handler);

    void* handle = NULL;
    NSData* payload = nil;

    if(argc != 2)
    {
        return -1;
    }

    if(strncmp(argv[1], "http", strlen("http")) == 0) {

        NSURL* url = [NSURL URLWithString:[NSString stringWithUTF8String:argv[1]]];
        payload = [NSData dataWithContentsOfURL:url];

    } else {

        NSString* path = [NSString stringWithUTF8String:argv[1]];
        payload = [NSData dataWithContentsOfFile:path];

    }

    if(0 == payload.length)
    {
        exit(-1);
    }

    try {
        handle = custom_dlopen_from_memory((void*)payload.bytes, (int)payload.length);
        if (handle == NULL) {
            return -1;
        }

        dispatch_main();

    } catch (...) {
        return -1;
    }

    return 0;
}
