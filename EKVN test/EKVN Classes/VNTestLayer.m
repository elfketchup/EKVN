//
//  VNTestLayer.m
//
//  Created by James Briones on 8/30/12.
//  Copyright 2012. All rights reserved.
//

#import "VNTestLayer.h"
#import "VNLayer.h"
#import "EKRecord.h"

// Some Z-values, so that Cocos2D knows where to position things on the Z-coordinate (and which nodes will
// be drawn on top of which other nodes!)
#define VNTestLayerZForBackgroundImage      10
#define VNTestLayerZForLabels               20
#define VNTestLayerZForTitle                30

@implementation VNTestLayer

+ (id)scene
{
    CCScene* tempScene = [CCScene node];
    [tempScene addChild:[VNTestLayer node]];
    return tempScene;
}

#pragma mark - UI

// This loads the user interface for the title menu. Default view settings are first loaded into a dictionary,
// and then custom settings are loaded from a file (assuming file the exists, of course!). After that, the actual
// CCSprite / CCLabelTTF objects are created from that information.
- (void)loadUI
{
    // Knowing the screen size is important for positioning UI elements
    CGSize screenSize = [CCDirector sharedDirector].winSize;
    
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
            NSLog(@"[VNTestLayer] UI settings have been loaded from file.");
        }
    }
    
    // Check if no custom settings could be loaded. if this is the case, just log it for diagnostics purposes
    if( customSettings == nil ) {
        NSLog(@"[VNTestLayer] UI settings could not be loaded from a file.");
    }
    
    // For the "Start New Game" button, get the values from the dictionary
    float startLabelX = [standardSettings[VNTestLayerStartNewGameLabelX] floatValue];
    float startLabelY = [standardSettings[VNTestLayerStartNewGameLabelY] floatValue];
    float startFontSize = [standardSettings[VNTestLayerStartNewGameSize] floatValue];
    NSString* startText = standardSettings[VNTestLayerStartNewGameText];
    NSString* startFont = standardSettings[VNTestLayerStartNewGameFont];
    NSDictionary* startColors = standardSettings[VNTestLayerStartNewGameColorDict];
    
    // Now create the actual label
    playLabel = [CCLabelTTF labelWithString:startText fontName:startFont fontSize:startFontSize];
    playLabel.position = CGPointMake( screenSize.width * startLabelX, screenSize.height * startLabelY );
    playLabel.color = ccc3( [startColors[@"r"] unsignedCharValue],
                            [startColors[@"g"] unsignedCharValue],
                            [startColors[@"b"] unsignedCharValue] );
    [self addChild:playLabel z:VNTestLayerZForLabels];
    
    // Now grab the values for the Continue button
    float continueLabelX = [standardSettings[VNTestLayerContinueLabelX] floatValue];
    float continueLabelY = [standardSettings[VNTestLayerContinueLabelY] floatValue];
    float continueFontSize = [standardSettings[VNTestLayerContinueSize] floatValue];
    NSString* continueText = standardSettings[VNTestLayerContinueText];
    NSString* continueFont = standardSettings[VNTestLayerContinueFont];
    NSDictionary* continueColors = standardSettings[VNTestLayerContinueColor];
    
    // Load the "Continue" label
    loadLabel = [CCLabelTTF labelWithString:continueText fontName:continueFont fontSize:continueFontSize];
    loadLabel.position = CGPointMake( screenSize.width * continueLabelX, screenSize.height * continueLabelY );
    loadLabel.color = ccc3( [continueColors[@"r"] unsignedCharValue],
                            [continueColors[@"g"] unsignedCharValue],
                            [continueColors[@"b"] unsignedCharValue] );
    [self addChild:loadLabel z:VNTestLayerZForLabels];
    
    // Load the title info
    float titleX = [standardSettings[VNTestLayerTitleX] floatValue];
    float titleY = [standardSettings[VNTestLayerTitleY] floatValue];
    title = [CCSprite spriteWithFile:standardSettings[VNTestLayerTitleImage]];
    title.position = CGPointMake( screenSize.width * titleX, screenSize.height * titleY );
    [self addChild:title z:VNTestLayerZForTitle];
    
    // Set up background data
    backgroundImage = [CCSprite spriteWithFile:standardSettings[VNTestLayerBackgroundImage]];
    backgroundImage.position = CGPointMake( screenSize.width * 0.5, screenSize.height * 0.5 );
    [self addChild:backgroundImage z:VNTestLayerZForBackgroundImage];
    
    // Grab script name information
    nameOfScript = standardSettings[VNTestLayerScriptToLoad];
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
    [resourcesDict setObject:@(0.5) forKey:VNTestLayerStartNewGameLabelX];
    [resourcesDict setObject:@(0.3) forKey:VNTestLayerStartNewGameLabelY];
    [resourcesDict setObject:@"Helvetica" forKey:VNTestLayerStartNewGameFont];
    [resourcesDict setObject:@(18) forKey:VNTestLayerStartNewGameSize];
    [resourcesDict setObject:[whiteColorDict copy] forKey:VNTestLayerStartNewGameColorDict];
    
    // Create settings for "continue" button
    [resourcesDict setObject:@(0.5) forKey:VNTestLayerContinueLabelX];
    [resourcesDict setObject:@(0.2) forKey:VNTestLayerContinueLabelY];
    [resourcesDict setObject:@"Helvetica" forKey:VNTestLayerContinueFont];
    [resourcesDict setObject:@(18) forKey:VNTestLayerContinueSize];
    [resourcesDict setObject:[whiteColorDict copy] forKey:VNTestLayerContinueColor];
    
    // Set up title data
    [resourcesDict setObject:@(0.5) forKey:VNTestLayerTitleX];
    [resourcesDict setObject:@(0.75) forKey:VNTestLayerTitleY];
    [resourcesDict setObject:@"title.png" forKey:VNTestLayerTitleImage];
    
    // Set up background image
    [resourcesDict setObject:@"skyspace.png" forKey:VNTestLayerBackgroundImage];
    
    // Set up script data
    [resourcesDict setObject:@"demo script" forKey:VNTestLayerScriptToLoad];
    
    return [NSDictionary dictionaryWithDictionary:resourcesDict];
}

