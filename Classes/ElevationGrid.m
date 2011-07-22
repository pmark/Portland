//
//  ElevationGrid.m
//  BezierGarden
//
//  Created by P. Mark Anderson on 10/9/10.
//  Copyright 2010 Spot Metrix, Inc. All rights reserved.
//

#import "ElevationGrid.h"
#import "NSDictionary+BSJSONAdditions.h"

#define DEG2RAD(A)			((A) * 0.01745329278)
#define RAD2DEG(A)			((A) * 57.2957786667)

// WGS-84 ellipsoid
#define RADIUS_EQUATORIAL_A 6378137
#define RADIUS_POLAR_B 6356752.3142
#define INVERSE_FLATTENING 	1/298.257223563



@implementation ElevationGrid

@synthesize gridCenter;
@synthesize gridOrigin;
@synthesize gridPointSW;
@synthesize gridPointNW;
@synthesize gridPointNE;
@synthesize gridPointSE;
@synthesize lowestElevation;
@synthesize highestElevation;
@synthesize sm3dar;

- (void) dealloc
{
	self.gridOrigin = nil;
    self.gridCenter = nil;
    self.gridPointSW = nil;
    self.gridPointNW = nil;
    self.gridPointNE = nil;
    self.gridPointSE = nil;

    [sm3dar release];
    
    [super dealloc];
}

- (id) initFromFile:(NSString*)bundleFileName
{
    if (self = [super init])
    {
        self.lowestElevation = INT_MAX;
        self.highestElevation = INT_MIN;
        self.gridOrigin = nil;
        
        NSString *filePath = [[NSBundle mainBundle] pathForResource:bundleFileName ofType:nil];
        [self loadWorldCoordinateDataFile:filePath];        
    }
    
    return self;
}

- (id) initAroundLocation:(CLLocation*)center
{
    if (self = [super init])
    {
        self.lowestElevation = INT_MAX;
        self.highestElevation = INT_MIN;
        self.gridCenter = center;
        
        BOOL forceReload = NO;
        
        if (forceReload || ![self buildArrayFromCache])
        {
            [self buildArray];
        }
    }
    
    return self;
}

#pragma mark -
- (Coord3D*) worldCoordinates
{
    return *worldCoordinateDataHigh;
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
    NSString *cacheFileName = [NSString stringWithFormat:@"elevation_google_lat%.1f_lon%.1f_samples%.0f_size%.0f.txt",
                               gridCenter.coordinate.latitude,
                               gridCenter.coordinate.longitude,
                               ELEVATION_PATH_SAMPLES,
                               ELEVATION_LINE_LENGTH_HIGH];
    
    
    return [[self dataDir] stringByAppendingPathComponent:cacheFileName];

    
    /* // old way
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES); 
    NSString *documentsDirectoryPath = [paths objectAtIndex:0];
    return [documentsDirectoryPath stringByAppendingPathComponent:@"elevation_grid.txt"];
    */
    
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
        
        if (alt < lowestElevation)
            self.lowestElevation = alt;
        if (alt > highestElevation)
            self.highestElevation = alt;
                
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
//        CGFloat deltaLng = atanf((ELEVATION_LINE_LENGTH_HIGH/2) / [self longitudinalRadius:origin.coordinate.latitude]);
     	longitude = origin.coordinate.longitude + deltaLng;
    }
    
	return [[[CLLocation alloc] initWithLatitude:latitude longitude:longitude] autorelease];
}

- (CLLocation *) locationEastOf:(CLLocation *)northPoint byDegrees:(CLLocationDegrees)lonSegLenDegrees
{
    return [[[CLLocation alloc] initWithLatitude:northPoint.coordinate.latitude 
                                       longitude:northPoint.coordinate.longitude + lonSegLenDegrees] autorelease];
    
}

