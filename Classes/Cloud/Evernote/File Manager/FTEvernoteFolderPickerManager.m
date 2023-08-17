//
//  FTEvernoteFolderPickerManager.m
//  Noteshelf
//
//  Created by Amar Udupa on 9/4/14.
//
//

#import "FTEvernoteFolderPickerManager.h"
#import "NavigationControllerForFormSheet.h"
#import "FTFolderUICell.h"
#import "EvernoteSettingsViewController.h"

#import "Noteshelf-Swift.h"

NSString *const ENRootItemID = @"";

@interface FTEvernoteFolderPickerManager () <FTFolderPickerUIActionDelegate,UIPopoverPresentationControllerDelegate,EvernoteSettingsViewControllerDelegate>
{

}

@property (strong) NSMutableArray *fileList;
@property (assign) BOOL showingNotes;
@property (copy) FTFolderPickerCallbackBlock completionCallBack;
@property (strong) UIPopoverPresentationController *settingsPopoverController;

@end

@implementation FTEvernoteFolderPickerManager

@synthesize uiViewController;
@synthesize navController;
@synthesize rootItem;
@synthesize showingNotes;
@synthesize completionCallBack;
@synthesize loadingStatus;
@synthesize settingsPopoverController;

-(instancetype)initWithRootViewController:(UIViewController*)controller
{
    self = [super initWithRootViewController:controller];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeOrientation:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    
    return self;
}

- (void)dealloc
{
    [self.settingsPopoverController.presentedViewController dismissViewControllerAnimated:NO completion:nil];
    self.settingsPopoverController = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
}

-(void)showUIForMode:(FTViewMode)inViewMode
          parentPath:(id)path
modalPresentationStyle:(UIModalPresentationStyle)presentationStyle
        onCompletion:(FTFolderPickerCallbackBlock)completionHandler
{
    self.viewMode = inViewMode;
    self.completionCallBack = completionHandler;
    #if !TARGET_OS_MACCATALYST
    ENSession *session = [ENSession sharedSession];
    
    if (!session.isAuthenticated) {
        [session authenticateWithViewController:self.rootViewController preferRegistration:NO
                                     completion:^(NSError *error)
         {
             if (error || !session.isAuthenticated)
             {
                 UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"" message:NSLocalizedString(@"EvernoteAuthenticationFailed", @"Unable to authenticate with Evernote") preferredStyle:UIAlertControllerStyleAlert];
                 
                 UIAlertAction *action = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK") style:UIAlertActionStyleCancel handler:nil];
                 [alertController addAction:action];
                 [self.uiViewController presentViewController:alertController animated:YES completion:nil];
                 if(self.completionCallBack)
                 {
                     self.completionCallBack(NO,nil);
                     self.completionCallBack = nil;
                 }
             }
             else
             {
                 [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"EVERNOTE_LAST_LOGIN_ALERT_TIME"];
                 [self showUIForMode:self.viewMode
                          parentPath:path
              modalPresentationStyle:presentationStyle
                        onCompletion:self.completionCallBack];
             }
         }];
    }
    else
    {
        NSDictionary *notebookInfo = nil;
        if(inViewMode == FTViewModeExport)
            notebookInfo = [[NSUserDefaults standardUserDefaults] objectForKey:PersistenceKey_ExportTarget_FolderID_Evernote];
        
        EDAMNotebook *notebook = nil;
        FTUIButtonActionOption options = FTUIButtonActionOptionAll & ~FTUIButtonActionOptionExport;
        if(nil != notebookInfo) {
            notebook = [[EDAMNotebook alloc] init];
            notebook.guid = [notebookInfo objectForKey:@"guid"];
            notebook.name = [notebookInfo objectForKey:@"name"];
            options = (options & ~FTUIButtonActionOptionNewFolder) | FTUIButtonActionOptionExport;
            self.showingNotes = true;
        }
        __unused FTFolderPickerUIViewController *localController = [self pickerControllerForItem:notebook
                                                                                manager:self
                                                                 supportedButtonOptions:options];
        
        self.navController = (NavigationControllerForFormSheet *)self.rootViewController.navigationController;
        self.navController.modalPresentationStyle = presentationStyle;
        
        [self.navController pushViewController:uiViewController animated:YES];
         if(self.completionCallBack)
         {
             self.completionCallBack(YES,nil);
             self.completionCallBack = nil;
         }
    }
    #endif
}

