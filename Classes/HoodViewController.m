//
//  BezierGardenViewController.m
//  BezierGarden
//
//  Created by P. Mark Anderson on 10/6/10.
//  Copyright 2010 Spot Metrix, Inc. All rights reserved.
//

#import "HoodViewController.h"
#import "GridView.h"
#import "NSDictionary+BSJSONAdditions.h"
#import "DotView.h"
#import "CGPointUtil.h"
#import "WorldCoordinate.h"
#import "PolylinePoint.h"

#define MIN_CAMERA_ALTITUDE_METERS 2.0    // Lower than 275 meters may look bad.
#define MAX_CAMERA_ALTITUDE_METERS 10000.0
#define MAX_SPEED 350.0f

@implementation HoodViewController

@synthesize elevationGrid;
@synthesize mapView;

- (void)dealloc 
{
    self.elevationGrid = nil;
    [hoodGrid release];
    [joystick release];
    [joystickZ release];
    [originLocation release];
    [waveGrid release];
    self.mapView = nil;
    
    [super dealloc];
}


- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil 
{
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) 
    {
    }
    return self;
}

- (void) sm3darViewDidLoad
{
}

- (void) fetchGeoloqiHistory
{
    NSString *url = @"https://api.geoloqi.com/1/location/history?oauth_token=41a-de3165ae38a7a667074678df22af479af4c1b7c3&count=1500";
    NSLog(@"Fetching geoloqi history from %@", url);
    NSError *error = nil;
    NSString *json = [NSString stringWithContentsOfURL:[NSURL URLWithString:url] 
                                              encoding:NSUTF8StringEncoding 
                                                 error:&error];
    
    
    if (error)
    {
        NSLog(@"ERROR: Couldn't fetch geoloqi history. %@", [error localizedDescription]);
        return;
    }
    
    NSLog(@"Parsing geoloqi history.");

    NSDictionary *history = [NSDictionary dictionaryWithJSONString:json];
    
    /*
     {"uuid":"7a8637b9-f81f-4203-a58d-97df680adc91",
     "date":"2011-05-22T17:41:39-07:00",
     "date_ts":1306111299,
     "location":
     {
         "position":
         {
             "latitude":"40.025027389161",
             "longitude":"-105.29685357266",
             "speed":"5",
             "altitude":"1730",
             "heading":"153",
             "horizontal_accuracy":"5",
             "vertical_accuracy":"10"},
             "type":"point"
         }
     }
     */
    
    
    BOOL first = YES;
    Coord3D coord, firstCoord;    
    NSArray *allPoints = [history objectForKey:@"points"];
    NSMutableArray *coords = [NSMutableArray arrayWithCapacity:([allPoints count])];
    CLLocation *poiLocation = nil;
    
    for (NSDictionary *onePoint in [allPoints reverseObjectEnumerator]) 
    {
        NSDictionary *position = [onePoint valueForKeyPath:@"location.position"];
        
        CLLocationCoordinate2D c;        
        c.longitude = [[position objectForKey:@"longitude"] doubleValue];
        c.latitude = [[position objectForKey:@"latitude"] doubleValue];
        
        CLLocation *location = [[CLLocation alloc] initWithLatitude:c.latitude 
                                                           longitude:c.longitude];

        CGFloat halfGridSize = ELEVATION_LINE_LENGTH_HIGH / 2.0;    
        CGFloat maxRadius = sqrtf( 2.0 * (halfGridSize * halfGridSize) );

        if ([location distanceFromLocation:originLocation] > maxRadius)
            continue;
        
        coord = [SM3DARController worldCoordinateFor:location];
        coord.z = [self.elevationGrid elevationAtLocation:location] * GRID_SCALE_VERTICAL;
        
        if (poiLocation == nil)
        {
            // This is the head of the line.
            
            poiLocation = [[CLLocation alloc] initWithCoordinate:location.coordinate 
                                                        altitude:(coord.z - (elevationGrid.lowestElevation*GRID_SCALE_VERTICAL))
                                              horizontalAccuracy:-1 
                                                verticalAccuracy:-1 
                                                       timestamp:nil];
            
        }
        
        if (first)
        {
            firstCoord = coord;
            first = NO;
        }
        
        coord.x -= firstCoord.x;
        coord.y -= firstCoord.y;
        coord.z -= firstCoord.z;        
        
        NSLog(@"%.0f, %.0f, %.0f", coord.x, coord.y, coord.z);
        
        WorldCoordinate *wc = [[WorldCoordinate alloc] initWithCoord:coord];
        [coords addObject:wc];
        [wc release];
        
        [location release];
    }
    
    PolylinePoint *polyline = [[PolylinePoint alloc] initWithWorldCoordinates:coords 
                                                                   atLocation:poiLocation 
                                                                   properties:nil];
    
    [mapView.sm3dar addPointOfInterest:polyline];
    [polyline release];
    [poiLocation release];
}

