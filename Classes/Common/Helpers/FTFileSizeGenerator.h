//
//  FTFileSizeGenerator.h
//  Noteshelf
//
//  Created by Amar on 5/4/16.
//
//

#import <Foundation/Foundation.h>

@interface FTFileSizeGenerator : NSObject

+(instancetype)sharedFileSizeGen;

//returns token to listen if the file is to be update or currently not available. otherwise it will return nil
-(NSString*)packageSizeAtPath:(NSString*)packagePath
                     fileSize:(NSString**)packageSize
                 shouldUpdate:(BOOL)shouldUpdate;

+(long long)getDirectoryFileSize:(NSURL *)directoryUrl;

@end
