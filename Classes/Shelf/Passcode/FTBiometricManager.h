//
//  FTBiometricManager.h
//  All My Days
//
//  Created by Chandan on 11/2/16.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef enum {
    FTBiometryTypeUnknown   = 0,
    FTBiometryTypeTouchID   = 1,
    FTBiometryTypeFaceID    = 2,
} FTBiometryType;

@interface FTBiometricManager : NSObject

@property (nonatomic) BOOL isAttemptedEarlier;
@property (atomic) FTBiometryType biometryType;

+(FTBiometricManager*)sharedManager;

-(void)evaluateTouchID:(NSString*)reason reply:(void(^)(BOOL success, NSError *error))reply;
-(BOOL)isTouchIDEnabled;
-(BOOL)isTouchIDEnabledForUUID: (NSString *)uuid;

-(NSString *)openWithBiometryCaption;

#pragma mark - KeychainStorage
+(void)keychainSetIsTouchIDEnabled:(BOOL)isTouchIDEnabled withPin:(NSString *)pin forKey:(NSString *)uuid;
+(BOOL)keychainGetIsTouchIDEnabledForKey:(NSString *)uuid;
+(void)keychainRemovIsTouchIDEnabledFroKey:(NSString *)uuid;

@end
