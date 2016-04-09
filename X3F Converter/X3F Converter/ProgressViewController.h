#import <Cocoa/Cocoa.h>

@protocol ProgressViewControllerDelegate;

@interface ProgressViewController : NSViewController

@property (nonatomic, weak) id<ProgressViewControllerDelegate> delegate;

@property (weak) IBOutlet NSProgressIndicator *progressIndicator;

- (IBAction)tappedCancelButton:(id)sender;

@end

@protocol ProgressViewControllerDelegate <NSObject>

@optional

- (void)cancelWithProgressViewController:(ProgressViewController *)viewController;

@end