-(void)showUIForMode:(FTViewMode)inViewMode
          parentPath:(id)path
        onCompletion:(FTFolderPickerCallbackBlock)completionHandler
{
    [self showUIForMode:inViewMode
             parentPath:path
 modalPresentationStyle:UIModalPresentationFormSheet
           onCompletion:completionHandler];
}

-(void)viewDidAppear
{
    if(self.loadingStatus == FTLoadStatusNone)
    {
        [self loadContentsAtPath:self.rootItem];
    }
}

-(void)loadContentsAtPath:(id)refObject
{
    [self.uiViewController setHidden:YES buttons:FTUIButtonActionOptionAllExceptCancel];
    [self.uiViewController showActivityIndicator:YES];
    
    self.loadingStatus = FTLoadStatusLoading;
    //check fi the item passed is Notebook or root.
    #if !TARGET_OS_MACCATALYST
    if([refObject isKindOfClass:[EDAMNotebook class]])
    {
        EDAMNotebook *notebook = refObject;
        ENNoteStoreClient *noteStore = [ENSession sharedSession].primaryNoteStore;
        if (!noteStore)
        {
            if(self.completionCallBack)
            {
                self.completionCallBack(NO,nil);
                self.completionCallBack = nil;
            }
            [self dismissUI:nil];
            [self showAlertForRelogin];
            return;
        }
        EDAMNoteFilter *filter = [[EDAMNoteFilter alloc] init];
        filter.order = [NSNumber numberWithInt:0];
        filter.ascending = @YES;
        filter.words = nil;
        filter.notebookGuid = notebook.guid;
        filter.tagGuids = nil;
        filter.timeZone = nil;
        filter.inactive = @NO;
        filter.emphasized = nil;
        __block __weak FTEvernoteFolderPickerManager *weakSelf = self;
        [noteStore findNotesWithFilter:filter
                                offset:0
                              maxNotes:[EDAMLimitsConstants EDAM_USER_NOTES_MAX]
                            completion:^(EDAMNoteList * _Nullable list, NSError * _Nullable error) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                if(nil == error) {
                                    [weakSelf updateNavTitle];
                                    weakSelf.loadingLastOpenedFolder = NO;
                                    if(nil == weakSelf.fileList)
                                    {
                                        weakSelf.fileList = [NSMutableArray array];
                                    }
                                    else
                                        [weakSelf.fileList removeAllObjects];
                                    [weakSelf.fileList addObjectsFromArray:list.notes];
                                    [weakSelf sortItemsAlphabetically];
                                    
                                    weakSelf.loadingStatus = FTLoadStatusLoaded;
                                    [weakSelf.uiViewController showActivityIndicator:NO];
                                    [weakSelf.uiViewController reloadData];
                                    
                                }
                                else {
                                    if (error.code == ENErrorCodeAuthExpired)
                                    {
                                        if(weakSelf.completionCallBack)
                                        {
                                            weakSelf.completionCallBack(NO,nil);
                                            weakSelf.completionCallBack = nil;
                                        }
                                        [weakSelf dismissUI:nil];
                                        [weakSelf showAlertForRelogin];
                                        return;
                                    }
                                    
                                    if(weakSelf.loadingLastOpenedFolder)
                                    {
                                        if(weakSelf.viewMode == FTViewModeExport)
                                            [[NSUserDefaults standardUserDefaults] removeObjectForKey:PersistenceKey_ExportTarget_FolderID_Evernote];
                                        [[NSUserDefaults standardUserDefaults] synchronize];
                                        [weakSelf pushViewWithViewMode:weakSelf.viewMode driveFile:nil];
                                        return;
                                    }
                                    
                                    weakSelf.loadingStatus = FTLoadStatusLoaded;
                                    [weakSelf.uiViewController showActivityIndicator:NO];
                                    [weakSelf.uiViewController reloadData];
                                }
                            });
                                
                            }];
    }
    else
    {
        ENNoteStoreClient *noteStore = [ENSession sharedSession].primaryNoteStore;
        if (!noteStore)
        {
            if(self.completionCallBack)
            {
                self.completionCallBack(NO,nil);
                self.completionCallBack = nil;
            }
            [self dismissUI:nil];
            [self showAlertForRelogin];
            return;
        }
        __weak FTEvernoteFolderPickerManager *weakSelf = self;
        [noteStore listNotebooksWithCompletion:^(NSArray<EDAMNotebook *> * _Nullable notebooks, NSError * _Nullable error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if(nil == error) {
                    [weakSelf updateNavTitle];
                    if(nil == weakSelf.fileList)
                    {
                        weakSelf.fileList = [NSMutableArray array];
                    }
                    else
                        [weakSelf.fileList removeAllObjects];
                    [weakSelf.fileList addObjectsFromArray:notebooks];
                    [weakSelf sortItemsAlphabetically];

                    weakSelf.loadingStatus = FTLoadStatusLoaded;
                    [weakSelf.uiViewController showActivityIndicator:NO];
                    [weakSelf.uiViewController reloadData];
                    if(weakSelf.completionCallBack)
                    {
                        weakSelf.completionCallBack(YES,nil);
                        weakSelf.completionCallBack = nil;
                    }
                }
                else {
                    if(weakSelf.completionCallBack)
                    {
                        weakSelf.completionCallBack(NO,nil);
                        weakSelf.completionCallBack = nil;
                    }
                    weakSelf.loadingStatus = FTLoadStatusLoaded;
                    
                    if (error.code == ENErrorCodeAuthExpired)
                    {
                        [weakSelf dismissUI:nil];
                        [weakSelf showAlertForRelogin];
                        return;
                    }
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"" message:NSLocalizedString(@"EvernoteRetieveNotebookFailed", @"Unable to retrieve Evernote notebook") preferredStyle:UIAlertControllerStyleAlert];
                    
                    UIAlertAction *action = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK") style:UIAlertActionStyleDefault handler:nil];
                    [alertController addAction:action];
                    [weakSelf.uiViewController presentViewController:alertController animated:YES completion:nil];
                }
            });
            
        }];
    }
    #endif
}
#if !TARGET_OS_MACCATALYST
-(FTFolderPickerUIViewController*)pickerControllerForItem:(EDAMNotebook*)notebook
                                                  manager:(FTEvernoteFolderPickerManager*)manager
                                   supportedButtonOptions:(FTUIButtonActionOption)supportedButtonOptions
{
    FTFolderPickerUIViewController *localController = [[FTFolderPickerUIViewController alloc] initWithUIViewMode:self.viewMode supportedActions:supportedButtonOptions];
    
    localController.delegate = manager;
    localController.allowsMultipleFileSelection = self.allowsMultipleFileSelection;

    manager.uiViewController = localController;
    manager.navController = self.navController;
    manager.rootItem = notebook;
    manager.viewMode = self.viewMode;
    manager.delegate = self.delegate;
    return localController;
}

