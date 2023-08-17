//
//  FTGoogleDriveImportManager.m
//  Noteshelf
//
//  Created by Amar Udupa on 18/12/13.
//
//
#if !TARGET_OS_MACCATALYST

#import "FTGoogleDriveFolderPickerManager.h"
#import "FTGoogleDriveManager.h"
#import "NavigationControllerForFormSheet.h"
#import "FTUtils.h"
#import "FTFolderUICell.h"
#import "Noteshelf-Swift.h"

NSString *const GDRootItemID = @"My Drive";

@import GoogleAPIClientForREST;

@interface FTGoogleDriveFolderPickerManager()

@property (readonly) FTGoogleDriveManager *googleDriveManager;
@property (strong)  GTLRDrive_File *rootItem;
@property (copy) FTFolderPickerCallbackBlock completionCallBack;
@property (strong) NSString *pathFromRoot;

@end

@implementation FTGoogleDriveFolderPickerManager
{
    NSMutableArray *driveFileList;
}

@synthesize uiViewController;
@synthesize navController;
@synthesize rootItem;
@synthesize completionCallBack;

-(instancetype)initWithRootViewController:(UIViewController *)controller
{
    self = [super initWithRootViewController:controller];
    if(self)
    {
        
    }
    return self;
}

-(FTGoogleDriveManager*)googleDriveManager
{
    return [FTGoogleDriveManager sharedGoogleDriveManager];
}

-(void)showUIForMode:(FTViewMode)inViewMode parentPath:(id)path modalPresentationStyle:(UIModalPresentationStyle)presentationStyle onCompletion:(FTFolderPickerCallbackBlock)completionHandler
{
    self.viewMode = inViewMode;
    self.completionCallBack = completionHandler;
    
    if(self.googleDriveManager.isAuthorized)
    {
        if(navController)
        {
            [navController dismissViewControllerAnimated:NO completion:nil];
            navController = nil;
        }
        
        if(inViewMode == FTViewModeImport)
        {
            path = [[NSUserDefaults standardUserDefaults] objectForKey:@"GDRIVE_IMPORT_FOLDER_ID"];
        }
        else
        {
            path = [[NSUserDefaults standardUserDefaults] objectForKey:@"GDRIVE_EXPORT_FOLDER_ID"];
        }
        
        GTLRDrive_File *file = [[GTLRDrive_File alloc] init];
        if([path pathComponents].count <= 1) {
            file.identifier = FTGoogleDriveRootFolderId;
            file.name = GDRootItemID;
            self.pathFromRoot = file.identifier;
        }
        else {
            file.identifier = [[path pathComponents] lastObject];
            self.pathFromRoot = path;
        }
        
        __unused FTFolderPickerUIViewController *localController = [self pickerControllerForItem:file
                                                                                manager:self
                                                                 supportedButtonOptions:FTUIButtonActionOptionAll & ~FTUIButtonActionOptionSettings];
        self.navController = (NavigationControllerForFormSheet *)self.rootViewController.navigationController;
        self.navController.modalPresentationStyle = presentationStyle;

        [self.navController pushViewController:uiViewController animated:YES];
    }
    else
    {
        [self.googleDriveManager loginToGoogleAccountOnViewController:self.rootViewController completionHandler:^(BOOL success, NSError *error,BOOL isCancelled)
         {
             if(isCancelled)
             {
                 completionHandler(NO,nil);
                 return;
             }
             if(nil != error)
             {
                 completionHandler(NO,error);
                 UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"UnabletoAccessGoogleDrive",@"Unable to Access Google Drive") message:@"" preferredStyle:UIAlertControllerStyleAlert];
                 
                 UIAlertAction *action = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK",@"OK") style:UIAlertActionStyleCancel handler:nil];
                 [alertController addAction:action];
                 [self.uiViewController presentViewController:alertController animated:YES completion:nil];
             }
             else
             {
                 [self showUIForMode:self.viewMode
                          parentPath:nil
              modalPresentationStyle:presentationStyle
                        onCompletion:completionHandler];
             }
         }];
    }
}

-(void)showUIForMode:(FTViewMode)inViewMode
          parentPath:(id)path
        onCompletion:(FTFolderPickerCallbackBlock)completionHandler
{
    [self showUIForMode:inViewMode parentPath:path modalPresentationStyle:UIModalPresentationFormSheet onCompletion:completionHandler];
}

-(void)viewDidAppear
{
    if(self.loadingStatus == FTLoadStatusNone)
    {
        [self loadContentsAtPath:[self.rootItem identifier]];
    }
}

