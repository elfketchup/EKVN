//
//  VNTestScene.m
//
//  Created by James Briones on 8/30/12.
//  Copyright 2012. All rights reserved.
//

#import "VNTestScene.h"
#import "VNScene.h"
#import "EKRecord.h"
#import "OALSimpleAudio.h"

// Some Z-values, so that Cocos2D knows where to position things on the Z-coordinate (and which nodes will
// be drawn on top of which other nodes!)
#define VNTestSceneZForBackgroundImage      10
#define VNTestSceneZForLabelBG              19
#define VNTestSceneZForLabels               20
#define VNTestSceneZForTitle                30

#define VNTestSceneDefaultSupportLinkString @"http://www.google.com"

@implementation VNTestScene

+ (id)scene
{
    return [[self alloc] init];
}

#pragma mark - UI

// This loads the user interface for the title menu. Default view settings are first loaded into a dictionary,
// and then custom settings are loaded from a file (assuming file the exists, of course!). After that, the actual
// CCSprite / CCLabelTTF objects are created from that information.
- (void)loadUI
{
    // Knowing the screen size is important for positioning UI elements
    CGSize screenSize = [CCDirector sharedDirector].viewSize;
    
    // Load the default settings first
    NSMutableDictionary* standardSettings = [NSMutableDictionary dictionaryWithDictionary:[self loadDefaultUI]];
    NSDictionary* customSettings = nil;
    
    // Now try to load the custom settings that are stored in a file
    NSString* dictionaryFilePath = [[NSBundle mainBundle] pathForResource:@"main_menu" ofType:@"plist"];
    if( dictionaryFilePath ) {
        
        // Custom settings are loaded from that Property List file
        customSettings = [[NSDictionary alloc] initWithContentsOfFile:dictionaryFilePath];
        
        // Check if the loading was successful AND if there's any actual data stored in the file
        if( customSettings && customSettings.count > 0 ) {
            
            // Overwrite default settings with custom ones from the file
            [standardSettings addEntriesFromDictionary:customSettings];
            NSLog(@"[VNTestScene] UI settings have been loaded from file.");
        }
    }
    
    // Check if no custom settings could be loaded. if this is the case, just log it for diagnostics purposes
    if( customSettings == nil ) {
        NSLog(@"[VNTestScene] UI settings could not be loaded from a file.");
    }
    
    // For the "Start New Game" button, get the values from the dictionary
    float startLabelX = [standardSettings[VNTestSceneStartNewGameLabelX] floatValue];
    float startLabelY = [standardSettings[VNTestSceneStartNewGameLabelY] floatValue];
    float startFontSize = [standardSettings[VNTestSceneStartNewGameSize] floatValue];
    NSString* startText = standardSettings[VNTestSceneStartNewGameText];
    NSString* startFont = standardSettings[VNTestSceneStartNewGameFont];
    NSDictionary* startColors = standardSettings[VNTestSceneStartNewGameColorDict];
    
    // fill in missing data
    if( startText == nil )
        startText = @" ";
    
    // Now create the actual label
    playLabel = [CCLabelTTF labelWithString:startText fontName:startFont fontSize:startFontSize];
    playLabel.position = CGPointMake( screenSize.width * startLabelX, screenSize.height * startLabelY );
    ccColor3B playLabelColor = ccc3( [startColors[@"r"] unsignedCharValue],
                                    [startColors[@"g"] unsignedCharValue],
                                    [startColors[@"b"] unsignedCharValue] );
    playLabel.color = [[CCColor alloc] initWithCcColor3b:playLabelColor];
    [self addChild:playLabel z:VNTestSceneZForLabels];
    
    // Now grab the values for the Continue button
    float continueLabelX = [standardSettings[VNTestSceneContinueLabelX] floatValue];
    float continueLabelY = [standardSettings[VNTestSceneContinueLabelY] floatValue];
    float continueFontSize = [standardSettings[VNTestSceneContinueSize] floatValue];
    NSString* continueText = standardSettings[VNTestSceneContinueText];
    NSString* continueFont = standardSettings[VNTestSceneContinueFont];
    NSDictionary* continueColors = standardSettings[VNTestSceneContinueColor];
    
    if( continueText == nil )
        continueText = @" ";
    
    // Load the "Continue" label
    loadLabel = [CCLabelTTF labelWithString:continueText fontName:continueFont fontSize:continueFontSize];
    loadLabel.position = CGPointMake( screenSize.width * continueLabelX, screenSize.height * continueLabelY );
    ccColor3B loadLabelColor  = ccc3( [continueColors[@"r"] unsignedCharValue],
                                      [continueColors[@"g"] unsignedCharValue],
                                      [continueColors[@"b"] unsignedCharValue] );
    loadLabel.color = [[CCColor alloc] initWithCcColor3b:loadLabelColor];
    [self addChild:loadLabel z:VNTestSceneZForLabels];
    
    // Now grab the values for the Support button
    float supportLabelX = [standardSettings[VNTestSceneSupportLabelX] floatValue];
    float supportLabelY = [standardSettings[VNTestSceneSupportLabelY] floatValue];
    float supportFontSize = [standardSettings[VNTestSceneSupportSize] floatValue];
    NSString* supportText = standardSettings[VNTestSceneSupportText];
    NSString* supportFont = standardSettings[VNTestSceneSupportFont];
    NSDictionary* supportColors = standardSettings[VNTestSceneSupportColor];
    
    if( supportText == nil )
        supportText = @" ";
    
    // Load the "Support" label
    supportLabel = [CCLabelTTF labelWithString:supportText fontName:supportFont fontSize:supportFontSize];
    supportLabel.position = CGPointMake( screenSize.width * supportLabelX, screenSize.height * supportLabelY );
    ccColor3B supportLabelColor  = ccc3( [supportColors[@"r"] unsignedCharValue],
                                        [supportColors[@"g"] unsignedCharValue],
                                        [supportColors[@"b"] unsignedCharValue] );
    supportLabel.color = [[CCColor alloc] initWithCcColor3b:supportLabelColor];
    [self addChild:supportLabel z:VNTestSceneZForLabels];
    
    // Load the title info
    float titleX = [standardSettings[VNTestSceneTitleX] floatValue];
    float titleY = [standardSettings[VNTestSceneTitleY] floatValue];
    title = [CCSprite spriteWithImageNamed:standardSettings[VNTestSceneTitleImage]];
    title.position = CGPointMake( screenSize.width * titleX, screenSize.height * titleY );
    [self addChild:title z:VNTestSceneZForTitle];
    
    /*
     // testing scaling issues
    NSLog(@"title size: w=%f | h=%f", title.boundingBox.size.width, title.boundingBox.size.height);
    title.scaleX = 1.5;
    title.scaleY = 1.8;
    CCSprite* spriteFromTexture = [CCSprite spriteWithTexture:title.texture];
    NSLog(@"title size: w=%f | h=%f", title.boundingBox.size.width, title.boundingBox.size.height);
    NSLog(@"spriteFromTexture size: w=%f | h=%f", spriteFromTexture.boundingBox.size.width, spriteFromTexture.boundingBox.size.height);
     */
    
    // Set up background data
    backgroundImage = [CCSprite spriteWithImageNamed:standardSettings[VNTestSceneBackgroundImage]];
    backgroundImage.position = CGPointMake( screenSize.width * 0.5, screenSize.height * 0.5 );
    [self addChild:backgroundImage z:VNTestSceneZForBackgroundImage];
    
    // Grab script name information
    nameOfScript = standardSettings[VNTestSceneScriptToLoad];
    
    // The music data is loaded last since it looks weird if music is playing but nothing has shown up on the screen yet.
    NSString* musicFilename = standardSettings[VNTestSceneMenuMusic];
    // Make sure the music isn't set to 'nil'
    if( [musicFilename caseInsensitiveCompare:@"nil"] != NSOrderedSame ) {
        
        isPlayingMusic = YES;
        [[OALSimpleAudio sharedInstance] playBg:musicFilename loop:true];
    }
    
    // Load fade-out data
    NSNumber* fadeOutTimeNumber = [standardSettings objectForKey:VNTestSceneFadeOutTimeInSeconds];
    if( fadeOutTimeNumber != nil ) {
        
        double multiplier = (double) VNTestSceneAssumedFPS;
        double fadeOutTimeInSeconds = [fadeOutTimeNumber doubleValue] * multiplier;
        
        totalFadeTime = (int)fadeOutTimeInSeconds;
    }
    
    // Load optional background images for main menu labels
    NSString* valueForContinueBGImage = [standardSettings objectForKey:VNTestSceneContinueBGImage];
    NSString* valueForStartBGImage = [standardSettings objectForKey:VNTestSceneStartNewGameBGImage];
    NSString* valueForSupportBGImage = [standardSettings objectForKey:VNTestSceneSupportBGImage];
    
    if( valueForContinueBGImage != nil && valueForContinueBGImage.length > 1 ) {
        loadLabelBG = [CCSprite spriteWithImageNamed:valueForContinueBGImage];
        loadLabelBG.position = loadLabel.position;
        [self addChild:loadLabelBG z:(loadLabel.zOrder - 1)];
    }
    
    if( valueForStartBGImage != nil && valueForStartBGImage.length > 1 ) {
        // "playLabel" is the name of the CCSpriteTTF object that stores text data for "New Game"
        playLabelBG = [CCSprite spriteWithImageNamed:valueForStartBGImage];
        playLabelBG.position = playLabel.position;
        [self addChild:playLabelBG z:(playLabel.zOrder - 1)];
    }
    
    if( valueForSupportBGImage != nil && valueForSupportBGImage.length > 1 ) {
        supportLabelBG = [CCSprite spriteWithImageNamed:valueForSupportBGImage];
        supportLabelBG.position = supportLabel.position;
        [self addChild:supportLabelBG z:(supportLabel.zOrder - 1)];
    }
    
    // Load audio data
    NSString* newGameSound = [standardSettings objectForKey:VNTestSceneStartNewGameSound];
    NSString* loadGameSound = [standardSettings objectForKey:VNTestSceneContinueSound];
    
    if( newGameSound != nil && newGameSound.length > 1 ) {
        filenameOfSoundForStartButton = newGameSound.copy;
    }
    
    if( loadGameSound != nil && loadGameSound.length > 1 ) {
        filenameOfSoundForContinueButton = loadGameSound.copy;
    }
    
    // Load link data for support label
    supportLabelLink = [standardSettings objectForKey:VNTestSceneSupportLinkString];
    if( supportLabelLink == nil ) {
        supportLabelLink = @"http://www.google.com"; // default
    }
}