-(void)pushViewWithViewMode:(FTViewMode)viewMode driveFile:(EDAMNotebook*)notebook
{
    self.rootItem = notebook;
    self.showingNotes = (nil != notebook) ? YES : NO;
    [self refreshTableContents:true];
    [self updateButtons];
}
#endif
#pragma mark Create Notebook

-(void)createFolder:(NSString *)folderName parentFolder:(id)rootFolder onCompletion:(FTFolderPickerNewFolderCallbackBlock)callBack
{
    folderName = [self generateUniqueFolderName:folderName];
    #if !TARGET_OS_MACCATALYST
    ENNoteStoreClient *noteStore = [ENSession sharedSession].primaryNoteStore;
    if (!noteStore)
    {
        if (callBack)
        {
            callBack(nil,nil,[NSError errorWithDomain:ENErrorDomain code:ENErrorCodeAuthExpired userInfo:nil]);
        }
        [self dismissUI:nil];
        [self showAlertForRelogin];
        return;
    }

    EDAMNotebook *notebook = [[EDAMNotebook alloc] init];
	[notebook setName:folderName];
    
    [noteStore createNotebook:notebook completion:^(EDAMNotebook * _Nullable notebook, NSError * _Nullable error) {
        if (nil != error) {
            callBack(nil,nil,error);
        } else {
            callBack(notebook,notebook.name,nil);
        }
    }];
    #endif
}

