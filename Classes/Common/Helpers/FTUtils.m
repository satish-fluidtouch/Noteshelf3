//
//  FTUtils.m
//  PDFAnnotation
//
//  Created by Ashok Prabhu on 19/3/13.
//  Copyright (c) 2013 FluidTouch.biz. All rights reserved.
//

#import "FTUtils.h"
#import <sys/utsname.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "Constants.h"
#if !NOTESHELF_ACTION
    #if NS2_SIRI_APP || NOTESHELF_ACTION
        #import "NS2Siri_Intent_Extension-Swift.h"
    #else
        #import "Noteshelf-Swift.h"
    #endif
#else
#import "Noteshelf3_Action-Swift.h"
#endif

#import "NSString_Backup_Additions.h"
#import "FTLogger.h"

@import CoreGraphics;
@import AVFoundation;

long long const KILOBYTE = 1024;
long long const MEGABYTE = KILOBYTE * 1024;
long long const GIGABYTE = MEGABYTE * 1024;
long long const TERABYTE = GIGABYTE * 1024;

NSString *_Nonnull const nsBookExtension = @"noteshelf";
NSString *_Nonnull const nsThemePackExtension = @"nsthemepack";
NSString *_Nonnull const nsPDFExtension = @"ns_pdf";
NSString *_Nonnull const pdfExtension = @"pdf";
NSString *_Nonnull const newNotebookTodayWidget = @"Noteshelf Today New";
NSString *_Nonnull const openNotebookTodayWidget = @"Noteshelf Today Open";

NSString *_Nonnull const FTDidChangePagePropertiesNotification = @"FTDidChangePagePropertiesNotification";

NSString *encryptionKeyFormat = @"%@_??_%@";

NSString* _Nonnull noteshelfDocumentsExt = @"nsdata";
NSString* _Nonnull noteshelfDocuments(void)
{
    return [@"Noteshelf" stringByAppendingPathExtension:noteshelfDocumentsExt];
}

NSString *utiType(NSString* path);

NSString *const _Nonnull FTDidUnlinkAllDropboxClient = @"FTDidUnlinkAllDropboxClient";

#if  !NS2_SIRI_APP && !NOTESHELF_ACTION && !NOTESHELF_ACTION
CG_EXTERN void dbSharedSessionUnlink(void)
{
    //[DBClientsManager unlinkAndResetClients];
    //[[NSNotificationCenter defaultCenter] postNotificationName:FTDidUnlinkAllDropboxClient object:nil];
}
#endif

@implementation FTUtils
// Returns the URL to the application's Documents directory.

+(NSString * _Nonnull)todayWidgetNewNotebookScheme
{
    NSArray *dataArray = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleURLTypes"];
    NSDictionary *firstData = [dataArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"CFBundleURLName == %@",newNotebookTodayWidget]].firstObject;
    return firstData[@"CFBundleURLSchemes"][0];
}

+(NSString * _Nonnull)todayWidgetOpenNotebookScheme
{
    NSArray *dataArray = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleURLTypes"];
    NSDictionary *firstData = [dataArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"CFBundleURLName == %@",openNotebookTodayWidget]].firstObject;
    return firstData[@"CFBundleURLSchemes"][0];
}

+ (NSURL* _Nonnull)applicationDocumentsDirectory
{
    NSURL *url = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:[self  getGroupId]];
#if  !NS2_SIRI_APP && !NOTESHELF_ACTION && !NOTESHELF_ACTION
    if(nil == url) {
        FTLogError(@"Share group ID issue", @{@"Group ID": [self  getGroupId]});
    }
#endif
    return url;
}

+ (NSURL* _Nonnull)ns2ApplicationDocumentsDirectory
{
    NSURL *url = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:[self getNS2GroupId]];
#if  !NS2_SIRI_APP && !NOTESHELF_ACTION && !NOTESHELF_ACTION
    if(nil == url) {
        FTLogError(@"Share group ID issue", @{@"Group ID": [self  getNS2GroupId]});
    }
#endif
    return url;
}

+(NSURL* _Nonnull)noteshelfDocumentsDirectory
{
    NSURL *noteURL = [self noteshelfDocumentsDirectoryInSharedLoc];
    BOOL isDir = NO;
    if((nil != noteURL) && ![[NSFileManager defaultManager] fileExistsAtPath:noteURL.path isDirectory:&isDir] && !isDir)
    {
        [[NSFileManager defaultManager] createDirectoryAtURL:noteURL withIntermediateDirectories:NO attributes:nil error:nil];
    }
    return noteURL;
}

+(NSURL* _Nonnull)ns2DocumentsDirectory
{
    NSURL *noteURL = [self ns2DocumentsDirectoryInSharedLoc];
    BOOL isDir = NO;
    if((nil != noteURL) && ![[NSFileManager defaultManager] fileExistsAtPath:noteURL.path isDirectory:&isDir] && !isDir)
    {
        [[NSFileManager defaultManager] createDirectoryAtURL:noteURL withIntermediateDirectories:NO attributes:nil error:nil];
    }
    return noteURL;
}