// This creates a dictionary that's got the default UI values loaded onto them. If you want to change how it looks,
// you should open up "main_menu.plist" and set your own custom values for things there.
- (NSDictionary*)loadDefaultUI
{
    NSMutableDictionary* resourcesDict = [NSMutableDictionary dictionaryWithCapacity:13];
    NSDictionary* whiteColorDict = @{ @"r" : @(255),
                                      @"g" : @(255),
                                      @"b" : @(255) };
    
    // Create settings for the "start new game" button
    [resourcesDict setObject:@(0.5) forKey:VNTestSceneStartNewGameLabelX];
    [resourcesDict setObject:@(0.3) forKey:VNTestSceneStartNewGameLabelY];
    [resourcesDict setObject:@"Helvetica" forKey:VNTestSceneStartNewGameFont];
    [resourcesDict setObject:@(18) forKey:VNTestSceneStartNewGameSize];
    [resourcesDict setObject:[whiteColorDict copy] forKey:VNTestSceneStartNewGameColorDict];
    
    // Create settings for "continue" button
    [resourcesDict setObject:@(0.5) forKey:VNTestSceneContinueLabelX];
    [resourcesDict setObject:@(0.2) forKey:VNTestSceneContinueLabelY];
    [resourcesDict setObject:@"Helvetica" forKey:VNTestSceneContinueFont];
    [resourcesDict setObject:@(18) forKey:VNTestSceneContinueSize];
    [resourcesDict setObject:[whiteColorDict copy] forKey:VNTestSceneContinueColor];
    
    // set up support label
    [resourcesDict setObject:@(0.5) forKey:VNTestSceneSupportLabelX];
    [resourcesDict setObject:@(0.15) forKey:VNTestSceneSupportLabelY];
    [resourcesDict setObject:@"Helvetica" forKey:VNTestSceneSupportFont];
    [resourcesDict setObject:@(18) forKey:VNTestSceneSupportSize];
    [resourcesDict setObject:[whiteColorDict copy] forKey:VNTestSceneSupportColor];
    [resourcesDict setObject:VNTestSceneDefaultSupportLinkString forKey:VNTestSceneSupportLinkString];
    
    // Set up title data
    [resourcesDict setObject:@(0.5) forKey:VNTestSceneTitleX];
    [resourcesDict setObject:@(0.75) forKey:VNTestSceneTitleY];
    [resourcesDict setObject:@"title.png" forKey:VNTestSceneTitleImage];
    
    // Set up background image
    [resourcesDict setObject:@"skyspace.png" forKey:VNTestSceneBackgroundImage];
    
    // Set up script data
    [resourcesDict setObject:@"demo script" forKey:VNTestSceneScriptToLoad];
    
    // Set default music data
    [resourcesDict setObject:@"nil" forKey:VNTestSceneMenuMusic];
    
    return [NSDictionary dictionaryWithDictionary:resourcesDict];
}

