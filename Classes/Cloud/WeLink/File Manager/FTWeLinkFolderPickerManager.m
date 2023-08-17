//
//  FTWeLinkFolderPickerManager.m
//  Noteshelf
//
//  Created by Naidu on 16/01/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

#import "FTWeLinkFolderPickerManager.h"

#import "FTWeLinkFolderPickerManager.h"
#import "FTFolderUICell.h"
#import "NavigationControllerForFormSheet.h"
#import "FTWeLinkManager.h"
#import "Noteshelf-Swift.h"
#import "FTWeLinkLoginHelper.h"

#if TARGET_OS_IPHONE
#import <HWClouddriveLib/HWClouddriveManger.h>
#endif

#define SUCCESS 0
@import ObjectiveDropboxOfficial;

NSString *const WeLinkRootFolderID = @"0";

@interface FTWeLinkFolderPickerManager() <FTFolderPickerUIActionDelegate>
{
    NSMutableArray <FTWeLinkFile*> *fileList;
}

@property (copy) FTFolderPickerCallbackBlock callBackBlock;
@end

@implementation FTWeLinkFolderPickerManager

@synthesize uiViewController;
@synthesize callBackBlock;

-(instancetype)initWithRootViewController:(UIViewController*)controller
{
    self = [super initWithRootViewController:controller];
    self.rootItem = WeLinkRootFolderID;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(welinkClientUnlinked:) name:FTDidUnlinkAllDropboxClient object:nil];
    return self;
}
-(void)showUIForMode:(FTViewMode)inViewMode parentPath:(id)path modalPresentationStyle:(UIModalPresentationStyle)presentationStyle onCompletion:(FTFolderPickerCallbackBlock)completionHandler
{
    self.viewMode = inViewMode;
    self.callBackBlock = completionHandler;
    
    if(![FTWeLinkLoginHelper isLoggedIn])
    {
        __block __weak FTWeLinkFolderPickerManager *weakSelf = self;
        [[FTWeLinkManager sharedWeLinkManager] authenticateToWeLinkFromController:self.rootViewController
                                                                     onCompletion:^(BOOL success, BOOL cancelled)
         {
             FTWeLinkFolderPickerManager *strongSelf = weakSelf;
             if(nil != strongSelf) {
                 if(success) {
                     FTLoadingIndicatorViewController *loadingIndicatorViewController = [FTLoadingIndicatorViewController showOnMode:FTLoadingIndicatorStyleActivityIndicator from:strongSelf.rootViewController withText:@"" andDelay:0];
                     
                     dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                         [loadingIndicatorViewController hide:^{
                             [strongSelf showUIForMode:strongSelf.viewMode
                                            parentPath:nil
                                modalPresentationStyle:presentationStyle
                                          onCompletion:strongSelf.callBackBlock];
                         }];
                     });
                 }
                 else {
                     if(strongSelf.callBackBlock) {
                         strongSelf.callBackBlock(NO,nil);
                         strongSelf.callBackBlock = nil;
                     }
                 }
             }
         }];
        return;
    }
    
    if(inViewMode == FTViewModeImport)
        path = [[NSUserDefaults standardUserDefaults] objectForKey:@"WELINK_IMPORT_FOLDER_ID"];
    
    if([path pathComponents].count <= 1) {
        path = WeLinkRootFolderID;
    }
    __unused FTFolderPickerUIViewController *localController = [self pickerControllerForItem:path
                                                                                     manager:self
                                                                      supportedButtonOptions:FTUIButtonActionOptionAll & ~FTUIButtonActionOptionSettings];
    
    self.navController = (NavigationControllerForFormSheet *)self.rootViewController.navigationController;
    self.navController.modalPresentationStyle = presentationStyle;
    [self.navController pushViewController:uiViewController animated:YES];
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
        [self loadContentsAtPath: [self.rootItem lastPathComponent]];
    }
}

-(void)welinkClientUnlinked:(NSNotification*)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self dismissUI:nil];
}

