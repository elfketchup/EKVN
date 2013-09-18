//
//  VNLayer.m
//
//  Created by James Briones on 7/3/11.
//  Copyright 2011. All rights reserved.
//

#import "VNLayer.h"
#import "EKRecord.h"
#import "SimpleAudioEngine.h"

VNLayer* theCurrentScene = nil;

@implementation VNLayer

//@synthesize script = script;

#pragma - 
#pragma mark Initialization

+ (VNLayer*)currentVNLayer
{
    if( theCurrentScene == nil ) {
        CCLOG(@"[VNLayer] ERROR: No VNLayer instance found!");
    }
    
    return theCurrentScene;
}

+ (id)sceneWithSettings:(NSDictionary*)settings
{
    CCScene* scene = [CCScene node];
    VNLayer* vnlayer = [[VNLayer alloc] initWithSettings:settings];
    [scene addChild:vnlayer];
    
    // Since VNLayer is running on its own CCScene, that scene should get popped once VNLayer finishes running
    vnlayer.shouldPopScene = YES;
    
    return scene;
}

- (id)initWithSettings:(NSDictionary*)settings
{
    self = [super init];
    if( self ) {

        self.shouldPopScene = NO;
        self.isFinished = NO;
        self.touchEnabled = YES;
        self.wasJustLoadedFromSave = NO;
        
        // Set default values
        mode            = VNLayerModeLoading; // Mode is "loading resources"
        effectIsRunning = NO;
        isPlayingMusic  = NO;
        buttonPicked    = -1;
        soundsLoaded    = [[NSMutableArray alloc] init];
        sprites         = [[NSMutableDictionary alloc] init];
        record          = [[NSMutableDictionary alloc] initWithDictionary:settings]; // Copy data to local dictionary
        flags           = [[NSMutableDictionary alloc] initWithDictionary:[[[EKRecord sharedRecord] flags] copy]]; // COPY flags

        CCLOG(@"[VNLayer] Loading settings...");
        // Try to load script info from any saved script data that might exist. Otherwise, just create a fresh script object
        NSDictionary* savedScriptInfo = [settings objectForKey:VNLayerSavedScriptInfoKey];
        if( savedScriptInfo ) {
            
            // Load script data from a saved game
            script = [[VNScript alloc] initWithInfo:savedScriptInfo]; // Load saved data
            self.wasJustLoadedFromSave = YES; // Set flag; this is important since it's meant to prevent autosave errors
            script.indexesDone = script.currentIndex;
            CCLOG(@"[VNLayer] Settings were loaded from a saved game.");
            
        } else {
            
            // Create all-new script data
            script = [[VNScript alloc] initFromFile:[settings objectForKey:VNLayerToPlayKey]]; // Load data from script file
            CCLOG(@"[VNLayer] Settings were loaded from a script file.");
        }
        
        // Load default view settings
        [self loadDefaultViewSettings]; // The standard settings
        CCLOG(@"[VNLayer] Default view settings loaded.");
        
        // Load any "extra" view settings that may exist in a certain Property List file ("VNLayer View Settings.plist")
        NSString* filePath = [[NSBundle mainBundle] pathForResource:VNLayerViewSettingsFileName ofType:@"plist"];
        if( filePath ) {
            
            // Load any manual settings that might exist from the file
            NSDictionary* manualSettings = [NSDictionary dictionaryWithContentsOfFile:filePath];
            
            if( manualSettings ) {
                CCLOG(@"[VNLayer] Manual settings found; will load into view settings dictionary.");
                [viewSettings addEntriesFromDictionary:manualSettings]; // Copy custom settings to UI dictionary; overwrite default values
            }
        }
        
        [self loadUI]; // Actually load the UI using settings dictionary
        [self scheduleUpdate]; // Begin frame-by-frame processing
     
        CCLOG(@"[VNLayer] This instance of VNLayer will now become the primary VNLayer instance.");
        theCurrentScene = self;
    }
    
    return self;
}

#pragma mark -
#pragma mark Other setup or deletion functions

// The state of VNLayer's UI is stored whenever the game is saved. That way, in case music is playing, or some text is
// supposed to be on screen, VNLayer will remember and SHOULD restore things to exactly the way they were when the game
// was saved. The restoration of UI is what this function is for.
- (void)loadSavedResources
{    
	// Load any saved resource information from the dictionary
	NSArray* savedSprites       = [record objectForKey:VNLayerSpritesToShowKey];
	NSString* loadedMusic       = [record objectForKey:VNLayerMusicToPlayKey];
	NSString* savedBackground   = [record objectForKey:VNLayerBackgroundToShowKey];
	NSString* savedSpeakerName  = [record objectForKey:VNLayerSpeakerNameToShowKey];
	NSString* savedSpeech       = [record objectForKey:VNLayerSpeechToDisplayKey];
    NSNumber* showSpeechKey     = [record objectForKey:VNLayerShowSpeechKey];
    NSNumber* musicShouldLoop   = [record objectForKey:VNLayerMusicShouldLoopKey];
    CGSize screenSize           = [CCDirector sharedDirector].winSize; // Screensize is loaded to help position UI elements]
    
    // This determines whether or not the speechbox will be shown. By default, the speechbox is hidden
    // until a point in the script manually tells it to be shown, but when loading from a saved game,
    // it's necessary to know whether or not the box should be shown already
    if( showSpeechKey ) {
        
        if( [showSpeechKey boolValue] == NO ) {
            
            // If it's not supposed to show, then position it so it's JUST hidden below the bottom border of the screen
            //speechBox.position = ccp( speechBox.position.x, 0 - speechBox.boundingBox.size.height );
            speechBox.opacity = 0;
            
        } else {
            
            //float speechBoxX = [[viewSettings objectForKey:@"speechbox x"] floatValue];
            //float speechBoxY = [[viewSettings objectForKey:@"speechbox y"] floatValue];
            //speechBox.position = ccp( speechBoxX, speechBoxY );
            speechBox.opacity = 255;
            
        }
    }
	
    // Load speaker name (if any exists)
	if( savedSpeakerName ) {
		[speaker setString:savedSpeakerName];
    }
	
    // Load speech data (if any exists)
	if( savedSpeech ) {
        
		[speech setString:savedSpeech];
        
        if( self.wasJustLoadedFromSave == YES )
            [speech setString:@" "]; // Use empty text as the default
    }
    
    // Load background image (CCSprite)
	if( savedBackground ) {
		CCSprite* background = [CCSprite spriteWithFile:savedBackground];
		background.position = ccp( screenSize.width * 0.5, screenSize.height * 0.5 ); // Position the sprite / background image right in the middle of the screen
		[self addChild:background z:VNLayerBackgroundLayer tag:VNLayerTagBackground]; // Add to layer
	}
	
    // Load any music that was saved
	if( loadedMusic ) {
        
        // Check if no value was saved; create it on the fly in the (unlikely) case that no existing data could be found 
        if( musicShouldLoop == nil ) {
            musicShouldLoop = [NSNumber numberWithBool:YES]; // Assume YES by default ("forever looping" is the default behavior for VNLayer music)
        }
        
		isPlayingMusic = YES;
		[[SimpleAudioEngine sharedEngine] playBackgroundMusic:loadedMusic loop:[musicShouldLoop boolValue]];
	}
	
    // Check if any sprites need to be displayed
	if( savedSprites ) {
        
        CCLOG(@"[VNLayer] Sprite data was found in the saved game data.");
        
        // Check each entry of sprite data that was found, and start loading them into memory and displaying them onto the screen.
        // In theory, the process should be fast enough (and the number of sprites FEW enough) that the user shouldn't notice any delays.
		for( NSDictionary* spriteData in savedSprites ) {
            
            // Grab sprite data from dictionary
            NSString* spriteFilename = [spriteData objectForKey:@"name"];
            CCLOG(@"[VNLayer] Restoring saved sprite named: %@", spriteFilename);
            
            // Load CCSprite object and set its coordinates
			float spriteX = [[spriteData objectForKey:@"x"] floatValue]; // Load coordinates from dictionary
			float spriteY = [[spriteData objectForKey:@"y"] floatValue];
			CCSprite* sprite = [CCSprite spriteWithFile:spriteFilename]; // Load sprite from app bundle
			sprite.position = ccp( spriteX, spriteY );
			[self addChild:sprite z:VNLayerCharacterLayer]; // Add sprite to layer
            
            // Finally, add the sprite to the 'sprites' dictionary
            [sprites setValue:sprite forKey:spriteFilename];
		}
	}
}

