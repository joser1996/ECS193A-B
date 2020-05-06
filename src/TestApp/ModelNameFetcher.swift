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
        "cup": "mug-model",
        "coffee-mug": "mug-model",
        "bullet": "bullet-model",
        "keyboard": "keyboard-model",
        "pencil": "pencil-model",
        "stop-sign": "stop-sign-model",
        "water-bottle": "water-bottle-model",
        "rubiks-cube": "rubiks-cube-model",
        "glasses": "glasses-model",
        "sunglasses": "glasses-model",
        "tv-remote": "TV_remote-model",
        "lamp": "lamp-model"
    ]
    
    func getItemModelName(_ itemName: String) -> String! {
        return modelNames[itemName]
    }
}
