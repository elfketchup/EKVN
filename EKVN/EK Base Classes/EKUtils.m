//
//  ekutils.c
//  EKVN SpriteKit
//
//  Created by James on 9/17/14.
//  Copyright (c) 2014 James Briones. All rights reserved.
//

#include "ekutils.h"
#import "EKRecord.h"

__weak SKView* EKTheCurrentView = nil;

// Set screen/view dimensions; use default sizes for iPhone 4S
CGFloat EKScreenWidthInPoints   = 480.0;
CGFloat EKScreenHeightInPoints  = 320.0;

// Animation/time
double  EKAnimationIntervalValue    = -1.0;
int     EKNumberOfFramesPerSecond   = -1;

// scoring
NSUInteger EKUtilsLocalScore = 0;

#pragma mark - Screen dimensions

void EKSetScreenSizeInPoints( CGFloat width, CGFloat height )
{
    EKScreenWidthInPoints = fabs( width );
    EKScreenHeightInPoints = fabs( height );
    
    //NSLog(@"Screen size in points has been set to: %f, %f", EKScreenWidthInPoints, EKScreenHeightInPoints);
}

CGSize EKScreenSizeInPoints()
{
    return CGSizeMake( EKScreenWidthInPoints, EKScreenHeightInPoints );
}

void EKSetScreenDataFromView( SKView* view )
{
    EKTheCurrentView = view;
    
    if( view ) {
        
        // Set size data
        CGSize viewSizeInPoints = view.frame.size;
        EKSetScreenSizeInPoints( viewSizeInPoints.width, viewSizeInPoints.height );
        
        // Set animation data
        //
        // Cocos2d-to-SpriteKit notes: SKView's "frameInterval" is defined as "the number of frames that must pass
        // before the scene is called to update its contents." Setting this to 1 means that the scene is called to update
        // every frame (60fps behavior), setting it to 2 means it gets called every other frame (so 30fps), etc.
        // (Presumably setting this to 3 means that it sets FPS to 20fps, 4 would be 15fps, etc.)
        //
        // This works a little differently than cocos2d's CCDirection "animationInterval" (or whatever it's called), which
        // just returns the actual FPS it should be set to.
        int frameInterval = (int) view.frameInterval;
        EKNumberOfFramesPerSecond = 60 / frameInterval; // 60 / 1 = 60 FPS
        //NSLog(@"[GLOBAL] SKView's frame interval is %d frames per second.", EKNumberOfFramesPerSecond);
    }
}

BOOL EKScreenIsPortrait()
{
    if( EKScreenWidthInPoints > EKScreenHeightInPoints ) {
        return NO;
    }
    
    return YES;
}

SKView* EKCurrentView()
{
    if( EKTheCurrentView == nil )
        NSLog(@"[GLOBAL] WARNING: Cannot find current view data.");
    
    return EKTheCurrentView;
}

SKScene* EKCurrentScene()
{
    // Grab the current scene from the current view, if it exists
    SKView* theCurrentView = EKCurrentView();
    if( theCurrentView )
        return theCurrentView.scene;
    
    return nil;
}

#pragma mark - Positions

CGPoint EKPositionWithNormalizedCoordinates( const CGFloat normalizedX, const CGFloat normalizedY )
{
    return CGPointMake( EKScreenWidthInPoints * normalizedX, EKScreenHeightInPoints * normalizedY );
}

CGPoint EKPositionOfBottomLeftCornerOfParentNode( SKNode* parentNode )
{
    if( !parentNode )
        return CGPointZero;
    
    CGFloat widthOfParent = parentNode.frame.size.width;
    CGFloat heightOfParent = parentNode.frame.size.height;
    
    CGFloat xPos = (widthOfParent * (-0.5));
    CGFloat yPos = (heightOfParent * (-0.5));
    
    return CGPointMake(xPos, yPos);
}

