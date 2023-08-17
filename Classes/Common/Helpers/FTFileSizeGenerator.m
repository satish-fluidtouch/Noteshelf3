//
//  FTFileSizeGenerator.m
//  Noteshelf
//
//  Created by Amar on 5/4/16.
//
//

#import "FTFileSizeGenerator.h"
@import FTCommon;

@interface FTFileSizeGenerator ()

@property (strong) NSMutableDictionary *currentOperationInProgress;
@property (strong) NSOperationQueue *operationQueue;
@property (strong) NSMutableDictionary *fileSizeDictionary;

@end

@implementation FTFileSizeGenerator

+(instancetype)sharedFileSizeGen
{
    static dispatch_once_t onceToken;
    static FTFileSizeGenerator *staticManager = nil;
    dispatch_once(&onceToken, ^{
        staticManager = [[FTFileSizeGenerator alloc] init];
    });
    return staticManager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.currentOperationInProgress = [NSMutableDictionary dictionary];
        self.operationQueue = [[NSOperationQueue alloc] init];
        self.fileSizeDictionary = [NSMutableDictionary dictionary];
    }
    return self;
}

-(NSString*)packageSizeAtPath:(NSString*)packagePath
                     fileSize:(NSString**)packageSize
                 shouldUpdate:(BOOL)shouldUpdate
{
    if (!packagePath) {
        return nil;
    }
    NSString *fileHash = [NSString stringWithFormat:@"%lu",(unsigned long)packagePath.hash];
    NSString *localFileSize = [self.fileSizeDictionary objectForKey:fileHash];
    NSString *tokenId = nil;
    if (packageSize) {
        *packageSize = localFileSize;
    }
    
    if (!localFileSize || shouldUpdate) {
        tokenId = [self.currentOperationInProgress objectForKey:fileHash];
        if (tokenId) {
            return tokenId;
        }
        tokenId = [FTUtils GetUUID];
        
        __block __weak FTFileSizeGenerator *weakSelf = self;
        NSBlockOperation *blockOperation = [NSBlockOperation blockOperationWithBlock:^{
            long long fileSizeValue = [FTFileSizeGenerator getDirectoryFileSize:[NSURL fileURLWithPath:packagePath]];
            dispatch_async(dispatch_get_main_queue(), ^ {
                [weakSelf.currentOperationInProgress removeObjectForKey:fileHash];
                
                NSString *size = fileSize(fileSizeValue);
                if (![size isEqualToString:@"Empty"]) {
                    [self.fileSizeDictionary setObject:size forKey:fileHash];
                    [[NSNotificationCenter defaultCenter] postNotificationName:tokenId object:nil];
                }
            });
        }];
        
        [self.currentOperationInProgress setObject:tokenId forKey:fileHash];
        [self.operationQueue addOperation:blockOperation];
    }
    return tokenId;
}

+(long long)getDirectoryFileSize:(NSURL *)directoryUrl
{
    long long result = 0;
    NSArray *properties = [NSArray arrayWithObjects: NSURLLocalizedNameKey,
                           NSURLCreationDateKey, NSURLLocalizedTypeDescriptionKey, nil];
    
    NSArray *array = [[NSFileManager defaultManager]
                      contentsOfDirectoryAtURL:directoryUrl
                      includingPropertiesForKeys:properties
                      options:(NSDirectoryEnumerationSkipsHiddenFiles)
                      error:nil];
    
    for (NSURL *fileSystemItem in array)
    {
        BOOL directory = NO;
        [[NSFileManager defaultManager] fileExistsAtPath:[fileSystemItem path] isDirectory:&directory];
        if (!directory)
        {
            result += [[[[NSFileManager defaultManager] attributesOfItemAtPath:[fileSystemItem path] error:nil] objectForKey:NSFileSize] unsignedIntegerValue];
        }
        else
        {
            result += [FTFileSizeGenerator getDirectoryFileSize:fileSystemItem];
        }
    }
    
    return result;
}

@end