#pragma mak - Game starting and loading

- (void)startNewGame
{
    // Create a blank dictionary with no real data, except for the name of which script file to load.
    // You can pass this in to VNLayer with nothing but that information, and it will load a new game
    // (or at least, a new VNLayer scene!)
    //NSMutableDictionary* tempDict = [NSMutableDictionary dictionary];
    //[tempDict setObject:nameOfScript forKey:VNLayerToPlayKey];
    
    NSDictionary* settingsForScene = @{ VNSceneToPlayKey: nameOfScript};
    
    // Create an all-new scene and add VNLayer to it
    //[[CCDirector sharedDirector] pushScene:[VNLayer sceneWithSettings:tempDict]];

    [[CCDirector sharedDirector] pushScene:[VNScene sceneWithSettings:settingsForScene]];
}

- (void)loadSavedGame
{
    if( [[EKRecord sharedRecord] hasAnySavedData] == NO ) {
        NSLog(@"[VNTestScene] ERROR: No saved data, cannot continue game!");
        return;
    }
    
    // The following's not very pretty, but it is pretty useful...
    CCLOG(@"[VNTestScene] For diagnostics purporses, here's a flag dump from EKRecord:\n   %@", [[EKRecord sharedRecord] flags] );
    
    // Load saved-game records from EKRecord. The activity dictionary holds data about what the last thing the user was doing
    // (presumably, watching a scene), how far the player got, relevent data that needs to be reloaded, etc.
    NSDictionary* activityRecords = [[EKRecord sharedRecord] activityDict];
    NSString* lastActivity = [activityRecords objectForKey:EKRecordActivityTypeKey];
    if( lastActivity == nil ) {
        NSLog(@"[VNTestScene] ERROR: No previous activity found. No saved game can be loaded.");
        return;
    }
    
    NSDictionary* savedData = [activityRecords objectForKey:EKRecordActivityDataKey];
    CCLOG(@"[VNTestScene] Saved data is %@", savedData);
    
    // Unlike when the player is starting a new game, the name of the script to load doesn't have to be passed.
    // It should already be stored within the Activity Records from EKRecord.
    [[CCDirector sharedDirector] pushScene:[VNScene sceneWithSettings:savedData]];
}

