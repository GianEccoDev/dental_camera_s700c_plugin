#import "DentalCameraS700cPlugin.h"
#import <Flutter/Flutter.h>
#import "CameraView.h"

@interface CameraViewFactory : NSObject <FlutterPlatformViewFactory>
@property (nonatomic, strong) CameraView *cameraView; // Retain the CameraView instance
@end

@implementation CameraViewFactory

- (instancetype)init {
    self = [super init];
    if (self) {
        _cameraView = [[CameraView alloc] initWithFrame:CGRectZero viewIdentifier:0 arguments:nil];
    }
    return self;
}

- (NSObject<FlutterPlatformView> *)createWithFrame:(CGRect)frame viewIdentifier:(int64_t)viewId arguments:(id)args {
    return self.cameraView;
}

@end

@interface DentalCameraS700cPlugin ()
@property (nonatomic, strong) CameraViewFactory *cameraViewFactory;
@property (nonatomic, strong) FlutterMethodChannel *methodChannel;
@end

@implementation DentalCameraS700cPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
        methodChannelWithName:@"dental_camera_s700c_plugin"
              binaryMessenger:[registrar messenger]];
    DentalCameraS700cPlugin* instance = [[DentalCameraS700cPlugin alloc] init];
    instance.methodChannel = channel; // Assign the methodChannel to the instance
    [registrar addMethodCallDelegate:instance channel:channel];

    // Register the view factory
    instance.cameraViewFactory = [[CameraViewFactory alloc] init];
    [registrar registerViewFactory:instance.cameraViewFactory withId:@"my_uikit_view"];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"getPlatformVersion" isEqualToString:call.method]) {
        result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
    } else if ([@"startVideoRecording" isEqualToString:call.method]) {
        NSLog(@"[DEBUG] startVideoRecording method call received");
        [self.cameraViewFactory.cameraView startVideoRecordingWithResult:result];
        [self.methodChannel invokeMethod:@"RECORDING_STARTED" arguments:nil];
    } else if ([@"stopVideoRecording" isEqualToString:call.method]) {
        NSLog(@"[DEBUG] stopVideoRecording method call received");
        [self.cameraViewFactory.cameraView stopVideoRecordingWithResult:result];
        [self.methodChannel invokeMethod:@"RECORDING_STOPPED" arguments:nil];
    } else if ([@"foto_ios" isEqualToString:call.method]) {
        NSLog(@"[DEBUG] foto_ios method call received");
        [self.cameraViewFactory.cameraView capturePhotoWithResult:result];
    } else {
        result(FlutterMethodNotImplemented);
    }
}

@end
