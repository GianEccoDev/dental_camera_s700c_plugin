#import "DentalCameraS700cPlugin.h"
#import <Flutter/Flutter.h>
#import "CameraView.h"

@interface CameraViewFactory : NSObject <FlutterPlatformViewFactory>
@property (nonatomic, strong) NSObject<FlutterBinaryMessenger>* messenger;
@property (nonatomic, strong) CameraView* cameraView; // Retain the CameraView instance
@end

@implementation CameraViewFactory

- (instancetype)initWithMessenger:(NSObject<FlutterBinaryMessenger>*)messenger {
    self = [super init];
    if (self) {
        _messenger = messenger;
    }
    return self;
}

- (NSObject<FlutterPlatformView> *)createWithFrame:(CGRect)frame viewIdentifier:(int64_t)viewId arguments:(id)args {
    _cameraView = [[CameraView alloc] initWithFrame:frame viewIdentifier:viewId arguments:args binaryMessenger:_messenger];
    return _cameraView;
}

@end

@interface DentalCameraS700cPlugin()
@property (nonatomic, strong) CameraViewFactory* cameraViewFactory;
@property (nonatomic, strong) FlutterMethodChannel* channel;
@end

@implementation DentalCameraS700cPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
        methodChannelWithName:@"dental_camera_s700c_plugin"
              binaryMessenger:[registrar messenger]];
    DentalCameraS700cPlugin* instance = [[DentalCameraS700cPlugin alloc] init];
    instance.channel = channel;
    [registrar addMethodCallDelegate:instance channel:channel];

    CameraViewFactory* factory =
        [[CameraViewFactory alloc] initWithMessenger:registrar.messenger];
    instance.cameraViewFactory = factory;
    [registrar registerViewFactory:factory withId:@"my_uikit_view"];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"startVideoRecording" isEqualToString:call.method]) {
        [self.cameraViewFactory.cameraView startVideoRecordingWithResult:result];
        [self.channel invokeMethod:@"RECORDING_STARTED" arguments:nil];
    } else if ([@"stopVideoRecording" isEqualToString:call.method]) {
        [self.cameraViewFactory.cameraView stopVideoRecordingWithResult:result];
        [self.channel invokeMethod:@"RECORDING_STOPPED" arguments:nil];
    } else if ([@"foto_ios" isEqualToString:call.method]) {
        [self.cameraViewFactory.cameraView capturePhotoWithResult:result];
    } else {
        result(FlutterMethodNotImplemented);
    }
}

@end
