//
//  LinkTableViewCell.h
//  FreshDocs
//
//  Created by bdt on 6/9/14.
//
//

#import <UIKit/UIKit.h>

@interface LinkTableViewCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *lblLinkName;
@property (nonatomic, weak) IBOutlet UILabel *lblLinkExpirationDate;
@property (nonatomic, weak) IBOutlet UILabel *lblLinkURL;
@end