void EKPositionSetPositionWithTemporaryAnchorPoint( SKSpriteNode* sprite, CGPoint position, CGPoint temporaryAnchorPoint )
{
    if( sprite ) {
        
        CGFloat widthOfSprite   = sprite.frame.size.width;
        CGFloat heightOfSprite  = sprite.frame.size.height;
        CGFloat anchorX         = temporaryAnchorPoint.x;
        CGFloat anchorY         = temporaryAnchorPoint.y;
        
        // Initial position: upper-right corner of the sprite is at lower-left corner of 'somePos'
        CGFloat sX = position.x + (widthOfSprite  * 0.5);
        CGFloat sY = position.y + (heightOfSprite * 0.5);
        
        // Add adjustment due to 'someAnchorPoint'
        sX = sX - (widthOfSprite * anchorX);
        sY = sY - (heightOfSprite * anchorY);
        
        //sprite.anchorPoint = someAnchorPoint;
        //sprite.position = somePos;
        sprite.position = CGPointMake( sX, sY );
    }
}

#pragma mark - Math

// Gets the angle between the bullet and another object
CGFloat EKFindAngleBetweenPoints( CGPoint original, CGPoint target )
{
    CGFloat mX = target.x - original.x;
    CGFloat mY = target.y - original.y;
    
    CGFloat f = atan2(mX, mY);
    //f = CC_RADIANS_TO_DEGREES(f); // atan2 will return a value in radians, so it has to be converted to degrees first
    f = (f * 57.29577951f); // PI * 180
    
    // The converted value is fine if the angle is between 0 degrees and 180, degrees, but beyond 180 it becomes
    // a little unusual. 181 degrees will be -179, 182 will be -178, etc. Fortunately, this is easy to fix.
    if( f < 0.0 )
        f = 180.0 + (180.0 + f);
    
    // Correct for excessive values
    while( f > 360.0 )
        f = f - 360.0;
    while( f < 0.0 )
        f = f + 360.0;
    
    //NSLog(@"ANGLE SHOULD RETURN: %f", f);
    return f; // This should be the right angle now
}

CGFloat EKMathDistanceBetweenPoints( CGPoint first, CGPoint second )
{
    CGPoint subtractedValue     = CGPointMake( first.x - second.x, first.y - second.y );
    CGPoint p1                  = subtractedValue;
    CGPoint p2                  = subtractedValue;
    CGFloat lengthSquared       = ( p1.x * p2.x + p1.y * p2.y );
    CGFloat length              = sqrt( lengthSquared );
    
    return length;
}

// Clamp functions
CGFloat EKMathClampCGFloat(CGFloat input, CGFloat min, CGFloat max)
{
    if( max < min ) {
        NSLog(@"[EKUtils] Clamp error. input=%f | min=%f | max=%f", input, min, max);
        return min;
    }
    
    if( input < min ) {
        input = min;
    } else if( input > max ) {
        input = max;
    }
    
    return input;
}

double EKMathClampDouble(double input, double min, double max)
{
    if( max < min ) {
        NSLog(@"[EKUtils] Clamp error. input=%f | min=%f | max=%f", input, min, max);
        return min;
    }
    
    if( input < min ) {
        input = min;
    } else if( input > max ) {
        input = max;
    }
    
    return input;
}

float EKMathClampFloat(float input, float min, float max)
{
    if( max < min ) {
        NSLog(@"[EKUtils] Clamp error. input=%f | min=%f | max=%f", input, min, max);
        return min;
    }
    
    if( input < min ) {
        input = min;
    } else if( input > max ) {
        input = max;
    }
    
    return input;
}

int EKMathClampInt(int input, int min, int max)
{
    if( max < min ) {
        NSLog(@"[EKUtils] Clamp error. input=%d | min=%d | max=%d", input, min, max);
        return min;
    }
    
    if( input < min ) {
        input = min;
    } else if( input > max ) {
        input = max;
    }
    
    return input;
}


#pragma mark - Collision

