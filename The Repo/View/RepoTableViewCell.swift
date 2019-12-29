//
//  RepoTableViewCell.swift
//  The Repo
//
//  Created by Sherif Darwish on 12/24/19.
//  Copyright © 2019 Sherif Darwish. All rights reserved.
//

import UIKit
import SDWebImage

class RepoTableViewCell: UITableViewCell {

    @IBOutlet weak var ImgViewAvatar: UIImageView!
    @IBOutlet weak var LblRepoName: UILabel!
    @IBOutlet weak var LblOwnerName: UILabel!
    @IBOutlet weak var LblRepoDesc: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    func ConfigureCell(RepoName : String,RepoDesc : String ,OwnerName : String , OwnerAvatar : String ){
        self.ImgViewAvatar.sd_setImage(with: URL(string: OwnerAvatar), placeholderImage: UIImage())
        self.LblRepoDesc.text = RepoDesc
        self.LblRepoName.text = RepoName
        self.LblOwnerName.text = OwnerName
        
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
