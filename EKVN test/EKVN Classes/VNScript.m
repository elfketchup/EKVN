//
//  VNScript.m
//
//  Created by James Briones on 7/3/11.
//  Copyright 2011. All rights reserved.
//

#import "VNScript.h"

@implementation VNScript

#pragma mark -
#pragma mark Initialization

// Load the script from a Property List (.plist) file in the app bundle. Make sure to not include the ".plist" in the file name.
// For example, if the script is stored as "ThisScript.plist" in the bundle, just pass in "ThisScript" as the parameter.
- (id)initFromFile:(NSString *)nameOfFile withConversation:(NSString*)conversationName
{
    if( self = [super init] ) {
        
        // Load a dictionary from a .plist file in the app bundle
        NSString* filepath              = [[NSBundle mainBundle] pathForResource:nameOfFile ofType:@"plist"];
        NSDictionary* loadedDictionary  = [[NSDictionary alloc] initWithContentsOfFile:filepath]; // All data in the file
        self.filename                   = [[NSString alloc] initWithString:nameOfFile]; // Save filename
        
        // Now actually load some of the data
        [self prepareScript:loadedDictionary]; // Convert the script from text into binary data that's more easily read
        [self changeConversationTo:conversationName]; // Automatically move to the 'start' array (and set "index" data)
        
        // Check if no valid data could be loaded from the file
        if( self.data == nil ) {
            NSLog(@"[VNScript] ERROR: VNScript could not translate script.");
            return nil;
        }
    }
    
    return self;
}

- (id)initFromFile:(NSString *)nameOfFile
{
    return [self initFromFile:nameOfFile withConversation:VNScriptStartingPoint];
}

// Loads the script from a dictionary with a lot of other data (such as specific conversation names, indexes, etc).
// This is used mostly for loading from saved games.
- (id)initWithInfo:(NSDictionary*)dict
{
    if( dict == nil )
        return nil;
    
    NSString* filenameValue     = [dict objectForKey:VNScriptFilenameKey]; // File to load script from
    NSString* conversationValue = [dict objectForKey:VNScriptConversationNameKey]; // The conversation to start with
    NSNumber* currentIndexValue = [dict objectForKey:VNScriptCurrentIndexKey]; // OPTIONAL: Which index to start processing on
    NSNumber* indexesDoneValue  = [dict objectForKey:VNScriptIndexesDoneKey]; // OPTIONAL: Number of indexes processed already
    
    if( filenameValue == nil || conversationValue == nil )
        return nil;
    
    // Load (and translate) the script from a .plist file that has the same name as whatever 'filenameValue' has
    id result = [self initFromFile:filenameValue];
    
    // Go to the right conversation
    [self changeConversationTo:conversationValue];
    
    // Copy the "indexes done" and "current index" values from the dictionary to the class's instance variables
    if( currentIndexValue )
        self.currentIndex = [currentIndexValue intValue];
    if( indexesDoneValue )
        self.indexesDone = [indexesDoneValue intValue];
    
    return result;
}

/*
  Scene data:
 
    (dictionary root)
      1. "start" (array; holds dialogue, instructions, etc)
      2. ...other arrays just like "start"
 
 */

// This processes the script, converting the data from its original Property List format into something
// that can be used by VNLayer. (This new, converted format is stored in VNScript's "data" dictionary)
- (void)prepareScript:(NSDictionary*)dict
{
    // NOTE: The Property List dictionary that holds all the script data has a "child" dictionary titled
    //       "actual script." In an earlier version of the VN system, the Property List also had a section
    //       titled "resources" (which held the names of sounds/images/etc to pre-load), plus some other
    //       sections as well. However, as these other sections were never used, support for them has since
    //       been removed from the VN engine. Now, the entire dictionary is treated as the "actual script"
    //       section, and is composed of arrays that hold the "conversation" data.
    
    // Here's a dictionary object that will hold all the text-to-binary-data translated conversations. It will
    // hold the "finished product" when this function is done processing.
    NSMutableDictionary* translatedScript = [[NSMutableDictionary alloc] initWithCapacity:[dict count]];
    
    // Go through each NSArray (conversation) in the script and translate each conversation into something that's
    // easier for the program to process. This "outer" for loop will get all the conversation names and the loops
    // inside this one will translate each conversation.
    for( NSString* conversationKey in [dict allKeys] ) {
        
        // This retrieves the actual array data so that it can be processed. There's an "original array" that holds
        // the raw text data (taken from the Property List) and then a "translated array" that holds the data that's
        // been converted to processed data.
        NSArray* originalArray = [dict objectForKey:conversationKey]; // Get original text array
        
        // Make sure this is actually an NSArray object, and not some other kind of object that just happened to be in the dictionary
        if( [originalArray isKindOfClass:[NSArray class]] ) {

            NSMutableArray* translatedArray = [[NSMutableArray alloc] initWithCapacity:[originalArray count]];
        
            // Now go through each line in this particular "conversation" and convert it from raw text to processed data
            for( NSString* line in originalArray ) {
                
                // Break the string down into its individual components and translate it into something easy for the program to "read"
                NSArray* commandFromLine = [line componentsSeparatedByString:VNScriptSeparationString];
                NSArray* translatedLine = [self analyzedCommand:commandFromLine];
                
                // Add the translated line to the correct, "finished product" array
                if( translatedLine != nil ) {
                    [translatedArray addObject:translatedLine];
                }
            }
            
            // Add this translated "conversation" to the script
            [translatedScript setObject:translatedArray forKey:conversationKey];
        }
    }
    
    // At this point, the entire script should be translated, and can now be used in the actual game.
    // The finished product gets stored by the class for use later (during the game).
    self.data = [[NSDictionary alloc] initWithDictionary:translatedScript];
}

#pragma mark - 
#pragma mark Misc

// Returns information ABOUT the script (but NOT the script itself). Conveniently, this same information can be
// used to load a script using the 'initWithInfo' function.
- (NSDictionary*)info
{
	// Store index data
    NSNumber* indexesDoneValue = @(self.indexesDone);
    NSNumber* currentIndexValue = @(self.currentIndex);
    
    // Store all relevant data into another dictionary
    NSDictionary* dictForScript = @{VNScriptIndexesDoneKey:        indexesDoneValue,
                                    VNScriptCurrentIndexKey:       currentIndexValue,
                                    VNScriptConversationNameKey:   self.conversationName,
                                    VNScriptFilenameKey:           self.filename};
    
    return dictForScript;
}

