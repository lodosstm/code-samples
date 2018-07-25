import Foundation

protocol VideoListViewOutput {
    func didTapMenuButton()
    func viewWillAppear()
    func viewDidLoad()
    func didSelectVideoWithURL(_ videoURL: String)
    func didScrollToBottom()
    func wasOpen(videoId: Int64)
}
