//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import <UIKit/UIKit.h>

@class SNLInteractionCell;

typedef NS_ENUM(NSInteger, SNLSwipeAction){
	SNLSwipeActionBoth,
    SNLSwipeActionLeft,
	SNLSwipeActionRight
};

typedef NS_ENUM(NSInteger, SNLSwipeAnimation){
	SNLSwipeAnimationDefault,
    SNLSwipeAnimationBounce,
	SNLSwipeAnimationSlide
};

/**
 *  Delegate protocol to handle cell swipe actions.
 */
@protocol SNLInteractionCellActionDelegate <NSObject>

- (void)swipeAction:(SNLSwipeAction)swipeAction onCell:(SNLInteractionCell *)cell;

- (void)buttonActionWithTag:(NSInteger)tag onCell:(SNLInteractionCell *)cell;

@end



@interface SNLInteractionCell : UITableViewCell <UIDynamicAnimatorDelegate>

extern const double SNLToolbarHeight;

/**
 *  Cells delegate to handle swipe actions.
 */
@property (nonatomic, weak) id <SNLInteractionCellActionDelegate> delegate;


@property (nonatomic) UIView *container;

@property (nonatomic) BOOL hasToolbar;
@property (nonatomic) UIToolbar *toolbar;
@property (nonatomic) NSArray *toolbarButtons;

@property (nonatomic) UIView *indicatorLeft;
@property (nonatomic) UIView *indicatorRight;
@property (nonatomic) NSNumber *indicatorWidth;
@property (nonatomic) UIImage *indicatorImageLeft;
@property (nonatomic) UIImage *indicatorImageRight;
@property (nonatomic) UIImage *indicatorImageSuccessLeft;
@property (nonatomic) UIImage *indicatorImageSuccessRight;
@property (nonatomic) UIImageView *indicatorImageViewLeft;
@property (nonatomic) UIImageView *indicatorImageViewRight;

@property (nonatomic) BOOL panSuccesLeft;
@property (nonatomic) BOOL panSuccesRight;
@property (nonatomic) SNLSwipeAnimation swipeAnimationLeft;
@property (nonatomic) SNLSwipeAnimation swipeAnimationRight;

@property (nonatomic) UIView *customSeparatorTop;
@property (nonatomic) UIView *customSeparatorBottom;

@property (nonatomic) UIColor *colorBackground;
@property (nonatomic) UIColor *colorContainer;
@property (nonatomic) UIColor *colorSelected;
@property (nonatomic) UIColor *colorToolbarBarTint;
@property (nonatomic) UIColor *colorToolbarTint;
@property (nonatomic) UIColor *colorIndicator;
@property (nonatomic) UIColor *colorIndicatorSuccess;
@property (nonatomic) UIColor *colorCustomSeparatorTop;
@property (nonatomic) UIColor *colorCustomSeparatorBottom;


- (void)configureSwipeOn:(SNLSwipeAction)side withAnimation:(SNLSwipeAnimation)animation andImage:(UIImage *)image andImageOnSuccess:(UIImage *)imageSuccess;
- (void)buttonPressed:(UIButton *)sender;

@end
