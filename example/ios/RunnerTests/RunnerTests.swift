import Flutter
import UIKit
import XCTest

// If your plugin has been explicitly set to "type: .dynamic" in the Package.swift,
// you will need to add your plugin as a dependency of RunnerTests within Xcode.

@testable import chameleon_icons

// This demonstrates a simple unit test of the Swift portion of this plugin's implementation.
//
// See https://developer.apple.com/documentation/xctest for more information about using XCTest.

class RunnerTests: XCTestCase {
    
    func testGetPlatformVersion() {
        let plugin = ChameleonIconsPlugin()
        
        let call = FlutterMethodCall(methodName: "getPlatformVersion", arguments: [])
        
        let resultExpectation = expectation(description: "result block must be called.")
        plugin.handle(call) { result in
            XCTAssertEqual(result as! String, "iOS " + UIDevice.current.systemVersion)
            resultExpectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }
    
    //TODO
    func testChangeIcontoDark(){
        let plugin = ChameleonIconsPlugin()
        let ChangeIconcall = FlutterMethodCall(methodName: "changeIcon", arguments: "MainActivityDark")
        let currentIconCall = FlutterMethodCall(methodName: "getCurrentIcon",arguments: nil)
 
        let resultExpectation = expectation(description: "result block must be called.")
        
        plugin.handle(ChangeIconcall){
            result in
             resultExpectation.fulfill()
        }
        waitForExpectations(timeout: 1)
        
        plugin.handle(currentIconCall){
            result in
            XCTAssertEqual(result as! String, "MainActivityDark")

        }
        
        waitForExpectations(timeout: 1)

        
        
    }
    
}