- (void) addGridAtLocation:(CLLocation *)location
{
    // Create point.
    SM3DARPointOfInterest *p = [[SM3DARPointOfInterest alloc] initWithLocation:location
                                                                      properties:nil];
    
    GridView *gridView = [[GridView alloc] init];
    
    // Give the point a view.
    gridView.point = p;
    p.view = gridView;
    [gridView release];
        
    // Add point to 3DAR scene.
    [mapView addAnnotation:p];
    [p release];
}

//
// The GridView uses the global worldCoordinateDataHigh
// which is populated by the WaveGrid etc.
//
- (void) addGridAtX:(CGFloat)x Y:(CGFloat)y Z:(CGFloat)z
{
    // Create point.
    SM3DARFixture *p = [[SM3DARFixture alloc] init];
    
    GridView *gridView = [[GridView alloc] init];

    // Give the point a view.
    gridView.point = p;
    p.view = gridView;
    [gridView release];
    
    
    NSLog(@"Adding grid at %.1f, %.1f, %.1f", x, y, z);
    
    // Add point to 3DAR scene.
    [mapView.sm3dar addPointOfInterest:p];
    [p release];
}

- (void) loadSingleHoodPoint
{
    
}

//- (void) loadPointsOfInterest
- (void) sm3darLoadPoints:(SM3DARController *)_sm3dar
{
    
    NSLog(@"\n\nLoading scene...\n\n");
    
//    [mapView addBackground];
    [self addGridScene];

}

#pragma mark -

- (void) addJoystick
{
    joystick = [Joystick new];
    joystick.center = CGPointMake(80, 406);
    
    [self.view addSubview:joystick];
    [NSTimer scheduledTimerWithTimeInterval:0.05f target:self selector:@selector(updateJoystick) userInfo:nil repeats:YES];    
    
    
    // Z
    
    joystickZ = [Joystick new];
    joystickZ.center = CGPointMake(240, 406);
    
    [self.view addSubview:joystickZ];
    [NSTimer scheduledTimerWithTimeInterval:0.05f target:self selector:@selector(updateJoystickZ) userInfo:nil repeats:YES];    
}


- (void) updateJoystick 
{
    [joystick updateThumbPosition];
    
    CGFloat s = 6.2; // 4.6052;
    
    CGFloat xspeed =  joystick.velocity.x * exp(fabs(joystick.velocity.x) * s);
    CGFloat yspeed = -joystick.velocity.y * exp(fabs(joystick.velocity.y) * s);
    
    if (fabs(xspeed) > 0.0 || fabs(yspeed) > 0.0) 
    {        
        Coord3D ray = [mapView.sm3dar ray:CGPointMake(160, 240)];
        
        cameraOffset.x += (ray.x * yspeed);
        cameraOffset.y += (ray.y * yspeed);
        //        cameraOffset.z += (ray.z * yspeed);
        
        CGPoint perp = [CGPointUtil perpendicularCounterClockwise:CGPointMake(ray.x, ray.y)];        
        cameraOffset.x += (perp.x * xspeed);
        cameraOffset.y += (perp.y * xspeed);
        
        //NSLog(@"Camera (%.1f, %.1f, %.1f)", offset.x, offset.y, offset.z);
        
        [mapView.sm3dar setCameraPosition:cameraOffset];
    }
}