- (void)openSupportLink
{
    NSURL* supportURL = [NSURL URLWithString:supportLabelLink];
    [[UIApplication sharedApplication] openURL:supportURL];
}

#pragma mark - Touch controls

- (void)touchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    // There's not really anything going on in this function, but if this fucntion isn't implemented, then
    // any input in this class won't be recognized by Cocos2D v3. Thus, this function has been "implemented,"
    // just so that Cocos2D will pay attention to all the "real" action going on in the touchEnded function.
}

- (void)stopMenuMusic
{
    if( isPlayingMusic ) {
        [[OALSimpleAudio sharedInstance] stopBg];
    }
    
    isPlayingMusic = NO;
}

//- (void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
- (void)touchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint touchPos = [touch locationInNode:self];
    
    bool didTouchSupport = false;
    bool didTouchLoad = false;
    bool didTouchStart = false;
    
    // Check if the user tapped on the labels
    if( playLabel != nil ) {
        didTouchStart = CGRectContainsPoint(playLabel.boundingBox, touchPos);
    }
    if( loadLabel != nil ) {
        didTouchLoad = CGRectContainsPoint(loadLabel.boundingBox, touchPos);
    }
    if( supportLabel ) {
        didTouchSupport = CGRectContainsPoint(supportLabel.boundingBox, touchPos);
    }
    
    // Check if the user tapped on the background images behind the labels (but only if the matching flags remain "false")
    if( playLabelBG != nil && didTouchStart == false ) {
        didTouchStart = CGRectContainsPoint(playLabelBG.boundingBox, touchPos);
    }
    if( loadLabelBG != nil && didTouchLoad == false ) {
        didTouchLoad = CGRectContainsPoint(loadLabelBG.boundingBox, touchPos);
    }
    if( supportLabelBG != nil && didTouchSupport == false ) {
        didTouchSupport = CGRectContainsPoint(supportLabelBG.boundingBox, touchPos);
    }
    
    
    if( didTouchSupport == true ) {
        [self openSupportLink];
    }
    
    // Check if the user tapped on the "play" label
    if( didTouchStart == true ) {
        
        if( filenameOfSoundForStartButton != nil ) {
            [[OALSimpleAudio sharedInstance] playEffect:filenameOfSoundForStartButton];
        }
        
        if( totalFadeTime < 1 ) {
            [self stopMenuMusic];
            [self startNewGame];
        } else {
            actionToTakeAfterFade = VNTestSceneActionWillStartNewGame;
            [self beginFading];
        }
    }
    
    // Check if the user tapped on the "contine" / "load saved game" label
    if( didTouchLoad == true ) {
        
        if( filenameOfSoundForContinueButton != nil )  {
            [[OALSimpleAudio sharedInstance] playEffect:filenameOfSoundForContinueButton];
        }
        
        // Loading the game is only possible if the label is fully opaque. And it will only be fully
        // opaque if previous save game data has been found.
        if( loadLabel.opacity > 0.98 ) {
            if (totalFadeTime < 1 ) {
                [self stopMenuMusic];
                [self loadSavedGame];
            } else {
                actionToTakeAfterFade = VNTestSceneActionWillLoadSavedGame;
                [self beginFading];
            }
        }
    }
}

