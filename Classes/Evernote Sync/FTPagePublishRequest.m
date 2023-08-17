//
//  FTPagePublishRequest.m
//  Noteshelf
//
//  Created by Ashok Prabhu on 7/4/14.
//
//

#import "FTPagePublishRequest.h"
#import "Page.h"
#import "ShelfItem.h"
#import "ENSyncRecord.h"
#import "FTENSyncUtilities.h"
#import <ENSDK/Advanced/NSDate+EDAMAdditions.h>
#import "Tag.h"
#import "FTENIgnoreListManager.h"
#import "FTDocumentObject.h"

@interface FTPagePublishRequest()
@property (strong) NSManagedObjectID *objectID;
@property (strong) FTDocumentObject *notebook;
@end

@implementation FTPagePublishRequest

-(id)initWithObject:(id)refObject delegate:(id<FTBasePublishRequestDelegate>)delegate
{
    self=[super init];
    if(self)
    {
        self.objectID=refObject;
        self.delegate = delegate;
        
    }
    return self;
}

- (void)startRequest
{
    //Check if a page needs to be created or updated in EN
    NSError *error=nil;
    ENSyncRecord *pageRecord = (ENSyncRecord *)[[self managedObjectContext] existingObjectWithID:self.objectID error:&error];
    if(!pageRecord)
    {
        [self.delegate didCompletePublishRequestWithError:error];
        return;
    }
    if(pageRecord.deleted)
        [self deleteResourceForPage:pageRecord];
    else
        [self updateResourceForPage:pageRecord];
}

-(void)pageObjectFromRecord:(ENSyncRecord*)pageRecord onCompletion:(void(^)(id<PageProtocol>))completionHandler
{
    __block id<PageProtocol> pageObjectToReturn=nil;
    //First get the parent shelfItem
    NSPredicate *predicate=[NSPredicate predicateWithFormat:@"nsGUID==%@",pageRecord.parentRecord.nsGUID];
    ShelfItem *parentShelfItem=(ShelfItem *)[FTENSyncUtilities fetchTopManagedObjectWithEntity:@"ShelfItem" predicate:predicate];
    if(parentShelfItem)
    {
        [FTDocumentObject documentObjectForEvenotePublish:parentShelfItem.uuid
                                             onCompletion:^(FTDocumentObject *document)
        {
            [self executeBlockOnPublishQueue:^{
                self.notebook = document;
                pageObjectToReturn=(id<PageProtocol> )[self.notebook pageWithNSGUID:pageRecord.nsGUID];
                if (completionHandler) {
                    completionHandler(pageObjectToReturn);
                }
            }];
        }];
    }
    else
    {
        //TODO: Need to handle this case
        if (completionHandler) {
            completionHandler(pageObjectToReturn);
        }
    }
}