// Loads the default, hard-coded values for the view / UI settings dictionary.
- (void)loadDefaultViewSettings
{
    float fontSize = VNLayerViewFontSize; // Set default font size
    float iPadFontSizeMultiplier = 1.5; // Determines how much larger the "speech text" and speaker name will be on the iPad
    
    if( viewSettings == nil )
        viewSettings = [[NSMutableDictionary alloc] init];
    
    // Manually enter the default data for the UI
    [viewSettings setValue:[NSNumber numberWithUnsignedChar:255] forKey:VNLayerViewDefaultBackgroundOpacityKey];
    [viewSettings setValue:@0.0f forKey:VNLayerViewSpeechBoxOffsetFromBottomKey];
    [viewSettings setValue:@0.5f forKey:VNLayerViewSpriteTransitionSpeedKey];
    [viewSettings setValue:@0.5f forKey:VNLayerViewTextTransitionSpeedKey];
    [viewSettings setValue:@0.5f forKey:VNLayerViewNameTransitionSpeedKey];
    [viewSettings setValue:@10.0f forKey:VNLayerViewSpeechHorizontalMarginsKey];
    [viewSettings setValue:@30.0f forKey:VNLayerViewSpeechVerticalMarginsKey];
    [viewSettings setValue:@0.0f forKey:VNLayerViewSpeechOffsetXKey];
    [viewSettings setValue:@(VNLayerViewFontSize * 2) forKey:VNLayerViewSpeechOffsetYKey];
    [viewSettings setValue:@0.0f forKey:VNLayerViewSpeakerNameXOffsetKey];
    [viewSettings setValue:@0.0f forKey:VNLayerViewSpeakerNameYOffsetKey];
    [viewSettings setValue:@(VNLayerViewFontSize) forKey:VNLayerViewFontSizeKey]; // Was 'fontSize'; changed due to iPad font multiplier
    [viewSettings setValue:VNLayerViewTalkboxName forKey:VNLayerViewSpeechBoxFilenameKey];
    [viewSettings setValue:@"choicebox.png" forKey:VNLayerViewButtonFilenameKey];
    [viewSettings setValue:@"Helvetica" forKey:VNLayerViewFontNameKey];
    [viewSettings setValue:@(iPadFontSizeMultiplier) forKey:VNLayerViewMultiplyFontSizeForiPadKey]; // This is used for the iPad
    
    NSDictionary* buttonTouchedColorsDict = @{ @"r":@(0),
                                               @"g":@(0),
                                               @"b":@(255) }; // BLUE <- r0, g0, b255
    NSDictionary* buttonUntouchedColorsDict = @{@"r":@(0),
                                                 @"g":@(0),
                                                 @"b":@(0) }; // BLACK <- r0, g0, b0
    [viewSettings setValue:buttonTouchedColorsDict forKey:VNLayerViewButtonsTouchedColorsKey];
    [viewSettings setValue:buttonUntouchedColorsDict forKey:VNLayerViewButtonUntouchedColorsKey];
}

// Actually loads images and text for the UI (as opposed to just loading information ABOUT the UI)
- (void)loadUI
{
    // Load the default settings if they don't exist yet. If there's custom data, the default settings will be overwritten.
    if( viewSettings == nil ) {
        CCLOG(@"[VNLayer] Loading default view settings.");
        [self loadDefaultViewSettings];
    }
    
    // Get screen size data; getting the size/coordiante data is very important for placing UI elements on the screen
    CGSize screenSize = [[CCDirector sharedDirector] winSize];
    float widthOfScreen = screenSize.width;
    float heightOfScreen = screenSize.height;
    
    // Check if this is on an iPad, and if the default font size should be adjusted to compensate for the larger screen size
    if( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ) {
        
        NSNumber* multiplyFontSizeForiPadFactor = [viewSettings objectForKey:VNLayerViewMultiplyFontSizeForiPadKey]; // Default is 1.5x
        NSNumber* standardFontSize = [viewSettings objectForKey:VNLayerViewFontSizeKey]; // Default value is 17.0
        if( multiplyFontSizeForiPadFactor && standardFontSize ) {
            
            float fontFactor = [multiplyFontSizeForiPadFactor floatValue];
            float fontSize = [standardFontSize floatValue] * fontFactor; // Default is standardFontSize * 1.5
            
            [viewSettings setObject:[NSNumber numberWithFloat:fontSize] forKey:VNLayerViewFontSizeKey];
            
            // The value for the offset key is reset because the font size may have changed, and offsets are affected by this.
            [viewSettings setValue:@(fontSize * 2) forKey:VNLayerViewSpeechOffsetYKey];
        }
    }
    
    // Part 1: Create speech box, and then position it at the bottom of the screen (with a small margin, if one exists).
    //         The default setting is to have NO margin/space, meaning the bottom of the box touches the bottom of the screen.
    NSString* speechBoxFile = [viewSettings objectForKey:VNLayerViewSpeechBoxFilenameKey];
    float boxToBottomMargin = [[viewSettings objectForKey:VNLayerViewSpeechBoxOffsetFromBottomKey] floatValue];
    speechBox = [CCSprite spriteWithFile:speechBoxFile];
    speechBox.position = ccp( widthOfScreen * 0.5, ([speechBox boundingBox].size.height * 0.5) + boxToBottomMargin );
    [self addChild:speechBox z:VNLayerUILayer tag:VNLayerTagSpeechBox];
    
    // Save speech box position in the settings dictionary; this is useful in case you need to restore it to its default position later
    [viewSettings setValue:@(speechBox.position.x) forKey:@"speechbox x"];
    [viewSettings setValue:@(speechBox.position.y) forKey:@"speechbox y"];
    
    // Hide the speech-box by default. The top of the speechbox is now JUST below the bottom of the screen.
    //CGPoint hiddenBoxPosition = ccp( speechBox.position.x, 0 - speechBox.boundingBox.size.height );
    //speechBox.position = hiddenBoxPosition;
    speechBox.opacity = 0;
    
    // It's possible that the speechbox sprite may be wider than the width of the screen (this can happen if a
    // speechbox designed for the iPhone 5 is shown on an iPhone 4S or earlier). As the speech text's boundaries
    // are based (by default, at least) on the width and height of the speechbox sprite, it may be necessary to
    // pretend that the speechbox is smaller in order to fit it on a pre-iPhone5 screen.
    CGFloat widthOfSpeechBox = speechBox.boundingBox.size.width;
    CGFloat heightOfSpeechBox = speechBox.boundingBox.size.height;
    if( widthOfSpeechBox > widthOfScreen ) {
        widthOfSpeechBox = widthOfScreen; // Limit the width to whatever the screen's width is
    }
    
    // Part 2: Create the speech label.
    // The "margins" part is tricky. When generating the size for the CCLabelTTF object, it's important to pretend
    // that the margins value is twice as large (as what's stored), since the label's position won't be in the
    // exact center of the speech box, but slightly to the right and down, to create "margins" between speech and
    // the box it's displayed in.
    float verticalMargins = [[viewSettings objectForKey:VNLayerViewSpeechVerticalMarginsKey] floatValue];
    float horizontalMargins = [[viewSettings objectForKey:VNLayerViewSpeechHorizontalMarginsKey] floatValue];
    CGSize speechSize = CGSizeMake( widthOfSpeechBox - (horizontalMargins * 2.0),
                                    heightOfSpeechBox - (verticalMargins * 2.0) );
    CGFloat fontSize = [[viewSettings objectForKey:VNLayerViewFontSizeKey] floatValue];

    // Now actually create the speech label. By default, it's just empty text (until a character/narrator speaks later on)
    speech = [CCLabelTTF labelWithString:@" "
                                fontName:[viewSettings objectForKey:VNLayerViewFontNameKey]
                                fontSize:fontSize
                              dimensions:speechSize
                              hAlignment:UITextAlignmentLeft
                           lineBreakMode:UILineBreakModeWordWrap];
    
    // Make sure that the position is slightly off-center from where the textbox would be (plus any other offsets that may exist).
    float speechXOffset = [[viewSettings objectForKey:VNLayerViewSpeechOffsetXKey] floatValue];
    float speechYOffset = [[viewSettings objectForKey:VNLayerViewSpeechOffsetYKey] floatValue];
    speech.position = ccp( speechBox.boundingBox.size.width * 0.5 + horizontalMargins + speechXOffset,
                           speechBox.boundingBox.size.height * 0.5 + verticalMargins - speechYOffset );
    [speechBox addChild:speech z:VNLayerTextLayer tag:VNLayerTagSpeechText];
    
    // Part 3: Create speaker label
    // But first, figure out all the offsets and sizes.
    CGPoint speakerNameOffsets  = ccp( 0.0, 0.0 );
    CGSize speakerSize          = CGSizeMake( widthOfSpeechBox  * 0.99,
                                              [speechBox boundingBox].size.height * 0.95  );
    
    NSNumber* speakerNameOffsetXValue = [viewSettings objectForKey:VNLayerViewSpeakerNameXOffsetKey];
    NSNumber* speakerNameOffsetYValue = [viewSettings objectForKey:VNLayerViewSpeakerNameYOffsetKey];
    if( speakerNameOffsetXValue ) speakerNameOffsets.x = [speakerNameOffsetXValue floatValue];
    if( speakerNameOffsetYValue ) speakerNameOffsets.y = [speakerNameOffsetYValue floatValue];
    
    // Add the speaker to the speech-box. The "name" is just empty text by default, until an actual name is provided later.
    speaker = [CCLabelTTF labelWithString:@" "
                                 fontName:[viewSettings objectForKey:VNLayerViewFontNameKey]
                                 fontSize:fontSize * 1.1
                               dimensions:speakerSize
                               hAlignment:UILineBreakModeWordWrap
                            lineBreakMode:UITextAlignmentLeft];
    
    // Position the label and then add it to the display
    speaker.position = ccp( speechBox.boundingBox.size.width * 0.5, speechBox.boundingBox.size.height * 0.5);
    speaker.position = ccpAdd( speaker.position, speakerNameOffsets );
    [speechBox addChild:speaker z:VNLayerTextLayer tag:VNLayerTagSpeakerName];
    
    // Part 4: Load the button colors
    // First load the default colors
    buttonUntouchedColors = ccBLACK;
    buttonTouchedColors = ccBLUE;
    
    // Grab dictionaries from view settings
    NSDictionary* buttonUntouchedColorsDict = [viewSettings objectForKey:VNLayerViewButtonUntouchedColorsKey];
    NSDictionary* buttonTouchedColorsDict = [viewSettings objectForKey:VNLayerViewButtonsTouchedColorsKey];
    
    // Copy values from the dictionary
    if( buttonUntouchedColorsDict ) {
        CCLOG(@"[VNLayer] Untouched buttons colors settings = %@", buttonUntouchedColorsDict);
        buttonUntouchedColors.r = [[buttonUntouchedColorsDict objectForKey:@"r"] unsignedCharValue];
        buttonUntouchedColors.g = [[buttonUntouchedColorsDict objectForKey:@"g"] unsignedCharValue];
        buttonUntouchedColors.b = [[buttonUntouchedColorsDict objectForKey:@"b"] unsignedCharValue];
    }
    if( buttonTouchedColorsDict ) {
        CCLOG(@"[VNLayer] Touched buttons colors settings = %@", buttonTouchedColorsDict);
        buttonTouchedColors.r = [[buttonTouchedColorsDict objectForKey:@"r"] unsignedCharValue];
        buttonTouchedColors.g = [[buttonTouchedColorsDict objectForKey:@"g"] unsignedCharValue];
        buttonTouchedColors.b = [[buttonTouchedColorsDict objectForKey:@"b"] unsignedCharValue];
    }
    
    // Part 5: Load any other stuff. Transition speeds (which determine how quickly things appear or disappear) go here.
    spriteTransitionSpeed   = [[viewSettings objectForKey:VNLayerViewSpriteTransitionSpeedKey] floatValue];
    speechTransitionSpeed   = [[viewSettings objectForKey:VNLayerViewTextTransitionSpeedKey]   floatValue];
    speakerTransitionSpeed  = [[viewSettings objectForKey:VNLayerViewNameTransitionSpeedKey]   floatValue];
}

