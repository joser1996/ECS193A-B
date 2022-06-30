//
//  LeaderBoardViewCell.swift
//  TestApp
//
//  Created by Jose Torres on 3/16/20.
//  Copyright © 2020 Senior Design. All rights reserved.
//

import UIKit

class LeaderBoardViewCell: UITableViewCell {

    @IBOutlet weak var leaderBoardLabel: UILabel!
    
    func setCell(team: String, score: Int, gameName: String? = nil){
        var gameNameString = ""
        if let gn = gameName {
            gameNameString = "\(gn) | "
        }
        leaderBoardLabel.text = "\(gameNameString)\(team) | \(score)"
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