+(NSURL* _Nonnull )noteshelfDocumentsDirectoryInSharedLoc
{
    NSURL *docURL = [self applicationDocumentsDirectory];    
    NSURL *noteURL = [docURL URLByAppendingPathComponent:noteshelfDocuments() isDirectory:YES];
    return noteURL;
}

+(NSURL* _Nonnull )ns2DocumentsDirectoryInSharedLoc
{
    NSURL *docURL = [self ns2ApplicationDocumentsDirectory];
    NSURL *noteURL = [docURL URLByAppendingPathComponent:noteshelfDocuments() isDirectory:YES];
    return noteURL;
}

+(NSURL* _Nonnull )noteshelfDocumentsDirectoryBefore3o1
{
    NSURL *docURL = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL *noteURL = [docURL URLByAppendingPathComponent:noteshelfDocuments() isDirectory:YES];
    return noteURL;
}

+(NSString* _Nonnull)applicationCacheDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *baseDir = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return baseDir;
}

+(NSString* _Nonnull)applicationTempLocation
{
    NSString *cacheDirectory = [self applicationCacheDirectory];
    cacheDirectory = [cacheDirectory stringByAppendingPathComponent:@"TempCache"];
    BOOL isdir = NO;
    if(![[NSFileManager defaultManager] fileExistsAtPath:cacheDirectory isDirectory:&isdir] || !isdir)
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:cacheDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return cacheDirectory;
}

+ (NSString * _Nonnull)GetUUID
{
    return [[NSUUID new] UUIDString];
}

+(CGRect)aspectFitRect:(CGRect)inRect targetRect:(CGRect)maxRect{
    float originalAspectRatio = inRect.size.width / inRect.size.height;
	float maxAspectRatio = maxRect.size.width / maxRect.size.height;
    
	CGRect newRect = maxRect;
	if (originalAspectRatio > maxAspectRatio) { // scale by width
		newRect.size.height = (int)(maxRect.size.width * inRect.size.height / inRect.size.width);
		newRect.origin.y += (int)(maxRect.size.height - newRect.size.height)/2.0;
	} else {
		newRect.size.width = (int)(maxRect.size.height  * inRect.size.width / inRect.size.height);
		newRect.origin.x += (int)(maxRect.size.width - newRect.size.width)/2.0;
	}
    
	return CGRectIntegral(newRect);
}

#pragma mark -
#pragma mark Password Encryption

+(NSString * _Nonnull)encryptString:(NSString * _Nullable)string allowDefaultValue:(BOOL)allowDefault privateKey:(NSString* _Nullable)privateKey
{
    if (!string) string = @"";

//    string = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if(allowDefault && [string isEqualToString:@""]) string = NO_PASSWORD_STRING;
    
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    NSString *encyprtionKey = PASSWORD_SECRET;
    if(nil != privateKey)
    {
        encyprtionKey = [NSString stringWithFormat:encryptionKeyFormat,privateKey,PASSWORD_SECRET];
    }
    data = [data AES256EncryptWithKey:encyprtionKey];
    return [data base64EncodedStringWithOptions:0];
}


+(NSString * _Nullable)decryptString:(NSString * _Nullable)string allowDefaultValue:(BOOL)allowDefault privateKey:(NSString* _Nullable)privateKey
{
    if (!string) string = @"";
    
    NSData *data = [[NSData alloc] initWithBase64EncodedString:string options:NSDataBase64DecodingIgnoreUnknownCharacters];
    NSString *encyprtionKey = PASSWORD_SECRET;
    if(nil != privateKey)
    {
        encyprtionKey = [NSString stringWithFormat:encryptionKeyFormat,privateKey,PASSWORD_SECRET];
    }
    data = [data AES256DecryptDataWithKey:encyprtionKey];
    NSString *password = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

    if(!password)
    {
        password = @"59956";
    }
        
    if (allowDefault && [password isEqualToString:NO_PASSWORD_STRING]) {
        return nil;
    }
    
    if ([password isEqualToString:@""]) {
        return nil;
    }
    
    return password;
}

