#import "NativeMenuViewController.h"
#import "NativeViewController.h"
#import "NativeFeedViewController.h"
#import "ReelsFeedViewController.h"
#import <FBAudienceNetwork/FBAudienceNetwork.h>

static NSString * const kCellIdentifier = @"MenuCell";

typedef NS_ENUM(NSInteger, NativeMenuRow) {
    NativeMenuRowSingleAd,
    NativeMenuRowFeed,
    NativeMenuRowReelsFeed,
    NativeMenuRowCount
};

@implementation NativeMenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Native";
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kCellIdentifier];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return NativeMenuRowCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier forIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    if (@available(iOS 14.0, *)) {
        UIListContentConfiguration *config = [UIListContentConfiguration cellConfiguration];
        switch (indexPath.row) {
            case NativeMenuRowSingleAd:
                config.text = @"Single Ad — Image";
                config.secondaryText = @"Template / Manual / Late-binding flows";
                config.image = [UIImage systemImageNamed:@"photo"];
                break;
            case NativeMenuRowFeed:
                config.text = @"Feed — Video 16:9";
                config.secondaryText = @"Scrollable feed with landscape video ads";
                config.image = [UIImage systemImageNamed:@"rectangle.stack"];
                break;
            case NativeMenuRowReelsFeed:
                config.text = @"Reels — Video 9:16";
                config.secondaryText = @"Full-screen vertical paging — swipe to advance";
                config.image = [UIImage systemImageNamed:@"play.rectangle.fill"];
                break;
        }
        cell.contentConfiguration = config;
    } else {
        switch (indexPath.row) {
            case NativeMenuRowSingleAd:
                cell.textLabel.text = @"Single Ad — Image";
                break;
            case NativeMenuRowFeed:
                cell.textLabel.text = @"Feed — Video 16:9";
                break;
            case NativeMenuRowReelsFeed:
                cell.textLabel.text = @"Reels — Video 9:16";
                break;
        }
    }

    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    switch (indexPath.row) {
        case NativeMenuRowSingleAd: {
            [FBAdSettings setTestAdType:FBAdTestAdType_Img_16_9_App_Install];
            NativeViewController *vc = [[NativeViewController alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
        case NativeMenuRowFeed: {
            [FBAdSettings setTestAdType:FBAdTestAdType_Vid_HD_16_9_46s_App_Install];
            NativeFeedViewController *vc = [[NativeFeedViewController alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
        case NativeMenuRowReelsFeed: {
            [FBAdSettings setTestAdType:FBAdTestAdType_Vid_HD_9_16_39s_App_Install];
            ReelsFeedViewController *vc = [[ReelsFeedViewController alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
    }
}

@end
