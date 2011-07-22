//
//  GridView.m
//
//

#import <UIKit/UIKit.h>
#import "SM3DAR.h"
#import "Globals.h"

// Works well for grid size 660km
//#define GRID_SCALE_HORIZONTAL 0.001
//#define GRID_SCALE_VERTICAL 0.12

// Works well for grid size 25km


@interface GridView : SM3DARMarkerView
{
    CGFloat redColor;
    CGFloat greenColor;
    CGFloat blueColor;
    Texture *gridTexture;
}

@end
