import UIKit
import Kingfisher

class VideoListItemTableViewCell: UITableViewCell {
    static let nib = R.nib.videoListItemTableViewCell

    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var videoNameLabel: UILabel!
    @IBOutlet weak var videoDescriptionLabel: UILabel!
    @IBOutlet weak var videoViewedImage: UIImageView!
    
    class func reusableInstance(forTableView tableView: UITableView)
        -> VideoListItemTableViewCell? {
            var cell: VideoListItemTableViewCell?
            cell = tableView.dequeueReusableCell(withIdentifier: nib.identifier)
                as? VideoListItemTableViewCell
            if cell == nil {
                tableView.register(UINib(nibName: nib.identifier, bundle: nil),
                                   forCellReuseIdentifier: nib.identifier)
                cell = tableView.dequeueReusableCell(withIdentifier: nib.identifier)
                    as? VideoListItemTableViewCell
            }
            return cell
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        videoDescriptionLabel.textColor = Constant.descriptionTextColor
        thumbnailImageView.backgroundColor = Constant.cellBacgroundColor
        thumbnailImageView.image = nil
        selectionStyle = .none
    }

    func updateWithVideoItem(item: Video) {
        let thumb = item.getPreview()
        setupImage(imageURL: thumb)
        videoNameLabel.text = item.title
        videoViewedImage.isHidden = item.isViewed ?? false
        setup(description: item.description)
    }
    
    func setupImage(imageURL: String) {
        if let url = URL(string: thumb) {
            thumbnailImageView.kf.setImage(with: url,
                                           placeholder: nil,
                                           options: [.transition(.fade(1))],
                                           progressBlock: nil,
                                           completionHandler: nil)
        }
    }
    
    func setup(description: String?) {
        if let description = description {
            videoDescriptionLabel.text = description.isEmpty ?
                Constant.learningVideoNoDescription() : description
        } else {
            videoDescriptionLabel.text = Constant.learningVideoNoDescription()
        }
    }
    
}
