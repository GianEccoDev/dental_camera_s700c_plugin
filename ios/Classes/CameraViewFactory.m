#import "CameraViewFactory.h"
#import "CameraView.h"

@implementation CameraViewFactory {
    NSObject<FlutterBinaryMessenger>* _messenger;
}

- (instancetype)initWithMessenger:(NSObject<FlutterBinaryMessenger>*)messenger {
  self = [super init];
  if (self) {
    _messenger = messenger;
    NSLog(@"[DEBUG] CameraViewFactory initialized with messenger");
  }
  return self;
}

- (NSObject<FlutterPlatformView>*)createWithFrame:(CGRect)frame
                                   viewIdentifier:(int64_t)viewId
                                        arguments:(id _Nullable)args {
  NSLog(@"[DEBUG] Creating CameraView with viewId: %lld", viewId);
  CameraView* cameraView = [[CameraView alloc] initWithFrame:frame viewIdentifier:viewId arguments:args];
  return cameraView;
}

- (NSObject<FlutterMessageCodec>*)createArgsCodec {
  NSLog(@"[DEBUG] Creating args codec");
  return [FlutterStandardMessageCodec sharedInstance];
}

@end
