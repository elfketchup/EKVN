//
//  VNTestScene.h
//
//  Created by James Briones on 8/30/12.
//  Copyright 2012. All rights reserved.
//

#import "cocos2d.h"
#import "VNScene.h"

#define VNTestSceneAssumedFPS   60 // assumes that the game is meant to run at 60fps, used mostly for timing fade-out sequence

/*
 
 Some important notes:
 
 The labels have X and Y values, but these aren't X and Y in pixel coordinates. Rather, they're in percentages
 (where 0.01 is 1% while 1.00 is 100%), and they're used to position things in relation to the width and height
 of the screen. For example, if you were to position the "Start New Game" label at
 
    X: 0.5
    Y: 0.3
 
 ...then horizontally, it would be at the middle of the screen (50%) while it would be positioned at only 30% of
 the screen's height.
 
 Also, (0.0, 0.0) would be the bottom-left corner of the screen, while (1.0, 1.0) should be the upper-right corner.
 
 */

// Actions to take after "fade out to scene"
#define VNTestSceneActionWillLoadSavedGame  100
#define VNTestSceneActionWillStartNewGame   101

// Dictionary keys for the UI elements
#define VNTestSceneStartNewGameLabelX       @"startnewgame label x"
#define VNTestSceneStartNewGameLabelY       @"startnewgame label y"
#define VNTestSceneStartNewGameText         @"startnewgame text"
#define VNTestSceneStartNewGameFont         @"startnewgame font"
#define VNTestSceneStartNewGameSize         @"startnewgame size"
#define VNTestSceneStartNewGameColorDict    @"startnewgame color"
#define VNTestSceneStartNewGameBGImage      @"startnewgame background image"
#define VNTestSceneStartNewGameSound        @"startnewgame sound"
#define VNTestSceneContinueLabelX           @"continue label x"
#define VNTestSceneContinueLabelY           @"continue label y"
#define VNTestSceneContinueText             @"continue text"
#define VNTestSceneContinueFont             @"continue font"
#define VNTestSceneContinueSize             @"continue size"
#define VNTestSceneContinueColor            @"continue color"
#define VNTestSceneContinueBGImage          @"continue background image"
#define VNTestSceneContinueSound            @"continue sound"
#define VNTestSceneTitleX                   @"title x"
#define VNTestSceneTitleY                   @"title y"
#define VNTestSceneTitleImage               @"title image"
#define VNTestSceneBackgroundImage          @"background image"
#define VNTestSceneScriptToLoad             @"script to load"
#define VNTestSceneMenuMusic                @"menu music"
#define VNTestSceneFadeOutTimeInSeconds     @"fade out time in seconds" // fade time in seconds (but the timer measures in frames)

@interface VNTestScene : CCScene
{
    CCLabelTTF* playLabel;
    CCLabelTTF* loadLabel;
    
    // optional images positioned behind the labels
    CCSprite* playLabelBG;
    CCSprite* loadLabelBG;
    
    CCSprite* title; // Title image
    CCSprite* backgroundImage;
    
    NSString* nameOfScript; // The name of the property list that has all the script data
    VNScene* testScene;
    
    BOOL isPlayingMusic;
    
    // Used to play sounds when tapping either the "New Game" button or the "Resume/Continue" button
    NSString* filenameOfSoundForStartButton;
    NSString* filenameOfSoundForContinueButton;
    
    /* "Fade Out To Scene"
     *
     * This is an optional feature: On the main menu, starting a new game (or loading an old game) will cause the scene
     * to gradually fade to black and the music to fade out.
     *
     */
    BOOL fadingProcessBegan;
    int fadeTimer;
    int totalFadeTime; // how long the fading sequence lasts (measured in frames)
    int actionToTakeAfterFade; // whether to start a new game or load a previously saved game
    float originalVolumeOfMusic; // what the volume was before this process began
    float originalOpacityOfLoadLabel;
}

+ (id)scene;

- (void)startNewGame;
- (void)loadSavedGame;

- (void)beginFading;
- (void)handleFading;

- (void)loadUI;
- (NSDictionary*)loadDefaultUI;

@end