- (void) updateJoystickZ
{
    [joystickZ updateThumbPosition];
    
    CGFloat s = 6.2; // 4.6052;
    
    //CGFloat xspeed =  joystickZ.velocity.x * exp(fabs(joystickZ.velocity.x));
    CGFloat yspeed = -joystickZ.velocity.y * exp(fabs(joystickZ.velocity.y) * s);    
    
    /*
     if (abs(xspeed) > 0.0) 
     {   
     APP_DELEGATE.gearSpeed += xspeed;
     
     if (APP_DELEGATE.gearSpeed < 0.0)
     APP_DELEGATE.gearSpeed = 0.0;
     
     if (APP_DELEGATE.gearSpeed > 5.0)
     APP_DELEGATE.gearSpeed = 5.0;
     
     NSLog(@"speed: %.1f", APP_DELEGATE.gearSpeed);
     }
     */
    
    if (fabs(yspeed) > 0.0) 
    {        
        cameraOffset.z += yspeed;
        
        [mapView.sm3dar setCameraPosition:cameraOffset];
    }
    
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    touchCount++;
    
    UITouch *touch = [[touches allObjects] objectAtIndex:0];    
    CGPoint point = [touch locationInView:mapView.sm3dar.view];    
    
    if (touchCount == 1)
    {
        // if joysticks are visible then hide them
        if (joystick.hidden)
        {
            joystick.center = point;
            joystick.transform = CGAffineTransformMakeRotation([mapView.sm3dar screenOrientationRadians]);
            joystick.hidden = NO;
        }
        else
        {
            joystick.hidden = YES;
        }

        joystickZ.hidden = YES;
    }
    else if (touchCount == 2)
    {
        joystickZ.center = point;
        joystickZ.transform = CGAffineTransformMakeRotation([mapView.sm3dar screenOrientationRadians]);
        joystickZ.hidden = NO;
    }
    else
    {
        touchCount = 0;
    }
    
    //NSLog(@"joystick: %@\n parent: %@\n parent2: %@", joystick, joystick.superview, joystick.superview.superview);
    
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    touchCount--;
    if (touchCount < 0)
        touchCount = 0;
}


#pragma mark -

- (void)viewDidLoad 
{
    [super viewDidLoad];   
    
    mapView.sm3dar.delegate = mapView.delegate = self;
    
    
//    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"3darDisableLocationServices"])
//    {
//        [self sm3darLoadPoints:mapView.sm3dar];
//    }
    
//    joystick = [[Joystick alloc] initWithBackground:[UIImage imageNamed:@"128_white.png"]];
//    joystick.center = CGPointMake(160, 406);

//    [self.view addSubview:joystick];    
//    [NSTimer scheduledTimerWithTimeInterval:0.10f target:self selector:@selector(updateJoystick) userInfo:nil repeats:YES];    
//    [self.view becomeFirstResponder];
    
    
    [NSTimer scheduledTimerWithTimeInterval:0.3f target:waveGrid selector:@selector(refresh) userInfo:nil repeats:YES];
    
    NSLog(@"Waiting for location update...");
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self addJoystick];
}

- (void)didReceiveMemoryWarning 
{
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
    NSLog(@"[BGVC] didReceiveMemoryWarning");
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
    NSLog(@"[BGVC] viewDidUnload");
}


/*
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];    
    CGPoint touchPoint = [touch locationInView:self.view];
    [self screenTouched:touchPoint];    
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint touchPoint = [touch locationInView:self.view];
    [self screenTouched:touchPoint];    
}

#pragma mark Touches

- (void) screenTouched:(CGPoint)p {
    CGFloat zmax = MAX_CAMERA_ALTITUDE_METERS;
    CGFloat altitude = (p.y / 480.0) * zmax + MIN_CAMERA_ALTITUDE_METERS;
    SM3DAR.cameraAltitudeMeters = altitude;    
}
*/

- (void) addOBJNamed:(NSString *)objName atLatitude:(CLLocationDegrees)latitude longitude:(CLLocationDegrees)longitude
{
    SM3DARTexturedGeometryView *modelView = [[[SM3DARTexturedGeometryView alloc] 
                                              initWithOBJ:objName 
                                              textureNamed:nil] autorelease];
    
    modelView.sizeScalar = 100.0;
    modelView.color = [UIColor blueColor];

    
    
    // Add a point with a 3D view to the 3DAR scene.

    CLLocationCoordinate2D coord;
    coord.latitude = latitude;
    coord.longitude = longitude;

    CLLocationDistance altitude = ([elevationGrid elevationAtCoordinate:coord]) * GRID_SCALE_VERTICAL;
    
    altitude += 1.0;

    CLLocation *location = [[[CLLocation alloc] initWithCoordinate:coord 
                                                         altitude:altitude
                                               horizontalAccuracy:-1 
                                                 verticalAccuracy:-1 
                                                         timestamp:nil] autorelease];
    
    SM3DARPoint *poi = [[mapView.sm3dar addPointAtLocation:location 
                                                     title:objName 
                                                  subtitle:nil 
                                                       url:nil 
                                                properties:nil 
                                                      view:modelView] autorelease];
                        
    
    // (OPTIONAL) Add a map annotation for this point.
    
    [mapView addAnnotation:(SM3DARPointOfInterest*)poi]; 
}

