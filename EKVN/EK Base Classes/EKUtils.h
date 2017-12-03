//
//  ekutils.h
//  EKVN SpriteKit
//
//  Created by James on 9/17/14.
//  Copyright (c) 2014 James Briones. All rights reserved.
//

/*
 
 NOTES:
 
 The "normal" edition of EKVN is meant for use with cocos2d, while EKVN SpriteKit runs on -- obviously -- SpriteKit.
 However, cocos2d has certain functions/capabilities/quirks that aren't present in SpriteKit. The EKUtils files then,
 are a group of functions that are meant to bridge the gap between the two frameworks, and make the transition from
 cocos2d to SpriteKit a little easier.
 
 */

#include <SpriteKit/SpriteKit.h>
@import AVFoundation;

#pragma mark - Definitions

// Ads notifications
#define EKUtilsShowAdsNotificationID        @"EKUtilsShowAdsNotificationID"
#define EKUtilsHideAdsNotificationID        @"EKUtilsHideAdsNotificationID"

#pragma Mark - Functions

// Set (or find) the screen size in points (as opposed to the screen size in pixels).
void EKSetScreenSizeInPoints( CGFloat width, CGFloat height );
CGSize EKScreenSizeInPoints(void);
BOOL EKScreenIsPortrait(void);

// Retrieves view/screen size data from an SKView object.
void EKSetScreenDataFromView( SKView* view );
SKView* EKCurrentView(void);
SKScene* EKCurrentScene(void);

// Sets position using normalized coordinates; used mostly to set SKNode positions to normalized coordinates (0.0 to 1.0)
CGPoint EKPositionWithNormalizedCoordinates( CGFloat normalizedX, CGFloat normalizedY );

// Used when adding one node to another; this function finds where the bottom-left corner of the node would be.
// In cocos2d, adding one node to another with a position of (0,0) results in the child node being positioned
// at the lower-left corner of the parent, which isn't the case with SpriteKit.
CGPoint EKPositionOfBottomLeftCornerOfParentNode( SKNode* parentNode );

// Since setting the anchorPoint in SpriteKit can lead to some tricky positioning later on, this is a function that does
// something similar to the cocos2d "change anchorPoint and set position" method, but without the hassle of actually changing anchorPoint
void EKPositionSetPositionWithTemporaryAnchorPoint( SKSpriteNode* sprite, CGPoint position, CGPoint temporaryAnchorPoint );

// Finds the angles between two points; useful if you need to figure out which way to rotate a sprite
CGFloat EKFindAngleBetweenPoints( CGPoint original, CGPoint target );

// Calculates distance between two points. This works more-or-less like cocos2d's ccpDistance function
CGFloat EKMathDistanceBetweenPoints( CGPoint first, CGPoint second );

// Checks for collision between two sprite "circles," or rather, it checks the distance between two sprites and sees
// if they're close enough to "collide."
BOOL EKCollisionBetweenSpriteCircles( SKSpriteNode* first, SKSpriteNode* second );

// Checks for collision between two boundinx boxes.
BOOL EKCollisionBetweenSpriteBoundingBoxes( SKSpriteNode* first, SKSpriteNode* second );

// Used to convert color from cocos2d's ccColor3B format to the UIColor format.
UIColor* EKColorFromUnsignedCharRGB( unsigned char r, unsigned char g, unsigned char b );
UIColor* EKColorFromUnsignedCharRGBA( unsigned char r, unsigned char g, unsigned char b, unsigned char a );

// Retrieves bounding box of sprite. However, cocos2d's "bounding box" and SpriteKit's "frame" are similar; so this might not be necessary.
CGRect EKBoundingBoxOfSprite( SKSpriteNode* sprite );

// Clamp functions
CGFloat EKMathClampCGFloat(CGFloat input, CGFloat min, CGFloat max);
double EKMathClampDouble(double input, double min, double max);
float EKMathClampFloat(float input, float min, float max);
int EKMathClampInt(int input, int min, int max);

