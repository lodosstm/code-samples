import UIKit

class VideoListViewController: BaseViewController {

    var output: VideoListViewOutput!

    var dataDisplayManager: VideoListDataDisplayManager?

    @IBOutlet weak var loadingErrorView: LoadingErrorView!

    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.backgroundColor = Constant.tableBackgroundColor
            tableView.estimatedRowHeight = 100
            tableView.rowHeight = UITableViewAutomaticDimension
            tableView.sectionHeaderHeight = 0
            tableView.sectionFooterHeight = 0
        }
    }

    override var prefersStatusBarHidden: Bool {
        return false
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        
        dataDisplayManager = VideoListDataDisplayManager(tableView: tableView,
                                                     output: output)
        
        output.viewDidLoad()
    }
    
    func setupUI() {
        loadingErrorView.updateWithMessage(Constant.errorMessage)
        setupNavBar()
    }
    
    func setupNavBar() {
        let menuBarButtonItem = UIBarButtonItem.makeFromImage(R.image.menu(),
                                                              target: self,
                                                              action: #selector(didTapMenuButton))
        navigationItem.leftBarButtonItem = menuBarButtonItem
        title = R.string.localizable.video()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        output.viewWillAppear()
        self.setNeedsStatusBarAppearanceUpdate()
        UIApplication.shared.isStatusBarHidden = false
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.setNeedsStatusBarAppearanceUpdate()
         UIApplication.shared.isStatusBarHidden = false
    }

    func didTapMenuButton() {
        output.didTapMenuButton()
    }
    
}

class VideoListDataDisplayManager: NSObject {
    var output: VideoListViewOutput!
    var tableView: UITableView!
    var videoListItems: [Video] = []

    init(tableView: UITableView, output: VideoListViewOutput) {
        super.init()
        self.output = output
        self.tableView = tableView
        tableView.delegate = self
        tableView.dataSource = self
    }

    func makeVideoListItemCell(item: Video,
                              indexPath: IndexPath,
                              forTableView tableView: UITableView) -> UITableViewCell {
        guard let videoListItemCell = VideoListItemTableViewCell.reusableInstance(forTableView: tableView) else {
                return UITableViewCell()
        }
        videoListItemCell.updateWithVideoItem(item: item)
        return videoListItemCell
    }
    
    func makeHintCell(text: String,
                       indexPath: IndexPath,
                       forTableView tableView: UITableView) -> UITableViewCell {
        guard let cell = AppHintCenteredTVCell.reusableInstance(forTableView: tableView) else {
                return UITableViewCell()
        }
        cell.configureWith(text: text)
        return cell
    }
    
}

extension VideoListDataDisplayManager: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return videoListItems.count > 0 ? videoListItems.count : 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == videoListItems.count - 2 {
            output.didScrollToBottom()
        }
        
        if videoListItems.count == 0 {
            let cell = makeHintCell(text: R.string.localizable.learningVideoEmpty(), indexPath: indexPath, forTableView: tableView)
            return cell
        } else {
            return makeVideoListItemCell(item: videoListItems[indexPath.section],
                                         indexPath: indexPath,
                                         forTableView: tableView)
        }
    }
    
}

extension VideoListDataDisplayManager: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return Constant.videoSectionHeaderHeight
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UIView(frame: CGRect.zero)
        header.backgroundColor = UIColor.clear
        return header
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footer = UIView(frame: CGRect.zero)
        footer.backgroundColor = UIColor.clear
        return footer
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let video = videoListItems[indexPath.section]
        startVideo(video: video)
    }
    
    func startVideo(video: Video) {
        if !video.isViewed {
            video.isViewed = true
            output.wasOpen(videoId: video.id)
        }
        if let url = video.url, !url.isEmpty {
            output.didSelectVideoWithURL(url)
        }
    }
    
}

extension VideoListViewController: VideoListViewInput {
    func updateWithVideoListItems(_ videoListItems: [Video]) {
        if videoListItems.count > 0 {
            dataDisplayManager?.videoListItems.append(contentsOf:videoListItems)
            tableView.reloadData()
        }
    }

    func showLoadingErrorView() {
        loadingErrorView.isHidden = false
    }

    func hideLoadingErrorView() {
        loadingErrorView.isHidden = true
    }

}
