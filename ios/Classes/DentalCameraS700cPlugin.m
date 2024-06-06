#import "DentalCameraS700cPlugin.h"
#import "CameraView.h"
#import "AppDelegate.h"
#import <Flutter/Flutter.h>


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

@implementation DentalCameraS700cPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"dental_camera_s700c_plugin"
            binaryMessenger:[registrar messenger]];
  DentalCameraS700cPlugin* instance = [[DentalCameraS700cPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
    
  [GeneratedPluginRegistrant registerWithRegistry:self];

    
  CameraViewFactory* factory = [[CameraViewFactory alloc] initWithMessenger:[registrar messenger]];
  [registrar registerViewFactory:factory withId:@"my_uikit_view"];
}


@end