// Changes from one conversation to another. The indexes are reset as part of the process.
- (BOOL)changeConversationTo:(NSString *)newConversation
{
    // Check if there's any data; if not, then there's no point to this function as there are no conversations!
    if( self.data != nil ) {
        
        // Try to point to a new array with dialogue data
        self.conversation = [self.data objectForKey:newConversation];
        
        // Check if that worked at all
        if( self.conversation ) {
            
            // Get rid of old data and replace it
            self.conversationName   = [newConversation copy];
            self.currentIndex       = 0;
            self.indexesDone        = 0;
            self.maxIndexes         = self.conversation.count;
            
            return YES;
        }
    }
    
    return NO;
}

- (id)commandAtLine:(NSInteger)line
{
    // Check if conversation data is valid
    if( self.conversation  ) {
        
        // Check to make sure there's no "out-of-bounds" array error
        if( line < self.conversation.count ) {
            return [self.conversation objectAtIndex:line];
        }
    }
    
    return nil;
}

// Returns the current "command" (string) in the current conversation
- (id)currentCommand
{
    if( self.indexesDone > self.currentIndex )
        return nil;
    
    return [self commandAtLine:self.indexesDone];
}

// Check if the current index still needs processing, or if it's already been processed
- (BOOL)lineShouldBeProcessed
{
    if( self.indexesDone <= self.currentIndex )
        return YES;
    
    return NO;
}

// Advance the number of indexes done by by one. Since this function only has one line, it's probably not necessary
// to call it (or rather, you could just copy+paste its one line INSTEAD of calling it), but it might be useful in
// case you need to advance the line in a selector (or as part of a Cocos2D action).
- (void)advanceLine
{
    self.indexesDone = self.indexesDone + 1;
}

// Similar to 'advanceLine' except it advances the current index instead of the number of indexes that have been processed
- (void)advanceIndex
{
    self.currentIndex++;
}

- (id)currentLine
{
    return [self commandAtLine:self.currentIndex];
}

#pragma mark - Script Translation

// Function definition
//
//  Name: NAME
//
//  DESCRIPTION
//
//  Parameters:
//
//      #1: PARAMETER1 (type)
//
//      #2: (OPTIONAL) Sprite appears at once? (Boolean value) (example: "NO") (default is NO)
//          If set to YES, the sprite appears immediately (no fade-in). If set to NO, then the
//          sprite "gradually" fades in (though the fade-in usually takes a second or less).
//
//  Example: EXAMPLE
//

