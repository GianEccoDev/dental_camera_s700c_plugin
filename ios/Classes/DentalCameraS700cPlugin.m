#import "DentalCameraS700cPlugin.h"

@implementation DentalCameraS700cPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"dental_camera_s700c_plugin"
            binaryMessenger:[registrar messenger]];
  DentalCameraS700cPlugin* instance = [[DentalCameraS700cPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
    
    // Create the CameraViewFactory, passing the registrar
  CameraViewFactory* factory = [[CameraViewFactory alloc] initWithRegistrar:registrar];
  [registrar registerViewFactory:factory withId:@"my_uikit_view"];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if ([@"getPlatformVersion" isEqualToString:call.method]) {
    result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
  } else {
    result(FlutterMethodNotImplemented);
  }
}

@end
