#import <Flutter/Flutter.h>
#import "ViewController.h"

@interface CameraView : NSObject <FlutterPlatformView>
@property (nonatomic, strong) ViewController *customViewController;
@property (nonatomic, copy) FlutterResult captureResult;
- (instancetype)initWithFrame:(CGRect)frame viewIdentifier:(int64_t)viewId arguments:(id)args;
- (UIView *)view;
- (void)capturePhotoWithResult:(FlutterResult)result;
@end
