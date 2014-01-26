//
//  VNTestScene.m
//
//  Created by James Briones on 8/30/12.
//  Copyright 2012. All rights reserved.
//

#import "VNTestScene.h"
#import "VNScene.h"
#import "EKRecord.h"

// Some Z-values, so that Cocos2D knows where to position things on the Z-coordinate (and which nodes will
// be drawn on top of which other nodes!)
#define VNTestSceneZForBackgroundImage      10
#define VNTestSceneZForLabels               20
#define VNTestSceneZForTitle                30

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
    
    // Load the "Continue" label
    loadLabel = [CCLabelTTF labelWithString:continueText fontName:continueFont fontSize:continueFontSize];
    loadLabel.position = CGPointMake( screenSize.width * continueLabelX, screenSize.height * continueLabelY );
    ccColor3B loadLabelColor  = ccc3( [continueColors[@"r"] unsignedCharValue],
                                      [continueColors[@"g"] unsignedCharValue],
                                      [continueColors[@"b"] unsignedCharValue] );
    loadLabel.color = [[CCColor alloc] initWithCcColor3b:loadLabelColor];
    [self addChild:loadLabel z:VNTestSceneZForLabels];
    
    // Load the title info
    float titleX = [standardSettings[VNTestSceneTitleX] floatValue];
    float titleY = [standardSettings[VNTestSceneTitleY] floatValue];
    title = [CCSprite spriteWithImageNamed:standardSettings[VNTestSceneTitleImage]];
    title.position = CGPointMake( screenSize.width * titleX, screenSize.height * titleY );
    [self addChild:title z:VNTestSceneZForTitle];
    
    // Set up background data
    backgroundImage = [CCSprite spriteWithImageNamed:standardSettings[VNTestSceneBackgroundImage]];
    backgroundImage.position = CGPointMake( screenSize.width * 0.5, screenSize.height * 0.5 );
    [self addChild:backgroundImage z:VNTestSceneZForBackgroundImage];
    
    // Grab script name information
    nameOfScript = standardSettings[VNTestSceneScriptToLoad];
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

#pragma mark - Touch controls

- (void)touchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    // There's not really anything going on in this function, but if this fucntion isn't implemented, then
    // any input in this class won't be recognized by Cocos2D v3. Thus, this function has been "implemented,"
    // just so that Cocos2D will pay attention to all the "real" action going on in the touchEnded function.
}

//- (void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
- (void)touchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint touchPos = [touch locationInNode:self];
    
    // Check if the user tapped on the "play" label
    if( CGRectContainsPoint([playLabel boundingBox], touchPos) ) {
        
        [self startNewGame];
    }
    
    // Check if the user tapped on the "contine" / "load saved game" label
    if( CGRectContainsPoint([loadLabel boundingBox], touchPos) ) {
        
        // Loading the game is only possible if the label is fully opaque. And it will only be fully
        // opaque if previous save game data has been found.
        if( loadLabel.opacity > 0.98 )
            [self loadSavedGame];
    }
}

- (id)init
{
    if( self = [super init] ) {
        
        BOOL previousSaveData = [[EKRecord sharedRecord] hasAnySavedData];
        
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



@end