+(NSString* _Nonnull)deviceModelFriendlyName
{
    NSString *code = [self deviceModel];
    if([code isEqualToString:@"Unknown"]) {
        return code;
    }
    static NSDictionary* deviceNamesByCode = nil;
    
    if (!deviceNamesByCode) {
        
        deviceNamesByCode = @{
            @"i386" : @"iPhone Simulator",
            @"x86_64" : @"iPhone Simulator",
            @"iPhone1,1" : @"iPhone",
            @"iPhone1,2" : @"iPhone 3G",
            @"iPhone2,1" : @"iPhone 3GS",
            @"iPhone3,1" : @"iPhone 4",
            @"iPhone3,2" : @"iPhone 4 GSM Rev A",
            @"iPhone3,3" : @"iPhone 4 CDMA",
            @"iPhone4,1" : @"iPhone 4S",
            @"iPhone5,1" : @"iPhone 5 (GSM)",
            @"iPhone5,2" : @"iPhone 5 (GSM+CDMA)",
            @"iPhone5,3" : @"iPhone 5C (GSM)",
            @"iPhone5,4" : @"iPhone 5C (Global)",
            @"iPhone6,1" : @"iPhone 5S (GSM)",
            @"iPhone6,2" : @"iPhone 5S (Global)",
            @"iPhone7,1" : @"iPhone 6 Plus",
            @"iPhone7,2" : @"iPhone 6",
            @"iPhone8,1" : @"iPhone 6s",
            @"iPhone8,2" : @"iPhone 6s Plus",
            @"iPhone8,4" : @"iPhone SE (GSM)",
            @"iPhone9,1" : @"iPhone 7",
            @"iPhone9,2" : @"iPhone 7 Plus",
            @"iPhone9,3" : @"iPhone 7",
            @"iPhone9,4" : @"iPhone 7 Plus",
            @"iPhone10,1" : @"iPhone 8",
            @"iPhone10,2" : @"iPhone 8 Plus",
            @"iPhone10,3" : @"iPhone X Global",
            @"iPhone10,4" : @"iPhone 8",
            @"iPhone10,5" : @"iPhone 8 Plus",
            @"iPhone10,6" : @"iPhone X GSM",
            @"iPhone11,2" : @"iPhone XS",
            @"iPhone11,4" : @"iPhone XS Max",
            @"iPhone11,6" : @"iPhone XS Max Global",
            @"iPhone11,8" : @"iPhone XR",
            @"iPhone12,1" : @"iPhone 11",
            @"iPhone12,3" : @"iPhone 11 Pro",
            @"iPhone12,5" : @"iPhone 11 Pro Max",
            @"iPhone12,8" : @"iPhone SE 2nd Gen",
            @"iPod1,1" : @"1st Gen iPod",
            @"iPod2,1" : @"2nd Gen iPod",
            @"iPod3,1" : @"3rd Gen iPod",
            @"iPod4,1" : @"4th Gen iPod",
            @"iPod5,1" : @"5th Gen iPod",
            @"iPod7,1" : @"6th Gen iPod",
            @"iPod9,1" : @"7th Gen iPod",
            @"iPad1,1" : @"iPad",
            @"iPad1,2" : @"iPad 3G",
            @"iPad2,1" : @"2nd Gen iPad",
            @"iPad2,2" : @"2nd Gen iPad GSM",
            @"iPad2,3" : @"2nd Gen iPad CDMA",
            @"iPad2,4" : @"2nd Gen iPad New Revision",
            @"iPad3,1" : @"3rd Gen iPad",
            @"iPad3,2" : @"3rd Gen iPad CDMA",
            @"iPad3,3" : @"3rd Gen iPad GSM",
            @"iPad2,5" : @"iPad mini",
            @"iPad2,6" : @"iPad mini GSM+LTE",
            @"iPad2,7" : @"iPad mini CDMA+LTE",
            @"iPad3,4" : @"4th Gen iPad",
            @"iPad3,5" : @"4th Gen iPad GSM+LTE",
            @"iPad3,6" : @"4th Gen iPad CDMA+LTE",
            @"iPad4,1" : @"iPad Air (WiFi)",
            @"iPad4,2" : @"iPad Air (GSM+CDMA)",
            @"iPad4,3" : @"1st Gen iPad Air (China)",
            @"iPad4,4" : @"iPad mini Retina (WiFi)",
            @"iPad4,5" : @"iPad mini Retina (GSM+CDMA)",
            @"iPad4,6" : @"iPad mini Retina (China)",
            @"iPad4,7" : @"iPad mini 3 (WiFi)",
            @"iPad4,8" : @"iPad mini 3 (GSM+CDMA)",
            @"iPad4,9" : @"iPad Mini 3 (China)",
            @"iPad5,1" : @"iPad mini 4 (WiFi)",
            @"iPad5,2" : @"4th Gen iPad mini (WiFi+Cellular)",
            @"iPad5,3" : @"iPad Air 2 (WiFi)",
            @"iPad5,4" : @"iPad Air 2 (Cellular)",
            @"iPad6,3" : @"iPad Pro (9.7 inch, WiFi)",
            @"iPad6,4" : @"iPad Pro (9.7 inch, WiFi+LTE)",
            @"iPad6,7" : @"iPad Pro (12.9 inch, WiFi)",
            @"iPad6,8" : @"iPad Pro (12.9 inch, WiFi+LTE)",
            @"iPad6,11" : @"iPad (2017)",
            @"iPad6,12" : @"iPad (2017)",
            @"iPad7,1" : @"iPad Pro 2nd Gen (WiFi)",
            @"iPad7,2" : @"iPad Pro 2nd Gen (WiFi+Cellular)",
            @"iPad7,3" : @"iPad Pro 10.5-inch",
            @"iPad7,4" : @"iPad Pro 10.5-inch",
            @"iPad7,5" : @"iPad 6th Gen (WiFi)",
            @"iPad7,6" : @"iPad 6th Gen (WiFi+Cellular)",
            @"iPad7,11" : @"iPad 7th Gen 10.2-inch (WiFi)",
            @"iPad7,12" : @"iPad 7th Gen 10.2-inch (WiFi+Cellular)",
            @"iPad8,1" : @"iPad Pro 11 inch (WiFi)",
            @"iPad8,2" : @"iPad Pro 11 inch (1TB, WiFi)",
            @"iPad8,3" : @"iPad Pro 11 inch (WiFi+Cellular)",
            @"iPad8,4" : @"iPad Pro 11 inch (1TB, WiFi+Cellular)",
            @"iPad8,5" : @"iPad Pro 12.9 inch 3rd Gen (WiFi)",
            @"iPad8,6" : @"iPad Pro 12.9 inch 3rd Gen (1TB, WiFi)",
            @"iPad8,7" : @"iPad Pro 12.9 inch 3rd Gen (WiFi+Cellular)",
            @"iPad8,8" : @"iPad Pro 12.9 inch 3rd Gen (1TB, WiFi+Cellular)",
            @"iPad8,9" : @"iPad Pro 11 inch 2nd Gen (WiFi)",
            @"iPad8,10" : @"iPad Pro 11 inch 2nd Gen (WiFi+Cellular)",
            @"iPad8,11" : @"iPad Pro 12.9 inch 4th Gen (WiFi)",
            @"iPad8,12" : @"iPad Pro 12.9 inch 4th Gen (WiFi+Cellular)",
            @"iPad11,1" : @"iPad mini 5th Gen (WiFi)",
            @"iPad11,2" : @"iPad mini 5th Gen",
            @"iPad11,3" : @"iPad Air 3rd Gen (WiFi)",
            @"iPad11,4" : @"iPad Air 3rd Gen",
        };
    }
    
    NSString* deviceName = [deviceNamesByCode objectForKey:code];
    
    if (!deviceName) return code; //Just return the code as we did in the past
    
    return deviceName;
}