// MARK: Init

- (id)init
{
    if( self = [super init] ) {
        
        BOOL previousSaveData = [[EKRecord sharedRecord] hasAnySavedData];
        isPlayingMusic = NO;
        
        // set default data
        playLabelBG = nil;
        loadLabelBG = nil;
        fadingProcessBegan = NO;
        totalFadeTime = 0;
        fadeTimer = 0;
        actionToTakeAfterFade = 0;
        originalVolumeOfMusic = [[OALSimpleAudio sharedInstance] bgVolume];
        filenameOfSoundForContinueButton = nil;
        filenameOfSoundForStartButton = nil;
        
        [self loadUI];
        
        // If there's no previous data, then the "Continue" / "Load Game" label will be partially transparent.
        if( previousSaveData == NO )
            loadLabel.opacity = 0.5;
        else
            loadLabel.opacity = 1.0;
        
        self.userInteractionEnabled = YES;
    }
    
    return self;
}

// MARK: Updates

// does whatever was supposed to happen after the fade-out activity was finished
- (void)performPostFadeActivity
{
    // stop menu music entirely
    [self stopMenuMusic];
    
    if( actionToTakeAfterFade == VNTestSceneActionWillStartNewGame ) {
        [self startNewGame];
    } else if( actionToTakeAfterFade == VNTestSceneActionWillLoadSavedGame ) {
        [self loadSavedGame];
    } else {
        NSLog(@"ERROR: There is no valid action to perform.");
    }
}

