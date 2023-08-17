//
//  FTBackUpAccountInfo.h
//  Noteshelf
//
//  Created by Amar on 30/3/16.
//
//

#import <Foundation/Foundation.h>

@interface FTBackUpAccountInfo : NSObject

@property (strong) NSString *name;
@property (strong) NSString *email;
@property (assign) long long totalBytes;
@property (assign) long long consumedBytes;
@property (readonly,nonatomic) CGFloat percentageUsed;

@end
