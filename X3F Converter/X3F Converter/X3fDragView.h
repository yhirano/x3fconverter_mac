#import <Cocoa/Cocoa.h>

@protocol X3fDragViewDelegate;

@interface X3fDragView : NSView

@property (nonatomic, weak) id<X3fDragViewDelegate> delegate;

@end

@protocol X3fDragViewDelegate <NSObject>

@optional

- (void)x3fDragView:(X3fDragView *)view draggedX3fFileList:(NSArray<NSString*> *)filePathList;

@end