- (void)loadedMetadata:(NSMutableArray *)metadata
{
    [self updateNavTitle];
    if(nil == fileList)
    {
        fileList = [NSMutableArray array];
    }
    else {
        [fileList removeAllObjects];
    }
    
    [metadata enumerateObjectsUsingBlock:^(NSDictionary*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        FTWeLinkFile *fileItem = [[FTWeLinkFile alloc] init];
        fileItem.cownerId = [NSString stringWithFormat:@"%@",obj[@"ownedBy"]];
        fileItem.rid = [NSString stringWithFormat:@"%@",obj[@"id"]];
        fileItem.cname = [NSString stringWithFormat:@"%@",obj[@"name"]];
        fileItem.lpath = [NSString stringWithFormat:@"%@",obj[@"name"]];
        NSInteger type = [obj[@"type"] integerValue];
        if (type > 0) {
            fileItem.isFolder = NO;
        } else {
            fileItem.isFolder = YES;
        }
        
        [fileList addObject:fileItem];
    }];
    
    self.loadingStatus = FTLoadStatusLoaded;
    [self sortItemsAlphabetically];
    [self.uiViewController showActivityIndicator:NO];
    [self.uiViewController reloadData];
    if(self.callBackBlock)
    {
        self.callBackBlock(YES,nil);
        self.callBackBlock = nil;
    }
}

- (void)loadMetadataFailedWithError:(NSError*)error
{
    if(error.code == 6 && [self hasParentItem]) // 6 = Resource deleted / not found error
    {
        if(self.viewMode == FTViewModeImport)
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"WELINK_IMPORT_FOLDER_ID"];
        else
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"WELINK_EXPORT_FOLDER_ID"];
        
        [[NSUserDefaults standardUserDefaults] synchronize];
        self.rootItem = WeLinkRootFolderID;
        [self refreshTableContents:true];
        return;
    }
    else
    {
        [self dismissUI:nil];
        self.loadingStatus = FTLoadStatusLoaded;
        [error showAlertFrom:self.uiViewController];
        if(self.callBackBlock)
        {
            self.callBackBlock(NO,error);
            self.callBackBlock = nil;
        }
    }
}

#pragma mark -
-(void)loadContentsAtPath:(NSString*)fileResourceId
{
    [self.uiViewController setHidden:YES buttons:FTUIButtonActionOptionAllExceptCancel];
    self.loadingStatus = FTLoadStatusLoading;
    [self.uiViewController showActivityIndicator:YES];
    
    void (^ callBack)(id result) = ^ (id result) {
        
        DEBUGLOG(@"%@", result);
        NSDictionary*resultDic = (NSDictionary*)result;
        
        NSDictionary *JsonDic = [resultDic objectForKey:@"jsonStr"];
        NSDictionary *responseObject = [[NSDictionary alloc] init];
        NSDictionary *errorInfo = JsonDic[@"error"];
        NSInteger errorCode = [errorInfo[@"errorCode"] integerValue];
        if (errorCode == SUCCESS) {
            responseObject = [JsonDic objectForKey:@"fileslist"];
            
            if (responseObject != nil) {
                
                NSArray* files = [responseObject objectForKey:@"files"];
                NSArray* folders = [responseObject objectForKey:@"folders"];
                NSMutableArray* allItems = [NSMutableArray arrayWithCapacity:files.count + folders.count];
                [allItems addObjectsFromArray:files];
                [allItems addObjectsFromArray:folders];
                [allItems sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                    NSDictionary* dic1 = obj1;
                    NSDictionary* dic2 = obj2;
                    
                    NSString* fid1 = [[dic1 objectForKey:@"id"] stringValue];
                    NSString* fid2 = [[dic2 objectForKey:@"id"] stringValue];
                    
                    NSString* owner1 = [[dic1 objectForKey:@"ownedBy"] stringValue];
                    NSString* owner2 = [[dic2 objectForKey:@"ownedBy"] stringValue];
                    
                    NSComparisonResult result =  [fid1 compare:fid2];
                    return !result ? [owner1 compare:owner2] : result;
                }];
                [self loadedMetadata:allItems];
            } else {
                DEBUGLOG(@"getClouddriveFilesListForThird %@", errorInfo);
                NSString *errorMessage = errorInfo[@"errorMsg"];
                if([errorMessage containsString:@"NSErrorFailingURLKey"]){
                    if([errorMessage containsString:@"Internet connection appears to be offline"]){
                        errorMessage = NSLocalizedString(@"NoInternetHeader", @"No internet connection");
                    }
                    else{
                        errorMessage = @"Error";
                    }
                }
                [self loadMetadataFailedWithError:[FTWeLinkError welinkErrorWith:errorMessage code:[errorInfo[@"errorCode"] intValue]]];
            }
            
        } else {
            DEBUGLOG(@"getClouddriveFilesListForThird %@", errorInfo);
            NSString *errorMessage = errorInfo[@"errorMsg"];
            if([errorMessage containsString:@"NSErrorFailingURLKey"]){
                if([errorMessage containsString:@"Internet connection appears to be offline"]){
                    errorMessage = NSLocalizedString(@"NoInternetHeader", @"No internet connection");
                }
                else{
                    errorMessage = @"Error";
                }
            }
            [self loadMetadataFailedWithError:[FTWeLinkError welinkErrorWith:errorMessage code:[errorInfo[@"errorCode"] intValue]]];
        }
    };
    #if !TARGET_OS_MACCATALYST
    #if !TARGET_OS_SIMULATOR
        HWClouddriveURI* uri = [HWClouddriveURI URIWithString:@"method://welink.onebox/getClouddriveFilesListForThird"];
        uri.parameters = @{@"thirdClient_id":@"NoteShelf",
                           @"folderId":fileResourceId,
                           @"orderField":@"",
                           @"orderDirection":@"",
                           @"callback":callBack,
                           };
        [[HWClouddriveManger Instance] resourceWithURI:uri];
    #endif
    #endif
}