#pragma mak - Game starting and loading

- (void)startNewGame
{
    // Create a blank dictionary with no real data, except for the name of which script file to load.
    // You can pass this in to VNLayer with nothing but that information, and it will load a new game
    // (or at least, a new VNLayer scene!)
    NSMutableDictionary* tempDict = [NSMutableDictionary dictionary];
    [tempDict setObject:nameOfScript forKey:VNLayerToPlayKey];
    
    // Create an all-new scene and add VNLayer to it
    [[CCDirector sharedDirector] pushScene:[VNLayer sceneWithSettings:tempDict]];
}

- (void)loadSavedGame
{
    if( [[EKRecord sharedRecord] hasAnySavedData] == NO ) {
        NSLog(@"[VNTestLayer] ERROR: No saved data, cannot continue game!");
        return;
    }
    
    // The following's not very pretty, but it is pretty useful...
    CCLOG(@"[VNTestLayer] For diagnostics purporses, here's a flag dump from EKRecord:\n   %@", [[EKRecord sharedRecord] flags] );
    
    // Load saved-game records from EKRecord. The activity dictionary holds data about what the last thing the user was doing
    // (presumably, watching a scene), how far the player got, relevent data that needs to be reloaded, etc.
    NSDictionary* activityRecords = [[EKRecord sharedRecord] activityDict];
    NSString* lastActivity = [activityRecords objectForKey:EKRecordActivityTypeKey];
    if( lastActivity == nil ) {
        NSLog(@"[VNTestLayer] ERROR: No previous activity found. No saved game can be loaded.");
        return;
    }
    
    NSDictionary* savedData = [activityRecords objectForKey:EKRecordActivityDataKey];
    CCLOG(@"[VNTestLayer] Saved data is %@", savedData);
    
    // Unlike when the player is starting a new game, the name of the script to load doesn't have to be passed.
    // It should already be stored within the Activity Records from EKRecord.
    [[CCDirector sharedDirector] pushScene:[VNLayer sceneWithSettings:savedData]];
}

#pragma mark - Touch controls

- (void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch* anyTouch = [touches anyObject];
    CGPoint touchPosInView = [anyTouch locationInView:[anyTouch view]];
    CGPoint touchPos = [[CCDirector sharedDirector] convertToGL:touchPosInView];
    
    if( CGRectContainsPoint([playLabel boundingBox], touchPos) ) {
        
        [self startNewGame];
        
    }
    
    if( CGRectContainsPoint([loadLabel boundingBox], touchPos) ) {
        
        // Loading the game is only possible if the label is fully opaque. And it will only be fully
        // opaque if previous save game data has been found.
        if( loadLabel.opacity > 250 )
            [self loadSavedGame];
        
    }
}

- (void)update:(ccTime)deltaTime
{
    // The following commented-out section is only necessary if you're adding VNLayer as a child layer of this layer
    // (or this scene). Since the "normal" version is to create a new sceen entirely, this other stuff isn't  necessary.
    
    /*
    if( testScene ) {
        if( testScene.isFinished == YES ) {
            
            [self removeChild:testScene];
            testScene = nil;
            
            self.touchEnabled = YES;
        }
    }*/
}

- (id)init
{
    if( self = [super init] ) {
        
        BOOL previousSaveData = [[EKRecord sharedRecord] hasAnySavedData];
        
        [self loadUI];
        
        // If there's no previous data, then the "Continue" / "Load Game" label will be partially transparent.
        if( previousSaveData == NO )
            loadLabel.opacity = (255 * 0.5);
        else
            loadLabel.opacity = 255;
        
        self.touchEnabled = YES;
        //[self scheduleUpdate];
    }
    
    return self;
}



@end
