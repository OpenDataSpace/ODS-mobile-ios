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
 *
 * ***** END LICENSE BLOCK ***** */

//
//  MultiSelectActionsToolbar.m
//

#import "MultiSelectActionsToolbar.h"
#import "MultiSelectActionItem.h"
#import "Utility.h"

/**
 * Private methods
 */
@interface MultiSelectActionsToolbar ()

@property (nonatomic, retain) NSMutableOrderedSet *actionItems;
@property (nonatomic, retain) UIButton *cancelButton;
@property (nonatomic, retain) NSMutableArray *selectedItems;
@property (nonatomic, retain) NSMutableArray *selectedIndexPaths;
@property (nonatomic, retain) UITabBarController *tabBarController;

@end

/**
 * Implementation
 */
@implementation MultiSelectActionsToolbar

@synthesize multiSelectDelegate = _multiSelectDelegate;
@synthesize actionItems = _actionItems;
@synthesize cancelButton = _cancelButton;
@synthesize selectedItems = _selectedItems;
@synthesize selectedIndexPaths = _selectedIndexPaths;
@synthesize tabBarController = _tabBarController;

- (id)init
{
    // Disallow
    return nil;
}

- (id)initWithParentViewController:(UIViewController *)viewController
{
    self = [super init];
    if (self)
    {
        self.alpha = 0;
        self.barStyle = UIBarStyleDefault;

        // Find the tabBarController
        if ([viewController isKindOfClass:[UITabBarController class]])
        {
            [self setTabBarController:(UITabBarController *)viewController];
        }
        else
        {
            [self setTabBarController:viewController.tabBarController];
        }

        // Set the toolbar to fit the width of the app.
        [self sizeToFit];
        
        CGFloat toolbarHeight = [self frame].size.height;
        CGRect rootViewBounds = self.tabBarController.view.bounds;
        CGFloat rootViewHeight = CGRectGetHeight(rootViewBounds);
        CGFloat rootViewWidth = CGRectGetWidth(rootViewBounds);
        CGRect rectArea = CGRectMake(0, rootViewHeight - toolbarHeight, rootViewWidth, toolbarHeight);

        [self setFrame:rectArea];
        
        [self.tabBarController.view addSubview:self];
        
        NSMutableOrderedSet *actionItems = [[NSMutableOrderedSet alloc] initWithCapacity:2];
        [self setActionItems:actionItems];
        [actionItems release];
        
        NSMutableArray *selectedItems = [[NSMutableArray alloc] init];
        [self setSelectedItems:selectedItems];
        [selectedItems release];
        
        NSMutableArray *selectedIndexPaths = [[NSMutableArray alloc] init];
        [self setSelectedIndexPaths:selectedIndexPaths];
        [selectedIndexPaths release];
}
    return self;
}


#pragma mark - Dealloc

- (void)dealloc
{
    [self removeFromSuperview];

	[_actionItems release];
    [_cancelButton release];
    [_selectedItems release];
    [_selectedIndexPaths release];
    [_tabBarController release];

    [super dealloc];
}

#pragma mark - Private instance methods

- (void)notifyDelegateItemsDidChange
{
    if (self.multiSelectDelegate && [(id)self.multiSelectDelegate respondsToSelector:@selector(multiSelectItemsDidChange:items:)])
    {
        [self.multiSelectDelegate multiSelectItemsDidChange:self items:[NSArray arrayWithArray:self.selectedItems]];
    }
}

- (void)notifyDelegateUserDidPerformAction:(MultiSelectActionItem *)item
{
    if (self.multiSelectDelegate && [(id)self.multiSelectDelegate respondsToSelector:@selector(multiSelectUserDidPerformAction:named:withItems:atIndexPaths:)])
    {
        [self.multiSelectDelegate multiSelectUserDidPerformAction:self named:item.name withItems:self.selectedItems atIndexPaths:self.selectedIndexPaths];
    }
}

- (UIBarButtonItem *)createButton:(NSString *)name withLabelKey:(NSString *)labelKey atIndex:(NSUInteger)index isDestructive:(BOOL)destructive
{
    // Create helper class
    MultiSelectActionItem *item = [[MultiSelectActionItem alloc] init];
    item.name = name;
    item.labelKey = labelKey;
    item.index = index;
    item.isDestructive = destructive;
    
    // Create a button
    UIBarButtonItem *button = [[[UIBarButtonItem alloc] initWithTitle:[item labelWithCounterValue:0]
                                                               style:UIBarButtonItemStyleBordered
                                                              target:self
                                                              action:@selector(performButtonAction:)] autorelease];
    [button setPossibleTitles:[NSSet setWithObjects:[item labelWithCounterValue:0], [item labelWithCounterValue:100], nil]];
    [button setEnabled:NO];
    if (destructive)
    {
        styleButtonAsDestructiveAction(button);
    }
    item.button = button;

    [self.actionItems insertObject:item atIndex:index];
    [item release];
    return button;
}