- (void) findGridCornerPoints
{
    // Compute SW corner point.
    
    CGFloat halfLineLength = ELEVATION_LINE_LENGTH_HIGH / 2;    
    CGFloat cornerPointDistanceMeters = sqrtf( 2 * (halfLineLength * halfLineLength) );
    CGFloat bearingDegrees = -135.0;
    
    
    // Get the south-west point location.
    
    self.gridPointSW = [self locationAtDistanceInMeters:cornerPointDistanceMeters 
                                         bearingDegrees:bearingDegrees
                                           fromLocation:gridCenter];
    self.gridOrigin = gridPointSW;
    
    
    // Get the north-east point location.
    
    self.gridPointNE = [self locationAtDistanceInMeters:cornerPointDistanceMeters 
                                         bearingDegrees:bearingDegrees+180.0
                                           fromLocation:gridCenter];
        
    // Make the NW point.
    
    self.gridPointNW = [[[CLLocation alloc] initWithLatitude:gridPointNE.coordinate.latitude 
                                                   longitude:gridPointSW.coordinate.longitude] autorelease];
    
    // Make the SE point.
    
    self.gridPointSE = [[[CLLocation alloc] initWithLatitude:gridPointSW.coordinate.latitude 
                                                   longitude:gridPointNE.coordinate.longitude] autorelease];
    
}

- (void) buildArray
{    
    [self findGridCornerPoints];
     
    // Get the longitude grid segment length in degrees.
    
    CLLocationDegrees lineLengthDegrees = fabsf(
                                                (180 + gridPointSW.coordinate.longitude) -
                                                (180 + gridPointNE.coordinate.longitude));
    
    CLLocationDegrees lonSegLenDegrees = lineLengthDegrees / (ELEVATION_PATH_SAMPLES + 1);
    
    
    // The elevation grid's origin is in the SW.
    
    CLLocation *southPoint = gridPointSW;
    CLLocation *northPoint = gridPointNW;
    
    for (int i=0; i < ELEVATION_PATH_SAMPLES; i++)
    {        
        NSLog(@"Getting elevations between %@ and %@", southPoint, northPoint);
        
        NSArray *pathLocations = [self googlePathElevationBetween:southPoint 
                                                              and:northPoint 
                                                          samples:ELEVATION_PATH_SAMPLES];    
        
        
        // Validate path elevation data returned from google's elevation API.
        
        if (!pathLocations || [pathLocations count] == 0)
        {
            //NSLog(@"[EG] WARNING: Google failed.");
			continue;            
        }
                
        // Parse results.
        
        for (int j=0; j < ELEVATION_PATH_SAMPLES; j++)
        {
            CLLocation *tmpLocation = [pathLocations objectAtIndex:j];
            
            ElevationPoint ep;
            ep.coordinate = tmpLocation.coordinate;
            ep.elevation = tmpLocation.altitude;

            elevationPointsHigh[j][i] = ep;            

            // Project the point.
            
            worldCoordinateDataHigh[j][i] = [SM3DARController worldCoordinateFor:tmpLocation];            
        }
        

        // Move meridian points to the east and reiterate.
        
        NSLog(@"Moving east: %.3f deg", lonSegLenDegrees);
        
		southPoint = [self locationEastOf:southPoint byDegrees:lonSegLenDegrees];        
		northPoint = [self locationEastOf:northPoint byDegrees:lonSegLenDegrees];                
        
    }

	[self printElevationData:YES];
}

// Returns YES if cache file was used.
- (BOOL) buildArrayFromCache
{
    [self findGridCornerPoints];
    
    BOOL loadedCacheFile = NO;
    
    NSString *path = [self dataFilePath];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSLog(@"[EG] Checking for cache file at %@", path);
    
    if ([fileManager fileExistsAtPath:path])
    {
        [self loadElevationPointDataFile:path];
        
        loadedCacheFile = YES;
    }
    
    return loadedCacheFile;
}

