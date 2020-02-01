//
//  State.swift
//  TestApp
//
//  Created by Cameron Brown on 2/1/20.
//  Copyright © 2020 Senior Design. All rights reserved.
//

import Foundation

class Context {
    private var state: State
    
    init(_ state: State) {
        self.state = state
        transitionTo(state: state)
    }
    
    func transitionTo(state: State) {
        self.state = state
        self.state.update(context: self)
    }
    
    func toHome() {
        state.home()
    }
    
    func toOptions() {
        state.options()
    }
    
    func toDeath() {
        state.death()
    }
    
    func toPause() {
        state.pause()
    }
    
    func toGameplay() {
        state.gameplay()
    }
}

protocol State: class {
    func update(context: Context)
    
    func home()
    func options()
    func death()
    func pause()
    func gameplay()
}

class BaseState: State {
    private(set) weak var context: Context?
    
    func update(context: Context) {
        self.context = context
    }
    
    func home() {}
    func options() {}
    func death() {}
    func pause() {}
    func gameplay() {}
}

class Home: BaseState {
    override func options() {
        context?.transitionTo(state: Options())
    }
}

class Options: BaseState {
    override func home() {
        context?.transitionTo(state: Home())
    }
    
    override func gameplay() {
        context?.transitionTo(state: Gameplay())
    }
}
class Death: BaseState {
    override func home() {
        context?.transitionTo(state: Home())
    }
}
class Pause: BaseState {
    override func home() {
        context?.transitionTo(state: Home())
    }
    
    override func gameplay() {
        context?.transitionTo(state: Gameplay())
    }
}
class Gameplay: BaseState {
    override func death() {
        context?.transitionTo(state: Death())
    }
    
    override func pause() {
        context?.transitionTo(state: Pause())
    }
}