- (NSString *)labelForButtonNamed:(NSString *)name counterValue:(NSUInteger)counter
{
    MultiSelectActionItem *item = [self itemWithName:name];
    return [item labelWithCounterValue:counter];
}

- (MultiSelectActionItem *)itemWithName:(NSString *)name
{
    for (MultiSelectActionItem *item in self.actionItems)
    {
        if ([item.name isEqualToCaseInsensitiveString:name])
        {
            return item;
        }
    }
    return nil;
}

- (MultiSelectActionItem *)itemFromButton:(UIBarButtonItem *)button;
{
    for (MultiSelectActionItem *item in self.actionItems)
    {
        if ([item.button isEqual:button])
        {
            return item;
        }
    }
    return nil;
}

- (NSArray *)itemButtons
{
    NSMutableArray *buttons = [[[NSMutableArray alloc] initWithCapacity:[self.actionItems count]] autorelease];
    for (MultiSelectActionItem *item in self.actionItems)
    {
        [buttons addObject:item.button];
    }
    return buttons;
}

- (void)updateItemButtonLabels
{
    NSUInteger nSelectedItems = [self.selectedItems count];
    for (MultiSelectActionItem *item in self.actionItems)
    {
        [item setButtonTitleWithCounterValue:nSelectedItems];
    }
}

- (void)disableItemButtons
{
    for (MultiSelectActionItem *item in self.actionItems)
    {
        [item.button setEnabled:NO];
    }
}

- (void)performButtonAction:(id)sender
{
    MultiSelectActionItem *item = [self itemFromButton:sender];
    if (item != nil)
    {
        [self notifyDelegateUserDidPerformAction:item];
    }
}


#pragma mark - Public instance methods

- (void)didEnterMultiSelectMode
{
    [self didEnterMultiSelectModeFromSearchView:NO];
}

- (void)didEnterMultiSelectModeFromSearchView:(BOOL)searchViewIsActive
{
    [self.selectedItems removeAllObjects];
    [self.selectedIndexPaths removeAllObjects];
    [self updateItemButtonLabels];
    [self disableItemButtons];

    [UIView beginAnimations:@"multiselect" context:nil];
    self.tabBarController.tabBar.frame = CGRectOffset(self.tabBarController.tabBar.frame, 0, +self.tabBarController.tabBar.frame.size.height);
    self.tabBarController.tabBar.alpha = 0;
    self.alpha = 1;
    [UIView commitAnimations];
}

- (void)didLeaveMultiSelectMode
{
    [UIView beginAnimations:@"multiselect" context:nil];
    self.tabBarController.tabBar.frame = CGRectOffset(self.tabBarController.tabBar.frame, 0, -self.tabBarController.tabBar.frame.size.height);
    self.tabBarController.tabBar.alpha = 1;
    self.alpha = 0;
    [UIView commitAnimations];
}

- (void)addActionButtonNamed:(NSString *)name withLabelKey:(NSString *)labelKey atIndex:(NSUInteger)index
{
    if ([self createButton:name withLabelKey:labelKey atIndex:index isDestructive:NO] != nil)
    {
        [self setItems:[self itemButtons]];
    }
}

- (void)addActionButtonNamed:(NSString *)name withLabelKey:(NSString *)labelKey atIndex:(NSUInteger)index isDestructive:(BOOL)destructiveAction
{
    if ([self createButton:name withLabelKey:labelKey atIndex:index isDestructive:destructiveAction] != nil)
    {
        [self setItems:[self itemButtons]];
    }
}

- (void)enableActionButtonNamed:(NSString *)name isEnabled:(BOOL)enabled
{
    MultiSelectActionItem *item = [self itemWithName:name];
    if (item != nil)
    {
        [item.button setEnabled:enabled];
    }
}

- (void)userDidSelectItem:(id)item atIndexPath:(NSIndexPath *)indexPath
{
    [self.selectedItems addObject:item];
    [self.selectedIndexPaths addObject:indexPath];
    [self updateItemButtonLabels];
    [self notifyDelegateItemsDidChange];
}

- (void)userDidDeselectItem:(id)item atIndexPath:(NSIndexPath *)indexPath
{
    [self.selectedItems removeObject:item];
    [self.selectedIndexPaths removeObject:indexPath];
    [self updateItemButtonLabels];
    [self notifyDelegateItemsDidChange];
}

- (void)removeAllSelectedItems
{
    [self.selectedItems removeAllObjects];
}

@end
