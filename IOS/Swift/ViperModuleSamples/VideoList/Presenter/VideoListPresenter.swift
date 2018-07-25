import Foundation

class VideoListPresenter {
    weak var view: VideoListViewInput?
    var interactor: VideoListInteractorInput!
    var router: VideoListRouterInput!

}

extension VideoListPresenter: VideoListViewOutput {
    func didTapMenuButton() {
        router.toggleMenu()
    }

    func viewWillAppear() {
        router.enableSideMenu()
    }

    func viewDidLoad() {
        if let v = view {
            v.showLoading()
        }
        interactor.downloadNextPage()
        interactor.updateUserPlaylistViwed()
    }

    func didSelectVideoWithURL(_ videoURL: String) {
        router.openPlayerForVideoWithURL(videoURL)
    }

    func didScrollToBottom() {
        interactor.downloadNextPage()
    }
    
    func wasOpen(videoId: Int64) {
        interactor.markVideo(videoId: videoId)
    }
    
}

extension VideoListPresenter: VideoListInteractorOutput {
    func didObtainVideoListItems(_ videoListVideos: [Video]) {
        if let v = view {
            v.hideLoading()
            v.hideLoadingErrorView()
            v.updateWithVideoListItems(videoListVideos)
        }
    }

    func didObtainError(_ error: Error) {
        if let v = view {
            v.showLoadingErrorView()
            v.hideLoading()
        }
    }
    
}