- (void) addMarkerIconNamed:(NSString *)markerIconName atLatitude:(CLLocationDegrees)latitude longitude:(CLLocationDegrees)longitude title:(NSString *)poiTitle
{
    // Add a point with a 3D view to the 3DAR scene.
    
    CLLocationCoordinate2D coord;
    coord.latitude = latitude;
    coord.longitude = longitude;
    
    //CLLocationDistance altitude = [elevationGrid elevationAtCoordinate:coord] * GRID_SCALE_VERTICAL;
    
    CLLocationDistance altitude = ([elevationGrid elevationAtCoordinate:coord] - 
                                   [elevationGrid lowestElevation]) * GRID_SCALE_VERTICAL;
    
    altitude += 1.0;
    
    CLLocation *location = [[[CLLocation alloc] initWithCoordinate:coord 
                                                          altitude:altitude
                                                horizontalAccuracy:-1 
                                                  verticalAccuracy:-1 
                                                         timestamp:nil] autorelease];
    
    SM3DARIconMarkerView *marker = [[[SM3DARIconMarkerView alloc] initWithFrame:CGRectZero] autorelease];
    marker.icon.image = [UIImage imageNamed:markerIconName];
    
    SM3DARPoint *poi = [[mapView.sm3dar addPointAtLocation:location 
                                                     title:poiTitle 
                                                  subtitle:nil 
                                                       url:nil 
                                                properties:nil 
                                                      view:marker] autorelease];
    
    
    
    
    // (OPTIONAL) Add a map annotation for this point.
    
    [mapView addAnnotation:(SM3DARPointOfInterest*)poi]; 
}

#pragma mark CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager
	didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{    
    NSLog(@"[BGVC] New location (acc %.0f): %@", newLocation.horizontalAccuracy, newLocation);

//    if (newLocation.horizontalAccuracy < 200.0) 
//    {
        NSLog(@"[BGVC] Turning off location updates.");
        [manager stopUpdatingLocation];


        if (elevationGrid)
        {
            // This happens when app resumes.
            
            [mapView.sm3dar changeCurrentLocation:originLocation];
        }
        else
        {
            [self addGridScene];
            
            [self addOBJNamed:@"Moscone.obj" atLatitude:37.784173 longitude:-122.401557];

            Coord3D c = { 0, 0, (elevationGrid.highestElevation + MIN_CAMERA_ALTITUDE_METERS)*GRID_SCALE_VERTICAL };
            cameraOffset = c;

            [mapView.sm3dar setCameraPosition:cameraOffset];
        }
//    }
}


#pragma mark -
/*
- (void) addHoodGridPoint
{
    // Relocate camera.
    
    originLocation = [[CLLocation alloc] initWithLatitude:45.278439 longitude:-121.816742];
    [mapView.sm3dar changeCurrentLocation:originLocation];
    
    
    NSLog(@"loc: %@", mapView.sm3dar.userLocation);

    
    // Populate grid.
    
    hoodGrid = [[HoodGrid alloc] init];


    // Add a view.
    
    [self addGridAtX:0 Y:0 Z:-100];    
    
}
*/

- (void) addWaveGridPoint
{
    waveGrid = [[WaveGrid alloc] init];    
    [self addGridAtX:2000 Y:2000 Z:0];    
}

