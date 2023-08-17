//
//  FTENPublishManager.m
//  Noteshelf
//
//  Created by Ashok Prabhu on 7/4/14.
//
//

#import "FTENPublishManager.h"
#import "FTENSyncUtilities.h"
#import "ShelfItem.h"
#import "Page.h"
#import "ENSyncRecord.h"
#import "NoteshelfAppDelegate.h"
#import "FTShelfItemPublishRequest.h"
#import "FTPagePublishRequest.h"
#import "FTNoteshelfNotebookPublishRequest.h"
#import "FTDocumentObject.h"
#import "SyncLog.h"
#import <MessageUI/MessageUI.h>
#import "SFManager.h"
#import "Reachability.h"
#import "UIWindow_VisibleViewController.h"
#import "Noteshelf-Swift.h"

//TODO: FLURRY
/*
 Event Name: Evernote Sync Enabled {Parameter: New or Existing, From: Shelf/ Notebook}
 Event Name: Evernote Sync Disable {From: Shelf/ Notebook}
 Shelf item Published
 
 Event Name: Page published {Size: < 500KB,500KB - 1MB,1MB-2MB,>2MB} //200 Increnebts upto 2 MB
 Event Name: Unexpected Error
 
 Sync On WIFI Only
 
 CLS_LOG in sync log
*/

static dispatch_queue_t publishQueue = nil;


static FTENPublishManager *sharedPublishManager = nil;
@interface FTENPublishManager()<FTBasePublishRequestDelegate>

@property(atomic,assign) BOOL shouldCancelPublishing;
@property(nonatomic,strong) NSString *currentlyPublingNotebookId;
@property (atomic,assign) BOOL publishInProgress;

@end
@implementation FTENPublishManager
@synthesize noteshelfNotebookGuid;
@synthesize currentlyPublingNotebookId;
@synthesize managedObjectContext;
#pragma mark -
#pragma mark Public interface
+(instancetype)sharedPublishManager
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedPublishManager = [[self alloc] init];
        if(publishQueue==nil)
            publishQueue= dispatch_queue_create("com.ramki.noteshelf.evernotePublish", NULL);

    });
    return sharedPublishManager;
}

-(BOOL)evernotePublishFeaturePurchased
{
#if DEBUG || EVERNOTEDEBUG
    return YES;
#endif
    BOOL isPurchased=NO;
    isPurchased = [[NSUserDefaults standardUserDefaults]boolForKey:EVERNOTE_PUBLISH_PURCHASED];
    return isPurchased;
    
}

-(BOOL)isLoggedin
{
    return [[ENSession sharedSession] isAuthenticated];
}

-(void)promptPurchaseOfENPublishFeature:(UIViewController*)rootviewController
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"" message:NSLocalizedString(@"PurchaseEvernotePublishMessage", @"Evernote Publish") preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *action = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Evernote Publish") style:UIAlertActionStyleCancel handler:nil];
    [alertController addAction:action];
    
    UIAlertAction *action1 = [UIAlertAction actionWithTitle:NSLocalizedString(@"VisitStore", @"Visit Store") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[FTProductDescriptionManager sharedObject] showProductPageWithProductID:EVERNOTE_PUBLISH_IAP_PRODUCT_ID];
    }];
    [alertController addAction:action1];

    [rootviewController presentViewController:alertController animated:YES completion:nil];
}

