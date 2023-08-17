//
//  FTExportHandler.m
//  Noteshelf
//
//  Created by Amar Udupa on 1/4/13.
//
//

#import "FTExportHandler.h"
#import "FTDropboxExporter.h"
#import "FTEvernoteExporter.h"
#import "FTMailExporter.h"
#import "FTiTunesExporter.h"
#import "FTPhotoAlbumExporter.h"
#import "FTPrintExporter.h"
#import "DataServices.h"
#import "FTGoogleDriveExporter.h"
#import "FTOneDriveExporter.h"
#import "FTBoxExporter.h"

#import "Noteshelf-Swift.h"

@interface FTExportHandler()

@property(strong) FTBaseExporter *currentExporter;

@end

@implementation FTExportHandler

@synthesize exportItems = _exportItems;
@synthesize delegate = _delegate;
@synthesize baseViewController;
@synthesize currentExporter;
@synthesize barButton;

@synthesize uploadToFolderId;
@synthesize exportFilename;
@synthesize includePageFooter;
@synthesize includePageLayout;
@synthesize exportMode;
@synthesize exportFormat;
@synthesize selectedPageNumbersSet;

-(id)initWithDelegate:(id<FTExportHandlerDelegate>)delegate
           exportMode:(RKExportMode)mode
         exportFormat:(RKExportFormat)inExportFormat
{
    self = [super init];
    if(self)
    {
        self.delegate = delegate;
        self.exportFormat = inExportFormat;
        self.exportMode = mode;
    }
    return self;
}

-(NSProgress*)export
{
    switch (self.exportMode) {
        case kExportModeEmail:
        {
            self.currentExporter = [[FTMailExporter alloc] initWithDelegate:self];
        }
            break;
        case kExportModeWeLink:
        {
            self.currentExporter = [[FTWeLinkExporter alloc] initWithDelegate:self];
        }
            break;
        case kExportModeiTunes:
        {
            self.currentExporter = [[FTiTunesExporter alloc] initWithDelegate:self];
            self.currentExporter.exportToID = self.uploadToFolderId;
        }
            break;
        case kExportModeDropbox:
        {
            self.currentExporter = [[FTDropboxExporter alloc] initWithDelegate:self];
            self.currentExporter.exportToID = self.uploadToFolderId;
        }
            break;
        case kExportModeEvernote:
        {
            self.currentExporter = [[FTEvernoteExporter alloc] initWithDelegate:self];
            [(FTEvernoteExporter*)self.currentExporter setIncludeTags:[FTUserDefaults exportIncludeEvernoteTags]];
            self.currentExporter.exportToID = self.uploadToFolderId;
            ((FTEvernoteExporter*)self.currentExporter).exportAsSingleNote = [[NSUserDefaults standardUserDefaults] boolForKey:EVERNOTE_EXPORT_AS_SINGLE_NOTE];
        }
            break;
        case kExportModePhotoAlbum:
        {
            self.currentExporter = [[FTPhotoAlbumExporter alloc] initWithDelegate:self];
        }
            break;
        case kExportModePrint:
        {
            self.currentExporter = [[FTPrintExporter alloc] initWithDelegate:self];
            [(FTPrintExporter*)self.currentExporter setBarButton:self.barButton];
        }
            break;
        case kExportModeBox:
        {
            FTBoxExporter *boxExporter  = [[FTBoxExporter alloc] initWithDelegate:self];
            boxExporter.boxExportFolder = self.uploadToFolderId;
            self.currentExporter = boxExporter;
        }
            break;
        case kExportModeGoogleDrive:
        {
            FTGoogleDriveExporter *gdExporter = [[FTGoogleDriveExporter alloc] initWithDelegate:self];
            gdExporter.googleDriveFileIdentifier = self.uploadToFolderId;
            self.currentExporter = gdExporter;
        }
            break;
        case kExportModeOneDrive:
        {
            FTOneDriveExporter *exporter = [[FTOneDriveExporter alloc] initWithDelegate:self];
            exporter.oneDriveFolderIdentifier = self.uploadToFolderId;
            self.currentExporter = exporter;
        }
            break;
        case kExportModeOpenIn:
        {
            FTOpenInExporter *exporter = [[FTOpenInExporter alloc] initWithDelegate:self];
            self.currentExporter = exporter;
            self.currentExporter.targetShareButton = self.targetShareButton;
        }
            break;
        case kExportModeFilesDrive:
        {
            FTFilesDriveExporter *exporter = [[FTFilesDriveExporter alloc] initWithDelegate:self];
            self.currentExporter = exporter;
        }
            break;
        case kExportModeFacebook:
        {
            FTFacebookExporter *exporter = [[FTFacebookExporter alloc] initWithDelegate:self];
            self.currentExporter = exporter;
        }
            break;
        case kExportModeTwitter:
        {
            FTTwitterExporter *exporter = [[FTTwitterExporter alloc] initWithDelegate:self];
            self.currentExporter = exporter;
        }
            break;
        case kExportModeSaveAsTemplate:
        {
            FTSaveAsTemplateExporter *exporter = [[FTSaveAsTemplateExporter alloc] initWithDelegate:self];
            self.currentExporter = exporter;
        }
            break;
        default:
            break;
    }
    self.currentExporter.exportItems = self.exportItems;
    self.currentExporter.exportFormat = self.exportFormat;
    self.currentExporter.baseViewController = self.baseViewController;
    self.currentExporter.exportFilename = exportFilename;
    self.uploadToFolderId = nil;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.currentExporter export];
    });
    return self.currentExporter.progress;
}

-(void)cancelExport:(id)sender
{

}

#pragma mark base exporter call back

-(void)didCancelExport
{
    if([self.delegate respondsToSelector:@selector(exportHandlerDidCancelExport:)]) {
        __weak FTExportHandler *weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.delegate exportHandlerDidCancelExport:weakSelf];
        });
    }
}

-(void)didEndExportWithMessage:(NSString*)message
{
    if([self.delegate respondsToSelector:@selector(exportHandlerDidEndExport:message:)]) {
        __weak FTExportHandler *weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.delegate exportHandlerDidEndExport:weakSelf message:message];
        });
    }
}

-(void)didFailExportWithError:(NSError*)error withMessage:(NSString*)message
{
    if([self.delegate respondsToSelector:@selector(exportHandler:didFailExportWithError:message:)]) {
        __weak FTExportHandler *weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.delegate exportHandler:weakSelf didFailExportWithError:error message:message];
        });
    }
}
@end
