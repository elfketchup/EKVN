//
//  VNLayer.h
//
//  Created by James Briones on 7/3/11.
//  Copyright 2011. All rights reserved.
//

#import "cocos2d.h"
#import "VNScript.h"
#import "VNSystemCall.h"

/*
 
 VNLayer
 
 VNLayer is the main class for displaying and interacting with the Visual Novel system (or "VN system") I've coded.
 VNLayer works by taking script data (interpreted from a Property List file using VNScript), and processes
 the script to handle audio and display graphics, text, and basic animation. It also handles user input for playing
 the scene and user choices, plus saving related data to EKRecord.
 
 Visual and audio elements are handled by VNLayer; sprites and sounds are stored in a mutable dictionary and mutable array, 
 respectively. A record of the dialogue scene / visual-novel elements is kept by VNLayer, and can be copied over to EKRecord 
 (and from EKRecord, into device memory) when necessary. During certain "volatile" periods (like when performing effects or
 presenting the player with a menu of choices), VNLayer will store that record in a "safe save," which is created just before
 the effect/choice-menu is run, and holds the data from "the last time it was safe to save the game." Afterwards, when VNLayer
 resumes "normal" activity, then the safe-save is removed and any attempts to save the game will just draw data from the
 "normal" record.
 
 When processing script data from VNScript, the script is divided into "conversations," which are really an NSArray
 of text/NSString objects that have been converted to string and number data to be more easily processed. Different "conversations"
 represent branching paths in the script. When VNLayer begins processing script data, it always starts with a converation
 named "start".
 
 */

/*
 
 Coding/readability notes
 
 NOTE: What would become VNLayer was originally written as part of a visual-novel game engine that I made in conjuction
       with a custom sprite-drawing kit written in OpenGL ES v1. At that time, it used the MVC (Model-View-Controller) model,
       where there were separate classes for each.
 
       Later, I ported the code over to Cocos2D (which worked MUCH better than my custom graphics kit), and the View and
       Controller classes were mixed together to form VNLayer, while VNScript held the Model information. I've tried
       to clean up the code so it would make sense to reflect how things work now, but there are still some quirks and
       "leftovers" from the prior version of the code.

 */

#pragma mark - Defintions and Constants

#define VNLayerActivityType             @"VNLayer" // The type of activity this is (used in conjuction with EKRecord)
#define VNLayerToPlayKey                @"scene to play"
#define VNLayerViewFontSize             17
#define VNLayerSpriteIsSafeToRemove     9001 // Used for sprite removal (to free up memory and remove unused sprite)

// Sprite alignment strings (used for commands)
#define VNLayerViewSpriteAlignmentLeftString                @"left"             // 25% of screen width
#define VNLayerViewSpriteAlignmentCenterString              @"center"           // 50% of screen width
#define VNLayerViewSpriteAlignmentRightString               @"right"            // 75% of screen width
#define VNLayerViewSpriteAlignemntFarLeftString             @"far left"         // 0% of screen width
#define VNLayerViewSpriteAlignmentExtremeLeftString         @"extreme left"     // -50% of screen width; offscreen to the left
#define VNLayerViewSpriteAlignmentFarRightString            @"far right"        // 100% of screen width
#define VNLayerViewSpriteAlignmentExtremeRightString        @"extreme right"    // 150% of screen width; offscreen to the right

