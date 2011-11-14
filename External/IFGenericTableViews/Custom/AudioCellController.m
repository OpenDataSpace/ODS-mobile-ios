/* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is the Alfresco Mobile App.
 *
 * The Initial Developer of the Original Code is Zia Consulting, Inc.
 * Portions created by the Initial Developer are Copyright (C) 2011
 * the Initial Developer. All Rights Reserved.
 *
 *
 * ***** END LICENSE BLOCK ***** */
//
//  AudioCellController.m
//

#import "AudioCellController.h"
#import "IFGenericTableViewController.h"
#import "IFControlTableViewCell.h"
#import "SavedDocument.h"

@implementation AudioCellController
@synthesize backgroundColor;
@synthesize selectionStyle;
@synthesize accessoryType;
@synthesize updateTarget, updateAction;
@synthesize indentationLevel;
@synthesize cellControllerFirstResponderHost, tableController, cellIndexPath;
@synthesize maxWidth;
@synthesize player;
@synthesize recorder;
@synthesize playButton;
@synthesize recordButton;

NSString * const kACCTempFilename = @"record.m4a";
CGFloat const kACCGutter = 10.0f;
#define LABEL_FONT [UIFont boldSystemFontOfSize:17.0f]

- (void)dealloc
{
	[label release];
	[key release];
	[model release];
	[backgroundColor release];	
	[tableController release];
	[cellIndexPath release];
    [player release];
    [recorder release];
    [playButton release];
    [recordButton release];
	[super dealloc];
}

- (id)initWithLabel:(NSString *)newLabel atKey:(NSString *)newKey inModel:(id<IFCellModel>)newModel;
{
	self = [super init];
	if (self != nil)
	{
		label = [newLabel retain];
		key = [newKey retain];
		model = [newModel retain];
		
		backgroundColor = nil;
		selectionStyle = UITableViewCellSelectionStyleNone;
        accessoryType = UITableViewCellAccessoryNone;
		indentationLevel = 0;
		
		autoAdvance = NO;
        self.playButton =[UIButton buttonWithType:UIButtonTypeRoundedRect];
        [playButton setTitle:NSLocalizedString(@"audiorecord.play", @"Play") forState:UIControlStateNormal];
        [playButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [playButton addTarget:self action:@selector(playOrStop:) forControlEvents:UIControlEventTouchUpInside];
        playButton.enabled = NO;
        self.recordButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [recordButton setTitle:NSLocalizedString(@"audiorecord.record", @"Record") forState:UIControlStateNormal];
        [recordButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [recordButton addTarget:self action:@selector(recordOrStop:) forControlEvents:UIControlEventTouchUpInside];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clearAudioSession) name:UIApplicationWillResignActiveNotification object:nil];
	}
	return self;
}

- (void) clearAudioSession {
    if(recorder && recorder.isRecording) {
        [recorder stop];
        self.recorder = nil;
        
        [[AVAudioSession sharedInstance] setActive: NO error: nil];
        [recordButton setTitle:NSLocalizedString(@"audiorecord.record", @"Record") forState:UIControlStateNormal];
        playButton.enabled = YES;
        recorded = YES;
    }
    
    if(player && player.isPlaying) {
        [player stop];
        self.player = nil;
        
        [[AVAudioSession sharedInstance] setActive: NO error: nil];
        [playButton setTitle:NSLocalizedString(@"audiorecord.play", @"Play") forState:UIControlStateNormal];
        recordButton.enabled = YES;
    }
}

-(void)recordOrStop:(id)sender {
    if(recorder && recorder.isRecording) {
        [recorder stop];
        self.recorder = nil;
        
        [[AVAudioSession sharedInstance] setActive: NO error: nil];
        [recordButton setTitle:NSLocalizedString(@"audiorecord.record", @"Record") forState:UIControlStateNormal];
        playButton.enabled = YES;
        recorded = YES;
        NSString *recordPath = [SavedDocument pathToTempFile:kACCTempFilename];
        [model setObject:[NSURL URLWithString:recordPath] forKey:key];
    } else {
        NSError *error = nil;
        [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryRecord error: &error];
        if(error) {
            NSLog(@"Error trying to start audio session: %@", error.localizedDescription);
            return;
        }
        
        NSString *recordPath = [SavedDocument pathToTempFile:kACCTempFilename];
        NSDictionary *recordSettings =
        [[NSDictionary alloc] initWithObjectsAndKeys:
         [NSNumber numberWithFloat: 44100.0], AVSampleRateKey,
         [NSNumber numberWithInt: kAudioFormatMPEG4AAC], AVFormatIDKey,
         [NSNumber numberWithInt: 1], AVNumberOfChannelsKey,
         [NSNumber numberWithInt: AVAudioQualityMax],
         AVEncoderAudioQualityKey,
         nil];
        
        AVAudioRecorder *newRecorder =
        [[AVAudioRecorder alloc] initWithURL: [NSURL fileURLWithPath:recordPath]
                                    settings: recordSettings
                                       error: &error];
        
        self.recorder = newRecorder;
        [newRecorder release];
        [recordSettings release];
        
        if(error) {
            NSLog(@"Error trying to record audio: %@", error.description);
            [[AVAudioSession sharedInstance] setActive: NO error: nil];
        } else {
            self.recorder.delegate = self;
            [self.recorder prepareToRecord];
            [self.recorder record];
            
            [recordButton setTitle:NSLocalizedString(@"audiorecord.stop", @"Stop") forState:UIControlStateNormal];
            playButton.enabled = NO;
        }
    }
}