- (void) addElevationOBJGridPoint
{
    // Load obj, actually it's an SM3DARFixture 
    // with a TexturedGeometryView

    /*
    // Create point.
    SM3DARFixture *p = [[SM3DARFixture alloc] init];
    
    Coord3D coord = {
        0, 0, -100
    };

     p.worldPoint = coord;
    */
    
#if 0
    NSString *path = [[NSBundle mainBundle] pathForResource:@"arc" ofType:@"obj"];
    
    NSString *fileContents = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];

    NSArray *lines = [fileContents componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    NSString *firstLine = [lines objectAtIndex:0];
        
    NSLog(@"first line: %@", firstLine);
    
    NSArray *parts = [firstLine componentsSeparatedByString:@"#"];
    
    NSString *csv = [parts objectAtIndex:1];
    
    parts = [csv componentsSeparatedByString:@","];    

    NSString *lngStr = [parts objectAtIndex:0];
    NSString *latStr = [parts objectAtIndex:1];
    
    
    
    
    CLLocationDegrees latitude = [latStr doubleValue];
    CLLocationDegrees longitude = [lngStr doubleValue];

    SM3DARPoint *poi = [mapView.sm3dar initPointOfInterestWithLatitude:latitude 
                                                        longitude:longitude 
                                                         altitude:0 
                                                            title:@""
                                                         subtitle:@""
                                                  markerViewClass:nil
                                                       properties:nil];
    
    ObjGridView *gridView = [[ObjGridView alloc] init];
    

    // Give the point a view.
    
    gridView.point = poi;
    poi.view = gridView;
    [gridView release];
    
    
    // Add point to 3DAR scene.
    
    [mapView.sm3dar addPointOfInterest:poi];
    [poi release];
#endif
}

- (void) addElevationGridPoint
{
    originLocation = [[CLLocation alloc] initWithLatitude:45.523563 longitude:-122.675099];
    
    NSLog(@"\n\nMoving to downtown Portland\n\n");
    
    [mapView.sm3dar changeCurrentLocation:originLocation];
   
    self.elevationGrid = [[[ElevationGrid alloc] initAroundLocation:originLocation] autorelease];        
    elevationGrid.sm3dar = mapView.sm3dar;

    CLLocationDistance actualOriginElevation = [elevationGrid elevationAtLocation:originLocation];
    
    NSLog(@"Origin elevation is %.1f", actualOriginElevation);
    
    CLLocation *gridLocation = [[CLLocation alloc] initWithCoordinate:originLocation.coordinate 
//                                                   altitude:-(elevationGrid.lowestElevation * GRID_SCALE_VERTICAL)
                                                   altitude:(actualOriginElevation * GRID_SCALE_VERTICAL)
                                         horizontalAccuracy:-1 
                                           verticalAccuracy:-1 
                                                  timestamp:nil];
    
    [self addGridAtLocation:gridLocation];
    [gridLocation release];
}

- (void) addCityNamePoints
{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"pdx_cities" ofType:@"json"];            
    NSError *error = nil;
    NSLog(@"[BGVC] Loading cities from %@", filePath);
    NSString *citiesJSON = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
    
    if (error)
    {
        NSLog(@"[BGVC] ERROR parsing cities: ", [error localizedDescription]);
    }
    else
    {
/*
 {"geonames":[
                     
 {"fcodeName":"populated place", "countrycode":"US", "fcl":"P", "fclName":"city,village,...", "name":"Portland", "wikipedia":"en.wikipedia.org/wiki/Portland", 
 "lng":-122.6762071, "fcode":"PPL", "geonameId":5746545, 
 "lat":45.5234515, "population":540513},
*/
                     
        NSDictionary *data = [NSDictionary dictionaryWithJSONString:citiesJSON];
        
        NSArray *cities = [data objectForKey:@"geonames"];
        
        NSMutableArray *allPoints = [NSMutableArray arrayWithCapacity:[cities count]];
        
        mapView.sm3dar.markerViewClass = [SM3DARIconMarkerView class];
        
        CLLocation *locx = nil;
        
        for (NSDictionary *city in cities)
        {
            NSString *poiTitle = [city objectForKey:@"name"];
            NSString *poiSubtitle = [city objectForKey:@"population"];
            NSString *latString = [city objectForKey:@"lat"];
            NSString *lngString = [city objectForKey:@"lng"];

            CLLocationDegrees latitude = [latString doubleValue];
            CLLocationDegrees longitude = [lngString doubleValue];
            
            SM3DARPoint *point = [mapView.sm3dar initPointOfInterestWithLatitude:latitude 
                                          longitude:longitude 
                                           altitude:0 
                                              title:poiTitle 
                                           subtitle:poiSubtitle 
                                    markerViewClass:nil
                                    //markerViewClass:[SM3DARIconMarkerView class] 
                                         properties:nil];
            
         
            if (!locx)
            {
                locx = [[[CLLocation alloc] initWithLatitude:latitude longitude:longitude] autorelease];
            }
            
            [allPoints addObject:point];
            [point release];            
        }

        //////////////////////////
        [elevationGrid elevationAtLocation:locx];

        
        [mapView.sm3dar addPointsOfInterest:allPoints];
        
    }
	    
}

