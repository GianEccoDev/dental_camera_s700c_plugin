#import "AppDelegate.h"
#import "GeneratedPluginRegistrant.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [GeneratedPluginRegistrant registerWithRegistry:self];
    
    // Initialize and retain a single CameraView instance
    cameraViewFactory = [[CameraViewFactory alloc] init];
    NSObject<FlutterPluginRegistrar> *registrar = [controller.engine registrarForPlugin:@"CameraViewFactory"];
    [registrar registerViewFactory:cameraViewFactory withId:@"my_uikit_view"];
    
    return [super application:application didFinishLaunchingWithOptions:launchOptions];
    
    
}

@end