-(void)startPublishing
{
    if(![self evernotePublishFeaturePurchased])
        return;//Safety check
    
    if(self.publishInProgress)
        return;
    
    //Check if logged in to Evernote
    if([[ENSession sharedSession] isAuthenticated] && [self shouldProceedWithPublishing])
    {
        self.publishInProgress=YES;

        [self executeBlockOnPublishQueue:^{
            if([self isPublishPending])
            {
                [FTENSyncUtilities recordSyncLog:@"Publish began"];
                
                [self managedObjectContext];
                [FTENSyncUtilities truncateSyncLogUpperLimitIfReachedUpperLimit];
                [self publishNextRequest];
            }
            else
                self.publishInProgress=NO;

        }];
    }
    else
    {
        if ([[NSUserDefaults standardUserDefaults] valueForKey:@"EVERNOTE_LAST_LOGIN_ALERT_TIME"])
        {
            NSTimeInterval currentTimeInterval = [NSDate timeIntervalSinceReferenceDate];
            NSTimeInterval lastAlertTimeInterval = [[NSUserDefaults standardUserDefaults] doubleForKey:@"EVERNOTE_LAST_LOGIN_ALERT_TIME"];
            if ((currentTimeInterval - lastAlertTimeInterval) > 60)
            {
                [self showAlertForReloginOnError:[NSError errorWithDomain:ENErrorDomain code:ENErrorCodeAuthExpired userInfo:nil]];
            }
        }
    }
}
-(void)cancelPublishing
{
    if (self.publishInProgress) {
        self.shouldCancelPublishing=YES;
    }
}
-(BOOL)shouldProceedWithPublishing
{
    BOOL shouldProceed=YES;
    BOOL publishOverWifiOnly=[[NSUserDefaults standardUserDefaults] boolForKey:EVERNOTE_PUBLISH_ON_WIFI_ONLY];
    Reachability *reachability=[Reachability reachabilityWithHostName:@"www.evernote.com"];
    NetworkStatus status=[reachability currentReachabilityStatus];
    
    if(publishOverWifiOnly)
    {
        //Check if we are have a valid Wi-Fi network
        if(status!=ReachableViaWiFi)
            shouldProceed=NO;
    }
    return shouldProceed;

}
-(void)loginToEvernoteWithViewController:(UIViewController*)viewController completionHandler:(genericCompletionBlockWithStatus)block
{
    ENSession *session=[ENSession sharedSession];
    [session authenticateWithViewController:viewController preferRegistration:NO
                                 completion:^(NSError *error) {
                                     
        if (error || !session.isAuthenticated)
        {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"" message:NSLocalizedString(@"EvernoteAuthenticationFailed", @"Unable to authenticate with Evernote") preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *action = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK") style:UIAlertActionStyleCancel handler:nil];
            [alertController addAction:action];
            [[[UIApplication sharedApplication].delegate window].visibleViewController presentViewController:alertController animated:YES completion:nil];
            block(NO);
        }
        else
        {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"EVERNOTE_LAST_LOGIN_ALERT_TIME"];
            block(YES);
        }
    }];
}


