//
//  NSString_Backup_Additions.m
//  Noteshelf
//
//  Created by Amar on 15/3/16.
//
//

#import "NSString_Backup_Additions.h"

@implementation NSString (Backup_Additions)

-(NSString*)validateFileName
{
    NSString *docName = [[self componentsSeparatedByCharactersInSet:[NSCharacterSet controlCharacterSet]] componentsJoinedByString:@" "];

    NSString *extentsion = docName.pathExtension;
    docName = [docName stringByDeletingPathExtension];

    docName = [docName stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
    docName = [docName stringByReplacingOccurrencesOfString:@"." withString:@"" options:NSAnchoredSearch range:NSMakeRange(0, docName.length)];
    
    //doc name cannot be greater than 240 charecters
    if (docName.length > 240) {
        NSRange range = [docName rangeOfComposedCharacterSequenceAtIndex:240];
        docName = [docName substringToIndex:range.location];
    }
    
    if(docName.length == 0) {
        docName = NSLocalizedString(@"Untitled", @"Untitled");
    }

    //Doc name cannot have leading or trailing whitespaces
    docName=[docName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    docName = [docName stringByAppendingPathExtension:extentsion];

    return docName;
}

@end
