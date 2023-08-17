//
//  FTGoogleDriveImportManager.h
//  Noteshelf
//
//  Created by Amar Udupa on 18/12/13.
//
//
#if !TARGET_OS_MACCATALYST

#import <Foundation/Foundation.h>
#import "FTBaseFolderPickerManager.h"

@class GTLRDrive_File;

CG_EXTERN NSString *const GDRootItemID;

@interface FTGoogleDriveFolderPickerManager : FTBaseFolderPickerManager <FTFolderPickerUIActionDelegate>

@end
#endif
