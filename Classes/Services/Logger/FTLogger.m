//
//  FTLogger.m
//  Noteshelf
//
//  Created by Akshay on 05/03/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

#import "FTLogger.h"
#import "Noteshelf-Swift.h"

/// IMPORTATNT: This C function is being used only by Objective-C classes, there's another function in FTLogger.Swift with the same name and implementation in order to reduce the ObjC and Swift interference. Consider updating the Swift file as well while modifying this.
void FTCLSLog(NSString *logString) {
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"CLS_REPORTING_ENABLED_KEY"] == YES) {
        [[FIRCrashlytics crashlytics] log:logString];
        [[FTLogger userFlowLogger] log:logString];
    }
}

void FTLogError(NSString *name, NSDictionary *attributes) {
    NSString *errorStr = [NSString stringWithFormat:@"Error ⚠️: %@, attributes: %@", name, attributes.description];
    FTCLSLog(errorStr);
    NSError *error = [NSError errorWithDomain:name code:1 userInfo:attributes];
    [[FIRCrashlytics crashlytics] recordError:error];
}