// Time/FPS-related helper functions
int EKSecondsToFrames( double seconds );
double EKFramesToSeconds( int frames );
void EKSetFPS( int numberOfFramesPerSecond );
int EKFramesPerSecond(void);
void EKSetAnimationInterval( double interval );
double EKAnimationInterval(void);

// Scoring functions
void EKScoringResetLocalScore(void);
void EKScoringLoadLocalScoreFromRecord(void);
void EKScoringModifyLocalScore(NSUInteger scoreModifier);
void EKScoringAddScoreToRecord(void);
NSUInteger EKScoringLocalScore(void);

// Strings
NSString* EKStringFilenameWithoutExtension(NSString* input, NSString* extension);
NSArray* EKStringArrayWithFilenameAndExtension(NSString* filename);
NSURL* EKStringURLFromFilename(NSString* filename);

// Dictionary (used to load a dicdtionary from a file or retrieve objects from dictionary)
NSDictionary* EKDictionaryFromFile(NSString* plistFilename);
int EKDictionaryNumberToInt(NSDictionary* dict, NSString* key);
float EKDictionaryNumberToFloat(NSDictionary* dict, NSString* key);
double EKDictionaryNumberToDouble(NSDictionary* dict, NSString* key);
CGFloat EKDictionaryNumberToCGFloat(NSDictionary* dict, NSString* key);
NSInteger EKDictionaryNumberToNSInteger(NSDictionary* dict, NSString* key);
NSUInteger EKDictionaryNumberToNSUInteger(NSDictionary* dict, NSString* key);
// retrieve complex objects
NSString* EKDictionaryRetrieveString(NSDictionary* dict, NSString* key);
NSArray* EKDictionaryRetrieveArray(NSDictionary* dict, NSString* key);
NSNumber* EKDictionaryRetrieveNumber(NSDictionary* dict, NSString* key);
NSDictionary* EKDictionaryRetrieveDictionary(NSDictionary* dict, NSString* key);
// Convert a number to a scalar value; if the number object is invalid then use a default value instead
int EKNumberToIntOrUseDefault(NSNumber* theNumber, int theDefault);
float EKNumberToFloatOrUseDefault(NSNumber* theNumber, float theDefault);
double EKNumberToDoubleOrUseDefault(NSNumber* theNumber, double theDefault);
CGFloat EKNumberToCGFloatOrUseDefault(NSNumber* theNumber, CGFloat theDefault);
NSInteger EKNumberToIntegerOrUseDefault(NSNumber* theNumber, NSInteger theDefault);
NSUInteger EKNumberToUnsignedIntegerOrUseDefault(NSNumber* theNumber, NSUInteger theDefault);
NSString* EKStringToStringOrUseDefault(NSString* theString, NSString* theDefault);

// Audio
AVAudioPlayer* EKAudioSoundFromFile(NSString* filename);
//void EKAudioSetLoops(AVAudioPlayer* sound, int numberOfLoops);

// Misc functions
int EKRollDice( int numberOfDice, int maximumRollValue, int plusModifier );


#pragma mark - Inline functions

/*
 * NOTE: These need to be fast because they'll almost certainly get called a lot
 */

// Adds two positions (CGPoints) together; returns result.
static inline CGPoint EKPositionAddTwoPositions( CGPoint first, CGPoint second )
{
    return CGPointMake( first.x + second.x, first.y + second.y );
}

// Subtracts two points together
static inline CGPoint EKPositionSubtractTwoPositions( CGPoint first, CGPoint second )
{
    return CGPointMake(first.x - second.x, first.y - second.y);
}

static inline CGFloat EKDegreesToRadians( CGFloat degrees )
{
    return (degrees * 0.01745329252f);
}

static inline CGFloat EKRadiansToDegrees( CGFloat radians )
{
    return (radians * 57.29577951f);
}

