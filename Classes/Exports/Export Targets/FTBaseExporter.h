//
//  FTBaseExporter.h
//  Noteshelf
//
//  Created by Amar Udupa on 1/4/13.
//
//

#import <Foundation/Foundation.h>

CG_EXTERN NSString *const FTCloudRootFolder;

@class FTBaseExporter;

typedef void (^FolderSearchCompletionHandler)(id folderObject, BOOL success);
typedef void (^FolderCheckCompletionHandler)(id folderObject, BOOL isAvailable, BOOL shouldCreateOne);

@protocol FTExporterDelegate <NSObject>

-(void)didEndExportWithMessage:(NSString*)message;
-(void)didFailExportWithError:(NSError*)error withMessage:(NSString*)message;
-(void)didCancelExport;

@end

@interface FTBaseExporter : NSObject

@property (strong) NSArray *exportItems;
@property (weak) id<FTExporterDelegate> delegate;
@property (assign) RKExportFormat exportFormat;
@property (weak) UIViewController *baseViewController;
@property (weak) UIView *targetShareButton;

@property (strong) NSString *exportFilename;

@property (strong) id exportToID;

@property (strong) NSProgress *progress;

@property (copy) FolderSearchCompletionHandler folderSearchCompletionHandler;
@property (copy) FolderCheckCompletionHandler folderCheckCompletionHandler;

-(id)initWithDelegate:(id<FTExporterDelegate>)delegate;
-(void)export;
-(NSString*)name;
    
@end
