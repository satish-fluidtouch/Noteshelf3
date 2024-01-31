//
//  FTDocument.h
//  FTDocumentSample
//
//  Created by Ashok Prabhu on 30/10/14.
//  Copyright (c) 2014 FluidTouch.biz. All rights reserved.
//

@class FTFileItem, FTFileItemFactory,FTSecurityModal;
@protocol FTDocumentDelegate;

#import "FTDocumentConstants.h"
#import <UIKit/UIKit.h>

/**
 `FTDocument` defines the basic Fluid Touch extensions to the UIDocument. The objective of this abstraction is reuse across all future document based apps to be developed by Fluid Touch. Clients can optionally implement the `FTDocumentDelegate` to get informed about key events related to the `FTDocument`.
 
 ## Subclassing Notes
 
 The main purpose of subclassing `FTDocument` is to define the specific structure and constituent files of the document.
 
 ## Methods to Override
 `createDefaultFileItemsForNewDocumentWithSourceURL:onCompletion:`
 `loadInitialDataForDocument`
 `fileItemFactory`
 `awakeFromTemplate`
 `thumbnailImage`
  
 */

typedef enum : NSUInteger {
    FTDocumentOpenRequestTypeFull,
    FTDocumentOpenRequestTypeUniqueID,
}FTDocumentOpenRequestType;

@interface FTDocument : UIDocument
{
    @private BOOL _shouldSecureData;
}
///---------------------------------------
/// @name Location & File Item access
///---------------------------------------

/**
 The root file item holds the entire hierarchy of file items contained in the document.
 */
@property (nonatomic, strong) FTFileItem* rootFileItem;

/**
 The full path to the document excluding the document name.
 */
@property (readonly) NSString *filePath;

/**
 The name of the document i.e. document filename without the extension.
 */
@property (readonly) NSString *documentName;

/**
 Thumbnail image of the document.
 */
@property (readonly) UIImage * _Nullable thumbnailImage;

/**
 Partial or full opening.
 */
@property (assign) FTDocumentOpenRequestType requestType;

///---------------------------------------
/// @name Document life-cycle
///---------------------------------------

/**
 Delegate is notified of any UIDocument state changes. `FTDocumentDelegate` just simplifies the `UIDocument` state change callbacks.
 */

@property (nonatomic, weak) id<FTDocumentDelegate> delegate;

/**
 Pin to secure data
 */

@property (nonatomic,strong) NSString *pin;
@property (nonatomic,strong) NSString *pinHint;

/**
 if securyty is enabled, this wil be loaded lazily
 */
@property (nonatomic,strong)FTSecurityModal *securityModal;

/**
 `FTDocument` calls this method right after the document is open. Override this method load any document data that is necessary right after the document is open. The default implementation of this method does nothing.
 */
- (void)loadInitialDataForDocument;

/**
 A convenience method that will call save on the `saveToURL:forSaveOperation:completionHandler:` on the UIDocument with UIDocumentSaveForOverwriting operation.
 
 @param completionHandler Called after save completion.
 
 */
- (void)saveWithCompletionHandler:(void (^)(BOOL success))completionHandler;


//Document status flags

///---------------------------------------
/// @name File Item management
///---------------------------------------

/**
 Returns a factory suitable for the FTDocument. Typically subclasses override this method to return custom factories specific to that document's file item types.
 */

-(FTFileItemFactory*)fileItemFactory;

/**
 The document provider (`FTDocumentProvider`) that is responsible for creating this document will call this method as soon as the 'rootFileItem' is created. Override this method to create the initial files the document should contain on creation. The default implementation of this method does nothing.
 
 @param sourceDocumentURL The URL of the PDF or template used as the base for the document creation.
 
 @param block Generic completion block to be called on completion. Subclasses should make sure this completion block is called at all times.
 
 */
-(void)createDefaultFileItemsForNewDocumentWithSourceURL:(NSURL*)sourceDocumentURL onCompletion:(GenericSuccessBlock)block;


/**
 Indicates that there are some non-undoable changes that needs to be saved
 */
@property(nonatomic,assign)BOOL hasNonUndoableChanges;

///---------------------------------------
/// @name Misc Methods
///---------------------------------------