-(FTFolderPickerUIViewController*)pickerControllerForItem:(GTLRDrive_File*)file
                                                  manager:(FTGoogleDriveFolderPickerManager*)manager
                                   supportedButtonOptions:(FTUIButtonActionOption)supportedButtonOptions
{
    FTFolderPickerUIViewController *localController = [[FTFolderPickerUIViewController alloc] initWithUIViewMode:self.viewMode supportedActions:supportedButtonOptions];
    
    localController.delegate = manager;
    localController.allowsMultipleFileSelection = self.allowsMultipleFileSelection;

    manager.uiViewController = localController;
    manager.navController = self.navController;
    manager.rootItem = file;
    manager.viewMode = self.viewMode;
    manager.delegate = self.delegate;
    return localController;
}

-(void)pushViewWithViewMode:(FTViewMode)viewMode driveFile:(GTLRDrive_File*)file
{
    self.rootItem = file;
    self.pathFromRoot = [self.pathFromRoot stringByAppendingPathComponent:file.identifier];
    [self refreshTableContents:true];
}

#pragma mark
-(void)loadContentsAtPath:(NSString*)fileId
{
    [self.uiViewController setHidden:YES buttons:FTUIButtonActionOptionAllExceptCancel];
    [self.uiViewController showActivityIndicator:YES];
    self.loadingStatus = FTLoadStatusLoading;
    [self.googleDriveManager loadDriveFilesWithFileID:fileId onCompletion:^(GTLRDrive_File *file,NSArray *fileList, NSError *error,BOOL completed) {
        if(error == nil)
        {
            if(nil == driveFileList)
            {
                driveFileList = [NSMutableArray array];
            }
            else
            {
                [driveFileList removeAllObjects];
            }
            [driveFileList addObjectsFromArray:fileList];
            [self sortItemsAlphabetically];
        }
        else
        {
            driveFileList = nil;
            if([self hasParentItem] && error.code == 404)
            {
                if(self.viewMode == FTViewModeImport)
                {
                    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"GDRIVE_IMPORT_FOLDER_ID"];
                }
                else
                {
                    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"GDRIVE_EXPORT_FOLDER_ID"];
                }
                
                [[NSUserDefaults standardUserDefaults] synchronize];
                GTLRDrive_File *rootItem = [[GTLRDrive_File alloc] init];
                rootItem.identifier = FTGoogleDriveRootFolderId;
                rootItem.name = GDRootItemID;
                self.rootItem = rootItem;
                [self refreshTableContents:true];
                
                return;
            }
        }
        if(completed || error)
        {
            self.loadingStatus = FTLoadStatusLoaded;
            [self.uiViewController showActivityIndicator:NO];
            if(self.completionCallBack)
            {
                self.completionCallBack((nil == error)?YES:NO,error);
                self.completionCallBack = nil;
            }
            if(!error)
            {
                self.rootItem = file;
                [self updateNavTitle];
            }
        }
        [self.uiViewController reloadData];
        
        if(error)
        {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"UnabletoAccessGoogleDrive",@"Unable to Access Google Drive") message:@"" preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *action = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK",@"OK") style:UIAlertActionStyleCancel handler:nil];
            [alertController addAction:action];
            [self.uiViewController presentViewController:alertController animated:YES completion:nil];
        }
    }];
}

#pragma mark create folder
-(void)createFolder:(NSString *)folderName parentFolder:(NSString *)rootFolder onCompletion:(FTFolderPickerNewFolderCallbackBlock)callBack
{
    folderName = [self generateUniqueFolderName:folderName];
    [self.googleDriveManager createFolderUnderGoogleDriveFile:rootFolder title:folderName completionHandler:^(GTLRDrive_File *folder, NSError *error) {
        callBack(folder,folder.identifier,error);
    }];
}

#pragma mark delegate Methods
-(void)signOut:(id)sender
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"GDRIVE_IMPORT_FOLDER_ID"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"GDRIVE_EXPORT_FOLDER_ID"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self.googleDriveManager signoutFromGoogleAccount];
    if([self.delegate respondsToSelector:@selector(didDismissUI)])
        [self.delegate didDismissUI];
    [self.rootViewController dismissViewControllerAnimated:YES completion:nil];
}