CGRect EKBoundingBoxOfSprite( SKSpriteNode* sprite )
{
    if( !sprite )
        return CGRectZero;
    
    CGFloat rectX = sprite.position.x - (sprite.size.width * sprite.anchorPoint.x);
    CGFloat rectY = sprite.position.y - (sprite.size.height * sprite.anchorPoint.y);
    CGFloat width = sprite.size.width;
    CGFloat height = sprite.size.height;
    
    return CGRectMake(rectX, rectY, width, height);
}

BOOL EKCollisionBetweenSpriteCircles( SKSpriteNode* first, SKSpriteNode* second )
{
    if( first && second ) {
        
        // Returns "averaged out" values for distance: (width + height) / 2
        CGFloat radiusOfFirst   = ((first.size.width*0.5) + (first.size.height*0.5)) * 0.5;
        CGFloat radiusOfSecond  = ((second.size.width*0.5) + (second.size.height*0.5)) * 0.5;
        
        CGFloat distanceBetweenTwo = EKMathDistanceBetweenPoints( first.position, second.position );
        
        if( distanceBetweenTwo <= (radiusOfFirst + radiusOfSecond) )
            return YES;
    }
    
    return NO;
}

BOOL EKCollisionBetweenSpriteBoundingBoxes( SKSpriteNode* first, SKSpriteNode* second )
{
    if( first && second ) {
        
        CGPoint firstPos    = first.position;
        CGFloat firstWidth  = first.size.width;
        CGFloat firstHeight = first.size.height;
        CGFloat firstX      = firstPos.x - (firstWidth * first.anchorPoint.x);
        CGFloat firstY      = firstPos.y - (firstHeight * first.anchorPoint.y);
        CGRect firstBox     = CGRectMake(firstX , firstY, firstWidth, firstHeight);
        
        CGPoint secondPos       = second.position;
        CGFloat secondWidth     = second.size.width;
        CGFloat secondHeight    = second.size.height;
        CGFloat secondX         = secondPos.x - (secondWidth * second.anchorPoint.x);
        CGFloat secondY         = secondPos.y - (secondHeight * second.anchorPoint.y);
        CGRect secondBox        = CGRectMake(secondX, secondY, secondWidth, secondHeight);
        
        return CGRectIntersectsRect( firstBox, secondBox );
    }
    
    return NO;
}

#pragma mark - Color

UIColor* EKColorFromUnsignedCharRGB( unsigned char r, unsigned char g, unsigned char b )
{
    return EKColorFromUnsignedCharRGBA(r, g, b, 255);
}

UIColor* EKColorFromUnsignedCharRGBA( unsigned char r, unsigned char g, unsigned char b, unsigned char a )
{
    float fR = (float) r;
    float fG = (float) g;
    float fB = (float) b;
    float fA = (float) a;
    
    // Convert to normalized values (0.0 to 1.0)
    fR = fR / 255.0;
    fG = fG / 255.0;
    fB = fB / 255.0;
    fA = fA / 255.0;
    
    return [UIColor colorWithRed:fR green:fG blue:fB alpha:fA];
}

#pragma mark - Animation and time

// Convert from frames to seconds
int EKSecondsToFrames( double seconds )
{
    if( EKNumberOfFramesPerSecond < 1 )
        EKSetFPS(0); // This tries to discover FPS using CCDirector
    
    double fpsCount = (double) EKNumberOfFramesPerSecond;
    return (seconds * fpsCount); // example: 0.5 seconds * 60fps = 30 frames
}

double EKFramesToSeconds( int frames )
{
    if( EKNumberOfFramesPerSecond < 1 )
        EKSetFPS(0); // Automatically calculate FPS and animation interval
    
    double framesAsFloatingPoint = (double) frames;
    return (framesAsFloatingPoint / EKNumberOfFramesPerSecond);
}