-(void)udpateSyncRecordsOfShelfItemWithObjectID:(NSManagedObjectID*)objectID removeDeletedPageRecords:(BOOL)deletePageRecords
{
    [self executeBlockOnPublishQueue:^{
        
        //Create a record for shelfItem if not present.
        //Create a record for each of its page if not present
        __block NSError *error=nil;
        __block ShelfItem *shelfItem=(ShelfItem *)[self.managedObjectContext existingObjectWithID:objectID error:&error];
        if(!shelfItem || error)
        {
            //Handle error case here.
            return;
        }
        
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            [FTDocumentObject documentObjectForEvenotePublish:shelfItem.uuid onCompletion:^(FTDocumentObject *notebook)
             {
                 NSMutableArray *pagesArray = [NSMutableArray array];
                 for (id<PageProtocol> eachPage in notebook.pages)
                 {
                     NSMutableDictionary *dict = [NSMutableDictionary dictionary];
                     if([eachPage nsGUID])
                     {
                         [dict setObject:[eachPage nsGUID] forKey:@"nsGUID"];
                     }

                     if([eachPage pageIndex])
                     {
                         [dict setObject:[eachPage pageIndex] forKey:@"pageIndex"];
                     }

                     if([eachPage lastUpdated])
                     {
                         [dict setObject:[eachPage lastUpdated] forKey:@"lastUpdated"];
                     }
                     [pagesArray addObject:dict];
                 }
                 //closing the document to avoid calling revert of UIDOCument while accessing the page information for evernote publish.
                 [notebook closeDocumentWithCompletionHandler:nil];
                 dispatch_semaphore_signal(semaphore);
                 
                 [self executeBlockOnPublishQueue:^{
                     
                     shelfItem = (ShelfItem *)[self.managedObjectContext existingObjectWithID:objectID error:&error];
                     if(!shelfItem || error)
                     {
                         //Handle error case here.
                         return;
                     }
                     NSString * shelfItemGUID=shelfItem.nsGUID;
                     NSPredicate *predicate=[NSPredicate predicateWithFormat:@"nsGUID==%@",shelfItemGUID];
                     ENSyncRecord *shelfItemRecord=(ENSyncRecord *)[FTENSyncUtilities fetchTopManagedObjectWithEntity:@"ENSyncRecord" predicate:predicate];
                     if(!shelfItemRecord)
                     {
                         shelfItemRecord=[NSEntityDescription insertNewObjectForEntityForName:@"ENSyncRecord" inManagedObjectContext:self.managedObjectContext];
                         shelfItemRecord.nsGUID=shelfItemGUID;
                         if(shelfItem.type.intValue==kNotebook)
                             shelfItemRecord.type=FTENSynRecordNotebook;
                         else if(shelfItem.type.intValue==kPDFDocument)
                             shelfItemRecord.type=FTENSynRecordPDF;
                     }
                     //remove from ignore list
                     [[FTENIgnoreListManager sharedIgnoreListManager] removeNotebook:shelfItemRecord.nsGUID];
                     
                     shelfItemRecord.syncEnabled=YES;
                     
                     NSMutableSet *pageGUIDs=[NSMutableSet set];
                     
                     [pagesArray enumerateObjectsUsingBlock:^(NSDictionary *pageInfo, NSUInteger idx, BOOL *stop)
                      {
                          NSString *nsGUID = [pageInfo objectForKey:@"nsGUID"];
                          NSNumber *pageIndex = [pageInfo objectForKey:@"pageIndex"];
                          NSNumber *lastUpdated = [pageInfo objectForKey:@"lastUpdated"];
                          
                          if(nsGUID)
                          {
                              [pageGUIDs addObject:nsGUID];
                              NSPredicate *predicate=[NSPredicate predicateWithFormat:@"nsGUID==%@ AND parentRecord.nsGUID==%@",nsGUID,shelfItemGUID];
                              ENSyncRecord *pageRecord=(ENSyncRecord *)[FTENSyncUtilities fetchTopManagedObjectWithEntity:@"ENSyncRecord" predicate:predicate];
                              if(!pageRecord)
                              {
                                  pageRecord=[NSEntityDescription insertNewObjectForEntityForName:@"ENSyncRecord" inManagedObjectContext:self.managedObjectContext];
                                  pageRecord.nsGUID=nsGUID;
                                  pageRecord.parentRecord=shelfItemRecord;
                                  pageRecord.lastUpdated = lastUpdated;
                                  pageRecord.index = pageIndex;
                              }
                              else
                              {
                                  //Check if it has been modified after it has been published. This can be checked by comparing the last updated date. If yes, mark it as dirty
                                  if(pageRecord.lastUpdated.doubleValue< lastUpdated.doubleValue)
                                  {
                                      pageRecord.isDirty = YES;
                                      pageRecord.isContentDirty = YES;
                                      pageRecord.lastUpdated = lastUpdated;
                                      pageRecord.index = pageIndex;
                                      
                                  }
                                  else if(pageRecord.index.integerValue!=pageIndex.integerValue) //Check if the page index is changed
                                  {
                                      pageRecord.isDirty = YES;
                                      pageRecord.index = pageIndex;
                                  }
                              }
                          }
                          else
                          {
                              NSLog(@"Page does not have nsGUID!");
                          }
                      }];
                     [self commitDataChanges];
                     if(deletePageRecords)
                     {
                         //Delete any ENSyncRecord objects whose pages are deleted
                         //Get child ENSyncRecord objects of shelfItemRecord
                         NSSet *pageRecords=[shelfItemRecord childRecords];
                         NSMutableSet *pageRecordGUIDs=[NSMutableSet set];
                         [pageRecords enumerateObjectsUsingBlock:^(ENSyncRecord *pageRecord, BOOL *stop) {
                             [pageRecordGUIDs addObject:pageRecord.nsGUID];
                         }];
                         
                         [pageRecordGUIDs minusSet:pageGUIDs];
                         //Mark the records as deleted for which there is no corresponding page object
                         [pageRecordGUIDs enumerateObjectsUsingBlock:^(NSString *pageRecordGUID, BOOL *stop) {
                             NSPredicate *predicate=[NSPredicate predicateWithFormat:@"nsGUID==%@ AND parentRecord.nsGUID==%@",pageRecordGUID,shelfItemGUID];
                             ENSyncRecord *pageRecord=(ENSyncRecord *)[FTENSyncUtilities fetchTopManagedObjectWithEntity:@"ENSyncRecord" predicate:predicate];
                             pageRecord.deleted=YES;
                             pageRecord.isDirty=YES;
                             
                         }];
                         [self commitDataChanges];
                         
                     }
                 }];
             }];
        });
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    }];
}

