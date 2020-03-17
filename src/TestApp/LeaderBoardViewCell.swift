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
    
    
    func setCell(team: String, score: Int){
        let names = "Players: \(team)"
        let s = "    Score: \(score)"
        
        let fullLabelText = names + s
        leaderBoardLabel.text = fullLabelText
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
