//
//  FTBiometricManager.m
//  All My Days
//
//  Created by Chandan on 11/2/16.
//
//

#import "FTBiometricManager.h"
#import <LocalAuthentication/LocalAuthentication.h>
#import "Noteshelf-Swift.h"

#define CAN_SHOW_TOUCH_ID_ALERT @"CAN_SHOW_TOUCH_ID_ALERT" //Identifier for Settings > Noteshelf > Touch ID
#define TOUCH_ID_STATUS @"TOUCH_ID_STATUS"

@interface FTBiometricManager ()
@property(nonatomic,weak)UIViewController *alertParentViewController;
@end

@implementation FTBiometricManager

+(FTBiometricManager*)sharedManager
{
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] init];
    });
    return _sharedObject;
}

- (BOOL)isTouchIDAvailable:(void(^)(BOOL success, NSError * __nullable error))reply
{
    BOOL success;
    NSError *error;
    success = [[[LAContext alloc] init] canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error];
    if(reply){
        reply(success,error);
    }
    return success;
}

-(BOOL)isTouchIDAvailableForThisDevice
{
    BOOL touchIDAvailable = YES;
    NSError *error;
    LAContext *context = [[LAContext alloc] init];
    BOOL canEvaluatePolicy = [context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error];
    
    if(error.code == LAErrorBiometryNotAvailable){
        touchIDAvailable = NO;
    }
    
    if (canEvaluatePolicy) {
        
        self.biometryType = FTBiometryTypeTouchID;
        
        self.biometryType = (context.biometryType == LABiometryTypeTouchID) ? FTBiometryTypeTouchID : FTBiometryTypeFaceID;
    }
    
    return touchIDAvailable;
}

- (void)evaluateTouchID:(NSString*)reason reply:(void(^)(BOOL success, NSError *error))reply;
{
    LAContext *context = [[LAContext alloc] init];
    [context evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
            localizedReason:reason
                      reply:^(BOOL success, NSError *authenticationError) {
                          dispatch_async(dispatch_get_main_queue(), ^{
                              if(reply){
                                  reply(success,authenticationError);
                              }
                          });
                      }];
}


#pragma - custom methods for Noteshelf - 

-(NSString *)openWithBiometryCaption
{
    return [NSString stringWithFormat:NSLocalizedString(@"UseTouchID", comment: @"Open with Touch ID"), self.biometryType == FTBiometryTypeFaceID ? @"Face ID" : @"Touch ID"];//Do not localize Touch ID and Face ID as Apple is not localizing
}

-(BOOL)settingsStatusForTouchID
{
    return ([[NSUserDefaults standardUserDefaults] boolForKey:TOUCH_ID_STATUS] && [[FTBiometricManager sharedManager] isTouchIDAvailableForThisDevice]);
}

-(BOOL)canShowTouchIDCustomAlert
{
    BOOL canShowAlert = YES;
    NSNumber *object = [[NSUserDefaults standardUserDefaults] objectForKey:CAN_SHOW_TOUCH_ID_ALERT];
    if(!object){
        canShowAlert = YES; //default Value YES
    }
    else{
        canShowAlert = [object boolValue];
    }
    return canShowAlert;
}

-(BOOL)isTouchIDEnabled
{
    BOOL enabled = NO;
    if ([self settingsStatusForTouchID] && [[FTBiometricManager sharedManager] isTouchIDAvailable:nil]){
        enabled = YES;
    }
    return enabled;
}

#pragma mark - DocumentSpecific
-(BOOL)isTouchIDEnabledForUUID: (NSString *)uuid {
    return [self isTouchIDEnabled] && [FTBiometricManager keychainGetIsTouchIDEnabledForKey:uuid];
}

#pragma mark - KeychainStorage
+ (NSString *)touchIDKeyForUUID:(NSString *)uuid {
    return [NSString stringWithFormat:@"%@_TouchID", uuid];
}