- (id)analyzedCommand:(NSArray*)command
{
    NSArray* analyzedArray = nil;
    NSNumber* type = nil;
    
    unichar firstCharacter = [[command objectAtIndex:0] characterAtIndex:0];
    
    // Check if this is really just a line of dialogue being spoken by a character/narrator. Since "real"
    // commands always have two or more items in the array, AND start with a "." character, this is
    // the easiest way to check.
    if( command.count < 2 || firstCharacter != '.' ) {
        
        // Any time that a line of dialogue has colons, it will be treated as a command and split into
        // different sections. However, it's possible that it really was just meant to be a regular
        // line (and not a command), so it's sometimes necessary to take the different substrings and
        // merge them back into one fixed string. This is kind of a cheap, hack-y way to do it, but
        // it works.
        NSMutableString* fixedString = [NSMutableString stringWithFormat:@"%@", [command objectAtIndex:0]];
        if( firstCharacter != '.' && command.count > 1 ) {
            
            for( int part = 1; part < command.count; part++ ) {
                
                NSString* currentPart = [command objectAtIndex:part];
                NSString* fixedSubString = [[NSString alloc] initWithFormat:@":%@", currentPart];
                [fixedString appendString:fixedSubString];
            }
        }
        
        // Example: "Hi there"
        type = @VNScriptCommandSayLine;
        //analyzedArray = @[type, [command objectAtIndex:0]];
        analyzedArray = @[type, fixedString];
        return analyzedArray; // Return the data at once (instead of doing more processing)
    }
    
    // Automatically prepare the action and parameter values. After all, pretty much every command has 
    // an action string and a first parameter. It's only certain commands that have more parameters than that.
    NSString* action = [command objectAtIndex:0];
    NSString* parameter1 = [command objectAtIndex:1];
    
    // Now begins a long series of if-else comparisons to check if the first item in the array
    // matches any of the predetermined "commands" that this rather simple scripting language knows.
    if( [action caseInsensitiveCompare:VNScriptStringAddSprite] == NSOrderedSame ) {
        
        // Function definition
        //
        //  Name: .ADDSPRITE
        //
        //  Uses Cocos2D to add a sprite to the screen. By default, the sprite usually appears right
        //  at the center of the screen.
        //
        //  Parameters:
        //
        //      #1: Sprite name (string) (example: "girl.png")
        //          Quite simply, the name of a file where the sprite is. Currently, the VN system doesn't
        //          support sprite sheets, so it needs to be a single image in a single file.
        //
        //      #2: (OPTIONAL) Sprite appears at once? (Boolean value) (example: "NO") (default is NO)
        //          If set to YES, the sprite appears immediately (no fade-in). If set to NO, then the
        //          sprite "gradually" fades in (though the fade-in usually takes a second or less).
        //
        //  Example: .addsprite:girl.png:NO
        //
        
        NSString* parameter2 = [NSString stringWithFormat:@"NO"]; // Set default value
        
        // If an existing command was already provided in the script, then overwrite the default one
        // with the value found within the script.
        if( command.count > 2 )
            parameter2 = [command objectAtIndex:2];
        
        // Convert the second parameter to a Boolean value (stored as a Boolean NSNumber object)
        BOOL appearAtOnce = [parameter2 boolValue];
        NSNumber* appearParameter = @(appearAtOnce);
        
        type = @VNScriptCommandAddSprite;            
        analyzedArray = @[type, parameter1, appearParameter];
        
    } else if ( [action caseInsensitiveCompare:VNScriptStringAlignSprite] == NSOrderedSame ) {
        
        // Function definition
        //
        //  Name: .ALIGNSPRITE
        //
        //  Aligns a particular sprite in either the center, left, or right ends of the screen. This is done
        //  by finding the center of the sprite and setting the X coordinate to either 25% of the screen's
        //  width (on the iPhone 4S, this is 480*0.25 or 120), 50% (the middle), or 75% (the right).
        //
        //  There's also the Far Left (the left border of the screen), Far Right (the right border of the screen),
        //  and Extreme Left and Extremem Right, which are so far that the sprite is drawn offscreen.
        //
        //  Parameters:
        //
        //      #1: Name of sprite (string) (example: "girl.png")
        //          This is the name of the sprite to manipulate/align. All sprites currently displayed by the
        //          VN system are kept track of in the scene, so if the sprite exists onscreen, it'll be found.
        //
        //      #2: Alignment name (string) (example: "left") (default is "center")
        //          Determines whether to move the sprite to the LEFT, CENTER, or RIGHT of the screen.
        //          (Other, more unusual values also include FAR LEFT, FAR RIGHT, EXTREME LEFT, EXTREME RIGHT)
        //          It has to be one of those values; partial/percentage values aren't supported.
        //
        //      #2: (OPTIONAL) Alignment duration in SECONDS (double value) (example: "0.5") (Default is 0.5)
        //          Determines how long it takes for the sprite to move from its current position to the
        //          new position. Setting it to zero makes the transition instant. Time is measured in seconds.
        //
        //  Example: .alignsprite:girl.png:center
        //
	
		// Set default values
        NSString* newAlignment = [NSString stringWithFormat:@"center"];
        NSString* duration = [NSString stringWithFormat:@"0.5"];
        
        // Overwrite any default values with any values that have been explicitly written into the script
        if( command.count >= 3 )
            newAlignment = [command objectAtIndex:2]; // Parameter 2; should be either "left", "center", or "right"
        if( command.count >= 4 )
            duration = [command objectAtIndex:3]; // Optional, default value is 0.5
            
        type = @VNScriptCommandAlignSprite;
        NSNumber* durationToUse = @([duration doubleValue]);
        analyzedArray = @[type, parameter1, newAlignment, durationToUse];
        
    } else if ( [action caseInsensitiveCompare:VNScriptStringRemoveSprite] == NSOrderedSame ) {
        
        // Function definition
        //
        //  Name: .REMOVESPRITE
        //
        //  Removes a sprite from the screen, assuming that it's part of the VN system's dictionary of
        //  existing sprite objects.
        //
        //  Parameters:
        //
        //      #1: Name of sprite (string) (example: "girl.png")
        //          This is the name of the sprite to manipulate/align. All sprites currently displayed by the
        //          VN system are kept track of in the scene, so if the sprite exists onscreen, it'll be found.
        //
        //      #2: (OPTIONAL) Sprite appears at once (Boolean value) (example: "NO") (Default is NO)
        //          Determines whether the sprite disappears from the screen instantly or fades out gradually.
        //
        //  Example: .removesprite:girl.png:NO
        //
        
        NSString* parameter2 = [NSString stringWithFormat:@"NO"]; // Default value
        
        if( command.count > 2 )
            parameter2 = [command objectAtIndex:2]; // Overwrite default value with user-defined one, if it exists
        
        // Convert to Boolean NSNumber object
        BOOL vanishAtOnce = [parameter2 boolValue];
        NSNumber* vanishParameter = @(vanishAtOnce);
        
        // Example: .removesprite:bob:NO
        type = @VNScriptCommandRemoveSprite;
        analyzedArray = @[type, parameter1, vanishParameter];
        
    } else if ( [action caseInsensitiveCompare:VNScriptStringEffectMoveSprite] == NSOrderedSame ) {
        
        // Function definition
        //
        //  Name: .MOVESPRITE
        //
        //  Uses Cocos2D actions to move a sprite by a certain number of points.
        //
        //  Parameters:
        //
        //   (note that all parameters after the first are TECHNICALLY optional, but if you use one,
        //    you had better call the ones that come before it!)
        //
        //      #1: The name of the sprite to move (string) (example: "girl.png")
        //
        //      #2: Amount to move sprite by X points (float) (example: 128) (default is ZERO)
        //
        //      #3: Amount to move the sprite by Y points (float) (example: 256) (default is ZERO)
        //
        //      #4: Duration in seconds (float) (example: 0.5) (default is 0.5 seconds)
        //          This measures how long it takes to move the sprite, in seconds.
        //
        //  Example: .movesprite:girl.png:128:-128:1.0
        //
        
        // Set default values for extra parameters
        NSString* xParameter = @"0";
        NSString* yParameter = @"0";
        NSString* durationParameter = @"0.5";
        
        // Overwrite default values with ones that exist in the script (assuming they exist, of course)
        if( command.count > 2 ) xParameter = [command objectAtIndex:2];
        if( command.count > 3 ) yParameter = [command objectAtIndex:3];
        if( command.count > 4 ) durationParameter = [command objectAtIndex:4];
        
        // Convert parameters (which are NSStrings) to NSNumber values
        NSNumber* moveByX = @([xParameter floatValue]);
        NSNumber* moveByY = @([yParameter floatValue]);
        NSNumber* duration = @([durationParameter doubleValue]);
        
        // syntax = command:sprite:xcoord:ycoord:duration
        type = @VNScriptCommandEffectMoveSprite;
        analyzedArray = @[type, parameter1, moveByX, moveByY, duration];
        
    } else if ( [action caseInsensitiveCompare:VNScriptStringEffectMoveBackground] == NSOrderedSame ) {
        
        // Function definition
        //
        //  Name: .MOVEBACKGROUND
        //
        //  Uses Cocos2D actions to move the background by a certain number of points. This is normally used to
        //  pan the background (along the X-axis), but you can move the background up and down as well. Character
        //  sprites can also be moved along with the background, though usually at a slightly different rate;
        //  the rate is referred to as the "parallax factor." A parallax factor of 1.0 means that the character
        //  sprites move just as quickly as the background does, while a factor 0.0 means that the character
        //  sprites do not move at all.
        //
        //  Parameters:
        //
        //      #1: Amount to move sprite by X points (float) (example: 128) (default is ZERO)
        //
        //      #2: Amount to move the sprite by Y points (float) (OPTIONAL) (example: 256) (default is ZERO)
        //
        //      #3: Duration in seconds (float) (OPTIONAL) (example: 0.5) (default is 0.5 seconds)
        //          This measures how long it takes to move the sprite, in seconds.
        //
        //      #4: Parallax factor (float) (OPTIONAL) (example: 0.5) (default is 0.95)
        //          The rate at which sprites move compared to the background. 1.00 means that the
        //          sprites move at exactly the same rate as the background, while 0.00 means that
        //          the sprites do not move at all. You'll probably want to set it something in between.
        //
        //  Example: .movebackground:100:0:1.0
        //
        
        // Set default values for extra parameters
        NSString* xParameter = @"0";
        NSString* yParameter = @"0";
        NSString* durationParameter = @"0.5";
        NSString* parallaxFactor = @"0.95";
        
        // Overwrite default values with ones that exist in the script (assuming they exist, of course)
        if( command.count > 1 ) xParameter = [command objectAtIndex:1];
        if( command.count > 2 ) yParameter = [command objectAtIndex:2];
        if( command.count > 3 ) durationParameter = [command objectAtIndex:3];
        if( command.count > 4 ) parallaxFactor = [command objectAtIndex:4];
        
        // Convert parameters (which are NSStrings) to NSNumber values
        NSNumber* moveByX = @([xParameter floatValue]);
        NSNumber* moveByY = @([yParameter floatValue]);
        NSNumber* duration = @([durationParameter doubleValue]);
        NSNumber* parallaxing = @([parallaxFactor floatValue]);
        
        // syntax = command:xcoord:ycoord:duration:parallaxing
        type = @VNScriptCommandEffectMoveBackground;
        analyzedArray = @[type, moveByX, moveByY, duration, parallaxing];
        
    } else if ( [action caseInsensitiveCompare:VNScriptStringSetSpritePosition] == NSOrderedSame ) {
        
        // Function definition
        //
        //  Name: .SETSPRITEPOSITION
        //
        //  NOTE that unlike .MOVESPRITE, this call is instantaneous. I don't remember why I made it that
        //  way (probably since sprites usually don't move instantly in most visual novels), but it's probably
        //  best to keep things simple like that anyways.
        //
        //  Parameters:
        //
        //      #1: The name of the sprite (string) (example: "girl.png")
        //
        //      #2: The sprite's X coordinate, in points (float) (example: 10)
        //
        //      #3: The sprite's Y coordinate, in points (float) (example: 10)
        //
        //  Example: .setspriteposition:girl.png:100:100
        //
        
        NSString* xParameter = @"0";
        NSString* yParameter = @"0";
        
        if( command.count > 2 ) xParameter = [command objectAtIndex:2];
        if( command.count > 3 ) yParameter = [command objectAtIndex:3];
        
        NSNumber* coordinateX = @([xParameter floatValue]);
        NSNumber* coordinateY = @([yParameter floatValue]);
        
        type = @VNScriptCommandSetSpritePosition;
        analyzedArray = @[type, parameter1, coordinateX, coordinateY];
        
    } else if ( [action caseInsensitiveCompare:VNScriptStringSetBackground] == NSOrderedSame ) {
        
        // Function definition
        //
        //  Name: .SETBACKGROUND
        //
        //  Changes whatever image (if any) is used as the background. You can set this to 'nil' which removes
        //  the background entirely, and shows whatever is behind. This is useful if you're overlaying the VN
        //  scene over an existing Cocos2D layer/scene node.
        //
        //  Unlike some of the other image-switching commands, this one is supposed to do the change instantly.
        //  It might be helpful to fade-out and then fade-in the scene during transistions so that the background
        //  change isn't too jarring for the person playing the game.
        //
        //  Parameters:
        //
        //      #1: The name of the background image (string) (example: "beach.png")
        //
        //  Example: .setbackground:beach.png
        
        type = @VNScriptCommandSetBackground;
        analyzedArray = @[type, parameter1];
        
    } else if ( [action caseInsensitiveCompare:VNScriptStringSetSpeaker] == NSOrderedSame ) {
        
        // Function definition
        //
        //  Name: .SETSPEAKER
        //
        //  The "speaker name" is the title of the person speaking. If you set this to "nil" then it
        //  removes whatever the previous speaker name was.
        //
        //  Parameters:
        //
        //      #1: The name of the character speaking (string) (example: "Harry Potter")
        //
        //  Example: .setspeaker:John Smith
        //
        
        type = @VNScriptCommandSetSpeaker;
        analyzedArray = @[type, parameter1];
        
    } else if ( [action caseInsensitiveCompare:VNScriptStringChangeConversation] == NSOrderedSame ) {
        
        // Function definition
        //
        //  Name: .SETCONVERSATION
        //
        //  This jumps to a new conversation. The beginning conversation name is "start" and the other
        //  arrays in the script's Property List represent other conversations.
        //
        //  Parameters:
        //
        //      #1: The name of the conversation/array to switch to (string) (example: "flirt sequence")
        //
        //  Example: .setconversation:flirt sequence
        // 

        type = @VNScriptCommandChangeConversation;
        analyzedArray = @[type, parameter1];
        
    } else if ( [action caseInsensitiveCompare:VNScriptStringJumpOnChoice] == NSOrderedSame ) {
        
        // Function definition
        //
        //  Name: .JUMPONCHOICE
        //
        //  This presents the player with multiple choices. Each choice causes the scene to jump to a different
        //  "conversation" (or rather, an array in the script dictionary). The function can have multipe parameters,
        //  but the number should always be even-numbered.
        //
        //  Parameters:
        //
        //      #1: The name of the first action (shows up on button when player decides) (string) (example: "Run away")
        //
        //      #2: The name of the conversation to jump to (string) (example: "fleeing sequence")
        //
        //      ...these variables can be repeated multiple times.
        //
        //  Example: .JUMPONCHOICE:"Hug someone":hug sequence:"Glomp someone":glomp sequence
        //
        
        // Figure out how many choices there are
        NSInteger numberOfChoices = (command.count - 1) / 2;
        
        // Check if there's not enough data
        if( numberOfChoices < 1 || command.count < 3 ) 
            return nil;
        
        // Create some arrays; one will hold the text that appears to the player, while the other will hold
        // the names of the conversations/arrays that the script will switch to depending on the player's choice.
        NSMutableArray* choiceText = [[NSMutableArray alloc] initWithCapacity:numberOfChoices];
        NSMutableArray* destinations = [[NSMutableArray alloc] initWithCapacity:numberOfChoices];
        
        // After determining the number of choices that exist, use a loop to match each choice text with the
        // name of the conversation that each choice would correspond to. Then add both to the appropriate arrays.
        for( int i = 0; i < numberOfChoices; i++ ) {
            
            // This variable will hold 1 and then every odd number after. It starts at one because index "zero"
            // is where the actual .JUMPONCHOICE string is stored.
            int indexOfChoice = 1 + (2 * i);
            
            // Add choice data to the two separate arrays
            [choiceText addObject:[command objectAtIndex:indexOfChoice]];
            [destinations addObject:[command objectAtIndex:indexOfChoice+1]];
        }
        
        type = @VNScriptCommandJumpOnChoice;
        analyzedArray = @[type, choiceText, destinations];
        
    } else if ( [action caseInsensitiveCompare:VNScriptStringShowSpeechOrNot] == NSOrderedSame ) {
        
        // Function definition
        //
        //  Name: .SHOWSPEECH
        //
        //  Determines whether or not to show the speech (and accompanying speech-box or speech-area). You
        //  can set it to NO if you don't want any text to show up.
        //
        //  Parameters:
        //
        //      #1: Whether or not to show the speech box (Boolean)
        //
        //  Example: .SHOWSPEECH:NO
        //
        
        // Convert parameter from NSString to a Boolean NSNumber
        BOOL showParameter = [parameter1 boolValue];
        NSNumber* parameterObject = @(showParameter);
        
        type = @VNScriptCommandShowSpeechOrNot;
        analyzedArray = @[type, parameterObject];
        
    } else if ( [action caseInsensitiveCompare:VNScriptStringEffectFadeIn] == NSOrderedSame ) {
        
        // Function definition
        //
        //  Name: .FADEIN
        //
        //  Uses Cocos2D to fade-out the VN scene's backgrounds and sprites... and nothing else (UI
        //  elements like speech text are unaffected).
        //
        //  Parameters:
        //
        //      #1: Duration of fade-in sequence, in seconds (double)
        //
        //  Example: .FADEIN:0.5
        //
        
        // Convert from NSString to NSNumber
        double fadeDuration = [parameter1 doubleValue]; // NSString gets converted to a 'double' by this
        NSNumber* durationObject = @(fadeDuration);
        
        type = @VNScriptCommandEffectFadeIn;
        analyzedArray = @[type, durationObject];
        
    } else if ( [action caseInsensitiveCompare:VNScriptStringEffectFadeOut] == NSOrderedSame) {
        
        // Function definition
        //
        //  Name: .FADEOUT
        //
        //  Uses Cocos2D to fade-out the VN scene's backgrounds and sprites... and nothing else (UI
        //  elements like speech text are unaffected).
        //
        //  Parameters:
        //
        //      #1: Duration of fade-out sequence, in seconds (double)
        //
        //  Example: .FADEOUT:1.0
        //

        double fadeDuration = [parameter1 doubleValue];
        NSNumber* durationObject = @(fadeDuration);
        
        type = @VNScriptCommandEffectFadeOut;
        analyzedArray = @[type, durationObject];
        
    } else if ( [action caseInsensitiveCompare:VNScriptStringPlaySound] == NSOrderedSame ) {
        
        // Function definition
        //
        //  Name: .PLAYSOUND
        //
        //  Plays a sound (any type of sound file supported by Cocos2D/SimpleAudioEngine)
        //
        //  Parameters:
        //
        //      #1: name of sound file (string)
        //
        //  Example: .PLAYSOUND:effect1.caf
        //
        
        type = @VNScriptCommandPlaySound;
        analyzedArray = @[type, parameter1];
        
    } else if ( [action caseInsensitiveCompare:VNScriptStringPlayMusic] == NSOrderedSame ) {
        
        // Function definition
        //
        //  Name: .PLAYMUSIC
        //
        //  Plays background music. May or may not loop. You can also stop any background music
        //  by calling this with the parameter set to "nil"
        //
        //  Parameters:
        //
        //      #1: name of music filename (string)
        //          (you can write "nil" to stop all the music)
        //
        //      #2: (Optional) Should this loop forever? (BOOL value) (default is YES)
        //
        //  Example: .PLAYMUSIC:LevelUpper.mp3:NO
        //
        
        NSString* parameter2 = @"YES"; // Loops forever by default
        
        // Check if there's already a user-specified value, in which case that would override the default value
        if( command.count > 2 )
            parameter2 = [command objectAtIndex:2];
        
        // Convert the second parameter to a Boolean NSNumber, since it was originally stored as a string
        BOOL musicLoopsForever = [parameter2 boolValue];
        NSNumber* loopParameter = @(musicLoopsForever);
        
        type = @VNScriptCommandPlayMusic;
        analyzedArray = @[type, parameter1, loopParameter];
        
    } else if ( [action caseInsensitiveCompare:VNScriptStringSetFlag] == NSOrderedSame ) {
        
        // Function definition
        //
        //  Name: .SETFLAG
        //
        //  Used to manually set a "flag" value in the VN system.
        //
        //  Parameters:
        //
        //      #1: Name of flag (string)
        //
        //      #2: The value to set the flag to (integer)
        //
        //  Example: .SETFLAG:number of friends:12
        //
        
        NSString* parameter2 = @"0"; // Default value
        
        if( command.count > 2 ) 
            parameter2 = [command objectAtIndex:2];
        
        // Convert the second parameter to an NSNumber (it was originally an NSString)
        NSNumber* value = @([parameter2 intValue]);
        
        type = @VNScriptCommandSetFlag;
        analyzedArray = @[type, parameter1, value];
        
    } else if ( [action caseInsensitiveCompare:VNScriptStringModifyFlagValue] == NSOrderedSame ) {
        
        // Function definition
        //
        //  Name: .MODIFYFLAG
        //
        //  Modifies a flag (which stores a numeric, integer value) by another integer. The catch is,
        //  the modifying value has to be a "literal" number value, and not another flag/variable.
        //
        //  Parameters:
        //
        //      #1: Name of the flag/variable to modify (string)
        //
        //      #2: The number to modify the flag by (integer)
        //
        //  Example: .MODIFYFLAG:number of friends:1
        //
        
        NSString* parameter2 = @"0";
        
        if( command.count > 2 ) 
            parameter2 = [command objectAtIndex:2];
 
        NSNumber* modifyWithValue = @([parameter2 intValue]); // Converts from string to Boolean NSNumber
 
        type = @VNScriptCommandModifyFlagValue;
        analyzedArray = @[type, parameter1, modifyWithValue];
        
    } else if ( [action caseInsensitiveCompare:VNScriptStringIfFlagHasValue] == NSOrderedSame ) {
        
        // Function definition
        //
        //  Name: .ISFLAG
        //
        //  Checks if a flag matches a certain value. If it does, then it immediately runs another command.
        //  In theory, you could probably even nest .ISFLAG commands inside each other, but I've never tried
        //  this before.
        //
        //  Parameters:
        //
        //      #1: Name of flag (string)
        //
        //      #2: Expected value (integer)
        //
        //      #3: Another command
        //
        //  Example: .ISFLAG:number of friends:1:.SETSPEAKER:That One Friend You Have
        //
        
        if( command.count < 4 )
            return nil;
        
        NSString* variableName = [command objectAtIndex:1];
        NSString* expectedValue = [command objectAtIndex:2];
        NSInteger extraCount = command.count - 3; // This number = secondary command + secondary command's parameters
        
        if( variableName == nil || expectedValue == nil ) {
            NSLog(@"[VNScript] ERROR: Invalid variable name or value in .ISFLAG command");
            return nil;
        }
        
        // Now, here comes the hard part... the 3rd "parameter" (and all that follows) is actually a separate
        // command that will get executed IF the variable contains the expected value. At this point, it's necessary to
        // translate that extra command so it can be more easily run when the actual script gets run for real.
        NSMutableArray* extraCommand = [[NSMutableArray alloc] initWithCapacity:extraCount];
        
        // This loop starts at the command index where the "secondary command" is and then goes through each
        // parameter of the second command.
        for( int i = 3; i < command.count; i++ ) {
        
            // Extract the secondary/"extra" command and put it in its own array
            NSString* partOfCommand = [command objectAtIndex:i]; // 3rd parameter and everything afterwards
            [extraCommand addObject:partOfCommand]; // Add that new data to the "extra command" array
        }
        
        // Try to make sense of that secondary command... if it doesn't work out, then just give up on translating this line
        NSArray* secondaryCommand = [self analyzedCommand:extraCommand];
        if( secondaryCommand == nil ) {
            NSLog(@"[VNScript] ERROR: Could not translate secondary command of .ISFLAG");
            return nil;
        }
        
        type = @VNScriptCommandIfFlagHasValue;
        analyzedArray = @[type, variableName, expectedValue, secondaryCommand];
        
    } else if ( [action caseInsensitiveCompare:VNScriptStringIsFlagMoreThan] == NSOrderedSame ) {
        
        // Function definition
        //
        //  Name: .ISFLAGMORETHAN
        //
        //  Checks if a flag's value is above a certain number. If it is, then a secondary command is run.
        //
        //  Parameters:
        //
        //      #1: Name of flag (string)
        //
        //      #2: Certain number (integer)
        //
        //      #3: Another command
        //
        //  Example: .ISFLAGMORETHAN:power level:9000:.PLAYSOUND:over nine thousand.mp3
        //
        
        if( command.count < 4 )
            return nil;
        
        NSString* variableName = [command objectAtIndex:1];
        NSString* expectedValue = [command objectAtIndex:2];
        NSInteger extraCount = command.count - 3; // This number = secondary command + secondary command's parameters
        
        if( variableName == nil || expectedValue == nil ) {
            NSLog(@"[VNScript] ERROR: Invalid variable name or value in .ISFLAGMORETHAN command");
            return nil;
        }
        
        NSMutableArray* extraCommand = [[NSMutableArray alloc] initWithCapacity:extraCount];
        
        for( int i = 3; i < command.count; i++ ) {
            NSString* partOfCommand = [command objectAtIndex:i];
            [extraCommand addObject:partOfCommand];
        }
        
        NSArray* secondaryCommand = [self analyzedCommand:extraCommand];
        if( secondaryCommand == nil ) {
            NSLog(@"[VNScript] ERROR: Could not translate secondary command of .ISFLAGMORETHAN");
            return nil;
        }
        
        type = @VNScriptCommandIsFlagMoreThan;
        analyzedArray = @[type, variableName, expectedValue, secondaryCommand];
        
    } else if ( [action caseInsensitiveCompare:VNScriptStringIsFlagLessThan] == NSOrderedSame ) {
        
        // Function definition
        //
        //  Name: .ISFLAGLESSTHAN
        //
        //  Checks if a flag's value is below a certain number. If it is, then a secondary command is run.
        //
        //  Parameters:
        //
        //      #1: Name of flag (string)
        //
        //      #2: Certain number (integer)
        //
        //      #3: Another command
        //
        //  Example: .ISFLAGLESSTHAN:time remaining:0:.PLAYMUSIC:time's up.mp3
        //
        
        if( command.count < 4 )
            return nil;
        
        NSString* variableName = [command objectAtIndex:1];
        NSString* expectedValue = [command objectAtIndex:2];
        NSInteger extraCount = command.count - 3; // This number = secondary command + secondary command's parameters
        
        if( variableName == nil || expectedValue == nil ) {
            NSLog(@"[VNScript] ERROR: Invalid variable name or value in .ISFLAGLESSTHAN command");
            return nil;
        }
        
        NSMutableArray* extraCommand = [[NSMutableArray alloc] initWithCapacity:extraCount];
        
        for( int i = 3; i < command.count; i++ ) {
            NSString* partOfCommand = [command objectAtIndex:i];
            [extraCommand addObject:partOfCommand];
        }
        
        NSArray* secondaryCommand = [self analyzedCommand:extraCommand];
        if( secondaryCommand == nil ) {
            NSLog(@"[VNScript] ERROR: Could not translate secondary command of .ISFLAGLESSTHAN");
            return nil;
        }
        
        type = @VNScriptCommandIsFlagLessThan;
        analyzedArray = @[type, variableName, expectedValue, secondaryCommand];
    
    }else if ( [action caseInsensitiveCompare:VNScriptStringIsFlagBetween] == NSOrderedSame ) {
        
        // Function definition
        //
        //  Name: .ISFLAGBETWEEN
        //
        //  Checks if a flag's value is between two numbers, and if it is, this will run another command.
        //
        //  Parameters:
        //
        //      #1: Name of flag (string)
        //
        //      #2: First number (integer)
        //
        //      #3: Second number (integer)
        //
        //      #4: Another command
        //
        //  Example: .ISFLAGBETWEEN:number of cookies:1:3:YOU HAVE EXACTLY TWO COOKIES!
        //
        
        if( command.count < 5 )
            return nil;
        
        NSString* variableName  = [command objectAtIndex:1];
        NSString* firstValue    = [command objectAtIndex:2];
        NSString* secondValue   = [command objectAtIndex:3];
        NSInteger extraCount    = command.count - 4; // This number = secondary command + secondary command's parameters
        
        if( variableName == nil || firstValue == nil || secondValue == nil ) {
            NSLog(@"[VNScript] ERROR: Invalid variable name or value in .ISFLAGBETWEEN command");
            return nil;
        }
        
        // Figure out which value is the lesser value, and which one is the greater value. By default,
        // it's assumed first value is the "lesser" value, and the second ond is the "greater" one
        int first           = [firstValue intValue];
        int second          = [secondValue intValue];
        int lesserValue     = first;
        int greaterValue    = second;
        
        // Check if the default value assignment is wrong. In this case, the second value is the lesser one,
        // and that the first value is the greater one.
        if( first > second ) {
            // Reassign the values appropriately
            greaterValue = first;
            lesserValue = second;
        }
        
        NSMutableArray* extraCommand = [[NSMutableArray alloc] initWithCapacity:extraCount];
        
        for( int i = 4; i < command.count; i++ ) {
            NSString* partOfCommand = [command objectAtIndex:i];
            [extraCommand addObject:partOfCommand];
        }
        
        NSArray* secondaryCommand = [self analyzedCommand:extraCommand];
        if( secondaryCommand == nil ) {
            NSLog(@"[VNScript] ERROR: Could not translate secondary command of .ISFLAGBETWEEN");
            return nil;
        }
        
        // Convert greater/lesser scalar values back into NSString format for the script
        NSString* lesserValueString = [NSString stringWithFormat:@"%d", lesserValue];
        NSString* greaterValueString = [NSString stringWithFormat:@"%d", greaterValue];
        
        type = @VNScriptCommandIsFlagBetween;
        analyzedArray = @[type, variableName, lesserValueString, greaterValueString, secondaryCommand];
        
    } else if ( [action caseInsensitiveCompare:VNScriptStringModifyFlagOnChoice] == NSOrderedSame ) {
        
        // Function definition
        //
        //  Name: .MODIFYFLAGBYCHOICE
        //
        //  This presents a choice menu. Each choice causes a particular flag/variable to be changed
        //  by a particular integer value.
        //
        //  Parameters:
        //
        //      #1: The text that will appear on the choice (string)
        //
        //      #2: The name of the flag/variable to be modified (string)
        //
        //      #3: The amount to modify the flag/variable by (integer)
        //
        //      ...these variables can be repeated multiple times.
        //
        //  Example: .MODIFYFLAGBYCHOICE:"Be nice":niceness:1:"Be rude":niceness:-1
        //
        
        // Since the first item in the command array is the ".MODIFYFLAG" string, we'll just ignore that first index
        // when counting the number of choices. Also, since each set of parameters consists of three parts (choice text,
        // variable name, and variable value), the number will be divided by three to get the actual number of choices.
        NSInteger numberOfChoices = (command.count - 1) / 3;
        
        // Create some empty mutable arrays
        NSMutableArray* choiceText = [[NSMutableArray alloc] initWithCapacity:numberOfChoices];
        NSMutableArray* variableNames = [[NSMutableArray alloc] initWithCapacity:numberOfChoices];
        NSMutableArray* variableValues = [[NSMutableArray alloc] initWithCapacity:numberOfChoices];
        
        for( int i = 0; i < numberOfChoices; i++ ) {
        
        	// This is used as an offset in order to get the right index numbers for the 'command' array.
        	// It starts at 1 and then jumps to every third number thereafter (from 1 to 4, 7, 10, 13, etc).    
            int nameIndex = 1 + (i * 3);
            
            // Get the parameters for the command array
            NSString* text = [command objectAtIndex:nameIndex]; // Text to show to player
            NSString* name = [command objectAtIndex:nameIndex+1]; // The name of the flag to modify
            NSString* check = [command objectAtIndex:nameIndex+2]; // The amount to modify the flag by
            
            // Move each value to the appropriate array
            [choiceText addObject:text];
            [variableNames addObject:name];
            [variableValues addObject:check];
        }
        
        type = @VNScriptCommandModifyFlagOnChoice;
        analyzedArray = @[type, choiceText, variableNames, variableValues];
        
    } else if ( [action caseInsensitiveCompare:VNScriptStringJumpOnFlag] == NSOrderedSame ) {
        
        // Function definition
        //
        //  Name: .JUMPONFLAG
        //
        //  If a particular flag has a particular value, then this command will jump to a different
        //  conversation/dialogue-sequence in the script.
        //
        //  Parameters:
        //
        //      #1: The name of the flag to be checked (string)
        //
        //      #2: The expected value of the flag (integer)
        //
        //      #3: The scene to jump to, if the flag's vaue matches the expected value in parameter #2 (string)
        //
        //  Example: .JUMPONFLAG:should jump to beach scene:1:BeachScene
        //
        
        if( command.count < 4 )
            return nil;
        
        NSString* variableName = [command objectAtIndex:1];
        NSString* expectedValue = [command objectAtIndex:2];
        NSString* newLocation = [command objectAtIndex:3];
        
        if( variableName == nil || expectedValue == nil || newLocation == nil ) {
            NSLog(@"[VNScript] ERROR: Invalid parameters passed to .JUMPONFLAG command.");
            return nil;
        }
        
        type = @VNScriptCommandJumpOnFlag;
        analyzedArray = @[type, variableName, expectedValue, newLocation];
        
    } else if( [action caseInsensitiveCompare:VNScriptStringSystemCall] == NSOrderedSame ) {
        
        // Function definition
        //
        //  Name: .SYSTEMCALL
        //
        //  Used to do a "system call," which is usually game-specific. This command will try to contact the
        //  VNSystemCall class, and use it to perform some kind of particular task. Some examples of this would
        //  be starting a mini-game or some other activity that's specific to a particular app.
        //
        //  Parameters:
        //
        //      #1: The "call string" or a string that described what the activity/system-call type will be (string)
        //
        //      #2: (OPTIONAL) The first parameter to pass in to the system call (string?)
        //
        //      ...more parameters can be passed in as necessary
        //
        //  Example: .SYSTEMCALL:start-bullet-hell-minigame:BulletHellLevel01
        //
        
        if( command.count < 1 )
            return nil;
        
        NSString* callString = [command objectAtIndex:1]; // Extract the call string
        
        NSMutableArray* extraParameters = [NSMutableArray arrayWithArray:command];
        [extraParameters removeObjectAtIndex:1]; // Remove call type
        [extraParameters removeObjectAtIndex:0]; // Remove command
        
        // Add a dummy parameter just for the heck of it
        if( extraParameters.count < 1 )
            [extraParameters addObject:@"nil"];
        
        type = @VNScriptCommandSystemCall;
        analyzedArray = @[type, callString, extraParameters];
        
    } else if( [action caseInsensitiveCompare:VNScriptStringCallCode] == NSOrderedSame ) {
        
        // Function definition
        //
        //  Name: .CALLCODE
        //
        //  This action can be used to call functions (usually from static objects). Careful when using it to
        //  call classes or functions that the VN system doesn't have access to! You may need to include header
        //  files from certain places if you really want to use certain classes.
        //
        //  Parameters:
        //
        //      #1: The name of the class to call (string)
        //
        //      #2: The name of a static function to call (string)
        //
        //		#3: (OPTIONAL) The name of another function, PRESUMABLY a function that belongs to the class
        //			instance that was returned by the function called in #2 (string)
        //
        //		#4: (OPTIONAL) A parameter to pass into the function called in #3 (string?)
        //
        //  Example: .CALLCODE:EKRecord:sharedRecord:flagNamed:times played
        //
        
        if( command.count < 3 )
            return nil;
        
        // At this point, you'll need an array that has all the things needed to call a particular class,
        // as well as class functions. The first string in the array will be the class, the second will be
        // a "shared object" static function, and if a third string exists, it will call a particular
        // function in that class. If there are any more strings, they will be parameters. For example:
        //
        //  callingArray[0] = EKRecord
        //  callingArray[1] = sharedRecord
        //  callingArray[2] = flagNamed
        //  callingArray[3] = times played
        //
        // ...which would come out something like --> [[EKRecord sharedRecord] flagNamed:@"times played"];
        //
        NSMutableArray* callingArray = [NSMutableArray arrayWithArray:command];
        [callingArray removeObjectAtIndex:0]; // Removes the string ".callcode"
        
        type = @VNScriptCommandCallCode;
        analyzedArray = @[type, callingArray];
    } else if( [action caseInsensitiveCompare:VNScriptStringSwitchScript] == NSOrderedSame ) {
        
        // Function definition
        //
        //  Name: .SWITCHSCRIPT
        //
        //  Replaces a scene's script with a script loaded from another .PLIST file. This is useful if you're
        //  using multiple .PLIST files.
        //
        //  Parameters:
        //
        //      #1: The name of the .PLIST file to load (string)
        //
        //      #2: (OPTIONAL) The name of the "conversation"/array to start at to (string) (default is "start")
        //
        //  Example: .SWITCHSCRIPT:script number 2:Some Random Event
        //
        
        if( command.count < 2 )
            return nil;
        
        NSString* scriptName = [command objectAtIndex:1];
        NSString* startingPoint = VNScriptStartingPoint; // Default value
        
        // Check if the script name is missing
        if( scriptName == nil )
            return nil;

        // Load non-default starting point (if it exists)
        if( command.count > 2 ) {
            startingPoint = [command objectAtIndex:2];
        }
        
        type = @VNScriptCommandSwitchScript;
        
        NSLog(@"Hey, starting point is: %@", startingPoint);
        NSLog(@"Command.count is %lu", (unsigned long)command.count);
        analyzedArray = @[type, scriptName, startingPoint];
        NSLog(@"Anaylzed array is: %@", analyzedArray);
    } else if( [action caseInsensitiveCompare:VNScriptStringSetSpeakerFont] == NSOrderedSame ) {
        
        // Function definition
        //
        //  Name: .SETSPEAKERFONT
        //
        //  Replaces the current font used by the "speaker name" label with another font.
        //
        //  Parameters:
        //
        //      #1: The name of the font to use (string)
        //
        //  Example: .SETSPEAKERFONT:Helvetica
        //
        
        type = @VNScriptCommandSetSpeakerFont;
        analyzedArray = @[type, parameter1];
        
    } else if( [action caseInsensitiveCompare:VNScriptStringSetSpeakerFontSize] == NSOrderedSame ) {
        
        // Function definition
        //
        //  Name: .SETSPEAKERFONTSIZE
        //
        //  Changes the font size used by the "speaker name" label.
        //
        //  Parameters:
        //
        //      #1: Font size (float)
        //
        //  Example: .SETSPEAKERFONTSIZE:17.0
        //
        
        type = @VNScriptCommandSetSpeakerFontSize;
        analyzedArray = @[type, parameter1];
        
    } else if( [action caseInsensitiveCompare:VNScriptStringSetSpeechFont] == NSOrderedSame ) {
        
        // Function definition
        //
        //  Name: .SETSPEECHFONT
        //
        //  Replaces the current font used by the speech/dialogue label with another font.
        //
        //  Parameters:
        //
        //      #1: The name of the font to use (string)
        //
        //  Example: .SETSPEECHFONT:Courier New
        //
        
        type = @VNScriptCommandSetSpeechFont;
        analyzedArray = @[type, parameter1];
        
    } else if( [action caseInsensitiveCompare:VNScriptStringSetSpeechFontSize] == NSOrderedSame ) {
        
        // Function definition
        //
        //  Name: .SETSPEECHFONTSIZE
        //
        //  Changes the speech/dialogue font size.
        //
        //  Parameters:
        //
        //      #1: Font size (float)
        //
        //  Example: .SETSPEECHFONTSIZE:18.0
        //
        
        type = @VNScriptCommandSetSpeechFontSize;
        analyzedArray = @[type, parameter1];
    }

    
    return analyzedArray;
}




@end
