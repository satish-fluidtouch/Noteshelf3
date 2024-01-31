//
//  FTDocument+FTDocumentSecurity.h
//  FTDocumentFramework
//
//  Created by Prabhu on 6/22/17.
//  Copyright © 2017 Fluid Touch. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "FTDocument.h"
@class FTSecurityModal;
@protocol FTFileItemSecurity;

@interface FTDocument (FTDocumentSecurity)<FTFileItemSecurity>
-(FTSecurityModal *)loadAndRevealKeys;
-(BOOL)authenticate:(NSString *)pin;
-(BOOL)isPinEnabled;
-(void)setHint:(NSString *)hint;
-(NSString *)getHint;
-(void)secureDocumentOnCompletion:(void(^)(BOOL success))completionHandler;
-(void)deSecureDocumentOnCompletion:(void(^)(BOOL success))completionHandler;
-(void)updatePin:(NSString *)newPin onCompletion:(void(^)(BOOL success))completionHandler;

/**
 Cordinate access methods to read files while FTDocument is not yet opened.
*/
-(void)authenticate:(NSString *)pin coordinated:(BOOL)coordinated completion:(void (^)(BOOL success,NSError *error ))complete;

/**
 Cordinate access methods to read files while FTDocument is not yet opened.
 Should be called only on secondary threads.
*/

-(void)documentUUIDWithCoordinatedAccess:(void (^)(NSString *uudi))completionBlock;


/**
 Keychain helper funcitons.
 TO-DO Considering moving to helper seperate file as helpers
 */
+(void)keychainSet:(NSString *)pin forKey:(NSString *)uuid;
+(void)keychainRemovPinFroKey:(NSString *)uuid;
+(NSString *)keychainGetPinForKey:(NSString *)uuid;

@end
