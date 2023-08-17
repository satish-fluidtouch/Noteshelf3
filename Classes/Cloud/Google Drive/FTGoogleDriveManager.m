//
//  FTGoogleDriveManager.m
//  Noteshelf
//
//  Created by Amar Udupa on 18/12/13.
//
//
#if !TARGET_OS_MACCATALYST

#import "FTGoogleDriveManager.h"
#import "FTUtils.h"
#import "NavigationControllerForFormSheet.h"
#import "Noteshelf-Swift.h"

@import GTMSessionFetcher;
@import GoogleSignIn;
@import GoogleAPIClientForREST;

NSString *const FTGoogleDriveRootFolderId = @"root";
NSString *const FTGoogleDriveFolderMimeType = @"application/vnd.google-apps.folder";
NSString *const FTGoogleDriveImageMimeType = @"image/png";
NSString *const FTGoogleDrivePDFMimeType = @"application/pdf";
@interface FTGoogleDriveManager() <GIDSignInDelegate,GIDSignInUIDelegate>
@property (assign) BOOL shouldCancel;
@property (copy) FTGoogleDriveAuthenticationCallBack authCallBack;
@property (weak) UIViewController *loginScreenPresnetingViewController;
@end

@implementation FTGoogleDriveManager

@synthesize isAuthorized;
@synthesize shouldCancel;

+ (instancetype)sharedGoogleDriveManager
{
    static FTGoogleDriveManager *googleDriveManager = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        googleDriveManager = [[FTGoogleDriveManager alloc] init];
    });
    return googleDriveManager;
}

- (id)init
{
    self = [super init];
    if (self) {
        [GIDSignIn sharedInstance].delegate = self;
        [GIDSignIn sharedInstance].scopes = @[kGTLRAuthScopeDrive];
        if([[GIDSignIn sharedInstance] hasAuthInKeychain]) {
            [[GIDSignIn sharedInstance] signInSilently];
        }
    }
    return self;
}

#pragma mark GD setup
static GTLRDriveService *service = nil;
- (GTLRDriveService *)driveService
{
    if (!service) {
        service = [[GTLRDriveService alloc] init];
        service.authorizer = [[[[GIDSignIn sharedInstance] currentUser] authentication] fetcherAuthorizer];
        // Have the service object set tickets to fetch consecutive pages
        // of the feed so we do not need to manually fetch them.
        service.shouldFetchNextPages = YES;
        // Have the service object set tickets to retry temporary error conditions
        // automatically.
        service.retryEnabled = YES;
    }
    return service;
}

-(void)getFileInforID:(NSString*)fileID onCompletion:(void (^) (GTLRDrive_File *file,NSError *error,BOOL isTrashed))handler
{
    GTLRDriveQuery_FilesGet *query = nil;
    if(nil == fileID)
    {
        fileID = FTGoogleDriveRootFolderId;
    }
    query = [GTLRDriveQuery_FilesGet queryWithFileId:fileID];
    //query.q = @"trashed = false";
    [self.driveService executeQuery:query completionHandler:^(GTLRServiceTicket *ticket, id object, NSError *error) {
        if(error)
        {
            handler(nil,error,NO);
            return ;
        }
        GTLRDrive_File *file = object;
        BOOL isthrashed = true;
        if([file respondsToSelector:@selector(explicitlyTrashed)]) {
            isthrashed = file.explicitlyTrashed.boolValue;
        }
        handler(file,nil,isthrashed);
    }];
}

