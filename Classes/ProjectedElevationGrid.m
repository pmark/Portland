//
//  ProjectedElevationGrid.m
//  BezierGarden
//
//  Created by P. Mark Anderson on 10/9/10.
//  Copyright 2010 Spot Metrix, Inc. All rights reserved.
//

#import "ProjectedElevationGrid.h"
#import "NSDictionary+BSJSONAdditions.h"

#define DEG2RAD(A)			((A) * 0.01745329278)
#define RAD2DEG(A)			((A) * 57.2957786667)

// WGS-84 ellipsoid
#define RADIUS_EQUATORIAL_A 6378137
#define RADIUS_POLAR_B 6356752.3142
#define INVERSE_FLATTENING 	1/298.257223563



@implementation ProjectedElevationGrid

@synthesize gridCenter;
@synthesize gridPointSW;
@synthesize gridPointNE;

- (void) dealloc
{
    self.gridCenter = nil;
    self.gridPointSW = nil;
    self.gridPointNE = nil;
    
    [super dealloc];
}

- (id) initFromFile:(NSString*)bundleFileName
{
    if (self = [super init])
    {
        NSString *filePath = [[NSBundle mainBundle] pathForResource:bundleFileName ofType:nil];
        [self loadDataFile:filePath];        
    }
    
    return self;
}

- (id) initAroundLocation:(CLLocation*)center
{
    if (self = [super init])
    {
        self.gridCenter = center;
        
        [self buildArray];
    }
    
    return self;
}

#pragma mark -
- (Coord3D*) worldCoordinates
{
    return *worldCoordinateData;
}

#pragma mark -

- (NSArray*) getChildren:(id)data parent:(NSString*)parent
{	    
    if ( ! data || [data count] == 0) 
        return nil;
    
    if ([parent length] > 0)
    {
        data = [data objectForKey:parent]; 

        if ( ! data || [data count] == 0) 
            return nil;
    }
    
    if ([data isKindOfClass:[NSArray class]]) 
        return data;
    
    if ([data isKindOfClass:[NSDictionary class]]) 
        return [NSArray arrayWithObject:data];
    
    return nil;
}

- (NSString *) dataDir
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES); 
    return [paths objectAtIndex:0];
}

- (NSString *) dataFilePath
{
    NSString *cacheFileName = [NSString stringWithFormat:@"elevation_google_lat%.2f_lon%.2f_samples%.0f_size%.0f",
                               gridCenter.coordinate.latitude,
                               gridCenter.coordinate.longitude,
                               ELEVATION_PATH_SAMPLES,
                               ELEVATION_LINE_LENGTH];
    
    
    return [[self dataDir] stringByAppendingPathComponent:cacheFileName];
}