- (void) printElevationData:(BOOL)saveToCache
{
    CGFloat len = ELEVATION_LINE_LENGTH_HIGH / 1000.0;
    NSMutableString *str = [NSMutableString stringWithFormat:@"\n\n%.0fx%.0f elevation samples in a %.1f sq km grid\n", ELEVATION_PATH_SAMPLES, len];
    NSMutableString *epStr = [NSMutableString string];
    
    for (int i=0; i < ELEVATION_PATH_SAMPLES; i++)
    {
        [str appendString:@"\n"];
        [epStr appendString:@"\n"];

        for (int j=0; j < ELEVATION_PATH_SAMPLES; j++)
        {
            ElevationPoint ep = elevationPointsHigh[i][j];

            // NOTE: lon,lat,alt
            
            [epStr appendFormat:@"%f,%f,%f ", ep.coordinate.longitude, ep.coordinate.latitude, ep.elevation];            
            
#if 0            
            Coord3D c = worldCoordinateDataHigh[i][j];
            
            c.z -= sm3dar.currentLocation.altitude;
            
            CGFloat elevation = c.z;

            if (abs(elevation) < 10) [str appendString:@" "];
            if (abs(elevation) < 100) [str appendString:@" "];
            if (abs(elevation) < 1000) [str appendString:@" "];
            
            if (elevation < 0)
            {
                [str replaceCharactersInRange:NSMakeRange(0, 1) withString:@""];
            }

            [str appendFormat:@"%.1f, %.1f, %.1f  ", c.x, c.y, c.z];            
            [str appendFormat:@"%.0f ", elevation];                        
#endif
        }

    }

//    NSLog(@"\n\nWorld coordinates:\n");
//    [str appendString:@"\n\n"];
//    NSLog(str, 0);
//
//    NSLog(@"\n\nElevation points:\n");
//    NSLog(epStr, 0);

    if (saveToCache)
    {
        NSString *filePath = [self dataFilePath];
        NSLog(@"[EG] Saving elevation points to %@", filePath);
        [epStr writeToFile:filePath atomically:NO encoding:NSUTF8StringEncoding error:nil];
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
- (void) loadElevationPointDataFile:(NSString*)filePath
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
            NSLog(@"[EG] ERROR loading data file: ", [error localizedDescription]);
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
                        
                        ElevationPoint ep;
                        
                        @try 
                        {
                            // lon, lat, alt
                            
                            ep.coordinate.longitude = [[xyz objectAtIndex:0] doubleValue];
                            ep.coordinate.latitude = [[xyz objectAtIndex:1] doubleValue];
                            ep.elevation = [[xyz objectAtIndex:2] doubleValue];
                            
                            if (ep.elevation < lowestElevation)
                                self.lowestElevation = ep.elevation;
                            if (ep.elevation > highestElevation)
                                self.highestElevation = ep.elevation;
                        }
                        @catch (NSException *e) 
                        {
                            NSLog(@"[EG] Unable to convert triplet to coordinate: %@", [e reason]);
                            j++;
                            continue;                                
                        }
                        
                        elevationPointsHigh[i][j] = ep;


                        // Convert point to world coordinate.
                        
                        CLLocation *tmpLocation = [[CLLocation alloc] initWithCoordinate:ep.coordinate 
                                                                                altitude:ep.elevation 
                                                                      horizontalAccuracy:-1 
                                                                        verticalAccuracy:-1
                                                                               timestamp:nil];


                        // Convert location to world coordinate.
                        
                        Coord3D c = [SM3DARController worldCoordinateFor:tmpLocation];
                        c.z -= sm3dar.userLocation.altitude;
                        worldCoordinateDataHigh[i][j] = c;
                        [tmpLocation release];

                        
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
        
        [self printElevationData:NO];
    }
    else
    {
        NSLog(@"[EG] No cache file.");
    }
}

- (void) loadWorldCoordinateDataFile:(NSString*)filePath
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
            NSLog(@"[EG] ERROR: ", [error localizedDescription]);
        }
        else
        {
            //NSLog(@"\n\n%@\n\n", coordData);
            
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
                        
                        Coord3D coord;
                        
                        @try 
                        {
                            coord.x = i * GRID_CELL_SIZE_HIGH;
                            coord.y = j * GRID_CELL_SIZE_HIGH;
                            coord.z = [[xyz objectAtIndex:2] floatValue];
                            
                            if (coord.z < lowestElevation)
                                self.lowestElevation = coord.z;
                            if (coord.z > highestElevation)
                                self.highestElevation = coord.z;
                            
                        }
                        @catch (NSException *e) 
                        {
                            NSLog(@"[EG] Unable to convert triplet to coordinate: %@", [e reason]);
                            j++;
                            continue;                                
                        }
                        
                        //NSLog(@"[%i][%i] Z: %.0f", i, j, coord.z);
                        
                        worldCoordinateDataHigh[i][j] = coord;
                        
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
        
        [self printElevationData:NO];
    }
    else
    {
        NSLog(@"[EG] No cache file.");
    }
}