-(void)playOrStop:(id)sender {
    NSURL *videoUrl     = [model objectForKey:key];
    
    if(player && player.isPlaying) {
        [player stop];
        self.player = nil;
        
        [[AVAudioSession sharedInstance] setActive: NO error: nil];
        [playButton setTitle:NSLocalizedString(@"audiorecord.play", @"Play") forState:UIControlStateNormal];
        recordButton.enabled = YES;
        [((IFGenericTableViewController *)tableController) updateAndRefresh];
    } else if([[NSFileManager defaultManager] fileExistsAtPath:[videoUrl absoluteString]]) {
        NSError *error = nil;
        [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback error: &error];
        if(error) {
            NSLog(@"Error trying to start audio session: %@", error.localizedDescription);
            return;
        }
        
        AVAudioPlayer *newPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[videoUrl absoluteString]] error:&error];
        newPlayer.delegate = self;
        self.player = newPlayer;
        [newPlayer release];
        
        if(error) {
            NSLog(@"Error trying to play audio: %@", error.description);
        } else {
            [playButton setTitle:NSLocalizedString(@"audiorecord.stop", @"Stop") forState:UIControlStateNormal];
            recordButton.enabled = NO;
            [self.player play];
            [((IFGenericTableViewController *)tableController) updateAndRefresh];
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	self.cellIndexPath = indexPath;
	self.tableController = (UITableViewController *)tableView.dataSource;
	
	static NSString *cellIdentifier = @"AudioDataCell";
	IFControlTableViewCell* cell = (IFControlTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (nil == cell)
	{
		cell = [[[IFControlTableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:cellIdentifier] autorelease];
		if (nil != backgroundColor) [cell setBackgroundColor:backgroundColor];
		cell.clipsToBounds = YES;
		cell.textLabel.font = LABEL_FONT;
        cell.accessoryType = UITableViewCellAccessoryNone;
	}
	
	cell.indentationLevel = indentationLevel;
	cell.textLabel.text = label;
	cell.selectionStyle = selectionStyle;
    
    CGFloat height = cell.bounds.size.height - kACCGutter;
    CGRect  bounds     = [tableView bounds];
    CGSize  labelSize  = [label sizeWithFont:LABEL_FONT];
    CGFloat tableWidth = bounds.size.width;
    CGFloat drawWidth  = (tableWidth * (5.0f/6.0f)) - ((20.0f * indentationLevel) + labelSize.width + (2 * kACCGutter));
    CGRect containerFrame = CGRectMake(0.0f, kACCGutter / 2.0f, drawWidth, height);
    
    recordButton.frame = CGRectMake(0, 0, 90, height);
    playButton.frame = CGRectMake(100, 0, 90, height);
    
    UIView *masterView = [[UIView alloc] initWithFrame:containerFrame];
    [masterView addSubview:recordButton];
    [masterView addSubview:playButton];
    cell.view = masterView;
    [masterView release];
    
    return cell;
}

#pragma mark - AVAudioPlayerDelegate methods
- (void) audioPlayerDidFinishPlaying: (AVAudioPlayer *) player
                        successfully: (BOOL) completed {
    if (completed == YES) {
        [playButton setTitle:NSLocalizedString(@"audiorecord.play", @"Play") forState:UIControlStateNormal];
        self.player = nil;
        [((IFGenericTableViewController *)tableController) updateAndRefresh];
    }
}

-(void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player 
                                error:(NSError *)error {
    NSLog(@"Decode Error occurred");
}

#pragma mark - AVAudioRecorderDelegate methods
-(void)audioRecorderDidFinishRecording: (AVAudioRecorder *)recorder successfully:(BOOL)flag{
}

-(void)audioRecorderEncodeErrorDidOccur:
(AVAudioRecorder *)recorder 
                                  error:(NSError *)error
{
    NSLog(@"Encode Error occurred");
}


#pragma mark IFCellControllerFirstResponder
-(void)assignFirstResponderHost: (NSObject<IFCellControllerFirstResponderHost> *)hostIn
{
	[self setCellControllerFirstResponderHost: hostIn];
}

-(void)becomeFirstResponder
{
	@try {
		autoAdvance = YES;
		[self tableView:(UITableView *)tableController.view didSelectRowAtIndexPath: self.cellIndexPath];
	}
	@catch (NSException *ex) {
		NSLog(@"unable to become first responder");
	}
}

-(void)resignFirstResponder
{
	NSLog(@"resign first responder is noop for photo cells");
}

@end
