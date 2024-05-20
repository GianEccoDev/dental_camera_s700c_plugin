#import "CameraView.h"

@implementation CameraView

- (instancetype)initWithFrame:(CGRect)frame viewIdentifier:(int64_t)viewId arguments:(id)args {
    self = [super init];
    if (self) {
        _customViewController = [[ViewController alloc] init];
        _customViewController.view.frame = frame;
    }
    return self;
}

- (UIView *)view {
    return _customViewController.view;
}

- (void)capturePhotoWithResult:(FlutterResult)result {
    NSLog(@"[DEBUG] capturePhotoWithResult called");
    self.captureResult = result;
    UIImage *capturedImage = [self.customViewController getCurrentFrame];
    if (capturedImage) {
        NSData *imageData = UIImagePNGRepresentation(capturedImage);
        if (imageData) {
            NSLog(@"[DEBUG] Image captured and converted to NSData");
            if (self.captureResult) {
                NSLog(@"[DEBUG] Sending image data back to Flutter");
                self.captureResult([FlutterStandardTypedData typedDataWithBytes:imageData]);

                // Notify Flutter about the captured image
                FlutterViewController *flutterViewController = (FlutterViewController *)UIApplication.sharedApplication.delegate.window.rootViewController;
                FlutterMethodChannel *channel = [FlutterMethodChannel methodChannelWithName:@"com.example.flutterino/stream" binaryMessenger:flutterViewController.binaryMessenger];
                [channel invokeMethod:@"photoPreview" arguments:[FlutterStandardTypedData typedDataWithBytes:imageData]];
            } else {
                NSLog(@"[DEBUG] captureResult is nil");
            }
        } else {
            NSLog(@"[DEBUG] Failed to convert image to data");
            if (self.captureResult) {
                self.captureResult([FlutterError errorWithCode:@"UNAVAILABLE"
                                                       message:@"Could not convert image to data"
                                                       details:nil]);
            } else {
                NSLog(@"[DEBUG] captureResult is nil");
            }
        }
    } else {
        NSLog(@"[DEBUG] No image captured");
        if (self.captureResult) {
            self.captureResult([FlutterError errorWithCode:@"UNAVAILABLE"
                                                   message:@"No image captured"
                                                   details:nil]);
        } else {
            NSLog(@"[DEBUG] captureResult is nil");
        }
    }
    self.captureResult = nil;
}

@end
