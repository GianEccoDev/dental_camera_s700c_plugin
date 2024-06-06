#import <Flutter/Flutter.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "ViewController.h"

@interface CameraView : NSObject <FlutterPlatformView>
@property (nonatomic, strong) ViewController *customViewController;
@property (nonatomic, copy) FlutterResult captureResult;
@property (nonatomic, strong) NSURL *outputURL;
@property (nonatomic, copy) FlutterResult videoResult;

@property (nonatomic, strong) AVAssetWriter *assetWriter;
@property (nonatomic, strong) AVAssetWriterInput *assetWriterInput;
@property (nonatomic, strong) AVAssetWriterInputPixelBufferAdaptor *adaptor;
@property (nonatomic, assign) CMTime frameTime;
@property (nonatomic, assign) BOOL isRecording;

- (CVPixelBufferRef)pixelBufferFromCGImage:(CGImageRef)image;

@end
