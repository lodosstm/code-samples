import Foundation

protocol VideoListInteractorOutput: class {
    func didObtainVideoListItems(_ videoListVideos: [Video])
    func didObtainError(_ error: Error)

}
