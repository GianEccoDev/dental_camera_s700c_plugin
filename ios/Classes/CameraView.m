#import "CameraView.h"

@interface CameraViewFactory : NSObject <FlutterPlatformViewFactory>
- (instancetype)initWithMessenger:(NSObject<FlutterBinaryMessenger>*)messenger;
+ (CameraView *)getCameraViewWithId:(int64_t)viewId;
@end

@interface CameraView : NSObject <FlutterPlatformView>

- (instancetype)initWithFrame:(CGRect)frame
               viewIdentifier:(int64_t)viewId
                    arguments:(id _Nullable)args
              binaryMessenger:(NSObject<FlutterBinaryMessenger>*)messenger;

- (UIView*)view;
- (void)startVideoRecordingWithResult:(FlutterResult)result;
- (void)stopVideoRecordingWithResult:(FlutterResult)result;
- (void)capturePhotoWithResult:(FlutterResult)result;
@end

@implementation CameraView {
    UIViewController *_customViewController;
    BOOL _isRecording;
    AVAssetWriter *_assetWriter;
    AVAssetWriterInput *_assetWriterInput;
    AVAssetWriterInputPixelBufferAdaptor *_adaptor;
    CMTime _frameTime;
    NSURL *_outputURL;
    FlutterResult _captureResult;
    FlutterResult _videoResult;
}

- (instancetype)initWithFrame:(CGRect)frame viewIdentifier:(int64_t)viewId arguments:(id)args {
    self = [super init];
    if (self) {
        _customViewController = [[UIViewController alloc] init];
        _customViewController.view.frame = frame;
        [self setupWriter];
    }
    return self;
}

- (UIView *)view {
    return _customViewController.view;
}

- (void)setupWriter {
    _isRecording = NO;
}

- (void)capturePhotoWithResult:(FlutterResult)result {
    NSLog(@"[DEBUG] capturePhotoWithResult called");
    _captureResult = result;
    UIImage *capturedImage = [self getCurrentFrame];
    if (capturedImage) {
        NSData *imageData = UIImagePNGRepresentation(capturedImage);
        if (imageData) {
            NSLog(@"[DEBUG] Image captured and converted to NSData");
            if (_captureResult) {
                NSLog(@"[DEBUG] Sending image data back to Flutter");
                _captureResult([FlutterStandardTypedData typedDataWithBytes:imageData]);

                // Notify Flutter about the captured image
                FlutterViewController *flutterViewController = (FlutterViewController *)UIApplication.sharedApplication.delegate.window.rootViewController;
                FlutterMethodChannel *channel = [FlutterMethodChannel methodChannelWithName:@"dental_camera_s700c_plugin" binaryMessenger:flutterViewController.binaryMessenger];
                [channel invokeMethod:@"photoPreview" arguments:[FlutterStandardTypedData typedDataWithBytes:imageData]];
            } else {
                NSLog(@"[DEBUG] captureResult is nil");
            }
        } else {
            NSLog(@"[DEBUG] Failed to convert image to data");
            if (_captureResult) {
                _captureResult([FlutterError errorWithCode:@"UNAVAILABLE"
                                                   message:@"Could not convert image to data"
                                                   details:nil]);
            } else {
                NSLog(@"[DEBUG] captureResult is nil");
            }
        }
    } else {
        NSLog(@"[DEBUG] No image captured");
        if (_captureResult) {
            _captureResult([FlutterError errorWithCode:@"UNAVAILABLE"
                                               message:@"No image captured"
                                               details:nil]);
        } else {
            NSLog(@"[DEBUG] captureResult is nil");
        }
    }
    _captureResult = nil;
}