#pragma mark -

-(FTFolderPickerUIViewController*)pickerControllerForItem:(NSString*)filePath
                                                  manager:(FTWeLinkFolderPickerManager*)manager
                                   supportedButtonOptions:(FTUIButtonActionOption)supportedButtonOptions
{
    FTFolderPickerUIViewController *localController = [[FTFolderPickerUIViewController alloc] initWithUIViewMode:self.viewMode
                                                                                                supportedActions:supportedButtonOptions];
    
    localController.delegate = manager;
    localController.allowsMultipleFileSelection = self.allowsMultipleFileSelection;
    
    manager.uiViewController = localController;
    manager.navController = self.navController;
    manager.rootItem = filePath;
    manager.viewMode = self.viewMode;
    manager.delegate = self.delegate;
    return localController;
}

#pragma mark -
-(void)pushViewWithViewMode:(FTViewMode)viewMode rootItem:(FTWeLinkFile*)object
{
    NSString *fileResourceId = [NSString stringWithFormat:@"%@",object.rid];
    self.rootItem = [self.rootItem stringByAppendingPathComponent:fileResourceId];
    [self refreshTableContents:true];
}

#pragma mark NEW Folder

-(void)createFolder:(NSString*)folderName parentFolder:(NSString*)rootFolder onCompletion:(FTFolderPickerNewFolderCallbackBlock)callBack
{
    folderName = [self generateUniqueFolderName:folderName];
    [[[[DBClientsManager authorizedClient] filesRoutes] createFolderV2:[rootFolder stringByAppendingPathComponent:folderName]] setResponseBlock:^(DBFILESCreateFolderResult * _Nullable result, DBFILESCreateFolderError * _Nullable routeError, DBRequestError * _Nullable networkError) {
        if(result) {
            if(callBack)
            {
                DBFILESFolderMetadata *metadata = result.metadata;
                callBack(result,metadata.pathLower,nil);
            }
        }
        else {
            if(callBack)
            {
                NSError *error = nil;
                if(nil != routeError) {
                    error = [routeError nserrorMapped];
                }
                if(nil == error) {
                    error = [networkError nserrorMapped];
                }
                callBack(nil,nil,error);
            }
        }
    }];
}

#pragma mark -
-(void)signOut:(id)sender
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"WELINK_IMPORT_FOLDER_ID"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)dismissUI:(id)sender
{
    self.uiViewController.delegate = nil;
    if(!self.navController.isBeingDismissed) {
        if([self.delegate respondsToSelector:@selector(didDismissUI)])
            [self.delegate didDismissUI];
        [self.rootViewController dismissViewControllerAnimated:YES completion:nil];
    }
}
-(void)exportHere:(id)sender
{
    if([self.delegate respondsToSelector:@selector(exportToFolder:manager:)])
    {
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
        [fileList removeAllObjects];
        [self.uiViewController reloadData];
    }
    [self loadContentsAtPath: [self.rootItem lastPathComponent]];
}

