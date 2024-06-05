#import "DentalCameraS700cPlugin.h"
#import <Flutter/Flutter.h>
#import "CameraView.h"
#import "ViewController.h"

@interface DentalCameraS700cPlugin () <FlutterPlatformViewFactory>
@property (nonatomic, strong) NSObject<FlutterBinaryMessenger>* messenger;
@end

@implementation DentalCameraS700cPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
        methodChannelWithName:@"dental_camera_s700c_plugin"
              binaryMessenger:[registrar messenger]];
    DentalCameraS700cPlugin* instance = [[DentalCameraS700cPlugin alloc] init];
    instance.messenger = [registrar messenger];
    [registrar addMethodCallDelegate:instance channel:channel];
    [registrar registerViewFactory:instance withId:@"my_uikit_view"];
}

- (NSObject<FlutterPlatformView> *)createWithFrame:(CGRect)frame
                                   viewIdentifier:(int64_t)viewId
                                        arguments:(id _Nullable)args {
    return [[CameraView alloc] initWithFrame:frame
                               viewIdentifier:viewId
                                    arguments:args
                              binaryMessenger:self.messenger];
}

- (NSObject<FlutterMessageCodec>*)createArgsCodec {
    return [FlutterStandardMessageCodec sharedInstance];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    CameraView *cameraView = (CameraView *)[self createWithFrame:CGRectZero viewIdentifier:0 arguments:nil];
    
    if ([@"startVideoRecording" isEqualToString:call.method]) {
        [cameraView startVideoRecordingWithResult:result];
        FlutterMethodChannel *channel = [FlutterMethodChannel methodChannelWithName:@"dental_camera_s700c_plugin" binaryMessenger:self.messenger];
        [channel invokeMethod:@"RECORDING_STARTED" arguments:nil];
    } else if ([@"stopVideoRecording" isEqualToString:call.method]) {
        [cameraView stopVideoRecordingWithResult:result];
        FlutterMethodChannel *channel = [FlutterMethodChannel methodChannelWithName:@"dental_camera_s700c_plugin" binaryMessenger:self.messenger];
        [channel invokeMethod:@"RECORDING_STOPPED" arguments:nil];
    } else if ([@"foto_ios" isEqualToString:call.method]) {
        [cameraView capturePhotoWithResult:result];
    } else {
        result(FlutterMethodNotImplemented);
    }
}

@end
