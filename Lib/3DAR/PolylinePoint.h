//
//  PolylinePoint.h
//  Hood
//
//  Created by P. Mark Anderson on 5/22/11.
//  Copyright 2011 Spot Metrix, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SM3DAR.h"


@interface PolylinePoint : SM3DARPointOfInterest 
{
    NSArray *coords;
}

@property (nonatomic, retain) NSArray *coords;

- (id) initWithWorldCoordinates:(NSArray *)coords 
                     atLocation:(CLLocation *)location 
                     properties:(NSDictionary *)props;

@end
