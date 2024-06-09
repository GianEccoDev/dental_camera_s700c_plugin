#import <Flutter/Flutter.h>
#import "AppDelegate.h"
#import "GeneratedPluginRegistrant.h"

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    FlutterViewController *controller = (FlutterViewController *)self.window.rootViewController;
    [GeneratedPluginRegistrant registerWithRegistry:controller.engine];
    FlutterMethodChannel *channel = [FlutterMethodChannel methodChannelWithName:@"dental_camera_s700c_plugin" binaryMessenger:controller.binaryMessenger];
    return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

@end
