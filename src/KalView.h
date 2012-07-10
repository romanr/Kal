/* 
 * Copyright (c) 2009 Keith Lazuka
 * License: http://www.opensource.org/licenses/mit-license.html
 */

#import <UIKit/UIKit.h>

@class KalGridView, KalDate;
@protocol KalViewDelegate, KalDataSourceCallbacks;

/*
 *    KalView
 *    ------------------
 *
 *    Private interface
 *
 *  As a client of the Kal system you should not need to use this class directly
 *  (it is managed by KalViewController).
 *
 *  KalViewController uses KalView as its view.
 *  KalView defines a view hierarchy that looks like the following:
 *
 *       +-----------------------------------------+
 *       |                header view              |
 *       +-----------------------------------------+
 *       |                                         |
 *       |                                         |
 *       |                                         |
 *       |                 grid view               |
 *       |             (the calendar grid)         |
 *       |                                         |
 *       |                                         |
 *       +-----------------------------------------+
 *       |                                         |
 *       |           table view (events)           |
 *       |                                         |
 *       +-----------------------------------------+
 *
 */
@interface KalView : UIView
{
	UILabel *headerTitleLabel;
	IBOutlet KalGridView *gridView;
	IBOutlet UITableView *tableView;
	IBOutlet UIImageView *shadowView;
	id<KalViewDelegate> __unsafe_unretained delegate;
	BOOL isNib;
}

@property (nonatomic, unsafe_unretained) IBOutlet id<KalViewDelegate> delegate;
@property (nonatomic, readonly) IBOutlet UITableView *tableView;
@property (unsafe_unretained, nonatomic, readonly) KalDate *selectedDate;
@property (nonatomic, retain) UIImageView *shadowView;
@property (nonatomic, readonly) KalGridView *gridView;

- (id)initWithFrame:(CGRect)frame delegate:(id<KalViewDelegate>)delegate;
- (BOOL)isSliding;
- (void)selectDate:(KalDate *)date;
- (void)markTilesForDates:(NSArray *)dates;
- (void)redrawEntireMonth;

// These 3 methods are exposed for the delegate. They should be called 
// *after* the KalLogic has moved to the month specified by the user.
- (void)slideDown;
- (void)slideUp;
- (void)jumpToSelectedMonth;    // change months without animation (i.e. when directly switching to "Today")

@end

#pragma mark -

@class KalDate;

@protocol KalViewDelegate <NSObject>

- (void)showPreviousMonth;
- (void)showFollowingMonth;
- (void)didSelectDate:(KalDate *)date;

@end
