//
//  CounterTests.swift
//  CounterTests
//
//  Created by Vera Dias on 09/08/2023.
//
import ComposableArchitecture
import XCTest
@testable import Counter

@MainActor // A singleton actor whose executor is equivalent to the main dispatch queue.
// Inherits from globalactor, added on Swift 5.5
final class CounterTests: XCTestCase {
    var store: TestStore<CounterFeature.State, CounterFeature.Action>!

    override func setUp() async throws {
        store = TestStore(initialState: CounterFeature.State()) {
            CounterFeature()
        } withDependencies: {
            $0.continuousClock = ImmediateClock()
            $0.numberFact.fetch = { "\($0) is a great number!" }
        }
    }
    
    func testCounter() async {
        await store.send(.incrementButtonTapped) {
            // Assert here the state of the feature before the action was sent
            $0.count = 1 // 1st test, very easy to do since the whole feature was built with value types
            // otherwise (if it was a reference type) this set would not asser anything since
            // it would change the same object
        }
    }
    
    // Not testing much in this case, just making sure the toggle of the timer works
    // Added the toggle timer off to make sure no effects are running after the testing ends
    func testBehaviourOfTimerToggle() async {
        await store.send(.toggleTimerButtonTapped) {
            $0.isTimerOn = true // Since the counter timer will be turned on, leaving this as is will
            // cause this test to fail since there are effects still running in the background
            // We have make sure no effects are still running after the test ends
        }
        
        await store.send(.toggleTimerButtonTapped) {
            $0.isTimerOn = false
        }
    }

    // This test will fail since there is no overwrite of the clock dependency
    // We are accidentally using a live value
//    func testTimerCount() async throws{
//        await store.send(.toggleTimerButtonTapped) {
//            $0.isTimerOn = true
//        }
//
//        // We now have control of how tests are executed in to our feature and feeds data into the system
//        try await Task.sleep(for: .microseconds(1_100)) // Awaiting for the task to run is very inneficient
//        // What if we had to assert 10 timer ticks? Would we wait for 10 seconds??
//
//        // To receive actions, all enum actions should be equatable
//        await store.receive(.timerTicked){
//            $0.count = 1 // The receive of the timer ticked will increase the count to one and that should be checked here or
//            // else it fails
//        }
//        await store.send(.toggleTimerButtonTapped) {
//            $0.isTimerOn = false
//        }
//    }
    
    // Test runs now 60x faster than the previous test
    func testTimerCountWorking() async throws {
        let clock = TestClock()
        
        let store = TestStore(initialState: CounterFeature.State()) {
            CounterFeature()
        } withDependencies: {
            $0.continuousClock = clock
        }
        
        await store.send(.toggleTimerButtonTapped) {
            $0.isTimerOn = true
        }
        
        // We now have control of how tests are executed in to our feature and feeds data into the system
        await clock.advance(by: .seconds(1))
        
        // To receive actions, all enum actions should be equatable
        await store.receive(.timerTicked){
            $0.count = 1 // The receive of the timer ticked will increase the count to one and that should be checked here or
            // else it fails
        }
        
        await clock.advance(by: .seconds(1))
        
        // To receive actions, all enum actions should be equatable
        await store.receive(.timerTicked){
            $0.count = 2 // The receive of the timer ticked will increase the count to one and that should be checked here or
            // else it fails
        }
        
        await store.send(.toggleTimerButtonTapped) {
            $0.isTimerOn = false
        }
    }
    
    func testGetFact() async {
        await store.send(.getFactButtonTapped) {
            $0.isLoading = true
        }
        
        // We cannot receive the action fact response with the expected string since
        // we are fetching from the outside world.
        await store.receive(.factResponse("0 is a great number!")){
            $0.fact = "0 is a great number!"
            $0.isLoading = false
        }
    }
    
    func testGetFact_Failure() async {
        store = TestStore(initialState: CounterFeature.State()) {
            CounterFeature()
        } withDependencies: {
            $0.numberFact.fetch = { _ in
                struct SomeError: Error {}
                throw SomeError()
            }
        }
        
        XCTExpectFailure()
        await store.send(.getFactButtonTapped) {
            $0.isLoading = true
        }
    }
}
