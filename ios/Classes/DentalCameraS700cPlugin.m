#import "DentalCameraS700cPlugin.h"
#import <Flutter/Flutter.h>
#import "CameraView.h"

@interface CameraViewFactory : NSObject <FlutterPlatformViewFactory>
@property (nonatomic, strong) CameraView *cameraView;
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

@implementation DentalCameraS700cPlugin {
    CameraViewFactory *cameraViewFactory;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
        methodChannelWithName:@"dental_camera_s700c_plugin"
              binaryMessenger:[registrar messenger]];
    DentalCameraS700cPlugin* instance = [[DentalCameraS700cPlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];

    cameraViewFactory = [[CameraViewFactory alloc] init];
    [registrar registerViewFactory:cameraViewFactory withId:@"my_uikit_view"];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"startVideoRecording" isEqualToString:call.method]) {
        [cameraViewFactory.cameraView startVideoRecordingWithResult:result];
    } else if ([@"stopVideoRecording" isEqualToString:call.method]) {
        [cameraViewFactory.cameraView stopVideoRecordingWithResult:result];
    } else if ([@"foto_ios" isEqualToString:call.method]) {
        [cameraViewFactory.cameraView capturePhotoWithResult:result];
    } else {
        result(FlutterMethodNotImplemented);
    }
}

@end
