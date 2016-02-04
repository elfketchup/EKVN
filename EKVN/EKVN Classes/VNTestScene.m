//
//  VNTestScene.m
//
//  Created by James Briones on 8/30/12.
//  Copyright 2012. All rights reserved.
//

#import "VNTestScene.h"
#import "VNScene.h"
#import "EKRecord.h"
#import "ekutils.h"
//#import "OALSimpleAudio.h"

// Some Z-values, so that Cocos2D knows where to position things on the Z-coordinate (and which nodes will
// be drawn on top of which other nodes!)
#define VNTestSceneZForBackgroundImage      10
#define VNTestSceneZForLabels               20
#define VNTestSceneZForTitle                30

#define VNTestSceneMainMenuPLIST            @"main_menu"
//#define VNTestSceneMainMenuPLIST            @"a_mainmenu"

@implementation VNTestScene

#pragma mark - UI

// This loads the user interface for the title menu. Default view settings are first loaded into a dictionary,
// and then custom settings are loaded from a file (assuming file the exists, of course!). After that, the actual
// CCSprite / CCLabelTTF objects are created from that information.
- (void)loadUI
{
    // Load the default settings first
    NSMutableDictionary* standardSettings = [NSMutableDictionary dictionaryWithDictionary:[self loadDefaultUI]];
    NSDictionary* customSettings = nil;
    
    // Now try to load the custom settings that are stored in a file
    NSString* dictionaryFilePath = [[NSBundle mainBundle] pathForResource:VNTestSceneMainMenuPLIST ofType:@"plist"];
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
    
    // Now create the actual label
    //playLabel = [CCLabelTTF labelWithString:startText fontName:startFont fontSize:startFontSize];
    //playLabel = [[SKLabelNode alloc] initWithFontNamed:startFont];
    playLabel = [[DSMultilineLabelNode alloc] initWithFontNamed:startFont];
    playLabel.text = startText;
    playLabel.fontSize = startFontSize;
    playLabel.color = EKColorFromUnsignedCharRGB([startColors[@"r"] unsignedCharValue],
                                                 [startColors[@"g"] unsignedCharValue],
                                                 [startColors[@"b"] unsignedCharValue] );
    //playLabel.position = CGPointMake( screenSize.width * startLabelX, screenSize.height * startLabelY );
    playLabel.position = EKPositionWithNormalizedCoordinates( startLabelX, startLabelY );
    playLabel.zPosition = VNTestSceneZForLabels;
    [self addChild:playLabel];
    
    // Now grab the values for the Continue button
    float continueLabelX = [standardSettings[VNTestSceneContinueLabelX] floatValue];
    float continueLabelY = [standardSettings[VNTestSceneContinueLabelY] floatValue];
    float continueFontSize = [standardSettings[VNTestSceneContinueSize] floatValue];
    NSString* continueText = standardSettings[VNTestSceneContinueText];
    NSString* continueFont = standardSettings[VNTestSceneContinueFont];
    NSDictionary* continueColors = standardSettings[VNTestSceneContinueColor];
    
    // Load the "Continue" label
    //loadLabel = [CCLabelTTF labelWithString:continueText fontName:continueFont fontSize:continueFontSize];
    //loadLabel = [[SKLabelNode alloc] initWithFontNamed:continueFont];
    loadLabel = [[DSMultilineLabelNode alloc] initWithFontNamed:continueFont];
    loadLabel.fontSize = continueFontSize;
    loadLabel.text = continueText;
    //loadLabel.position = CGPointMake( screenSize.width * continueLabelX, screenSize.height * continueLabelY );
    loadLabel.position = EKPositionWithNormalizedCoordinates( continueLabelX, continueLabelY );
    loadLabel.color = EKColorFromUnsignedCharRGB([continueColors[@"r"] unsignedCharValue],
                                                 [continueColors[@"g"] unsignedCharValue],
                                                 [continueColors[@"b"] unsignedCharValue]);
    loadLabel.zPosition = VNTestSceneZForLabels;
    [self addChild:loadLabel];
    
    // Load the title info
    float titleX = [standardSettings[VNTestSceneTitleX] floatValue];
    float titleY = [standardSettings[VNTestSceneTitleY] floatValue];
    //title = [CCSprite spriteWithImageNamed:standardSettings[VNTestSceneTitleImage]];
    title = [SKSpriteNode spriteNodeWithImageNamed:standardSettings[VNTestSceneTitleImage]];
    //title.position = CGPointMake( screenSize.width * titleX, screenSize.height * titleY );
    title.position = EKPositionWithNormalizedCoordinates(titleX, titleY);
    title.zPosition = VNTestSceneZForTitle;
    [self addChild:title];
    
    // Set up background data
    //backgroundImage = [CCSprite spriteWithImageNamed:standardSettings[VNTestSceneBackgroundImage]];
    backgroundImage = [SKSpriteNode spriteNodeWithImageNamed:standardSettings[VNTestSceneBackgroundImage]];
    //backgroundImage.position = CGPointMake( screenSize.width * 0.5, screenSize.height * 0.5 );
    backgroundImage.position = EKPositionWithNormalizedCoordinates( 0.5, 0.5 );
    backgroundImage.zPosition = VNTestSceneZForBackgroundImage;
    [self addChild:backgroundImage];
    
    // Grab script name information
    nameOfScript = standardSettings[VNTestSceneScriptToLoad];
    
    // The music data is loaded last since it looks weird if music is playing but nothing has shown up on the screen yet.
    NSString* musicFilename = standardSettings[VNTestSceneMenuMusic];
    // Make sure the music isn't set to 'nil'
    if( [musicFilename caseInsensitiveCompare:@"nil"] != NSOrderedSame ) {
        
        //[[OALSimpleAudio sharedInstance] playBg:musicFilename loop:true];
        //if( backgroundMusicPlayer )
        [self playBackgroundMusic:musicFilename];
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
    
    NSDictionary* settingsForScene = @{ VNSceneToPlayKey: nameOfScript };
    
    // Create an all-new scene and add VNLayer to it
    //[[CCDirector sharedDirector] pushScene:[VNLayer sceneWithSettings:tempDict]];

    //[[CCDirector sharedDirector] pushScene:[VNScene sceneWithSettings:settingsForScene]];
    
    VNScene* scene = [[VNScene alloc] initWithSize:self.size andSettings:settingsForScene];
    scene.scaleMode = self.scaleMode;
    scene.previousScene = self;
    
    [self.view presentScene:scene];
}

- (void)loadSavedGame
{
    if( [[EKRecord sharedRecord] hasAnySavedData] == NO ) {
        NSLog(@"[VNTestScene] ERROR: No saved data, cannot continue game!");
        return;
    }
    
    // The following's not very pretty, but it is pretty useful...
    NSLog(@"[VNTestScene] For diagnostics purporses, here's a flag dump from EKRecord:\n   %@", [[EKRecord sharedRecord] flags] );
    
    // Load saved-game records from EKRecord. The activity dictionary holds data about what the last thing the user was doing
    // (presumably, watching a scene), how far the player got, relevent data that needs to be reloaded, etc.
    NSDictionary* activityRecords = [[EKRecord sharedRecord] activityDict];
    NSString* lastActivity = [activityRecords objectForKey:EKRecordActivityTypeKey];
    if( lastActivity == nil ) {
        NSLog(@"[VNTestScene] ERROR: No previous activity found. No saved game can be loaded.");
        return;
    }
    
    NSDictionary* savedData = [activityRecords objectForKey:EKRecordActivityDataKey];
    NSLog(@"[VNTestScene] Saved data is %@", savedData);
    
    // Unlike when the player is starting a new game, the name of the script to load doesn't have to be passed.
    // It should already be stored within the Activity Records from EKRecord.
    //[[CCDirector sharedDirector] pushScene:[VNScene sceneWithSettings:savedData]];
    VNScene* loadedGameScene = [[VNScene alloc] initWithSize:self.size andSettings:savedData];
    loadedGameScene.scaleMode = self.scaleMode;
    loadedGameScene.previousScene = self;
    [self.view presentScene:loadedGameScene];
}

#pragma mark - Touch controls

- (void)stopMenuMusic
{
    if( isPlayingMusic ) {
        //[[OALSimpleAudio sharedInstance] stopBg];
        if( backgroundMusic != nil ) {
            [backgroundMusic stop];
        }
    }
    
    isPlayingMusic = NO;
}

- (void)playBackgroundMusic:(NSString *)filename
{
    if( !filename )
        return;
    
    if( isPlayingMusic )
        [self stopMenuMusic];
    
    //[[OALSimpleAudio sharedInstance] playBg:filename loop:true];
    
    backgroundMusic = EKAudioSoundFromFile(filename);
    if( backgroundMusic == nil ) {
        NSLog(@"[VNTestScene] ERROR: Could not load background music from file named: %@", filename);
        return;
    } else {
        backgroundMusic.numberOfLoops = -1;
        [backgroundMusic play];
    }
    
    isPlayingMusic = YES;
}

- (void)toggleAds
{
    if( shouldShowAds == YES ) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"showadsID" object:nil];
        shouldShowAds = NO;
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"hideadsID" object:nil];
        shouldShowAds = YES;
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    for( UITouch* touch in touches ) {

        CGPoint touchPos = [touch locationInNode:self];

        // Check if the user tapped on the "play" label
        if( CGRectContainsPoint(EKBoundingBoxOfSprite(playLabel), touchPos) ) {
            [self stopMenuMusic];
            [self startNewGame];
        }

        // Check if the user tapped on the "contine" / "load saved game" label
        if( CGRectContainsPoint(EKBoundingBoxOfSprite(loadLabel), touchPos) ) {
            
            // Loading the game is only possible if the label is fully opaque. And it will only be fully
            // opaque if previous save game data has been found.
            if( loadLabel.alpha > 0.98 ) {
                [self stopMenuMusic];
                [self loadSavedGame];
            }
        }
    }
    
    //[self toggleAds];
}

- (id)initWithSize:(CGSize)size
{
    if( self = [super initWithSize:size] ) {
        
        EKSetScreenSizeInPoints(size.width, size.height);
        
        BOOL previousSaveData = [[EKRecord sharedRecord] hasAnySavedData];
        isPlayingMusic = NO;
        
        [self loadUI];
        
        // If there's no previous data, then the "Continue" / "Load Game" label will be partially transparent.
        if( previousSaveData == NO )
            loadLabel.alpha = 0.5;
        else
            loadLabel.alpha = 1.0;
        
        self.userInteractionEnabled = YES;
    }
    
    return self;
}



@end
