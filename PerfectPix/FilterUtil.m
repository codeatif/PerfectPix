//
//  FilterUtil.m
//  PerfectPix
//
//  Created by Atif Imran on 9/12/17.
//  Copyright © 2017 Atif Imran. All rights reserved.
//

#import "FilterUtil.h"

@implementation FilterUtil

+(NSMutableArray*)filtersList{
    NSMutableArray* filters = [NSMutableArray arrayWithObjects:
                @"Grayscale",
                @"Bloater",
                @"Spink",
                @"Twistrr",
                @"BlackHole",
                @"Gamma",
                @"Sepia",
                @"Invert",
                @"Amatorka",
                @"Miss Etikate",
                @"Soft Elegance",
                @"Tilt Shift",
                @"Erosion",
                @"iOS Blur",
                @"Haze",
                @"Solarize",
                @"Pixellate",
                @"Polka Dot",
                @"Sketch",
                @"Smooth Toon",
                @"Posterize",
                @"Stretch",
                @"Sphere",
                @"Glass",
                @"Kuwahara",
                @"Vignette",
                @"False",
                @"Emboss",
                @"Halftone",
                @"Threshold",
                @"Monochrome",
                nil];
    return filters;
}

+ (void)showErrorShutterWithMessage:(NSString *)message andController:(UIViewController *)controller andYOrigin:(int)yOrigin{
    UIView *shutterView = [[UIView alloc] initWithFrame:CGRectMake(0, -64, controller.view.frame.size.width, 64)];
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(7, 5, 25, 25)];
    [imageView setImage:[UIImage imageNamed:@"warning-sign.png"]];
    [imageView clipsToBounds];
    //    [shutterView addSubview:imageView];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, shutterView.frame.size.width, shutterView.frame.size.height)];
    if(message==nil)
        label.text= NSLocalizedString(@"Network not available. Try again later",nil);
    else
        label.text= message;
    label.numberOfLines=2;
    label.textColor =[UIColor whiteColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.adjustsFontSizeToFitWidth = YES;
    label.font = [UIFont systemFontOfSize:11.0];
    label.minimumScaleFactor = 12.0;
    label.backgroundColor = [UIColor colorWithRed:89/255.0 green:88/255.0 blue:92/255.0 alpha:1];
    
    [shutterView addSubview:label];
    
    shutterView.backgroundColor = [UIColor clearColor];
    shutterView.clipsToBounds = YES;
    shutterView.layer.cornerRadius = 4.0;
    
    //    shutterView.alpha=0;
    [controller.view addSubview:shutterView];
    
    [UIView animateWithDuration:.3 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{//slide down slide up
        shutterView.frame  = CGRectMake(0, yOrigin+20/*statusbar*/, controller.view.frame.size.width,shutterView.frame.size.height);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:.3 delay:4.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            shutterView.frame  = CGRectMake(0, controller.view.frame.origin.y-shutterView.frame.size.height, controller.view.frame.size.width,shutterView.frame.size.height);
        } completion:^(BOOL finished) {
            shutterView.alpha=0;
        }];
        
    }];
}
@end
