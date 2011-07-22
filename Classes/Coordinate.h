//
//  Coordinate.h
//  BezierGarden
//
//  Created by Thomas Burke on 1/27/11.
//  Copyright 2011 Box Elder Solutions, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "SM3DAR.h"

@interface Coordinate : NSObject {
        CLLocationDegrees latitude;
        CLLocationDegrees longitude;
        CGFloat elevation;
}

@property (nonatomic, assign) CLLocationDegrees latitude;
@property (nonatomic, assign) CLLocationDegrees longitude;

- (id) initWithLatitude:(CLLocationDegrees)_latitude longitude:(CLLocationDegrees)_longitude elevation:(CGFloat)_elevation;
- (Coord3D) toCoord3D;

@end