// Removes unused character sprites (CCSprite objects) from memory.
- (void)removeUnusedSprites
{
    if( spritesToRemove == nil || spritesToRemove.count < 1 ) // Check if there's nothing that needs doing
        return;
    
    CCLOG(@"[VNLayer] Will now remove unused sprites (%u found).", spritesToRemove.count);
    
    // Get all the CCSprite objects in the array and then remove them
    //for( CCSprite* sprite in spritesToRemove ) {
    for( int i = (spritesToRemove.count - 1); i >= 0; i-- ) {
        
        CCSprite* sprite = [spritesToRemove objectAtIndex:i];
        
        // If the sprite is part of some node/layer and is no longer visible, then it's really "unused" and can be removed
        //if( sprite.parent != nil && sprite.opacity < 10 ) {
        if( sprite.parent != nil && sprite.tag == VNLayerSpriteIsSafeToRemove) {
            
            [spritesToRemove removeObject:sprite]; // Remove from array also
            [sprite removeFromParentAndCleanup:YES];
        }
    }
}

// This takes all the "active" sprites and moves them to the "inactive" list. If you really want to remove them from memory, you
// should call 'removeUnusedSprites' soon afterwards; that will actually remove the CCSprite objects from RAM.
- (void)markActiveSpritesAsUnused
{
    if( sprites == nil || sprites.count < 1 ) // Check if there are no active sprites at all
        return;
    
    // Check if the "sprites to remove" array needs to be created.
    if( spritesToRemove == nil ) {
        spritesToRemove = [[NSMutableArray alloc] init];
    }
    
    CCLOG(@"[VNLayer] Will now remove ACTIVE sprites.");
    
    // Grab all the sprites (by name or "key") and relocate them to the "inactive sprites" list
    for( NSString* spriteName in [sprites allKeys] ) {
        
        CCSprite* spriteToRelocate = [sprites objectForKey:spriteName]; // Grab sprite from active sprites dictionary
        spriteToRelocate.opacity = 0;                                   // Mark as invisble/inactive (inactive as far as VNLayer is concerned)
        spriteToRelocate.tag = VNLayerSpriteIsSafeToRemove;             // Mark as definitely unused
        [spritesToRemove addObject:spriteToRelocate];                   // Push to inactive sprites array
        [sprites removeObjectForKey:spriteName];                        // Remove from "active sprites" dictionary
    }
}

// Currently, this removes "unused" character sprites, plus all audio. The name may be misleading, since it doesn't
// remove "active" character sprites or the background.
- (void)purgeDataCreatedByScene
{
    [self markActiveSpritesAsUnused]; // Mark all sprites as being unused
    [self removeUnusedSprites]; // Remove the "unused" sprites
    [spritesToRemove removeAllObjects];
    [sprites removeAllObjects];
    
    // Check if any sounds were loaded; they should be removed by this function.
    if( soundsLoaded ) {
        
        // Remove all sounds loaded
        for( NSString* soundFileName in soundsLoaded ) {
            [[SimpleAudioEngine sharedEngine] unloadEffect:soundFileName];
        }
        
        // Now that the sounds are unloaded, remove the information ABOUT the sounds as well.
        [soundsLoaded removeAllObjects];
        soundsLoaded = nil;
    }
    
    // Unload any music that may be playing.
    if( isPlayingMusic ) {
        [[SimpleAudioEngine sharedEngine] stopBackgroundMusic];
        isPlayingMusic = NO; // Make sure this is set to NO, since the function might be called more than once!
    }
    
    // Now, forcibly get rid of anything that might have been missed
    if( self.children && self.children.count > 0 ) {
        
        CCLOG(@"[VNLayer] Will now forcibly remove all child nodes of this layer.");
        
        for( CCNode* remainingChildNode in self.children ) {
            [remainingChildNode removeFromParent];
        }
    }
}

#pragma mark -
#pragma mark Misc and Utility

// The set/clear effect-running-flag functions exist so that Cocos2D can call them after certain actions
// (or sequences of actions) have been run. The "effect is running" flag is important, since it lets VNLayer
// know when it's safe (or unsafe) to do certain things (which might interrupt the effect that's being run).
- (void)setEffectRunningFlag
{
    CCLOG(@"[VNLayer] Effect will be running.");
    effectIsRunning = YES;
    mode = VNLayerModeEffectIsRunning;
}
- (void)clearEffectRunningFlag
{
    effectIsRunning = NO;
    CCLOG(@"[VNLayer] Effect is no longer running.");
}

// Update script info. This consists of index data, the script name, and which conversation/section is the current one
// being displayed (or run) before the player.
- (void)updateScriptInfo
{
    if( script ) {
        // Save existing script information (indexes, "current" conversation name, etc.) in the record.
        // This overwrites any script information which may already have been stored.
        [record setObject:[script info] forKey:VNLayerSavedScriptInfoKey];
    }
}

// This saves important information (script info, flags, which resources are being used, etc) to EKRecord.
- (void)saveToRecord
{
    CCLOG(@"[VNLayer] Saving data to record.");
    
    // Create the default "dictionary to save" that will be passed into EKRecord's "activity dictionary."
    // Keep in mind that the activity dictionary holds the type of activity that the player was engaged in
    // when the game was saved (in this case, the activity is a VN scene), plus any specific details
    // of that activity (in this case, the script's data, which includes indexes, script name, etc.)
    NSMutableDictionary* dictToSave = [[NSMutableDictionary alloc] init];
    [dictToSave setObject:VNLayerActivityType forKey:EKRecordActivityTypeKey]; // Set activity type (VNLayer)
    
    // Check if the "safe save" exists; if it does, then it should be used instead of whatever the current data is.
    if( safeSave != nil ) {
    
        [[[EKRecord sharedRecord] flags] addEntriesFromDictionary:[safeSave objectForKey:@"flags"]];
        [dictToSave setObject:[safeSave objectForKey:@"record"] forKey:EKRecordActivityDataKey];
        [[EKRecord sharedRecord] setActivityDict:dictToSave];
        return;
    }
    
    // Save all the names and coordinates of the sprites still active in the scene. This data will be enough
    // to recreate them later on, when the game is loaded from saved data.
    NSArray* spritesToSave = [self spriteDataFromScene];
    if( spritesToSave ) {
        [record setValue:spritesToSave forKey:VNLayerSpritesToShowKey];
    }
    
    // Load all flag data back to EKRecord. Remember that VNLayer doesn't have a monopoly on flag data;
    // other classes and game systems can modify the flags as well! 
    [[EKRecord sharedRecord].flags addEntriesFromDictionary:flags];
    
    // Update script data and then load it into the activity dictionary.
    [self updateScriptInfo];                                        // Update all index and conversation data
    [dictToSave setObject:record forKey:EKRecordActivityDataKey];   // Load into activity dictionary
    [[EKRecord sharedRecord] setActivityDict:dictToSave];           // Save the activity dictionary into EKRecord
    [[EKRecord sharedRecord] saveToDevice];                         // Save all record data to device memory
    
    CCLOG(@"[VNLayer] Data has been saved. Stored data is: %@", dictToSave);
}

// Create the "safe save." This function usually gets called before VNLayer does some sort of volatile/potentially-hazardous
// operation, like performing effects or presenting the player with choices menus. In case the game needs to be saved during
// times like this, the data stored in the "safe save" will be the data that's stored in the saved game.
- (void)createSafeSave
{
    CCLOG(@"[VNLayer] Creating safe-save data.");
    [self updateScriptInfo]; // Update index data, conversation name, script filename, etc. to the most recent information
    
    // Save sprite names and coordinates
    NSArray* spritesToSave = [self spriteDataFromScene];
    if( spritesToSave )
        [record setValue:spritesToSave forKey:VNLayerSpritesToShowKey];
    
    // Create dictionary object
    safeSave = [[NSDictionary alloc] initWithObjectsAndKeys:[flags copy], @"flags",    // Holds flags before they were modified
                                                            record, @"record",         // Holds sprite data, UI data, etc.
                                                            [script info], VNLayerSavedScriptInfoKey, // Script/index/conversationd ata
                                                            nil];
}

- (void)removeSafeSave
{
    CCLOG(@"[VNLayer] Removing safe-save data.");
    safeSave = nil;
}

