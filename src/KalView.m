/* 
 * Copyright (c) 2009 Keith Lazuka
 * License: http://www.opensource.org/licenses/mit-license.html
 */

#import "KalView.h"
#import "KalGridView.h"
#import "KalLogic.h"
#import "KalPrivate.h"
#import "KalDate.h"

@interface KalView ()
- (void)addSubviewsToHeaderView:(UIView *)headerView;
- (void)addSubviewsToContentView:(UIView *)contentView;
- (void)setHeaderTitleText:(NSString *)text;

@property (nonatomic, readwrite) UITableView *tableView;
@end

//static const CGFloat kHeaderHeight = 44.f;
static const CGFloat kHeaderHeight = 66.f;
static const CGFloat kMonthLabelHeight = 17.f;

@implementation KalView

static float kFrameWidth=300.0;
static float kGridTileWidth=43.0;

@synthesize delegate, tableView, shadowView, gridView;

/*
 - (id)initWithCoder:(NSCoder *)aDecoder { 
 return [self initWithFrame:self.frame delegate:delegate logic:logic]; 
 }*/
- (void)finalizeInit {
	[[KalLogic sharedLogic] addObserver:self forKeyPath:@"selectedMonthNameAndYear" options:NSKeyValueObservingOptionNew context:NULL];
	self.autoresizesSubviews = YES;
	
        CGFloat frameWidth = 0.f;
	CGFloat frameHeight = 0.f;
	if (isIpadDevice()) {
		frameWidth = kFrameWidth;//322.f;
		frameHeight = 309.f;
	}
	else {
		frameWidth = self.frame.size.width;
		frameHeight = self.frame.size.height - kHeaderHeight;
		self.autoresizingMask = UIViewAutoresizingFlexibleHeight;
	}
	//NSLog(@"framewidth:%f",frameWidth);

	
	UIView *contentView = [[UIView alloc] initWithFrame:CGRectMake(0.f, kHeaderHeight, frameWidth, frameHeight-kHeaderHeight+kMonthLabelHeight)];
	contentView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
	[self addSubviewsToContentView:contentView];
	[self addSubview:contentView];	
	
	UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, frameWidth, kHeaderHeight)];
	headerView.backgroundColor = [UIColor grayColor];
	[self addSubviewsToHeaderView:headerView];
	[self addSubview:headerView];
}

- (void)awakeFromNib {
	[super awakeFromNib];
	NSLog(@"awakeFromNib");
	if (!delegate) {
		NSLog(@"KalView doesn't have a delegate!");
	}
	[self finalizeInit];
}	

- (id)initWithFrame:(CGRect)frame delegate:(id<KalViewDelegate>)theDelegate
{
	NSLog(@"initWithFrame");
	if ((self = [super initWithFrame:frame])) {
		delegate = theDelegate;
		[self finalizeInit];
	}
	
	return self;
}

- (id)initWithFrame:(CGRect)frame
{
	delegate = nil;
	[NSException raise:@"Incomplete initializer" format:@"KalView must be initialized with a delegate. Use the initWithFrame:delegate method."];
	return nil;
}

- (void)redrawEntireMonth { [self jumpToSelectedMonth]; }

- (void)slideDown { [gridView slideDown]; }
- (void)slideUp { [gridView slideUp]; }

- (void)showPreviousMonth
{
	if (!gridView.transitioning) {
		if (delegate && [delegate respondsToSelector:@selector(showPreviousMonth)])
			[delegate performSelector:@selector(showPreviousMonth)];
	}
}

- (void)showFollowingMonth
{
	if (!gridView.transitioning)
		if (delegate && [delegate respondsToSelector:@selector(showFollowingMonth)])
			[delegate performSelector:@selector(showFollowingMonth)];
}

