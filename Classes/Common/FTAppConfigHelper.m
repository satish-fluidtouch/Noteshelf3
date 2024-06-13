//
//  FTAppConfigHelper.m
//  Noteshelf
//
//  Created by Amar on 8/10/15.
//
//

#import "FTAppConfigHelper.h"
#import "Noteshelf-Swift.h"

#if !TARGET_OS_MACCATALYST
#import <FirebaseRemoteConfig/FirebaseRemoteConfig.h>
#endif

NSString *const FTRemoteConfigShouldShowIRateNotification = @"FTRemoteConfigShouldShowIRateNotification";

NSString *const FTRemoteConfigOldValueKey = @"oldValue";
NSString *const FTRemoteConfigNewValueKey = @"newValue";

@interface FTAppConfigHelper ()

#if !TARGET_OS_MACCATALYST
@property (strong,readwrite) FIRRemoteConfig *appRemoteConfig;
#endif
@end

@implementation FTAppConfigHelper

+(instancetype _Nonnull)sharedAppConfig
{
    static FTAppConfigHelper *sharedConfigHelper = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedConfigHelper = [[FTAppConfigHelper alloc] init];
        [sharedConfigHelper registerDefaults];
    });
    return sharedConfigHelper;
}

#pragma mark Private Methods
-(void)registerDefaults
{
    #if !TARGET_OS_MACCATALYST
    self.appRemoteConfig = [FIRRemoteConfig remoteConfig];
    NSDictionary *defaultValues = @{[self hideiRateKey] : @(false),
                                           [self downloadableThemesGUIDKey] : @"49518704-4c22-11e7-b114-b2f933d5fe66",
                                           [self themesMetadataVersionKey] : @(2.0),
                                           [self clipartFilterVersionKey] : @(1),
                                           [self myScriptRecognitionResetDurationKey] : @(24 * 60 * 60)
   //                                        ,@"dev_message_uuid_12_0" : @"xyz-abc122322ggg"
   //                                        ,@"dev_message_show_12_0" : @(1)
   //                                        ,@"dev_message_learn_more_12_0" : @"235408087"
   //                                        ,@"dev_message_text_12_0" : @"sample text"
        };
    NSMutableDictionary *mutDefaultValue = [NSMutableDictionary dictionaryWithDictionary:defaultValues];
    [self.appRemoteConfig setDefaults:mutDefaultValue];
    #endif
}

#pragma mark Update App Config
-(void)updateAppConfig
{
    #if !TARGET_OS_MACCATALYST
    [self.appRemoteConfig fetchWithCompletionHandler:^(FIRRemoteConfigFetchStatus status, NSError * _Nullable error) {
        if(status == FIRRemoteConfigFetchStatusSuccess) {
            BOOL oldValueShouldShowIRate = [self shouldShowiRate];
            //To refresh the values with the latest pull
            [self.appRemoteConfig activateWithCompletion:^(BOOL changed, NSError * _Nullable error) {
                //newvalues
                BOOL newValueShouldShowIRate = [self shouldShowiRate];
                //irate
                if(oldValueShouldShowIRate != newValueShouldShowIRate) {
                    [iRate sharedInstance].promptAtLaunch = newValueShouldShowIRate;
                    [[NSNotificationCenter defaultCenter] postNotificationName:FTRemoteConfigShouldShowIRateNotification object:self userInfo:@{FTRemoteConfigOldValueKey : @(oldValueShouldShowIRate),FTRemoteConfigNewValueKey:@(newValueShouldShowIRate)}];
                }
            }];
        } else {
        }
        FTRemoteMessagePopupController *messagePopOver = [[FTRemoteMessagePopupController alloc] initWithRemoteConfig:self.appRemoteConfig];
        [messagePopOver popUpAppropriateMessage];
    }];
    #endif
}

#pragma mark Public Methods
-(BOOL)shouldShowiRate
{
    #if !TARGET_OS_MACCATALYST
#if DEBUG
    return  true;
#endif
    return !([self.appRemoteConfig configValueForKey:[self hideiRateKey]].boolValue);
    #else
    return FALSE;
    #endif
}

-(NSDictionary* _Nonnull)logFileInfo
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:@(![self shouldShowiRate]) forKey:[self hideiRateKey]];
    return dict;
}

// By default iRate is enabled. in case we want to stop it add hideiRateKey in remote config and set it to true.
-(NSString *)showiRateKey DEPRECATED_MSG_ATTRIBUTE("Use hideiRateKey instead")
{
    /*
     DEBUG      :   dev_enable_irate_appversion
     BETA      :   beta_enable_irate_appversion
     RELEASE    :   prod_enable_irate_appversion
     */
    NSString *key = [NSString stringWithFormat:@"%@_enable_irate_%@",appEnviromentPrefix(),[appVersion() stringByReplacingOccurrencesOfString:@"." withString:@"_"]];
    return key;
}