- (NSArray*) googlePathElevationBetween:(CLLocation*)point1 and:(CLLocation*)point2 samples:(NSInteger)samples
{
    NSLog(@"[EG] Fetching elevation data...");
    
    // Build the request.
    NSString *pathString = [NSString stringWithFormat:
                            @"%f,%f|%f,%f",
                            point1.coordinate.latitude, 
                            point1.coordinate.longitude,
                            point2.coordinate.latitude, 
                            point2.coordinate.longitude];
    
    NSString *requestURI = [NSString stringWithFormat:
                            GOOGLE_ELEVATION_API_URL_FORMAT,
                            [self urlEncode:pathString],
                            samples];
    
	// Fetch the elevations from google as JSON.
    NSError *error;
    NSLog(@"[EG] URL:\n\n%@\n\n", requestURI);

	NSString *responseJSON = [NSString stringWithContentsOfURL:[NSURL URLWithString:requestURI] 
                                                  encoding:NSUTF8StringEncoding error:&error];    

    
    if ([responseJSON length] == 0)
    {
        NSLog(@"[EG] Empty response. %@, %@", [error localizedDescription], [error userInfo]);
        return nil;
    }
    
    /* Example response:
    {
        "status": "OK",
        "results": [ {}, {} ]
    }
     Status code may be one of the following:
     - OK indicating the API request was successful
     - INVALID_REQUEST indicating the API request was malformed
     - OVER_QUERY_LIMIT indicating the requestor has exceeded quota
     - REQUEST_DENIED indicating the API did not complete the request, likely because the requestor failed to include a valid sensor parameter
     - UNKNOWN_ERROR indicating an unknown error
    */
    
    // Parse the JSON response.
    id data = [NSDictionary dictionaryWithJSONString:responseJSON];

    // Get the request status.
    NSString *status = [data objectForKey:@"status"];    
    NSLog(@"[EG] Request status: %@", status);    

    if ([status isEqualToString:@"OVER_QUERY_LIMIT"])
    {
        NSLog(@"[EG] Over query limit!");
        return nil;
    }

    // Get the result data items. See example below.
    /* GeoJSON
     {
         "location": 
         {
             "lat": 36.5718491,
             "lng": -118.2620657
         },
         "elevation": 3303.3430176
     }
    */
        
	NSArray *results = [self getChildren:data parent:@"results"];        
    //NSLog(@"RESULTS:\n\n%@", results);
    
    NSMutableArray *pathLocations = [NSMutableArray arrayWithCapacity:[results count]];
    NSString *elevation, *lat, *lng;
    CLLocation *tmpLocation;
    CLLocationDistance alt;
    CLLocationCoordinate2D coordinate;
    
    for (NSDictionary *oneResult in results)
    {
        NSDictionary *locationData = [oneResult objectForKey:@"location"];
        
        // TODO: Make sure the location data is valid.
        lat = [locationData objectForKey:@"lat"];
        coordinate.latitude = [lat doubleValue];
        
        lng = [locationData objectForKey:@"lng"];
        coordinate.longitude = [lng doubleValue];

        elevation = [oneResult objectForKey:@"elevation"];        
		alt = [elevation doubleValue];
                
        tmpLocation = [[CLLocation alloc] initWithCoordinate:coordinate 
                                                    altitude:alt
                                          horizontalAccuracy:-1 
                                            verticalAccuracy:-1 
                                                   timestamp:nil];
        
        [pathLocations addObject:tmpLocation];
        [tmpLocation release];
    }
    
    return pathLocations;
}

- (CLLocation*) locationAtDistanceInMetersNorth:(CLLocationDistance)northMeters
                                           East:(CLLocationDistance)eastMeters
                                   fromLocation:(CLLocation*)origin
{
    CLLocationDegrees latitude, longitude;
    
    // Latitude
    if (northMeters == 0) 
    {
        latitude = origin.coordinate.latitude;
    }
    else
    {
        CGFloat deltaLat = 
     	latitude = origin.coordinate.latitude + deltaLat;
    }
    
    
    // Longitude
    if (eastMeters == 0) 
    {
        longitude = origin.coordinate.longitude;
    }
    else
    {
        CGFloat deltaLng = eastMeters / 10000.0;
//        CGFloat deltaLng = atanf((ELEVATION_LINE_LENGTH/2) / [self longitudinalRadius:origin.coordinate.latitude]);
     	longitude = origin.coordinate.longitude + deltaLng;
    }
    
	return [[[CLLocation alloc] initWithLatitude:latitude longitude:longitude] autorelease];
}

- (CLLocation*) pathEndpointFrom:(CLLocation*)startPoint
{
    CLLocationCoordinate2D endPoint;
    CGFloat delta = (ELEVATION_LINE_LENGTH / 10000.0);
    endPoint.latitude = startPoint.coordinate.latitude - delta;
    endPoint.longitude = startPoint.coordinate.longitude;

    return [[[CLLocation alloc] initWithCoordinate:endPoint altitude:0 horizontalAccuracy:-1 verticalAccuracy:-1 timestamp:nil] autorelease];
    
    
//    return [self locationAtDistanceInMetersNorth:-ELEVATION_LINE_LENGTH
//                                            East:0
//                                    fromLocation:startPoint];
}

- (CLLocation *) locationEastOf:(CLLocation *)northPoint byDegrees:(CLLocationDegrees)longitudeSpacingInDegrees
{
    return [[[CLLocation alloc] initWithLatitude:northPoint.coordinate.latitude 
                                                       longitude:northPoint.coordinate.longitude + longitudeSpacingInDegrees] autorelease];
    
}

