//
//  FirstViewController.swift
//  TestApp
//
//  Created by David Mottle on 2/15/20.
//  Copyright © 2020 Senior Design. All rights reserved.
//

import UIKit

class FirstViewController: UIViewController {

    @IBOutlet weak var singlePlayerButton: UIButton!
    @IBOutlet weak var onlineButton: UIButton!
    @IBOutlet weak var leaderBoardButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        MusicPlayer.shared.playBackgroundMusic()
        

        
        
        setUpButton(button: singlePlayerButton)
        setUpButton(button: onlineButton)
        setUpButton(button: leaderBoardButton)
    }

    func setUpButton(button: UIButton) {
        button.backgroundColor = #colorLiteral(red: 0.3252816287, green: 0.3614723956, blue: 0.7651386138, alpha: 0.8793463908)
        button.layer.shadowColor = #colorLiteral(red: 0.1602400432, green: 0.1780683174, blue: 0.3769221306, alpha: 1)
        button.layer.shadowOffset = CGSize(width:0, height: 6)
        button.layer.shadowOpacity = 1
        button.layer.shadowRadius = 0.0
        button.layer.cornerRadius = 10
        button.layer.masksToBounds = false
    }
    
    //MARK: Leader Board Stuff
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let leaderBoardVC = segue.destination as? LeaderBoardController {
            print("Segueing to \(leaderBoardVC)")
        }
        
    }
    
    
}
