/*
 *  Constants.h
 *  Noteshelf
 *
 *  Created by Rama Krishna on 8/7/10.
 *  Copyright 2010 __MyCompanyName__. All rights reserved.
 *
 */
#import <UIKit/UIKit.h>

#ifndef Constants_h
#define Constants_h

#define APPLICATION (NoteshelfApplication *)[UIApplication sharedApplication]

#define EVERNOTE_PUBLISH_IAP_PRODUCT_ID @"EVERNOTE_PUBLISH"

typedef void (^GenericSuccessBlock)(BOOL);
typedef void(^ VoidCompletionHanlder) (void);

CG_EXTERN NSInteger majorRadiusThresholdForGestures;

#define MAX_NOTEBOOKS_IN_TRIAL 10
#define MAX_PAGES_IN_TRIAL 3
#define PASSWORD_SECRET @"Noteshelf laladodola"
#define NO_PASSWORD_STRING @"???NO PASS???"

#define STRINGIZE(x) #x
#define STRINGIZE2(x) STRINGIZE(x)
#define MULTILINE_STRING_CONSTANT(text) @ STRINGIZE2(text)

#define assertMainThread() NSAssert([NSThread isMainThread],@"Method called using a thread other than main!")

typedef enum {
	FTENSynRecordNotebook = 0,
    FTENSynRecordPDF    = 1,
} FTENSyncRecordType;

typedef NS_ENUM(NSInteger,FTNotebookListType) {
    FTNotebookListTypeDropbox,
    FTNotebookListTypeEvernote
};

#define FTPageDidGetReleasedNotification @"FTPageDidGetReleasedNotification"
#define FTPageDidUpdatedPropertiesNotification @"FTPageDidUpdatedPropertiesNotification"
#define FTRecognitionInfoDidUpdateNotification @"FTRecognitionInfoDidUpdateNotification"
#define FTAudioSessionAskedToAddPlayerNotification @"FTAudioSessionAskedToAddPlayerNotification"
#define FTAudioSessionAskedToRemovePlayerNotification @"FTAudioSessionAskedToRemovePlayerNotification"
#define FTAudioAnnotationExportNotification @"FTAudioAnnotationExportNotification"

#define THUMBNAIL_SIZE CGSizeMake(200,248)

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue &  0xFF0000) >> 16))/255.0 green:((float)((rgbValue &  0xFF00) >> 8))/255.0 blue:((float)(rgbValue &  0xFF))/255.0 alpha:1.0]
#define CLAMP(x, low, high)  (((x) > (high)) ? (high) : (((x) < (low)) ? (low) : (x)))

#define SMART_MESSAGE_TAG 999

#define PEN_TUNING_MODE NO

typedef void (^completionBlock)(BOOL success);

typedef enum {
	kFirstVertex,
	kInterimVertex,
	kLastVertex
} VertexType;

typedef NS_ENUM(NSInteger,RKDeskMode) {
	kDeskModePen,
	kDeskModeMarker,
	kDeskModeEraser,
	kDeskModeStickers,
	kDeskModePhoto,
    kDeskModeCamera, //We are not using it now but it is kept because it is there in DB
    kDeskModeClipboard,
	kDeskModeText,
    kDeskModeView,
    kDeskModeLaser,
    kDeskModeShape,
    kDeskModeReadOnly,
    kDeskModeFavorites,
} ;

typedef enum {
	kExportFormatImage = 0,
	kExportFormatPDF = 1,
    kExportFormatNBK = 2,
    kExportFormatTemplate = 3
} RKExportFormat;

typedef enum {
	kExportModeEmail,
	kExportModeiTunes,
	kExportModeDropbox,
	kExportModeEvernote,
	kExportModePhotoAlbum,
	kExportModePrint,
    kExportModeBox,
    kExportModeGoogleDrive,
    kExportModeOneDrive,
    kExportModeOpenIn,
    kExportModeFacebook,
    kExportModeTwitter,
    kExportModeFilesDrive,
    kExportModeSaveAsTemplate,
    kExportModeSchoolwork,
    kExportModeNone,
} RKExportMode;

