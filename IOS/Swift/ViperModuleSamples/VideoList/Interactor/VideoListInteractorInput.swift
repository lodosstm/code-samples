import Foundation

protocol VideoListInteractorInput {
    func downloadNextPage()
    func markVideo(videoId: Int64)
    func updateUserPlaylistViwed()
    
}
