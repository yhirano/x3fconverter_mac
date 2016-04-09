#import "X3FFileFinderUtil.h"
#import "X3fDragView.h"

@implementation X3fDragView

- (void)awakeFromNib {
    if ([[self superclass] instancesRespondToSelector:@selector(awakeFromNib)]) {
        [super awakeFromNib];
    }
    
    NSArray *parrTypes = [NSArray arrayWithObject:NSFilenamesPboardType];
    [self registerForDraggedTypes:parrTypes];
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    return NSDragOperationCopy;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    NSPasteboard *pasteboard = [sender draggingPasteboard];
    NSArray *draggedFileList = [pasteboard propertyListForType:NSFilenamesPboardType];
    
    NSArray<NSString*> *x3fFilePathList = [X3FFileFinderUtil getX3fFiles:draggedFileList];

    if ([self.delegate respondsToSelector:@selector(x3fDragView:draggedX3fFileList:)]) {
        [self.delegate x3fDragView:self draggedX3fFileList:x3fFilePathList];
    }
    
    return x3fFilePathList.count > 0;
}

@end
