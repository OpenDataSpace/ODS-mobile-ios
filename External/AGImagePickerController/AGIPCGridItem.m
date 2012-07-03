//
//  AGIPCGridItem.m
//  AGImagePickerController
//
//  Created by Artur Grigor on 17.02.2012.
//  Copyright (c) 2012 Artur Grigor. All rights reserved.
//  
//  For the full copyright and license information, please view the LICENSE
//  file that was distributed with this source code.
//  

#import "AGIPCGridItem.h"

@interface AGIPCGridItem ()

@property (nonatomic, retain) UIImageView *thumbnailImageView;
@property (nonatomic, retain) UIView *selectionView;
@property (nonatomic, retain) UIImageView *checkmarkImageView;

+ (void)resetNumberOfSelections;

@end

static NSUInteger numberOfSelectedGridItems = 0;

@implementation AGIPCGridItem

#pragma mark - Properties

@synthesize delegate, selected, asset, thumbnailImageView, selectionView, checkmarkImageView;

- (void)setSelected:(BOOL)isSelected
{
    @synchronized (self)
    {
        if (selected != isSelected)
        {
            if (isSelected) {
                // Check if we can select
                if ([self.delegate respondsToSelector:@selector(agGridItemCanSelect:)])
                {
                    if (![self.delegate agGridItemCanSelect:self])
                        return;
                }
            }
            
            selected = isSelected;
            
            self.selectionView.hidden = !selected;
            self.checkmarkImageView.hidden = !selected;
            
            if (selected)
            {
                numberOfSelectedGridItems++;
            }
            else
            {
                if (numberOfSelectedGridItems > 0)
                    numberOfSelectedGridItems--;
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
               
                if ([self.delegate respondsToSelector:@selector(agGridItem:didChangeSelectionState:)])
                {
                    [self.delegate performSelector:@selector(agGridItem:didChangeSelectionState:) withObject:self withObject:[NSNumber numberWithBool:selected]];
                }
                
                if ([self.delegate respondsToSelector:@selector(agGridItem:didChangeNumberOfSelections:)])
                {
                    [self.delegate performSelector:@selector(agGridItem:didChangeNumberOfSelections:) withObject:self withObject:[NSNumber numberWithUnsignedInteger:numberOfSelectedGridItems]];
                }
                
            });
        }
    }
}

- (BOOL)selected
{
    BOOL ret;
    
    @synchronized (self)
    {
        ret = selected;
    }
    
    return ret;
}

- (void)setAsset:(ALAsset *)theAsset
{
    @synchronized (self)
    {
        if (asset != theAsset)
        {
            [asset release];
            asset = [theAsset retain];
            
            self.thumbnailImageView.image = [UIImage imageWithCGImage:asset.thumbnail];
        }
    }
}

- (ALAsset *)asset
{
    ALAsset *ret = nil;
    
    @synchronized (self)
    {
        ret = [[asset retain] autorelease];
    }
    
    return ret;
}

#pragma mark - Object Lifecycle

- (void)dealloc
{
    [asset release];
    [thumbnailImageView release];
    [selectionView release];
    [checkmarkImageView release];
    
    [super dealloc];
}

- (id)init
{
    self = [self initWithAsset:nil andDelegate:nil];
    return self;
}

- (id)initWithAsset:(ALAsset *)theAsset
{
    self = [self initWithAsset:theAsset andDelegate:nil];
    return self;
}

- (id)initWithAsset:(ALAsset *)theAsset andDelegate:(id<AGIPCGridItemDelegate>)theDelegate
{
    self = [super init];
    if (self)
    {
        self.selected = NO;
        self.delegate = theDelegate;
        CGSize standardSize = CGSizeMake(320, 480);
        
        CGRect frame = [AGImagePickerController itemRect:standardSize];
        CGRect checkmarkFrame = [AGImagePickerController checkmarkFrameUsingItemFrame:frame];
        
        self.thumbnailImageView = [[[UIImageView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)] autorelease];
		self.thumbnailImageView.contentMode = UIViewContentModeScaleToFill;
		[self addSubview:self.thumbnailImageView];

		
		// Position the movie icon on bottom left corner; only if the media type is Video
		if ([theAsset valueForProperty:ALAssetPropertyType] == ALAssetTypeVideo) {
			
			// Black semi-transparent background at the bottom of the item
			CGRect containerFrame = CGRectMake(0, frame.size.height - AGIPC_MOVIE_HEIGHT, frame.size.width, AGIPC_MOVIE_HEIGHT);
			UIView *containerForMovieInfo = [[[UIView alloc] initWithFrame:containerFrame] autorelease];
			containerForMovieInfo.backgroundColor = [UIColor blackColor];
			containerForMovieInfo.alpha = 0.7f;
			
			// Movie icon on left side
			CGRect movieFrame = CGRectMake(AGIPC_MOVIE_LEFT_MARGIN, 0, AGIPC_MOVIE_WIDTH, AGIPC_MOVIE_HEIGHT);
			UIImageView *movieImageView = [[[UIImageView alloc] initWithFrame:movieFrame] autorelease];
            movieImageView.image = [UIImage imageNamed:@"AGIPC-Movie"];
			[containerForMovieInfo addSubview:movieImageView];
			
			// Movie duration on right side
			if ([theAsset valueForProperty:ALAssetPropertyDuration] != ALErrorInvalidProperty) {
				NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
				[formatter setDateFormat:@"mm:ss"];
				CGRect durationFrame = CGRectMake(frame.size.width - AGIPC_MOVIE_WIDTH - AGIPC_MOVIE_LEFT_MARGIN, 0, AGIPC_MOVIE_WIDTH, AGIPC_MOVIE_HEIGHT);
				UILabel *durationView = [[[UILabel alloc] initWithFrame:durationFrame] autorelease];
				durationView.backgroundColor = [UIColor clearColor];
				durationView.textColor = [UIColor whiteColor];
				durationView.text = [formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:[[theAsset valueForProperty:ALAssetPropertyDuration] doubleValue]]];
				durationView.font = [UIFont systemFontOfSize:10];
				[containerForMovieInfo addSubview:durationView];
			}
			
			[self addSubview:containerForMovieInfo];
		}
		
		
		
		
		
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)] ;
        self.selectionView = view;
        self.selectionView.backgroundColor = [UIColor whiteColor];
        self.selectionView.alpha = .5f;
        self.selectionView.hidden = !self.selected;
        [self addSubview:self.selectionView];
		[view release];
		
        // Position the checkmark image in the bottom right corner
        self.checkmarkImageView = [[[UIImageView alloc] initWithFrame:checkmarkFrame] autorelease];
        self.checkmarkImageView.image = [UIImage imageNamed:@"AGIPC-Checkmark"];
        self.checkmarkImageView.hidden = !self.selected;
		[self addSubview:self.checkmarkImageView];
        
        self.asset = theAsset;
    }
    
    return self;
}

#pragma mark - Others

- (void)tap
{
    self.selected = !self.selected;
}

#pragma mark - Private

+ (void)resetNumberOfSelections
{
    numberOfSelectedGridItems = 0;
}

+ (NSUInteger)numberOfSelections
{
    return numberOfSelectedGridItems;
}

@end
