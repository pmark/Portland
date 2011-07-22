//
//  ElevationGrid.h
//  BezierGarden
//
//  Created by P. Mark Anderson on 10/9/10.
//  Copyright 2010 Spot Metrix, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "SM3DAR.h"
#import "Globals.h"

#define GOOGLE_ELEVATION_API_URL_FORMAT @"http://maps.googleapis.com/maps/api/elevation/json?path=%@&samples=%i&sensor=false"
#define SM3DAR_ELEVATION_API_URL_FORMAT @"http://localhost:5984/hood1/_design/point_elevation/_spatial/points?bbox=%@"


@interface ElevationGrid : NSObject 
{
	CLLocation *gridCenter;
	CLLocation *gridOrigin;
    CLLocation *gridPointSW;
    CLLocation *gridPointNW;
    CLLocation *gridPointNE;
    CLLocation *gridPointSE;
    CGFloat lowestElevation;
    CGFloat highestElevation;
    
    SM3DARController *sm3dar;
}

@property (nonatomic, retain) CLLocation *gridCenter;
@property (nonatomic, retain) CLLocation *gridOrigin;
@property (nonatomic, retain) CLLocation *gridPointSW;
@property (nonatomic, retain) CLLocation *gridPointNW;
@property (nonatomic, retain) CLLocation *gridPointNE;
@property (nonatomic, retain) CLLocation *gridPointSE;
@property (nonatomic, retain) SM3DARController *sm3dar;
@property (nonatomic, assign) CGFloat lowestElevation;
@property (nonatomic, assign) CGFloat highestElevation;

//- (id) initFromCache;
- (id) initFromFile:(NSString*)bundleFileName;
- (id) initAroundLocation:(CLLocation*)origin;
- (NSArray*) googlePathElevationBetween:(CLLocation*)point1 and:(CLLocation*)point2 samples:(NSInteger)samples;
- (CLLocation*) locationAtDistanceInMetersNorth:(CLLocationDistance)northMeters East:(CLLocationDistance)eastMeters fromLocation:(CLLocation*)origin;
- (void) buildArray;
- (NSString *) urlEncode:(NSString*)unencoded;
- (void) printElevationData:(BOOL)saveToCache;
- (CLLocation *) locationAtDistanceInMeters:(CLLocationDistance)meters bearingDegrees:(CLLocationDistance)bearing fromLocation:(CLLocation *)origin;
- (Coord3D *) worldCoordinates;
- (NSString *) dataFilePath;
- (void) loadElevationPointDataFile:(NSString*)filePath;
- (void) loadWorldCoordinateDataFile:(NSString*)filePath;
- (CLLocationDistance) elevationAtLocation:(CLLocation*)referenceLocation;
- (CLLocationDistance) elevationAtCoordinate:(CLLocationCoordinate2D)coord;
- (CLLocationDistance) elevationAtWorldCoordinate:(Coord3D)referenceCoord;
- (BOOL) buildArrayFromCache;
- (CLLocationDistance) interpolateWorldCoordinateBetweenA:(Coord3D)coordA B:(Coord3D)coordB C:(Coord3D)coordC D:(Coord3D)coordD u:(double)u v:(double)v;
- (CLLocationDistance) interpolateBetweenA:(ElevationPoint)epa B:(ElevationPoint)epb C:(ElevationPoint)epc D:(ElevationPoint)epd u:(double)u v:(double)v;
- (CGFloat) centerpointElevation;

@end
