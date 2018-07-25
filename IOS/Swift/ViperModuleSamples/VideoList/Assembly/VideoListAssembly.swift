import UIKit

class VideoListAssembly {

    func viewVideoListModule() -> VideoListViewController {
        let viewController = makeViewController()

        let router = VideoListRouter()
        let interactor = VideoListInteractor()

        let presenter = VideoListPresenter()
        presenter.view = viewController
        presenter.router = router
        presenter.interactor = interactor

        router.view = viewController
        interactor.output = presenter
        viewController.output = presenter
        return viewController
    }

    private func makeViewController() -> VideoListViewController {
        return VideoListViewController(
            nib: R.nib.videoListViewController
        )
    }

}
