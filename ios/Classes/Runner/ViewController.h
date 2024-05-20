//
//  ViewController.h
//  bfl_test
//
//  Created by Neo on 2019/2/21.
//  Copyright © 2019 bouffalolab. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property (nonatomic, strong, readonly) UIImage *capturedImage; // Declare the property as readonly

- (UIImage *)getCurrentFrame; // Declare the method

@end
