//
//	A6Softbounds.m
//	A6Softbounds
//
//	Created by makoto tsuyuki on 2011.10.29.
//	Copyright makoto tsuyuki 2011. All rights reserved.
//

#import "A6Softbounds.h"


@implementation A6Softbounds

 - (id)initWithAPIManager:(id<PROAPIAccessing>)apiManager
{
	if (self = [super init])
	{
		_apiManager	= apiManager;
		_exportManager = [[_apiManager apiForProtocol:@protocol(ApertureExportManager)] retain];
		if (!_exportManager)
			return nil;
		
		_progressLock = [[NSLock alloc] init];
		
		// Finish your initialization here
	}
	
	return self;
}

- (void)dealloc
{
	// Release the top-level objects from the nib.
	[_topLevelNibObjects makeObjectsPerformSelector:@selector(release)];
	[_topLevelNibObjects release];
	
	[_progressLock release];
	[_exportManager release];
	
	[super dealloc];
}


#pragma mark -
// UI Methods
#pragma mark UI Methods

- (NSView *)settingsView
{
	if (nil == settingsView)
	{
		NSBundle *myBundle = [NSBundle bundleForClass:[self class]];
		NSNib *myNib = [[NSNib alloc] initWithNibNamed:@"A6Softbounds" bundle:myBundle];
		if ([myNib instantiateNibWithOwner:self topLevelObjects:&_topLevelNibObjects])
		{
			[_topLevelNibObjects retain];
		}
		[myNib release];
	}
	
	return settingsView;
}

- (NSView *)firstView
{
	return firstView;
}

- (NSView *)lastView
{
	return lastView;
}

- (void)willBeActivated
{
	
}

- (void)willBeDeactivated
{
	
}

#pragma mark
// Aperture UI Controls
#pragma mark Aperture UI Controls

- (BOOL)allowsOnlyPlugInPresets
{
	return YES;	
}

- (BOOL)allowsMasterExport
{
	return NO;
}

- (BOOL)allowsVersionExport
{
	return NO;	
}

- (BOOL)wantsFileNamingControls
{
	return NO;	
}

- (void)exportManagerExportTypeDidChange
{
}


#pragma mark -
// Save Path Methods
#pragma mark Save/Path Methods

- (BOOL)wantsDestinationPathPrompt
{
	return YES;
}

- (NSString *)destinationPath
{
	return nil;
}

- (NSString *)defaultDirectory
{
	return [@"~/Pictures" stringByExpandingTildeInPath];
}


#pragma mark -
// Export Process Methods
#pragma mark Export Process Methods

- (void)exportManagerShouldBeginExport
{
    [_exportManager shouldBeginExport];
}

- (void)exportManagerWillBeginExportToPath:(NSString *)path
{
	// Save our export base path to use later.
	_exportPath = [path copy];
	
	// Update the progress structure to say Beginning Export... with an indeterminate progress bar.
	[self lockProgress];
	exportProgress.totalValue = [_exportManager imageCount];
	exportProgress.indeterminateProgress = YES;
	exportProgress.message = [@"Beginning Export..." retain];
	[self unlockProgress];
}

- (BOOL)exportManagerShouldExportImageAtIndex:(unsigned)index
{
	return YES;
}

- (void)exportManagerWillExportImageAtIndex:(unsigned)index
{
	
}