- (void)beginFading
{
    NSLog(@"Will now begin the fading-out process...");
    fadingProcessBegan = YES;
    originalOpacityOfLoadLabel = loadLabel.opacity;
    
    // visually fade out the scene (this involves fading out all the screen elements)
    CCTime fadingOutDuration = (CCTime)(totalFadeTime / VNTestSceneAssumedFPS);
    
    CCActionFadeOut* fadeOutStartLabel = [CCActionFadeOut actionWithDuration:fadingOutDuration];
    CCActionFadeOut* fadeOutLoadLabel = [CCActionFadeOut actionWithDuration:fadingOutDuration];
    CCActionFadeOut* fadeOutBackground = [CCActionFadeOut actionWithDuration:fadingOutDuration];
    CCActionFadeOut* fadeOutSupport = [CCActionFadeOut actionWithDuration:fadingOutDuration];
    CCActionFadeOut* fadeOutLogo = [CCActionFadeOut actionWithDuration:fadingOutDuration];
    
    [backgroundImage runAction:fadeOutBackground];
    [loadLabel runAction:fadeOutLoadLabel];
    [playLabel runAction:fadeOutStartLabel];
    [supportLabel runAction:fadeOutSupport];
    [title runAction:fadeOutLogo];
    
    if( playLabelBG != nil ) {
        CCActionFadeOut* fadeOutStartBG = [CCActionFadeOut actionWithDuration:fadingOutDuration];
        [playLabelBG runAction:fadeOutStartBG];
    }
    
    if( loadLabelBG != nil ) {
        CCActionFadeOut* fadeOutLoadBG = [CCActionFadeOut actionWithDuration:fadingOutDuration];
        [loadLabelBG runAction:fadeOutLoadBG];
    }
    
    if( supportLabelBG != nil ) {
        CCActionFadeOut* fadeOutSupportBG = [CCActionFadeOut actionWithDuration:fadingOutDuration];
        [supportLabelBG runAction:fadeOutSupportBG];
    }
    
    //CCActionFadeOut* fadeOutAction = [CCActionFadeOut actionWithDuration:fadingOutDuration];
    //[self runAction:fadeOutAction];
}

- (void)handleFading
{
    if( fadeTimer >= totalFadeTime ) {
        // reset volume, timing, etc. (for when/if VNTestScene is reloaded or transitioned back to)
        fadeTimer = 0;
        fadingProcessBegan = NO;
        [[OALSimpleAudio sharedInstance] setBgVolume:originalVolumeOfMusic]; // reset to normal volume
        // reset visuals so everything looks normal again
        [loadLabel setOpacity:originalOpacityOfLoadLabel];
        [playLabel setOpacity:1.0];
        [supportLabel setOpacity:1.0];
        [title setOpacity:1.0];
        [backgroundImage setOpacity:1.0];
        // perform final activity before transitioning
        [self performPostFadeActivity];
        
        // restore background images
        if( playLabelBG ) playLabelBG.opacity = 1.0;
        if( loadLabelBG ) loadLabelBG.opacity = 1.0;
        if( supportLabelBG ) supportLabelBG.opacity = 1.0;
        
    } else {
        fadeTimer++;
        
        if( isPlayingMusic == YES ) {
            // Calculate the sound volume. The idea is that the volume should be 1.0 before the fade-out process begins,
            // and then it slowly fades to down to 0 when the fading process ends.
            float timeSoFar = (float)fadeTimer;
            float theTotalTime = (float)totalFadeTime;
            float theValueOfASingleFrame = 1.0 / theTotalTime;
            float volumeAtThisTime = 1.0 - (theValueOfASingleFrame * timeSoFar);
            
            [[OALSimpleAudio sharedInstance] setBgVolume:volumeAtThisTime];
        }
    }
}

- (void)update:(CCTime)delta
{
    if( totalFadeTime > 0 && fadingProcessBegan == YES ) {
        [self handleFading];
    }
}



@end
