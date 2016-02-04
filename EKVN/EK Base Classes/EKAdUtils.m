//
//  EKAdUtils.m
//  EKVN
//
//  Created by James on 2/3/16.
//  Copyright © 2016 James Briones. All rights reserved.
//

#import "EKUtils.h"
#import "EKAdUtils.h"

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