#pragma mark folder picker ui delegate
-(NSString*)newFolderButtonTitle
{
    return NSLocalizedString(@"NewNotebook", @"New Notebook");
}

-(void)signOut:(id)sender
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:PersistenceKey_ExportTarget_FolderID_Evernote];
    [[NSUserDefaults standardUserDefaults] synchronize];
    #if !TARGET_OS_MACCATALYST
    ENSession *session = [ENSession sharedSession];
    [session unauthenticate];
    #endif
    [self dismissUI:nil];
    
    //Just remove the error cached in NSUserDefaults
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:EVERNOTE_PUBLISH_ERROR];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:EN_PUBLISH_ERR_SHOW_SUPPORT];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"EVERNOTE_LAST_LOGIN_ALERT_TIME"];
    [[FTENIgnoreListManager sharedIgnoreListManager] clearIgnoreList];
}

-(void)createNewFolder:(id)sender
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"FolderName", @"Folder Name") message:@"" preferredStyle:UIAlertControllerStyleAlert];
    __block __weak UIAlertController *weakController = alertController;
    __block __weak FTEvernoteFolderPickerManager *weakSelf = self;

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel",@"Cancel") style:UIAlertActionStyleCancel handler:nil];
    [alertController addAction:cancelAction];
    
    UIAlertAction *doneAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK",@"OK") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action)
    {
        if(nil != weakController) {
            NSString *folderName = [[weakController textFields].firstObject.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if ([folderName isEqualToString:@""]) {
                return;
            }
            [self createFolder:folderName parentFolder:self.rootItem onCompletion:^(id item,NSString *folderID,NSError *error) {
                if(error)
                {
                    [error showAlertFrom:self.uiViewController];
                    return;
                }
                if(item)
                {
                    [weakSelf.fileList addObject:item];
                    [self sortItemsAlphabetically];
                    [self.uiViewController reloadData];

                    NSInteger section = [self hasParentItem] ? 1 : 0;

                    NSInteger index = [weakSelf.fileList indexOfObject:item];
                    [self.uiViewController.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:section] atScrollPosition:UITableViewScrollPositionBottom animated:NO];
                }
            }];
        }
    }];
    
    [alertController addAction:doneAction];
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
        if(!self.rootItem)
        {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:PersistenceKey_ExportTarget_FolderID_Evernote];
        }
        else
        {
            #if !TARGET_OS_MACCATALYST
            EDAMNotebook *root = self.rootItem;
            
            [[NSUserDefaults standardUserDefaults] setObject:@{@"name": [root name],@"guid":[root guid]} forKey:PersistenceKey_ExportTarget_FolderID_Evernote];
            [[NSUserDefaults standardUserDefaults] setObject:[root name] forKey:[NSString stringWithFormat:@"%@_FolderName", PersistenceKey_ExportTarget_Evernote]];
            #endif
        }
        [[NSUserDefaults standardUserDefaults] synchronize];
        self.uiViewController.delegate = nil;
        
        for(UIViewController *controller in (NavigationControllerForFormSheet *)self.rootViewController.navigationController.viewControllers){
            if([controller isKindOfClass:[FTExportSettingsViewController class]]){
                [(UINavigationController *)self.rootViewController.navigationController popToViewController:controller animated:YES];
                break;
            }
        }
        [self.delegate exportToFolder:self.rootItem manager:self];
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
        [self.fileList removeAllObjects];
        [self.uiViewController reloadData];
    }
    [self loadContentsAtPath:self.rootItem];
}

