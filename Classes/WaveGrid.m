//
//  WaveGrid.m
//

#import "Coordinate.h"
#import "WaveGrid.h"
#import "NSDictionary+BSJSONAdditions.h"

@implementation WaveGrid

- (void) gridToWorldCoordinates:(NSArray *)rows
{    
    // Cool maths
    
    CGFloat half = ELEVATION_PATH_SAMPLES / 2.0;
    
    for (int rowNumber=0; rowNumber < ELEVATION_PATH_SAMPLES; rowNumber++)
    {
        NSInteger rnd = (rand() % 3);

        CGFloat rowpct = rowNumber / ELEVATION_PATH_SAMPLES;
        
        CGFloat rowdegrees = (2 * M_PI * rowpct) + (swellDegrees / 3);

        CGFloat zex = 110 + ((rnd/4) * 30);
        
        
        for (int colNumber=0; colNumber < ELEVATION_PATH_SAMPLES; colNumber++)
        {
            Coord3D c;
            
            CGFloat colpct = colNumber / ELEVATION_PATH_SAMPLES;

            CGFloat coldegrees = (2 * M_PI * colpct) + swellDegrees;
            
            CGFloat zrnd1, zrnd2;
            
            switch (rnd) 
            {                    
                case 0:
                    zrnd1 = sinf(coldegrees);
                    zrnd2 = sinf(rowdegrees) * (1.4);
                    break;
                
                default:
                    zrnd1 = sinf(coldegrees);
                    zrnd2 = sinf(rowdegrees);
                    break;
            }

            c.z = (zrnd1 + zrnd2) * zex;  

            c.x = (colNumber - half) * 60; //(60 + (rnd*4));
            c.y = (rowNumber - half) * 60;
            
            
            // Dome tarp is sin + sin
            
            worldCoordinateDataHigh[rowNumber][colNumber] = c;
        }
    }    
    
}

- (void) refresh
{
    swellDegrees += M_PI / 8;
    
    [self gridToWorldCoordinates:nil];
}

- (id) init
{
    if (self = [super init])
    {
        NSArray *gridRows = nil;
        swellDegrees = 0;
        
        [self gridToWorldCoordinates:gridRows];
    }
    
    return self;
}


@end
