//
//  FTBaseFolderPickerManager.h
//  Noteshelf
//
//  Created by Amar Udupa on 14/3/14.
//
//
#import <Foundation/Foundation.h>
#import "FTFolderPickerUIViewController.h"

typedef NS_ENUM(NSInteger, FTLoadStatus)
{
    FTLoadStatusNone,
    FTLoadStatusLoading,
    FTLoadStatusLoaded,
};

@class NavigationControllerForFormSheet,FTBaseFolderPickerManager;

typedef void (^FTFolderPickerCallbackBlock)(BOOL success,NSError *error);
typedef void (^FTFolderPickerNewFolderCallbackBlock)(id item,NSString *folderID,NSError *error);

@protocol FTFolderPickerDelegate <NSObject>

@optional

-(void)downloadFiles:(NSArray*)files manager:(FTBaseFolderPickerManager*)manager;
-(void)exportToFolder:(id)folder manager:(FTBaseFolderPickerManager*)manager;
-(void)didDismissUI;

@end

@interface FTBaseFolderPickerManager : NSObject

@property (nonatomic,readonly,weak) UIViewController *rootViewController;
@property (assign) FTViewMode viewMode;
@property (weak) FTFolderPickerUIViewController *uiViewController;
@property (strong) id rootItem;
@property (strong) NSString *fullPath;
@property (readwrite, nonatomic) BOOL allowsMultipleFileSelection;
@property (assign) BOOL supportsNoteshelfBookImport;

@property (weak)  id<FTFolderPickerDelegate> delegate;
@property (weak)  NavigationControllerForFormSheet *navController;
@property (assign) FTLoadStatus loadingStatus;
@property (assign) BOOL loadingLastOpenedFolder;

-(instancetype)initWithRootViewController:(UIViewController*)controller;

-(void)showUIForMode:(FTViewMode)inViewMode
          parentPath:(id)path
        onCompletion:(FTFolderPickerCallbackBlock)completionHandler;

-(void)showUIForMode:(FTViewMode)inViewMode
          parentPath:(id)path
modalPresentationStyle:(UIModalPresentationStyle)presentationStyle
        onCompletion:(FTFolderPickerCallbackBlock)completionHandler;

-(void)loadContentsAtPath:(id)refObject;

-(void)createFolder:(NSString *)folderName parentFolder:(id)rootFolder onCompletion:(FTFolderPickerNewFolderCallbackBlock)callBack;

-(NSString*)localizedStringForFailedToUpload;

-(NSString*)newFolderButtonTitle;

#pragma mark Unique folder name

-(NSString*)generateUniqueFileName:(NSString*)fileName;
-(NSString*)generateUniqueFolderName:(NSString*)fileName;

-(NSString*)generateUniqueFolderName:(NSString*)fileName existingFileNames:(NSSet*)existingFileNames;
-(NSString*)generateUniqueFileName:(NSString*)fileName existingFileNames:(NSSet*)existingFileNames;

@end