-(void)deleteResourceForPage:(ENSyncRecord*)pageRecord
{
    [FTENSyncUtilities recordSyncLog:@"Deleting Page-began"];
    
    //Get the note associated with this page
    [[ENSession sharedSession].primaryNoteStore getNoteWithGuid:pageRecord.parentRecord.enGUID
                                                    withContent:YES
                                              withResourcesData:NO
                                       withResourcesRecognition:NO
                                     withResourcesAlternateData:NO
                                                        success:^(EDAMNote *note)
     {
          [self executeBlockOnPublishQueue:^{
             if(!note.active.boolValue)
             {
                 [self noteDidGetDeletedFromEvernote];
                 return;
             }
             
             NSError *error=nil;
             ENSyncRecord *pageRecord = (ENSyncRecord *)[[self managedObjectContext] existingObjectWithID:self.objectID error:&error];
             if(!pageRecord)
             {
                 [self.delegate didCompletePublishRequestWithError:error];
                 return;
             }
             
             NSMutableArray *orderedResources = [self orderedListOfResourcesFromNote:note parentGUID:pageRecord.parentRecord.nsGUID];
             
             NSMutableArray *updatedResourcesList = [NSMutableArray array];
             if(orderedResources)
                 [updatedResourcesList addObjectsFromArray:orderedResources];
             __block BOOL pageExistsOnEvernote=NO;
             __block NSUInteger index=0;
             [updatedResourcesList enumerateObjectsUsingBlock:^(EDAMResource *resourceObj, NSUInteger idx, BOOL *stop) {
                 if([resourceObj.guid isEqualToString:pageRecord.enGUID])
                 {
                     *stop=YES;
                     index=idx;
                     pageExistsOnEvernote=YES;
                 }
             }];
             if(pageExistsOnEvernote)
             {
                 [updatedResourcesList removeObjectAtIndex:index];
             }
             else
             {
                 //If page does not exist on Evernote, no point in updating it again. Just delete the sync record.
                 [self.managedObjectContext deleteObject:pageRecord];
                 [self commitDataChanges];
                 [FTENSyncUtilities recordSyncLog:[NSString stringWithFormat:@"Deleting Page-completed for notebook: %@", note.title]];
                 
                 [self.delegate didCompletePublishRequestWithError:nil];
                 return;
                 
             }
             note.resources=updatedResourcesList;
             NSString *enml=[FTENSyncUtilities enmlRepresentationWithResources:note.resources];
             
             [note setContent:[[NSString alloc] initWithFormat:EVERNOTE_NOTE_TEMPLATE,enml]];
             
             note.updated = [NSNumber numberWithLongLong:[[NSDate dateWithTimeIntervalSinceReferenceDate:pageRecord.lastUpdated.doubleValue] edamTimestamp]];
             
             [[ENSession sharedSession].primaryNoteStore updateNote:note success:^(EDAMNote *updatedNote) {
                 
                  [self executeBlockOnPublishQueue:^{
                     NSError *error=nil;
                     ENSyncRecord *pageRecord = (ENSyncRecord *)[self.managedObjectContext existingObjectWithID:self.objectID error:&error];
                     if(!pageRecord)
                     {
                         [self.delegate didCompletePublishRequestWithError:nil];//Dont return error as we want to proceed in this case. (Should never come here though!)
                         return;
                     }
                     [self.managedObjectContext deleteObject:pageRecord];
                     [self commitDataChanges];
                     [FTENSyncUtilities recordSyncLog:[NSString stringWithFormat:@"Deleting Page-completed for notebook: %@", updatedNote.title]];
                     
                     [self.delegate didCompletePublishRequestWithError:nil];
                     
                 }];
                 
             }
                                                            failure:^(NSError *error)
              {
                   [self executeBlockOnPublishQueue:^{
                      [FTENSyncUtilities recordSyncLog:[NSString stringWithFormat:@"Failed with Error:%@",error]];
                      [self.delegate didCompletePublishRequestWithError:error];
                  }];
                  
              }];
             
             
             
         }];
     }
                                                        failure:^(NSError *error)
     {
          [self executeBlockOnPublishQueue:^{
             if(error.code == ENErrorCodeNotFound)
             {
                 [self noteDidGetDeletedFromEvernote];
                 
             }
             else
             {
                 [FTENSyncUtilities recordSyncLog:[NSString stringWithFormat:@"Failed with error:%@",error]];
                 [self.delegate didCompletePublishRequestWithError:error];
                 
             }
             
         }];
     }];
}

-(NSMutableArray*)orderedListOfResourcesFromNote:(EDAMNote*)note parentGUID:(NSString*)parentGUID
{
    NSMutableArray *listOfRecords = [NSMutableArray array];
    [note.resources enumerateObjectsUsingBlock:^(EDAMResource *resource, NSUInteger idx, BOOL *stop) {
        //Get the ENSyncRecord associated with this resource. Insert this resource at that index
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"nsGUID==%@ AND parentRecord.nsGUID==%@",resource.attributes.fileName.stringByDeletingPathExtension,parentGUID];
        ENSyncRecord *record = (ENSyncRecord *)[FTENSyncUtilities fetchTopManagedObjectWithEntity:@"ENSyncRecord" predicate:predicate];
        if(record)
            [listOfRecords addObject:record];
    }];
    NSArray *sortedRecords = [listOfRecords sortedArrayUsingComparator:^NSComparisonResult(ENSyncRecord *obj1, ENSyncRecord *obj2) {
        if(obj1.index.integerValue < obj2.index.integerValue)
            return NSOrderedAscending;
        else
            return NSOrderedDescending;
    }];
    
    NSMutableArray *orderedList = [NSMutableArray array];
    [sortedRecords enumerateObjectsUsingBlock:^(ENSyncRecord *record, NSUInteger idx, BOOL *stop) {
        NSArray *filteredArray = [note.resources filteredArrayUsingPredicate:[NSPredicate  predicateWithFormat:@"attributes.fileName == %@ OR attributes.fileName == %@",record.nsGUID,[record.nsGUID stringByAppendingPathExtension:@"jpg"]]];
        if(filteredArray.firstObject)
            [orderedList addObject:filteredArray.firstObject];
    }];
    return orderedList;
}