void EKSetFPS( int numberOfFramesPerSecond )
{
    // Check if the value should just be calculated using CCDirector
    if( numberOfFramesPerSecond < 1 ) {
        
        int framesCounted = 0;
        double animationInterval = 1 / 60.0;
        double currentInterval = 0.0;
        
        // See how long it takes to get from 0.0 to 1.0; the actual frame count is determined by the number of loops
        while( currentInterval < 1.0 ) {
            currentInterval = currentInterval + animationInterval; // If 60fps, this becomes: currentInterval + 0.016667
            framesCounted++;
        }
        
        numberOfFramesPerSecond = framesCounted;
    }
    
    // Assign new value
    EKNumberOfFramesPerSecond = numberOfFramesPerSecond;
    
    // Figure out the frame interval
    double fpsAsFloatingNumber = (double) numberOfFramesPerSecond;
    EKAnimationIntervalValue = 1.0 / fpsAsFloatingNumber;
    
    //NSLog(@"FPS set to %d, with animation interval set to %f", EKNumberOfFramesPerSecond, EKAnimationIntervalValue);
}

int EKFramesPerSecond()
{
    if( EKNumberOfFramesPerSecond < 1 )
        EKSetFPS(0);
    
    return EKNumberOfFramesPerSecond;
}

void EKSetAnimationInterval( double interval )
{
    // Check if the interval is too low or too high
    if( interval <= 0.0 || interval >= 1.0 )
        EKSetFPS(0); // If the value is "out of bounds" then set it automatically
    else
        EKAnimationIntervalValue = interval;
}

double EKAnimationInterval()
{
    if( EKAnimationIntervalValue <= 0.0 || EKAnimationIntervalValue >= 1.0 )
        EKSetFPS(0);
    
    return EKAnimationIntervalValue;
}

#pragma mark - Scoring

void EKScoringResetLocalScore()
{
    EKUtilsLocalScore = 0;
}

void EKScoringLoadLocalScoreFromRecord()
{
    EKUtilsLocalScore = [[EKRecord sharedRecord] currentScore];
}

void EKScoringModifyLocalScore(NSUInteger scoreModifier)
{
    EKUtilsLocalScore = EKUtilsLocalScore + scoreModifier;
}

void EKScoringAddScoreToRecord()
{
    NSUInteger total = [[EKRecord sharedRecord] currentScore] + EKUtilsLocalScore;
    [[EKRecord sharedRecord] setCurrentScore:total];
}

NSUInteger EKScoringLocalScore() {
    return EKUtilsLocalScore;
}

#pragma mark - Dictionary

// Dictionary (used to load a dicdtionary from a file or retrieve objects from dictionary)
NSDictionary* EKDictionaryFromFile(NSString* plistFilename)
{
    if( plistFilename == nil || plistFilename.length < 1 ) {
        NSLog(@"[-EKDictionaryFromFile] ERROR: Could not load property list as the filename was invalid.");
        return nil;
    }
    
    NSString* filepath = [[NSBundle mainBundle] pathForResource:plistFilename ofType:@"plist"];
    if( filepath == nil ) {
        NSLog(@"[-EKDictionaryFromFile] ERROR: Could not find property list named: %@", plistFilename);
        return nil;
    }
    
    NSDictionary* rootDictionary = [NSDictionary dictionaryWithContentsOfFile:filepath];
    if( rootDictionary == nil ) {
        NSLog(@"[-EKDictionaryFromFile] ERROR: Could not load root dictionary from file named: %@", plistFilename);
        return nil;
    }
    
    return rootDictionary;
}

int EKDictionaryNumberToInt(NSDictionary* dict, NSString* key)
{
    NSNumber* theNumber = EKDictionaryRetrieveNumber(dict, key);
    if( theNumber != nil ) {
        return theNumber.intValue;
    }
    
    return 0;
}

float EKDictionaryNumberToFloat(NSDictionary* dict, NSString* key)
{
    NSNumber* n = EKDictionaryRetrieveNumber(dict, key);
    if( n ) {
        return n.floatValue;
    }
    
    return 0;
}

double EKDictionaryNumberToDouble(NSDictionary* dict, NSString* key)
{
    NSNumber* n = EKDictionaryRetrieveNumber(dict, key);
    if( n ) {
        return n.doubleValue;
    }
    
    return 0;
}

