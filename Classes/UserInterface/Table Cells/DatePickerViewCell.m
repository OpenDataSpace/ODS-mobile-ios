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
//  DatePickerViewCell.m
//

#import "DatePickerViewCell.h"

@implementation DatePickerViewCell

@synthesize datePicker = _datePicker;

- (void)dealloc
{
    [_datePicker release];
    [super dealloc];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (!self)
    {
        return nil; 
    }
    
    if (IS_IPAD)
    {
        self.datePicker = [[[UIDatePicker alloc] initWithFrame:CGRectMake(80, 15, 325, 250)] autorelease];
    }
    else 
    {
        self.datePicker = [[[UIDatePicker alloc] initWithFrame:CGRectMake(0, 15, 325, 250)] autorelease];
    }
    self.datePicker.datePickerMode = UIDatePickerModeDate;
    self.datePicker.hidden = NO;
    self.datePicker.date = [NSDate date];
    [self.contentView addSubview:self.datePicker];
    
    return self;
}

@end
