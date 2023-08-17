//
//  FTFileItemPDFTemp.m
//  Noteshelf
//
//  Created by Amar on 18/10/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

#import "FTFileItemPDFTemp.h"
@import PDFKit;

@interface FTFileItemPDFTemp()

@property (strong) PDFDocument *documentRef;
@property (strong) NSURL *sourcePDFURL;

@end

@implementation FTFileItemPDFTemp
@synthesize documentRef = _documentRef;

-(PDFDocument*)pdfDocumentRef
{
    if(!_documentRef)
    {
        _documentRef = [[PDFDocument alloc] initWithURL:self.sourcePDFURL];
        if([_documentRef isEncrypted] == true)
        {
            if (self.documentPassword.length != 0)
            {
                [_documentRef unlockWithPassword:self.documentPassword];
            }
            else
            {
                [_documentRef unlockWithPassword:@""];
            }
        }
    }
    return _documentRef;
}

- (BOOL)saveContentsOfFileItem
{
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSError *error = nil;
    [fileManager moveItemAtURL:self.sourcePDFURL toURL:self.fileItemURL error:&error];
    if(nil != error) {
        return false;
    }
    else {
        [self setSourceFileURL:self.fileItemURL];
        return true;
    }
}

-(void)setSourceFileURL:(NSURL*)inSourceURL
{
    if(![self.sourcePDFURL isEqual:inSourceURL]) {
        self.sourcePDFURL = inSourceURL;
        self.documentRef = nil;
        [self updateContent:nil];
    }
}

-(void)unloadContentsOfFileItem
{
    @synchronized(self) {
        if(!self.isModified) {
            self.documentRef = nil;
        }
    }
}

- (void)dealloc
{
    self.documentRef = nil;
}

@end
