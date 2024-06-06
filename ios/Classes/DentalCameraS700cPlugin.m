#import "DentalCameraS700cPlugin.h"
#import <Flutter/Flutter.h>
#import "CameraView.h"

@implementation DentalCameraS700cPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  CameraViewFactory* factory =
      [[CameraViewFactory alloc] initWithMessenger:registrar.messenger];
  [registrar registerViewFactory:factory withId:@"<my_uikit_view"];
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