// This creates an array that stores all the sprite filenames and coordinates. When the game is loaded from saved data,
// the sprites can be easily reloaded and repositioned.
- (NSArray*)spriteDataFromScene
{
    if( sprites == nil || sprites.count < 1 )
        return nil;
    
    CCLOG(@"[VNLayer] Retrieving sprite data from scene!");
    
    // Create the "sprites array." Each index in the array holds a dictionary, and each dictionary holds
    // certain data: sprite filename, sprite x coordinate, and sprite y coordinate.
    NSMutableArray* spritesArray = [NSMutableArray array];
    
    // Get every single sprite from the 'sprites' dictionary and extract the relevent data from it.
    for( NSString* spriteName in [sprites allKeys] ) {
        
        CCLOG(@"[VNLayer] Saving sprite named: %@", spriteName);
        CCSprite* actualSprite = [sprites objectForKey:spriteName]; // The actual CCSprite object is used as a reference (for getting coordinate data)
        NSNumber* spriteX = @(actualSprite.position.x); // Get coordinates; these will be saved to the dictionary.
        NSNumber* spriteY = @(actualSprite.position.y);
        
        // Save relevant data (sprite name and coordinates) in a dictionary
        NSDictionary* savedSpriteData = @{  @"name" : spriteName,
                                            @"x"    : spriteX,
                                            @"y"    : spriteY };
        
        // Save dictionary data into the array (which will later be saved to a file)
        [spritesArray addObject:savedSpriteData];
    }
    
    return [NSArray arrayWithArray:spritesArray];
}

#pragma mark -
#pragma mark Core functions

- (void)ccTouchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
    UITouch* anyTouch = [touches anyObject];
    CGPoint locationInView = [anyTouch locationInView:anyTouch.view];
    CGPoint touchPos = [[CCDirector sharedDirector] convertToGL:locationInView];
    
    // During the "choice" sections of the VN scene, any buttons that are touched in the menu will
    // change their background  appearance (to blue, by default), while all the untouched buttons
    // will stay black by default. In both cases, the color of text ON the button remains unchanged.
    if( mode == VNLayerModeChoiceWithJump || mode == VNLayerModeChoiceWithFlag ) {
        
        if( buttons ) {
            
            for( CCSprite* button in buttons ) {
                
                if( CGRectContainsPoint([button boundingBox], touchPos) ) {
                    
                    button.color = buttonTouchedColors; // The touched button will appear blue (or whatever color this has been set to)
                    
                } else {
                    
                    button.color = buttonUntouchedColors; // All untouched buttons will appear black (or a custom color)
                }
            }
        }
    }
}

- (void)ccTouchesMoved:(NSSet*)touches withEvent:(UIEvent*)event
{
    UITouch* anyTouch = [touches anyObject];
    CGPoint locationInView = [anyTouch locationInView:anyTouch.view];
    CGPoint touchPos = [[CCDirector sharedDirector] convertToGL:locationInView];
    
    if( mode == VNLayerModeChoiceWithJump || mode == VNLayerModeChoiceWithFlag ) {
        
        if( buttons ) {
            
            for( CCSprite* button in buttons ) {
                
                if( CGRectContainsPoint([button boundingBox], touchPos) ) {
                    
                    button.color = buttonTouchedColors;
                    
                } else {
                    
                    button.color = buttonUntouchedColors;
                }
            }
        }
    }
}

- (void)ccTouchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
{
    UITouch* anyTouch = [touches anyObject];
    CGPoint locationInView = [anyTouch locationInView:anyTouch.view];
    CGPoint touchPos = [[CCDirector sharedDirector] convertToGL:locationInView];
    
    // Check if this is the "normal mode," in which there are no choices and dialogue is just displayed normally.
    // Every time the user does "Touches Ended" during Normal Mode, VNLayer advances to the next command (or line
    // of dialogue).
    if( mode == VNLayerModeNormal ) { // Story mode
        
        // The "just loaded from save" flag is disabled once the user passes the first line of dialogue
        if( self.wasJustLoadedFromSave == YES ) {
            self.wasJustLoadedFromSave = NO; // Remove flag
        }
        
        [script advanceIndex]; // Move the script forward
        
    // If the current mode is some kind of choice menu, then Touches Ended actually picks a choice (assuming,
    // of course, that the touch landed on a button).
    } else if( mode == VNLayerModeChoiceWithJump || mode == VNLayerModeChoiceWithFlag ) { // Choice menu mode

        if( buttons ) {
            
            for( CCSprite* button in buttons ) {
                
                if( CGRectContainsPoint([button boundingBox], touchPos) ) {
                    
                    button.color = buttonTouchedColors;
                    buttonPicked = button.tag; // Remember the button's tag/ID for later. 'buttonPicked' is normally set to -1, but
                                               // when a button is pressed, then the button's tag number is copied over to 'buttonPicked'
                                               // so that VNLayer will know which button was pressed.
                } else {
                    
                    button.color = buttonUntouchedColors;
                }
            }
        }
    }
}

- (void)update:(ccTime)delta
{
    // Check if the scene is finished
    if( script.isFinished == YES ) {
        
        // Print the 'quitting time' message
        CCLOG(@"[VNLayer] The 'Script Is Finished' flag is triggered. Now moving to 'end of script' mode.");
        mode = VNLayerModeEnded; // Set 'end' mode
    }
    
    switch( mode ) {
        
        // Resources need to be loaded?
        case VNLayerModeLoading:

            CCLOG(@"[VNLayer] Now in 'loading mode'");
            
            // Do any last-minute loading operations here
			[self loadSavedResources];

            // Switch to 'clean-up loading' mode
            mode = VNLayerModeFinishedLoading; 
            break;
            
        // Have all the resources and script data just finished loading?
        case VNLayerModeFinishedLoading:
            
            CCLOG(@"[VNLayer] Finished loading.");
            
            // Switch to "Normal Mode" (which is where the dialogue and normal script processing happen)
            mode = VNLayerModeNormal;
            break;
            
        // Is everything just being processed as usual?
        case VNLayerModeNormal:
            
            // Check if there's any safe-save data. When the scene has switched over to Normal Mode, then the safe-save
            // becomes unnecessary, since the conditions that caused it (like certain effects being run) are no longer
            // active. In this case, the safe-save should just be removed so that the normal data can be saved.
            if( safeSave ) {
                [self removeSafeSave];
            }
            
            // Take care of normal operations
            [self runScript]; // Process script data
            break;
            
        // Is an effect currently running? (this is normally when the "safe save" data comes into play)
        case VNLayerModeEffectIsRunning:
            
            // Ask the scene view object if the effect has finished. If it has, then it will delete the effect object automatically,
            // and then it will be time for VNLayer to return to 'normal' mode.
            if( effectIsRunning == NO ) {
                
                [self removeSafeSave];
                
                // Change mode
                mode = VNLayerModeNormal;
            }
            
            break;
        
        // Is the player being presented with a choice menu? (the "choice with jump" means that when the user makes a choice,
        // VNLayer "jumps" to a different array of dialogue immediately afterwards.)
        case VNLayerModeChoiceWithJump:
            
            // Check if there was any input. Normally, 'buttonPicked' is set to -1, but when a button is pressed,
            // the button's tag (which is always zero or higher) is copied over to 'buttonPicked', and so it's possible
            // to figure out which button was pressed just by seeing what value was stored in 'buttonPicked'
            if( buttonPicked >= 0 ) {
                
                NSString* conversationToJumpTo = [choices objectAtIndex:buttonPicked]; // The conversation names are stored in the 'choices' array
                [script changeConversationTo:conversationToJumpTo]; // Switch to the new "conversation" / dialogue array.
                mode = VNLayerModeNormal; // Go back to Normal Mode (after this has been processed, of course)
                
                // Get rid of any lingering objects in memory
                if( buttons ) {
                    for( CCSprite* button in buttons ) {
                        [button removeAllChildrenWithCleanup:NO]; // Get rid of text labels
                        [button removeFromParentAndCleanup:NO]; // Get rid of the button's CCSprite object
                    }
                }
                
                buttons = nil;
                buttonPicked = -1; // Reset "which button was pressed" to its default, untouched state
            }
            
            break;
        
        // Is the player being presented with another choice menu? (the "choice with flag" means that when a user makes a choice,
        // VNLayer just changes the value of a "flag" or variable that it's keeping track of. Later, when the game is saved, the
        // value of that flag is copied over to EKRecord).
        case VNLayerModeChoiceWithFlag:
                        
            if( buttonPicked >= 0 ) {
                
                // Get array elements
                id flagName  = [choices objectAtIndex:buttonPicked];
                id flagValue = [choiceExtras objectAtIndex:buttonPicked];
                id oldFlag   = [flags objectForKey:flagName];
                
                // Check if the flag had a previously existing value; if it did, then just add the old value to the new value
                if( oldFlag ) {
                    
                    id tempValue = [NSNumber numberWithInt:([oldFlag intValue] + [flagValue intValue])];
                    flagValue = tempValue;
                }
                
                // Set the new value of the flag. The change will be made to the "local" flag dictionary, not the
                // global one stored in EKRecord. This is to prevent any save-data conflicts (since it's certainly
                // possible that not all the data in the VNLayer will be stored along with the updated flag data)
                [flags setValue:flagValue forKey:flagName];
                
                // Get rid of any unnecessary objects in memory
                if( buttons ) {
                    for( CCSprite* button in buttons ) {
                        [button removeAllChildrenWithCleanup:NO];
                        [button removeFromParentAndCleanup:NO];
                    }
                }
                
                // Get rid of any lingering data
                buttons = nil;
                choices = nil;
                choiceExtras = nil;
                buttonPicked = -1; // Reset this to the original, untouched value
                
                // Return to 'normal' mode
                mode = VNLayerModeNormal;
            }
            
            break;
            
        // Has the script been finished?
        case VNLayerModeEnded:
            
            if( self.isFinished == NO ) {
            
                CCLOG(@"[VNLayer] The scene has ended. Flag data will be auto-saved.");
                CCLOG(@"[VNLayer] Remaining scene and activity data will be deleted.");
            
                // Save all necessary data
                EKRecord* theRecord = [EKRecord sharedRecord];
                [theRecord addExistingFlags:flags]; // Save flag data (this can overwrite existing flag values)
                //[theRecord resetActivityInformationInDict:theRecord.record]; // Remove activity data from record
                
                self.isFinished = YES; // Mark as finished
                [self purgeDataCreatedByScene]; // Get rid of all data stored by the scene
                
                if( self.shouldPopScene == YES ) {
                    CCLOG(@"[VNLayer] VNLayer will now ask Cocos2D to pop the current scene.");
                    [[CCDirector sharedDirector] popScene];
                }
                
                // TODO: Add more shutdown code
            }
            
            break;
            
        default:break;
    }
}

