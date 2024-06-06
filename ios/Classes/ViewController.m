#import "ViewController.h"
#import "Camera.h"

#define WIDTH [UIScreen mainScreen].bounds.size.width
#define HEIGHT [UIScreen mainScreen].bounds.size.height

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
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
    [self.camera start];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.camera stop];
}

- (void)camera:(Camera *)camera image:(UIImage *)image appendix:(NSString *)appendix {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.imageView.image = image;
        self.capturedImage = image;
    });
}

@end