-(void)pageDidGetUpdated:(id<PageProtocol>)page
{
    if(page.shelfItem.enSyncEnabled)
    {
        NSString *parentGUID=page.shelfItem.nsGUID;
        NSString * pageGUID=page.nsGUID;
        NSNumber *lastUpdated=[page lastUpdated];
        NSNumber *pageIndex=[page pageIndex];
        
        NSDictionary *dict=@{@"type": [NSNumber numberWithInt:FTENSynRecordNotebook],
                             @"nsGUID": pageGUID,
                             @"parentGUID": parentGUID,
                             @"isDirty": @YES,
                             @"isContentDirty": @YES,
                             @"lastUpdated":lastUpdated,
                             @"index":pageIndex
                             };
        [[FTENPublishManager sharedPublishManager] updateSyncRecordForPageWithDict:dict
         ];
    }
    
}
-(void)shelfItemDidGetUpdated:(ShelfItem*)shelfItem
{
    NSString *nsGUID=shelfItem.nsGUID;
    if(nsGUID)
    {
        NSNumber *lastUpdated=[shelfItem lastUpdated];
        
        NSDictionary *dict=@{@"type": [NSNumber numberWithInt:FTENSynRecordNotebook],
                             @"nsGUID": nsGUID,
                             @"isDirty": @YES,
                             @"lastUpdated":lastUpdated,
                             @"syncEnabled":[NSNumber numberWithBool:shelfItem.enSyncEnabled]
                             };
        [[FTENPublishManager sharedPublishManager] updateSyncRecordForShelfWithDict:dict
         ];
    }
    
}

-(void)pageDidGetDeleted:(id<PageProtocol>)deletedPage
{
    if(deletedPage.shelfItem.enSyncEnabled)
    {
        NSDictionary *dict=@{@"deleted":@YES,
                             @"isDirty":@YES,
                             @"nsGUID":deletedPage.nsGUID};
        [self updateSyncRecordForPageWithDict:dict];
    }
}

-(void)shelfItemDidGetDeleted:(ShelfItem*)deletedShelfItem
{
    if(deletedShelfItem.nsGUID)
    {
        NSDictionary *dict=@{@"deleted":@YES,
                             @"isDirty":@YES,
                             @"nsGUID":deletedShelfItem.nsGUID};
        [self updateSyncRecordForShelfWithDict:dict];

    }
}

+(void)recordSyncLog:(NSString *)syncLog{
    
    [[FTENPublishManager sharedPublishManager] executeBlockOnPublishQueue:^{
        [FTENSyncUtilities recordSyncLog:syncLog];
    }];
}

#pragma mark-
#pragma mark Core Data related

- (void)executeBlockOnPublishQueue:(void (^)())block
{
    dispatch_async(publishQueue, ^{
        [self.managedObjectContext performBlock:block];
    });
    
}

- (NSManagedObjectContext *) managedObjectContext {
    
    if (managedObjectContext != nil) {
        return managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [APP_DELEGATE persistentStoreCoordinator];
    if (coordinator != nil) {
        managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [managedObjectContext setPersistentStoreCoordinator: coordinator];
    }
    
    managedObjectContext.undoManager = nil;
    return managedObjectContext;
}
- (void)commitDataChanges {
	
    NSError *error;
    if (![[self managedObjectContext] save:&error]) {
		// Update to handle the error appropriately.
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		exit(-1);  // Fail
    }
}

#pragma mark-
#pragma mark Publish request pipelining

-(void)publishNextRequest
{
    if(self.shouldCancelPublishing)
    {
        [self publishDidCancel];
        return;
    }
    FTBasePublishRequest *request=[self getNextPublishRequest];
    if(request)
    {
        [request startRequest];
    }
    else
    {
        //No more changes to publish. We are done here.
        [self publishDidFinish];
    }
    
    
}
-(FTBasePublishRequest*)getNextPublishRequest
{
    FTBasePublishRequest *nextRequest=nil;
    
    if([[[FTENIgnoreListManager sharedIgnoreListManager] ignoredNotebooksID] containsObject:self.currentlyPublingNotebookId])
    {
        self.currentlyPublingNotebookId = nil;
    }
    
    if(self.noteshelfNotebookGuid==nil)
    {
        nextRequest= [[FTNoteshelfNotebookPublishRequest alloc] initWithObject:nil delegate:self];
        return nextRequest;
    }
    if(!self.currentlyPublingNotebookId)
    {
        [self chooseNotebookToPublish];
    }
    if (self.currentlyPublingNotebookId)
    {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"nsGUID==%@",self.currentlyPublingNotebookId];
        ENSyncRecord *parentRecord = (ENSyncRecord *)[FTENSyncUtilities fetchTopManagedObjectWithEntity:@"ENSyncRecord" predicate:predicate];
        if(parentRecord && (!parentRecord.enGUID || parentRecord.isDirty || parentRecord.deleted))
        {
            //Publish shelfitem.
            nextRequest = [[FTShelfItemPublishRequest alloc] initWithObject:parentRecord.objectID delegate:self];

        }
        else
        {
            if(parentRecord.syncEnabled) //In case sync is disabled during publishing
            {
                //Here we need to create a request for publishing the dirty page for this notebook
                //Get the dirty page in this notebook
                predicate = [NSPredicate predicateWithFormat:@"parentRecord==%@ AND isDirty==YES",parentRecord];
                NSArray *sortDescriptors=[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES]];
                
                ENSyncRecord *pageRecord = (ENSyncRecord *)[FTENSyncUtilities fetchTopManagedObjectWithEntity:@"ENSyncRecord" predicate:predicate sortDescriptors:sortDescriptors];
                if(pageRecord)
                {
                    nextRequest = [[FTPagePublishRequest alloc]initWithObject:pageRecord.objectID delegate:self];
                    
                }
                else
                {
                    self.currentlyPublingNotebookId=nil;
                    nextRequest = [self getNextPublishRequest];
                    
                }
            }
            else
            {
                self.currentlyPublingNotebookId=nil;
                nextRequest = [self getNextPublishRequest];

            }
        }
    }
    return nextRequest;
}

