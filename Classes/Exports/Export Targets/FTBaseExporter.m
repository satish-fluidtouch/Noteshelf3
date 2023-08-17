//
//  FTBaseExporter.m
//  Noteshelf
//
//  Created by Amar Udupa on 1/4/13.
//
//

#import "FTBaseExporter.h"

NSString *const FTCloudRootFolder = @"Noteshelf";

@implementation FTBaseExporter

@synthesize delegate;

-(id)initWithDelegate:(id<FTExporterDelegate>)inDelegate
{
    self = [super init];
    if(self)
    {
        self.delegate = inDelegate;
        self.progress = [[NSProgress alloc] init];
    }
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.progress = [[NSProgress alloc] init];
    }
    return self;
}

-(void)export
{
    //subclass should override this
}

-(NSString*)name
{
    return nil;
}

@end
