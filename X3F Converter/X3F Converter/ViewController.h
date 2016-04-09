#import <Cocoa/Cocoa.h>
#import "X3fDragView.h"

@interface ViewController : NSViewController

@property (strong) IBOutlet X3fDragView *rootView;

@property (strong) IBOutlet NSView *dragMeView;

@property (weak) IBOutlet NSPopUpButton *outputFormatPopUpButton;

@property (weak) IBOutlet NSPopUpButton *colorSpacePopUpButton;

@property (weak) IBOutlet NSPopUpButton *spatialGainPopUpButton;

@property (weak) IBOutlet NSButton *denoiseCheckBox;

@property (weak) IBOutlet NSButton *compressCheckBox;

- (IBAction)selectedOutputFormat:(id)sender;

- (IBAction)selectedColorSpace:(id)sender;

- (IBAction)selectedSpatialGain:(id)sender;

- (IBAction)changeDenoise:(id)sender;

- (IBAction)changeCompress:(id)sender;

@end