typedef enum {
    FTFileTypeFolder,
    FTFileTypeRegular,
    FTFileTypePDF,
}FTFileType;

typedef NS_ENUM(NSInteger, FTWritingStyle)
{
    FTWritingStyleRightBottom,
    FTWritingStyleRightCenter,
    FTWritingStyleRightTop,
    FTWritingStyleLeftBottom,
    FTWritingStyleLeftCenter,
    FTWritingStyleLeftTop,
};

typedef enum {
    FTSnapshotPurposeDefault,
    FTSnapshotPurposeEvernoteSync,
    FTSnapshotPurposeThumbnail,
}FTSnapshotPurpose;

CG_EXTERN NSInteger const defaultKernValue;

CG_INLINE CGFloat aspectFittedRatio(CGSize sourceSize,CGSize targetSize)
{
    //do not resize if the actual size is within the bounds
    if (sourceSize.width <= targetSize.width && sourceSize.height <= targetSize.height) {
        return 1;
    }
    
    CGFloat horizontalRatio = targetSize.width / sourceSize.width;
    CGFloat verticalRatio = targetSize.height / sourceSize.height;
    CGFloat ratio;
    ratio = MIN(horizontalRatio, verticalRatio);
    
    return ratio;
}

CG_INLINE CGRect CGRectSetCenter(CGRect rect,CGPoint center,CGRect maxFrame)
{
    CGRect centeredFrame = CGRectMake(MAX(0, center.x - CGRectGetWidth(rect)*0.5),
                                      MAX(0,center.y - CGRectGetHeight(rect) * 0.5),
                                      CGRectGetWidth(rect),
                                      CGRectGetHeight(rect));
    
    if ((centeredFrame.origin.x + CGRectGetWidth(centeredFrame)) > CGRectGetWidth(maxFrame)) {
        centeredFrame.origin.x = CGRectGetWidth(maxFrame) - CGRectGetWidth(centeredFrame);
    }
    
    if ((centeredFrame.origin.y + CGRectGetHeight(centeredFrame)) > CGRectGetHeight(maxFrame)) {
        centeredFrame.origin.y = CGRectGetHeight(maxFrame) - CGRectGetHeight(centeredFrame);
    }
    
    return centeredFrame;
}

CG_INLINE CGRect CGRectScaleFromCenter(CGRect rect,CGFloat scale)
{
    CGRect finalFrame = rect;
    CGFloat centerX = CGRectGetMidX(finalFrame);
    CGFloat centerY = CGRectGetMidY(finalFrame);
    
    finalFrame.size.width *= scale;
    finalFrame.size.height *= scale;
    
    finalFrame.origin.x = centerX - finalFrame.size.width * scale;
    finalFrame.origin.y = centerY - finalFrame.size.height * scale;
    return finalFrame;
}

CG_INLINE CGRect CGRectScale(CGRect rect,CGFloat scale)
{
    CGRect scaledRect = rect;
    scaledRect.origin.x *= scale;
    scaledRect.origin.y *= scale;
    scaledRect.size.width *= scale;
    scaledRect.size.height *= scale;
    return scaledRect;
}

CG_INLINE CGPoint CGPointScale(CGPoint point,CGFloat scale)
{
    CGPoint scaledPoint = point;
    scaledPoint.x *= scale;
    scaledPoint.y *= scale;
    return scaledPoint;
}

CG_INLINE CGPoint CGPointTranslate(CGPoint point, CGFloat dx, CGFloat dy)
{
    CGPoint translatedPoint = point;
    translatedPoint.x += dx;
    translatedPoint.y += dy;
    return translatedPoint;
}

CG_INLINE CGSize CGSizeScale(CGSize size,CGFloat scale)
{
    CGSize scaledSize = size;
    scaledSize.width *= scale;
    scaledSize.height *= scale;
    return scaledSize;
}