CGFloat EKDictionaryNumberToCGFloat(NSDictionary* dict, NSString* key)
{
    NSNumber* n = EKDictionaryRetrieveNumber(dict, key);
    if( n ) {
        return ((CGFloat) n.doubleValue);
    }
    
    return 0;
}

NSInteger EKDictionaryNumberToNSInteger(NSDictionary* dict, NSString* key)
{
    NSNumber* n = EKDictionaryRetrieveNumber(dict, key);
    if( n ) {
        return n.integerValue;
    }
    
    return 0;
}

NSUInteger EKDictionaryNumberToNSUInteger(NSDictionary* dict, NSString* key)
{
    NSNumber* n = EKDictionaryRetrieveNumber(dict, key);
    if( n ) {
        return n.unsignedIntegerValue;
    }
    
    return 0;
}

// retrieve complex objects
NSString* EKDictionaryRetrieveString(NSDictionary* dict, NSString* key)
{
    if( dict != nil ) {
        NSString* someValue = [dict objectForKey:key];
        // check if what was retrieved is valid (and also a string)
        if( someValue != nil && [someValue isKindOfClass:[NSString class]] == YES ) {
            return someValue;
        }
    }
    
    return nil;
}

NSArray* EKDictionaryRetrieveArray(NSDictionary* dict, NSString* key)
{
    if( dict != nil ) {
        NSArray* someValue = dict[key];
        
        if( someValue != nil && [someValue isKindOfClass:[NSArray class]] == YES ) {
            return someValue;
        }
    }
    
    return nil;
}

NSNumber* EKDictionaryRetrieveNumber(NSDictionary* dict, NSString* key)
{
    if( dict == nil ) {
        return nil;
    }
    
    NSNumber* theNumber = [dict objectForKey:key];
    if( theNumber != nil && [theNumber isKindOfClass:[NSNumber class]] == YES ) {
        return theNumber;
    }
    
    return nil;
}

NSDictionary* EKDictionaryRetrieveDictionary(NSDictionary* dict, NSString* key)
{
    if( dict != nil ) {
        NSDictionary* value = dict[key];
        
        if( value != nil && [value isKindOfClass:[NSDictionary class]] == YES ) {
            return value;
        }
    }
    
    return nil;
}

#pragma mark - Numbers to scalars

int EKNumberToIntOrUseDefault(NSNumber* theNumber, int theDefault)
{
    if( theNumber == nil || [theNumber isKindOfClass:[NSNumber class]] == NO ) {
        return theDefault;
    }
    
    return theNumber.intValue;
}

float EKNumberToFloatOrUseDefault(NSNumber* theNumber, float theDefault)
{
    if( theNumber == nil || [theNumber isKindOfClass:[NSNumber class]] == NO ) {
        return theDefault;
    }
    
    return theNumber.floatValue;
}

double EKNumberToDoubleOrUseDefault(NSNumber* theNumber, double theDefault)
{
    if( theNumber == nil || [theNumber isKindOfClass:[NSNumber class]] == NO ) {
        return theDefault;
    }
    
    return theNumber.doubleValue;
}

CGFloat EKNumberToCGFloatOrUseDefault(NSNumber* theNumber, CGFloat theDefault)
{
    if( theNumber == nil || [theNumber isKindOfClass:[NSNumber class]] == NO ) {
        return theDefault;
    }
    
    return ((CGFloat) theNumber.doubleValue);
}

NSInteger EKNumberToIntegerOrUseDefault(NSNumber* theNumber, NSInteger theDefault)
{
    if( theNumber == nil || [theNumber isKindOfClass:[NSNumber class]] == NO ) {
        return theDefault;
    }
    
    return theNumber.integerValue;
}

NSUInteger EKNumberToUnsignedIntegerOrUseDefault(NSNumber* theNumber, NSUInteger theDefault)
{
    if( theNumber == nil || [theNumber isKindOfClass:[NSNumber class]] == NO ) {
        return theDefault;
    }
    
    return theNumber.unsignedIntegerValue;
}

