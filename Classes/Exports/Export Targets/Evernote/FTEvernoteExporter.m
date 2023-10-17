//
//  FTEvernoteExporter.m
//  Noteshelf
//
//  Created by Amar Udupa on 1/4/13.
//
//

#import "FTEvernoteExporter.h"
#import "DataServices.h"
#import "FTExportItem.h"

#import "Noteshelf-Swift.h"

@interface FTEvernoteExporter() <FTExporterDelegate>

@property (assign) NSInteger currentIndex;
#if !TARGET_OS_MACCATALYST
@property (nonatomic, strong) EDAMNotebook* evernoteNotebook;
@property (nonatomic, strong) EDAMNote* evernoteNote;
#endif

@property (strong) FTBaseExporter *currentExporter;
@property (assign) BOOL isChildExporter;

@end

@implementation FTEvernoteExporter

@synthesize currentIndex;
@synthesize delegate;
@synthesize exportFormat;
@synthesize exportItems;
#if !TARGET_OS_MACCATALYST
@synthesize evernoteNotebook;
@synthesize evernoteNote;
#endif
@synthesize exportFilename;

- (id)init
{
    self = [super init];
    if (self) {
        currentIndex = 0;
    }
    return self;
}

- (void)showExportError:(NSError *)error {
    NSString *exportMessage = NSLocalizedString(@"EvernoteUploadFailed", @"Unexpected error. Upload to Evernote failed");
    [self.delegate didFailExportWithError:error withMessage:exportMessage];
}

-(void)export
{
    self.progress.totalUnitCount = self.exportItems.count;
    NSString *exportMessage = NSLocalizedString(@"Exporting", @"Exporting...");
    self.progress.localizedDescription = exportMessage;

    if(self.exportToID == nil) {
        self.progress.totalUnitCount += 1;
        [self fetchFolderObjectWithCompletionHandler:^(id folderObject, BOOL success) {
            self.progress.completedUnitCount += 1;
            if(success) {
                self.exportToID = folderObject;
                [self startExportingCurrentItem];
            }
            else {
                [self showExportError:nil];
            }
        }];
    }
    else {
        [self startExportingCurrentItem];
    }
}

- (void)startExportingCurrentItem {
    
    if(!self.isChildExporter) {
        if(self.currentIndex >= self.exportItems.count) {
            [self.delegate didEndExportWithMessage:NSLocalizedString(@"ExportComplete",@"Export Complete!")];
            return;
        }
        
        if(self.progress.isCancelled) {
            [self.delegate didCancelExport];
            return;
        }
        
        [self runUploadOperationForCurrentItem];
        return;
    }
    #if !TARGET_OS_MACCATALYST
    self.evernoteNotebook = self.exportToID;
    #endif
    [self uploadToEvernote];
}

-(void)uploadToEvernote
{
    //Kick the export process
	if (self.exportFormat == kExportFormatPDF)
    {
        NSString *exportMessage = NSLocalizedString(@"UploadingToCloud", @"Uploading to %@");
        exportMessage = [NSString stringWithFormat:exportMessage,self.name];
        self.progress.localizedDescription = exportMessage;
        
		[self performSelector:@selector(uploadPDFToEvernote) withObject:nil afterDelay:0.001];
	}
    else if (self.exportFormat == kExportFormatImage)
    {
        NSString *exportMessage = [NSString stringWithFormat:NSLocalizedString(@"UploadingPageNToEvernote", @"Uploading page %d of %d to Evernote"), self.currentIndex+1, [self.exportItems count]];
        self.progress.localizedDescription = exportMessage;

        self.currentIndex = 0;
        [self performSelector:@selector(startUploadingImagesToEvernote) withObject:nil afterDelay:0.001];
	}
}

