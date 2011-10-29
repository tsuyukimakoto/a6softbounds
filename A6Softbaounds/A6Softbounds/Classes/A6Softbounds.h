//
//	A6Softbounds.h
//	A6Softbounds
//
//	Created by makoto tsuyuki on 2011.10.29.
//	Copyright makoto tsuyuki 2011. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#import "ApertureExportManager.h"
#import "ApertureExportPlugIn.h"

#define A6SOFTBOUNDS_A6_WIDTH   105.0f
#define A6SOFTBOUNDS_A6_HEIGHT  148.0f
#define A6SOFTBOUNDS_GROOVE        3.0f
//#define A6SOFTBOUNDS_OVERLAP       5.0f # official
#define A6SOFTBOUNDS_OVERLAP       6.0f
#define A6SOFTBOUNDS_OVERLAPPING  (A6SOFTBOUNDS_GROOVE + A6SOFTBOUNDS_OVERLAP) / (A6SOFTBOUNDS_A6_WIDTH+(A6SOFTBOUNDS_GROOVE*2))
#define A6SOFTBOUNDS_ASPECT_RATIO ((A6SOFTBOUNDS_A6_WIDTH+(A6SOFTBOUNDS_GROOVE*2))-(A6SOFTBOUNDS_GROOVE+A6SOFTBOUNDS_OVERLAP)*2)/(A6SOFTBOUNDS_A6_HEIGHT+(A6SOFTBOUNDS_GROOVE*2))
#define A6SOFTBOUNDS_PIECE_ASPECT_RATIO (111.0f / 154.0f) //((A6SOFTBOUNDS_A6_WIDTH+(A6SOFTBOUNDS_GROOVE*2))/(A6SOFTBOUNDS_A6_HEIGHT+(A6SOFTBOUNDS_GROOVE*2)))
#define A6SOFTBOUNDS_QUALITY 0.96f

@interface A6Softbounds : NSObject <ApertureExportPlugIn>
{
	// The cached API Manager object, as passed to the -initWithAPIManager: method.
	id _apiManager; 
	
	// The cached Aperture Export Manager object - you should fetch this from the API Manager during -initWithAPIManager:
	NSObject<ApertureExportManager, PROAPIObject> *_exportManager; 
	
	// The lock used to protect all access to the ApertureExportProgress structure
	NSLock *_progressLock;
	
	// Top-level objects in the nib are automatically retained - this array
	// tracks those, and releases them
	NSArray *_topLevelNibObjects;
	
	// The structure used to pass all progress information back to Aperture
	ApertureExportProgress exportProgress;

	// Outlets to your plug-ins user interface
	IBOutlet NSView *settingsView;
	IBOutlet NSView *firstView;
	IBOutlet NSView *lastView;

	NSString *_exportPath;
}

@end
