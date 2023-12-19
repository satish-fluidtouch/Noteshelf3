// Copyright @ MyScript. All rights reserved.

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

/**
 * Describes the types of pointer that can be used for input.
 */
typedef NS_ENUM(NSUInteger, IINKPointerType)
{
  /** The pointer is a pen. */
  IINKPointerTypePen     = 0,
  /** The pointer is a touch point. */
  IINKPointerTypeTouch   = 1,
  /** The pointer is an eraser. */
  IINKPointerTypeEraser  = 2,
  /** The pointer is a mouse. */
  IINKPointerTypeMouse   = 3,
  /** The pointer is Custom. */
  IINKPointerTypeCustom1 = 4,
  /** The pointer is Custom. */
  IINKPointerTypeCustom2 = 5,
  /** The pointer is Custom. */
  IINKPointerTypeCustom3 = 6,
  /** The pointer is Custom. */
  IINKPointerTypeCustom4 = 7,
  /** The pointer is Custom. */
  IINKPointerTypeCustom5 = 8
};

/**
 * Describes the types of pointer event that can be provided to the editor.
 */
typedef NS_ENUM(NSUInteger, IINKPointerEventType)
{
  /** A pointer down event. */
  IINKPointerEventTypeDown,
  /** A pointer move event. */
  IINKPointerEventTypeMove,
  /** A pointer up event. */
  IINKPointerEventTypeUp,
  /** A pointer cancel event. */
  IINKPointerEventTypeCancel
};

/**
 * Represents a pointer event.
 */
typedef struct _IINKPointerEvent
{
  /** The event type. */
  IINKPointerEventType eventType;
  /** The event x coordinate. */
  float x;
  /** The event y coordinate. */
  float y;
  /** The event timestamp in ms since Unix EPOCH, or -1. */
  int64_t t;
  /** The event normalised pressure. */
  float f;
  /** The type of input pointer. */
  IINKPointerType pointerType;
  /** The id of the pointer. */
  int pointerId;
} IINKPointerEvent;

CG_INLINE IINKPointerEvent
IINKPointerEventMake(IINKPointerEventType eventType,
                     CGPoint point, int64_t t, float f,
                     IINKPointerType pointerType, int pointerId)
{
  IINKPointerEvent e;
  e.eventType = eventType;
  e.x = (float)point.x;
  e.y = (float)point.y;
  e.t = t;
  e.f = f;
  e.pointerType = pointerType;
  e.pointerId = pointerId;
  return e;
}

CG_INLINE IINKPointerEvent
IINKPointerEventMakeDown(CGPoint point, int64_t t, float f,
                         IINKPointerType pointerType, int pointerId)
{
  return IINKPointerEventMake(IINKPointerEventTypeDown, point, t, f, pointerType, pointerId);
}

CG_INLINE IINKPointerEvent
IINKPointerEventMakeMove(CGPoint point, int64_t t, float f,
                         IINKPointerType pointerType, int pointerId)
{
  return IINKPointerEventMake(IINKPointerEventTypeMove, point, t, f, pointerType, pointerId);
}

CG_INLINE IINKPointerEvent
IINKPointerEventMakeUp(CGPoint point, int64_t t, float f,
                       IINKPointerType pointerType, int pointerId)
{
  return IINKPointerEventMake(IINKPointerEventTypeUp, point, t, f, pointerType, pointerId);
}

CG_INLINE IINKPointerEvent
IINKPointerEventMakeCancel(int pointerId)
{
  return IINKPointerEventMake(IINKPointerEventTypeCancel, CGPointMake(0, 0), -1, 0, (IINKPointerType)0, pointerId);
}


/**
 * Wrapper object for an `IINKPointerEvent` value.
 */
@interface IINKPointerEventValue : NSObject
{

}

@property (nonatomic) IINKPointerEvent value;

/**
 * Create a new `IINKPointerEventValue` instance.
 * @param value the pointer event value.
 */
- (nullable instancetype)initWithValue:(IINKPointerEvent)value;

/**
 * Builds a new `IINKPointerEventValue` instance.
 * @param value the pointer event value.
 */
+ (nonnull IINKPointerEventValue *)valueWithPointerEvent:(IINKPointerEvent)value;

@end
