//
//  NavigationControllerForFormSheet.m
//  Noteshelf
//
//  Created by Rama Krishna on 5/4/13.
//
//

#import "NavigationControllerForFormSheet.h"

@interface NavigationControllerForFormSheet ()

@end

@implementation NavigationControllerForFormSheet

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (BOOL)disablesAutomaticKeyboardDismissal {
    
    return NO;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
