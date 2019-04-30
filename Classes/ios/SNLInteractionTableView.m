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

#import "SNLInteractionTableView.h"


@interface SNLInteractionTableView ()

@property (nonatomic) UILongPressGestureRecognizer *longPress;
@property (nonatomic) NSIndexPath *initialIndexPath;
@property (nonatomic) NSIndexPath *currentIndexPath;
@property (nonatomic) UIImageView *draggingView;
@property (nonatomic) CADisplayLink *scrollDisplayLink;
@property (nonatomic) CGFloat scrollRate;

@property (nonatomic) BOOL orientationDidChange;

@end



@implementation SNLInteractionTableView

@dynamic delegate;

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self initialize];
    }
    return self;
}
- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
    }
    return self;
}
- (id)initWithFrame:(CGRect)frame style:(UITableViewStyle)style {
    self = [super initWithFrame:frame style:style];
    if (self) {
        [self initialize];
    }
    return self;
}
- (void)initialize {
    [self setAllowsMultipleSelection:NO];
    [self setAllowsSelection:YES];
	self.toolbarEnabled = YES;
    
    self.longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
    [self addGestureRecognizer:self.longPress];
    
    // disable separator to prevent rotation bug on bounce animation
	self.customSeparatorEnabled = (self.separatorStyle != UITableViewCellSeparatorStyleNone);
    self.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.separatorColor = [UIColor clearColor];
}


#pragma mark - Functionality

- (void)deselectSelectedRow {
    NSIndexPath *selected = [self indexPathForSelectedRow];
    if (selected) {
        [self.delegate tableView:self willDeselectRowAtIndexPath:selected];
        [self deselectRowAtIndexPath:selected animated:YES];
        [self.delegate tableView:self didDeselectRowAtIndexPath:selected];
    }
}

