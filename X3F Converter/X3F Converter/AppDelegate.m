#import "X3FFileFinderUtil.h"
#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
}

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename {
    NSArray<NSString*> *x3fFilePathList = [X3FFileFinderUtil getX3fFiles:@[filename]];
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_KEY_OPEN_FILES object:x3fFilePathList];
    return x3fFilePathList.count > 0;
}

- (void)application:(NSApplication *)theApplication openFiles:(NSArray<NSString *> *)filenames {
    NSArray<NSString*> *x3fFilePathList = [X3FFileFinderUtil getX3fFiles:filenames];
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_KEY_OPEN_FILES object:x3fFilePathList];
}

@end
