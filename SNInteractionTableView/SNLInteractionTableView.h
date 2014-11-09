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

/**
 *  Delegate protocol to handle reordering of cells in SNLInteractionTableView.
 */
@protocol SNLInteractionTableViewDelegate <UITableViewDelegate>

/**
 *	Called when user long presses a cell.
 */
- (void)startedReorderAtIndexPath:(NSIndexPath *)indexPath;

/**
 *	Called every time 2 cells switch positions.
 *  To update the data source when a cell is dragged to a new position.
 */
- (void)moveRowFromIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath;

/**
 *	Called when user stops dragging.
 */
- (void)finishedReorderAtIndexPath:(NSIndexPath *)indexPath;

@end




@interface SNLInteractionTableView : UITableView

/**
 *  TableViews delegate ViewController to handle reordering.
 */
@property (nonatomic, weak) id <SNLInteractionTableViewDelegate> delegate;

/**
 *  Toolbar is shown when cell is tapped.
 *
 *  Default: YES.
 */
@property (nonatomic) BOOL toolbarEnabled;


#pragma mark - Functionality
/**
 *  Deselect selected cell and calls tableView:willDeselectRowAtIndexPath and
 *	tableView:didDeselectRowAtIndexPath of delegate.
 */
- (void)deselectSelectedRow;

/**
 *  Reloads rows at indexPath like normal tableView does, but maintans selection.
 */
- (void)reloadRowsAtIndexPaths:(NSArray *)indexPaths andKeepSelection:(BOOL)keepSelection;

@end
