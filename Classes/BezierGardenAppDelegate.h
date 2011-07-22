//
//  BezierGardenAppDelegate.h
//  BezierGarden
//
//  Created by P. Mark Anderson on 10/6/10.
//  Copyright 2010 Spot Metrix, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HoodViewController;

@interface BezierGardenAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    HoodViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet HoodViewController *viewController;

@end