- (void)addSubviewsToHeaderView:(UIView *)theHeader
{
	const CGFloat kChangeMonthButtonWidth = 46.0f;
	const CGFloat kChangeMonthButtonHeight = 46.0f;
	const CGFloat kMonthLabelWidth = 200.0f;
	const CGFloat kHeaderVerticalAdjust = 6.f;
	
	// Header background gradient
	//UIImageView *backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Kal.bundle/kal_grid_background.png"]];
	UIImageView *backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cal-header-under.png"]];
	CGRect imageFrame = theHeader.frame;
	imageFrame.origin = CGPointZero;
	backgroundView.frame = imageFrame;
	[theHeader addSubview:backgroundView];
	
	UIImageView *headerBarView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"header-zigzag-50h.png"]];
	
	imageFrame = CGRectMake(0, 0, 300, 50.0);//theHeader.frame;
	imageFrame.origin = CGPointZero;
	headerBarView.frame = imageFrame;
	[theHeader addSubview:headerBarView];
	
		
	// Draw the selected month name centered and at the top of the view

	CGRect monthLabelFrame = CGRectMake((theHeader.width/2.0f) - (kMonthLabelWidth/2.0f),
										kHeaderVerticalAdjust,
										kMonthLabelWidth,
										kMonthLabelHeight);
	headerTitleLabel = [[UILabel alloc] initWithFrame:monthLabelFrame];
	headerTitleLabel.backgroundColor = [UIColor clearColor];
	headerTitleLabel.font = [UIFont fontWithName:@"HelveticaNeue-CondensedBold" size:22.f];
	headerTitleLabel.textAlignment = UITextAlignmentCenter;
	headerTitleLabel.textColor = [UIColor whiteColor];//[UIColor colorWithPatternImage:[UIImage imageNamed:@"Kal.bundle/kal_header_text_fill.png"]];
	headerTitleLabel.shadowColor = [UIColor grayColor];
	headerTitleLabel.shadowOffset = CGSizeMake(0.f, 0.1f);
	[self setHeaderTitleText:[[KalLogic sharedLogic] selectedMonthNameAndYear]];
	[theHeader addSubview:headerTitleLabel];
	
	// Create the next month button on the right side of the view
	CGRect nextMonthButtonFrame = CGRectMake(theHeader.width - kChangeMonthButtonWidth,
											 0,
											 kChangeMonthButtonWidth,
											 kChangeMonthButtonHeight);
	UIButton *nextMonthButton = [[UIButton alloc] initWithFrame:nextMonthButtonFrame];
	[nextMonthButton setImage:[UIImage imageNamed:@"cal-next-month.png"] forState:UIControlStateNormal];
	nextMonthButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
	nextMonthButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
	[nextMonthButton addTarget:self action:@selector(showFollowingMonth) forControlEvents:UIControlEventTouchUpInside];
	[theHeader addSubview:nextMonthButton];
	
	// Add column labels for each weekday (adjusting based on the current locale's first weekday)

	NSArray *weekdayNames = [[[NSDateFormatter alloc] init] shortWeekdaySymbols];
	NSUInteger firstWeekday = [[NSCalendar currentCalendar] firstWeekday];
	NSUInteger i = firstWeekday - 1;
	for (CGFloat xOffset = 0.f; xOffset < theHeader.width; xOffset += kGridTileWidth, i = (i+1)%7) {
		CGRect weekdayFrame = CGRectMake(xOffset, kHeaderHeight - 29.f, kGridTileWidth, kHeaderHeight - 29.f);
		UILabel *weekdayLabel = [[UILabel alloc] initWithFrame:weekdayFrame];
		weekdayLabel.backgroundColor = [UIColor clearColor];
		weekdayLabel.font = [UIFont boldSystemFontOfSize:10.f];
		weekdayLabel.textAlignment = UITextAlignmentCenter;
		weekdayLabel.textColor = [UIColor colorWithRed:0.3f green:0.3f blue:0.3f alpha:1.f];
		weekdayLabel.shadowColor = [UIColor whiteColor];
		weekdayLabel.shadowOffset = CGSizeMake(0.f, 1.f);
		weekdayLabel.text = [[weekdayNames objectAtIndex:i] uppercaseString];
		[theHeader addSubview:weekdayLabel];
	}

	
	
	// Create the previous month button on the left side of the view

	CGRect previousMonthButtonFrame = CGRectMake(theHeader.left,
												 0,
												 kChangeMonthButtonWidth,
												 kChangeMonthButtonHeight);
	UIButton *previousMonthButton = [[UIButton alloc] initWithFrame:previousMonthButtonFrame];
	[previousMonthButton setImage:[UIImage imageNamed:@"cal-prev-month.png"] forState:UIControlStateNormal];
	previousMonthButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
	previousMonthButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
	[previousMonthButton addTarget:self action:@selector(showPreviousMonth) forControlEvents:UIControlEventTouchUpInside];
	[theHeader addSubview:previousMonthButton];

	
	
	
}

