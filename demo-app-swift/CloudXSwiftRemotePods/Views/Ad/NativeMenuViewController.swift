import UIKit
import FBAudienceNetwork

class NativeMenuViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Native"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "MenuCell")
    }

    // MARK: - UITableViewDataSource

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 3 }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MenuCell", for: indexPath)
        cell.accessoryType = .disclosureIndicator

        if #available(iOS 14.0, *) {
            var config = UIListContentConfiguration.cell()
            switch indexPath.row {
            case 0:
                config.text = "Single Ad — Image"
                config.secondaryText = "Template / Manual / Late-binding flows"
                config.image = UIImage(systemName: "photo")
            case 1:
                config.text = "Feed — Video 16:9"
                config.secondaryText = "Scrollable feed with landscape video ads"
                config.image = UIImage(systemName: "rectangle.stack")
            case 2:
                config.text = "Reels — Video 9:16"
                config.secondaryText = "Full-screen vertical paging — swipe to advance"
                config.image = UIImage(systemName: "play.rectangle.fill")
            default: break
            }
            cell.contentConfiguration = config
        } else {
            switch indexPath.row {
            case 0: cell.textLabel?.text = "Single Ad — Image"
            case 1: cell.textLabel?.text = "Feed — Video 16:9"
            case 2: cell.textLabel?.text = "Reels — Video 9:16"
            default: break
            }
        }

        return cell
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch indexPath.row {
        case 0:
            FBAdSettings.testAdType = .img_16_9_App_Install
            navigationController?.pushViewController(NativeViewController(), animated: true)
        case 1:
            FBAdSettings.testAdType = .vid_HD_16_9_46s_App_Install
            navigationController?.pushViewController(NativeFeedViewController(), animated: true)
        case 2:
            FBAdSettings.testAdType = .vid_HD_9_16_39s_App_Install
            navigationController?.pushViewController(ReelsFeedViewController(), animated: true)
        default: break
        }
    }
}