-(void)showSettings:(id)sender
{
    if(self.settingsPopoverController)
    {
        [self.settingsPopoverController.presentedViewController dismissViewControllerAnimated:NO completion:nil];
        self.settingsPopoverController = nil;
    }
    
    EvernoteSettingsViewController *controller = [[EvernoteSettingsViewController alloc] initWithNibName:@"EvernoteSettingsViewController4" bundle:nil];
    controller.delegate = self;
    UINavigationController *navSettingsController = [[UINavigationController alloc] initWithRootViewController:controller];
    navSettingsController.modalPresentationStyle = UIModalPresentationPopover;
    
    self.settingsPopoverController = navSettingsController.popoverPresentationController;
    self.settingsPopoverController.delegate = self;
    self.settingsPopoverController.barButtonItem = sender;
    self.settingsPopoverController.permittedArrowDirections = UIPopoverArrowDirectionDown;
    self.settingsPopoverController.passthroughViews = nil;
    
    [self.uiViewController presentViewController:navSettingsController animated:YES completion:nil];
}

-(NSInteger)numberOfItemsForSection:(NSInteger)section
{
    NSInteger count = self.fileList.count;
    if(section == 0 && [self hasParentItem]) {
        count = 0;
        if(self.loadingStatus == FTLoadStatusLoaded) {
            count = 1;
        }
    }
    return count;
}

-(UITableViewCell*)tableView:(UITableView*)tableView cellForItemAtIndex:(NSIndexPath*)indexPath
{
    static NSString *identifier = @"FTFolderUICell";
    FTFolderUICell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if(indexPath.section == 0 && [self hasParentItem]) {
        [cell setMimeType:PARENT_FOLDER_MINE_TYPE];
        [cell.titleLabel setText:NSLocalizedString(@"ParentFolder", @"Parent Folder")];
    }
    else {
        NSString *mimeType = nil;
        #if !TARGET_OS_MACCATALYST
        if(self.showingNotes)
        {
            // Configure the cell...
            EDAMNote *item = [self.fileList objectAtIndex:indexPath.row];
            [cell.titleLabel setText:[item title]];
            mimeType = @"UNKNOWN";
        }
        else
        {
            // Configure the cell...
            EDAMNotebook *item = [self.fileList objectAtIndex:indexPath.row];
            [cell.titleLabel setText:[item name]];
            mimeType = @"evernote-notebook";
        }
        #endif
        [cell setMimeType:mimeType];
    }

    [cell updateIcon];
    [cell updateImportMode:(self.viewMode == FTViewModeImport)];
    [cell updateSelectionState:NO];

    return cell;
}

-(void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    #if !TARGET_OS_MACCATALYST
    if(indexPath.section ==0 && [self hasParentItem]) {
        [self pushViewWithViewMode:self.viewMode driveFile:nil];
        return;
    }
    if(!self.showingNotes)
    {
        EDAMNotebook *item = [self.fileList objectAtIndex:indexPath.row];
        [self pushViewWithViewMode:self.viewMode driveFile:item];
    }
    else
    {
        
    }
    #endif
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

-(void)updateNavTitle
{
    NSString *title = NSLocalizedString(@"AllFiles",@"All Files");
    if([self hasParentItem]){
        #if !TARGET_OS_MACCATALYST
        title = [(EDAMNotebook *)self.rootItem name];
        #endif
    }
    [self.uiViewController updateNavigationTitle:title forExportMode:self.viewMode];
}
#pragma mark 
-(void)evernoteSettingsDismissPopover:(EvernoteSettingsViewController *)controller
{
    [self.settingsPopoverController.presentedViewController dismissViewControllerAnimated:YES completion:nil];
    self.settingsPopoverController = nil;
}

#pragma mark UIPopOverDelegate
-(void)popoverPresentationControllerDidDismissPopover:(UIPopoverPresentationController *)popoverPresentationController
{
    self.settingsPopoverController = nil;
}

#pragma mark Notification

-(void)didChangeOrientation:(NSNotification*)notification
{
    if(UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])
       ||
       UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]))
    {
        [self.settingsPopoverController.presentedViewController dismissViewControllerAnimated:NO completion:nil];
        self.settingsPopoverController = nil;
    }
}