// View settings keys
#define VNLayerViewTalkboxName                  @"talkbox.png"
#define VNLayerViewSpeechBoxOffsetFromBottomKey @"speechbox offset from bottom"
#define VNLayerViewSpriteTransitionSpeedKey     @"sprite transition speed"
#define VNLayerViewTextTransitionSpeedKey       @"text transition speed"
#define VNLayerViewNameTransitionSpeedKey       @"speaker name transition speed"
#define VNLayerViewSpeechBoxXKey                @"speech box x"
#define VNLayerViewSpeechBoxYKey                @"speech box y"
#define VNLayerViewNameXKey                     @"name x"
#define VNLayerViewNameYKey                     @"name y"
#define VNLayerViewSpeechXKey                   @"speech x"
#define VNLayerViewSpeechYKey                   @"speech y"
#define VNLayerViewSpriteXKey                   @"sprite x"
#define VNLayerViewSpriteYKey                   @"sprite y"
#define VNLayerViewButtonXKey                   @"button x"
#define VNLayerViewButtonYKey                   @"button y"
#define VNLayerViewSpeechHorizontalMarginsKey   @"speech horizontal margins"
#define VNLayerViewSpeechVerticalMarginsKey     @"speech vertical margins"
#define VNLayerViewSpeechBoxFilenameKey         @"speech box filename"
#define VNLayerViewSpeechOffsetXKey             @"speech offset x"
#define VNLayerViewSpeechOffsetYKey             @"speech offset y"
#define VNLayerViewDefaultBackgroundOpacityKey  @"default background opacity"
#define VNLayerViewMultiplyFontSizeForiPadKey   @"multiply font size for iPad"
#define VNLayerViewButtonUntouchedColorsKey     @"button untouched colors"
#define VNLayerViewButtonsTouchedColorsKey      @"button touched colors"

// Resource dictionary keys
#define VNLayerViewSpeechTextKey                @"speech text"
#define VNLayerViewSpeakerNameKey               @"speaker name"
#define VNLayerViewShowSpeechKey                @"show speech flag"
#define VNLayerViewBackgroundResourceKey        @"background resource"
#define VNLayerViewAudioInfoKey                 @"audio info"
#define VNLayerViewSpriteResourcesKey           @"sprite resources"
#define VNLayerViewSpriteNameKey                @"sprite name"
#define VNLayerViewSpriteAlphaKey               @"sprite alpha"
#define VNLayerViewSpriteXKey                   @"sprite x"
#define VNLayerViewSpriteYKey                   @"sprite y"
#define VNLayerViewSpeakerNameXOffsetKey        @"speaker name offset x"
#define VNLayerViewSpeakerNameYOffsetKey        @"speaker name offset y"
#define VNLayerViewButtonFilenameKey            @"button filename"
#define VNLayerViewFontSizeKey                  @"font size"
#define VNLayerViewFontNameKey                  @"font name"

// Dictionary keys
#define VNLayerSavedScriptInfoKey       @"script info"
#define VNLayerSavedResourcesKey        @"saved resources"
#define VNLayerMusicToPlayKey			@"music to play"
#define VNLayerMusicShouldLoopKey       @"music should loop"
#define VNLayerSpritesToShowKey			@"sprites to show"
#define VNLayerSoundsToRemoveKey        @"sounds to remove"
#define VNLayerMusicToRemoveKey         @"music to remove"
#define VNLayerBackgroundToShowKey		@"background to show"
#define VNLayerSpeakerNameToShowKey		@"speaker name to show"
#define VNLayerSpeechToDisplayKey		@"speech to display"
#define VNLayerShowSpeechKey            @"show speech"

// Graphics/display stuff
#define VNLayerViewSettingsFileName     @"vnlayer view settings"
#define VNLayerSpriteXKey               @"x position"
#define VNLayerSpriteYKey               @"y position"

// Sprite/node layers
#define VNLayerBackgroundLayer          50
#define VNLayerCharacterLayer           60
#define VNLayerUILayer                  100
#define VNLayerTextLayer                110
#define VNLayerButtonsLayer             120
#define VNLayerButtonTextLayer          130

// Node tags
#define VNLayerTagSpeechBox             600
#define VNLayerTagSpeakerName           601
#define VNLayerTagSpeechText            602
#define VNLayerTagBackground            603

// Scene modes
#define VNLayerModeLoading              100
#define VNLayerModeFinishedLoading      101
#define VNLayerModeNormal               200 // Normal "playing," with dialogue and interaction
#define VNLayerModeEffectIsRunning      201 // An Effect (fade-in/fade-out, sprite-movement, etc.) is currently running
#define VNLayerModeChoiceWithFlag       202
#define VNLayerModeChoiceWithJump       203
#define VNLayerModeEnded                300 // There isn't any more script data to process

