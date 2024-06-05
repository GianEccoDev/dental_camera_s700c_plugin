#import <Flutter/Flutter.h>

@interface DentalCameraS700cPlugin : NSObject<FlutterPlugin>
@end

@interface CameraViewFactory : NSObject <FlutterPlatformViewFactory>
@property (nonatomic, strong) CameraView *cameraView;
@end
