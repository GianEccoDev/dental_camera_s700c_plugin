//
//  ViewController.m
//  bfl_test
//
//  Created by Neo on 2019/2/21.
//  Copyright © 2019 bouffalolab. All rights reserved.
//

#import "ViewController.h"
#import <BFL_SDK/Camera.h>
#import <BFL_SDK/BFL_SDK.h>

#define WIDTH [UIScreen mainScreen].bounds.size.width
#define HEIGHT [UIScreen mainScreen].bounds.size.height

@interface ViewController () <CameraDelegate>

@property (nonatomic, strong, readwrite) UIImage *capturedImage; // Redeclare the property as readwrite
@property (nonatomic, strong) Camera *camera;
@property (nonatomic, strong) UIImageView *imageView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSLog(@"[DEBUG] ViewController viewDidLoad");
    
    self.camera = [Camera sharedCamera];
    self.camera.delegate = self;
    
    self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 20, WIDTH, (0.75) * WIDTH)];
    self.imageView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.imageView];
    
    UIView *line = [[UIView alloc] initWithFrame:CGRectMake(10, HEIGHT - 50, WIDTH - 20, 1)];
    [self.view addSubview:line];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSLog(@"[DEBUG] ViewController viewDidAppear");
    [self.camera start];
}

- (void)camera:(Camera *)server image:(UIImage *)image appendix:(NSString *)appendix {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.imageView.image = image;
        self.capturedImage = image;
    });
}

- (UIImage *)getCurrentFrame {
    return self.imageView.image;
}

@end