- (void) printWorldCoordinates:(BOOL)saveToCache
{
    CGFloat len = ELEVATION_LINE_LENGTH / 1000.0;
    NSMutableString *str = [NSMutableString stringWithFormat:@"\n\n%.0f elevation samples in a %.1f sq km grid\n", ELEVATION_PATH_SAMPLES, len];
    NSMutableString *wpStr = [NSMutableString string];
    
    for (int i=0; i < ELEVATION_PATH_SAMPLES; i++)
    {
        [str appendString:@"\n"];
        [wpStr appendString:@"\n"];
        
        for (int j=0; j < ELEVATION_PATH_SAMPLES; j++)
        {
            Coord3D c = worldCoordinateData[i][j];
            [wpStr appendFormat:@"%.0f,%.0f,%.0f ", c.x, c.y, c.z];            
            
            CGFloat elevation = c.z;
            
            if (abs(elevation) < 10) [str appendString:@" "];
            if (abs(elevation) < 100) [str appendString:@" "];
            if (abs(elevation) < 1000) [str appendString:@" "];
            
            if (elevation < 0)
            {
                [str replaceCharactersInRange:NSMakeRange(0, 1) withString:@""];
            }
            
            [str appendFormat:@"%.0f ", elevation];                        
        }
        
    }
    
    [str appendString:@"\n\n"];
    [wpStr appendString:@"\n\n"];

    NSLog(@"\n\nElevations:\n");
    NSLog(str, 0);
    
    
    NSLog(@"\n\nWorld coordinates:\n");
    NSLog(wpStr, 0);
    
    if (saveToCache)
    {
        NSString *filePath = [self dataFilePath];
        NSLog(@"[EG] Saving world coordinates to %@", filePath);
        [wpStr writeToFile:filePath atomically:NO encoding:NSUTF8StringEncoding error:nil];
    }
    
}

- (void) projectWorldCoordinates
{
    
    // Compute reference values.    
    
    // XY position of tangent intersection point at user position (grid center).
    
    double referenceLatitude = DEG2RAD(gridCenter.coordinate.latitude);
    double referenceLongitude = DEG2RAD(gridCenter.coordinate.longitude);

    double xTangentIntercept = cos(referenceLatitude) * AVG_EARTH_RADIUS_METERS;
    double yTangentIntercept = sin(referenceLatitude) * AVG_EARTH_RADIUS_METERS;

    double yAxisTangentSlopeIntercept = yTangentIntercept - ((-1 / tan(referenceLatitude)) * xTangentIntercept);
    
    
    // Project each point.
    
    for (int i=0; i < ELEVATION_PATH_SAMPLES; i++)
    {
        for (int j=0; j < ELEVATION_PATH_SAMPLES; j++)
        {
            Coord3D worldCoordinate;
            
            ElevationPoint ep = elevationPoints[i][j];
            
            double xElevationPoint = cos(fabs(referenceLongitude - DEG2RAD(ep.coordinate.longitude))) * xTangentIntercept;

            double yElevationPoint = sin(ep.coordinate.latitude) * (AVG_EARTH_RADIUS_METERS + ep.elevation);

            double yAxisIntercept = yElevationPoint - tan(referenceLatitude) * xElevationPoint;
            
            double xIntersection = (tan(referenceLatitude) * xElevationPoint + yAxisTangentSlopeIntercept - yAxisIntercept) /
                                   (-1 / tan(referenceLatitude));

//            double yIntersection = tan(referenceLatitude) * xIntersection + yAxisIntercept;
            
            //double heightAbovePlane = sqrt( 
            //                               (pow(fabs(xElevationPoint - xIntersection), 2)) +
            //                               (pow(fabs(yTangentIntercept - yIntersection), 2)));
            
            double heightAbovePlane = (pow(sin(referenceLatitude - DEG2RAD(ep.coordinate.latitude)), 2)) /
            (2 * AVG_EARTH_RADIUS_METERS);
            
            
            worldCoordinate.z = (CGFloat)heightAbovePlane;

            worldCoordinate.x = (CGFloat)(sin(referenceLongitude - DEG2RAD(ep.coordinate.longitude)) * xTangentIntercept); 
            worldCoordinate.y = (CGFloat)(
                                          ((AVG_EARTH_RADIUS_METERS * cos(DEG2RAD(ep.coordinate.latitude))) - xElevationPoint) /
                                    (cos(M_PI/2 - referenceLatitude))
                                        );

            worldCoordinateData[i][j] = worldCoordinate;
        }
    }

    [self printWorldCoordinates:NO];
}

