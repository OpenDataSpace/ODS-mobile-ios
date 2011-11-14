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
//  AudioCellController.h
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "IFCellController.h"
#import "IFCellFirstResponder.h"
#import "IFCellModel.h"

@interface AudioCellController : NSObject <IFCellController, IFCellControllerFirstResponder, AVAudioPlayerDelegate, AVAudioRecorderDelegate> {
    NSString *label;
	id<IFCellModel> model;
	NSString *key;
	
	UIColor *backgroundColor;
	UITableViewCellSelectionStyle selectionStyle;
    UITableViewCellAccessoryType accessoryType;
	
	SEL updateAction;
	id updateTarget;
	
	NSInteger indentationLevel;
	
	UITableViewController *tableController;
	NSIndexPath *cellIndexPath;
	id<IFCellControllerFirstResponderHost>cellControllerFirstResponderHost;
	
	BOOL autoAdvance;
	CGFloat maxWidth;
    
    //View
    UIButton *recordButton;
    UIButton *playButton;
    //Audio
    AVAudioPlayer	*player;
    AVAudioRecorder *recorder;
    BOOL recorded;
}

@property (nonatomic, retain) UIColor *backgroundColor;
@property (nonatomic, assign) UITableViewCellSelectionStyle selectionStyle;
@property (nonatomic, assign) UITableViewCellAccessoryType accessoryType;

@property (nonatomic, assign) SEL updateAction;
@property (nonatomic, assign) id updateTarget;

@property (nonatomic, assign) NSInteger indentationLevel;

@property (nonatomic, retain) UITableViewController *tableController;
@property (nonatomic, retain) NSIndexPath *cellIndexPath;
@property (nonatomic, assign) id<IFCellControllerFirstResponderHost>cellControllerFirstResponderHost;
@property (nonatomic, assign) CGFloat maxWidth;
@property (nonatomic, retain) UIButton *recordButton;
@property (nonatomic, retain) UIButton *playButton;
@property (nonatomic, retain) AVAudioPlayer	*player;
@property (nonatomic, retain) AVAudioRecorder	*recorder;

- (id)initWithLabel:(NSString *)newLabel atKey:(NSString *)newKey inModel:(id<IFCellModel>)newModel;

@end
