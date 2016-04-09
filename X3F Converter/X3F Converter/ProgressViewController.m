#import "ProgressViewController.h"

@interface ProgressViewController ()

@end

@implementation ProgressViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [_progressIndicator startAnimation:self];
}

- (IBAction)tappedCancelButton:(id)sender {
    if ([self.delegate respondsToSelector:@selector(cancelWithProgressViewController:)]) {
        [self.delegate cancelWithProgressViewController:self];
    }
}
@end