- (BOOL)exportManagerShouldWriteImageData:(NSData *)imageData toRelativePath:(NSString *)path forImageAtIndex:(unsigned)index
{
    //TODO Main
	// Create a base URL
	CFURLRef baseURLRef = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)[NSString stringWithFormat:@"%@/%@", _exportPath, path], kCFURLPOSIXPathStyle, true);
    NSURL* path_directory = [baseURLRef URLByDeletingLastPathComponent];

	CGImageRef image;
    
    NSImage *im = [[NSImage alloc] initWithData:imageData];
    NSBitmapImageRep *bitmap = [NSBitmapImageRep imageRepWithData:[im TIFFRepresentation]];
	image = [bitmap CGImage];

    CFDictionaryRef* metadata = (CFDictionaryRef *)[[_exportManager propertiesWithoutThumbnailForImageAtIndex:index] retain];
    CFDictionarySetValue(metadata, kCGImageDestinationLossyCompressionQuality, [NSNumber numberWithFloat:A6SOFTBOUNDS_QUALITY]);
    float width = CGImageGetWidth(image);
    float height = CGImageGetHeight(image);
    
    
    float image_aspect_ratio = width/height;
    //bool  landscape = (image_aspect_ratio > A6SOFTBOUNDS_ASPECT_RATIO); // more wide image.
    bool  landscape = (width > height);
    if (landscape) {
        // 横が長過ぎる場合には、縦を基準にサイズを決める
        float total_width = height*image_aspect_ratio;
        float crop_width = (total_width/2)+((total_width/2)*A6SOFTBOUNDS_OVERLAPPING);
        float crop_height = height;
        CGRect leftRect = CGRectMake((width/2) - (total_width/2),0, crop_width, crop_height);
        CGRect rightRect = CGRectMake((width/2) - (crop_width*A6SOFTBOUNDS_OVERLAPPING), 0, crop_width, crop_height);
        CGImageRef image_left = CGImageCreateWithImageInRect(image, leftRect);
        CGImageRef image_right = CGImageCreateWithImageInRect(image, rightRect);
        
        NSString* file_left  = [NSString stringWithFormat:@"%@/%03d_l.jpg", [path_directory path], index];
        NSString* file_right = [NSString stringWithFormat:@"%@/%03d_r.jpg", [path_directory path], index];
        NSURL* url_left  = [NSURL fileURLWithPath:file_left];
        NSURL* url_right = [NSURL fileURLWithPath:file_right];
        
        CGImageDestinationRef dest_left  = CGImageDestinationCreateWithURL((CFURLRef)url_left , kUTTypeJPEG, 1, NULL);
        CGImageDestinationRef dest_right = CGImageDestinationCreateWithURL((CFURLRef)url_right, kUTTypeJPEG, 1, NULL);
        
        if (dest_left)
        {
            CGImageDestinationAddImage(dest_left, image_left, metadata);
            CGImageDestinationFinalize(dest_left);
            CFRelease(dest_left);
        }
        if (dest_right)
        {
            CGImageDestinationAddImage(dest_right, image_right, metadata);
            CGImageDestinationFinalize(dest_right);
            CFRelease(dest_right);
        }
        CFRelease(image_left);
        CFRelease(image_right);
    } else {
        // 縦長は分割しないでちょうどいいサイズにする
        // ちょうどいいか、縦が長い場合には横を基準にサイズを決める
        float crop_width;
        float crop_height;
        CGRect rect;
        int x;
        int y;
        if (image_aspect_ratio > A6SOFTBOUNDS_PIECE_ASPECT_RATIO) {
            //A6片面で横幅が大きい場合
            crop_width  = height*A6SOFTBOUNDS_PIECE_ASPECT_RATIO;
            crop_height = height;
            x = (width - crop_width)/2;
            y = 0;
        } else {
            //A6片面で縦幅が大きい場合
            crop_width  = width;
            crop_height = width / A6SOFTBOUNDS_PIECE_ASPECT_RATIO;
            x = 0;
            y = (height - crop_height)/2;
        }
        rect =  CGRectMake(x,y, crop_width, crop_height);
        CGImageRef img = CGImageCreateWithImageInRect(image, rect);
        NSString* file  = [NSString stringWithFormat:@"%@/%03d.jpg", [path_directory path], index];
        NSURL* url  = [NSURL fileURLWithPath:file];
        CGImageDestinationRef dest  = CGImageDestinationCreateWithURL((CFURLRef)url , kUTTypeJPEG, 1, NULL);
        CGImageDestinationAddImage(dest, img, metadata);
        CGImageDestinationFinalize(dest);
        CFRelease(dest);
    }
    CFRelease(metadata);
    CFRelease(image);
//    [path_directory release];
	return NO;	
}

- (void)exportManagerDidWriteImageDataToRelativePath:(NSString *)relativePath forImageAtIndex:(unsigned)index
{
	
}

- (void)exportManagerDidFinishExport
{
	[_exportManager shouldFinishExport];
}

- (void)exportManagerShouldCancelExport
{
	[_exportManager shouldCancelExport];
}


#pragma mark -
// Progress Methods
#pragma mark Progress Methods

- (ApertureExportProgress *)progress
{
	return &exportProgress;
}

- (void)lockProgress
{
	
	if (!_progressLock)
		_progressLock = [[NSLock alloc] init];
		
        [_progressLock lock];
}

- (void)unlockProgress
{
	[_progressLock unlock];
}

@end
