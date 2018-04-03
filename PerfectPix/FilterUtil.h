//
//  FilterUtil.h
//  PerfectPix
//
//  Created by Atif Imran on 9/12/17.
//  Copyright © 2017 Atif Imran. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface FilterUtil : NSObject

+(NSMutableArray*)filtersList;
+ (void)showErrorShutterWithMessage:(NSString *)message andController:(UIViewController *)controller andYOrigin:(int)yOrigin;

@end
