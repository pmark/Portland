//
//  PushpinView.m
//
//

#import <OpenGLES/ES1/gl.h>
#import "PushpinView.h"

//#import "Pushpin.h"  // Statically stored pushpin geometry.

#define PPV_SHADOW_VERTEX_COUNT 16

@implementation PushpinView

static float ppvShadowVerts[PPV_SHADOW_VERTEX_COUNT][3];
static unsigned short ppvShadowIndexes[PPV_SHADOW_VERTEX_COUNT];
static Geometry *pushpinGeometry;
static Texture *pushpinTexture;

//@synthesize label;


- (void) dealloc
{
    [label release];
    
    [super dealloc];
}

- (void) buildView 
{
	self.frame = CGRectZero;
    self.color = [UIColor redColor];
    self.hidden = NO;    
    self.zrot = 0.0;    

    self.sizeScalar = 30.0;  // for pushpin_1.0
    
//    self.sizeScalar = 5.0;  // for pushpin_textured
    
    NSLog(@"[PushpinView] buildView");
    
    if (!pushpinGeometry)
    {
        // Works
        NSString *path = [[NSBundle mainBundle] pathForResource:@"pushpin_1.0" ofType:@"obj"];
        
        // Experimental
        //NSString *path = [[NSBundle mainBundle] pathForResource:@"pushpin_textured" ofType:@"obj"];
        
        pushpinGeometry = [[Geometry newOBJFromResource:path] autorelease];
    }
    
    self.geometry = pushpinGeometry;
    self.geometry.cullFace = YES;
    
    // Shadow    
    
    CGFloat radius = 2.5;
	
	for (int i=0; i < PPV_SHADOW_VERTEX_COUNT; i++)
	{
		float theta = 2 * M_PI * i / PPV_SHADOW_VERTEX_COUNT;
		
		ppvShadowVerts[i][0] = radius * cos(theta);
		ppvShadowVerts[i][1] = radius * sin(theta);
		ppvShadowVerts[i][2] = 0.0; //GROUNDPLANE_ALTITUDE_METERS - POI_ALTITUDE_METERS;
		
		ppvShadowIndexes[i] = i;
	}

    
//    label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 50, 20)];
//    label.font = [UIFont fontWithName:@"Courier" size:14];    
//    [self addSubview:label];    
    
}

/*
static float rlLineVertex[2][3] =
{
    // x y z 
    { 0, 0, (POI_ALTITUDE_METERS-5.0) },
    { 0, 0, (GROUNDPLANE_ALTITUDE_METERS-POI_ALTITUDE_METERS) }
};

static unsigned short rlLineIndex[2] = 
{
    0, 1
};
*/

- (void) displayGeometry 
{
    /*
    if ([label.text length] == 0)
    {
        SM3DARPointOfInterest *poi = (SM3DARPointOfInterest *)self.point;

        if (poi)
        {
            label.text = [[poi formattedDistanceInMilesFromCurrentLocation] stringByAppendingString:@" mi"];
            [label sizeToFit];
        }
    }
     */
    
    if (!self.texture)
    {
//        textureName = @"pushpin_textured2.jpg";
        self.textureName = @"red.png";
    }
    
    if (!self.texture && [self.textureName length] > 0) 
    {
        if (!pushpinTexture)
        {
            NSLog(@"Loading texture named %@", self.textureName);

            NSString *textureExtension = [[self.textureName componentsSeparatedByString:@"."] objectAtIndex:1];
            NSString *textureBaseName = [self.textureName stringByDeletingPathExtension];
            NSString *imagePath = [[NSBundle mainBundle] pathForResource:textureBaseName ofType:textureExtension];
            NSData *imageData = [[NSData alloc] initWithContentsOfFile:imagePath]; 
            UIImage *textureImage =  [[UIImage alloc] initWithData:imageData];
            CGImageRef cgi = textureImage.CGImage;
            
            pushpinTexture = [Texture newTextureFromImage:cgi];
            
            [imageData release];
            [textureImage release];
            
        }

        self.texture = pushpinTexture;        
    }

    
    glTranslatef(0, 0, -100);
    

    // Scale last.
    
    glScalef(self.sizeScalar, self.sizeScalar, self.sizeScalar); //*0.85);
    
    

    // Shadow
    
    glLineWidth(1.0);
    glColor4f(.2, .2, .2, 0.6);
	glVertexPointer(3, GL_FLOAT, 0, ppvShadowVerts);
	glDrawElements(GL_TRIANGLE_FAN, PPV_SHADOW_VERTEX_COUNT, GL_UNSIGNED_SHORT, ppvShadowIndexes);


//    [self.geometry displayWireframe];
//    [self.geometry displayShaded:self.color];
    [self.geometry displayFilledWithTexture:self.texture];
    
    
    /////////
/*
    glVertexPointer(3, GL_FLOAT, 0, pushpinVerts);
//    glNormalPointer(GL_FLOAT, 0, pushpinNormals);
//    glTexCoordPointer(2, GL_FLOAT, 0, pushpinTexCoords);
    glDrawArrays(GL_TRIANGLES, 0, pushpinNumVerts);
    /////////
*/
    
/*
    // Line
    
    glLineWidth(3.0);
    glColor4f(0.66, 0.66, 0.66, 1.0);
    glVertexPointer(3, GL_FLOAT, sizeof(float) * 3, rlLineVertex);
    glDrawElements(GL_LINES, 2, GL_UNSIGNED_SHORT, rlLineIndex);
    

    // Head
    
    glLineWidth(1.0);
    //[self.geometry displayShaded:self.color];
    [self.geometry displayWireframe];
    //[Geometry displaySphereShadedWithColor:self.color];
    //[Geometry displaySphereWithTexture:nil];
*/    

}

- (void) didReceiveFocus
{
//    self.color = [UIColor colorWithRed:1.0 green:0 blue:0 alpha:0.25];
}

- (void) didLoseFocus
{
//    self.color = [UIColor redColor];
}


@end
