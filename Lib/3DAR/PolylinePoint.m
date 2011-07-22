//
//  PolylinePoint.m
//  Hood
//
//  Created by P. Mark Anderson on 5/22/11.
//  Copyright 2011 Spot Metrix, Inc. All rights reserved.
//

#import "PolylinePoint.h"
#import "PolylineView.h"
#import "WorldCoordinate.h"

@implementation PolylinePoint

@synthesize coords;

- (void) dealloc
{
    [coords release];
    
    [super dealloc];
}

- (id) initWithWorldCoordinates:(NSArray *)_coords 
                     atLocation:(CLLocation *)_location 
                     properties:(NSDictionary *)_properties
{
    self = [super initWithLocation:_location properties:_properties];
    
    if (self)
    {
        self.coords = _coords;
        self.view = [[[PolylineView alloc] initWithWorldCoordinates:coords] autorelease];        
    }
    
    return self;
}

@end
