#import "AppDelegate.h"
#import "ProgressViewController.h"
#import "ViewController.h"

typedef enum : NSUInteger {
    Jpeg = 0, Dng, Tiff
} OutputFileFormat;

typedef enum : NSUInteger {
    None = 0, sRGB, AdobeRGB, ProPhotoRGB
} ColorSpace;

typedef enum : NSUInteger {
    Auto = 0, Apply, DontApply
} Gain;

static NSString * const USER_DEFAULT_KEY_OUTPUT_FORMAT = @"USER_DEFAULT_KEY_OUTPUT_FORMAT";
static NSString * const USER_DEFAULT_KEY_COLOR_SPACE = @"USER_DEFAULT_KEY_COLOR_SPACE";
static NSString * const USER_DEFAULT_KEY_GAIN = @"USER_DEFAULT_KEY_GAIN";
static NSString * const USER_DEFAULT_KEY_DENOISE = @"USER_DEFAULT_KEY_DENOISE";
static NSString * const USER_DEFAULT_KEY_COMPRESS = @"USER_DEFAULT_KEY_COMPRESS";

@interface ViewController () <X3fDragViewDelegate, ProgressViewControllerDelegate>

@end

@implementation ViewController
{
    OutputFileFormat _outputFileFormat;

    ColorSpace _colorSpace;
    
    Gain _gain;
    
    BOOL _denoise;
    
    BOOL _compress;
    
    ProgressViewController *_progressDialog;
    
    NSMutableArray<NSTask *>* _convertRemainTasks;
    
    NSUInteger _convertWholeTaskCount;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_KEY_OPEN_FILES object:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _rootView.delegate = self;

    // Restore user setting.
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    _outputFileFormat = [userDefaults integerForKey:USER_DEFAULT_KEY_OUTPUT_FORMAT];
    _colorSpace = [userDefaults integerForKey:USER_DEFAULT_KEY_COLOR_SPACE];
    _gain = [userDefaults integerForKey:USER_DEFAULT_KEY_GAIN];
    if ([userDefaults objectForKey:USER_DEFAULT_KEY_DENOISE]) {
        _denoise = [userDefaults boolForKey:USER_DEFAULT_KEY_DENOISE];
    } else {
        _denoise = YES;
    }
    if ([userDefaults objectForKey:USER_DEFAULT_KEY_COMPRESS]) {
        _compress = [userDefaults boolForKey:USER_DEFAULT_KEY_COMPRESS];
    } else {
        _compress = YES;
    }
    
    [_outputFormatPopUpButton selectItemAtIndex:_outputFileFormat];
    [self updateOutputFormat:_outputFileFormat];

    [_colorSpacePopUpButton selectItemAtIndex:_colorSpace];
    [self updateColorSpace:_colorSpace];

    [_spatialGainPopUpButton selectItemAtIndex:_gain];
    [self updateSpatialGain:_gain];

    [_denoiseCheckBox setState:_denoise ? NSOnState : NSOffState];
    [self updateDenoise:_denoise];
    
    [_compressCheckBox setState:_compress ? NSOnState : NSOffState];
    [self updateCompress:_compress];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(openFiles:)
                                                 name:NOTIFICATION_KEY_OPEN_FILES
                                               object:nil];
}

- (void)viewWillAppear {
    [super viewWillAppear];

    _dragMeView.wantsLayer = YES;
    _dragMeView.layer.backgroundColor = [NSColor colorWithRed:0.4f green:0.4f blue:0.4f alpha:1].CGColor;
    _dragMeView.layer.cornerRadius = 5.0f;

    [_spatialGainPopUpButton setToolTip:@"Apply spatial gain (color compensation)"];
    [_denoiseCheckBox setToolTip:@"Denoise RAW data"];
    [_compressCheckBox setToolTip:@"Enable ZIP compression for DNG and TIFF output"];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
}

#pragma mark - Action

- (IBAction)selectedOutputFormat:(id)sender {
    [self updateOutputFormat:[sender selectedItem].tag];
}

- (IBAction)selectedColorSpace:(id)sender {
    [self updateColorSpace:[sender selectedItem].tag];
}

- (IBAction)selectedSpatialGain:(id)sender {
    [self updateSpatialGain:[sender selectedItem].tag];
}

- (IBAction)changeDenoise:(id)sender {
    [self updateDenoise:[sender state] == NSOnState];
}

- (IBAction)changeCompress:(id)sender {
    [self updateCompress:[sender state] == NSOnState];
}

#pragma mark - Notification

- (void)openFiles:(NSNotification *)notification {
    NSArray<NSString*> *fileNames = [notification object];
    [self convertX3f:fileNames];
}

#pragma mark - X3fDragViewDelegate

- (void)x3fDragView:(X3fDragView *)view draggedX3fFileList:(NSArray<NSString*> *)filePathList {
    [self convertX3f:filePathList];
}

#pragma mark - ProgressViewControllerDelegate

- (void)cancelWithProgressViewController:(ProgressViewController *)viewController {
    for (NSTask *task in _convertRemainTasks) {
        task.terminationHandler = nil;
        if ([task isRunning]) {
            [task interrupt];
        }
    }
    [_convertRemainTasks removeAllObjects];
    
    [viewController dismissController:viewController];
}

#pragma mark - Private methods