+(NSString* _Nonnull)deviceModel
{
    struct utsname systemInfo;
    
    uname(&systemInfo);
    NSString *modelName = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    return modelName ? modelName : @"Unknown";
}

+(NSString * _Nonnull)getNewAudioTrackName:(NSString* _Nonnull)extension {
    NSString *trackName = [[FTUtils GetUUID] stringByAppendingPathExtension:extension];
    return trackName;
}

+ (NSString * _Nonnull)timeFormatted:(NSUInteger)totalSeconds
{
    NSInteger
    seconds = 0,minutes = 0,hours=0;
    NSString *formatString = @"";
    
    hours = totalSeconds / 3600;
    if(hours > 0){
        seconds = totalSeconds % 60;
        minutes = (totalSeconds / 60) % 60;
        hours = totalSeconds / 3600;
        
        formatString = [NSString stringWithFormat:@"%02ld:%02ld:%02ld",(long)hours, (long)minutes, (long)seconds];
    }
    else{
        seconds = totalSeconds % 60;
        minutes = (totalSeconds / 60);
        formatString = [NSString stringWithFormat:@"%02ld:%02ld", (long)minutes, (long)seconds];
    }
    
    return formatString;
}

+ (NSString* _Nonnull)currentLanguage
{
    return [[[NSBundle mainBundle] preferredLocalizations] objectAtIndex:0];
}

+(BOOL)isNoteshelfBookType:(NSString* _Nonnull)extension
{
    if([extension.lowercaseString isEqualToString:nsBookExtension.lowercaseString]) {
        return true;
    }
    return false;
}

+(BOOL)isDeviceSupportsApplePencil2
{
    if(isDeviceSupportsApplePencil()) {
        Class pencilInteraction = NSClassFromString(@"UIPencilInteraction");
        if(nil != pencilInteraction) {
            return YES;
        }
    }
    return NO;
}

@end

