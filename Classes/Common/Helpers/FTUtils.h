//
//  FTUtils.h
//  PDFAnnotation
//
//  Created by Ashok Prabhu on 19/3/13.
//  Copyright (c) 2013 FluidTouch.biz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PDFKit/PDFKit.h>

#define NOTEBOOK_NBK_VERSION @"2"

#define THEME_METADATA_UPDATED_NOTIFICATION @"THEME_METADATA_UPDATED_NOTIFICATION"

CG_EXTERN NSString *_Nonnull const nsThemePackExtension;
CG_EXTERN NSString *_Nonnull const nsPDFExtension;
CG_EXTERN NSString *_Nonnull const pdfExtension;

CG_EXTERN NSString *_Nonnull const FTDidChangePagePropertiesNotification;

CG_EXTERN void Log2File(NSString *_Nonnull format,...);

CG_EXTERN NSString* _Nonnull noteshelfDocuments(void);

@interface FTUtils : NSObject

+(NSString* _Nonnull )deviceModel;
+(NSString* _Nonnull )deviceModelFriendlyName;

+(NSURL* _Nonnull )ns2ApplicationDocumentsDirectory;
+(NSURL* _Nonnull )noteshelfDocumentsDirectory;
+(NSURL* _Nonnull)ns2DocumentsDirectory;
+(NSURL* _Nonnull )noteshelfDocumentsDirectoryInSharedLoc;
+(NSURL* _Nonnull )noteshelfDocumentsDirectoryBefore3o1;

+(NSString* _Nonnull )applicationCacheDirectory;
+(NSString* _Nonnull )applicationTempLocation;

+(NSString * _Nonnull )GetUUID;
+(CGRect)aspectFitRect:(CGRect)inRect targetRect:(CGRect)maxRect;

+(NSString * _Nonnull )encryptString:(NSString * _Nullable)string allowDefaultValue:(BOOL)allowDefault privateKey:(NSString* _Nullable)privateKey;
+(NSString * _Nullable )decryptString:(NSString * _Nullable)string allowDefaultValue:(BOOL)allowDefault privateKey:(NSString* _Nullable)privateKey;

+(NSString * _Nonnull)getNewAudioTrackName:(NSString* _Nonnull)extension;
+(NSString * _Nonnull)timeFormatted:(NSUInteger)totalSeconds;

+(NSString * _Nonnull)todayWidgetNewNotebookScheme;
+(NSString * _Nonnull)todayWidgetOpenNotebookScheme;

//Shelf Utilities
//+(NSString*)uniqueFileName:(NSString *)fileName;

+ ( NSString* _Nonnull )currentLanguage;

+(BOOL)isNoteshelfBookType:(NSString* _Nonnull)extension;

+(BOOL)isDeviceSupportsApplePencil2;

@end

typedef NS_ENUM(NSInteger, FTPackageType) {
    FTPackageTypeNone,
    FTPackageTypeDatabase,
    FTPackageTypePDF,
    FTPackageTypeNotebook,
};

typedef NS_ENUM(NSInteger, FTPageBackgroundType) {
    FTPageBackgroundTypeNone,
    FTPageBackgroundTypePDF,
    FTPageBackgroundTypeImage,
};

CG_EXTERN CGAffineTransform drawingTransform(PDFPage * _Nonnull pageRef,
                                             CGRect rect,
                                             CGFloat pdfScale,
                                             PDFDisplayBox pdfBox,
                                             int rotationAngle,
                                             NSString* _Nullable metaDataVersion);

CG_EXTERN NSString* _Nonnull appVersion(void);
CG_EXTERN NSString* _Nonnull appBuildVersion(void);

CG_EXTERN NSString* _Nonnull fileSize(long long fileSize);

CG_EXTERN NSString* _Nullable dateStringForItem(NSDate* _Nonnull date);

CG_EXTERN NSArray<NSString*>* _Nonnull supportedMimeTypesForDownload(void);


CG_EXTERN NSArray* _Nonnull devicesOlderThaniPadPro(void);

CG_EXTERN NSString* _Nullable MIMETypeFileAtPath(NSString *_Nonnull path);

CG_EXTERN BOOL shouldConvertToPDF(NSString * _Nonnull path,NSString* _Nullable * _Nullable mimeType);

//CG_EXTERN FTPackageType packageType(NSString* _Nonnull path);

CG_EXTERN CGAffineTransform NSPDFPageGetDrawingTransform(PDFPage * _Nonnull pageRef,CGRect rect,CGFloat pdfScale,PDFDisplayBox pdfBox,int rotatedAngle);

CG_EXTERN CGPoint CGPointIntegral(CGPoint p1);

CG_EXTERN const CGFloat kAudioBarHeight;

CG_EXTERN BOOL isDeviceSupportsApplePencil(void);

CG_EXTERN BOOL useCustomFrameRateForDisplayLink(void);

CG_EXTERN NSString* _Nonnull appEnviromentPrefix(void);

CG_EXTERN BOOL isAudioFile(NSString * _Nonnull path);
CG_EXTERN BOOL isSupportedAudioFile(NSString * _Nonnull path);
CG_EXTERN BOOL isImageFile(NSString * _Nonnull path);

CG_EXTERN void dbSharedSessionUnlink(void);
CG_EXTERN NSString * _Nonnull const FTDidUnlinkAllDropboxClient;
CG_EXTERN float distanceBetweenPoints2(CGPoint a, CGPoint b);
