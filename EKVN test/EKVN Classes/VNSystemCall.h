//
//  VNLayerScript.h
//
//  Created by James Briones on 4/2/13.
//  Copyright 2013. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 
 VNSystemCall
 
 This class is built specifically to handle ".SYSTEMCALL" commands that are used in the VN system. These types of commands
 are mainly used for game-specific tasks that need to be called/accessed/controlled from within the VN system. Examples
 may include autosaving the game, logging diagnostic information, or starting mini-games.
 
 Currently, this class only supports the first two uses, and only at the most basic level. It's recommended that developers
 modify/extend this class for their own purposes.
 
 */

#pragma mark - VNSystemCall

@interface VNSystemCall : NSObject

// This class is the main way that the VN system has to access System Calls. An array of data is passed as a parameter,
// and it's up to VNSystemCall to perform some kind of action using that information.
- (void)sendCall:(NSArray*)callData;

// This tries to autosave the game; it assumes that the player is currently using the VN system.
- (void)autosave;

@end