- (void)convertX3f:(NSArray<NSString*> *)filePathList {
    if (filePathList == nil || filePathList.count <= 0) {
        return;
    }
    
    _convertRemainTasks = [NSMutableArray arrayWithCapacity:filePathList.count];
    _convertWholeTaskCount = filePathList.count;
    
    _progressDialog = [self.storyboard instantiateControllerWithIdentifier:@"ProgressViewController"];
    _progressDialog.delegate = self;
    [self presentViewControllerAsSheet:_progressDialog];
    
    for (NSString *filePath in filePathList) {
        // Remove temporary file if exist, because couse erro if remain temporary file.
        [[self class] removeTempFileWithInputFilePath:filePath outputFileFormat:_outputFileFormat];
        
        NSTask *task = [self createConvertX3f:filePath];
        task.terminationHandler = ^(NSTask *task) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [_convertRemainTasks removeObject:task];
                if (_convertRemainTasks.count <= 0) {
                    [_progressDialog dismissController:_progressDialog];
                }
                [_progressDialog.progressIndicator incrementBy:(1.0 / _convertWholeTaskCount) * 100];
                
                [_convertRemainTasks.firstObject launch];
            });
        };
        [_convertRemainTasks addObject:task];
    }
    
    [_convertRemainTasks.firstObject launch];
}

- (NSTask *)createConvertX3f:(NSString *)filePath {
    NSString *x3fExtractPath = [[NSBundle mainBundle] pathForResource:@"x3f_extract" ofType:nil];
    
    NSMutableArray *arguments = [NSMutableArray array];
    switch (_outputFileFormat) {
        case Jpeg:
            [arguments addObject:@"-jpg"];
            break;
        case Dng:
        default:
            [arguments addObject:@"-dng"];
            break;
        case Tiff:
            [arguments addObject:@"-tiff"];
            break;
    }
    if (_outputFileFormat == Tiff) {
        switch (_colorSpace) {
            case None:
                [arguments addObject:@"-color"];
                [arguments addObject:@"none"];
                break;
            case sRGB:
            default:
                [arguments addObject:@"-color"];
                [arguments addObject:@"sRGB"];
                break;
            case AdobeRGB:
                [arguments addObject:@"-color"];
                [arguments addObject:@"AdobeRGB"];
                break;
            case ProPhotoRGB:
                [arguments addObject:@"-color"];
                [arguments addObject:@"ProPhotoRGB"];
                break;
        }
    }
    if (_outputFileFormat == Dng || _outputFileFormat == Tiff) {
        switch (_gain) {
            case Auto:
            default:
                break;
            case Apply:
                [arguments addObject:@"-no-sgain"];
                break;
            case DontApply:
                [arguments addObject:@"-sgain"];
                break;
        }
        if (!_compress) {
            [arguments addObject:@"-unprocessed"];
        }
    }
    if (_outputFileFormat == Dng || _outputFileFormat == Tiff) {
        if (!_compress) {
            [arguments addObject:@"-unprocessed"];
        }
    }
    if (_outputFileFormat == Dng || _outputFileFormat == Tiff) {
        if (!_denoise) {
            [arguments addObject:@"-no-denoise"];
        }
    }

    [arguments addObject:filePath];

    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:x3fExtractPath];
    [task setArguments:arguments];
    
    return task;
}

+ (BOOL)removeTempFileWithInputFilePath:(NSString *)inputFilePath outputFileFormat:(OutputFileFormat)outputFileFormat {
    NSString *deleteFilePath = [NSString stringWithFormat:@"%@.%@.tmp",
                                inputFilePath,
                                [[self class] extentionOfOutputFileFormat:outputFileFormat]];
    
    if ([[NSFileManager defaultManager] isDeletableFileAtPath:deleteFilePath]) {
        return [[NSFileManager defaultManager] removeItemAtPath:deleteFilePath error:nil];
    }
    return YES;
}

+ (NSString *)extentionOfOutputFileFormat:(OutputFileFormat)outputFileFormat {
    switch (outputFileFormat) {
        case Jpeg:
            return @"jpg";
        case Dng:
            return @"dng";
        case Tiff:
            return @"tif";
        default:
            break;
    }
}

- (void)updateOutputFormat:(OutputFileFormat)format {
    _outputFileFormat = format;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setInteger:_outputFileFormat forKey:USER_DEFAULT_KEY_OUTPUT_FORMAT];
    [userDefaults synchronize];
    
    switch (_outputFileFormat) {
        case Jpeg:
            _colorSpacePopUpButton.enabled = NO;
            _spatialGainPopUpButton.enabled = NO;
            _denoiseCheckBox.enabled = NO;
            _compressCheckBox.enabled = NO;
            break;
        case Dng:
            _colorSpacePopUpButton.enabled = NO;
            _spatialGainPopUpButton.enabled = YES;
            _denoiseCheckBox.enabled = YES;
            _compressCheckBox.enabled = YES;
            break;
        case Tiff:
            _colorSpacePopUpButton.enabled = YES;
            _spatialGainPopUpButton.enabled = YES;
            _denoiseCheckBox.enabled = YES;
            _compressCheckBox.enabled = YES;
            break;
        default:
            break;
    }
}

- (void)updateColorSpace:(ColorSpace)colorSpace {
    _colorSpace = colorSpace;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setInteger:_colorSpace forKey:USER_DEFAULT_KEY_COLOR_SPACE];
    [userDefaults synchronize];
}

- (void)updateSpatialGain:(Gain)gain {
    _gain = gain;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setInteger:_gain forKey:USER_DEFAULT_KEY_GAIN];
    [userDefaults synchronize];
}

- (void)updateDenoise:(BOOL)denoise {
    _denoise = denoise;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:_denoise forKey:USER_DEFAULT_KEY_DENOISE];
    [userDefaults synchronize];
}

- (void)updateCompress:(BOOL)compress {
    _compress = compress;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:_compress forKey:USER_DEFAULT_KEY_COMPRESS];
    [userDefaults synchronize];
}

@end