NSArray* _Nonnull devicesOlderThaniPadPro(void)
{
    NSArray *array = @[ @"iPhone1,1",//return @"iPhone 1G";
                        @"iPhone1,2",//return @"iPhone 3G";
                        @"iPhone2,1",//return @"iPhone 3GS";
                        @"iPhone3,1",//return @"iPhone 4";
                        @"iPhone3,2",//return @"iPhone 4";
                        @"iPhone3,3",//return @"Verizon iPhone 4";
                        @"iPhone4,1",//return @"iPhone 4S";
                        @"iPhone5,1",//return @"iPhone 5 (GSM)";
                        @"iPhone5,2",//return @"iPhone 5 (GSM+CDMA)";
                        @"iPhone5,3",//return @"iPhone 5C (GSM)";
                        @"iPhone5,4",//return @"iPhone 5C (GSM+CDMA)";
                        @"iPhone6,1",//return @"iPhone 5S (GSM)";
                        @"iPhone6,2",//return @"iPhone 5S (GSM+CDMA)";
                        @"iPhone7,1",//return @"iPhone 6 Plus";
                        @"iPhone7,2",//return @"iPhone 6";
                        @"iPhone8,1",//return @"iPhone 6s";
                        @"iPhone8,2",//return @"iPhone 6s Plus";
                        @"iPhone8,4",//return @"iPhone SE";
                        @"iPhone9,1",//return @"iPhone 7";
                        @"iPhone9,2",//return @"iPhone 7 Plus";
                        @"iPhone10,1",//return @"iPhone 8";
                        @"iPhone10,4",//return @"iPhone 8";
                        @"iPhone10,2",//return @"iPhone 8 Plus";
                        @"iPhone10,5",//return @"iPhone 8 Plus";
                        @"iPhone10,3",//return @"iPhoneX";
                        @"iPhone10,6",//return @"iPhoneX";
                        
                        @"iPod1,1",//return @"iPod Touch 1G";
                        @"iPod2,1",//return @"iPod Touch 2G";
                        @"iPod3,1",//return @"iPod Touch 3G";
                        @"iPod4,1",//return @"iPod Touch 4G";
                        @"iPod5,1",//return @"iPod Touch 5G";
                        @"iPod7,1",//return @"iPod Touch 6G";
                        
                        @"iPad1,1",//return @"iPad";
                        @"iPad2,1",//return @"iPad 2 (WiFi)";
                        @"iPad2,2",//return @"iPad 2 (GSM)";
                        @"iPad2,3",//return @"iPad 2 (CDMA)";
                        @"iPad2,4",//return @"iPad 2 (WiFi)";
                        @"iPad2,5",//return @"iPad Mini (WiFi)";
                        @"iPad2,6",//return @"iPad Mini (GSM)";
                        @"iPad2,7",//return @"iPad Mini (GSM+CDMA)";
                        @"iPad3,1",//return @"iPad 3 (WiFi)";
                        @"iPad3,2",//return @"iPad 3 (GSM+CDMA)";
                        @"iPad3,3",//return @"iPad 3 (GSM)";
                        @"iPad3,4",//return @"iPad 4 (WiFi)";
                        @"iPad3,5",//return @"iPad 4 (GSM)";
                        @"iPad3,6",//return @"iPad 4 (GSM+CDMA)";
                        @"iPad4,1",//return @"iPad Air (WiFi)";
                        @"iPad4,2",//return @"iPad Air (Cellular)";
                        @"iPad4,3",//return @"iPad Air";
                        @"iPad4,4",//return @"iPad Mini 2G (WiFi)";
                        @"iPad4,5",//return @"iPad Mini 2G (Cellular)";
                        @"iPad4,6",//return @"iPad Mini 2G";
                        @"iPad4,7",//return @"iPad mini 3 (WiFi)";
                        @"iPad4,8",//return @"iPad mini 3 (Cellular)";
                        @"iPad4,9",//return @"iPad mini 3 (China Model)";
                        @"iPad5,1",//return @"iPad mini 4 (WiFi)";
                        @"iPad5,2",//return @"iPad mini 4 (Cellular)";
                        @"iPad5,3",//return @"iPad Air 2 (WiFi)";
                        @"iPad5,4",//return @"iPad Air 2 (Cellular)";
                        
                        @"i386",//return @"Simulator";
                        @"x86_64"];//return @"Simulator";
    return array;
}

BOOL isDeviceSupportsApplePencil(void)
{
    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return NO;
    }
    return YES;
}

BOOL useCustomFrameRateForDisplayLink(void)
{
    static BOOL useCustomFrameRateDisplayLink = NO;
    static dispatch_once_t onceTokenForCustomRate;
    dispatch_once(&onceTokenForCustomRate, ^{
        NSString *deviceModel = [FTUtils deviceModel];
        if (
            [deviceModel isEqualToString:@"iPad6,7"] // iPad Pro 12.9 inches - (model A1584)
            || [deviceModel isEqualToString:@"iPad6,8"] // iPad Pro 12.9 inches - (model A1652)
            || [deviceModel isEqualToString:@"iPad6,3"] // iPad Pro 9.7 inches - (model A1673)
            || [deviceModel isEqualToString:@"iPad6,4"] // iPad Pro 9.7 inches - (models A1674 and A1675)
            || [deviceModel isEqualToString:@"iPad6,11"] // iPad 9.7 inches Wifi- (models A1822)
            || [deviceModel isEqualToString:@"iPad6,12"] // iPad 9.7 inches cellular - (models A1823)
            ) {
            useCustomFrameRateDisplayLink = YES;
        }
    });
    return useCustomFrameRateDisplayLink;
}