// Processes the script (during "Normal Mode"). This function determines whether it's safe to process the script (since there are
// many times when it might be considered "unsafe," such as when effects are being run, or even if it's something mundane like
// waiting for user input).
- (void)runScript
{
    BOOL scriptShouldBeRun = YES; // This flag is used to run the following loop...
    
    while( scriptShouldBeRun == YES ) {
        
        // Check if there's anything that could change this flag
        if( [script lineShouldBeProcessed] == NO ) // Have enough indexes been processed for now?
            scriptShouldBeRun = NO;
        if( mode == VNLayerModeEffectIsRunning ) // When effects are running, it becomes impossible to reliably process the script
            scriptShouldBeRun = NO;
        if( mode == VNLayerModeChoiceWithJump || mode == VNLayerModeChoiceWithFlag ) // Should a choice be made?
            scriptShouldBeRun = NO; // Can't run script while waiting for player input!
        
        // Check if any of the "stop running" conditions were met
        if( scriptShouldBeRun == NO )
            return; // Stop the function; nothing else should be done for now
        
        /* If the function has made it this far, then it's time to grab more script data and process that */
        
        // Get the current line/command from the script
        NSArray* currentCommand = [script currentCommand];
        
        // Check if there is no valid data (this might also mean that there are no more commands at all)
        if( currentCommand == nil ) {
            // Print warning message and finish the scene
            CCLOG(@"[VNLayer] NOTICE: Script has run out of commands. Switching to 'Scene Ended' mode...");
            mode = VNLayerModeEnded;
            return;
        }
        
        // Helpful output! This is just optional, but it's useful for development (especially for tracking
        // bugs and crashes... hopefully most of those have been ironed out at this point!)
        CCLOG(@"[%d] %@ - %@", script.currentIndex, [currentCommand objectAtIndex:0], [currentCommand objectAtIndex:1]);
        
        [self processCommand:currentCommand];   // Handle whatever line was just taken from the script
        script.indexesDone++;                   // Tell the script that it's handled yet another line
    }
}
 
#pragma mark - Script Processing

