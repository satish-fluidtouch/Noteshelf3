//
//  PressurePenEngine.h
//  Noteshelf
//
//  Created by Rama Krishna on 9/27/12.
//
//

@protocol PressurePenEngineDelegate;

@interface PressurePenEngine : NSObject


@property (nonatomic, weak) id <PressurePenEngineDelegate> delegate;

@property (nonatomic) BOOL applePencilEnabled;


@property (nonatomic, readonly) NSString *enabledPenName;
@property (nonatomic, readonly)StylusType enabledStylusType;

//UniversalSettings
@property (assign) int batteryLevel;

+(PressurePenEngine*)sharedPressurePenEngine;

+(NSString *)titleForButtonAction:(RKAccessoryButtonAction)buttonAction;


-(void)start;
-(void)stop;
-(void)refresh;
-(void)updateDefaults;

-(BOOL)pressurePenWristProtectionActive;

//Universal Settings
-(BOOL)isAnyStylusConnected;

@end


@protocol PressurePenEngineDelegate

//Called when a stylus is already connected when PressurePenEngine's start is called.
-(void)pressurePenAvailable:(NSString *)stylusName;

-(void)pressurePenNotAvailable:(NSString *)stylusName;

//Called when a stylus is gets connected after PressurePenEngine's start is called.
-(void)pressurePenConnected:(NSString *)stylusName;
//Called when a stylus is gets disconnected after PressurePenEngine's start is called
-(void)pressurePenDisconnected:(NSString *)stylusName;

//Called when a stylus type is enabled for use and no stylus is connected yet.
-(void)pressurePenEnabled:(NSString *)stylusName;
//Called when a stylus type is disabled for use and no stylus is connected yet.
-(void)pressurePenDisabled:(NSString *)stylusName;

-(void)pressurePenShowMessage:(NSString *)message;

-(void)pressurePenButtonAction:(RKAccessoryButtonAction)actionToPerform;

-(void)didSuggestEnablingGestures;
-(void)didSuggestDisablingGestures;


@end