#pragma mark UI
-(void)loadDriveFilesWithFileID:(NSString*)fileID
                   onCompletion:(void (^)(GTLRDrive_File *file,NSArray *fileList, NSError *error,BOOL completed))handler
{
    if(nil == fileID)
    {
        fileID = FTGoogleDriveRootFolderId;
    }
    [self getFileInforID:fileID onCompletion:^(GTLRDrive_File *driveFile, NSError *error, BOOL isTrashed) {
        
        if(error)
        {
            handler(driveFile,nil,error,YES);
            return;
        }
        if(isTrashed)
        {
            NSError *trashError = [NSError errorWithDomain:@"GDError" code:404 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"FileIsDeleted",@"File is deleted")}];
            handler(driveFile,nil,trashError,YES);
            return;
        }
        
        GTLRDriveQuery_FilesList *query = nil;
        
        //TODO: Need to use nextPageToken to get subsequent pages
        query = [GTLRDriveQuery_FilesList query];
        query.fields = @"kind,nextPageToken,files(mimeType,id,kind,name,modifiedTime,size,fileExtension,parents)";
        query.q = [NSString stringWithFormat:@"('%@' IN parents) AND (explicitlyTrashed = false)", fileID];
        
        [self.driveService executeQuery:query completionHandler:^(GTLRServiceTicket *ticket, GTLRDrive_FileList *fileList, NSError *error) {
            if(error)
            {
                handler(driveFile,nil,error,YES);
                return ;
            }
            handler(driveFile,fileList.files,nil,YES);
        }];
        
    }];
}

#pragma mark login/signout
-(void)loginToGoogleAccountOnViewController:(UIViewController*)viewController
                          completionHandler:(FTGoogleDriveAuthenticationCallBack)completionHandler
{
    self.authCallBack = completionHandler;
    self.loginScreenPresnetingViewController = viewController;
    [GIDSignIn sharedInstance].uiDelegate = self;
    [[GIDSignIn sharedInstance] signIn];
}

-(void)signoutFromGoogleAccount
{
    [[GIDSignIn sharedInstance] signOut];
    service = nil;
    self.isAuthorized = NO;
}

#pragma mark download/ convert file
-(void)convertUsingGoogleDriveToPDF:(NSString*)filePath
                   onViewController:(UIViewController*)viewController
                         onProgress:(FTGoogleDriveUpdateCallback)updateHandler
                          onSuccess:(FTGoogleDriveSuccessCallback)successHandler
                          onFailure:(FTGoogleDriveFailureCallback)failureHandler

{
    if(!self.isAuthorized)
    {
        if([GIDSignIn sharedInstance].hasAuthInKeychain) {
            [self loginToGoogleAccountOnViewController:nil completionHandler:^(BOOL success, NSError *error, BOOL isCancelled) {
                if(nil == error) {
                    [self convertUsingGoogleDriveToPDF:filePath
                                      onViewController:viewController
                                            onProgress:updateHandler
                                             onSuccess:successHandler
                                             onFailure:failureHandler];
                }
                else {
                    failureHandler(error);
                }
            }];
            return;
        }
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"NeedGoogleDriveForConvertion", @"Login to google drive") message:@"" preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *action = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            if(failureHandler)
                failureHandler(nil);
        }];
        [alertController addAction:action];
        
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self loginToGoogleAccountOnViewController:viewController completionHandler:^(BOOL success, NSError *error, BOOL isCancelled) {
                if(success)
                {
                    [self convertUsingGoogleDriveToPDF:filePath
                                      onViewController:viewController
                                            onProgress:updateHandler
                                             onSuccess:successHandler
                                             onFailure:failureHandler];
                }
                else
                {
                    if(failureHandler)
                        failureHandler(error);
                }
            }];
        }];
        [alertController addAction:okAction];
        
        [viewController presentViewController:alertController animated:YES completion:nil];
        
        return;
    }

    [self uploadFileAtPath:filePath
                    update:^(CGFloat progress) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            CGFloat percentage = progress * 0.5;
                            updateHandler(percentage);
                        });
                    } completion:^(GTLRDrive_File *file, NSError *error) {
                        if(nil == error) {
                            if(self.shouldCancel)
                            {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    failureHandler(nil);
                                });
                                return;
                            }
                            [self downloadFile:file update:^(CGFloat progress) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    if(progress == -1) {
                                        updateHandler(0.5);
                                    }
                                    else {
                                        CGFloat percentage = (progress *0.5) + 0.5;
                                        updateHandler(percentage);
                                    }
                                });
                            } complationHandler:^(NSString *fileLoc, NSError *error) {
                                [self deleteFile:file onCompletion:nil];
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    if(nil == error) {
                                        successHandler(fileLoc);
                                    }
                                    else {
                                        failureHandler(error);
                                    }
                                });
                            }];
                        }
                        else {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                failureHandler(error);
                            });
                        }
                    }
     ];
}

#pragma mark Upload/create folder