/**
 Generate cover page image.
 
 @param completionHandler A completion handler
 */

- (void)generateCoverPageImage:(void (^)(BOOL success))completionHandler;

///---------------------------------------
/// @name Conflict resolution
///---------------------------------------

/**
 When multiple conflicting versions of the document on present on the server, the document delegate will receive a call to `documentDidReceiveConflict:conflictingVersions:`. Use this method to choose one version as the winner. This is generally done by presenting all the versions to the user and asking him/her to choose a winner.
 
 @param version The version that wins. Should be one of the elements of the conflictingVersions array propvided by the `documentDidReceiveConflict:conflictingVersions:` callback.
 
 */
- (void)resolveConflictWithVersion:(NSFileVersion*)version;

- (NSDate*)urlModificationDate;
- (NSDate*)urlCreationDate;

@end


/**
 `FTDocumentDelegate` provides a set of optional methods that can be used by clients of `FTDocument` to get notified on key events that occur in relation to the document.
 */

@protocol FTDocumentDelegate <NSObject>

@optional

/**
`FTDocument` calls this method when the document's state changes to UIDocumentStateInConflict so delegates can choose the winning version. Use `resolveConflictWithVersion:` method of the `FTDocument` to pick the winner.
 
 @param document Source document that raised this event.
 
 @param conflictingVersions An array of all conflicting versions of the document.
 */
- (void)documentDidReceiveConflict:(FTDocument*)document conflictingVersions:(NSArray*)conflictingVersions;
- (void)documentDidResolveConflict:(FTDocument*)document;

/**
 The method is called when the document is deleted for some reason.
 
 @param document Source document that raised this event.
 
 */
- (void)documentDidDelete:(FTDocument*)document;

/**
 The method is called when the document fails to save for some reason.
 
 @param document Source document that raised this event.
 
 */
- (void)documentDidFailToSave:(FTDocument*)document;


/**
 Any document state changes other than UIDocumentStateInConflict and UIDocumentStateSavingError will be posted to the delegate via this callback.
 
 @param document Source document that raised this event.
 
 @param state The new state of the document.
 */

- (void)document:(FTDocument*)document didChangeState:(UIDocumentState)state;


/**
 When document gets reloaded as a part of iCloud changes from other device, this method gets called indicating the document is about to reloaded.
 
 @param document Source document that raised this event.
 
 */
- (void)documentWillGetReloaded:(FTDocument*)document onCompletion:(void(^)())completionBLock;

/**
 When document gets reloaded as a part of iCloud changes from other device, this method gets called.
 
 @param document Source document that raised this event.
 
 */

- (void)documentDidGetReloaded:(FTDocument*)document;

-(void)documentWillGetRenamed:(FTDocument*)document;
-(void)documentDidGetRenamed:(FTDocument*)document;
-(NSInteger)currentPageDisplayed;

@end

/**
 The template additions category provides a set methods to create documents from templates.
 */

@interface FTDocument (TemplateAdditions)

//This gets called when a document is created from one of the stored templates.
//This method should be overridden to make any document specific changes that needs to be done at the time when a document is created from the template. For eg. when a new document gets created from a teamplate, it should be assigned a new documentID. Any such document specific changes should be done here.
-(void) awakeFromTemplate:(void (^)(BOOL))completionHandler;

@end

@interface FTDocument (Duplicate)
//This gets called when a document is duplicated.
//This method should be overridden to make any document specific changes that needs to be done at the time of creatting document copy (duplicate). For eg. when a new document gets created due to a copy opertation, it should be assigned a new documentID. Any such document specific changes should be done here.

- (void)prepareForDocumentCopy;

/**
 `FTDocumentProvider` calls this method when a document is copied from a template document. Override this method to make any document specific changes that needs to be done at the time when a document is created from the template. For eg. when a new document gets created from a teamplate, it should be assigned a new documentID. Any such document specific changes should be done here.
 */
-(void) awakeFromTemplate;

@end

@interface FTDocument (Rename)

-(void)documentWillGetRenamed;
-(void)documentDidGetRenamed;

@end

@interface FTDocument (Conflict)
- (NSArray*)conflictingVersions;
@end
