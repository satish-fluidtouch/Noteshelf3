//
//  PressurePenEngine.m
//  Noteshelf
//
//  Created by Rama Krishna on 9/27/12.
//
//
#import "PressurePenEngine.h"
#import "SynthesizeSingleton.h"
#import "Noteshelf-Swift.h"


@implementation PressurePenEngine

SYNTHESIZE_SINGLETON_FOR_CLASS(PressurePenEngine)

@synthesize delegate;

@synthesize enabledPenName;


#pragma mark - Lifecycle

- (id)init{
    if ((self = [super init])) {
        //Set the defaults all the supported pens
        [self registerDefaults];
        [self updateDefaults];
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector:@selector(writingStyleChanged:)
                                                     name: @"FTWritingStyleChanged"
                                                   object:nil];
    }
    
    return self;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - Start, Stop, Refresh

-(void)start{

    if (self.applePencilEnabled) {
        [delegate pressurePenAvailable:@"Apple Pencil"];
    }
}

-(void)stop{
}


-(void)refresh{
    //This is called when some setting is changed
    if ([NSUserDefaults isApplePencilEnabled] && !self.applePencilEnabled) {
        [delegate pressurePenAvailable:@"Apple Pencil"];
    }
    else if(self.applePencilEnabled && ![NSUserDefaults isApplePencilEnabled])
    {
        [delegate pressurePenNotAvailable:@"Apple Pencil"];
    }
    [self updateDefaults];
}


-(BOOL)pressurePenWristProtectionActive
{
    BOOL wristProtectionActive=NO;
    
    return wristProtectionActive;
}

-(void)writingStyleChanged:(NSNotification *) note
{

}

#pragma mark - Public Helpers

-(StylusType)enabledStylusType
{
    if([NSUserDefaults isApplePencilEnabled])
    {
        return kStylusApplePencil;
    }
    return kStylusFinger;

}

-(BOOL)isAnyStylusConnected
{
    BOOL isStylusConnected = false;
    if([NSUserDefaults isApplePencilEnabled]) //Apple Pencil
    {
        isStylusConnected = true;
    }
    return isStylusConnected;
}

-(NSString *)enabledPenName{
    return nil;
}

+(NSString *)titleForButtonAction:(RKAccessoryButtonAction)buttonAction{

    switch (buttonAction) {
        case kAccessoryButtonActionNone:
            return NSLocalizedString(@"ButtonActionNone", @"No Action");
            break;
        case kAccessoryButtonActionUndo:
            return NSLocalizedString(@"ButtonActionUndo", @"Undo");
            break;
        case kAccessoryButtonActionRedo:
            return NSLocalizedString(@"ButtonActionRedo", @"Redo");
            break;
        case kAccessoryButtonActionNextColor:
            return NSLocalizedString(@"ButtonActionNextColor", @"NextColor");
            break;
        case kAccessoryButtonActionPrevColor:
            return NSLocalizedString(@"ButtonActionPreviousColor", @"Previous Color");
            break;
        case kAccessoryButtonActionNextPage:
            return NSLocalizedString(@"ButtonActionNextPage", @"Next Page");
            break;
        case kAccessoryButtonActionPrevPage:
            return NSLocalizedString(@"ButtonActionPreviousPage", @"Previous Page");
            break;
    }
}
#pragma mark - Private Helpers

-(void)peformAccessoryButtonAction:(NSNumber *)action{
    [delegate pressurePenButtonAction:[action intValue]];
}

-(void)registerDefaults
{
}

-(void)updateDefaults
{
    self.applePencilEnabled = [NSUserDefaults isApplePencilEnabled];
}

@end