-(void)createFolderUnderGoogleDriveFile:(NSString*)parentIdentifier
                                  title:(NSString*)title
                      completionHandler:(void(^)(GTLRDrive_File *folder,NSError *error))handler
{
    GTLRDrive_File *folderObj = [GTLRDrive_File object];
    
    if(parentIdentifier)
    {
        folderObj.parents = [NSArray arrayWithObject:parentIdentifier];
    }
    
    GTLRUploadParameters *uploadParameters = nil;
    folderObj.mimeType = @"application/vnd.google-apps.folder";
    folderObj.name = title;
    
    GTLRDriveQuery_FilesCreate *query = nil;
    query = [GTLRDriveQuery_FilesCreate queryWithObject:folderObj
                                       uploadParameters:uploadParameters];
    
    [self.driveService executeQuery:query completionHandler:^(GTLRServiceTicket *ticket,
                                                              GTLRDrive_File *updatedFile,
                                                              NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            handler(updatedFile,error);
        });
    }];
    
}

-(void)uploadFileWithName:(NSString*)title
                 mimeType:(NSString*)mimeType
                 toFolder:(NSString*)folderIdentifier
                 filePath:(NSString*)filePath
                onSuccess:(void(^)(BOOL success,GTLRDrive_File *updatedFile))successHandler
                onFailure:(void(^)(NSError *error))failureHandler
           updateProgress:(void(^)(CGFloat percentage,GTLRServiceTicket *ticket))progessHandler
{
    GTLRDrive_File *file = [[GTLRDrive_File alloc] init];
    file.mimeType = mimeType;
    file.name = title;
    
    if(folderIdentifier)
    {
        file.parents = [NSArray arrayWithObject:folderIdentifier];
    }
    
    GTLRDriveQuery_FilesCreate *query = nil;
    GTLRUploadParameters *uploadParameters = nil;
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:filePath];
    
    uploadParameters =  [GTLRUploadParameters uploadParametersWithFileHandle:fileHandle MIMEType:file.mimeType];
    query = [GTLRDriveQuery_FilesCreate queryWithObject:file uploadParameters:uploadParameters];
    
    GTLRServiceTicket *ticket = [self.driveService executeQuery:query completionHandler:^(GTLRServiceTicket *ticket, GTLRDrive_File *updatedFile, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if(error == nil)
            {
                successHandler(YES,updatedFile);
            }
            else
            {
                failureHandler(error);
            }
        });
    }];
    
    ticket.objectFetcher.sendProgressBlock = ^(int64_t bytesSent,
                                               int64_t totalBytesSent,
                                               int64_t totalBytesExpectedToSend) {
        if(self.shouldCancel)
        {
            [ticket cancelTicket];
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            CGFloat percentage = (CGFloat)totalBytesSent/(CGFloat)totalBytesExpectedToSend;
            percentage = percentage;
            progessHandler(percentage,ticket);
        });
    };
}

#pragma mark cancel
-(void)cancelImport:(id)sender
{
    self.shouldCancel = YES;
}

- (void)signIn:(GIDSignIn *)signIn
didSignInForUser:(GIDGoogleUser *)user
     withError:(NSError *)error
{
    if(error == nil) {
        self.isAuthorized = true;
    }
    
    if(self.authCallBack != nil) {
        self.authCallBack((error != nil) ? false : true,error,false);
        self.authCallBack = nil;
    }
}