-(void)publishDidCancel
{
    self.currentlyPublingNotebookId=nil;
    self.noteshelfNotebookGuid=nil;
    self.publishInProgress=NO;
    self.shouldCancelPublishing=NO;
    managedObjectContext=nil;
    [FTENSyncUtilities recordSyncLog:@"Publish did cancel"];

}
-(void)publishDidFinish
{
    self.currentlyPublingNotebookId=nil;
    self.noteshelfNotebookGuid=nil;
    self.publishInProgress=NO;
    self.shouldCancelPublishing=NO;
    managedObjectContext=nil;
    
    
    [[NSUserDefaults standardUserDefaults] setDouble:[NSDate timeIntervalSinceReferenceDate]
                                              forKey:EVERNOTE_LAST_PUBLISH_TIME];
    
    [FTENSyncUtilities recordSyncLog:@"Publish did finish"];

    
}
-(void)publishDidFail
{
    self.currentlyPublingNotebookId=nil;
    self.noteshelfNotebookGuid=nil;
    self.publishInProgress=NO;
    self.shouldCancelPublishing=NO;
    managedObjectContext=nil;
}

-(void)logPublishError:(NSError*)error
{
    BOOL continuePublish = NO;
    
    BOOL logFlurry = NO;
    BOOL showSupportAction = NO;

    NSString *failureReason=@"Unknown";
    Reachability *reachability=[Reachability reachabilityWithHostName:@"www.evernote.com"];
    NetworkStatus status=[reachability currentReachabilityStatus];
    if(status==NotReachable)
    {
        failureReason=@"Not Reachable";
    }
    else
    {
        logFlurry = YES;
        [self showAlertForReloginOnError:error];
        switch (error.code)
        {
            case ENErrorCodeUnknown:
            {
                logFlurry = YES;
                showSupportAction = YES;
               
                failureReason = @"Unknown";
            }
                break;
            case ENErrorCodeAuthExpired:
            {
                logFlurry = YES;
                
                failureReason=@"Auth Expired. Please login Again";
            }
                break;
            case ENErrorCodeInvalidData:
            {
                /*can be any one of the following:
                 EDAMErrorCode_BAD_DATA_FORMAT:
                 EDAMErrorCode_DATA_REQUIRED:
                 EDAMErrorCode_LEN_TOO_LONG:
                 EDAMErrorCode_LEN_TOO_SHORT:
                 EDAMErrorCode_TOO_FEW:
                 EDAMErrorCode_TOO_MANY:
                 */
                logFlurry = YES;
                showSupportAction = YES;
                
                NSInteger errorCode = [[error.userInfo objectForKey:@"EDAMErrorCode"] integerValue];
                failureReason=[NSString stringWithFormat:@"Invalid Data - %ld",(long)errorCode];
            }
                break;
            case ENErrorCodeNotFound:
            {
                logFlurry = YES;
                
                failureReason = @"Data not found";
            }
                break;
            case ENErrorCodePermissionDenied:
            {
                /*
                 EDAMErrorCode_INVALID_AUTH
                 EDAMErrorCode_PERMISSION_DENIED
                */
                logFlurry = YES;
                showSupportAction = YES;
                
                NSInteger errorCode = [[error.userInfo objectForKey:@"EDAMErrorCode"] integerValue];
                failureReason=[NSString stringWithFormat:@"Permission Denied - %ld",(long)errorCode];
            }
                break;
            case ENErrorCodeLimitReached:
            {
                continuePublish = YES;
                
                failureReason=@"Limit Reached";
            }
                break;
            case ENErrorCodeQuotaReached:
            {
                failureReason=@"Quota Reached";
            }
                
                break;
            case ENErrorCodeDataConflict:
            {
                logFlurry = YES;
                showSupportAction = YES;

                failureReason=@"Data conflict";
            }
                break;
            case ENErrorCodeENMLInvalid:
            {
                logFlurry = YES;
                showSupportAction = YES;
                
                failureReason=@"Permission Denied";
            }
                break;
            case ENErrorCodeRateLimitReached:
            {
                failureReason=@"Rate limit reached";
            }
                break;
            default:
                //NSURL related error codes are always negative. We would like to show a neat error. Hence going into the userinfo dict of the Evernote error and getting teh details of NSURL error.
                if(error.code<0 && [failureReason isEqualToString:@"Unknown"])
                {
                    NSDictionary *errorInfoDict=[error userInfo];
                    NSError *urlError =[errorInfoDict valueForKey:@"error"];
                    if(urlError && [urlError respondsToSelector:@selector(localizedDescription)])
                        failureReason=[urlError localizedDescription];
                    
                }
                break;
        }
        
        [[NSUserDefaults standardUserDefaults] setObject:failureReason forKey:EVERNOTE_PUBLISH_ERROR];
        [[NSUserDefaults standardUserDefaults] setBool:showSupportAction forKey:EN_PUBLISH_ERR_SHOW_SUPPORT];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    [FTENSyncUtilities recordSyncLog:[NSString stringWithFormat:@"Publish failed with reason: %@. Error: %@",failureReason,error]];
    
    if (logFlurry)
    {
        //***************************************************
        //Flurry Info
        //***************************************************
        [Flurry logEvent:@"Evernote Publish Error" withParameters:@{@"Reason":failureReason}];
        //***************************************************
        
        //***************************************************
        //Crashlytics Info
        //***************************************************
        
        CLSLog(@"Evernote Publish Error: Reason %@",failureReason);
        
        //***************************************************
    }
}

-(void)chooseNotebookToPublish
{
    //Create a publish request for any dirty shelfItem that is enabled for EN sync
    NSPredicate *predicate=[NSPredicate predicateWithFormat:@"parentRecord==nil AND isDirty==YES AND syncEnabled==YES AND deleted==NO AND (NOT (nsGUID IN %@))",[[FTENIgnoreListManager sharedIgnoreListManager] ignoredNotebooksID]];
    
    ENSyncRecord *syncRecord = (ENSyncRecord *)[FTENSyncUtilities fetchTopManagedObjectWithEntity:@"ENSyncRecord" predicate:predicate];
    if(syncRecord)
    {
        self.currentlyPublingNotebookId=syncRecord.nsGUID;
    }
    else
    {
        //Choose any ENSyncRecord that corresponds a page and is dirty and its parentrecord is enabled for sync
        NSPredicate *predicate=[NSPredicate predicateWithFormat:@"parentRecord!=nil AND parentRecord.syncEnabled==YES AND isDirty==YES AND (NOT (parentRecord.nsGUID IN %@))",[[FTENIgnoreListManager sharedIgnoreListManager] ignoredNotebooksID]];
        
        ENSyncRecord *record = (ENSyncRecord *)[FTENSyncUtilities fetchTopManagedObjectWithEntity:@"ENSyncRecord" predicate:predicate];
        if(record)
        {
            self.currentlyPublingNotebookId = record.parentRecord.nsGUID;
        }
    }
}

-(BOOL)isPublishPending
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isDirty==YES"];
    ENSyncRecord *parentRecord = (ENSyncRecord *)[FTENSyncUtilities fetchTopManagedObjectWithEntity:@"ENSyncRecord" predicate:predicate];
    return parentRecord?YES:NO;

}

