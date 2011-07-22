//
//  WorldCoordinate.h
//  Hood
//
//  Created by P. Mark Anderson on 5/22/11.
//  Copyright 2011 Spot Metrix, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SM3DAR.h"


@interface WorldCoordinate : NSObject 
{
    Coord3D coord3d;
}

@property (nonatomic, assign) Coord3D coord;

- (id) initWithCoord:(Coord3D)coord;

@end
