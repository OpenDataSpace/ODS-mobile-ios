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
 * Portions created by the Initial Developer are Copyright (C) 2011-2012
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
#import "FileUtils.h"

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
static UIColor const *kRecordButtonColor;
static UIColor const *kRecordButtonRecordingColor;
static UIColor const *kPlayButtonColor;
static UIColor const *kDisabledColor;
#define LABEL_FONT [UIFont boldSystemFontOfSize:17.0f]

- (void)dealloc
{
    [self clearAudioSession];
    [recorder setDelegate:nil];
    [player setDelegate:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[label release];
	[key release];
	[model release];
	[backgroundColor release];	
	[cellIndexPath release];
    [player release];
    [recorder release];
    [playButton release];
    [recordButton release];
	[super dealloc];
}

+ (void)initialize {
    kRecordButtonColor = [UIColor redColor];
    kRecordButtonRecordingColor = [UIColor greenColor];
    kPlayButtonColor = [UIColor greenColor];
    kDisabledColor = [UIColor lightGrayColor];
    
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
        [playButton addTarget:self action:@selector(performPlay:) forControlEvents:UIControlEventTouchUpInside];
        playButton.enabled = NO;
        self.recordButton =[UIButton buttonWithType:UIButtonTypeRoundedRect];
        [recordButton setTitle:NSLocalizedString(@"audiorecord.record", @"Record") forState:UIControlStateNormal];
        [recordButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [recordButton addTarget:self action:@selector(performRecord:) forControlEvents:UIControlEventTouchUpInside];
        
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
        //[recordButton useRedDeleteStyle];
        playButton.enabled = YES;
        //[playButton useGreenConfirmStyle];
        recorded = YES;
    }
    
    if(player && player.isPlaying) {
        [player stop];
        self.player = nil;
        
        [[AVAudioSession sharedInstance] setActive: NO error: nil];
        [playButton setTitle:NSLocalizedString(@"audiorecord.play", @"Play") forState:UIControlStateNormal];
        recordButton.enabled = YES;
        //[recordButton useRedDeleteStyle];
    }
}

-(void)performRecord:(id)sender {
    [recordButton performSelector:@selector(setSelected:) withObject:[NSNumber numberWithBool:YES] afterDelay:1];
    [recordButton setEnabled:NO];
    [self performSelectorInBackground:@selector(recordOrStop:) withObject:sender];
}

-(void)stopRecording {
    //If we try to release the recorder in a background thread we get a memory error
    self.recorder = nil;
    [recordButton setTitle:NSLocalizedString(@"audiorecord.record", @"Record") forState:UIControlStateNormal];
    playButton.enabled = YES;
    recorded = YES;
    NSString *recordPath = [FileUtils pathToTempFile:kACCTempFilename];
    [model setObject:[NSURL fileURLWithPath:recordPath] forKey:key];
    [recordButton setEnabled:YES];
}

-(void)changeRecordLabel:(NSString *)recordLabel {
    [recordButton setTitle:recordLabel forState:UIControlStateNormal];
    [recordButton setNeedsDisplay];
}

-(void)recordOrStop:(id)sender {
    if(self.recorder && self.recorder.isRecording) {
        [recorder stop];
        [[AVAudioSession sharedInstance] setActive: NO error: nil];
        [self performSelectorOnMainThread:@selector(stopRecording) withObject:nil waitUntilDone:NO];
    } else {
        NSError *error = nil;
        [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryRecord error: &error];
        if(error) {
            AlfrescoLogDebug(@"Error trying to start audio session: %@", error.localizedDescription);
            return;
        }
        
        NSString *recordPath = [FileUtils pathToTempFile:kACCTempFilename];
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
            //[recordButton useRedDeleteStyle];
            AlfrescoLogDebug(@"Error trying to record audio: %@", error.description);
            [[AVAudioSession sharedInstance] setActive: NO error: nil];
        } else {            
            self.recorder.delegate = self;
            [self.recorder prepareToRecord];
            [self.recorder record];
            
            playButton.enabled = NO;
            [self performSelectorOnMainThread:@selector(changeRecordLabel:) withObject:NSLocalizedString(@"audiorecord.stop", @"Stop") waitUntilDone:NO];
        }
        
        [recordButton setEnabled:YES];
    }
}

-(void)performPlay:(id)sender {
    [playButton setEnabled:NO];
    [self performSelectorInBackground:@selector(playOrStop:) withObject:sender];
}

-(void)changePlayLabel:(NSString *)playLabel {
    [playButton setTitle:playLabel forState:UIControlStateNormal];
    [playButton setNeedsDisplay];
}

-(void)playOrStop:(id)sender {
    NSURL *videoUrl     = [model objectForKey:key];
    
    if(player && player.isPlaying) {
        [player stop];
        self.player = nil;
        
        [[AVAudioSession sharedInstance] setActive: NO error: nil];
        [self performSelectorOnMainThread:@selector(changePlayLabel:) withObject:NSLocalizedString(@"audiorecord.play", @"Play")waitUntilDone:NO];
        recordButton.enabled = YES;
        //[((IFGenericTableViewController *)tableController) updateAndRefresh];
    } else if([[NSFileManager defaultManager] fileExistsAtPath:[videoUrl path]]) {
        NSError *error = nil;
        [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback error: &error];
        if(error) {
            AlfrescoLogDebug(@"Error trying to start audio session: %@", error.localizedDescription);
            [playButton setEnabled:YES];
            return;
        }
        
        AVAudioPlayer *newPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:videoUrl error:&error];
        newPlayer.delegate = self;
        self.player = newPlayer;
        [newPlayer release];
        
        if(error) {
            AlfrescoLogDebug(@"Error trying to play audio: %@", error.description);
        } else {
            [self performSelectorOnMainThread:@selector(changePlayLabel:) withObject:NSLocalizedString(@"audiorecord.stop", @"Stop")waitUntilDone:NO];
            recordButton.enabled = NO;
            [self.player play];
            [recordButton setNeedsDisplay];
            //[((IFGenericTableViewController *)tableController) updateAndRefresh];
        }
    }
    
    [playButton setEnabled:YES];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	self.cellIndexPath = indexPath;
	self.tableController = (UITableViewController *)tableView.dataSource;
	
	static NSString *cellIdentifier = @"AudioDataCell";
	IFControlTableViewCell* cell = (IFControlTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (nil == cell)
	{
		cell = [[[IFControlTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
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
        [playButton setNeedsDisplay];
        self.player = nil;
        recordButton.enabled = YES;
    }
}

-(void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player 
                                error:(NSError *)error {
    AlfrescoLogDebug(@"Decode Error occurred");
}

#pragma mark - AVAudioRecorderDelegate methods
-(void)audioRecorderDidFinishRecording: (AVAudioRecorder *)recorder successfully:(BOOL)flag{
}

-(void)audioRecorderEncodeErrorDidOccur:
(AVAudioRecorder *)recorder 
                                  error:(NSError *)error
{
    AlfrescoLogDebug(@"Encode Error occurred");
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
		AlfrescoLogDebug(@"unable to become first responder");
	}
}

-(void)resignFirstResponder
{
	AlfrescoLogDebug(@"resign first responder is noop for photo cells");
}

- (void)controllerWillBeDismissed:(IFGenericTableViewController *)sender
{
    [self clearAudioSession];
}

@end