- (BoundingBox) boundingBox:(CLLocation *)sampleLocation
{
    int rowCount = ELEVATION_PATH_SAMPLES;
    int columnCount = ELEVATION_PATH_SAMPLES;
    
    CLLocationDegrees lonWest = gridPointSW.coordinate.longitude;
    CLLocationDegrees lonEast = gridPointSE.coordinate.longitude;
    CLLocationDegrees latSouth = gridPointSW.coordinate.latitude;
    CLLocationDegrees latNorth = gridPointNW.coordinate.latitude;
    
    CLLocationDegrees lonSpanCell = (lonEast + 180.0) - (lonWest + 180.0);
    CLLocationDegrees latSpanCell = (latNorth + 180.0) - (latSouth + 180.0);
    
    CLLocationDegrees lonSpanPoint = (sampleLocation.coordinate.longitude + 180.0) - (lonWest + 180.0);
    CLLocationDegrees latSpanPoint = (sampleLocation.coordinate.latitude + 180.0) - (latSouth + 180.0);

    CGFloat u = lonSpanPoint / lonSpanCell;
    CGFloat v = latSpanPoint / latSpanCell;

    int columnIndex = (u * (columnCount-1));  
    int rowIndex = (v * (rowCount-1));  

    BoundingBox bbox;
    
    if (rowIndex >= rowCount || columnIndex >= columnCount)
    {
        // bad
        NSLog(@"\n\nERROR: Sample location's bounding box is out of bounds.\n\nsample: %@ \nSW: %@ \nNE: %@ \n",
              sampleLocation, gridPointSW, gridPointNE);        
        ElevationPoint ep0;
        ep0.coordinate.latitude = ep0.coordinate.longitude = -1.0;
        ep0.elevation = -1.0;
        bbox.a = bbox.b = bbox.c = bbox.d = ep0;
    }
    else
    {
        // TODO: Confirm that the row/col indices aren't reversed. 
        // The resulting bbox should look like this:
        //   C  D
        //   A  B
        //
        
        bbox.a = elevationPointsHigh[rowIndex][columnIndex];
        bbox.b = elevationPointsHigh[rowIndex][columnIndex+1];
        bbox.c = elevationPointsHigh[rowIndex+1][columnIndex];
        bbox.d = elevationPointsHigh[rowIndex+1][columnIndex+1];
    }
    
    return bbox;
}

- (WorldCoordinateBoundingBox) worldCoordinateBoundingBox:(Coord3D)sampleCoord
{
    int rowCount = ELEVATION_PATH_SAMPLES;
    int columnCount = ELEVATION_PATH_SAMPLES;
    
    CGFloat xWest = worldCoordinateDataHigh[0][0].x;  // SW
    CGFloat xEast = worldCoordinateDataHigh[0][columnCount-1].x;  // SE
    CGFloat ySouth = worldCoordinateDataHigh[0][0].y;  // SW
    CGFloat yNorth = worldCoordinateDataHigh[rowCount-1][0].y;  // NW
    
    CGFloat xSpanCell = (xEast + 180.0) - (xWest + 180.0);
    CGFloat ySpanCell = (yNorth + 180.0) - (ySouth + 180.0);
    
    CGFloat xSpanPoint = (sampleCoord.x + 180.0) - (xWest + 180.0);
    CGFloat ySpanPoint = (sampleCoord.y + 180.0) - (ySouth + 180.0);
    
    CGFloat u = xSpanPoint / xSpanCell;
    CGFloat v = ySpanPoint / ySpanCell;
    
    int columnIndex = (u * (columnCount-1));  
    int rowIndex = (v * (rowCount-1));  
    
    WorldCoordinateBoundingBox bbox;
    
    if (rowIndex >= rowCount || columnIndex >= columnCount)
    {
        // bad
        NSLog(@"\n\nERROR: Sample location's bounding box is out of bounds.\n\n");        
    }
    else
    {
        // TODO: Confirm that the row/col indices aren't reversed. 
        // The resulting bbox should look like this:
        //   C  D
        //   A  B
        //
        
        bbox.a = worldCoordinateDataHigh[rowIndex][columnIndex];
        bbox.b = worldCoordinateDataHigh[rowIndex][columnIndex+1];
        bbox.c = worldCoordinateDataHigh[rowIndex+1][columnIndex];
        bbox.d = worldCoordinateDataHigh[rowIndex+1][columnIndex+1];
    }
    
    return bbox;
}

