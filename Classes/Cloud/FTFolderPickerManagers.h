//
//  FTFolderPickerManagers.h
//  Noteshelf
//
//  Created by Amar Udupa on 17/3/14.
//
//

#ifndef Noteshelf_FTFolderPickerManagers_h
#define Noteshelf_FTFolderPickerManagers_h

#import "FTItunesFolderPickerManager.h"

#if !TARGET_OS_MACCATALYST
#import "FTGoogleDriveFolderPickerManager.h"
#endif

#import "FTDropboxFolderPickerManager.h"
#import "FTEvernoteFolderPickerManager.h"
#import "FTWeLinkFolderPickerManager.h"

#endif
