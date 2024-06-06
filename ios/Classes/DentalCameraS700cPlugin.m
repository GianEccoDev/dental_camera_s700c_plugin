#import "DentalCameraS700cPlugin.h"
#import <Flutter/Flutter.h>
#import "CameraView.h"

@implementation DentalCameraS700cPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    CameraViewFactory* factory = [[CameraViewFactory alloc] initWithMessenger:registrar.messenger];
    [registrar registerViewFactory:factory withId:@"my_uikit_view"];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSDictionary *arguments = call.arguments;
    int64_t viewId = [arguments[@"viewId"] longLongValue];
    CameraView *cameraView = [CameraViewFactory getCameraViewWithId:viewId];
    
    if ([@"startVideoRecording" isEqualToString:call.method]) {
        [cameraView startVideoRecordingWithResult:result];
    } else if ([@"stopVideoRecording" isEqualToString:call.method]) {
        [cameraView stopVideoRecordingWithResult:result];
    } else if ([@"foto_ios" isEqualToString:call.method]) {
        [cameraView capturePhotoWithResult:result];
    } else {
        result(FlutterMethodNotImplemented);
    }
}

@end
