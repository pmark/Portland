//
//  HoodGrid.m
//  BezierGarden
//
//  Created by Thomas Burke on 1/27/11.
//  Copyright 2011 Box Elder Solutions, LLC. All rights reserved.
//

#import "Coordinate.h"
#import "HoodGrid.h"
#import "NSDictionary+BSJSONAdditions.h"

@implementation HoodGrid

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


- (NSString *) urlEncode:(NSString*)unencoded
{
	return (NSString *)CFURLCreateStringByAddingPercentEscapes(
                                                               NULL,
                                                               (CFStringRef)unencoded,
                                                               NULL,
                                                               (CFStringRef)@"!*'();:@&=+$,/?%#[]|",
                                                               kCFStringEncodingUTF8);
}


// Returns an array of sorted Coordinate[].
- (NSArray*) fetchElevationPoints
{
/*
 // fetch data
    NSString *requestURI = HOOD_ELEVATION_DATASOURCE;

//    NSString *requestURI = [self urlEncode:HOOD_ELEVATION_DATASOURCE];
    
    
	// Fetch the elevations from geocouch as JSON.
    NSError *error = nil;
    NSLog(@"[EG] URL:\n\n%@\n\n", requestURI);
    
    // parse JSON
    NSString *responseJSON = [NSString stringWithContentsOfURL:[NSURL URLWithString:requestURI] 
                                                      encoding:NSUTF8StringEncoding error:&error];    
    
*/
    
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"hood" ofType:@"json"];            
    NSError *error = nil;
    NSLog(@"[BGVC] Loading Mount Hood from %@", filePath);
    NSString *responseJSON = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
    
    if (error)
    {
        NSLog(@"[BGVC] ERROR parsing JSON: ", [error localizedDescription]);
    }
    
    
    if ([responseJSON length] == 0 || error)
    {
        NSLog(@"[EG] Empty response. %@, %@", [error localizedDescription], [error userInfo]);
        return nil;
    }
    
//    NSLog(@"%@", responseJSON);
    
    // Parse the JSON response.
    id data = [NSDictionary dictionaryWithJSONString:responseJSON];
    
    // Get the result data items. See example below.
    /* 
     {
     {"update_seq":230401,"rows":[
     {"id":"c9d94056543bd73f8a15de2f671e608b",
     "bbox":[-121.767222222076,45.304722222054,-121.767222222076,45.304722222054],
     "value":933},
     }
     */
    
	NSArray *results = [self getChildren:data parent:@"rows"];
    //NSLog(@"RESULTS:\n\n%@", results);
    
//    NSInteger coordCount = sqrt([results count]);
    
//    NSDictionary *lineData = [NSMutableDictionary dictionaryWithCapacity:coordCount];
    NSDictionary *lineData = [NSMutableDictionary dictionary];
    
//    NSInteger skipper = 0;
    
    for (NSDictionary *rowdata in results)
    {
//        if ((skipper++ % 6) != 0) continue;
            
        // Extract this row's 3 coordinate values.
        
        NSArray *bbox = [rowdata objectForKey:@"bbox"];
        
        NSString *value = [rowdata objectForKey:@"value"];
        
        NSString *lngStr = [bbox objectAtIndex:0];                                
        CLLocationDegrees longitude = [lngStr doubleValue];
        
        NSString *latStr = [bbox objectAtIndex:1];
        CLLocationDegrees latitude = [latStr doubleValue];

        CGFloat elevation = [value floatValue];
        

        // Create a Coordinate.
        
        Coordinate *c = [[Coordinate alloc] initWithLatitude:latitude longitude:longitude elevation:elevation];
        
        
        // Get or create this row's bucket.
        
        NSString *bucketKey = [NSString stringWithFormat:@"%d", latitude];
        
        NSMutableArray *lineBucket = [lineData objectForKey:bucketKey];
        
        if (!lineBucket)
        {
            // Create a bucket of all points in a single line.
            
//            lineBucket = [NSMutableArray arrayWithCapacity:coordCount];
            lineBucket = [NSMutableArray array];
            [lineData setValue:lineBucket forKey:bucketKey];
        }
        
        
        // Add this coordinate to the row bucket.
        
        [lineBucket addObject:c];           

        [c release];
    }
    
    
    // For each row
    
    for (NSArray *lineBucket in [lineData allValues])
    {
        // Sort columns by ascending longitude in bucket.
        
        [lineBucket sortedArrayUsingSelector:@selector(longitude)];
    }
    
    NSArray *latitudeArray = [lineData allKeys];

    // Sort latitude array 
    
    [latitudeArray sortedArrayUsingSelector:@selector(doubleValue)];
    

    // For each latitude key, build an array of rows
    