-(NSString *)hideiRateKey
{
    /*
     DEBUG      :   dev_disable_irate_appversion
     BETA      :   beta_disable_irate_appversion
     RELEASE    :   prod_disable_irate_appversion
     */
    NSString *key = [NSString stringWithFormat:@"%@_disable_irate_%@",appEnviromentPrefix(),[appVersion() stringByReplacingOccurrencesOfString:@"." withString:@"_"]];
    return key;
}

-(NSString *)themesMetadataVersionKey
{
    /*
     DEBUG      :   dev_themes_v8_metadata_version
     BETA      :   beta_themes_v8_metadata_version
     RELEASE    :   prod_themes_v8_metadata_version
     change themePlist in FTNThemeStorage after changing the key. Make sure the path is pointing to proper version folder like v5 in FTServerConfig themesMetadataURL method
     */
    NSString *key = [NSString stringWithFormat:@"%@_themes_v8_metadata_version",appEnviromentPrefix()];
    return key;
}

-(NSString *)clipartFilterVersionKey
{
    /*
     DEBUG      :   dev_clipart_filter_version
     BETA      :   beta_clipart_filter_version
     RELEASE    :   prod_clipart_filter_version
     change themePlist in FTNThemeStorage after changing the key. Make sure the path is pointing to proper version folder like v5 in FTServerConfig themesMetadataURL method
     */
    NSString *key = [NSString stringWithFormat:@"%@_clipart_filter_version",appEnviromentPrefix()];
    return key;
}

#pragma mark -
-(NSString*)downloadableThemesGUID
{
    #if !TARGET_OS_MACCATALYST
    return [self.appRemoteConfig configValueForKey:[self downloadableThemesGUIDKey]].stringValue;
    #else
    return @"49518704-4c22-11e7-b114-b2f933d5fe66";
    #endif
}

-(NSString*)downloadableThemesGUIDKey
{
    /*
     DEBUG      :   dev_downloadable_theme_GUID
     BETA      :   beta_downloadable_theme_GUID
     RELEASE    :   prod_downloadable_theme_GUID
     */
    return [NSString stringWithFormat:@"%@_downloadable_theme_GUID",appEnviromentPrefix()];
}

-(CGFloat)themesMetadataVersion
{
    #if !TARGET_OS_MACCATALYST
    CGFloat newCoverThemeversion = [self.appRemoteConfig configValueForKey:[self themesMetadataVersionKey]].numberValue.floatValue;
    return newCoverThemeversion;
    #else
    return 4.0;
    #endif
}

-(NSString*)forceDownloadMetadataKey
{
    NSString *key = [NSString stringWithFormat:@"%@_force_download_metadata_%@",appEnviromentPrefix(),[appVersion() stringByReplacingOccurrencesOfString:@"." withString:@"_"]];
    return key;
}

-(NSInteger)clipartFilterVersion {
    #if !TARGET_OS_MACCATALYST
    NSInteger newClipartFilterVersionKey = [self.appRemoteConfig configValueForKey:[self clipartFilterVersionKey]].numberValue.integerValue;
    return newClipartFilterVersionKey;
    #else
    return 1;
    #endif
}

-(NSString * _Nonnull)variationForiRateMessage {
#if !TARGET_OS_MACCATALYST
    NSString *iRateMessage = [self.appRemoteConfig configValueForKey:@"irate_message_type"].stringValue;
    return iRateMessage;
#else
    return @"a";
#endif
}

#pragma mark- Beta Program -
-(NSURL * _Nullable )betaTestingAppURL
{
    NSString *urlKey = [NSString stringWithFormat:@"v%@_Beta_App_URL_Key",[self betaProgramVersion]];
#if DEBUG
    NSString *urlString = [self.appRemoteConfig configValueForKey:urlKey].stringValue;
//    urlString = @"https://testflight.apple.com/join/mgyJaQR7";
#else
    NSString *urlString = [self.appRemoteConfig configValueForKey:urlKey].stringValue;
#endif
    if(urlString.length > 0) {
        return [NSURL URLWithString:urlString];
    }
    return nil;
}

-(NSString * _Nonnull)betaTestingAppVersionKey {
    #if !TARGET_OS_MACCATALYST
    NSString *betaAlertKey = [self.appRemoteConfig configValueForKey:@"betaAppAlertKey"].stringValue;
    if(nil == betaAlertKey || betaAlertKey.length == 0) {
        betaAlertKey = [NSString stringWithFormat:@"v%@_beta_alert",[self betaProgramVersion]];
    }
    return betaAlertKey;
    #else
    return @"";
    #endif
}

-(NSString * _Nonnull)betaProgramVersion {
    return @"8_2_0";
}

#pragma mark- My Script -
-(NSString*)myScriptRecognitionResetDurationKey
{
    return @"myScriptRecognitionResetDuration";
}

-(NSTimeInterval)myScriptRecognitionResetDuration
{
    #if !TARGET_OS_MACCATALYST
    NSTimeInterval resetDuration = [self.appRemoteConfig configValueForKey:[self myScriptRecognitionResetDurationKey]].numberValue.doubleValue;
    if (resetDuration == 0.0) {
        resetDuration = 24 * 60 * 60;
    }
    return resetDuration;
    #else
    return 24 * 60 * 60;
    #endif
}

@end
