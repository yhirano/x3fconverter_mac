#import "X3FFileFinderUtil.h"

@implementation X3FFileFinderUtil

+ (NSArray<NSString*> *)getX3fFiles:(NSArray<NSString *>*)pathList {
    NSMutableArray<NSString*> *result = [NSMutableArray array];
    
    for (NSString *file in pathList) {
        BOOL isDirectory = NO;
        if ([[NSFileManager defaultManager] fileExistsAtPath:file isDirectory:&isDirectory] && !isDirectory &&
            [[file pathExtension] caseInsensitiveCompare:@"x3f"] == NSOrderedSame) {
            [result addObject:file];
        } else {
            NSArray<NSString*> *array = [[self class] getX3fFilesInDirectory:file];
            [result addObjectsFromArray:array];
        }
    }
    
    //    for (NSString *filePath in result) {
    //        NSLog(@"%@", filePath);
    //    }
    
    return result;
}

+ (NSArray<NSString*> *)getX3fFilesInDirectory:(NSString *)path {
    NSMutableArray *result = [NSMutableArray array];
    
    NSDirectoryEnumerator *dirEnum = [[NSFileManager defaultManager] enumeratorAtPath:path];
    NSString *name;
    while (name = [dirEnum nextObject]) {
        NSString *fullPath = [path stringByAppendingPathComponent:name];
        BOOL isDirectory = NO;
        if ([[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:&isDirectory] && !isDirectory &&
            [[fullPath pathExtension] caseInsensitiveCompare:@"x3f"] == NSOrderedSame) {
            [result addObject:fullPath];
        }
    }
    return result;
}

@end
