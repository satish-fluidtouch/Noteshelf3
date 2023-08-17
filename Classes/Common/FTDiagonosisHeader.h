//
//  FTDiagonosisHeader.h
//  Noteshelf
//
//  Created by Amar on 24/9/14.
//
//

#ifndef Noteshelf_FTDiagonosisHeader_h
#define Noteshelf_FTDiagonosisHeader_h

//Switches to enable/disable diagnosis
#if DEBUG
    #define LS_DIAGNOSIS 0
    #define COVER_THEME_DIAGNOSIS 0
    #define PAPER_THEME_DIAGNOSIS 0
    #define SHELF_THEME_DIAGNOSIS 0
    #define SHELF_REORDERING_DIAGNOSIS 1
#else
    #define LS_DIAGNOSIS 0
    #define COVER_THEME_DIAGNOSIS 0
    #define PAPER_THEME_DIAGNOSIS 0
    #define SHELF_THEME_DIAGNOSIS 0
    #define SHELF_REORDERING_DIAGNOSIS 0
#endif

//definitions of various diagnosis options

#if PAPER_THEME_DIAGNOSIS
    #define PT_LOG(s,...) NSLog(@"[Paper Themes] %@", [NSString stringWithFormat:s, ##__VA_ARGS__])
#else
    #define PT_LOG(s,...)
#endif

#if COVER_THEME_DIAGNOSIS
    #define CT_LOG(s,...) NSLog(@"[Covers Themes] %@", [NSString stringWithFormat:s, ##__VA_ARGS__])
#else
    #define CT_LOG(s,...)
#endif

#if SHELF_THEME_DIAGNOSIS
    #define ST_LOG(s,...) NSLog(@"[Shelf Themes] %@", [NSString stringWithFormat:s, ##__VA_ARGS__])
#else
    #define ST_LOG(s,...)
#endif

#if SHELF_REORDERING_DIAGNOSIS
#define SR_LOG(s,...) NSLog(@"[Shelf ReOrdering] %@", [NSString stringWithFormat:s, ##__VA_ARGS__])
#else
#define SR_LOG(s,...)
#endif

#ifdef DEBUG
    #define DEBUGLOG(...) //NSLog(__VA_ARGS__)
#else
    #define DEBUGLOG(...)
#endif

#endif
