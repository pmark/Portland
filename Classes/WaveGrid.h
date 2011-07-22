//
//  WaveGrid.h
//

#import <Foundation/Foundation.h>
#import "SM3DAR.h"
#import "Globals.h"

//Coord3D worldCoordinateDataHigh[(int)ELEVATION_PATH_SAMPLES][(int)ELEVATION_PATH_SAMPLES];


@interface WaveGrid : NSObject 
{
    CGFloat swellDegrees;
}

- (void) refresh;

@end