//    NSMutableArray *sortedRows = [NSMutableArray arrayWithCapacity:coordCount];
    NSMutableArray *sortedRows = [NSMutableArray array];
    
//    skipper = 0;
    for (NSString *bucketKey in latitudeArray)
    {
//        if ((skipper++ % 6) != 0) continue;
        
        NSArray *lineBucket = [lineData objectForKey:bucketKey];
                               
        [sortedRows addObject:lineBucket];
    }
    
    
    return sortedRows;
}

- (void) gridToWorldCoordinates:(NSArray *)rows
{
    
    // For each row of Coordinate objects, 
    // convert to Coord3D
    
    
    
#if 0
    for (int rowNumber=0; rowNumber < [rows count]; rowNumber++)
    {
        NSArray *row = [rows objectAtIndex:rowNumber];
        
        for (int colNumber=0; colNumber < [row count]; colNumber++)
        {
            Coordinate *coordinate = [row objectAtIndex:colNumber];            
            if (!coordinate) continue;
                        
            worldCoordinateDataHigh[rowNumber][colNumber] = [coordinate toCoord3D];
        }
        
    }
    
#else
    
    // Cool maths
    
    CGFloat half = ELEVATION_PATH_SAMPLES / 2.0;
    
    for (int rowNumber=0; rowNumber < ELEVATION_PATH_SAMPLES; rowNumber++)
    {
        NSInteger rnd = (rand() % 3);

        CGFloat rowpct = rowNumber / ELEVATION_PATH_SAMPLES;
        
        CGFloat rowdegrees = (2 * M_PI * rowpct) + swellDegrees;

        CGFloat zex = 110 + ((rnd/4) * 30);
        
        
        for (int colNumber=0; colNumber < ELEVATION_PATH_SAMPLES; colNumber++)
        {
            Coord3D c;
            
            CGFloat colpct = colNumber / ELEVATION_PATH_SAMPLES;

            CGFloat coldegrees = (2 * M_PI * colpct) + swellDegrees;
            
            CGFloat zrnd1, zrnd2;
            

            
            zrnd1 = sinf(coldegrees);
            zrnd2 = sinf(rowdegrees);

            switch (rnd) 
            {                    
                case 0:
                    zrnd1 = sinf(coldegrees);
                    zrnd2 = sinf(rowdegrees) * (1.4);
                    break;
                
                default:
                    zrnd1 = sinf(coldegrees);
                    zrnd2 = sinf(rowdegrees);
                    break;
            }

#endif
            c.z = (zrnd1 + zrnd2) * zex;  

            c.x = (colNumber - half) * 60; //(60 + (rnd*4));
            c.y = (rowNumber - half) * 60;
            
            
            // Dome tarp is sin + sin
            
            worldCoordinateDataHigh[rowNumber][colNumber] = c;
        }
    }    
    
}

- (void) refresh
{
    swellDegrees += M_PI / 8;
    
    [self gridToWorldCoordinates:nil];
}

- (id) init
{
    if (self = [super init])
    {
//        NSArray *gridRows = [self fetchElevationPoints];
        NSArray *gridRows = nil;
        swellDegrees = 0;
        
        [self gridToWorldCoordinates:gridRows];
    }
    
    return self;
}



@end
