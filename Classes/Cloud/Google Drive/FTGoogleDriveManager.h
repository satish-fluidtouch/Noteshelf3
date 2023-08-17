//
//  FTGoogleDriveManager.h
//  Noteshelf
//
//  Created by Amar Udupa on 18/12/13.
//
//
#if !TARGET_OS_MACCATALYST

#import <Foundation/Foundation.h>

@import GoogleAPIClientForREST;

CG_EXTERN NSString *const FTGoogleDriveRootFolderId;
CG_EXTERN NSString *const FTGoogleDriveFolderMimeType;
CG_EXTERN NSString *const FTGoogleDriveImageMimeType;
CG_EXTERN NSString *const FTGoogleDrivePDFMimeType;

@class GTLRDrive_File,GTLService;

typedef void (^FTGoogleDriveUpdateCallback)(CGFloat percentage);
typedef void (^FTGoogleDriveFailureCallback)(NSError *error);
typedef void (^FTGoogleDriveSuccessCallback)(NSString *fileLocation);

typedef void (^FTGoogleDriveFileSuccessCallback)(GTLRDrive_File *updatedFile);
typedef void (^FTGoogleDriveFileFailureCallback)(NSError *error);


typedef void (^FTGoogleDriveAuthenticationCallBack)(BOOL success,NSError *error,BOOL isCancelled);

@interface FTGoogleDriveManager : NSObject

@property (weak, readonly) GTLRDriveService *driveService;
@property (assign) BOOL isAuthorized;

+ (instancetype)sharedGoogleDriveManager;

#pragma mark UI
-(void)loadDriveFilesWithFileID:(NSString*)fileID onCompletion:(void (^)(GTLRDrive_File *file,NSArray *fileList, NSError *error,BOOL completed))handler; //pass nil for root

#pragma makr Login/signout

-(void)signoutFromGoogleAccount;
-(void)loginToGoogleAccountOnViewController:(UIViewController*)viewController completionHandler:(FTGoogleDriveAuthenticationCallBack)completionHandler;

#pragma mark Upload/create folder

-(void)createFolderUnderGoogleDriveFile:(NSString*)parentIdentifier
                                  title:(NSString*)title
                      completionHandler:(void(^)(GTLRDrive_File *folder,NSError *error))handler;

-(void)uploadFileWithName:(NSString*)title
                 mimeType:(NSString*)mimeType
                 toFolder:(NSString*)folderIdentifier
                 filePath:(NSString*)filePath
                onSuccess:(void(^)(BOOL success,GTLRDrive_File *updatedFile))successHandler
                onFailure:(void(^)(NSError *error))failureHandler
           updateProgress:(void(^)(CGFloat percentage,GTLRServiceTicket *ticket))progessHandler;


@end
#endif
