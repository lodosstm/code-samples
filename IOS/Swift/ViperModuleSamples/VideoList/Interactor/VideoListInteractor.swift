import Foundation
import RxSwift

class VideoListInteractor {
    weak var output: VideoListInteractorOutput?
    var offset = 0
    var hasDownloadedAll = false
}

extension VideoListInteractor: VideoListInteractorInput {

    func downloadNextPage() {
        if hasDownloadedAll {
            if let output = self.output {
                output.didObtainVideoListItems([])
            }
        } else {
            dowloadVideos()
        }
    }
    
    func dowloadVideos() {
        _ = VideoNetworking.downloadVideo(offset: offset, count: 10)
            .setupThreading()
            .subscribe(onNext: {
                [weak self] response in
                    self?.handleDowloadedVideos(response: response)
                }, onError: {
                    [weak self] (error) in
                    if let output = self?.output {
                        output.didObtainError(error)
                    }
                }, onCompleted: {
                    // No operations.
            })
    }
    
    func handleDowloadedVideos(response: [String : Any]) {
        let videos = parseDowloadedVideos(response: response)
        let count = response["count"] as? Int ?? 0
        hasDownloadedAll = (offset + videos.count >= count)
        offset += videos.count
        
        if let output = self.output {
            output.didObtainVideoListItems(videos)
        }
    }
    
    func parseDowloadedVideos(response: [String : Any]) -> [Video] {
        var videos: [Video] = []
        if let objects = response["objects"] as? [[String:Any]] {
            for dict in objects {
                let temp = Video(serverDict: dict)
                videos.append(temp)
            }
        }
        return videos
    }
    
    func markVideo(videoId: Int64){
        _ = VideoNetworking.markVideo(videoId: videoId)
            .setupThreading()
            .subscribe(onNext: {
                response in
                // No operations.
            }, onError: {
                (error) in
                print("Mark Video \(error)")
            }, onCompleted: {
                // No operations.
            })
    }
    
    func updateUserPlaylistViwed(){
        _ = UserSessionNetworking.updatePlaylistVisited()
            .setupThreading()
            .subscribe(onNext: {
                response in
                 // No operations.
            }, onError: {
                (error) in
                 print("Update user playlist \(error)")
            }, onCompleted: {
                // No operations.
            })
    }
}
