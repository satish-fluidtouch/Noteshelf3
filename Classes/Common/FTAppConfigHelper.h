//
//  FTAppConfigHelper.h
//  Noteshelf
//
//  Created by Amar on 8/10/15.
//
//

#import <Foundation/Foundation.h>
@import FirebaseRemoteConfig;

#define FT_APP_CONFIG [FTAppConfigHelper sharedAppConfig]

CG_EXTERN NSString * _Nonnull const FTRemoteConfigShouldShowIRateNotification;

CG_EXTERN NSString * _Nonnull const FTRemoteConfigOldValueKey;
CG_EXTERN NSString * _Nonnull const FTRemoteConfigNewValueKey;

@interface FTAppConfigHelper : NSObject

+(instancetype _Nonnull)sharedAppConfig;
@property (readonly) FIRRemoteConfig * _Nonnull appRemoteConfig;

-(void)updateAppConfig;

-(BOOL)shouldShowiRate;

//log file info
-(NSDictionary* _Nonnull)logFileInfo;

-(CGFloat)themesMetadataVersion;

-(NSInteger)clipartFilterVersion;

//iOS 13 Beta related
-(NSURL * _Nullable )betaTestingAppURL;
-(NSString * _Nonnull)betaTestingAppVersionKey;

-(NSTimeInterval)myScriptRecognitionResetDuration;

-(NSInteger)offerPriceLocationForIAPOffer;

@end
