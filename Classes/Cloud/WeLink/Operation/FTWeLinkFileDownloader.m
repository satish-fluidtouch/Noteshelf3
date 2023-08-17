//
//  FTWeLinkFileDownloader.m
//  Noteshelf
//
//  Created by Naidu on 23/01/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//
#import "UIKit/UIKit.h"
#import "FTWeLinkFileDownloader.h"
#import "Noteshelf-Swift.h"

#if TARGET_OS_IPHONE
#import <HWClouddriveLib/HWClouddriveManger.h>
#endif

@implementation FTWeLinkFileDownloader: NSObject

//Created Objective C File & extension due to no swift block support in WeLink SDK

-(NSProgress *)downloadFile:(FTWeLinkFile *)file completionHandler:(void(^)(NSString *downloadPath, NSError *error))completionHandler {
    NSProgress *progressObj = [[NSProgress alloc] init];
    progressObj.totalUnitCount = 100;
    
    void (^ callBack)(id result) = ^ (id result) {
        NSDictionary *jsonStr = [result objectForKey:@"jsonStr"];
        
        NSDictionary *errorInfo = jsonStr[@"error"];
        NSInteger errorCode = [errorInfo[@"errorCode"] integerValue];
        if (errorCode == 0) {
            CGFloat progress = [[jsonStr objectForKey:@"progress"] floatValue];
            progressObj.completedUnitCount = progress*100;
            if([[[jsonStr objectForKey:@"error"] objectForKey:@"errorMsg"] isEqualToString:@"下载成功"]){
                NSString *downloadPath = [jsonStr objectForKey:@"downloadFilePath"];
                completionHandler(downloadPath, nil);
            }
        } else {
            completionHandler(nil, [[NSError alloc] initWithDomain:@"FTDownloadError" code:100 userInfo:@{NSLocalizedDescriptionKey: @"Download Failed"}]);
        }
    };
#if !TARGET_OS_MACCATALYST
#if !TARGET_OS_SIMULATOR
    HWClouddriveURI* uri = [HWClouddriveURI URIWithString:@"method://welink.onebox/downloadClouddriveFileForThird"];
    uri.parameters = @{@"thirdClient_id":@"NoteShelf",
                       @"fileId":file.rid,
                       @"callback":callBack
                       };
    [[HWClouddriveManger Instance] resourceWithURI:uri];
#endif
#endif
    return progressObj;
}

@end
