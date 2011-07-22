//
//  PolylineView.m
//  Hood
//
//  Created by P. Mark Anderson on 5/22/11.
//  Copyright 2011 Spot Metrix, Inc. All rights reserved.
//

#import "PolylineView.h"
#import <OpenGLES/ES1/gl.h>
#import "WorldCoordinate.h"

@implementation PolylineView

@synthesize coords;

- (void) dealloc
{
    [coords release];
    
    free(verts);
    
    [super dealloc];
}

- (id) initWithWorldCoordinates:(NSArray *)_coords
{
    self = [super initWithFrame:CGRectZero];
    
    if (self)
    {
//        self.coords = _coords;
        vertCount = [_coords count];
        
        verts = (Coord3D*)calloc(vertCount, sizeof(Coord3D));

        if (verts == NULL)
		{
			NSLog(@"\nError allocating requested memory for PolylineView.\n");
            return nil;
		}        
        
        int i = 0;
        for (WorldCoordinate *wc in _coords)
        {
            verts[i] = wc.coord;
            i++;
        }
        
//        UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
//        label.text = @" | ";
//        label.backgroundColor = [UIColor redColor];
//        [label sizeToFit];
//        [self addSubview:label];
    }
    
    return self;
}

- (void) drawInGLContext
{
    static CGFloat lineColor = 0.0;
    static CGFloat lineWidth = 7.0;

    glDisable(GL_LIGHTING);
    glEnable(GL_DEPTH_TEST);    
	glEnableClientState(GL_VERTEX_ARRAY);
	glDisableClientState(GL_NORMAL_ARRAY);
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
    glDisable(GL_FOG);
    glDisable(GL_DEPTH_TEST);

    
//    glColor4f(lineColor, lineColor*0.33, lineColor*0.66, 1.0); 
    glColor4f(1.0, lineColor, lineColor, 1.0); 
    glLineWidth(lineWidth);
    
    glVertexPointer(3, GL_FLOAT, 0, verts);
    glDrawArrays(GL_LINE_STRIP, 0, vertCount);    
//    glDrawArrays(GL_POINTS, 0, vertCount);    
}

@end
