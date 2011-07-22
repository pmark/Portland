//
//  SimpleKMLObject.m
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

#import "SimpleKMLObject.h"

@interface SimpleKMLObject (SimpleKMLObjectPrivate)

- (NSString *)cachePath;

@end

#pragma mark -

@implementation SimpleKMLObject

@synthesize objectID;

- (id)initWithXMLNode:(CXMLNode *)node sourceURL:(NSURL *)inSourceURL error:(NSError **)error
{
    self = [super init];
    
    if (self != nil)
    {
        sourceURL = [inSourceURL retain];
        source    = [[NSString stringWithString:[node XMLString]] retain];
        objectID  = [[[[((CXMLElement *)node) attributeForName:@"id"] stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] retain];
    }
    
#pragma mark TODO: assert that abstract classes aren't being instantiated
    
    return self;
}

- (void)dealloc
{
    [sourceURL release];
    [source release];
    [objectID release];
    
    [super dealloc];
}

#pragma mark -

- (void)setCacheObject:(id)object forKey:(NSString *)key
{
    NSMutableDictionary *cache = [NSMutableDictionary dictionaryWithContentsOfFile:[self cachePath]];
    
    if ( ! cache)
        cache = [NSMutableDictionary dictionary];
    
    [cache setObject:object forKey:key];
    
    [cache writeToFile:[self cachePath] atomically:YES];
}

- (id)cacheObjectForKey:(NSString *)key
{
    NSMutableDictionary *cache = [NSMutableDictionary dictionaryWithContentsOfFile:[self cachePath]];

    return [cache objectForKey:key];
}

- (NSString *)cachePath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    
    return [NSString stringWithFormat:@"%@/%@", [paths objectAtIndex:0], [self class]];
}

@end