-(void)createNewFolder:(id)sender
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"FolderName", @"Folder Name") message:@"" preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel",@"Cancel") style:UIAlertActionStyleCancel handler:nil];
    [alertController addAction:cancelAction];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK",@"OK") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action)
                               {
                                   NSString *folderName = [[alertController textFields].firstObject.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                                   if ([folderName isEqualToString:@""]) {
                                       return;
                                   }
                                   __unused FTLoadingIndicatorViewController *loadingController = [FTLoadingIndicatorViewController showOnMode:FTLoadingIndicatorStyleActivityIndicator from:self.uiViewController withText:NSLocalizedString(@"CreatingFolder",@"Creating New Folder") andDelay:0];
                                   
                                   [self createFolder:folderName parentFolder:self.rootItem.identifier onCompletion:^(id item, NSString *folderID, NSError *error) {
                                       [loadingController hide:nil];
                                       if(error) {
                                           [error showAlertFrom:self.uiViewController];
                                           return;
                                       }
                                       if(item) {
                                           [driveFileList addObject:item];
                                           [self sortItemsAlphabetically];
                                           [self.uiViewController reloadData];
                                           
                                           NSInteger section = [self hasParentItem] ? 1 : 0;

                                           NSInteger index = [driveFileList indexOfObject:item];
                                           [self.uiViewController.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:section] atScrollPosition:UITableViewScrollPositionBottom animated:NO];
                                       }
                                   }];
                               }];
    [alertController addAction:okAction];
    
    [alertController addTextFieldWithConfigurationHandler:nil];
    UITextField *textField = [alertController textFields].firstObject;
    [textField setStyledPlaceHolder:NSLocalizedString(@"FolderName", @"Folder Name") style:FTTextFieldPlaceHolderStyleDefaultStyle];

    [self.uiViewController presentViewController:alertController animated:YES completion:nil];
}

-(void)dismissUI:(id)sender
{
    self.uiViewController.delegate = nil;
    if([self.delegate respondsToSelector:@selector(didDismissUI)])
        [self.delegate didDismissUI];
    [self.rootViewController dismissViewControllerAnimated:YES completion:nil];
}

-(void)exportHere:(id)sender
{
    if([self.delegate respondsToSelector:@selector(exportToFolder:manager:)])
    {
        [[NSUserDefaults standardUserDefaults] setObject:self.pathFromRoot forKey:PersistenceKey_ExportTarget_FolderID_GoogleDrive];
        NSString *pathDisplayName = self.rootItem.name;
        if(![pathDisplayName isEqualToString:GDRootItemID]) {
            pathDisplayName = [GDRootItemID stringByAppendingPathComponent:pathDisplayName];
        }
        [[NSUserDefaults standardUserDefaults] setObject:pathDisplayName forKey:[NSString stringWithFormat:@"%@_FolderName", PersistenceKey_ExportTarget_GoogleDrive]];
        [[NSUserDefaults standardUserDefaults] synchronize];
       self.uiViewController.delegate = nil;

        NSArray *viewControllers = [(NavigationControllerForFormSheet *)self.rootViewController.navigationController viewControllers];
        for(UIViewController *controller in viewControllers){
            if([controller isKindOfClass:[FTExportSettingsViewController class]]){
                [(UINavigationController *)self.rootViewController.navigationController popToViewController:controller animated:YES];
                break;
            }
        }
        [self.delegate exportToFolder:self.rootItem.identifier manager:self];
    }
}

-(void)refreshContents:(id)sender
{
    [self refreshTableContents:false];
}

-(void)refreshTableContents:(BOOL)clearContents
{
    self.loadingStatus = FTLoadStatusLoading;
    [self.uiViewController setHidden:YES buttons:FTUIButtonActionOptionAllExceptCancel];
    if(clearContents){
        [driveFileList removeAllObjects];
        [self.uiViewController reloadData];
    }
    [self loadContentsAtPath:self.rootItem.identifier];
}

-(NSInteger)numberOfItemsForSection:(NSInteger)section
{
    if([self hasParentItem]) {
        if(section == 0){
            if(self.loadingStatus == FTLoadStatusLoaded) {
                return 1;
            }
            return 0;
        }
    }
    NSInteger count = driveFileList.count;
    return count;
}

-(NSInteger)numberOfItems
{
    NSInteger count = driveFileList.count;
    return count;
}

-(FTFolderUICell*)tableView:(UITableView*)tableView cellForItemAtIndex:(NSIndexPath*)index
{
    static NSString *identifier = @"FTFolderUICell";
    FTFolderUICell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    BOOL isSupportedFile = false;
    BOOL isSelected = false;
    if([self hasParentItem] && (index.section == 0)) {
        [cell setMimeType:PARENT_FOLDER_MINE_TYPE];
        [cell.titleLabel setText:NSLocalizedString(@"ParentFolder", @"Parent Folder")];
    }
    else {
        GTLRDrive_File *object = [driveFileList objectAtIndex:index.row];
        [cell.titleLabel setText:[object name]];
        
        if([object.mimeType isEqualToString:FTGoogleDriveFolderMimeType])
        {
            //[cell setStyledDetailText:[NSString stringWithFormat:NSLocalizedString(@"CloudFolderLastUpdatedFormat",@"Last updated: %@"),dateStringForItem(object.modifiedTime.date)] style:FTTableViewCellStyleStyle1];
            [cell setMimeType:nil];
        }
        else
        {
            NSString *mimeType = object.mimeType;
            if ([object.fileExtension.lowercaseString isEqualToString:nsBookExtension]) {
                mimeType = MIMETypeFileAtPath([[object.name stringByDeletingPathExtension] stringByAppendingPathExtension:object.fileExtension]);
            }
            [cell setMimeType:mimeType];
        }
        isSelected = [self.uiViewController.itemsToImport containsObject:object];
        isSupportedFile = ([supportedMimeTypesForDownload() containsObject:object.mimeType] || (self.supportsNoteshelfBookImport && [FTUtils isNoteshelfBookType:object.name.pathExtension]) ||
                (isAudioFile(object.name) && isSupportedFormat(object.name)));
    }

    [cell updateIcon];
    [cell updateImportMode:(self.viewMode == FTViewModeImport)];
    [cell updateSelectionState:isSelected];
    cell.checkButton.hidden = !isSupportedFile;

    return cell;
}

