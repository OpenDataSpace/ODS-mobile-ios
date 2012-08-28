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
// UILabel(Utils) 
//

#import <Foundation/Foundation.h>

@interface UILabel (Utils)

// This method changes the font size of this label until the label text
// fits within the bounds of its frame.
// First the 'defaultFontSize' is tried if it fits. If not, the font size is
// decreased until the text fits using that font size, or when 'minFontSize' is reached.
- (void) fitTextToLabelUsingFont:(NSString *)fontName defaultFontSize:(NSInteger)defaultFontSize minFontSize:(NSInteger)minFontSize;

@end
