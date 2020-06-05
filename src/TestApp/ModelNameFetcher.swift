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
        "bowl": "bowl",
        "cup": "mug",
        "measuring-cup": "mug",
        "coffee-mug": "mug",
        "bullet": "bullet",
        "computer-keyboard": "keyboard",
        "pencil": "pencil",
        "pen": "pencil",
        "stop-sign": "stop-sign",
        "water-bottle": "water_bottle",
        "rubiks-cube": "rubiks-cube",
        "glasses": "glasses",
        "sunglass": "glasses",
        "toothbrush": "toothbrush",
        "plate": "plate",
        "tv-remote": "TV_remote",
        "lamp": "lamp",
        "toilet-seat": "bowl",
        "bathtub": "bowl",
        "smartphone": "smartphone"
    ]
    
    func getItemModelName(_ itemName: String) -> String! {
        return modelNames[itemName]
    }
    
    func getRandomItem() -> String {
        let r = modelNames.randomElement()
        return r?.key ?? "pencil"
    }
}