CG_EXTERN CGAffineTransform NSPDFPageGetDrawingTransform(PDFPage *pageRef,
                                                         CGRect rect,
                                                         CGFloat pdfScale,
                                                         PDFDisplayBox pdfBox,
                                                         int rotatedAngle)
{
    CGAffineTransform sTransform = CGAffineTransformIdentity;
    float boxWidth, boxHeight;
    float destWidth, destHeight;

    float scaleX, scaleY;
    
    CGRect boxRect = [pageRef boundsForBox:pdfBox];
    boxWidth = CGRectGetWidth(boxRect);
    boxHeight = CGRectGetHeight(boxRect);
    
    NSInteger rotate = pageRef.rotation + rotatedAngle;
    // Adjust the page rotation angle to ensure that it is between 0-360 degrees.
    rotate %= 360;
    if (rotate < 0)
        rotate += 360;
    
    if(rotate == 90 || rotate == 270){
        float tmp = boxWidth;
        boxWidth = boxHeight;
        boxHeight = tmp;
    }
    
    // Obtain the origin, width and height of the destination rect.
    destWidth = CGRectGetWidth(rect);
    destHeight = CGRectGetHeight(rect);
    
    scaleX = destWidth/boxWidth;
    scaleY = destHeight/boxHeight;
    scaleX = scaleY = MIN(scaleX, scaleY);
    
    sTransform = CGAffineTransformMakeScale(scaleX, scaleY);
    
    return sTransform;
}

CG_EXTERN CGAffineTransform drawingTransform(PDFPage *pageRef,
                                             CGRect rect,
                                             CGFloat pdfScale,
                                             PDFDisplayBox pdfBox,
                                             int rotationAngle,
                                             NSString *metaDataVersion)
{
    CGFloat documentVersion = [metaDataVersion floatValue];
    if(documentVersion > 0)
        return NSPDFPageGetDrawingTransform(pageRef, rect, pdfScale, pdfBox,rotationAngle);
    
    //If the pdfpageRef is having the rotation angle of -90, when used with PDFPage's pageref the rotation angle us returned as 270
    //this will affect the current rendering of pdfpage for old documents created in NS1 earlier to 8.4 and below
    CFURLRef urlRef = (__bridge CFURLRef)(pageRef.document.documentURL);
    CGPDFDocumentRef docRef = CGPDFDocumentCreateWithURL(urlRef);
    
    CGPDFPageRef cgPageRef = CGPDFDocumentGetPage(docRef, pageRef.label.floatValue);
    CGRect mediaBoxRect;
    if(pdfBox == kPDFDisplayBoxCropBox) {
        mediaBoxRect = CGPDFPageGetBoxRect(cgPageRef, kCGPDFCropBox);
    }
    else {
        mediaBoxRect = CGPDFPageGetBoxRect(cgPageRef, kCGPDFMediaBox);
    }
    
    CGAffineTransform transform = CGPDFPageGetDrawingTransform(cgPageRef, kCGPDFMediaBox, rect, rotationAngle, true);

    if (pdfScale > 1) {
        transform = CGPDFPageGetDrawingTransform(cgPageRef, kCGPDFMediaBox, mediaBoxRect, rotationAngle, true);
        int angle = CGPDFPageGetRotationAngle(cgPageRef);
        angle = angle+rotationAngle;
        switch (angle) {
            case 0:
            {
                transform = CGAffineTransformScale(transform, pdfScale, pdfScale);
                transform.tx = 0;
                transform.ty = 0;//rect.size.height;
            }
                break;
            case 90:
            {
                transform = CGAffineTransformScale(transform, pdfScale, pdfScale);
                transform.tx = 0;
                transform.ty = rect.size.height;
            }
                break;
            case 180:
            {
                transform = CGAffineTransformScale(transform, pdfScale, pdfScale);
                transform.tx = rect.size.width;
                transform.ty = rect.size.height;
            }
                break;
            case 270:
            {
                transform = CGAffineTransformScale(transform, pdfScale, pdfScale);
                transform.tx = rect.size.width;
                transform.ty = 0;
            }
                break;
            default:
                break;
        }
    }
    CGPDFDocumentRelease(docRef);
    return transform;
}

CG_EXTERN NSString * _Nonnull appVersion(void)
{
    NSString *appversion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    if ([appversion length] == 0)
    {
        appversion = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
    }
    return appversion;
}

CG_EXTERN NSString* _Nonnull appBuildVersion(void)
{
    NSString *buildVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
    if(nil == buildVersion) {
        buildVersion = @"EMPTY";
    }
    return buildVersion;
}

CG_EXTERN NSString * _Nonnull dateStringForItem(NSDate *date)
{
    // Caching the dates string to avoid performance drop while formatting dates.
    NSString *dateString = [NSDateFormatter localizedStringFromDate:date
                                                          dateStyle:NSDateFormatterShortStyle
                                                          timeStyle:NSDateFormatterShortStyle];
    return dateString;
}

