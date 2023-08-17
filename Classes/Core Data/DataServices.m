//
//  ApplicationState.m
//  Daily Notes
//
//  Created by Rama Krishna on 3/5/10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import "SynthesizeSingleton.h"
#import "DataServices.h"
#import "Noteshelf-Swift.h"

@interface DataServices ()

-(void)firstTimeInitialize;

@end

@implementation DataServices

SYNTHESIZE_SINGLETON_FOR_CLASS(DataServices)

-(void)initializeDatabase
{
#if DEBUG
#if TARGET_OS_SIMULATOR
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:WelcomeScreenViewed];
#else
    BOOL showWelcomeAlways = false;
    if(showWelcomeAlways) {
        [[NSUserDefaults standardUserDefaults] setBool:FALSE forKey:WelcomeScreenViewed];
    }
#endif
#endif
    
    if(![[NSUserDefaults standardUserDefaults] boolForKey:@"isAlreadyInstalled"]) {
        [[NSUserDefaults standardUserDefaults] setBool: TRUE forKey:@"quickCreateTipToShow"];
        [self firstTimeInitialize];
    }
    else
    {
        [FTUserDefaults registerDefaultsWithIsFreshInstall:false];
        [NSUserDefaults registerPageLayoutDefaultsWithFreshInsstall:false];
        [FTNotebookRecognitionHelper updateMyScriptActivationWithFreshInstall:FALSE];
    }
}

-(void)firstTimeInitialize{
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"isAlreadyInstalled"];
    if([FTWhatsNewManger shouldShowWhatsNew]) {
        [FTWhatsNewManger setAsWhatsNewViewed];
    }
    [FTUserDefaults registerDefaultsWithIsFreshInstall:true];
    [NSUserDefaults registerPageLayoutDefaultsWithFreshInsstall:true];
    [FTBetaAlertHandler initializeForFreshInstall];
    [FTNotebookRecognitionHelper updateMyScriptActivationWithFreshInstall:TRUE];
}

@end
