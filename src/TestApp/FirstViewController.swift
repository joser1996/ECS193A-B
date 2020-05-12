//
//  FirstViewController.swift
//  TestApp
//
//  Created by David Mottle on 2/15/20.
//  Copyright © 2020 Senior Design. All rights reserved.
//

import UIKit

class FirstViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        MusicPlayer.shared.playBackgroundMusic()
        
//        for family: String in UIFont.familyNames {
//            print(family)
//            for names: String in UIFont.fontNames(forFamilyName: family) {
//                print("==\(names)")
//            }
//        }
    }

    
    //MARK: Leader Board Stuff
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let leaderBoardVC = segue.destination as? LeaderBoardController {
            print("Segueing to \(leaderBoardVC)")
        }
        
    }
    
    
}