-(void)updateResourceForPage:(ENSyncRecord*)pageRecord
{
    //Get the note associated with this page
    [[ENSession sharedSession].primaryNoteStore getNoteWithGuid:pageRecord.parentRecord.enGUID
                                       withContent:YES
                                 withResourcesData:NO
                          withResourcesRecognition:NO
                        withResourcesAlternateData:NO
                                           success:^(EDAMNote *note)
     {
          [self executeBlockOnPublishQueue:^{
             
             if(!note.active.boolValue)
             {
                 [self noteDidGetDeletedFromEvernote];
                 return;
             }
             NSError *error=nil;
             ENSyncRecord *pageRecord = (ENSyncRecord *)[[self managedObjectContext] existingObjectWithID:self.objectID error:&error];

             if(!pageRecord)
             {
                 [self.delegate didCompletePublishRequestWithError:error];
                 return;
             }
             
             NSMutableArray *orderedResources = [self orderedListOfResourcesFromNote:note parentGUID:pageRecord.parentRecord.nsGUID];
             [self pageObjectFromRecord:pageRecord onCompletion:^(id<PageProtocol> pageObject) {
                 if(!pageObject)
                 {
                     if(self.notebook)
                     {
                         [self.notebook closeDocumentWithCompletionHandler:nil];
                     }
                     [Flurry logEvent:@"Evernote Publish Error" withParameters:@{@"Reason":@"Page Not Found"}];
                     pageRecord.isDirty = NO;
                     pageRecord.isContentDirty = NO;
                     [self commitDataChanges];
                     [self.delegate didCompletePublishRequestWithError:nil];
                     return;
                 }
                 //                         __block NSNumber *lastupdated = pageObject.shelfItem.lastUpdated;
                 NSMutableArray *updatedResourcesList = [NSMutableArray array];
                 if(orderedResources)
                     [updatedResourcesList addObjectsFromArray:orderedResources];
                 __block BOOL pageExistsOnEvernote=NO;
                 __block NSUInteger index=0;
                 __block int32_t contentSizeForFlurry = 0;
                 [updatedResourcesList enumerateObjectsUsingBlock:^(EDAMResource *resourceObj, NSUInteger idx, BOOL *stop) {
                     if([resourceObj.guid isEqualToString:pageRecord.enGUID])
                     {
                         *stop=YES;
                         index=idx;
                         pageExistsOnEvernote=YES;
                     }
                 }];
                 if(pageExistsOnEvernote)
                 {
                     EDAMResource *resource=[updatedResourcesList objectAtIndex:index];
                     [updatedResourcesList removeObjectAtIndex:index];
                     if(pageRecord.isContentDirty)
                     {
                         resource=[pageObject edamResource:self.notebook];
                         contentSizeForFlurry = resource.data.size;
                     }
                     
                     if(pageRecord.index.integerValue<updatedResourcesList.count)
                     {
                         [updatedResourcesList insertObject:resource atIndex:pageRecord.index.integerValue];
                     }
                     else
                     {
                         [updatedResourcesList addObject:resource];
                     }
                 }
                 if(!pageExistsOnEvernote)
                 {
                     if(pageObject.pageIndex.integerValue < updatedResourcesList.count)
                         [updatedResourcesList insertObject:[pageObject edamResource:self.notebook] atIndex:pageObject.pageIndex.integerValue];
                     else
                         [updatedResourcesList addObject:[pageObject edamResource:self.notebook]];
                 }
                 note.resources=updatedResourcesList;
                 NSString *enml=[FTENSyncUtilities enmlRepresentationWithResources:note.resources];
                 
                 [note setContent:[[NSString alloc] initWithFormat:EVERNOTE_NOTE_TEMPLATE,enml]];
                 if(pageRecord.isContentDirty)
                 {
                     [FTENSyncUtilities recordSyncLog:[NSString stringWithFormat:@"Updating content of page (%ld of %ld) of notebook: %@", (long)(pageObject.pageIndex.integerValue+1), (unsigned long)self.notebook.pages.count, note.title]];
                     
                     note.updated = [NSNumber numberWithLongLong:[[NSDate dateWithTimeIntervalSinceReferenceDate:pageObject.shelfItem.lastUpdated.doubleValue] edamTimestamp]];
                     
                 }
                 else
                 {
                     [FTENSyncUtilities recordSyncLog:[NSString stringWithFormat:@"Updating page (Content not modified) (%ld of %ld) of notebook: %@", (long)(pageObject.pageIndex.integerValue+1), (unsigned long)self.notebook.pages.count, note.title]];
                     
                 }
                 
                 //Before updating the note, we set the isDirty flag to NO. if the update fails we reset it back to YES.
                 pageRecord.isDirty=NO;
                 __block BOOL pageContentWasDirty = pageRecord.isContentDirty;
                 pageRecord.isContentDirty = NO;
                 
                 [self commitDataChanges];
                 
                 ////////////////////////////////////////
                 //Publish tags to Evernote
                 ////////////////////////////////////////
                 NSMutableSet *tags = [NSMutableSet set];
                 for (NSString *tag in [pageObject tagNames])
                 {
                     [tags addObject:tag];
                 }
                 [tags addObjectsFromArray:note.tagNames];
                 note.tagNames = tags.allObjects.mutableCopy;
                 ////////////////////////////////////////
                 [self.notebook closeDocumentWithCompletionHandler:nil];
                 [[ENSession sharedSession].primaryNoteStore updateNote:note success:^(EDAMNote *updatedNote) {
                     
                      [self executeBlockOnPublishQueue:^{
                         NSError *error=nil;
                         ENSyncRecord *pageRecord = (ENSyncRecord *)[[self managedObjectContext] existingObjectWithID:self.objectID error:&error];
                         if(!pageRecord)
                         {
                             [self.delegate didCompletePublishRequestWithError:error];
                             return;
                         }
                         if(pageContentWasDirty)
                             [FTENSyncUtilities recordSyncLog:@"Updating page-completed"];
                         
                         
                         [self updateResourceGUIDsOfNote:updatedNote];
                         [self commitDataChanges];
                         [self.delegate didCompletePublishRequestWithError:nil];
                         
                         //***************************************************
                         //Flurry Info
                         //***************************************************
                         NSString *sizeRangeString = [self sizeRangeStringForContentSize:contentSizeForFlurry];
                         
                         dispatch_async(dispatch_get_main_queue(), ^{
                             if(pageContentWasDirty)
                             {
                                 if(sizeRangeString)
                                     [Flurry logEvent:@"Evernote Page Published" withParameters:@{@"Size":sizeRangeString}];
                                 
                             }
                         });
                         //***************************************************
                         
                         
                     }];
                     
                 }
                                                                failure:^(NSError *error)
                  {
                       [self executeBlockOnPublishQueue:^{
                          
                          [FTENSyncUtilities recordSyncLog:[NSString stringWithFormat:@"Failed to update page with error:%@",error]];
                          
                          NSError *error2=nil;
                          ENSyncRecord *pageRecord = (ENSyncRecord *)[[self managedObjectContext] existingObjectWithID:self.objectID error:&error2];
                          pageRecord.isDirty=YES;
                          if(pageContentWasDirty)
                              pageRecord.isContentDirty = pageContentWasDirty;
                          [self commitDataChanges];
                          
                          if (error.code == ENErrorCodeLimitReached)
                          {
                              ShelfItem *shelfItem = [self shelfItemForNotebookID:pageRecord.parentRecord.nsGUID];
                              FTENIgnoreEntry *entry = [[FTENIgnoreEntry alloc] init];
                              entry.title = shelfItem.title;
                              entry.notebookID = pageRecord.parentRecord.nsGUID;
                              entry.ignoreType = FTENIgnoreReasonTypeDataLimitReached;
                              [self.delegate didCompletePublishRequestWithIgnore:entry];
                          }
                          else
                          {
                              [self.delegate didCompletePublishRequestWithError:error];
                          }
                          
                      }];
                      
                  }];
             }];
             
         }];
     }
     
                                           failure:^(NSError *error) {
                                                [self executeBlockOnPublishQueue:^{
                                                   if(error.code == ENErrorCodeNotFound)
                                                   {
                                                       [self noteDidGetDeletedFromEvernote];
                                                       
                                                   }
                                                   else
                                                   {
                                                       [FTENSyncUtilities recordSyncLog:[NSString stringWithFormat:@"Failed with error:%@",error]];
                                                       [self.delegate didCompletePublishRequestWithError:error];
                                                   }
                                               }];
                                           }];
}