#pragma mark-
#pragma mark Publish Request delegate
-(void)didCompletePublishRequestWithError:(NSError*)error
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:EVERNOTE_PUBLISH_ERROR];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:EN_PUBLISH_ERR_SHOW_SUPPORT];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"EVERNOTE_LAST_LOGIN_ALERT_TIME"];

    if(error)
    {
        [self logPublishError:error];
        [self publishDidFail];
    }
    else
    {
        [self executeBlockOnPublishQueue:^{
            [self publishNextRequest];
        }];
    }
}

-(void)didCompletePublishRequestWithIgnore:(FTENIgnoreEntry*)ignoreEntry
{
    [[FTENIgnoreListManager sharedIgnoreListManager] addIgnoreEntry:ignoreEntry];
    [self didCompletePublishRequestWithError:nil];
}

#pragma mark-
#pragma mark Sync Record related
-(void)updateSyncRecordForPageWithDict:(NSDictionary*)inDict
{
    [self executeBlockOnPublishQueue:^{
        
        //        [FTENSyncUtilities recordSyncLog:[NSString stringWithFormat:@"Modifying sync record : %@",inDict]];
        if(inDict)
        {
            NSString *nsGUID=[inDict valueForKey:@"nsGUID"];
            if(nsGUID)
            {
                NSString *parentGUID=[inDict valueForKey:@"parentGUID"];
                NSPredicate *predicate=[NSPredicate predicateWithFormat:@"nsGUID==%@ AND parentRecord.nsGUID==%@",nsGUID,parentGUID];
                
                ENSyncRecord *pageRecord=(ENSyncRecord *)[FTENSyncUtilities fetchTopManagedObjectWithEntity:@"ENSyncRecord" predicate:predicate];
                if (!pageRecord && parentGUID) {
                    pageRecord=[NSEntityDescription insertNewObjectForEntityForName:@"ENSyncRecord" inManagedObjectContext:[self managedObjectContext]];
                    
                    predicate=[NSPredicate predicateWithFormat:@"nsGUID==%@",parentGUID];
                    ENSyncRecord *parentRecord=(ENSyncRecord *)[FTENSyncUtilities fetchTopManagedObjectWithEntity:@"ENSyncRecord" predicate:predicate];
                    pageRecord.parentRecord=parentRecord;
                }
                pageRecord.nsGUID=nsGUID;
                NSString *enGUID=[inDict valueForKey:@"enGUID"];
                if(enGUID)
                    pageRecord.enGUID=enGUID;
                NSNumber *isDirty=[inDict valueForKey:@"isDirty"];
                if(isDirty)
                    pageRecord.isDirty=[isDirty boolValue];
                NSNumber *isContentDirty=[inDict valueForKey:@"isContentDirty"];
                if(isContentDirty)
                    pageRecord.isContentDirty=[isContentDirty boolValue];

                NSNumber *isDeleted=[inDict valueForKey:@"deleted"];
                if(isDeleted)
                    pageRecord.deleted=[isDeleted boolValue];
                NSNumber *type=[inDict valueForKey:@"type"];
                if(type)
                    pageRecord.type=[type intValue];
                NSNumber *lastUpdated=[inDict valueForKey:@"lastUpdated"];
                if(lastUpdated)
                    pageRecord.lastUpdated=lastUpdated;
                NSNumber *index=[inDict valueForKey:@"index"];
                if(index)
                    pageRecord.index=index;

                //remove from ignore list
                [[FTENIgnoreListManager sharedIgnoreListManager] removeNotebook:parentGUID];

                [self  commitDataChanges];
            }
        }
        
    }];

}