-(void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)index
{
    if([self hasParentItem] && (index.section == 0)) {
        NSString *currentPath = self.pathFromRoot;
        currentPath = [currentPath stringByDeletingLastPathComponent];
        if([currentPath.lowercaseString isEqualToString:FTGoogleDriveRootFolderId.lowercaseString]) {
            currentPath = FTGoogleDriveRootFolderId;
        }
        GTLRDrive_File *file = [[GTLRDrive_File alloc] init];
        file.identifier = currentPath.lastPathComponent;
        self.rootItem = file;
        self.pathFromRoot = currentPath;
        [self refreshTableContents:true];
        return;
    }
    
    GTLRDrive_File *object = [driveFileList objectAtIndex:index.row];
    if([object.mimeType isEqualToString:FTGoogleDriveFolderMimeType])
    {
        [self.uiViewController handleSelectedItem:nil];
        [self pushViewWithViewMode:self.viewMode driveFile:object];
    }
    else if((self.viewMode == FTViewModeImport) && ([supportedMimeTypesForDownload() containsObject:object.mimeType] || (self.supportsNoteshelfBookImport && [FTUtils isNoteshelfBookType:object.name.pathExtension])) ||
            (isAudioFile(object.name) && isSupportedFormat(object.name)))
    {
        [[NSUserDefaults standardUserDefaults] setObject:self.pathFromRoot forKey:@"GDRIVE_IMPORT_FOLDER_ID"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        track(@"import_document", @{@"type" : object.name, @"from" : @"googleDrive"});
        [self.uiViewController handleSelectedItem:object];
    }
}

-(void)updateNavTitle
{
    NSString *title = NSLocalizedString(@"AllFiles",@"All Files");
    if(![self.rootItem.name.lowercaseString isEqualToString:GDRootItemID.lowercaseString]){
        title = self.rootItem.name;
    }
    [self.uiViewController updateNavigationTitle:title forExportMode:self.viewMode];
}

-(NSString*)localizedStringForFailedToUpload
{
    return NSLocalizedString(@"UploadToGoogleDriveFailed",@"Unexpecter Error: Upload to Google Drive Failed");
}

#pragma mark Unique folder name

-(NSString*)generateUniqueFolderName:(NSString*)fileName
{
    NSMutableSet *existingFileNames = [NSMutableSet set];
    [driveFileList enumerateObjectsUsingBlock:^(GTLRDrive_File *obj, NSUInteger idx, BOOL *stop) {
        [existingFileNames addObject:[obj.name lowercaseString]];
    }];
    
    return [self generateUniqueFolderName:fileName existingFileNames:existingFileNames];
}

-(NSString*)generateUniqueFileName:(NSString *)fileName
{
    NSMutableSet *existingFileNames = [NSMutableSet set];
    [driveFileList enumerateObjectsUsingBlock:^(GTLRDrive_File *obj, NSUInteger idx, BOOL *stop) {
        [existingFileNames addObject:[obj.name lowercaseString]];
    }];
    
    return [self generateUniqueFileName:fileName existingFileNames:existingFileNames];
}

-(BOOL)hasParentItem
{
    if([self.rootItem.name.lowercaseString isEqualToString:GDRootItemID.lowercaseString]) {
        return false;
    }
    return true;
}

-(void)sortItemsAlphabetically
{
    [driveFileList sortUsingComparator:^NSComparisonResult(id   _Nonnull obj1, id   _Nonnull obj2) {
        NSString *title1, *title2;
        title1 =[(GTLRDrive_File*)obj1 name];
        title2 =[(GTLRDrive_File*)obj2 name];
        return [title1 compare:title2 options:NSCaseInsensitiveSearch|NSNumericSearch];
    }];
}

@end
#endif
