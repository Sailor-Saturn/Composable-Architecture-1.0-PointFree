//
//  ContentView.swift
//  Counter
//
//  Created by Vera Dias on 09/08/2023.
//
import ComposableArchitecture
import SwiftUI

struct CounterFeature: Reducer {
    struct State: Equatable {
        var count = 0
        var fact: String?
        var isTimerOn = false
    }
    
    enum Action {
        case decrementButtonTapped
        case incrementButtonTapped
        case getFactButtonTapped
        case toggleTimerButtonTapped
    }
    
    var body: some ReducerOf<Self> {// Can deduce that is Reducer <State, Action> using only self
        Reduce { state, action in
            switch action {
            case .decrementButtonTapped:
                state.count -= 1
                return .none
            case .incrementButtonTapped:
                state.count += 1
                return .none
            case .getFactButtonTapped:
                // TODO: Perform Request
                return .none
            case .toggleTimerButtonTapped:
                state.isTimerOn.toggle()
                return .none
                // TODO: Start Timer
            }
        }
    }
}

struct ContentView: View {
    // StoreOf<R: Reducer> = Store<R.State, R.Action>
    let store: StoreOf<CounterFeature>
    
    // Since you can use store.state.count
    // since it absorbs too much and will probaly cause
    // performance issues
    
 
    var body: some View {
        // We shouldn't always use the whole store for each component
        // But for now we will use this: observe: {$0}
        
        // On iOS 17 and Swift 5.9 WithViewStore can be removed completly
        // And viewStore can be changed to store instead
        // Since SwiftUI can access the state your calling and just observe that
        WithViewStore(self.store, observe: {$0}) { viewStore in
            Form {
                Section {
                    Text("\(viewStore.count)")
                    Button("Decrement"){
                        viewStore.send(.decrementButtonTapped)
                    }
                    Button("Increment"){
                        viewStore.send(.incrementButtonTapped)
                    }
                }
                Section {
                    Text("Get Fact")
                    if let fact = viewStore.fact {
                        Text("Some Fact")
                    }
                }
                Section {
                    if viewStore.isTimerOn {
                        Button("Stop Timer"){
                            viewStore.send(.toggleTimerButtonTapped)
                        }
                    } else {
                        Button("Start Timer"){
                            viewStore.send(.toggleTimerButtonTapped)
                        }
                    }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(store: Store(initialState: CounterFeature.State()){
            CounterFeature()
                ._printChanges()
        })
    }
}

// Since all the feature's logic is with value types and encapsulated into a single reducer
// A powerful tool from the composable architecture is to peek inside of the feature using
// ._printChanges() 🤩
// Since it's value types we can get a copy of the value before mutation and after the mutation and can compare the two