- (void) buildArray
{    

    // Check if file is already cached.
    
    NSString *dataFilePath = [self dataFilePath];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    if ([fm fileExistsAtPath:dataFilePath])
    {
        // Load existing data file.
        
        NSLog(@"Loading elevation data file: %@", dataFilePath);
        
        [self loadDataFile:dataFilePath];
        [self printElevationPoints:NO];
        [self projectWorldCoordinates];
        
        return;
    }
    
    
    
    // Compute SW corner point.
    
    CGFloat halfLineLength = ELEVATION_LINE_LENGTH / 2;    
    CGFloat cornerPointDistanceMeters = sqrtf( 2 * (halfLineLength * halfLineLength) );
    CGFloat bearingDegrees = -135.0;
    
    self.gridPointSW = [self locationAtDistanceInMeters:cornerPointDistanceMeters 
                                         bearingDegrees:bearingDegrees
                                           fromLocation:gridCenter];
    
    
    // Get the south-east point location.
    
    self.gridPointNE = [self locationAtDistanceInMeters:cornerPointDistanceMeters 
                                         bearingDegrees:bearingDegrees+180.0
                                           fromLocation:gridCenter];
    
    
    // Get the length between longitude lines in degrees.
    
    CLLocationDegrees pointSWLongitude = gridPointSW.coordinate.longitude;
    CLLocationDegrees pointNELongitude = gridPointNE.coordinate.longitude;
    
    CLLocationDegrees lineLengthDegrees = fabsf(
                        (180 + pointSWLongitude) -
                        (180 + pointNELongitude));
    
    NSLog(@"Grid line length: %.2f degrees of longitude", lineLengthDegrees);
    
    CLLocationDegrees longitudeSpacingInDegrees = lineLengthDegrees / ELEVATION_PATH_SAMPLES;


    // Make the line's top (NW) point.
    
    CLLocationDegrees pointNWLatitude = gridPointNE.coordinate.latitude;
    CLLocation *pointNW = [[[CLLocation alloc] initWithLatitude:pointNWLatitude longitude:pointSWLongitude] autorelease];
    
    CLLocation *southPoint = gridPointSW;
    CLLocation *northPoint = pointNW;
    
    for (int i=0; i < ELEVATION_PATH_SAMPLES; i++)
    {        
        NSLog(@"Getting elevations between SW %@ and NW %@", southPoint, northPoint);
        
        NSArray *pathLocations = [self googlePathElevationBetween:southPoint 
                                                              and:northPoint 
                                                          samples:ELEVATION_PATH_SAMPLES];    
        
        
        // Validate path elevation data returned from google's elevation API.
        
        if (!pathLocations || [pathLocations count] == 0)
        {
            NSLog(@"[EG] WARNING: Google failed.");
			continue;            
        }
        
        
        // Move meridian points east.
        
        NSLog(@"Moving east: %.3f deg", longitudeSpacingInDegrees);
        
		southPoint = [self locationEastOf:southPoint byDegrees:longitudeSpacingInDegrees];        
		northPoint = [self locationEastOf:northPoint byDegrees:longitudeSpacingInDegrees];        

        
        // Parse results.
        
        for (int j=0; j < ELEVATION_PATH_SAMPLES; j++)
        {
            CLLocation *tmpLocation = [pathLocations objectAtIndex:j];
            
            ElevationPoint ep;
            ep.coordinate = tmpLocation.coordinate;
            ep.elevation = tmpLocation.altitude;
            elevationPoints[j][i] = ep;
        }
    }

	[self printElevationPoints:YES];
    [self projectWorldCoordinates];
}

