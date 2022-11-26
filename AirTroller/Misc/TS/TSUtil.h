@import Foundation;
#import "CoreServices.h"

extern NSString* getNSStringFromFile(int fd);
extern void printMultilineNSString(NSString* stringToPrint);
extern int spawnRoot(NSString* path, NSArray* args, NSString** stdOut, NSString** stdErr);
extern void killall(NSString* processName, BOOL softly);
extern void respring(void);
