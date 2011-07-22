//
//  WorldCoordinate.m
//  Hood
//
//  Created by P. Mark Anderson on 5/22/11.
//  Copyright 2011 Spot Metrix, Inc. All rights reserved.
//

#import "WorldCoordinate.h"


@implementation WorldCoordinate

@synthesize coord;

- (id) initWithCoord:(Coord3D)_coord
{
    self = [super init];
    
    if (self)
    {
        self.coord = _coord;
    }
    
    return self;
}

@end