-(void)noteDidGetDeletedFromEvernote
{
    [FTENSyncUtilities recordSyncLog:@"Note got deleted from Evernote. Preparing to send all pages for this notebook"];
    
    NSError *error=nil;
    ENSyncRecord *pageRecord = (ENSyncRecord *)[[self managedObjectContext] existingObjectWithID:self.objectID error:&error];
    if(!pageRecord)
    {
        [self.delegate didCompletePublishRequestWithError:error];
        return;
    }
    ENSyncRecord * parentRecord=pageRecord.parentRecord;
    parentRecord.enGUID=nil;
    parentRecord.isDirty=YES;
    NSPredicate *predicate=[NSPredicate predicateWithFormat:@"parentRecord==%@",parentRecord];
    NSArray *childRecords=[FTENSyncUtilities fetchItemsWithEntity:@"ENSyncRecord" predicate:predicate];
    [childRecords enumerateObjectsUsingBlock:^(ENSyncRecord *childRecord, NSUInteger idx, BOOL *stop) {
        childRecord.enGUID=nil;
        childRecord.isDirty=YES;
        childRecord.isContentDirty=YES;
    }];
    [self commitDataChanges];
    [self.delegate didCompletePublishRequestWithError:nil]; //Publish should continue
    
}

- (void)updateResourceGUIDsOfNote:(EDAMNote *)note
{
    //Go through each resource and update its guid to the corresponding DayPhoto object's guid.
    [[note resources] enumerateObjectsUsingBlock:^(EDAMResource *obj, NSUInteger idx, BOOL *stop)
     {
         //since the EDAMResource filename is made as nsGUID, no need of querying again the server. we can retrieve the dnGuid directly by accessing the filename.
         NSString *fileName = obj.attributes.fileName;
         NSString *enNSGUID = fileName.stringByDeletingPathExtension;
         NSArray *results=[FTENSyncUtilities fetchItemsWithEntity:@"ENSyncRecord" predicate:[NSPredicate predicateWithFormat:@"(nsGUID==%@)",enNSGUID]];
         if(results.count)
         {
             ENSyncRecord *pageObjectRecord=results.firstObject;
             pageObjectRecord.enGUID=obj.guid;
         }
     }];
    [self commitDataChanges];
    
}

