//
//  FTSecurityModal.h
//  FTDocumentFramework
//
//  Created by Prabhu on 6/22/17.
//  Copyright © 2017 Fluid Touch. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FTSecurityModal : NSObject
{
}

-(id)init:(NSString *)pin key:(NSData *)key salt:(NSData *)salt iv:(NSData *)iv;

@property(nonatomic,strong) NSData *key;
@property(nonatomic,strong) NSData *salt;
@property(nonatomic,strong) NSData *iv;

@end