#pragma mark - VNLayer Declaration

@interface VNLayer : CCLayer {
    
    // Model data (which in this case is the scene's "script" that determines what will happen)
    VNScript* script;
    
    // A helper class that can be used to handle .systemcall commands. This may be redundant, now that
    // .callcode exists though!
    VNSystemCall* systemCallHelper;
    
    NSMutableDictionary* record; // Holds misc data (especially regarding the script)
    NSMutableDictionary* flags; // Local flags data (later saved to EKRecord's flags, when the scene is saved)
    
    int mode; // What the scene is doing (or should be doing) at the current moment
    
    // The "safe save" is an pseudo-autosave created right before performing a "dangerous" action like running an EKEffect.
    // Since saving the game in the middle of an effectt can cause unexpected results (like sprites being in the wrong
    // position), VNLayer won't allow for anything to be saved until a "safe" point can be reached. Instead, VNLayer saves
    // its data into this dictionary object beforehand, and if the user attempts to save the game in the middle of an effect,
    // they will only save the "safe" information instead of anything dangerous. Of course, when the "dangerous" part ends,
    // this dictionary is deleted, and things can be saved as normal.
    NSDictionary* safeSave;
    
    // View data
    NSMutableDictionary* viewSettings;
    
    BOOL effectIsRunning;
    BOOL isPlayingMusic;
    //BOOL wasJustLoadedFromSave; // Was this scene JUST loaded from a saved game? (used to stop strange index behavior)
    
    NSMutableArray* soundsLoaded;
    NSMutableArray* buttons;
    NSMutableArray* choices; // Holds values that will be used when making choices
    NSMutableArray* choiceExtras; // Holds extra data that's used when making choices (usually, flag data)
    NSInteger buttonPicked;
    
    NSMutableDictionary* sprites;
    NSMutableArray* spritesToRemove;
    
    CCSprite* speechBox; // Dialogue box
    CCLabelTTF* speech;
    CCLabelTTF* speaker; // Name of speaker
    
    float spriteTransitionSpeed, speechTransitionSpeed, speakerTransitionSpeed;
    ccColor3B buttonTouchedColors, buttonUntouchedColors;
}

//@property (nonatomic, strong) VNScript* script;
@property BOOL isFinished;
@property BOOL wasJustLoadedFromSave; // Useful because of some weird saving/loading quirks that popped up with .SYSTEMCALL:AUTOSAVE
@property BOOL shouldPopScene; // Checks if VNLayer should tell Cocos2D to remove the current scene after VNLayer has finished the script

+ (VNLayer*)currentVNLayer;

+ (id)sceneWithSettings:(NSDictionary*)settings;
- (id)initWithSettings:(NSDictionary*)settings;

- (NSArray*)spriteDataFromScene; // Saves information about the sprites in the scene

- (void)loadDefaultViewSettings;
- (void)loadSavedResources;
- (void)loadUI;

- (void)removeUnusedSprites;
- (void)markActiveSpritesAsUnused;
- (void)purgeDataCreatedByScene; // Get rid of any objects that were allocated by the scene (but which may be stored ELSEWHERE)

//- (id)main;
- (void)update:(ccTime)delta;
- (void)runScript;
- (void)processCommand:(NSArray*)command;

- (void)setEffectRunningFlag;
- (void)clearEffectRunningFlag;

- (void)updateScriptInfo;
- (void)createSafeSave;
- (void)removeSafeSave;
- (void)saveToRecord;

- (void)ccTouchesBegan:(NSSet*)touches withEvent:(UIEvent *)event;
- (void)ccTouchesMoved:(NSSet*)touches withEvent:(UIEvent *)event;
- (void)ccTouchesEnded:(NSSet*)touches withEvent:(UIEvent *)event;

@end
