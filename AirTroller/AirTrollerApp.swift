//
//  AirTrollerApp.swift
//  AirTroller
//
//  Created by exerhythm on 02.11.2022.
//

import SwiftUI

@main
struct AirTrollerApp: App {
    
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

func remLog(_ objs: Any...) {
    for obj in objs {
        let args: [CVarArg] = [ String(describing: obj) ]
        withVaList(args) { RLogv("%@", $0) }
    }
}
