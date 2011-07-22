/*
 *  Globals.h
 *  Hood
 *
 *  Created by P. Mark Anderson on 2/5/11.
 *  Copyright 2011 Spot Metrix, Inc. All rights reserved.
 *
 */

#define AVG_EARTH_RADIUS_METERS 6367444.65


// Portland
#define ELEVATION_LINE_LENGTH_HIGH    30000.0
#define ELEVATION_PATH_SAMPLES          155.0

//#define ELEVATION_LINE_LENGTH_HIGH    20000.0
//#define ELEVATION_PATH_SAMPLES          157.0

// SF
//#define ELEVATION_LINE_LENGTH_HIGH    14000.0
//#define ELEVATION_PATH_SAMPLES          155.0

// Mt. Sanitas
//#define ELEVATION_LINE_LENGTH_HIGH    6000.0
//#define ELEVATION_PATH_SAMPLES         145.0


// 159m res (limit at 25km size)
//#define ELEVATION_LINE_LENGTH_HIGH   20000.0
//#define ELEVATION_PATH_SAMPLES         145.0

// 63m res (limit at 10km size)
//#define ELEVATION_LINE_LENGTH_HIGH  10000.0   
//#define ELEVATION_PATH_SAMPLES        157.0

// 90m res
//#define ELEVATION_LINE_LENGTH_HIGH  10000.0   
//#define ELEVATION_PATH_SAMPLES        111.0

#define GRID_SCALE_HORIZONTAL 1.0   // 0.1
#define GRID_SCALE_VERTICAL 2.0  // 0.45

//#define ELEVATION_LINE_LENGTH_LOW   200000.0  // Use low res later.
#define GOOGLE_ELEVATION_API_URL_FORMAT @"http://maps.googleapis.com/maps/api/elevation/json?path=%@&samples=%i&sensor=false"
//#define SM3DAR_ELEVATION_API_URL_FORMAT @"http://localhost:5984/hood1/_design/point_elevation/_spatial/points?bbox=%@"

//#define GRID_CELL_SIZE_LOW ELEVATION_LINE_LENGTH_LOW/ELEVATION_PATH_SAMPLES
#define GRID_CELL_SIZE_HIGH ELEVATION_LINE_LENGTH_HIGH/ELEVATION_PATH_SAMPLES

typedef struct
{
    CLLocationCoordinate2D coordinate;
    CLLocationDistance elevation;
} ElevationPoint;

typedef struct
{
    ElevationPoint a, b, c, d;
} BoundingBox;

typedef struct
{
    Coord3D a, b, c, d;
} WorldCoordinateBoundingBox;



// This array holds points as lat, lon, elevation.

//ElevationPoint elevationPointsLow[(int)ELEVATION_PATH_SAMPLES][(int)ELEVATION_PATH_SAMPLES];
ElevationPoint elevationPointsHigh[(int)ELEVATION_PATH_SAMPLES][(int)ELEVATION_PATH_SAMPLES];

//Coord3D worldCoordinateDataLow[(int)ELEVATION_PATH_SAMPLES][(int)ELEVATION_PATH_SAMPLES];
Coord3D worldCoordinateDataHigh[(int)ELEVATION_PATH_SAMPLES][(int)ELEVATION_PATH_SAMPLES];




