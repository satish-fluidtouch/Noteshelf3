//
//  ENSyncRecord.m
//  Noteshelf
//
//  Created by Ashok Prabhu on 11/4/14.
//
//

#import "ENSyncRecord.h"
#import "ENSyncRecord.h"

#define BUSINESS_NOTEBOOK_ID_PREFIX @"##BUS##"

@implementation ENSyncRecord

@dynamic nsGUID;
@dynamic enGUID;
@dynamic isDirty;
@dynamic isContentDirty;
@dynamic deleted;
@dynamic type;
@dynamic syncEnabled;
@dynamic parentRecord;
@dynamic childRecords;
@dynamic lastUpdated;
@dynamic index;
@dynamic url;

//////////////////////
//The below methods have been written to accommodate a new data field "isBusinessNote"
//We did not want to change the core data model, so we are using this enGUID field to store this info as well
//////////////////////

-(void)setEnGUID:(NSString *)newEnGUID{
    
    //Get the current primitive value
    [self willAccessValueForKey:@"enGUID"];
    NSString *currentPrimitiveValue = [self primitiveValueForKey:@"enGUID"];
    [self didChangeValueForKey:@"enGUID"];
    
    //Just set the actual GUID if current primitive value is nil
    if (!currentPrimitiveValue){
     
        [self willChangeValueForKey:@"enGUID"];
        [self setPrimitiveValue:newEnGUID forKey:@"enGUID"];
        [self didChangeValueForKey:@"enGUID"];
        return;
    }
    
    //Copy over the current prefix to the new GUID value
    [self willChangeValueForKey:@"enGUID"];
    if ([currentPrimitiveValue hasPrefix:BUSINESS_NOTEBOOK_ID_PREFIX]) {
        if(nil == newEnGUID) {
            newEnGUID = @"";
        }
        [self setPrimitiveValue:[BUSINESS_NOTEBOOK_ID_PREFIX stringByAppendingString:newEnGUID] forKey:@"enGUID"];
    }else{
        
        //Continue with no prefix if there is no prefix currently
        [self setPrimitiveValue:newEnGUID forKey:@"enGUID"];
    }
    [self didChangeValueForKey:@"enGUID"];
}

-(NSString *)enGUID{

    //Get the primitive value
    [self willAccessValueForKey:@"enGUID"];
    NSString *primitiveValue = [self primitiveValueForKey:@"enGUID"];
    [self didChangeValueForKey:@"enGUID"];

    //Return nil if primitive value itself is nil
    if(!primitiveValue) return nil;
    
    //Get the actual value by stripping the prefix
    NSString *actualGUID = primitiveValue;
    actualGUID = [actualGUID stringByReplacingOccurrencesOfString:BUSINESS_NOTEBOOK_ID_PREFIX withString:@""];
    
    //Return nil of no guid exists
    return actualGUID.length ? actualGUID : nil;
    
}

-(void)setIsBusinessNote:(BOOL)newIsBusinessNote
{
    //Get the current primitive value
    [self willAccessValueForKey:@"enGUID"];
    NSString *currentPrimitiveValue = [self primitiveValueForKey:@"enGUID"];
    [self didChangeValueForKey:@"enGUID"];

    //Just set the prefix values if primitive value is nil
    if(!currentPrimitiveValue)
    {
        if (newIsBusinessNote)
        {
            [self willChangeValueForKey:@"enGUID"];
            [self setPrimitiveValue:BUSINESS_NOTEBOOK_ID_PREFIX forKey:@"enGUID"];
            [self didChangeValueForKey:@"enGUID"];
        }
        return;
    }
    
    //Get the actual value by stripping the prefix
    NSString *actualGUID = currentPrimitiveValue;
    actualGUID = [actualGUID stringByReplacingOccurrencesOfString:BUSINESS_NOTEBOOK_ID_PREFIX withString:@""];
    
    //Set the prefix accordingly
    [self willChangeValueForKey:@"enGUID"];
    if (newIsBusinessNote)
    {
        [self setPrimitiveValue:[BUSINESS_NOTEBOOK_ID_PREFIX stringByAppendingString:actualGUID] forKey:@"enGUID"];
    }else{
        [self setPrimitiveValue:actualGUID forKey:@"enGUID"];
    }
    [self didChangeValueForKey:@"enGUID"];
}

-(BOOL)isBusinessNote
{
    if (nil != self.parentRecord) {
        return [self.parentRecord isBusinessNote];
    }
    //Get the primitive value
    [self willAccessValueForKey:@"enGUID"];
    NSString *primitiveValue = [self primitiveValueForKey:@"enGUID"];
    [self didChangeValueForKey:@"enGUID"];

    //Anything other than business prefix is not a business notebook including nil
    if([primitiveValue hasPrefix:BUSINESS_NOTEBOOK_ID_PREFIX])
        return YES;
    else
        return NO;
}
#if !TARGET_OS_MACCATALYST
- (EDAMNoteStoreClient *)noteStoreClient {
    EvernoteSession *evernoteSession = [EvernoteSession sharedSession];
    return self.isBusinessNote ? evernoteSession.businessNoteStore : evernoteSession.noteStore;
}
#endif

-(BOOL)isDeleted
{
    return self.deleted;
}

@end