CG_EXTERN NSString * _Nonnull fileSize(long long fileSize)
{
    NSString * result_str = nil;
    
    if (fileSize >= TERABYTE)
    {
        double dSize = fileSize / (double)TERABYTE;
        result_str = [NSString stringWithFormat:NSLocalizedString(@"%1.1f TB", @"File size in terabytes (example: 1 TB)"), dSize];
    }
    else if (fileSize >= GIGABYTE)
    {
        double dSize = fileSize / (double)GIGABYTE;
        result_str = [NSString stringWithFormat:NSLocalizedString(@"%1.1f GB", @"File size in gigabytes (example: 1 GB)"), dSize];
    }
    else if (fileSize >= MEGABYTE)
    {
        double dSize = fileSize / (double)MEGABYTE;
        result_str = [NSString stringWithFormat:NSLocalizedString(@"%1.1f MB", @"File size in megabytes (example: 1 MB)"), dSize];
    }
    else if (fileSize >= KILOBYTE)
    {
        double dSize = fileSize / (double)KILOBYTE;
        result_str = [NSString stringWithFormat:NSLocalizedString(@"%1.1f KB", @"File size in kilobytes (example: 1 KB)"), dSize];
    }
    else if(fileSize > 0)
    {
        result_str = [NSString stringWithFormat:NSLocalizedString(@"%1.1f B", @"File size in bytes (example: 1 B)"), fileSize];
    }
    else
    {
        result_str = NSLocalizedString(@"Empty", @"File size 0 bytes");
    }
    
    return result_str;
}

NSArray<NSString*>* _Nonnull supportedUTITypesForDownload(void)
{
    static NSArray *supportedUTITypes = nil;
    if(!supportedUTITypes)
    {
        #if TARGET_OS_MACCATALYST
        supportedUTITypes = @[@"com.adobe.pdf"];
        #else
        supportedUTITypes = @[@"com.microsoft.excel.xls", @"com.microsoft.excel.xls", @"org.openxmlformats.spreadsheetml.sheet",@"com.microsoft.word.doc", @"org.openxmlformats.wordprocessingml.document",@"com.microsoft.powerpoint.ppt", @"org.openxmlformats.presentationml.presentation",@"com.adobe.pdf"];
        #endif
    }
    return supportedUTITypes;
}

NSArray<NSString*>* _Nonnull supportedAudioUTITypes(void)
{
    static NSArray *supportedUTITypes = nil;
    if(!supportedUTITypes)
    {
        supportedUTITypes = @[
            @"public.aac-audio",
            @"org.xiph.flac",
            AVFileTypeWAVE,
            AVFileTypeMPEGLayer3,
            AVFileTypeAIFF,
            AVFileTypeCoreAudioFormat,
            AVFileTypeAppleM4A,
            AVFileTypeAIFC
        ];
    }
    return supportedUTITypes;
}

NSArray<NSString *>* _Nonnull supportedMimeTypesForDownload(void)
{
    static NSArray *supportedMineTypes = nil;
    if(!supportedMineTypes)
    {
        #if TARGET_OS_MACCATALYST
        supportedMineTypes = [NSArray arrayWithObjects:@"application/pdf",
                              nil];
        #else
        supportedMineTypes = [NSArray arrayWithObjects:@"application/pdf",
                              @"application/vnd.ms-excel",
                              @"application/vnd.ms-excel.12",
                              @"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                              @"application/vnd.ms-powerpoint",
                              @"application/vnd.ms-powerpoint.12",
                              @"application/vnd.openxmlformats-officedocument.presentationml.presentation",
                              @"application/msword",
                              @"application/vnd.openxmlformats-officedocument.wordprocessingml.document",
                              @"application/vnd.ms-word.document.12",
                              @"text/html",
                              nil];
        #endif
    }
    return supportedMineTypes;
}
NSString* _Nullable MIMETypeFileAtPath(NSString *_Nonnull path)
{
    NSString *result = nil;
    NSString *extractedMimeType = nil;
    NSString *extension = [path pathExtension];
    if ([[extension lowercaseString] isEqualToString:@"pdf"])
    {
        return @"application/pdf";
    }
    if ([[extension lowercaseString] isEqualToString:noteshelfDocumentsExt]) {
        return @"com.ramki.noteshelfData";
    }
    if ([FTUtils isNoteshelfBookType:extension]) {
        return @"com.fluidtouch.noteshelfbook";
    }

    CFStringRef uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
                                                            (__bridge CFStringRef)extension, NULL);
    if (uti) {
        extractedMimeType = (__bridge NSString *)(uti);
        CFStringRef cfMIMEType = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType);
        if (cfMIMEType) {
            result = CFBridgingRelease(cfMIMEType);
        }
        CFRelease(uti);
    }
    if(nil == result)
    {
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
        BOOL isFolder = [[attributes fileType] isEqualToString:NSFileTypeDirectory];
        
        BOOL isPDFPackge = ([extractedMimeType caseInsensitiveCompare:@"com.ramki.noteshelfpdf"] == NSOrderedSame)?YES:NO;
        BOOL isNoteshelfData = ([extractedMimeType caseInsensitiveCompare:@"com.ramki.noteshelfData"] == NSOrderedSame)?YES:NO;
        
        if(isFolder && !isPDFPackge && !isNoteshelfData)
            result = @"";
        else
            result = extractedMimeType;
    }
    return result;
}