- (void) printElevationPoints:(BOOL)saveToCache
{
    CGFloat len = ELEVATION_LINE_LENGTH / 1000.0;
    NSMutableString *str = [NSMutableString stringWithFormat:@"\n\n%.0f elevation samples in a %.1f sq km grid\n", ELEVATION_PATH_SAMPLES, len];
    NSMutableString *wpStr = [NSMutableString string];
    
    for (int i=0; i < ELEVATION_PATH_SAMPLES; i++)
    {
        [str appendString:@"\n"];
        [wpStr appendString:@"\n"];
        
        for (int j=0; j < ELEVATION_PATH_SAMPLES; j++)
        {
            ElevationPoint ep = elevationPoints[i][j];
                        
            [wpStr appendFormat:@"%f,%f,%.1f ", ep.coordinate.latitude, ep.coordinate.longitude, ep.elevation];

            CLLocationDistance elevation = ep.elevation;
            
            if (abs(elevation) < 10) [str appendString:@" "];
            if (abs(elevation) < 100) [str appendString:@" "];
            if (abs(elevation) < 1000) [str appendString:@" "];
            
            if (elevation < 0)
            {
                [str replaceCharactersInRange:NSMakeRange(0, 1) withString:@""];
            }
            
            [str appendFormat:@"%.0f ", elevation];                        
        }
        
    }
    
    [str appendString:@"\n\n"];
    [wpStr appendString:@"\n\n"];
    
    NSLog(wpStr, 0);
    
    if (saveToCache)
    {        
        NSString *filePath = [self dataFilePath];
        NSLog(@"[EG] Caching elevation points at %@", filePath);
        [wpStr writeToFile:filePath atomically:NO encoding:NSUTF8StringEncoding error:nil];
    }
}

#pragma mark -
- (NSString *) urlEncode:(NSString*)unencoded
{
	return (NSString *)CFURLCreateStringByAddingPercentEscapes(
                                                               NULL,
                                                               (CFStringRef)unencoded,
                                                               NULL,
                                                               (CFStringRef)@"!*'();:@&=+$,/?%#[]|",
                                                               kCFStringEncodingUTF8);
}

#pragma mark Vincenty

/**
 * destinationVincenty
 * Calculate destination point given start point lat/long (numeric degrees),
 * bearing (numeric degrees) & distance (in m).
 * Adapted from Chris Veness work, see
 * http://www.movable-type.co.uk/scripts/latlong-vincenty-direct.html
 *
 */
- (CLLocation *) locationAtDistanceInMeters:(CLLocationDistance)meters bearingDegrees:(CLLocationDistance)bearing fromLocation:(CLLocation *)origin
{
    CGFloat a = RADIUS_EQUATORIAL_A;
    CGFloat b = RADIUS_POLAR_B;
	CGFloat f = INVERSE_FLATTENING;
    
    CLLocationDegrees lon1 = origin.coordinate.longitude;
    CLLocationDegrees lat1 = origin.coordinate.latitude;

	CGFloat s = meters;
	CGFloat alpha1 = DEG2RAD(bearing);

    CGFloat sinAlpha1 = sinf(alpha1);
    CGFloat cosAlpha1 = cosf(alpha1);
    
    CGFloat tanU1 = (1-f) * tanf(DEG2RAD(lat1));
    CGFloat cosU1 = 1 / sqrtf((1 + tanU1*tanU1)), 
	sinU1 = tanU1*cosU1;

    CGFloat sigma1 = atan2(tanU1, cosAlpha1);
    CGFloat sinAlpha = cosU1 * sinAlpha1;
    CGFloat cosSqAlpha = 1 - sinAlpha*sinAlpha;
    CGFloat uSq = cosSqAlpha * (a*a - b*b) / (b*b);
    CGFloat A = 1 + uSq/16384*(4096+uSq*(-768+uSq*(320-175*uSq)));
    CGFloat B = uSq/1024 * (256+uSq*(-128+uSq*(74-47*uSq)));
    
    CGFloat sigma = s / (b*A);
	CGFloat sigmaP = 2*M_PI;
    
	CGFloat cos2SigmaM, sinSigma, cosSigma, deltaSigma;
    
    while (fabs(sigma-sigmaP) > 1e-12) 
	{
        cos2SigmaM = cosf(2*sigma1 + sigma);
        sinSigma = sinf(sigma);
        cosSigma = cosf(sigma);
        deltaSigma = B*sinSigma*(cos2SigmaM+B/4*(cosSigma*(-1+2*cos2SigmaM*cos2SigmaM)-
                                                         B/6*cos2SigmaM*(-3+4*sinSigma*sinSigma)*(-3+4*cos2SigmaM*cos2SigmaM)));
        sigmaP = sigma;
        sigma = s / (b*A) + deltaSigma;
    }
    
    CGFloat tmp = sinU1*sinSigma - cosU1*cosSigma*cosAlpha1;
    CGFloat lat2 = atan2(sinU1*cosSigma + cosU1*sinSigma*cosAlpha1,
                          (1-f)*sqrt(sinAlpha*sinAlpha + tmp*tmp));
    CGFloat lambda = atan2(sinSigma*sinAlpha1, cosU1*cosSigma - sinU1*sinSigma*cosAlpha1);
    CGFloat C = f/16*cosSqAlpha*(4+f*(4-3*cosSqAlpha));
    CGFloat L = lambda - (1-C) * f * sinAlpha *
    (sigma + C*sinSigma*(cos2SigmaM+C*cosSigma*(-1+2*cos2SigmaM*cos2SigmaM)));
    
//    CGFloat revAz = atan2(sinAlpha, -tmp);  // final bearing
    
	CLLocationDegrees destLatitude = RAD2DEG(lat2);
	CLLocationDegrees destLongitude = lon1+RAD2DEG(L);
	CLLocation *location = [[CLLocation alloc] initWithLatitude:destLatitude longitude:destLongitude];

    return [location autorelease];
}

