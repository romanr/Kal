//
//  KalPrivate.m
//  Kal
//
//  Created by Gregory Combs on 4/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "KalPrivate.h"

 BOOL isIpadDevice(void) {
	static BOOL hasCheckediPadStatus = NO;
	static BOOL isRunningOniPad = NO;
	
	if (!hasCheckediPadStatus)
	{
		if ([[UIDevice currentDevice] respondsToSelector:@selector(userInterfaceIdiom)])
		{
			if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
			{
				isRunningOniPad = YES;
				hasCheckediPadStatus = YES;
				return isRunningOniPad;
			}
		}
		hasCheckediPadStatus = YES;
	}
	return isRunningOniPad;
}