CG_INLINE CGFloat angleBetweenPoints(const CGPoint p1, const CGPoint p2)
{
    CGPoint pnormal = CGPointMake(p1.x - p2.x, p1.y - p2.y);
    CGFloat bearingRadians = atan2f(pnormal.y, pnormal.x);
    CGFloat bearingDegrees = bearingRadians * (180. / M_PI);
    return bearingDegrees;
}

CG_INLINE UIEdgeInsets UIEdgeInsetsScale(UIEdgeInsets inset,CGFloat scale)
{
    UIEdgeInsets scaledInset = inset;
    scaledInset.top *= scale;
    scaledInset.left *= scale;
    scaledInset.bottom *= scale;
    scaledInset.right *= scale;
    return scaledInset;

}

typedef struct {
    float Position[2];
    float uThickness;
    float Opacity;
#if USE_TEST_COLOR_FOR_STROKE
    float testColor[4];
#endif
} Vertex;


#define SMART_PEN_MAX_TIME_INTERVAL 0.4
#define SMART_PEN_MAX_DISTANCE 100
#define WRIST_PROTECTION_STROKE_MAX_SIZE 100

#define TEXT_ANNOTATION_HEIGHT 136
#define TEXT_ANNOTATION_MIN_WIDTH 150

extern NSString * const FTValidateToolBarNotificationName;
extern NSString * const FTToggleToolbarModeNotificationName;
extern NSString * const FTDismissToolBarAccessoryNotificationName;

extern NSString *const FTZoomRenderViewDidCancelledTouches;
extern NSString *const FTPDFDisableGestures;
extern NSString *const FTZoomRenderViewDidBeginTouches;
extern NSString *const FTEnteringEditModeNotification;
extern NSString *const FTPDFEnableGestures;
extern NSString *const FTZoomRenderViewDidEndTouches;

//ZoomPanel constants
typedef enum : NSInteger{
	kZoomPanelLeftSide	= 0,
	kZoomPanelRightSide = 1,
	kZoomPanelTopSide	= 2,
	kZoomPanelBottomSide= 3
}RKZoomPanelSide;

typedef enum : NSInteger {
    FTRenderModeDefault=0,
    FTRenderModeZoom=1,
    FTRenderModeExternalScreen=2,
} FTRenderMode;

typedef enum : NSInteger{
    kAccessoryButtonActionNone      = 0,
    kAccessoryButtonActionUndo      = 1,
    kAccessoryButtonActionRedo      = 2,
    kAccessoryButtonActionNextColor = 3,
    kAccessoryButtonActionPrevColor = 4,
    kAccessoryButtonActionNextPage  = 5,
    kAccessoryButtonActionPrevPage  = 6
}RKAccessoryButtonAction;

typedef enum : NSInteger {
    kStylusFinger   = 0,
    kStylusApplePencil = 6,
} StylusType;

#ifdef DEBUG
#define EVERNOTE_LOG NSLog
#else
#define EVERNOTE_LOG(s,...)
#endif

#define EVERNOTE_CONSUMER_KEY @"noteshelf3-3461"

/*
#define EVERNOTE_NOTE_TEMPLATE  @"<?xml version=\"1.0\" encoding=\"UTF-8\"?><!DOCTYPE en-note SYSTEM \"http://xml.evernote.com/pub/enml2.dtd\"> %@"
 */

#define EVERNOTE_NOTE_TEMPLATE @"%@"


#define EVERNOTE_NOTESHELF_CONTENT_CLASS @"com.ramki.noteshelf.notebook"

#if DEBUG
#undef CLS_LOG
#define CLS_LOG(s,...)
#endif

#define FTAudioPlayerControllerDidChangeAnnotationNotification  @"FTAudioPlayerControllerDidChangeAnnotationNotification"
#define FTAudioPlayerControllerDidCloseNotification  @"FTAudioPlayerControllerDidClose"
#define FTAudioPlayerControllerDidOpenNotification  @"FTAudioPlayerControllerDidOpenNotification"

CG_EXTERN NSString *const FTExternalDisplayDidConnectedNotification;
CG_EXTERN NSString *const FTRefreshExternalViewNotification;
CG_EXTERN NSString *const FTRefreshRectKey;
CG_EXTERN NSString *const FTRefreshWindowKey;
CG_EXTERN NSString *const FTRefreshPageIDKey;

