#import "DentalCameraS700cPlugin.h"
#import "CameraViewFactory.h"

@implementation DentalCameraS700cPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  NSLog(@"[DEBUG] Registering DentalCameraS700cPlugin");
  
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"dental_camera_s700c"
            binaryMessenger:[registrar messenger]];
  DentalCameraS700cPlugin* instance = [[DentalCameraS700cPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];

  CameraViewFactory* factory = [[CameraViewFactory alloc] initWithMessenger:[registrar messenger]];
  NSLog(@"[DEBUG] Registering CameraViewFactory with id: my_uikit_view");
  [registrar registerViewFactory:factory withId:@"my_uikit_view"];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  NSLog(@"[DEBUG] handleMethodCall: %@", call.method);
  
  if ([@"getPlatformVersion" isEqualToString:call.method]) {
    result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
  } else {
    result(FlutterMethodNotImplemented);
  }
}

@end
