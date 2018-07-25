import UIKit

protocol VideoListRouterInput {
    func toggleMenu()
    func enableSideMenu()
    func openPlayerForVideoWithURL(_ url: String)
}

class VideoListRouter {
    weak var view: VideoListViewController?
}

extension VideoListRouter: VideoListRouterInput {
    func toggleMenu() {
        SideMenuManager.toggleSideMenu()
    }

    func enableSideMenu() {
        SideMenuManager.enableSideMenu()
    }

    func openPlayerForVideoWithURL(_ url: String) {
        let videoViewController = VideoAssembly().viewVideoModule {
            presenter in
            if let youtubeID = url.youtubeIDFromLink() {
                presenter.configureWithVideoId(youtubeID)
            }
        }
        if let v = view {
            v.present(videoViewController, animated: true, completion: nil)
        }
    }
    
}
