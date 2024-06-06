// AppDelegate.m

#import <Flutter/Flutter.h>
#import "AppDelegate.h"
#import "GeneratedPluginRegistrant.h"
#import "CameraView.h"

@interface CameraViewFactory : NSObject <FlutterPlatformViewFactory>
@end

@implementation CameraViewFactory

- (NSObject<FlutterPlatformView> *)createWithFrame:(CGRect)frame
                                     viewIdentifier:(int64_t)viewId
                                          arguments:(id _Nullable)args {
    return [[CameraView alloc] initWithFrame:frame viewIdentifier:viewId arguments:args];
}

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    FlutterViewController *controller = (FlutterViewController *)self.window.rootViewController;
    
    // Register CameraViewFactory
    NSObject<FlutterPluginRegistrar> *registrar = [controller.engine registrarForPlugin:@"CameraViewFactory"];
    CameraViewFactory *cameraViewFactory = [[CameraViewFactory alloc] init];
    [registrar registerViewFactory:cameraViewFactory withId:@"my_uikit_view"];
    
    // Register method channel
    FlutterMethodChannel *channel = [FlutterMethodChannel methodChannelWithName:@"dental_camera_s700c_plugin" binaryMessenger:controller.binaryMessenger];
    
    // Use weak reference to self in the block to avoid retain cycles.
    __weak typeof(self) weakSelf = self;
    [channel setMethodCallHandler:^(FlutterMethodCall *call, FlutterResult result) {
        __strong typeof(self) strongSelf = weakSelf; // Strong reference inside the block
        if ([@"startVideoRecording" isEqualToString:call.method]) {
            NSLog(@"[DEBUG] startVideoRecording method call received");
            // Access cameraView directly without strong reference
            [[strongSelf cameraView] startVideoRecordingWithResult:result];
            [channel invokeMethod:@"RECORDING_STARTED" arguments:nil];
        } else if ([@"stopVideoRecording" isEqualToString:call.method]) {
            NSLog(@"[DEBUG] stopVideoRecording method call received");
            [[strongSelf cameraView] stopVideoRecordingWithResult:result];
            [channel invokeMethod:@"RECORDING_STOPPED" arguments:nil];
        } else if ([@"foto_ios" isEqualToString:call.method]) {
            NSLog(@"[DEBUG] foto_ios method call received");
            [[strongSelf cameraView] capturePhotoWithResult:result];
        } else {
            result(FlutterMethodNotImplemented);
        }
    }];
    
    [GeneratedPluginRegistrant registerWithRegistry:controller.engine];
    return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

// Access the CameraView instance without creating a strong reference
- (CameraView *)cameraView {
    UIViewController *flutterVC = self.window.rootViewController;
    if ([flutterVC isKindOfClass:[FlutterViewController class]]) {
        for (UIView *subview in flutterVC.view.subviews) {
            if ([subview isKindOfClass:[CameraView class]]) {
                return (CameraView *)subview;
            }
        }
    }
    return nil;
}

@end