- (CLLocationDistance) elevationAtLocation:(CLLocation*)referenceLocation
{
    BoundingBox bbox = [self boundingBox:referenceLocation];

    return [self interpolateBetweenA:bbox.a 
                                   B:bbox.b 
                                   C:bbox.c 
                                   D:bbox.d 
                                   u:referenceLocation.coordinate.longitude 
                                   v:referenceLocation.coordinate.latitude];    
}

- (CLLocationDistance) elevationAtCoordinate:(CLLocationCoordinate2D)coord
{
    CLLocation *location = [[[CLLocation alloc] initWithLatitude:coord.latitude longitude:coord.longitude] autorelease];
    return [self elevationAtLocation:location];
}

- (CLLocationDistance) elevationAtWorldCoordinate:(Coord3D)referenceCoord
{
    WorldCoordinateBoundingBox bbox = [self worldCoordinateBoundingBox:referenceCoord];
    
    return [self interpolateWorldCoordinateBetweenA:bbox.a 
                                   B:bbox.b 
                                   C:bbox.c 
                                   D:bbox.d 
                                   u:referenceCoord.x 
                                   v:referenceCoord.y];    
}

- (CLLocationDistance) interpolateValueBetweenA:(Coord3D)coordA B:(Coord3D)coordB C:(Coord3D)coordC D:(Coord3D)coordD u:(double)u v:(double)v
{
    double cellWidth = coordB.x - coordA.x;
    double cellHeight = coordC.y - coordA.y;
    
//    NSLog(@"cellWidth %f", cellWidth);
//    NSLog(@"cellHeight %f", cellHeight);
    
    double fractionalU = (coordB.x - u) / cellWidth;
    double fractionalV = (v - coordA.y) / cellHeight;
    
//    NSLog(@"fractionalU %f", fractionalU);
//    NSLog(@"fractionalV %f", fractionalV);
    
    double a = (1 - fractionalU) * (1 - fractionalV);
    double b = fractionalU * (1 - fractionalV);
    double c = (1 - fractionalU) * fractionalV;
    double d = fractionalU * fractionalV;
    
    double aElevationComponent = coordA.z * a;
    double bElevationComponent = coordB.z * b;
    double cElevationComponent = coordC.z * c;
    double dElevationComponent = coordD.z * d;
    
//    NSLog(@"a %f", a);
//    NSLog(@"b %f", b);
//    NSLog(@"c %f", c);
//    NSLog(@"d %f", d);
//    
//    NSLog(@"aElevationComponent %f", aElevationComponent);
//    NSLog(@"bElevationComponent %f", bElevationComponent);
//    NSLog(@"cElevationComponent %f", cElevationComponent);
//    NSLog(@"dElevationComponent %f", dElevationComponent);
    
    double pointElevation = aElevationComponent + bElevationComponent+cElevationComponent + dElevationComponent;
    
//    NSLog(@"Elevation %f", pointElevation);
    
    return pointElevation;
}

- (CLLocationDistance) interpolateWorldCoordinateBetweenA:(Coord3D)coordA B:(Coord3D)coordB C:(Coord3D)coordC D:(Coord3D)coordD u:(double)u v:(double)v
{
    return [self interpolateValueBetweenA:coordA B:coordB C:coordC D:coordD u:u v:v];    
}

- (CLLocationDistance) interpolateBetweenA:(ElevationPoint)epa B:(ElevationPoint)epb C:(ElevationPoint)epc D:(ElevationPoint)epd u:(double)u v:(double)v
{
    Coord3D coordA, coordB, coordC, coordD;
    
    coordA.x = epa.coordinate.longitude;
    coordA.y = epa.coordinate.latitude;
    coordA.z = epa.elevation;
    
    coordB.x = epb.coordinate.longitude;
    coordB.y = epb.coordinate.latitude;
    coordB.z = epb.elevation;
    
    coordC.x = epc.coordinate.longitude;
    coordC.y = epc.coordinate.latitude;
    coordC.z = epc.elevation;
    
    coordD.x = epd.coordinate.longitude;
    coordD.y = epd.coordinate.latitude;
    coordD.z = epd.elevation;

    return [self interpolateValueBetweenA:coordA B:coordB C:coordC D:coordD u:u v:v];
}

- (CGFloat) centerpointElevation
{
    return [self elevationAtLocation:self.gridCenter];
}

@end
