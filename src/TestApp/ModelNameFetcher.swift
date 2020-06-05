//
//  ModelNameFetcher.swift
//  TestApp
//
//  Created by Jacob Smith on 4/30/20.
//  Copyright © 2020 Senior Design. All rights reserved.
//

import Foundation

class ModelNameFetcher {
    let modelNames = [
        "cup": "mug",
        "coffee-mug": "mug",
        "bullet": "bullet",
        "keyboard": "keyboard",
        "pencil": "pencil",
        "stop-sign": "stop-sign",
        "water-bottle": "water-bottle",
        "rubiks-cube": "rubiks-cube",
        "glasses": "glasses",
        "sunglass": "glasses",
        "tv-remote": "TV_remote",
        "lamp": "lamp",
        "toilet-seat": "bowl",
        "measuring-cup": "mug",
        "bathtub": "bowl"
    ]
    
    func getItemModelName(_ itemName: String) -> String! {
        return modelNames[itemName]
    }
}