#pragma mark -
#pragma mark Private Operations
#pragma mark -
-(void)convertFileInGoogleDriveToPDF:(GTLRDrive_File*)file
                          onProgress:(FTGoogleDriveUpdateCallback)updateHandler
                           onSuccess:(FTGoogleDriveSuccessCallback)successHandler
                           onFailure:(FTGoogleDriveFailureCallback)failureHandler
{
    self.shouldCancel = NO;
    
    [self getMimeType:file
         onCompletion:^(NSString * _Nullable mimeType, NSError * _Nullable error) {
             if(nil == error) {
                 [self copyFile:file
                       mimeType:mimeType
                  updateHandler:^(CGFloat progress) {
                      dispatch_async(dispatch_get_main_queue(), ^{
                          CGFloat percentage = progress*0.5;
                          updateHandler(percentage);
                      });
                      
                  } onCompletion:^(NSError * _Nullable error, GTLRDrive_File * _Nullable copiedFile) {
                      if(nil == error) {
                          if(self.shouldCancel) {
                              dispatch_async(dispatch_get_main_queue(), ^{
                                  failureHandler(error);
                              });
                              return ;
                          }
                          dispatch_async(dispatch_get_main_queue(), ^{
                              updateHandler(0.5);
                          });
                          
                          [self downloadFile:copiedFile
                                      update:^(CGFloat progress) {
                                          dispatch_async(dispatch_get_main_queue(), ^{
                                              if(progress == -1) {
                                                  updateHandler(0.5);
                                              }
                                              else {
                                                  CGFloat percentage = progress*0.5+0.5;
                                                  updateHandler(percentage);
                                              }
                                          });
                                      } complationHandler:^(NSString *fileLoc, NSError *error) {
                                          [self deleteFile:copiedFile onCompletion:nil];
                                          dispatch_async(dispatch_get_main_queue(), ^{
                                              if(error) {
                                                  failureHandler(error);
                                              }
                                              else {
                                                  successHandler(fileLoc);
                                              }
                                          });
                                      }];
                      }
                      else {
                          dispatch_async(dispatch_get_main_queue(), ^{
                              failureHandler(error);
                          });
                      }
                  }];
             }
             else {
                 dispatch_async(dispatch_get_main_queue(), ^{
                     failureHandler(error);
                 });
             }
         }];
}

#pragma mark -
#pragma mark Google Drive Operations
#pragma mark -
-(void)downloadFile:(GTLRDrive_File*)file
             update:(void(^)(CGFloat progress))updateHandler
  complationHandler:(void (^)(NSString *fileLoc,NSError *error))handler
{
    GTLRDriveQuery *query = nil;
    if([file.mimeType isEqualToString:@"application/pdf"]) {
        query = [GTLRDriveQuery_FilesGet queryForMediaWithFileId:file.identifier];
    }
    else {
        query = [GTLRDriveQuery_FilesExport queryForMediaWithFileId:file.identifier mimeType:@"application/pdf"];
    }
    NSMutableURLRequest *request = [self.driveService requestForQuery:query];
    GTMSessionFetcher *fetcher = [[self.driveService fetcherService] fetcherWithRequest:request];
    
    NSString *tempFileName = [file.name.stringByDeletingPathExtension stringByAppendingPathExtension:@"pdf"];
    NSString *tempFileLoc = [NSTemporaryDirectory() stringByAppendingPathComponent:tempFileName];
    [[[NSFileManager alloc] init] removeItemAtPath:tempFileLoc error:nil];
    
    __block GTMSessionFetcher *blkFetcher = fetcher;
    fetcher.downloadProgressBlock = ^(int64_t bytesWritten,
                                      int64_t totalBytesWritten,
                                      int64_t totalBytesExpectedToWrite)
    {
        if(self.shouldCancel)
        {
            handler(nil,nil);
            [blkFetcher stopFetching];
            return;
        }
        if(file.size == nil) {
            updateHandler(-1);
        }
        else {
            CGFloat percentage = (CGFloat)totalBytesWritten/file.size.floatValue;
            updateHandler(percentage);
        }
    };
    
    fetcher.destinationFileURL = [NSURL fileURLWithPath:tempFileLoc];
    [fetcher beginFetchWithCompletionHandler:^(NSData *data, NSError *error) {
        handler(tempFileLoc,error);
    }];
}