+(void)keychainSetIsTouchIDEnabled:(BOOL)isTouchIDEnabled withPin:(NSString *)pin forKey:(NSString *)uuid {
    @try {
        NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
        KeychainItemWrapper *keychain = [[KeychainItemWrapper alloc] initWithIdentifier:bundleId accessGroup:nil];
        NSMutableDictionary *keys = [[NSMutableDictionary alloc] init];
        //read
        NSData * persistedData = (NSData *)[keychain objectForKey:(__bridge NSString *)kSecValueData];
        if (NO == ([persistedData isKindOfClass:[NSString class]] && [(NSString *)persistedData isEqualToString:@""])) {
            NSDictionary *temp = [NSKeyedUnarchiver unarchiveObjectWithData:persistedData];
            if (temp) {
                [keys addEntriesFromDictionary:temp];
            }
        }
        //write back
        [keys setValue:pin forKey:uuid];
        [keys setValue:[NSNumber numberWithBool:isTouchIDEnabled] forKey:[self touchIDKeyForUUID: uuid]];
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:keys];
        [keychain setObject:data forKey:(__bridge NSString *)kSecValueData];
        [keychain setObject:@"Noteshelf" forKey:(id)kSecAttrService];//TO avoid crash
        DEBUGLOG(@"Clearing data for document %@ from keychain",uuid);
    } @catch (NSException *exception) {
        DEBUGLOG(@"%@",exception);
    } @finally {
    }
}

+(BOOL)keychainGetIsTouchIDEnabledForKey:(NSString *)uuid {
    BOOL isTouchIDEnabled = NO;
    @try {
        NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
        KeychainItemWrapper *keychain = [[KeychainItemWrapper alloc] initWithIdentifier:bundleId accessGroup:nil];
        //read
        NSData * persistedData = (NSData *)[keychain objectForKey:(__bridge NSString *)kSecValueData];
        if (NO == ([persistedData isKindOfClass:[NSString class]] && [(NSString *)persistedData isEqualToString:@""])) {
            NSDictionary *temp = [NSKeyedUnarchiver unarchiveObjectWithData:persistedData];
            if (temp) {
                NSNumber *numberIsTouchIDEnabled = [temp objectForKey:[self touchIDKeyForUUID: uuid]];
                isTouchIDEnabled = [numberIsTouchIDEnabled boolValue];
            }
        }
        DEBUGLOG(@"Returning %@ from keychain",uuid);
    } @catch (NSException *exception) {
        DEBUGLOG(@"%@",exception);
    } @finally {
        return isTouchIDEnabled;
    }
}

+(void)keychainRemovIsTouchIDEnabledFroKey:(NSString *)uuid {
    @try {
        NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
        KeychainItemWrapper *keychain = [[KeychainItemWrapper alloc] initWithIdentifier:bundleId accessGroup:nil];
        NSMutableDictionary *keys = [[NSMutableDictionary alloc] init];
        //read
        NSData * persistedData = (NSData *)[keychain objectForKey:(__bridge NSString *)kSecValueData];
        if (NO == ([persistedData isKindOfClass:[NSString class]] && [(NSString *)persistedData isEqualToString:@""])) {
            NSDictionary *temp = [NSKeyedUnarchiver unarchiveObjectWithData:persistedData];
            if (temp) {
                [keys addEntriesFromDictionary:temp];
            }
        }
        //write back
        [keys removeObjectForKey:[self touchIDKeyForUUID: uuid]];
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:keys];
        [keychain setObject:data forKey:(__bridge NSString *)kSecValueData];
        [keychain setObject:@"Noteshelf" forKey:(id)kSecAttrService];//TO avoid crash
        DEBUGLOG(@"Clearing data for document %@ from keychain",uuid);
    } @catch (NSException *exception) {
        DEBUGLOG(@"%@",exception);
    } @finally {
    }
}



@end
