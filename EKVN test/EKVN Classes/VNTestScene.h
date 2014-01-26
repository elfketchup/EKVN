//
//  VNTestScene.h
//
//  Created by James Briones on 8/30/12.
//  Copyright 2012. All rights reserved.
//

#import "cocos2d.h"
#import "VNScene.h"

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

// Dictionary keys for the UI elements
#define VNTestSceneStartNewGameLabelX       @"startnewgame label x"
#define VNTestSceneStartNewGameLabelY       @"startnewgame label y"
#define VNTestSceneStartNewGameText         @"startnewgame text"
#define VNTestSceneStartNewGameFont         @"startnewgame font"
#define VNTestSceneStartNewGameSize         @"startnewgame size"
#define VNTestSceneStartNewGameColorDict    @"startnewgame color"
#define VNTestSceneContinueLabelX           @"continue label x"
#define VNTestSceneContinueLabelY           @"continue label y"
#define VNTestSceneContinueText             @"continue text"
#define VNTestSceneContinueFont             @"continue font"
#define VNTestSceneContinueSize             @"continue size"
#define VNTestSceneContinueColor            @"continue color"
#define VNTestSceneTitleX                   @"title x"
#define VNTestSceneTitleY                   @"title y"
#define VNTestSceneTitleImage               @"title image"
#define VNTestSceneBackgroundImage          @"background image"
#define VNTestSceneScriptToLoad             @"script to load"

@interface VNTestScene : CCScene
{
    CCLabelTTF* playLabel;
    CCLabelTTF* loadLabel;
    
    CCSprite* title; // Title image
    CCSprite* backgroundImage;
    
    NSString* nameOfScript; // The name of the property list that has all the script data
    VNScene* testScene;
}

+ (id)scene;

- (void)startNewGame;
- (void)loadSavedGame;

- (void)loadUI;
- (NSDictionary*)loadDefaultUI;

@end