-(NSString *)sizeRangeStringForContentSize:(int32_t)pageSize
{
    NSString *sizeRangeString = nil;
    if(pageSize >0 && pageSize <= 200*1024)
        sizeRangeString = @"0-200KB";
    else if(pageSize >200*1024 && pageSize <= 400*1024)
        sizeRangeString = @"200-400KB";
    else if(pageSize >400*1024 && pageSize <= 600*1024)
        sizeRangeString = @"400-600KB";
    else if(pageSize >600*1024 && pageSize <= 800*1024)
        sizeRangeString = @"600-800KB";
    else if(pageSize >800*1024 && pageSize <= 1000*1024)
        sizeRangeString = @"800KB-1MB";
    else if(pageSize >1000*1024 && pageSize <= 1200*1024)
        sizeRangeString = @"1MB-1.2MB";
    else if(pageSize >1200*1024 && pageSize <= 1400*1024)
        sizeRangeString = @"1.2MB-1.4MB";
    else if(pageSize >1400*1024 && pageSize <= 1600*1024)
        sizeRangeString = @"1.4MB-1.6MB";
    else if(pageSize >1600*1024 && pageSize <= 1800*1024)
        sizeRangeString = @"1.6MB-1.8MB";
    else if(pageSize >1800*1024 && pageSize <= 2000*1024)
        sizeRangeString = @"1.8MB-2MB";
    else if(pageSize >2000*1024)
        sizeRangeString = @">2MB";



    return sizeRangeString;
}

-(ShelfItem*)shelfItemForNotebookID:(NSString*)notebookID
{
    NSPredicate *predicate=[NSPredicate predicateWithFormat:@"nsGUID==%@",notebookID];
    ShelfItem *parentShelfItem=(ShelfItem *)[FTENSyncUtilities fetchTopManagedObjectWithEntity:@"ShelfItem" predicate:predicate];
    return parentShelfItem;
}
@end