/*
- (void) sm3darLogoWasTapped:(SM3DARController *)sm3dar
{
    if (mapView.hidden || mapView.alpha < 0.1)
    {
        NSLog(@"showing map");
        mapView.hidden = NO;
        //        [mapView.sm3dar showMap];
    }
    else
    {
        NSLog(@"hiding map");
        mapView.hidden = YES;
        //        [mapView.sm3dar hideMap];
    }
}
*/
- (void) addPointAtLatitude:(CLLocationDegrees)latitude longitude:(CLLocationDegrees)longitude title:(NSString *)title
{
    CLLocationCoordinate2D coord;
    coord.latitude = latitude;
    coord.longitude = longitude;
        
    CLLocationDistance altitude = [elevationGrid elevationAtCoordinate:coord] * GRID_SCALE_VERTICAL;
    
    CLLocation *location = [[[CLLocation alloc] initWithCoordinate:coord 
                                                          altitude:altitude 
                                                horizontalAccuracy:-1 
                                                  verticalAccuracy:-1 
                                                         timestamp:nil] autorelease];
                             
    SM3DARPointOfInterest *point = [[[SM3DARPointOfInterest alloc] initWithLocation:location 
                                                                                title:title
                                                                             subtitle:nil 
                                                                                  url:nil] autorelease];    

    [mapView addAnnotation:point];
}

- (void) addGridScene
{
    [self addElevationGridPoint];
    
//    Coord3D c = { 0, 0, (elevationGrid.highestElevation + MIN_CAMERA_ALTITUDE_METERS)*GRID_SCALE_VERTICAL };

    CLLocationDistance actualOriginElevation = [elevationGrid elevationAtLocation:originLocation];
    
    Coord3D c = { 
        0, 
        0, 
        (actualOriginElevation + MIN_CAMERA_ALTITUDE_METERS)*GRID_SCALE_VERTICAL 
    };
    
    cameraOffset = c;
    
    [mapView.sm3dar setCameraPosition:cameraOffset];
    
    
//    [self addPointAtLatitude:originLocation.coordinate.latitude longitude:originLocation.coordinate.longitude title:@"Mt. Sanitas"];
//    [self addPointAtLatitude:40.014986 longitude:-105.270546 title:@"Boulder, Colorado"];

//    [self addPointAtLatitude:45.627559 longitude:-122.656914 title:@"Columbia Land Trust"];
    [self addOBJNamed:@"cube.obj" atLatitude:45.627559 longitude:-122.656914];

//    [self addPointAtLatitude:45.512332 longitude:-122.592874 title:@"Mt. Tabor"];
    [self addOBJNamed:@"cube.obj" atLatitude:45.512332 longitude:-122.592874];

//    [self addPointAtLatitude:45.525165 longitude:-122.716212 title:@"Pittock Mansion"];
    [self addOBJNamed:@"cube.obj" atLatitude:45.525165 longitude:-122.716212];

//    [self addPointAtLatitude:45.522759 longitude:-122.676001 title:@"Big Pink"];
    [self addOBJNamed:@"cube.obj" atLatitude:45.522759 longitude:-122.676001];

//    [mapView.sm3dar zoomMapToFit];    
}

- (IBAction) moveToUserLocation
{
    NSLog(@"Centering on user");
    [mapView.sm3dar.locationManager startUpdatingLocation];
    
    Coord3D c = { 0, 0, 0 };
    cameraOffset = c;
    [mapView.sm3dar setCameraPosition:cameraOffset];
    
}

- (void) sm3dar:(SM3DARController *)sm3dar didChangeFocusToPOI:(SM3DARPoint *)newPOI fromPOI:(SM3DARPoint *)oldPOI
{
//    NSLog(@"focused: %@", newPOI.title);
}

- (void) sm3dar:(SM3DARController *)sm3dar didChangeSelectionToPOI:(SM3DARPoint*)newPOI fromPOI:(SM3DARPoint*)oldPOI
{
    NSLog(@"selected: %@", newPOI.title);
}


@end