#pragma mark - Strings

NSString* EKStringToStringOrUseDefault(NSString* theString, NSString* theDefault)
{
    if( theString == nil )
        return theDefault;
    if( theString.length < 1 )
        return theDefault;
    
    return theString;
}

/*
 Pass in a filename. If the filename has an extension (like ".png") then the extension is removed.
 Otherwise, the string is just returned normally if no extension is detected.
 
 input - string with filename
 extension - OPTIONAL extension (such as ".png" or ".jpg")
 */
NSString* EKStringFilenameWithoutExtension(NSString* input, NSString* extension)
{
    if( input == nil || input.length < 5 ) { // needs 4 characters minimum for a proper filename + extension
        return input;
    }
    
    NSUInteger expectedLength = 4; // default value for three-letter extensions
    
    if( extension != nil ) {
        if( [extension characterAtIndex:0] == '.' ) {
            expectedLength = extension.length;
        } else {
            expectedLength = extension.length + 1;
        }
    }
    
    NSUInteger expectedPositionOfPeriod = input.length - expectedLength; // A.jpg
    unichar theCharacter = [input characterAtIndex:expectedPositionOfPeriod];
    
    if( theCharacter == '.' ) {
        return [input substringToIndex:expectedPositionOfPeriod];
    }
    
    return input;
}

#pragma mark - Ads

#define EKUtilsShouldNeverShowAdsKey    @"should_never_show_ads" // stored in NSUserDefaults; determines whether or not ads can NEVER be shown (IAP?)

BOOL EKUtilsShouldShowAds = NO;
BOOL EKUtilsCurrentlyShowingAds = NO;

// Sets value in NSUserDefaults
BOOL EKAdsShouldNeverShowAds()
{
    NSNumber* neverShowAdsNumber = [[NSUserDefaults standardUserDefaults] objectForKey:EKUtilsShouldNeverShowAdsKey];
    
    if( neverShowAdsNumber != nil ) {
        return neverShowAdsNumber.boolValue;
    }
    
    return NO;
}

void EKAdsSetShouldNeverShowAds(BOOL value)
{
    NSNumber* updatedValue = [NSNumber numberWithBool:value];
    
    if( updatedValue != nil ) {
        [[NSUserDefaults standardUserDefaults] setValue:updatedValue forKey:EKUtilsShouldNeverShowAdsKey];
    } else {
        NSLog(@"[EKUtils] ERROR: Could not set value in NSUserDefaults for: %@", EKUtilsShouldNeverShowAdsKey);
    }
}

void EKAdsSetShowAds(BOOL value)
{
    EKUtilsShouldShowAds = value;
}

BOOL EKAdsCanShowAds()
{
    BOOL shouldNeverShowAds = EKAdsShouldNeverShowAds();
    if( shouldNeverShowAds == YES ) {
        return NO;
    }
    
    return EKUtilsShouldShowAds;
}

void EKAdsHandleDisplayOfAds()
{
    BOOL canShowAds = EKAdsCanShowAds();
    
    if( canShowAds == NO ) {
        // Determine if ads are currently showing and need to be hidden
        if( EKUtilsCurrentlyShowingAds == YES ) {
            [[NSNotificationCenter defaultCenter] postNotificationName:EKUtilsHideAdsNotificationID object:nil];
            EKUtilsCurrentlyShowingAds = NO; // set "showing ads" to off
        }
    } else {
        // determine if ads are currently hidden and need to be shown
        if( EKUtilsCurrentlyShowingAds == NO ) {
            [[NSNotificationCenter defaultCenter] postNotificationName:EKUtilsShowAdsNotificationID object:nil];
            EKUtilsCurrentlyShowingAds = YES;
        }
    }
}

CGFloat EKAdsHeightOfBanner()
{
    if( EKAdsCanShowAds() == NO ){
        return 0;
    }
    
    BOOL isPortrait = EKScreenIsPortrait();
    
    if( isPortrait == YES ) {
        return 50;
    }
    
    return 30;
}