BOOL shouldConvertToPDF(NSString * _Nonnull path,
                        NSString *_Nullable * _Nullable mimeType)
{
    BOOL shouldConvert = YES;
     *mimeType = MIMETypeFileAtPath(path);
    if([supportedMimeTypesForDownload() containsObject:*mimeType])
    {
        if([*mimeType isEqualToString:@"application/pdf"])
            shouldConvert = NO;
    }
    else {
        *mimeType = nil;
    }
    return shouldConvert;
}

BOOL isAudioFile(NSString * _Nonnull path)
{
    BOOL audioFile = NO;
    NSString *uti = utiType(path);
    if(UTTypeConformsTo((__bridge CFStringRef _Nonnull)(uti), kUTTypeAudio)) {
        audioFile = YES;
    }
    return audioFile;
}

BOOL isImageFile(NSString * _Nonnull path) {
    BOOL imageFile = NO;
    NSString *uti = utiType(path);
    if(UTTypeConformsTo((__bridge CFStringRef _Nonnull)(uti), kUTTypeImage)) {
        imageFile = YES;
    }
    return imageFile;
}

BOOL isSupportedAudioFile(NSString * _Nonnull path)
{
    // Two formats that are not supported are "m4u" and "wma"
    BOOL supported = NO;

    NSArray *supportUTITypes = supportedAudioUTITypes();
    NSString *uti = utiType(path);
    if([supportUTITypes containsObject:uti]) {
        supported = YES;
    }
    return supported;
}

static NSFileHandle *handle = nil;

CG_INLINE void append(NSString *msg){

    if (handle == nil) {
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *path = [documentsDirectory stringByAppendingPathComponent:@"logfile.txt"];
        // create if needed
        if (![[NSFileManager defaultManager] fileExistsAtPath:path]){
            fprintf(stderr,"Creating file at %s",[path UTF8String]);
            [[NSData data] writeToFile:path atomically:YES];
        }
        
        handle = [NSFileHandle fileHandleForWritingAtPath:path];
    }
    
    //[handle truncateFileAtOffset:[handle seekToEndOfFile]];
    
    [handle writeData:[msg dataUsingEncoding:NSUTF8StringEncoding]];
    
    //[handle closeFile];
}

void Log2File(NSString *format,...) {
    va_list ap;
    va_start (ap, format);
    format = [format stringByAppendingString:@"\n"];
    NSString *msg = [[NSString alloc] initWithFormat:[NSString stringWithFormat:@"%@",format] arguments:ap];
    va_end (ap);
    
    append(msg);
}

NSString * _Nullable utiType(NSString* _Nonnull path)
{
    NSString *extractedUTIType = nil;
    NSString *extension = [path pathExtension];
    if ([[extension lowercaseString] isEqualToString:noteshelfDocumentsExt]) {
        return @"com.ramki.noteshelfData";
    }

    CFStringRef uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
                                                            (__bridge CFStringRef)extension, NULL);
    if (uti)
    {
        extractedUTIType = [(__bridge NSString *)(uti) copy];
        CFRelease(uti);
    }
    
    return extractedUTIType;
}

//CG_EXTERN FTPackageType packageType(NSString *_Nonnull path)
//{
//    NSString *mimeUTIType = utiType(path);
//    FTPackageType type = FTPackageTypeNone;
//    
//    if([mimeUTIType caseInsensitiveCompare:@"com.ramki.noteshelfData"] == NSOrderedSame)
//    {
//        type = FTPackageTypeDatabase;;
//    }
//    else     if([mimeUTIType caseInsensitiveCompare:@"com.ramki.noteshelfpdf"] == NSOrderedSame)
//    {
//        type = FTPackageTypePDF;;
//    }
//    else     if([mimeUTIType caseInsensitiveCompare:@"com.ramki.noteshelfNotebook"] == NSOrderedSame)
//    {
//        type = FTPackageTypeNotebook;;
//    }
//
//    return type;
//}

CG_EXTERN CGPoint CGPointIntegral(CGPoint p1)
{
    CGFloat x = ceil(p1.x);
    CGFloat y = ceil(p1.y);
    CGPoint point = CGPointMake(x, y);
    return point;
}

//MARK- APP Envi Key
NSString* _Nonnull appEnviromentPrefix(void)
{
#if DEBUG
    return @"dev";
#elif RELEASE
    return @"prod";
#else 
    return @"beta";
#endif
}

const CGFloat kAudioBarHeight = 47;

float distanceBetweenPoints2(CGPoint a, CGPoint b) {
    float deltaX = a.x - b.x;
    float deltaY = a.y - b.y;
    return sqrtf( (deltaX * deltaX) + (deltaY * deltaY) );
}
