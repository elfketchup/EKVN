//
//  VNTestLayer.h
//
//  Created by James Briones on 8/30/12.
//  Copyright 2012. All rights reserved.
//

#import "cocos2d.h"
#import "VNLayer.h"

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
#define VNTestLayerStartNewGameLabelX       @"startnewgame label x"
#define VNTestLayerStartNewGameLabelY       @"startnewgame label y"
#define VNTestLayerStartNewGameText         @"startnewgame text"
#define VNTestLayerStartNewGameFont         @"startnewgame font"
#define VNTestLayerStartNewGameSize         @"startnewgame size"
#define VNTestLayerStartNewGameColorDict    @"startnewgame color"
#define VNTestLayerContinueLabelX           @"continue label x"
#define VNTestLayerContinueLabelY           @"continue label y"
#define VNTestLayerContinueText             @"continue text"
#define VNTestLayerContinueFont             @"continue font"
#define VNTestLayerContinueSize             @"continue size"
#define VNTestLayerContinueColor            @"continue color"
#define VNTestLayerTitleX                   @"title x"
#define VNTestLayerTitleY                   @"title y"
#define VNTestLayerTitleImage               @"title image"
#define VNTestLayerBackgroundImage          @"background image"
#define VNTestLayerScriptToLoad             @"script to load"

@interface VNTestLayer : CCLayer
{
    CCLabelTTF* playLabel;
    CCLabelTTF* loadLabel;
    
    CCSprite* title; // Title image
    CCSprite* backgroundImage;
    
    NSString* nameOfScript; // The name of the property list that has all the script data
    VNLayer* testScene;
}

+ (id)scene;

- (void)startNewGame;
- (void)loadSavedGame;

- (void)loadUI;
- (NSDictionary*)loadDefaultUI;

@end