-(NSInteger)numberOfItemsForSection:(NSInteger)section
{
    NSInteger count = fileList.count;
    if([self hasParentItem] && section == 0) {
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
    
    BOOL isSupportedFile = false;
    BOOL isSelected = false;
    
    if([self hasParentItem] && indexPath.section == 0) {
        [cell setMimeType:PARENT_FOLDER_MINE_TYPE];
        [cell.titleLabel setText:NSLocalizedString(@"ParentFolder", @"Parent Folder")];
    }
    else {
        // Configure the cell...
        FTWeLinkFile *item = [fileList objectAtIndex:indexPath.row];
        [cell.titleLabel setText:[item cname]];
        NSString *mimeType = MIMETypeFileAtPath(item.lpath) ;
        
        if([item isFolder])
        {
            [cell setMimeType:nil];
        }
        else
        {
            [cell setMimeType:mimeType];
        }
        isSelected = [self.uiViewController.itemsToImport containsObject:item];
        isSupportedFile = ([supportedMimeTypesForDownload() containsObject:mimeType] || (self.supportsNoteshelfBookImport && [FTUtils isNoteshelfBookType:item.cname.pathExtension]) ||
                (isAudioFile(item.lpath) && isSupportedFormat(item.lpath)));
    }
    [cell updateIcon];
    [cell updateImportMode:(self.viewMode == FTViewModeImport)];
    [cell updateSelectionState:isSelected];
    cell.checkButton.hidden = !isSupportedFile;
    return cell;
}

-(void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    if(indexPath.section == 0 && [self hasParentItem]) {
        NSString *path = self.rootItem;
        NSString *parent = [path stringByDeletingLastPathComponent];
        if([parent isEqualToString:@"0"]) {
            parent = WeLinkRootFolderID;
        }
        self.rootItem = parent;
        [self refreshTableContents:true];
        return;
    }
    FTFolderUICell *cell = (FTFolderUICell*)[tableView cellForRowAtIndexPath:indexPath];
    NSString *mineType = [cell mimeType];
    
    FTWeLinkFile *item = [fileList objectAtIndex:indexPath.row];
    if([item isFolder])
    {
        [self.uiViewController handleSelectedItem:nil]; //To clear all the selected fies
        [self pushViewWithViewMode:self.viewMode rootItem:item];
    }
    else if((self.viewMode == FTViewModeImport) && ([supportedMimeTypesForDownload() containsObject:mineType] || (self.supportsNoteshelfBookImport && [FTUtils isNoteshelfBookType:item.cname.pathExtension])) ||
            (isAudioFile(item.lpath) && isSupportedFormat(item.lpath)))
    {
        [[NSUserDefaults standardUserDefaults] setObject:self.rootItem forKey:@"WELINK_IMPORT_FOLDER_ID"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        track(@"import_document", @{@"type" : item.lpath.lastPathComponent, @"from" : @"weLink"});
        [self.uiViewController handleSelectedItem:item];
    }}

-(void)updateNavTitle
{
    NSString *title = NSLocalizedString(@"AllFiles",@"All Files");
    if(self.hasParentItem){
        title = [self.rootItem lastPathComponent];
    }
    [self.uiViewController updateNavigationTitle:title forExportMode:self.viewMode];
}

-(NSString*)localizedStringForFailedToUpload
{
    return NSLocalizedString(@"UploadToDropboxFailed",@"Unexpecter Error: Upload to Dropbox Failed");
}

-(void)sortItemsAlphabetically
{
    [fileList sortUsingComparator:^NSComparisonResult(id   _Nonnull obj1, id   _Nonnull obj2) {
        NSString *title1, *title2;
        title1 =[(FTWeLinkFile*)obj1 cname];
        title2 =[(FTWeLinkFile*)obj2 cname];
        return [title1 compare:title2 options:NSCaseInsensitiveSearch|NSNumericSearch];
    }];
}

-(BOOL)hasParentItem
{
    if([self.rootItem isEqualToString:WeLinkRootFolderID]) {
        return false;
    }
    return  true;
}
@end