-(void)uploadFileAtPath:(NSString*)filePath
                 update:(void(^)(CGFloat))updateHandler
             completion:(void(^)(GTLRDrive_File *file,NSError *error))completionHandler
{
    GTLRDrive_File *file = [[GTLRDrive_File alloc] init];
    file.name = filePath.lastPathComponent;
    file.mimeType = MIMETypeFileAtPath(filePath);
    
    [self getMimeType:file onCompletion:^(NSString * _Nullable mimeType, NSError * _Nullable error) {
        if(nil == error) {
            file.mimeType = mimeType;
            NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:filePath];
            GTLRUploadParameters *uploadParameters =  [GTLRUploadParameters uploadParametersWithFileHandle:fileHandle MIMEType:mimeType];
            GTLRDriveQuery *query = [GTLRDriveQuery_FilesCreate queryWithObject:file uploadParameters:uploadParameters];
            self.shouldCancel = NO;
            GTLRServiceTicket *ticket = [self.driveService executeQuery:query
                                                      completionHandler:^(GTLRServiceTicket * _Nonnull callbackTicket, GTLRDrive_File * _Nullable object, NSError * _Nullable callbackError)
                                         {
                                             completionHandler(object,callbackError);
                                         }];
            
            ticket.objectFetcher.sendProgressBlock = ^(int64_t bytesSent,
                                                       int64_t totalBytesSent,
                                                       int64_t totalBytesExpectedToSend) {
                if(self.shouldCancel)
                {
                    [ticket cancelTicket];
                    return;
                }
                
                CGFloat percentage = (CGFloat)totalBytesSent/(CGFloat)totalBytesExpectedToSend;
                percentage = percentage;
                updateHandler(percentage);
            };
        }
        else {
            completionHandler(nil,error);
        }
    }];
}

-(void)getMimeType:(GTLRDrive_File*)file
      onCompletion:(void(^)(NSString * __nullable mimeType,NSError *__nullable error))completionHandler
{
    GTLRDriveQuery_AboutGet *query2 = [GTLRDriveQuery_AboutGet query];
    query2.fields =  @"importFormats,exportFormats";
    [self.driveService executeQuery:query2 completionHandler:^(GTLRServiceTicket *ticket, GTLRDrive_About *someObject, NSError *error) {
        NSString *mimeType = nil;
        if(nil == error) {
            mimeType = [[someObject.importFormats.JSON objectForKey:file.mimeType] lastObject];
        }
        completionHandler(mimeType,error);
    }];
}

-(void)copyFile:(GTLRDrive_File*)file
       mimeType:(NSString*)mimeType
  updateHandler:(void(^)(CGFloat progress))updateHandler
   onCompletion:(void(^)(NSError * __nullable error, GTLRDrive_File * __nullable copiedFile))handler
{
    GTLRDrive_File *emptyFile = [[GTLRDrive_File alloc] init];
    GTLRDriveQuery_FilesCopy *query = [GTLRDriveQuery_FilesCopy queryWithObject:emptyFile fileId:file.identifier];
    
    emptyFile.mimeType = mimeType;
    __block GTLRServiceTicket *ticket = [self.driveService executeQuery:query completionHandler:^(GTLRServiceTicket *ticket, GTLRDrive_File *updatedFile, NSError *error) {
        handler(error,updatedFile);
    }];
    
    ticket.objectFetcher.sendProgressBlock = ^(int64_t bytesSent,
                                               int64_t totalBytesSent,
                                               int64_t totalBytesExpectedToSend) {
        if(self.shouldCancel)
        {
            [ticket cancelTicket];
            return;
        }
        
        CGFloat percentage = (CGFloat)totalBytesSent/(CGFloat)totalBytesExpectedToSend;
        percentage = percentage;
        updateHandler(percentage);
    };
}

-(void)deleteFile:(GTLRDrive_File*)file onCompletion:(void(^)(NSError * __nullable error))handler
{
    GTLRDriveQuery_FilesDelete *deleteQuery = [GTLRDriveQuery_FilesDelete queryWithFileId:file.identifier];
    [self.driveService executeQuery:deleteQuery completionHandler:^(GTLRServiceTicket *ticket,
                                                                    id object,
                                                                    NSError *error) {
        if(handler) {
            handler(error);
        }
    }];
}

#pragma mark GIDSignInUIDelegate
- (void)signIn:(GIDSignIn *)signIn presentViewController:(UIViewController *)viewController
{
    viewController.modalPresentationStyle = UIModalPresentationOverFullScreen;
    UIViewController *presentFromController = self.loginScreenPresnetingViewController;
    if(presentFromController == nil) {
        FTLogError(@"GIDSignIn: Presenting Controller is Nil", nil);
        presentFromController = [[[UIApplication sharedApplication] keyWindow] visibleViewController];
    }
    [presentFromController presentViewController:viewController animated:true completion:nil];
}
@end
#endif