- (void)addSubviewsToContentView:(UIView *)contentView
{
	// Both the tile grid and the list of events will automatically lay themselves
	// out to fit the # of weeks in the currently displayed month.
	// So the only part of the frame that we need to specify is the width.
	CGRect fullWidthAutomaticLayoutFrame =CGRectMake(0.f, 0.f, kFrameWidth, 0.f);// CGRectMake(0.f, 0.f, 322, 0.f);
	
	//CGRect fullWidthAutomaticLayoutGridFrame =CGRectMake(3.f, 0.f, kGridWidth, 0.f);// CGRectMake(0.f, 0.f, 322, 0.f);
	// The tile grid (the calendar body)
	gridView = [[KalGridView alloc] initWithFrame:fullWidthAutomaticLayoutFrame delegate:delegate];
	[gridView addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:NULL];
	[contentView addSubview:gridView];
	
	// The list of events for the selected day
	if (!self.tableView) {
		self.tableView = [[UITableView alloc] initWithFrame:fullWidthAutomaticLayoutFrame style:UITableViewStylePlain];
		self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		[contentView addSubview:self.tableView];
	}
	
	// Drop shadow below tile grid and over the list of events for the selected day
	if (!self.shadowView) {
		self.shadowView = [[UIImageView alloc] initWithFrame:fullWidthAutomaticLayoutFrame];
		self.shadowView.image = [UIImage imageNamed:@"cal-bottom.png"];
		self.shadowView.height = shadowView.image.size.height;
		[contentView addSubview:self.shadowView];
	}
	
	// Trigger the initial KVO update to finish the contentView layout
	[gridView sizeToFit];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (object == gridView && [keyPath isEqualToString:@"frame"]) {
		
		/* Animate tableView filling the remaining space after the
		 * gridView expanded or contracted to fit the # of weeks
		 * for the month that is being displayed.
		 *
		 * This observer method will be called when gridView's height
		 * changes, which we know to occur inside a Core Animation
		 * transaction. Hence, when I set the "frame" property on
		 * tableView here, I do not need to wrap it in a
		 * [UIView beginAnimations:context:].
		 */
		if (isIpadDevice()) {
			self.shadowView.height = kHeaderHeight + gridView.top + gridView.height;
		}
		else {
			CGFloat gridBottom = gridView.top + gridView.height;
			CGRect frame = self.tableView.frame;
			frame.origin.y = gridBottom;
			frame.size.height = tableView.superview.height - gridBottom;
			self.tableView.frame = frame;
			self.shadowView.top = gridBottom;
		}
		
	} else if ([keyPath isEqualToString:@"selectedMonthNameAndYear"]) {
		[self setHeaderTitleText:[change objectForKey:NSKeyValueChangeNewKey]];
		
	} else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

- (void)setHeaderTitleText:(NSString *)text
{
	[headerTitleLabel setText:text];
	if (!isIpadDevice()) {
		[headerTitleLabel sizeToFit];
		headerTitleLabel.left = floorf(self.width/2.f - headerTitleLabel.width/2.f);
	}
}

- (void)jumpToSelectedMonth { [gridView jumpToSelectedMonth]; }

- (void)selectDate:(KalDate *)date { [gridView selectDate:date]; }

- (BOOL)isSliding { return gridView.transitioning; }

- (void)markTilesForDates:(NSArray *)dates { [gridView markTilesForDates:dates]; }

- (KalDate *)selectedDate { return gridView.selectedDate; }

- (void)dealloc
{
	[[KalLogic sharedLogic] removeObserver:self forKeyPath:@"selectedMonthNameAndYear"];
	[gridView removeObserver:self forKeyPath:@"frame"];
}

@end
