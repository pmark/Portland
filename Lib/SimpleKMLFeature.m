//
//  SimpleKMLFeature.m
//
//  Created by Justin R. Miller on 6/29/10.
//  Copyright 2010, Code Sorcery Workshop, LLC and Development Seed, Inc.
//  All rights reserved.
//  
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//  
//      * Redistributions of source code must retain the above copyright
//        notice, this list of conditions and the following disclaimer.
//  
//      * Redistributions in binary form must reproduce the above copyright
//        notice, this list of conditions and the following disclaimer in the
//        documentation and/or other materials provided with the distribution.
//  
//      * Neither the names of Code Sorcery Workshop, LLC or Development Seed,
//        Inc., nor the names of its contributors may be used to endorse or
//        promote products derived from this software without specific prior
//        written permission.
//  
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
//  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import "SimpleKMLFeature.h"
#import "SimpleKMLDocument.h"
#import "SimpleKMLStyle.h"

@implementation SimpleKMLFeature

@synthesize name;
@synthesize featureDescription;
@synthesize sharedStyleID;
@synthesize sharedStyle;
@synthesize inlineStyle;
@synthesize style;
@synthesize container;
@synthesize document;

- (id)initWithXMLNode:(CXMLNode *)node sourceURL:sourceURL error:(NSError **)error
{
    self = [super initWithXMLNode:node sourceURL:sourceURL error:error];
    
    if (self != nil)
    {
        for (CXMLNode *child in [node children])
        {
            if ([[child name] isEqualToString:@"name"])
                name = [[[child stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] retain];
            
            else if ([[child name] isEqualToString:@"description"])
                featureDescription = [[[child stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] retain];
            
            else if ([[child name] isEqualToString:@"Style"])
                inlineStyle = [[SimpleKMLStyle alloc] initWithXMLNode:child sourceURL:sourceURL error:NULL];
            
#pragma mark TODO: we really need case folding here
            else if ([[child name] isEqualToString:@"styleUrl"])
                sharedStyleID = [[[child stringValue] stringByReplacingOccurrencesOfString:@"#" withString:@""] retain];
        }
    }
    
    return self;
}

- (void)dealloc
{
    [name release];
    [featureDescription release];
    [sharedStyleID release];
    [inlineStyle release];
    
    [super dealloc];
}

#pragma mark -

- (SimpleKMLStyle *)style
{
    // inline style takes precedence
    //
    if (inlineStyle)
        return (SimpleKMLStyle *)inlineStyle;
    
    else if (sharedStyle)
        return (SimpleKMLStyle *)sharedStyle;
    
    return nil;
}

@end