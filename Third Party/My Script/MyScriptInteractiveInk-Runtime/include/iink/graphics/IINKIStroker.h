// Copyright @ MyScript. All rights reserved.

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <iink/graphics/IINKIPath.h>


/**
 * Represents an ink point.
 */
typedef struct _IINKPoint
{
  /** The point x coordinate. */
  float x;
  /** The point y coordinate. */
  float y;
  /** The point timestamp. */
  int64_t t;
  /** The point normalised pressure. */
  float f;
} IINKPoint;


/**
 * The stroker interface.
 */
@protocol IINKIStroker <NSObject>

@required

//==============================================================================
#pragma mark - Required Methods
//==============================================================================

/**
 * Tells whether stroked input should be drawn as a filled shaped or not.
 *
 * @return `YES` if strokes are to be filled, otherwise `NO`.
 */
- (BOOL)isFill;

/**
 * Constructs a visual stroke from input points.
 *
 * @param input the input points.
 * @param count the count of input points.
 * @param width the desired stroke width.
 * @param pixelSize the viewport pixel size.
 * @param output the resulting stroke.
 */
- (void)stroke:(nonnull IINKPoint *)input
         count:(NSInteger)count
         width:(float)width
     pixelSize:(float)pixelSize
        output:(nonnull id<IINKIPath>)output;

@end
