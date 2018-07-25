import Foundation

protocol VideoListViewInput: BaseView {
    func updateWithVideoListItems(_ videoListItems: [Video])
    func showLoadingErrorView()
    func hideLoadingErrorView()
}
