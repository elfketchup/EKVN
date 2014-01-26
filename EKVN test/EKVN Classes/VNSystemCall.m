//
//  VNSystemCall.m
//
//  Created by James Briones on 4/2/13.
//  Copyright (c) 2013 James Briones. All rights reserved.
//

#import "VNSystemCall.h"
#import "VNScene.h"

@implementation VNSystemCall

- (void)sendCall:(NSArray*)callData
{
    if( callData == nil ) // Check for invalid data
        return;
    
    NSString* typeString = [callData objectAtIndex:0];
    NSArray* extras = [callData objectAtIndex:1];
    
    // Check what kind TYPE parameter is
    if( [typeString caseInsensitiveCompare:@"nslog"] == NSOrderedSame ) {
        
        // Use NSLog to record whatever diagnostic data may have been sent from the VN system
        NSLog(@"[VNSystemCall] %@", [extras objectAtIndex:0]);
        
    } else if( [typeString caseInsensitiveCompare:@"autosave"] == NSOrderedSame ) {
        
        // Do a basic autosave of the VN system
        [self autosave];
    }
}

- (void)autosave
{
    // Try to get the current VN scene (if it exists)
    VNScene* currentVNScene = [VNScene currentVNScene];
    
    // Now check if the scene exists at all
    if( currentVNScene ) {
        
        // Check if the scene can't be saved due to it being created/loaded way too recently
        if( currentVNScene.wasJustLoadedFromSave == YES ) {
            
            CCLOG(@"[VNSystemCall] Cannot autosave; game was just loaded too recently.");
            return;
            
        } else {
            
            // In THEORY, it should be possible to save the game now...
            CCLOG(@"[VNSystemCall] Autosaving...");
            [currentVNScene saveToRecord]; // Attemp to autosave
        }
    }
}

@end
