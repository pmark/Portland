//
//  GridView.m
//
//

#import <OpenGLES/ES1/gl.h>
#import "GridView.h"
#import "ElevationGrid.h"


@implementation GridView

- (void) dealloc
{
    [gridTexture release];
    [super dealloc];
}

- (void) buildView 
{
    NSLog(@"[GV] buildView");    
    
//    gridTexture = [Texture newTextureFromResource:@"PortlandMap.png"];
    gridTexture = [Texture newTextureFromResource:@"PortlandBingMap2048.jpg"];
//    gridTexture = [Texture newTextureFromResource:@"PortlandAerial2048.jpg"];
}

- (void) drawFog
{
    GLfloat fogColor[4] = {0.6f, 0.0f, 0.9f, 0.7f};
    glFogfv(GL_FOG_COLOR, fogColor);
    
    glFogf(GL_FOG_MODE, GL_LINEAR);
    glFogf(GL_FOG_DENSITY, 1.0);
    
    glFogf(GL_FOG_START, 0.0);
    
    CGFloat fogEnd = GRID_SCALE_HORIZONTAL * ELEVATION_LINE_LENGTH_HIGH;
    glFogf(GL_FOG_END, fogEnd);
    
    glHint(GL_FOG_HINT, GL_NICEST);
    
    glEnable(GL_FOG);
}

- (void) drawGrid
{
    ushort lineIndex [1024];
    
    Coord3D *verts = &worldCoordinateDataHigh[0][0];
    int gridSize = ELEVATION_PATH_SAMPLES;
    
    glDisable(GL_LIGHTING);
    
	glPolygonOffset(1,1);			// Offset fill in z-buffer.
	glEnable(GL_POLYGON_OFFSET_FILL);
	
    glEnableClientState(GL_VERTEX_ARRAY);
    glDisableClientState(GL_NORMAL_ARRAY);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    
	glVertexPointer(3, GL_FLOAT, 0, verts);
    glTexCoordPointer(3, GL_FLOAT, 0, verts);
    
    glLineWidth(1.0);
    
    glScalef(GRID_SCALE_HORIZONTAL, GRID_SCALE_HORIZONTAL, GRID_SCALE_VERTICAL);
    
    // fill horizontal strip of triangles.
	
    glDisable(GL_CULL_FACE);
	glEnable(GL_DEPTH_TEST);
    glEnable(GL_TEXTURE_2D);
    
    // Bind to the loaded texture.
	
    glBindTexture(GL_TEXTURE_2D, gridTexture.handle);
    
    // Scale the coordinates to 0..1 space.
    
    glMatrixMode(GL_TEXTURE);

    
    
    float s = 1.0 / 30000.0;
    glLoadIdentity();
    glTranslatef(-0.5, -0.5, 0);
    glScalef(s, -s, 1);
    glMatrixMode(GL_MODELVIEW);

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR_MIPMAP_LINEAR);

	bool fill = true;
	
	if (fill)
		glColor4f(1,1,1,1);
		//glColor4f(1,.84,0,1);
        //glColor4f(0,0,1,1);
	else	
		glColorMask(0,0,0,0);			// Turn of visible filling.
    
	
    for (int y=0; y < gridSize-1; y++)
    {
    	int start1 = y * gridSize;
        int start2 = start1 + gridSize;
		
        // build index array.
        
		int ct = 0;
		
        for (int x=0; x < gridSize; x++)
		{
        	lineIndex[ct++] = start1 + x;
			lineIndex[ct++] = start2 + x;
		}
		
		glDrawElements(GL_TRIANGLE_STRIP, ct, GL_UNSIGNED_SHORT, lineIndex);
    }
	
    
    /*
    // draw horizontal lines.
    
	glColorMask(1,1,1,1);
    glColor4f(1,1,0,1);
	
    
    for (int y=0; y < gridSize; y++)
    {
    	int start = y * gridSize;
        
        // build index array.
        
        for (int x=0; x < gridSize; x++)
        	lineIndex[x] = start + x;
        
		glDrawElements(GL_LINE_STRIP, gridSize, GL_UNSIGNED_SHORT, lineIndex);
    }
    
    // draw horizontal lines.
    
    for (int x=0; x < gridSize; x++)
    {
    	int start = x;
        
        // build index array.
        
        for (int y=0; y < gridSize; y++)
        	lineIndex[y] = start + (y * gridSize);
        
		glDrawElements(GL_LINE_STRIP, gridSize, GL_UNSIGNED_SHORT, lineIndex);
    }
*/
    
    
    glDisable(GL_DEPTH_TEST);

}

/*
- (void) drawTexturedGrid
{
	glBindTexture(GL_TEXTURE_2D, texture.handle);
    
    // Render to opengl.
    
    glColor4f(1,1,1,1);
	glDisable(GL_LIGHTING);
    
	glDisable(GL_BLEND);
    
    //	glEnable(GL_CULL_FACE);  // what about when viewed from the inside?
	glEnable(GL_DEPTH_TEST);
    
    if (self.cullFace)
        glEnable(GL_CULL_FACE);
    else
        glDisable(GL_CULL_FACE);
    
	glEnableClientState(GL_VERTEX_ARRAY);
    glDisableClientState(GL_NORMAL_ARRAY);
    
    if (ndl->textureChannelCount)
    {
        glEnable(GL_TEXTURE_2D);
        glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    }
    else
    {  
        glDisable(GL_TEXTURE_2D);
        glDisableClientState(GL_TEXTURE_COORD_ARRAY);
    }
    
	glVertexPointer(3, GL_FLOAT, 24, &ndl->vertex[0].x);
    
    if (ndl->textureChannelCount)
        glTexCoordPointer(ndl->textureChannelCount, GL_FLOAT, 0, ndl->textureChannel);
    
    for (int i=0; i < ndl->polygonCount; i++)
    {
        GLsizei elemCount = ndl->polygon[i].vertexCount;
        glDrawElements(GL_TRIANGLE_FAN, elemCount, GL_UNSIGNED_SHORT, ndl->polygon[i].vertexIndex);
    }
}
*/

- (void) drawInGLContext 
{
//    [self drawFog];
    [self drawGrid];
//    [self drawTexturedGrid];
}

@end