-(void)updateSyncRecordForShelfWithDict:(NSDictionary*)inDict
{
    [self executeBlockOnPublishQueue:^{
        if(inDict)
        {
            NSString *nsGUID=[inDict valueForKey:@"nsGUID"];
            if(nsGUID)
            {
                NSPredicate *predicate=[NSPredicate predicateWithFormat:@"nsGUID==%@",nsGUID];
                ENSyncRecord *shelfRecord=(ENSyncRecord *)[FTENSyncUtilities fetchTopManagedObjectWithEntity:@"ENSyncRecord" predicate:predicate];
                if (!shelfRecord) {
                    //We need not insert a new record if the deleted flag is set.
                    NSNumber *isDeleted=[inDict valueForKey:@"deleted"];
                    if([isDeleted boolValue])
                        return;

                    shelfRecord=[NSEntityDescription insertNewObjectForEntityForName:@"ENSyncRecord" inManagedObjectContext:[self managedObjectContext]];
                }
                shelfRecord.nsGUID=nsGUID;
                NSString *enGUID=[inDict valueForKey:@"enGUID"];
                if(enGUID)
                    shelfRecord.enGUID=enGUID;
                NSNumber *isDirty=[inDict valueForKey:@"isDirty"];
                if(isDirty)
                    shelfRecord.isDirty=[isDirty boolValue];
                NSNumber *isDeleted=[inDict valueForKey:@"deleted"];
                if(isDeleted)
                    shelfRecord.deleted=[isDeleted boolValue];
                NSNumber *type=[inDict valueForKey:@"type"];
                if(type)
                    shelfRecord.type=[type intValue];
                NSNumber *syncEnabled=[inDict valueForKey:@"syncEnabled"];
                if(syncEnabled)
                    shelfRecord.syncEnabled=[syncEnabled boolValue];
                NSNumber *lastUpdated=[inDict valueForKey:@"lastUpdated"];
                if(lastUpdated)
                    shelfRecord.lastUpdated=lastUpdated;

                [self commitDataChanges];
                //If the sync gets disabled for this shelfItem, we need to stop the publish process for this notebook.
                if([shelfRecord.nsGUID isEqualToString:self.currentlyPublingNotebookId])
                {
                    if(shelfRecord.syncEnabled==NO || shelfRecord.deleted == YES)
                        self.currentlyPublingNotebookId=nil;
                        
                }
                
                //remove from ignore list
                [[FTENIgnoreListManager sharedIgnoreListManager] removeNotebook:shelfRecord.nsGUID];

                [self startPublishing];
            }
        }
    }];
}


