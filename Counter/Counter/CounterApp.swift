//
//  CounterApp.swift
//  Counter
//
//  Created by Vera Dias on 09/08/2023.
//

import SwiftUI
import ComposableArchitecture

@main
struct CounterApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(store: Store(initialState: CounterFeature.State()){
                CounterFeature()
            })
        }
    }
}
