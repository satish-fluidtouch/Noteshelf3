// Copyright @ MyScript. All rights reserved.

#import <Foundation/Foundation.h>


@class IINKEditor;

/**
 * Error code used in IINKEditorDelegate::onError:blockId:code:message:
 */
typedef NS_ENUM(NSUInteger, IINKEditorError)
{
  /** Generic error, refer to the `message` parameter for more information. */
  IINKEditorErrorGeneric,
  /** Ink was rejected, the stroke is too small. */
  IINKEditorErrorInkRejectedTooSmall,
  /** Ink was rejected, the stroke is too big. */
  IINKEditorErrorInkRejectedTooBig,
  /** Ink was rejected, the stroke is too far above the first line. */
  IINKEditorErrorInkRejectedAboveFirstLine,
  /** Ink was rejected, can not write on DIGITAL_PUBLISH blocks (convert to DIGITAL_EDIT). */
  IINKEditorErrorInkRejectedSmallTypeset,
  /** Ink was rejected, the stroke is too far left. */
  IINKEditorErrorInkRejectedBeforeFirstColumn,
  /** Ink was rejected, the stroke is out of the page bounds. */
  IINKEditorErrorInkRejectedOutOfPage,
  /** Ink was rejected, the stroke is too long. */
  IINKEditorErrorInkRejectedTooLong,
  /** Gesture notification, no words to join. */
  IINKEditorErrorGestureNotificationNoWordsToJoin,
  /** Gesture notification, cannot move above first line. */
  IINKEditorErrorGestureNotificationCannotMoveAboveFirstLine,
  /** Gesture notification, unable to apply. */
  IINKEditorErrorGestureNotificationUnableToApply,
};

/**
 * The delegate interface for receiving editor events.
 *
 * @see IINKEditor
 */
@protocol IINKEditorDelegate <NSObject>

@required

//==============================================================================
#pragma mark - Required Methods
//==============================================================================

/**
 * Invoked when the part associated with the listened editor has changed.
 *
 * @param editor the editor.
 * @see IINKEditor#setPart:(IINKContentPart)
 */
- (void)partChanged:(nonnull IINKEditor*)editor;

/**
 * Invoked when the content has changed.
 *
 * @param editor the editor.
 * @param blockIds an array of block ids that have changed.
 */
- (void)contentChanged:(nonnull IINKEditor*)editor blockIds:(nonnull NSArray<NSString *> *)blockIds;

/**
 * Invoked when an error has occurred.
 *
 * @param editor the editor.
 * @param blockId the block id on which this error has occurred.
 * @param message the error message.
 */
- (void)onError:(nonnull IINKEditor*)editor
        blockId:(nonnull NSString*)blockId
        message:(nonnull NSString*)message;

@optional

//==============================================================================
#pragma mark - Optional Methods
//==============================================================================

/**
 * Invoked when the selection has changed. The selection can be retrieved by
 * `IINKEditor:getSelection` on the editor.
 * @param editor the editor.
 *
 * @since 2.0
 */
- (void)selectionChanged:(nonnull IINKEditor *)editor;

/**
 * Invoked when the active block has changed.
 * The active block is usually the last modified text block.
 *
 * @param editor the editor.
 * @param blockId the identifier of the active block.
 */
- (void)activeBlockChanged:(nonnull IINKEditor *)editor blockId:(nonnull NSString *)blockId;

/**
 * Invoked when an error has occurred.
 *
 * @param editor the editor.
 * @param blockId the block id on which this error has occurred.
 * @param code the error code.
 * @param message the error message.
 */
- (void)onError:(nonnull IINKEditor*)editor
        blockId:(nonnull NSString*)blockId
           code:(IINKEditorError)code
        message:(nonnull NSString*)message;

@end
