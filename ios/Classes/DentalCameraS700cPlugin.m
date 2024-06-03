#import "DentalCameraS700cPlugin.h"
#import "AppDelegate.h"
@implementation DentalCameraS700cPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"dental_camera_s700c_plugin"
            binaryMessenger:[registrar messenger]];
  DentalCameraS700cPlugin* instance = [[DentalCameraS700cPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {




  if ([@"getPlatformVersion" isEqualToString:call.method]) {
    result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
  } else if ([@"startVideoRecording" isEqualToString:call.method]) {
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