CG_EXTERN NSString *const FTZoomRenderViewDidEndCurrentStrokeNotification;
CG_EXTERN NSString *const FTImpactedRectKey;

CG_EXTERN NSString *const FTPageDidChangePageTemplateNotification;

CG_EXTERN NSString *const FTWillPerformUndoRedoActionNotification;
CG_EXTERN NSString *const FTDidChangeWhiteBoardScreenValueNotification;

CG_EXTERN NSString *const FTWHITEBOARD_ENABLE_KEY;

#define FTAudioPlayerControllerDidExpand    @"FTAudioPlayerControllerDidExpandNotification"
#define FTAudioPlayerControllerDidCollapse  @"FTAudioPlayerControllerDidCollapseNotification"

CG_EXTERN NSString *const FTShelfThemeDidChangeNotification;
CG_EXTERN NSString *const CURRENT_SHELF_THEME_GUID_KEY;

#define APPLE_PENCIL_ENABLED @"APPLE_PENCIL_ENABLED"
#define APPLE_PENCIL_MESSAGE_DISPLAYED @"APPLE_PENCIL_MESSAGE_DISPLAYED"

#define SELECTED_STYLUS @"SELECTED_STYLUS"

typedef enum : NSUInteger {
    FTSettingsModeShelf = 1 << 0,
    FTSettingsModeDesk = 1 << 1,
    FTSettingsModeEvernoteError = 1 << 2,
    FTSettingsModeDropboxError = 1 << 3,
    FTSettingsModeAutoBackupSetup = 1 << 4,
    FTSettingsModeLanguageSettings = 1 << 5
}FTSettingsMode;

//Export
#define PDF_SCALE_FACTOR 0.84

//ExportTargets
#define PersistenceKey_ExportTarget_Dropbox @"Export_Dropbox"
#define PersistenceKey_ExportTarget_Evernote @"Export_Evernote"
#define PersistenceKey_ExportTarget_GoogleDrive @"Export_GoogleDrive"
#define PersistenceKey_ExportTarget_OneDrive @"Export_OneDrive"
#define PersistenceKey_ExportTarget_Box @"Export_Box"
#define PersistenceKey_ExportTarget_iTunes @"Export_iTunes"

#define PersistenceKey_ExportTarget_FolderID_Dropbox @"DROPBOX_EXPORT_FOLDER_ID"
#define PersistenceKey_ExportTarget_FolderID_Evernote @"EVERNOTE_EXPORT_FOLDER_ID"
#define PersistenceKey_ExportTarget_FolderID_GoogleDrive @"GDRIVE_EXPORT_FOLDER_ID"
#define PersistenceKey_ExportTarget_FolderID_OneDrive @"ONEDRIVE_EXPORT_FOLDER_ID"
#define PersistenceKey_ExportTarget_FolderID_Box @"BOX_EXPORT_FOLDER_ID"
#define PersistenceKey_ExportTarget_FolderID_iTunes @"ITUNES_EXPORT_FOLDER_ID"

#define Notification_ExportComplete @"Notification_ExportComplete"

@protocol FTDocumentClosing <NSObject>

-(void)startClosingProcessAndNotify:(void(^)(BOOL success))completionBlock;

@end


#define WelcomeScreenViewed @"WELCOME_SCREEN_VIEWED"
#define WelcomeScreenReminderTime @"WELCOME_SCREEN_REMINDER_TIME"
#define WhatsNewReminderTime @"WHATS_NEW_REMINDER_TIME"

CG_EXTERN float roundOf2Digits(float value);

#endif

typedef enum {
    FTInsertImageSourcePhotos,
    FTInsertImageSourceCamera,
    FTInsertImageSourceClipart,
    FTInsertImageSourceDrop,
    FTInsertImageSourceInsertFrom,
    FTInsertImageSourceUnSplash,
    FTInsertImageSourceSticker
} FTInsertImageSource;