#pragma mark Sync Logs


-(NSString *)nsENLogPath
{
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    path = [path stringByAppendingPathComponent:@"ns-en.log"];
    return path;
}

-(void)generateSyncLog
{
    [self executeBlockOnPublishQueue:^{
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"SyncLog" inManagedObjectContext:self.managedObjectContext];
        [request setEntity:entity];
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
        [request setSortDescriptors:@[sortDescriptor]];
        NSArray *logs = [FTENSyncUtilities fetchData:request];
        
        NSString *path = [self nsENLogPath];
        [[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
        
        FILE *fileHandle;
        fileHandle = fopen ( path.UTF8String , "w" );
        if (fileHandle != NULL){
            
            __block NSString *syncLog=@"";
            
            [logs enumerateObjectsUsingBlock:^(SyncLog *log, NSUInteger idx, BOOL *stop) {
                syncLog=@"";
                syncLog=[syncLog stringByAppendingString:[NSDateFormatter localizedStringFromDate:[NSDate dateWithTimeIntervalSinceReferenceDate:log.date.longLongValue] dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterLongStyle ] ];
                
                syncLog=[syncLog stringByAppendingString:@" "];
                syncLog=[syncLog stringByAppendingString:log.log];
                syncLog=[syncLog stringByAppendingString:@"\n"];
                
                fprintf (fileHandle, "%s",[syncLog cStringUsingEncoding:NSUTF8StringEncoding]);
            }];
            fclose(fileHandle);
        }
    }];
}


-(BOOL)publishOnlyOnWifi
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:EVERNOTE_PUBLISH_ON_WIFI_ONLY];
}

-(void)showAlertForReloginOnError:(NSError*)error
{
    if (error.code == ENErrorCodeAuthExpired)
    {
        UIAlertController *alertViewController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"EvernoteAuthTokenExpiredTitle", @"Evernote Token Expired") message:nil preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *action = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel",@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action)
                                 {
                                     [alertViewController dismissViewControllerAnimated:YES completion:nil];
                                 }];
        [alertViewController addAction:action];
        
        UIAlertAction *login = [UIAlertAction actionWithTitle:NSLocalizedString(@"Login",@"Login") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
            UIViewController *controller = [APP_DELEGATE window].visibleViewController;
            [self loginToEvernoteWithViewController:controller
                                  completionHandler:^(BOOL success)
             {
                 if (success)
                 {
                     [self startPublishing];
                 }
             }];
            [alertViewController dismissViewControllerAnimated:YES completion:nil];
        }];
        [alertViewController addAction:login];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            UIViewController *controller = [APP_DELEGATE window].visibleViewController;
            [controller presentViewController:alertViewController animated:YES completion:nil];
            [[NSUserDefaults standardUserDefaults] setDouble:[NSDate timeIntervalSinceReferenceDate] forKey:@"EVERNOTE_LAST_LOGIN_ALERT_TIME"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        });
    }
}

@end