- (void)reloadRowsAtIndexPaths:(NSArray *)indexPaths andKeepSelection:(BOOL)keepSelection {
    NSIndexPath *selectedRow = [self indexPathForSelectedRow];
    if (!keepSelection) [self deselectSelectedRow];
    
    [self reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
    
    if (selectedRow && keepSelection) {
        [self selectRowAtIndexPath:selectedRow animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
}


#pragma mark - Reorder

- (void)longPress:(UILongPressGestureRecognizer *)gesture {
    CGPoint location = [gesture locationInView:self];
    NSIndexPath *indexPath = [self indexPathForRowAtPoint:location];
    
    long sections = [self numberOfSections];
    int rows = 0;
    for (int i = 0; i < sections; i++) {
        rows += [self numberOfRowsInSection:i];
    }
    
    if ([self indexPathForSelectedRow]) {
        [self deselectSelectedRow];
    }
    
    // cancel gesture if tableView is empty, location is invalid row, dataSource does not allow moving the row or a cell is selected
    if  (rows == 0 ||
		 (! [self.delegate respondsToSelector:@selector(tableView:canMoveRowAtIndexPath:)]) ||
		 (gesture.state == UIGestureRecognizerStateBegan && indexPath == nil) ||
		 (gesture.state == UIGestureRecognizerStateBegan && indexPath && ![self.dataSource tableView:self canMoveRowAtIndexPath:indexPath])
		 ) {
        [self longPressCancel];
        return;
    }
    
    if (gesture.state == UIGestureRecognizerStateBegan) {
		// add observer to cancel gesture on orientation change
		[[NSNotificationCenter defaultCenter] addObserver:self  selector:@selector(orientationChanged:)    name:UIDeviceOrientationDidChangeNotification  object:nil];
		
        UITableViewCell *cell = [self cellForRowAtIndexPath:indexPath];
        [cell setHighlighted:NO animated:NO];
        
        // make an image from the pressed tableview cell
        UIGraphicsBeginImageContextWithOptions(cell.bounds.size, NO, 0);
        [cell.layer renderInContext:UIGraphicsGetCurrentContext()];
        UIImage *cellImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        // create image view to pan around
        if (!self.draggingView) {
            self.draggingView = [[UIImageView alloc] initWithImage:cellImage];
            [self addSubview:self.draggingView];
            CGRect rect = [self rectForRowAtIndexPath:indexPath];
            self.draggingView.frame = CGRectOffset(self.draggingView.bounds, rect.origin.x, rect.origin.y);
            
            // add drop shadow to image and lower opacity
            self.draggingView.layer.masksToBounds = NO;
            self.draggingView.layer.shadowColor = [[UIColor blackColor] CGColor];
            self.draggingView.layer.shadowOffset = CGSizeMake(0, 0);
            self.draggingView.layer.shadowRadius = 4.0;
            self.draggingView.layer.shadowOpacity = 0.7;
            self.draggingView.layer.opacity = 1.0;
            
            // zoom image towards user
            [UIView beginAnimations:@"zoom" context:nil];
            self.draggingView.transform = CGAffineTransformMakeScale(1.1, 1.1);
            self.draggingView.center = CGPointMake(self.center.x, location.y);
            [UIView commitAnimations];
        }
		
        [self beginUpdates];
        
        if ([self.delegate respondsToSelector:@selector(startedReorderAtIndexPath:)]) {
            [self.delegate startedReorderAtIndexPath:indexPath];
        }
        [self toggleCellVisibility:NO forIndexPath:indexPath];
		
        
        self.initialIndexPath = indexPath;
        self.currentIndexPath = indexPath;
        [self endUpdates];
        
        // setup scrolling for cell
        self.scrollDisplayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(scrollTableWithCell:)];
        [self.scrollDisplayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    }
    else if (gesture.state == UIGestureRecognizerStateChanged) {
        
        // scrolling
        CGRect rect = self.bounds;
        rect.size.height -= self.contentInset.top;
        
        [self updateCurrentLocation:gesture];
        
        CGFloat scrollZoneHeight = rect.size.height / 6;
        CGFloat bottomScrollBeginning = self.contentOffset.y + self.contentInset.top + rect.size.height - scrollZoneHeight;
        CGFloat topScrollBeginning = self.contentOffset.y + self.contentInset.top  + scrollZoneHeight;
		
        if (location.y >= bottomScrollBeginning) // scroll down
            self.scrollRate = (location.y - bottomScrollBeginning) / scrollZoneHeight;
        else if (location.y <= topScrollBeginning) // scroll up
            self.scrollRate = (location.y - topScrollBeginning) / scrollZoneHeight;
        else
            self.scrollRate = 0;
    }
    else if (gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled) {
		[[NSNotificationCenter defaultCenter]removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
		
        // gesture ended on last legal indexPath
        NSIndexPath *indexPath = self.currentIndexPath;
		
        [self beginUpdates];
        if ([self.delegate respondsToSelector:@selector(finishedReorderAtIndexPath:)]) {
            [self.delegate finishedReorderAtIndexPath:indexPath];
        }
        [self endUpdates];
		
        /*
		 NSMutableArray *visibleRows = [[self indexPathsForVisibleRows] mutableCopy];
		 [visibleRows removeObject:indexPath];
		 [self reloadRowsAtIndexPaths:visibleRows withRowAnimation:UITableViewRowAnimationNone];
		 */
        
        // remove scrolling CADisplayLink
        [self.scrollDisplayLink invalidate];
        self.scrollDisplayLink = nil;
        self.scrollRate = 0;
        
        // animate the drag view to the newly hovered cell
        [UIView animateWithDuration:0.3 animations: ^{
			CGRect rect = [self rectForRowAtIndexPath:indexPath];
			self.draggingView.transform = CGAffineTransformIdentity;
			self.draggingView.frame = CGRectOffset(self.draggingView.bounds, rect.origin.x, rect.origin.y);
		} completion:^(BOOL finished) {
			[self.draggingView removeFromSuperview];
			[self toggleCellVisibility:YES forIndexPath:indexPath];
			
			self.currentIndexPath = nil;
			self.draggingView = nil;
		}];
    }
}

- (void)orientationChanged:(NSNotification *)notification{
	self.longPress.enabled = NO;
	self.longPress.enabled = YES;
}

- (void)updateCurrentLocation:(UILongPressGestureRecognizer *)gesture {
    CGPoint location = [gesture locationInView:self];
    NSIndexPath *indexPath = [self indexPathForRowAtPoint:location];
    
    if ([self.delegate respondsToSelector:@selector(tableView:targetIndexPathForMoveFromRowAtIndexPath:toProposedIndexPath:)]) {
        indexPath = [self.delegate tableView:self targetIndexPathForMoveFromRowAtIndexPath:self.initialIndexPath toProposedIndexPath:indexPath];
    }
    
    NSInteger oldHeight = [self rectForRowAtIndexPath:self.currentIndexPath].size.height;
    NSInteger newHeight = [self rectForRowAtIndexPath:indexPath].size.height;
    
    if (indexPath && ![indexPath isEqual:self.currentIndexPath] && [gesture locationInView:[self cellForRowAtIndexPath:indexPath]].y > newHeight - oldHeight)
    {
		
        [self beginUpdates];
        [self deleteRowsAtIndexPaths:[NSArray arrayWithObject:self.currentIndexPath] withRowAnimation:UITableViewRowAnimationTop];
        [self insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationBottom];
        
        if ([self.delegate respondsToSelector:@selector(moveRowFromIndexPath:toIndexPath:)]) {
            [self.delegate moveRowFromIndexPath:self.currentIndexPath toIndexPath:indexPath];
        }
        
        [self endUpdates];
        
        [self toggleCellVisibility:YES forIndexPath:self.currentIndexPath];
        [self toggleCellVisibility:NO forIndexPath:indexPath];
        
        self.currentIndexPath = indexPath;
    }
}
- (void)toggleCellVisibility:(BOOL)visibility forIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [self cellForRowAtIndexPath:indexPath];
	cell.hidden = ! visibility;
}

- (void)scrollTableWithCell:(NSTimer *)timer {
    UILongPressGestureRecognizer *gesture = self.longPress;
    CGPoint location  = [gesture locationInView:self];
    
    CGPoint currentOffset = self.contentOffset;
    CGPoint newOffset = CGPointMake(currentOffset.x, currentOffset.y + self.scrollRate * 10);
    
    if (newOffset.y < -self.contentInset.top) {
        newOffset.y = -self.contentInset.top;
    } else if (self.contentSize.height + self.contentInset.bottom < self.frame.size.height) {
        newOffset = currentOffset;
    } else if (newOffset.y > (self.contentSize.height + self.contentInset.bottom) - self.frame.size.height) {
        newOffset.y = (self.contentSize.height + self.contentInset.bottom) - self.frame.size.height;
    }
    
    [self setContentOffset:newOffset];
    
    if (location.y >= 0 && location.y <= self.contentSize.height + 50) {
        self.draggingView.center = CGPointMake(self.center.x, location.y);
    }
    
    [self updateCurrentLocation:gesture];
}

- (void)longPressCancel {
    self.longPress.enabled = NO;
    self.longPress.enabled = YES;
}


@end
