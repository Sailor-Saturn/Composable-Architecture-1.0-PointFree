import ComposableArchitecture
import SwiftUI

struct NumberFactClient {
    var fetch: @Sendable (Int) async throws -> String
}

extension NumberFactClient: DependencyKey {
    
    static let liveValue: NumberFactClient = Self { number in
        let (data, _ ) = try await URLSession.shared.data(from: URL(
            string: "http://www.numbersapi.com/\(number)"
          )!
        )
        return String(decoding: data, as: UTF8.self)
    }
}

extension DependencyValues {
    var numberFact: NumberFactClient {
        get { self[NumberFactClient.self]}
        set { self[NumberFactClient.self] = newValue}
    }
}

struct CounterFeature: Reducer {
    struct State: Equatable {
        var count = 0
        var fact: String?
        var isTimerOn: Bool = false
        var isLoading: Bool = false
        
    }
    
    enum Action: Equatable{ // Need equatable to test the store.receive
        case decrementButtonTapped
        case incrementButtonTapped
        case getFactButtonTapped
        case factResponse(String)
        case toggleTimerButtonTapped
        case timerTicked
    }
    
    private enum CancelID {
        case timer
    }
    
    @Dependency(\.continuousClock) var clock
    @Dependency(\.numberFact) var numberFactClient

    var body: some ReducerOf<Self> {// Can deduce that is Reducer <State, Action> using only self
        Reduce { state, action in
            switch action {
            case .decrementButtonTapped:
                state.count -= 1
                state.fact = nil
                return .none

            case .incrementButtonTapped:
                state.count += 1
                state.fact = nil
                return .none

            case .getFactButtonTapped:
                state.fact = nil
                state.isLoading = true
                return .run { [count = state.count] send in
                    
                    try await send(.factResponse(self.numberFactClient.fetch(count)))
                }

            case .toggleTimerButtonTapped:
                state.isTimerOn.toggle()
                if state.isTimerOn {
                    return .run { send in
                        for await _ in self.clock.timer(interval: .seconds(1)) {
                            await send(.timerTicked)
                        }
                    }
                    .cancellable(id: CancelID.timer)
                } else {
                    return .cancel(id: CancelID.timer)
                }
            case .timerTicked:
                state.count += 1
                return .none
            case .factResponse(let fact):
                state.fact = fact
                state.isLoading = false
                return .none
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
                    Button {
                        viewStore.send(.getFactButtonTapped)
                    } label: {
                        HStack {
                            Text("Get Fact")
                            if viewStore.isLoading {
                                Spacer()
                                ProgressView()
                            }
                        }
                    }
                    if let fact = viewStore.fact {
                        Text(fact)
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
