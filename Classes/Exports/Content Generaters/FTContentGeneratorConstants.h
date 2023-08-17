//
//  FtContentGeneratorConstants.h
//  Noteshelf
//
//  Created by Amar on 18/7/14.
//
//

#ifndef Noteshelf_FtContentGeneratorConstants_h
#define Noteshelf_FtContentGeneratorConstants_h

typedef void (^FTContentGeneratorEndCallback)(BOOL completed,NSArray *exportItems);
typedef void (^FTContentGeneratorUpdateCallback)(NSString *exportMessage,CGFloat progress);

#endif
