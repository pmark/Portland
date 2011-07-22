//
//  ProjectedElevationGrid.h
//  BezierGarden
//
//  Created by P. Mark Anderson on 10/9/10.
//  Copyright 2010 Spot Metrix, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "SM3DAR.h"
#import "Globals.h"


@interface ProjectedElevationGrid : NSObject 
{
	CLLocation *gridCenter;
    CLLocation *gridPointSW;
    CLLocation *gridPointNE;
}

@property (nonatomic, retain) CLLocation *gridCenter;
@property (nonatomic, retain) CLLocation *gridPointSW;
@property (nonatomic, retain) CLLocation *gridPointNE;

- (id) initFromFile:(NSString*)bundleFileName;
- (id) initAroundLocation:(CLLocation*)origin;
- (NSArray*) googlePathElevationBetween:(CLLocation*)point1 and:(CLLocation*)point2 samples:(NSInteger)samples;
- (CLLocation*) locationAtDistanceInMetersNorth:(CLLocationDistance)northMeters East:(CLLocationDistance)eastMeters fromLocation:(CLLocation*)origin;
- (void) buildArray;
- (NSString *) urlEncode:(NSString*)unencoded;
- (void) printElevationPoints:(BOOL)saveToCache;
- (CLLocation *) locationAtDistanceInMeters:(CLLocationDistance)meters bearingDegrees:(CLLocationDistance)bearing fromLocation:(CLLocation *)origin;
- (Coord3D *) worldCoordinates;
- (NSString *) dataDir;
- (NSString *) dataFilePath;
- (void) loadDataFile:(NSString*)filePath;

@end