-(void)uploadPDFToEvernote{
    if(self.progress.isCancelled)
    {
        [self.delegate didCancelExport];
        return;
    }

	//Check if PDF is less than 25MB and fail if so
    FTExportItem *item = [self.exportItems objectAtIndex:self.currentIndex];
    NSFileManager *man = [NSFileManager defaultManager];
    
	NSDictionary *attrs = [man attributesOfItemAtPath:item.representedObject error: NULL];
	unsigned long long fileSize = [attrs fileSize];
    
	if (fileSize > 25000000) {
		//Show error message and conclude export
        NSString *exportMessage = NSLocalizedString(@"EvernotePDFSizeError", @"Upload failed. PDF too big for Evernote.");
        [self.delegate didFailExportWithError:nil withMessage:exportMessage];
		return;
	}
	#if !TARGET_OS_MACCATALYST
	EDAMNote *note = [[EDAMNote alloc] init];
	[note setNotebookGuid:[evernoteNotebook guid]];
	[note setTitle:[item.exportFileName stringByDeletingPathExtension]];
	
	//PDF Data Init
	NSData *pdfRawData = [NSData dataWithContentsOfFile:item.representedObject];
	EDAMResource *pdfResource = [[EDAMResource alloc] init];
    EDAMData *pdfData = [[EDAMData alloc] init];
    pdfData.bodyHash = [pdfRawData md5Hash];
    pdfData.size =[NSNumber numberWithInteger:[pdfRawData length]];
    pdfData.body = pdfRawData;
    
    [pdfResource setData:pdfData];
	[pdfResource setMime:@"application/pdf"];
	NSMutableArray *pdfArray = [[NSMutableArray alloc] initWithObjects:pdfResource, nil];
	[note setResources:pdfArray];
	
	NSMutableString* contentString = [[NSMutableString alloc] init];
	[contentString setString:	@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>"];
	[contentString appendString:@"<!DOCTYPE en-note SYSTEM \"http://xml.evernote.com/pub/enml.dtd\">"];
	[contentString appendString:@"			<en-note>"];
	[contentString appendString:@"<en-media type=\"application/pdf\" hash=\""];
	[contentString appendString:[pdfRawData md5HexHash]];
	[contentString appendString:@"\"/>"];
    NSString *publishByString = [NSString stringWithFormat:NSLocalizedString(@"PublishedByNoteshelf", @"Published by Noteshelf"),@"Noteshelf"];
	[contentString appendFormat:@"<br/>%@</en-note>",publishByString];
	[note setContent:contentString];
	[note setCreated:[NSNumber numberWithLongLong:[[NSDate date] timeIntervalSince1970] * 1000]];
	
    //Set tags
    note.tagNames = [[item.tags allObjects] mutableCopy];
    
    EDAMNoteStoreClient *noteStore = [EvernoteSession sharedSession].primaryNoteStore;
    
    [noteStore createNote:note completion:^(EDAMNote * _Nullable note, NSError * _Nullable error) {
        if (nil != error) {
            NSString *exportMessage = NSLocalizedString(@"EvernoteUploadFailed", @"Unexpected error. Upload to Evernote failed");
            
            [self.delegate didFailExportWithError:error withMessage:exportMessage];
        } else {
            self.progress.completedUnitCount += 1;
            [self.delegate didEndExportWithMessage:NSLocalizedString(@"ExportComplete",@"Export Complete!")];
        }
    }];
    #endif
}

-(void)startUploadingImagesToEvernote
{
    FTExportItem *item = [self.exportItems objectAtIndex:self.currentIndex];

    if(item.childItems.count == 0)
    {
        #if !TARGET_OS_MACCATALYST
        self.evernoteNote=nil;
        EDAMNote *note = [[EDAMNote alloc] init];
        [note setNotebookGuid:[evernoteNotebook guid]];
        NSString *title = self.exportFilename;
        if(!title)
        {
            title = [item.exportFileName stringByDeletingPathExtension];
        }
        [note setTitle:title];
        [note setCreated:[NSNumber numberWithLongLong:[[NSDate date] timeIntervalSince1970] * 1000]];
        note.content = @"<?xml version=\"1.0\" encoding=\"UTF-8\"?><!DOCTYPE en-note SYSTEM \"http://xml.evernote.com/pub/enml2.dtd\"><en-note></en-note>";
        
        [[EvernoteSession sharedSession].primaryNoteStore createNote:note completion:^(EDAMNote * _Nullable note, NSError * _Nullable error) {
            if (nil != error) {
                NSString *exportMessage = NSLocalizedString(@"EvernoteUploadFailed", @"Unexpected error. Upload to Evernote failed");
                
                [self.delegate didFailExportWithError:error withMessage:exportMessage];
            }
            else {
                self.progress.completedUnitCount += 1;
                self.evernoteNote = note;
                [self performSelector:@selector(uploadCurrentPageImageToEvernote) withObject:nil afterDelay:0.001];
            }
        }];
        #endif
    }
}

-(void)uploadCurrentPageImageToEvernote{
    
    if(self.currentIndex >= self.exportItems.count) {
        [self.delegate didEndExportWithMessage:NSLocalizedString(@"ExportComplete",@"Export Complete!")];
        return;
    }

    if(self.progress.isCancelled)
    {
        [self.delegate didCancelExport];
        return;
    }
    
    NSString *exportMessage = [NSString stringWithFormat:NSLocalizedString(@"UploadingPageNToEvernote", @"Uploading page %d of %d to Evernote"), self.currentIndex+1, [self.exportItems count]];
    self.progress.localizedDescription = exportMessage;

    FTExportItem *item = [self.exportItems objectAtIndex:self.currentIndex];
    #if !TARGET_OS_MACCATALYST
    NSData *imageRawData = [NSData dataWithContentsOfFile:item.representedObject];
    EDAMResource *imageResource = [[EDAMResource alloc] init];
    EDAMData *imageData = [[EDAMData alloc] init];
    imageData.bodyHash = [imageRawData md5Hash];
    imageData.size = [NSNumber numberWithInteger:[imageRawData length]];
    imageData.body = imageRawData;
    
    [imageResource setData:imageData];
    [imageResource setRecognition:imageData];
    [imageResource setMime:@"image/png"];
    UIImage *image=[UIImage imageWithData:imageRawData];
    imageResource.width = [NSNumber numberWithShort:image.size.width];
    imageResource.height = [NSNumber numberWithShort:image.size.height];
    
    NSMutableArray *imageArray = self.evernoteNote.resources? [NSMutableArray arrayWithArray:self.evernoteNote.resources]:[NSMutableArray array];
    [imageArray addObject:imageResource];
    [self.evernoteNote setResources:imageArray];
    NSString *enml = [FTENSyncUtilities enmlRepresentationWithResources:imageArray];
    [self.evernoteNote setContent:[[NSString alloc] initWithFormat:EVERNOTE_NOTE_TEMPLATE,enml]];
    [self.evernoteNote setUpdated:[NSNumber numberWithLongLong:[[NSDate date] timeIntervalSince1970] * 1000]];
    EDAMNoteStoreClient *noteStore = [EvernoteSession sharedSession].primaryNoteStore;
    
    ////////////////////////////////////////
    //Publish tags to Evernote
    ////////////////////////////////////////
    NSSet *tempSet = [item.tags setByAddingObjectsFromArray:self.evernoteNote.tagNames];
    [self.evernoteNote setTagNames:tempSet.allObjects.mutableCopy];

    ////////////////////////////////////////
    [noteStore updateNote:self.evernoteNote completion:^(EDAMNote * _Nullable note, NSError * _Nullable error) {
        if(nil != error) {
            NSString *exportMessage = NSLocalizedString(@"EvernoteUploadFailed", @"Unexpected error. Upload to Evernote failed");
            //Show error message and conclude export
            [self.delegate didFailExportWithError:error withMessage:exportMessage];
            
        }
        else {
            self.currentIndex++;
            self.progress.completedUnitCount += 1;
            [self performSelector:@selector(uploadCurrentPageImageToEvernote) withObject:nil afterDelay:0.001];
        }
    }];
    #endif
}

-(NSString*)name
{
    return @"Evernote";
}

-(void)runUploadOperationForCurrentItem
{
    FTExportItem *item = [self.exportItems objectAtIndex:self.currentIndex];
    FTEvernoteExporter *exporter = [[FTEvernoteExporter alloc] initWithDelegate:self];

    exporter.exportItems = [NSArray arrayWithObject:item];
    if(item.childItems.count > 0) {
        exporter.exportItems = item.childItems;
    }
    
    exporter.exportToID  = self.exportToID;
    exporter.exportFormat = self.exportFormat;
    exporter.exportFilename = item.exportFileName;
    exporter.isChildExporter = true;
    self.currentExporter = exporter;
   
    NSString *exportMessage = NSLocalizedString(@"Exporting", @"Exporting...");
    NSString *ratio = [NSString stringWithFormat:NSLocalizedString(@"NofNAlt", @"%d of %d"),self.currentIndex+1,[self.exportItems count]];
    if(self.exportItems.count > 1) {
        exportMessage = [NSString stringWithFormat:@"%@\n%@",exportMessage,ratio];
    }
    self.progress.localizedDescription = exportMessage;
    [self.progress addChild:self.currentExporter.progress withPendingUnitCount:1];

    [exporter export];
}

#pragma mark - FTExportDelegate -
-(void)didEndExportWithMessage:(NSString*)message
{
    self.currentExporter = nil;
    self.currentIndex++;
    [self startExportingCurrentItem];
}

-(void)didFailExportWithError:(NSError*)error withMessage:(NSString*)message
{
    self.currentExporter = nil;
    [self.delegate didFailExportWithError:error withMessage:message];
}

-(void)didCancelExport
{
    self.currentExporter = nil;
    [self.delegate didCancelExport];
}

@end
