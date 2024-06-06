#import "CameraView.h"

@implementation CameraViewFactory {
    NSObject<FlutterBinaryMessenger>* _messenger;
    NSMutableDictionary<NSNumber*, CameraView*> *_cameraViews;
}

- (instancetype)initWithMessenger:(NSObject<FlutterBinaryMessenger>*)messenger {
    self = [super init];
    if (self) {
        _messenger = messenger;
        _cameraViews = [NSMutableDictionary dictionary];
    }
    return self;
}

- (NSObject<FlutterPlatformView>*)createWithFrame:(CGRect)frame
                                   viewIdentifier:(int64_t)viewId
                                        arguments:(id _Nullable)args {
    CameraView *cameraView = [[CameraView alloc] initWithFrame:frame
                                                viewIdentifier:viewId
                                                     arguments:args
                                               binaryMessenger:_messenger];
    _cameraViews[@(viewId)] = cameraView;
    return cameraView;
}

+ (CameraView*)getCameraViewWithId:(int64_t)viewId {
    return _cameraViews[@(viewId)];
}

@end

@implementation CameraView {
    UIView *_view;
}

- (instancetype)initWithFrame:(CGRect)frame
               viewIdentifier:(int64_t)viewId
                    arguments:(id _Nullable)args
              binaryMessenger:(NSObject<FlutterBinaryMessenger>*)messenger {
    if (self = [super init]) {
        _view = [[UIView alloc] init];
    }
    return self;
}

- (UIView*)view {
    return _view;
}

@end
