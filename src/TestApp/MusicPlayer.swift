//
//  MusicPlayer.swift
//  TestApp
//
//  Created by Jose Torres on 4/1/20.
//  Copyright © 2020 Senior Design. All rights reserved.
//

import Foundation
import AVFoundation

class MusicPlayer {
    static let shared = MusicPlayer()
    var player: AVAudioPlayer?
    
    func playBackgroundMusic() {
        if let bundle = Bundle.main.path(forResource: "wind", ofType: "mp3") {
            let backgroundMusic = NSURL(fileURLWithPath: bundle)
            
            do{
                player = try AVAudioPlayer(contentsOf: backgroundMusic as URL)
                guard let player = player else {return}
                player.numberOfLoops = -1
                player.prepareToPlay()
                player.play()
                
            } catch {
                print(error)
            }
        }
        
    }
    
    func startSong() {
        if let bundle = Bundle.main.path(forResource: "NightOfDIzzySpells", ofType: "mp3") {
            let song = NSURL(fileURLWithPath: bundle)
            do{
                print("In do")
                player = try AVAudioPlayer(contentsOf: song as URL)
                guard let player = player else {
                    print("Failed here dude")
                    return
                    
                }
                player.numberOfLoops = -1
                player.prepareToPlay()
                let ret = player.play()
                if ret { print("Couldn't play") }
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func stopSong() {
        guard let player = player else {return}
        player.stop()
    }
    
    func pauseSong() {
        guard let player = player else {return}
        player.pause()
    }
    
    func resumeSong() {
        guard let player = player else {return}
        player.play()
    }
    func stopBackgroundMusic() {
        guard let player = player else {return}
        player.stop()
    }
    
    func playZombieDying() {
        if let path = Bundle.main.path(forResource: "David_Screeching", ofType: "mp3") {
            let url = URL(fileURLWithPath: path)
            
            do{
                player = try AVAudioPlayer(contentsOf: url)
                guard let player = player else {return}
                player.enableRate = true
                player.rate = 2
                player.numberOfLoops = 0
                player.prepareToPlay()
                player.play()
            } catch {
                print("Couldn't play sound")
                print(error)
            }
            
        }
    }
    

}