// This is the most important function; it breaks down the data stored in each line of the script and actually
// does something useful with it.
- (void)processCommand:(NSArray *)command
{
    if( command == nil || command.count < 1 )
        return;
    
    // Extract some data from the command
    int type        = [[command objectAtIndex:0] intValue]; // Command type, always stored as 'int'
    id parameter1   = [command objectAtIndex:1]; // Get the first parameter (which might be a string, number, etc)
    
    // Check if there's not enough parameters; all commands should have at least one.
    if( parameter1 == nil ) {
        CCLOG(@"[VNLayer] ERROR: No parameter detected; all commands must have at least 1 parameter!");
        return;
    }
    
    // Check if the command is really just "display a regular line of text"
    if( type == VNScriptCommandSayLine ) {
        
        // Speech opacity is set to zero, making it invisible. Remember, speech is supposed to "fade in"
        // instead of instantly appearing, since an instant appearance can be visually jarring to players.
        speech.opacity = 0;
        [speech setString:parameter1]; // Copy over the text (while the text label is "invisble")
        [record setValue:parameter1 forKey:VNLayerSpeechToDisplayKey]; // Copy text to save-game record
        
        // Now have the text fade into full visibility.
        CCFadeIn* fadeIn = [CCFadeIn actionWithDuration:speechTransitionSpeed];
        [speech runAction:fadeIn];
        
        return;
    }

    // Advance the script's index to make sure that commands run one after the other. Otherwise, they will only run one at a time
    // and the user would have to keep touching the screen each time in order for the next command to be run. Except for the
    // "display a line of text" command, most of the commands are designed to run one after the other seamlessly.
    script.currentIndex++;
    
    // Now, figure out what type of command this is!
    switch( type ) {
            
        // Adds a CCSprite object to the screen; the image is loaded from a file in the app bundle. Currently, VNLayer doesn't
        // support texture atlases, so it can only load the WHOLE IMAGE as-is.
        case VNScriptCommandAddSprite: {
            
            NSString* spriteName = parameter1;
            BOOL appearAtOnce = [[command objectAtIndex:2] boolValue]; // Should the sprite show up at once, or fade in (like text does)
            
            if( sprites == nil ) {
                sprites = [[NSMutableDictionary alloc] initWithCapacity:1]; // Lazy-load the sprites dictionary if it doesn't already exist.
            }
            
            // Check if this sprite already exists, and if it does, then stop the function since there's no point adding the sprite a second time.
            id spriteAlreadyExists = [sprites objectForKey:spriteName];
            if( spriteAlreadyExists )
                return;
            
            // Try to load the sprite from an image in the app bundle
            CCSprite* createdSprite = [CCSprite spriteWithFile:spriteName]; // Loads from file; sprite-sheets not supported
            if( createdSprite == nil ) {
                CCLOG(@"[VNLayer] ERROR: Could not load sprite named: %@!", spriteName);
                return;
            }
            
            // Add the newly-created sprite to the sprite dictionary
            [sprites setValue:createdSprite forKey:spriteName];
            
            // Position the sprite at the center; the position can be changed later. Usually, the command to change sprite positions
            // is almost immediately right after the command to add the sprite; the commands are executed so quickly that the user
            // shouldn't see any delay.
            CGSize screenSize = [[CCDirector sharedDirector] winSize];
            createdSprite.position = ccp( screenSize.width * 0.5, screenSize.height * 0.5 ); // Sprite positioned at screen center
            [self addChild:createdSprite z:VNLayerCharacterLayer];
            
            // Right now, the sprite is fully visible on the screen. If it's supposed to fade in, then the opacity is set to zero
            // (making the sprite "invisible") and then it fades in over a period of time (by default, that period is half a second).
            if( appearAtOnce == NO ) {
                
                // Make the sprite fade in gradually ("gradually" being a relative term!)
                createdSprite.opacity = 0.0;
                CCFadeIn* fadeIn = [CCFadeIn actionWithDuration:spriteTransitionSpeed];
                [createdSprite runAction:fadeIn];
            }
            
        }break;
        
        // This "aligns" a sprite so that it's either in the left, center, or right areas of the screen. (This is calculated as being
        // 25%, 50% or 75% of the screen width).
        case VNScriptCommandAlignSprite: {
            
            NSString* spriteName = parameter1;
            NSString* newAlignment = [command objectAtIndex:2]; // "left", "center", "right"
            NSNumber* duration = [command objectAtIndex:3]; // Default duration is 0.5 seconds; this is stored as an NSNumber (double)
            double durationAsDouble = [duration doubleValue]; // For when an actual scalar value has to be passed (instead of NSNumber)
            float alignmentFactor = 0.5; // 0.50 is the center of the screen, 0.25 is left-aligned, and 0.75 is right-aligned
            
            // STEP ONE: Find the sprite if it exists. If it doesn't, then just stop the function.
            CCSprite* sprite = [sprites objectForKey:spriteName];
            if( sprite == nil )
                return;
            
            // STEP TWO: Set the new sprite position
            
            // Check the string to find out if the sprite should be left-aligned or right-aligned instead
            if( [newAlignment caseInsensitiveCompare:VNLayerViewSpriteAlignmentLeftString] == NSOrderedSame ) {
    
                alignmentFactor = 0.25; // "left"

            } else if( [newAlignment caseInsensitiveCompare:VNLayerViewSpriteAlignmentRightString] == NSOrderedSame ) {
        
                alignmentFactor = 0.75; // "right"
                
            } else if( [newAlignment caseInsensitiveCompare:VNLayerViewSpriteAlignemntFarLeftString] == NSOrderedSame ) {
                
                alignmentFactor = 0.0; // "far left"
                
            } else if( [newAlignment caseInsensitiveCompare:VNLayerViewSpriteAlignmentFarRightString] == NSOrderedSame ) {
                
                alignmentFactor = 1.0; // "far right"
                
            } else if( [newAlignment caseInsensitiveCompare:VNLayerViewSpriteAlignmentExtremeLeftString] == NSOrderedSame ) {
                
                alignmentFactor = -0.5; // "extreme left"
                
            } else if( [newAlignment caseInsensitiveCompare:VNLayerViewSpriteAlignmentExtremeRightString] == NSOrderedSame ) {
                
                alignmentFactor = 1.5; // "extreme right"
            }
            
            // Tell the view to instantly re-position the sprite
            float updatedX = [[CCDirector sharedDirector] winSize].width * alignmentFactor;
            //float updatedY = [[CCDirector sharedDirector] winSize].height * 0.5;
            float updatedY = sprite.position.y; // Maintain the same height/altitude
            
            // If the duration is set to "instant" (meaning zero duration), then just move the sprite into position
            // and stop the function
            if( durationAsDouble <= 0.0 ) {
                
                sprite.position = ccp( updatedX, updatedY ); // Set new position
                return;
            }
            
            [self createSafeSave]; // Create safe-save before using a move effect on the sprite (safe-saves are always used before effects are run)
            
            // STEP THREE: Make preparations for the "move sprite" effect. Once the actual movement has been completed, then
            //            the action sequence will call 'clearEffectRunningFlag' to let VNLayer know that the effect's done.
            CCMoveTo* moveSprite = [CCMoveTo actionWithDuration:durationAsDouble position:ccp(updatedX, updatedY)];
            CCCallFunc* clearFlagAction = [CCCallFunc actionWithTarget:self selector:@selector(clearEffectRunningFlag)];
            CCSequence* spriteMoveSequence = [CCSequence actions:moveSprite, clearFlagAction, nil];
                    
            // STEP FOUR: Set the "effect running" flag, and then actually perform the CCAction sequence.
            [self setEffectRunningFlag];
            [sprite runAction:spriteMoveSequence];
            
        }break;
            
        // This command just removes a sprite from the screen. It can be done immediately (though suddenly vanishing is kind of
        // jarring for players) or it can gradually fade from sight.
        case VNScriptCommandRemoveSprite: {
            
            NSString* spriteName = parameter1;
            BOOL spriteVanishesImmediately = [[command objectAtIndex:2] boolValue];
            
            // Check if the sprite even exists. If it doesn't, just stop the function
            CCSprite* sprite = [sprites objectForKey:spriteName];
            if( sprite == nil )
                return;
            
            // Remove the sprite from the sprites array. If the game needs be saved soon right after this command
            // is called, then the now-removed sprite won't be included in the save data.
            [sprites removeObjectForKey:spriteName];
            
            // Check if it should just vanish at once (this should probably be done offscreen because it looks weird
            // if it just happens while the player can still see the sprite).
            if( spriteVanishesImmediately == YES ) {
                
                // Remove it from its parent node (if it has one)
                if( sprite.parent != nil )
                    [sprite removeFromParentAndCleanup:NO];
                
            } else {
                
                // If the sprite shouldn't be removed immediately, then it should be moved to an array of "unused" (or soon-to-be-unused)
                // sprites, and then later deleted.
                if( spritesToRemove == nil ) {
                    spritesToRemove = [[NSMutableArray alloc] initWithCapacity:1];
                }
                
                [spritesToRemove addObject:sprite]; // Add to the sprite-removal array; sprite will be removed later by a function
                sprite.tag = VNLayerSpriteIsSafeToRemove; // Mark the sprite as safe-to-delete
                
                // This sequence of CCActions will cause the sprite to fade out, and then it'll be removed from memory.
                CCFadeOut* fadeOutSprite = [CCFadeOut actionWithDuration:spriteTransitionSpeed];
                CCCallFunc* removeSprite = [CCCallFunc actionWithTarget:self selector:@selector(removeUnusedSprites)];
                CCSequence* spriteRemovalSequence = [CCSequence actions:fadeOutSprite, removeSprite, nil];
                [sprite runAction:spriteRemovalSequence];
            }
            
        }break;
            
        // This command moves a sprite by a certain number of points (since Cocos2D uses points instead of pixels). This
        // is really just a "wrapper" of sorts for the CCMoveBy action in Cocos2D.
        case VNScriptCommandEffectMoveSprite: {
            
            [self createSafeSave]; // Create safe-save since VNLayer is about to perform an effect
            
            NSString* spriteName = parameter1;
            NSNumber* moveByX = [command objectAtIndex:2]; // How far to move on X-plane
            NSNumber* moveByY = [command objectAtIndex:3]; // How far to move on Y-plane
            NSNumber* duration = [command objectAtIndex:4]; // How long this whole process takes (default is 0.5 seconds)
            double durationAsDouble = 0.0; // Default duration
            
            if( duration ) {
                durationAsDouble = [duration doubleValue]; // Overwrite default duration if a duration parameter is found
            }

            // Find the sprite! If it exists, of course... if not, just stop the function
            CCSprite* sprite = [sprites objectForKey:spriteName];
            if( sprite == nil ) {
                return;
            }
            
            // Check if this is meant to be done instantly. In that case, instantly move the sprite and stop the function
            if( durationAsDouble <= 0.0 ) {
                
                // Calculate updated sprite position (current position + moveBy values)
                float updatedX = sprite.position.x + [moveByX floatValue];
                float updatedY = sprite.position.y + [moveByY floatValue];
                sprite.position = ccp( updatedX, updatedY );
                return; // Stop the function, since an "immediate movement" command doesn't need to go any further
            }
            
            [self setEffectRunningFlag];
            
            // Set up movement action, and then have the "effect is running" flag get cleared at the end of the sequence
            CGPoint movementAmount = ccp( [moveByX floatValue], [moveByY floatValue] );
            CCMoveBy* moveByAction = [CCMoveBy actionWithDuration:durationAsDouble position:movementAmount];
            CCCallFunc* clearEffectFlag = [CCCallFunc actionWithTarget:self selector:@selector(clearEffectRunningFlag)];
            CCSequence* movementSequence = [CCSequence actions:moveByAction, clearEffectFlag, nil];
            [sprite runAction:movementSequence];
            
        }break;
            
        // Instantly set a sprite's position (this is similar to the "move sprite" command, except this happens instantly).
        // While instant movement can look strange, there are some situations it can be useful.
        case VNScriptCommandSetSpritePosition: {
            
            NSString* spriteName = parameter1;
            float updatedX = [[command objectAtIndex:2] floatValue];
            float updatedY = [[command objectAtIndex:3] floatValue];
            
            // Find the sprite. If it exists, then just change its coordinates. If it doesn't exist... then nothing happens.
            CCSprite* sprite = [sprites objectForKey:spriteName];
            if( sprite ) {
                
                // Instantly reposition sprite
                sprite.position = ccp( updatedX, updatedY );
            }
            
        }break;
            
        // Change the background image. If the name parameter is set to "nil" then this command just removes the background image.
        case VNScriptCommandSetBackground: {
            
            NSString* backgroundName = parameter1;
            
            // Get rid of the old background
            CCSprite* background = (CCSprite*) [self getChildByTag:VNLayerTagBackground];
            [background removeFromParentAndCleanup:NO];
            
            // Also remove background data from records
            [record removeObjectForKey:VNLayerBackgroundToShowKey];
            
            // Check the value of the string. If the string is "nil", then just get rid of any existing background
            // data. Otherwise, VNLayerView will try to use the string as a file name.
            if( [backgroundName caseInsensitiveCompare:VNScriptNilValue] != NSOrderedSame ) {
                
                CCSprite* updatedBackground = [CCSprite spriteWithFile:backgroundName]; // Grab new background image
                updatedBackground.position = ccp( [CCDirector sharedDirector].winSize.width * 0.5,
                                                  [CCDirector sharedDirector].winSize.height * 0.5 );
                updatedBackground.opacity = [[viewSettings objectForKey:VNLayerViewDefaultBackgroundOpacityKey] unsignedCharValue];
                [self addChild:updatedBackground
                             z:VNLayerBackgroundLayer
                           tag:VNLayerTagBackground];
                [record setObject:backgroundName forKey:VNLayerBackgroundToShowKey]; // Update record with the background image's file name
            }
            
        }break;
            
        // Sets the "speaker name," so that the player knows which character is speaking. The name usually appears above and to the
        // left of the actual dialogue text. The value of the speaker name can be set to "nil" to hide the label.
        case VNScriptCommandSetSpeaker: {
            
            NSString* updatedSpeakerName = parameter1;
            
            speaker.opacity = 0; // Make the label invisible so that it can fade in
            speaker.string = @" "; // Default value is to not have any speaker name in the label's text string
            [record removeObjectForKey:VNLayerSpeakerNameToShowKey]; // Remove speaker name from record
            
            // Check if this is a valid name (instead of the 'nil' value)
            if( [updatedSpeakerName caseInsensitiveCompare:VNScriptNilValue] != NSOrderedSame ) {

                // Set new name
                [record setValue:updatedSpeakerName forKey:VNLayerSpeakerNameToShowKey];
                
                speaker.opacity = 0;
                speaker.string = updatedSpeakerName;
                
                // Fade in the speaker name label
                CCFadeIn* fadeIn = [CCFadeIn actionWithDuration:speechTransitionSpeed];
                [speaker runAction:fadeIn];
            }
            
        }break;
            
        // This changes which "conversation" (or array of dialogue) in the script is currently being run.
        case VNScriptCommandChangeConversation: {
            
            NSString* updatedConversationName = parameter1;
            
            // Check if this conversation actually exists
            NSArray* convo = [script.data objectForKey:updatedConversationName];
            if( convo == nil ) {
                NSLog(@"[VNLayer] ERROR: No section titled %@ was found in script!", updatedConversationName);
                return;
            }
            
            // If the conversation actually exists, then just switch to it
            [script changeConversationTo:updatedConversationName];
            script.indexesDone--;
            
        }break;
            
        // This command presents a choice menu to the player, and after the player chooses, then VNLayer switches conversations.
        case VNScriptCommandJumpOnChoice: {
            
            [self createSafeSave]; // Always create a safe-save before doing something volatile
            
            NSArray* choiceTexts = [command objectAtIndex:1]; // Get the strings to display for individual choices
            NSArray* destinations = [command objectAtIndex:2]; // Get the names of the conversations to "jump" to
            int numberOfChoices = [choiceTexts count]; // Calculate number of choices
            
            buttons = [[NSMutableArray alloc] initWithCapacity:numberOfChoices];
            choices = [[NSMutableArray alloc] initWithCapacity:numberOfChoices];
            
            // Come up with some position data
            float screenHeight = [CCDirector sharedDirector].winSize.height;
            float screenWidth = [CCDirector sharedDirector].winSize.width;
            
            // This loop creates the buttons and loads them with information
            for( int i = 0; i < numberOfChoices; i++ ) {
                
                CCSprite* button = [CCSprite spriteWithFile:[viewSettings objectForKey:VNLayerViewButtonFilenameKey]];
                
                // Calculate the amount of space (including space between buttons) that each button will take up, and then
                // figure out where and how to position the buttons (factoring in margins / spaces between buttons). Generally,
                // the button in the middle of the menu of choices will show up in the middle of the screen with this formula.
                float spaceBetweenButtons = button.boundingBox.size.height * 0.2;
                float buttonHeight = button.boundingBox.size.height;
                float totalButtonSpace = buttonHeight + spaceBetweenButtons;
                float startingPosition = (screenHeight * 0.5) + ( ( numberOfChoices / 2 ) * totalButtonSpace );
                float buttonY = startingPosition + ( i * totalButtonSpace );
                
                // Set button position
                button.position = ccp( screenWidth * 0.5, buttonY );
                [self addChild:button z:VNLayerButtonsLayer tag:i];
                button.tag = i; // Just to be sure!
                button.color = buttonUntouchedColors; // Black by default
				[buttons addObject:button]; // Add button to array
                
                // Determine where the text should be positioned inside the button
                CGPoint labelWithinButtonPos = ccp( button.boundingBox.size.width * 0.5, button.boundingBox.size.height * 0.35 );
                if( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ) {
                    
                    // The position of the text inside the button has to be adjusted, since the actual font size on the iPad isn't exactly
                    // twice as large, but modified with some custom code. This results in having to do some custom positioning as well!
                    labelWithinButtonPos.y = button.boundingBox.size.height * 0.31;
                }
                
                // Create the button label
                CCLabelTTF* buttonLabel = [CCLabelTTF labelWithString:[choiceTexts objectAtIndex:i]
                                                             fontName:[viewSettings objectForKey:VNLayerViewFontNameKey]
                                                             fontSize:[[viewSettings objectForKey:VNLayerViewFontSizeKey] floatValue]
                                                           dimensions:[button boundingBox].size
                                                           hAlignment:UITextAlignmentCenter
                                                        lineBreakMode:UILineBreakModeWordWrap];
                buttonLabel.position = labelWithinButtonPos;
                [button addChild:buttonLabel z:VNLayerButtonTextLayer];
                
                // Add destionation/conversation data to the 'choices' array
                [choices addObject:[destinations objectAtIndex:i]];
            }
            
            // Change VNLayer's mode so that it knows to handle these choices
            mode = VNLayerModeChoiceWithJump;
            
        }break;
            
        // This command will show (or hide) the speech box (the little box where all the speech/dialogue text is shown).
        // Hiding it is useful in case you want the player to just enjoy the background art.
        case VNScriptCommandShowSpeechOrNot: {
            
            BOOL showSpeechOrNot = [parameter1 boolValue];
            [record setValue:parameter1 forKey:VNLayerShowSpeechKey];
            
            if( speechBox == nil ) {
                NSLog(@"[VNLayer] ERROR: No speech box found in VN module.");
                return;
            }
            
            // Case 1: DO show the speech box
            if( showSpeechOrNot == YES ) {
                
                [speechBox stopAllActions];
                [speech stopAllActions];
                    
                CCFadeIn* fadeInSpeechBox = [CCFadeIn actionWithDuration:speechTransitionSpeed];
                [speechBox runAction:fadeInSpeechBox];
                
                if( speech ) {
                    CCFadeIn* fadeInText = [CCFadeIn actionWithDuration:speechTransitionSpeed];
                    [speech runAction:fadeInText];
                }
                
            // Case 2: DON'T show the speech box.
            } else {
                
                [speech stopAllActions];
                [speechBox stopAllActions];
            
                CCFadeOut* fadeOutBox = [CCFadeOut actionWithDuration:speechTransitionSpeed];
                [speechBox runAction:fadeOutBox];
                
                if( speech )  {
                    [speech stopAllActions];
                    CCFadeOut* fadeOutText = [CCFadeOut actionWithDuration:speechTransitionSpeed];
                    [speech runAction:fadeOutText];
                }
            }
            
        }break;
            
        // This command causes the background image and character sprites to "fade in" (go from being fully transparent to being
        // opaque).
        //
        // Note that if you want a fade-to-black (or rather, fade-FROM-black) effect, it helps if this CCLayer is being run in
        // its own CCScene. If the layer has just been added on to an existing CCScene/CCLayer, then hopefully there's a big
        // black image behind it or something.
        case VNScriptCommandEffectFadeIn: {
            
            NSNumber* duration = parameter1;
            [self createSafeSave];
            [self setEffectRunningFlag];
            double durationAsDouble = [duration doubleValue];
            
            // Check if there's any character sprites in existence. If there are, they all need to have a CCFadeIn action
            // applied to each and every one.
            if( sprites ) {
                for( CCSprite* tempSprite in [sprites allValues] ){
                    CCFadeIn* fadeIn = [CCFadeIn actionWithDuration:durationAsDouble];
                    [tempSprite runAction:fadeIn];
                }
            }
            
            // Check if there's a background. If there is, it also needs to have a CCFadeIn action applied to it.
            CCSprite* background = (CCSprite*) [self getChildByTag:VNLayerTagBackground];
            if( background ) {
                
                CCFadeIn* fadeIn = [CCFadeIn actionWithDuration:durationAsDouble];
                [background runAction:fadeIn];
            }
        
            // Since the upcoming CCSequence runs at the same time that the prior CCFadeIn actions are run, the first thing
            // put into the sequence is a delay action, so that the "function call" action gets run immediately after the
            // fade-in actions finish.
            CCDelayTime* delay = [CCDelayTime actionWithDuration:durationAsDouble];
            CCCallFunc* callFunc = [CCCallFunc actionWithTarget:self selector:@selector(clearEffectRunningFlag)];
            CCSequence* delayedClearSequence = [CCSequence actions:delay, callFunc, nil];
            
            [self runAction:delayedClearSequence];
            
            // Finally, update the view settings with the "fully faded-in" value for the background's opacity
            [viewSettings setValue:[NSNumber numberWithUnsignedChar:255] forKey:VNLayerViewDefaultBackgroundOpacityKey];
            
        }break;
            
        // This is similar to the above command, except that it causes the character sprites and background to go from being
        // fully opaque to fully transparent (or "fade out").
        case VNScriptCommandEffectFadeOut: {
            
            NSNumber* duration = parameter1;
            [self createSafeSave];
            [self setEffectRunningFlag];
            double durationAsDouble = [duration doubleValue];
            
            // Check if there are any sprites and cause them to become fully transparent over a period of time
            // (by default that "period of time" is about 0.5 seconds)
            if( sprites ) {
                for( CCSprite* tempSprite in [sprites allValues] ){
                    CCFadeOut* fadeOut = [CCFadeOut actionWithDuration:durationAsDouble];
                    [tempSprite runAction:fadeOut];
                }
            }
            
            CCSprite* background = (CCSprite*) [self getChildByTag:VNLayerTagBackground];
            if( background ) {
                
                CCFadeOut* fadeOut = [CCFadeOut actionWithDuration:durationAsDouble];
                [background runAction:fadeOut];
                
            }
            
            CCDelayTime* delay = [CCDelayTime actionWithDuration:durationAsDouble];
            CCCallFunc* callFunc = [CCCallFunc actionWithTarget:self selector:@selector(clearEffectRunningFlag)];
            CCSequence* delayedClearSequence = [CCSequence actions:delay, callFunc, nil];
            
            [self runAction:delayedClearSequence];
            [viewSettings setValue:[NSNumber numberWithUnsignedChar:0] forKey:VNLayerViewDefaultBackgroundOpacityKey];
            
        }break;
            
        // This just plays a sound. I had actually thought about creating some kind of system to keep track of all
        // the sounds loaded, and then to manually remove them from memory once they were no longer being used,
        // but I've never gotten around to implementing it.
        case VNScriptCommandPlaySound: {
            
            NSString* soundName = parameter1;
        
            [[SimpleAudioEngine sharedEngine] playEffect:soundName];
    
        }break;
            
        // This plays music (an MP3 file is good, though you may try AAC since iOS devices supposedly have built-in
        // hardware-decoding for them, or CAF since they have small filesizes and small memory footprints). You can only
        // play one music file at a time. You can choose whether it loops infinitely, or if it just plays once.
        //
        // If you want to STOP music from playing, you can also pass "nil" as the filename (parameter #1) to cause
        // VNLayer to stop all music.
        case VNScriptCommandPlayMusic: {
            
            NSString* musicName = parameter1;
            NSNumber* musicShouldLoop = [command objectAtIndex:2];
            
            // Check if the value is 'nil', meaning that no music should be played
            if( [musicName caseInsensitiveCompare:VNScriptNilValue] == NSOrderedSame ) {
                
                isPlayingMusic = NO;
                [record removeObjectForKey:VNLayerMusicToPlayKey]; // Remove music data from saved-game record
                [record removeObjectForKey:VNLayerMusicShouldLoopKey];
                [[SimpleAudioEngine sharedEngine] stopBackgroundMusic];
                
            } else {
            
                isPlayingMusic = YES;
                [record setValue:musicName forKey:VNLayerMusicToPlayKey]; // Store music data in dictionary
                [record setValue:musicShouldLoop forKey:VNLayerMusicShouldLoopKey];
                [[SimpleAudioEngine sharedEngine] playBackgroundMusic:musicName loop:[musicShouldLoop boolValue]];
            }
                        
        }break;
            
        // This command sets a variable (or "flag"), which is usually an "int" value stored in an NSNumber object by a dictionary.
        // VNLayer stores a local dictionary, and whenever the game is saved, the contents of that dictionary are copied over to
        // EKRecord's own flags dictionary (and stored in device memory).
        case VNScriptCommandSetFlag: {
            
            NSString* flagName = parameter1;
            id flagValue = [command objectAtIndex:2];
            
            CCLOG(@"[VNLayer] Setting flag named [%@] to a value of [%@]", flagName, flagValue);
            
            // Store the new value in the local dictionary
            [flags setValue:flagValue forKey:flagName];
            
        }break;
            
        // This modifies an existing flag's integer value by a certain amount (you might have guessed: a positive value "adds",
        // while a negative "subtracts). If no flag actually exists, then a new flag is created with whatever value was passed in.
        case VNScriptCommandModifyFlagValue: {
            
            NSString* flagName = parameter1;
            int modifyWithValue = [[command objectAtIndex:2] intValue];
            
            // Check if the flag even exists
            id originalObject = [flags objectForKey:flagName];
            if( originalObject == nil ) {
                
                // Store the "modifier" value as a brand-new flag in the flags dictionary and then quit the function
                [flags setValue:@(modifyWithValue) forKey:flagName];
                return;
            }
            
            // Handle the modification operation
            int originalValue = [originalObject intValue]; // Get original value
            int modifiedValue = originalValue + modifyWithValue; // Create new version
            NSNumber* updatedValue = @(modifiedValue);
            
            // Replace the old version with the new, modified version
            [flags setValue:updatedValue forKey:flagName];
            
        }break;
            
        // This checks if a particular flag has a certain value. If it does, then it executes ANOTHER command (which starts
        // at the third parameter and continues to whatever comes afterwards).
        case VNScriptCommandIfFlagHasValue: {
            
            NSString* flagName = parameter1;
            int expectedValue = [[command objectAtIndex:2] intValue];
            NSArray* secondaryCommand = [command objectAtIndex:3]; // Secondary command, which runs if the actual and expected values are the same
            
            // Check if the variable even exists in the first place. If not, then this command just terminates.
            id theFlag = [flags objectForKey:flagName];
            if( theFlag == nil )
                return;
            
            // Check if the actual value doesn't matches the expected value
            int actualValue = [theFlag intValue];
            if( actualValue != expectedValue )
                return; // Terminate command if the value is different
            
            // If this point has been reached, then it's time to run the second command
            [self processCommand:secondaryCommand];
            script.currentIndex--; // This makes sure that things don't get knocked out of order by the "secondary command"
            
        }break;
            
        // This command presents the user with a choice menu. When the user makes a choice, it results in the value of a flag
        // being modified by a certain amount (just like if the .MODIFYFLAG command had been used).
        case VNScriptCommandModifyFlagOnChoice: {
            
            // Create "safe" autosave before doing something as volatile as presenting a choice menu
            [self createSafeSave];
            
            NSArray* choiceTexts    = parameter1;
            NSArray* variableNames  = [command objectAtIndex:2];
            NSArray* variableValues = [command objectAtIndex:3];
            int numberOfChoices     = [choiceTexts count];
            
            buttons         = [[NSMutableArray alloc] initWithCapacity:numberOfChoices]; // Holds CCSprite objects for individual menu buttons
            choices         = [[NSMutableArray alloc] initWithCapacity:numberOfChoices]; // The names of variables to modify
            choiceExtras    = [[NSMutableArray alloc] initWithCapacity:numberOfChoices]; // How much to modify the variables by
            
            float screenHeight  = [CCDirector sharedDirector].winSize.height;
            float screenWidth   = [CCDirector sharedDirector].winSize.width;
            
            // The following loop creates the buttons (and their label "child nodes") and adds them to an array. It also
            // loads the flag modification data into their own arrays.
            for( int i = 0; i < numberOfChoices; i++ ) {
                
                // Create a 'button' sprite using a filename stored in view settings
                CCSprite* button = [CCSprite spriteWithFile:[viewSettings objectForKey:VNLayerViewButtonFilenameKey]];
                
                // Calculate the amount of space (including space between buttons) that each button will take up, and then
                // figure out the position of the button that's being made. Ideally, the middle of the choice menu will also be the middle
                // of the screen. Of course, if you have a LOT of choices, there may be more buttons than there is space to put them!
                float spaceBetweenButtons   = button.boundingBox.size.height * 0.2; // 20% of button sprite height
                float buttonHeight          = button.boundingBox.size.height;
                float totalButtonSpace      = buttonHeight + spaceBetweenButtons; // total used-up space = 120% of button height
                float startingPosition      = (screenHeight * 0.5) + ( ( numberOfChoices * 0.5 ) * totalButtonSpace );
                float buttonY               = startingPosition + ( i * totalButtonSpace ); // This button's position
                
                // Set button position and other attributes
                button.position     = ccp( screenWidth * 0.5, buttonY );
                button.tag          = i; // Just to be sure! Remember, the 'tag' is actually used to determine which button was pressed.
                button.color        = buttonUntouchedColors;
                
                // Add the button to the layer (and also to the 'buttons' array)
                [self addChild:button z:VNLayerButtonsLayer tag:i];
				[buttons addObject:button];
                
                // Determine where the text should be positioned inside the button
                CGPoint labelWithinButtonPos = ccp( button.boundingBox.size.width * 0.5, button.boundingBox.size.height * 0.35 );
                if( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ) {
                    labelWithinButtonPos.y = button.boundingBox.size.height * 0.31;
                }
                
                // Create button label, set the position of the text, and add this label to the main 'button' sprite
                CCLabelTTF* buttonLabel = [CCLabelTTF labelWithString:[choiceTexts objectAtIndex:i]
                                                             fontName:[viewSettings objectForKey:VNLayerViewFontNameKey]
                                                             fontSize:[[viewSettings objectForKey:VNLayerViewFontSizeKey] floatValue]
                                                           dimensions:[button boundingBox].size
                                                           hAlignment:UITextAlignmentCenter
                                                        lineBreakMode:UILineBreakModeWordWrap];
                buttonLabel.position = labelWithinButtonPos;
                [button addChild:buttonLabel z:VNLayerButtonTextLayer];
                
                // Set up choices
                [choices addObject:[variableNames objectAtIndex:i]];
                [choiceExtras addObject:[variableValues objectAtIndex:i]];
            }
            
            // Activate the new mode
            mode = VNLayerModeChoiceWithFlag;
    
        }break;
            
        // This command will cause VNLayer to switch conversations if a certain flag holds a particular value.
        case VNScriptCommandJumpOnFlag: {
            
            NSString* flagName = parameter1;
            int expectedValue = [[command objectAtIndex:2] intValue];
            NSString* targetedConversation = [command objectAtIndex:3];
            
            // Check if the variable even exists in the first place
            id theFlag = [flags objectForKey:flagName];
            if( theFlag == nil )
                return;
            
            // Check if the actual value doesn't matches the expected value
            int actualValue = [theFlag intValue];
            if( actualValue != expectedValue )
                return;
            
            // Check if this conversation actually exists
            NSArray* convo = [script.data objectForKey:targetedConversation];
            if( convo == nil ) {
                NSLog(@"ERROR: No section titled %@ was found in script!", targetedConversation);
                return;
            }
            
            // If this point has been reached, then it's time to switch to the new 'conversation' in the script
            [script changeConversationTo:targetedConversation];
            script.indexesDone--;
            
        }break;
            
        // This command is used in conjuction with the VNSystemCall class, and is used to create certain game-specific effects.
        case VNScriptCommandSystemCall: {
            
            NSMutableArray* systemCallArray = [NSMutableArray arrayWithArray:command];
            [systemCallArray removeObjectAtIndex:0]; // Remove the ".systemcall" part of the command
            
            // Lazy-load the system call class if it doesn't already exist.
            if( systemCallHelper == nil ) {
                systemCallHelper = [[VNSystemCall alloc] init];
            }
            
            // Since the first part of the command has been removed from the array, VNSystemCall will only process the parameters.
            [systemCallHelper sendCall:systemCallArray];
                
        }break;
            
        // This command calls actual code used by the game. Keep in mind that it's limited to classes that VNLayer knows about,
        // so make sure to include the header file for that class if you want VNLayer to be able to access it this way. Also,
        // this really only works if the class is being accessed through a static function (or "class function," if you prefer),
        // since this command can't access instance variables directly.
        case VNScriptCommandCallCode: {
            
            NSArray* callingArray = [command objectAtIndex:1];
            NSString* className = [callingArray objectAtIndex:0];
            NSString* staticFunctionString = [callingArray objectAtIndex:1];
            Class nameOfClass = NSClassFromString( className );
            
            // Checks if the class could not be loaded
            if( nameOfClass == nil )
                return;
            
            // Check if there are no function parameters
            if( callingArray.count == 2 ) {
                
                SEL method = NSSelectorFromString( staticFunctionString );
                if( method == 0 )
                    return;
                
                if( [nameOfClass respondsToSelector:method] )
                    [nameOfClass performSelector:method]; // Xcode likes to give a warning about this; just ignore
                //objc_msgSend( nameOfClass, staticFunctionSelector );
                
            } else if( callingArray.count == 3 ) {
                
                // Need to create a new string that has a colon attached to the end, since colons cannot normally
                // be inserted into the VN script without causing serious problems.
                NSString* functionStringToUse = [NSString stringWithFormat:@"%@:", staticFunctionString];
                SEL method = NSSelectorFromString( functionStringToUse );
                if( method == 0 )
                    return;
                
                if( [nameOfClass respondsToSelector:method] )
                    [nameOfClass performSelector:method withObject:[callingArray objectAtIndex:2]]; // Another Xcode warning; I ignored it.
            }
            
            
        }break;
            
            
        default:
        {
            NSLog(@"[VNLayer] WARNING: Unknown command found in script. The command's NSArray is: %@", command);
        }break;
    }
}


@end