-(NSString*)localizedStringForFailedToUpload
{
    return NSLocalizedString(@"EvernoteUploadFailed",@"Unexpecter Error: Upload to Evernote Failed");
}

#pragma mark Unique folder name

-(NSString*)generateUniqueFolderName:(NSString*)fileName
{
    NSMutableSet *existingFileNames = [NSMutableSet set];
    #if !TARGET_OS_MACCATALYST
    [self.fileList enumerateObjectsUsingBlock:^(EDAMNotebook *obj, NSUInteger idx, BOOL *stop) {
        [existingFileNames addObject:[obj.name lowercaseString]];
    }];
    #endif
    return [self generateUniqueFolderName:fileName existingFileNames:existingFileNames];
}

-(NSString*)generateUniqueFileName:(NSString *)fileName
{
    NSMutableSet *existingFileNames = [NSMutableSet set];
    #if !TARGET_OS_MACCATALYST
    [self.fileList enumerateObjectsUsingBlock:^(EDAMNotebook *obj, NSUInteger idx, BOOL *stop) {
        [existingFileNames addObject:[obj.name lowercaseString]];
    }];
    #endif
    return [self generateUniqueFileName:fileName existingFileNames:existingFileNames];
}

-(void)showAlertForRelogin
{
    UIAlertController *alertViewController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"EvernoteAuthTokenExpiredTitle", @"Evernote Token Expired") message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *action = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel",@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action)
                             {
                                 [alertViewController dismissViewControllerAnimated:YES completion:nil];
                             }];
    [alertViewController addAction:action];
    
    dispatch_async(dispatch_get_main_queue(), ^
    {
        UIViewController *presentFromController = self.uiViewController;
        if(presentFromController == nil) {
            FTLogError(@"FTEvernoteFolderPickerManager: Presenting Controller is Nil", nil);
            presentFromController = [[[UIApplication sharedApplication] keyWindow] visibleViewController];
        }
        [presentFromController presentViewController:alertViewController animated:YES completion:nil];
    });
}

-(BOOL)hasParentItem {
    if(nil != self.rootItem) {
        return true;
    }
    return false;
}

-(void)updateButtons
{
    if([self hasParentItem]) {
        [self.uiViewController updateSupportedButtons:(self.uiViewController.supportedButtonOptions & ~FTUIButtonActionOptionNewFolder) | FTUIButtonActionOptionExport];
    }
    else {
        [self.uiViewController updateSupportedButtons:FTUIButtonActionOptionAll & ~FTUIButtonActionOptionExport];
    }
}

-(void)sortItemsAlphabetically
{
    #if !TARGET_OS_MACCATALYST
    [self.fileList sortUsingComparator:^NSComparisonResult(id   _Nonnull obj1, id   _Nonnull obj2) {
        NSString *title1, *title2;
        if([obj1 isKindOfClass:[EDAMNotebook class]]) {
            title1 =[(EDAMNotebook*)obj1 name];
            title2 =[(EDAMNotebook*)obj2 name];
        }
        else if([obj1 isKindOfClass:[EDAMNote class]]){
            title1 =[(EDAMNote*)obj1 title];
            title2 =[(EDAMNote*)obj2 title];
        }
        return [title1 compare:title2 options:NSCaseInsensitiveSearch|NSNumericSearch];
    }];
    #endif
}

@end