#pragma mark -

- (void) loadDataFile:(NSString*)filePath
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSLog(@"[EG] loadDataFile: %@", filePath);
    
    if ([fileManager fileExistsAtPath:filePath])
    {
        // Load cached data.
        NSLog(@"[EG] Loading elevation grid from file.");
        
        NSError *error = nil;
        NSString *coordData = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
        
        if (error)
        {
            NSLog(@"[EG] ERROR loading file: ", [error localizedDescription]);
        }
        else
        {
            // Parse data.  Extract lines first.
            
            NSArray *lines = [coordData componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
            
            if (!lines || [lines count] == 0)
            {
                NSLog(@"[EG] Cache file is empty.");
            }
            else
            {
                NSInteger i = 0;
                

                // Parse each line.
                
                for (NSString *oneLine in lines)
                {

                    if ([oneLine length] == 0)
                    {
                        // Skip blank line.
                        
                        continue;
                    }
                    
                    
                    // Each coordinate triplet is separated by a space.
                    
                    NSArray *coords = [oneLine componentsSeparatedByString:@" "];
                    
                    NSInteger j = 0;
                    
                    for (NSString *csv in coords)
                    {
                        if ([csv length] == 0)
                        {
                            // Skip empty triplet.
                            continue;
                        }
                        
                        // Each coordinate is represented as X,Y,Z.
                        NSArray *xyz = [csv componentsSeparatedByString:@","];
                        
                        if (!xyz || [xyz count] < 3)
                        {
                            NSLog(@"[EG] Invalid triplet format: %@", csv);
                            
                            continue;
                        }
                        
                        ElevationPoint point;
                        
                        @try 
                        {
                            point.coordinate.latitude = [[xyz objectAtIndex:0] floatValue];
                            point.coordinate.longitude = [[xyz objectAtIndex:1] floatValue];
                            point.elevation = [[xyz objectAtIndex:2] floatValue];
                        }
                        @catch (NSException *e) 
                        {
                            NSLog(@"[EG] Unable to convert triplet to coordinate: %@", [e reason]);
                            j++;
                            continue;                                
                        }
                        
                        elevationPoints[i][j] = point;

                        j++;
                        
                        // End of triplet.
                    }
                    
                    if (j >= ELEVATION_PATH_SAMPLES)
                    {
                        // Only increment i if we parsed the right number triplets.
                        i++;
                    }
                    
                    // End of line.
                }
            }
        }        
    }
    else
    {
        NSLog(@"[EG] No cache file.");
    }
}


@end
