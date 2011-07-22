//
//  Coordinate.m
//  BezierGarden
//
//  Created by Thomas Burke on 1/27/11.
//  Copyright 2011 Box Elder Solutions, LLC. All rights reserved.
//

#import "Coordinate.h"


@implementation Coordinate

@synthesize latitude;
@synthesize longitude;

- (id) initWithLatitude:(CLLocationDegrees)_latitude longitude:(CLLocationDegrees)_longitude elevation:(CGFloat)_elevation
{
    if (self = [super init])
    {
        latitude = _latitude;
        longitude = _longitude;
        elevation = _elevation;
    }
    return self;
}

- (CLLocation *) toLocation
{
    
    CLLocationCoordinate2D coord;
    coord.latitude = latitude;
    coord.longitude = longitude;
    
    return [[CLLocation alloc] initWithCoordinate:coord 
                                         altitude:elevation 
                               horizontalAccuracy:0 
                                 verticalAccuracy:0 
                                        timestamp:nil];
}

- (Coord3D) toCoord3D
{
    static BOOL first = YES;
    
    Coord3D c;
    
    c = [SM3DARController worldCoordinateFor:[self toLocation]];
    
    
    if (first)
    {
        first = NO;
    }
    
    return c;
}

@end
