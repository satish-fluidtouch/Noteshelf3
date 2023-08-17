//
//  Constants.m
//  Noteshelf
//
//  Created by Amar on 9/6/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

NSInteger majorRadiusThreshold = 60;
NSInteger majorRadiusThresholdForGestures = 100;

NSString *const FTWillPerformUndoRedoActionNotification = @"FTWillPerformUndoRedoActionNotification";

NSString *const FTDidChangeWhiteBoardScreenValueNotification = @"FTDidChangeWhiteBoardScreenValueNotification";

NSString *const FTWHITEBOARD_ENABLE_KEY = @"FTWHITEBOARD_ENABLE_KEY";

NSString * const FTValidateToolBarNotificationName = @"FTRefreshDeskToolBarNotification";
NSString * const FTToggleToolbarModeNotificationName = @"FTToolbarModeToggle";

NSString * const FTDismissToolBarAccessoryNotificationName = @"DismissToolBarAccessoryNotificationName";

NSString *const FTShelfThemeDidChangeNotification = @"FTShelfThemeDidChangeNotification";
NSString *const CURRENT_SHELF_THEME_GUID_KEY = @"CURRENT_SHELF_THEME_GUID";

NSString *const FTExternalDisplayDidConnectedNotification = @"FTExternalDisplayDidConnectedNotification";
NSString *const FTRefreshExternalViewNotification = @"FTRefreshExternalViewNotification";
NSString *const FTRefreshRectKey = @"refreshRect";
NSString *const FTRefreshWindowKey = @"refreshWindow";
NSString *const FTRefreshPageIDKey = @"FTRefreshPageIDKey";

NSString *const FTZoomRenderViewDidEndCurrentStrokeNotification = @"FTZoomRenderViewDidEndCurrentStrokeNotification";
NSString *const FTImpactedRectKey = @"impactedRect";

NSString *const FTPageDidChangePageTemplateNotification = @"FTPageDidChangePageTemplateNotification";

NSString *const FTZoomRenderViewDidCancelledTouches = @"FTZoomRenderViewDidCancelledTouches";
NSString *const FTPDFDisableGestures = @"FTPDFDisableGestures";
NSString *const FTZoomRenderViewDidBeginTouches = @"FTZoomRenderViewDidBeginTouches";
NSString *const FTEnteringEditModeNotification = @"EnteringEditMode";
NSString *const FTPDFEnableGestures = @"FTPDFEnableGestures";
NSString *const FTZoomRenderViewDidEndTouches = @"FTZoomRenderViewDidEndTouches";
NSInteger const defaultKernValue = -0.25;

CG_EXTERN float roundOf2Digits(float value)
{
    float newValue = roundf(value*100);
    newValue /= 100;
    return newValue;
}
