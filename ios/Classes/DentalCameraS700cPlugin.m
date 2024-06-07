#import "DentalCameraS700cPlugin.h"
#import "ViewController.h"
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

@implementation DentalCameraS700cPlugin{
    CameraViewFactory *cameraViewFactory;
}

+(void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"dental_camera_s700c_plugin"
            binaryMessenger:[registrar messenger]];
  DentalCameraS700cPlugin* instance = [[DentalCameraS700cPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
    
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"startVideoRecording" isEqualToString:call.method]) {
        NSLog(@"[DEBUG] startVideoRecording method call received");
        [cameraViewFactory.cameraView startVideoRecordingWithResult:result];
        [channel invokeMethod:@"RECORDING_STARTED" arguments:nil];
    } else if ([@"stopVideoRecording" isEqualToString:call.method]) {
        NSLog(@"[DEBUG] stopVideoRecording method call received");
        [cameraViewFactory.cameraView stopVideoRecordingWithResult:result];
        [channel invokeMethod:@"RECORDING_STOPPED" arguments:nil];
    } else if ([@"foto_ios" isEqualToString:call.method]) {
        NSLog(@"[DEBUG] foto_ios method call received");
        [cameraViewFactory.cameraView capturePhotoWithResult:result];
  } else {
    result(FlutterMethodNotImplemented);
  }
}

@end