- (void)startVideoRecordingWithResult:(FlutterResult)result {
    NSLog(@"[DEBUG] startVideoRecordingWithResult called");
    if (!_isRecording) {
        CGSize frameSize = CGSizeMake(640, 480);
        NSString *outputPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSUUID UUID].UUIDString];
        _outputURL = [NSURL fileURLWithPath:[outputPath stringByAppendingPathExtension:@"mov"]];

        NSError *error = nil;
        _assetWriter = [[AVAssetWriter alloc] initWithURL:_outputURL fileType:AVFileTypeQuickTimeMovie error:&error];
        if (error) {
            NSLog(@"[DEBUG] Error initializing AVAssetWriter: %@", error);
            result([FlutterError errorWithCode:@"ASSET_WRITER_INIT_FAILED"
                                       message:@"Could not initialize AVAssetWriter"
                                       details:error.localizedDescription]);
            return;
        }

        NSDictionary *outputSettings = @{AVVideoCodecKey: AVVideoCodecTypeH264,
                                         AVVideoWidthKey: @(frameSize.width),
                                         AVVideoHeightKey: @(frameSize.height)};
        _assetWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:outputSettings];
        _assetWriterInput.expectsMediaDataInRealTime = YES;
        
        NSDictionary *sourcePixelBufferAttributes = @{(NSString *)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32ARGB),
                                                      (NSString *)kCVPixelBufferWidthKey: @(frameSize.width),
                                                      (NSString *)kCVPixelBufferHeightKey: @(frameSize.height),
                                                      (NSString *)kCVPixelFormatOpenGLESCompatibility: @(YES)};
        _adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:_assetWriterInput
                                                                                   sourcePixelBufferAttributes:sourcePixelBufferAttributes];

        if ([_assetWriter canAddInput:_assetWriterInput]) {
            [_assetWriter addInput:_assetWriterInput];
        } else {
            NSLog(@"[DEBUG] Cannot add input to AVAssetWriter");
            result([FlutterError errorWithCode:@"ASSET_WRITER_INPUT_FAILED"
                                       message:@"Could not add input to AVAssetWriter"
                                       details:nil]);
            return;
        }

        _isRecording = YES;
        _videoResult = result;
        _frameTime = kCMTimeZero;

        [_assetWriter startWriting];
        [_assetWriter startSessionAtSourceTime:kCMTimeZero];

        [self captureFrame];
    } else {
        result([FlutterError errorWithCode:@"ALREADY_RECORDING"
                                   message:@"A recording is already in progress"
                                   details:nil]);
    }
}

- (void)captureFrame {
    if (!_isRecording) {
        return;
    }
    UIImage *capturedImage = [self getCurrentFrame];
    if (capturedImage) {
        CVPixelBufferRef buffer = [self pixelBufferFromCGImage:capturedImage.CGImage];
        if (buffer) {
            while (!_assetWriterInput.readyForMoreMediaData) {
                [NSThread sleepForTimeInterval:0.1];
            }
            [_adaptor appendPixelBuffer:buffer withPresentationTime:_frameTime];
            CVPixelBufferRelease(buffer);
            _frameTime = CMTimeAdd(_frameTime, CMTimeMake(1, 24)); // assuming 24 fps
        }
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 / 24.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self captureFrame];
    });
}

- (void)stopVideoRecordingWithResult:(FlutterResult)result {
    NSLog(@"[DEBUG] stopVideoRecordingWithResult called");

    if (_isRecording) {
        _isRecording = NO;
        [_assetWriterInput markAsFinished];
        [_assetWriter finishWritingWithCompletionHandler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                if (_assetWriter.status == AVAssetWriterStatusCompleted) {
                    NSData *videoData = [NSData dataWithContentsOfURL:_outputURL];
                    result([FlutterStandardTypedData typedDataWithBytes:videoData]);

                    // Notify Flutter about the recorded video
                    FlutterViewController *flutterViewController = (FlutterViewController *)UIApplication.sharedApplication.delegate.window.rootViewController;
                    FlutterMethodChannel *channel = [FlutterMethodChannel methodChannelWithName:@"dental_camera_s700c_plugin" binaryMessenger:flutterViewController.binaryMessenger];
                    [channel invokeMethod:@"videoPreview" arguments:[FlutterStandardTypedData typedDataWithBytes:videoData]];
                } else {
                    result([FlutterError errorWithCode:@"ASSET_WRITER_FINISH_FAILED"
                                               message:@"Could not finish writing the video"
                                               details:_assetWriter.error.localizedDescription]);
                }
            });
        }];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            result([FlutterError errorWithCode:@"NO_RECORDING"
                                       message:@"No recording is in progress"
                                       details:nil]);
        });
    }
}

- (CVPixelBufferRef)pixelBufferFromCGImage:(CGImageRef)image {
    CGSize frameSize = CGSizeMake(640, 480);

    NSDictionary *options = @{
        (NSString *)kCVPixelBufferCGImageCompatibilityKey: @YES,
        (NSString *)kCVPixelBufferCGBitmapContextCompatibilityKey: @YES
    };
    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, frameSize.width, frameSize.height, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef)options, &pxbuffer);
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);

    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);

    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, frameSize.width, frameSize.height, 8, 4 * frameSize.width, rgbColorSpace, kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    CGContextDrawImage(context, CGRectMake(0, 0, frameSize.width, frameSize.height), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);

    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);

    return pxbuffer;
}

- (UIImage *)getCurrentFrame {
    return self.customViewController.imageView.image;
}

@end
