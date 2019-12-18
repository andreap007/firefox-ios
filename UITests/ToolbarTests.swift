/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import WebKit
import UIKit
import EarlGrey

class ToolbarTests: KIFTestCase, UITextFieldDelegate {
    fileprivate var webRoot: String!

    override func setUp() {
        webRoot = SimplePageServer.start()
        BrowserUtils.configEarlGrey()
        BrowserUtils.dismissFirstRunUI()
    }

    func testURLEntry() {
        let textField = tester().waitForView(withAccessibilityIdentifier: "url") as! UITextField
        EarlGrey.selectElement(with: grey_accessibilityID("url"))
            .inRoot(grey_kindOfClass(UITextField.self))
            .perform(grey_tap())
        EarlGrey.selectElement(with: grey_accessibilityID("address"))
            .inRoot(grey_kindOfClass(UITextField.self))
            .perform(grey_replaceText("foobar"))
        tester().tapView(withAccessibilityIdentifier: "urlBar-cancel")
        XCTAssertNotEqual(textField.text, "foobar", "Verify that the URL bar text clears on about:home")

        // 127.0.0.1 doesn't cause http:// to be hidden. localhost does. Both will work.
        let localhostURL = webRoot.replacingOccurrences(of: "127.0.0.1", with: "localhost")
        let url = "\(localhostURL)/numberedPage.html?page=1"

        // URL without "http://".
        let displayURL = "\(localhostURL)/numberedPage.html?page=1".substring(from: url.index(url.startIndex, offsetBy: "http://".count))

        BrowserUtils.enterUrlAddressBar(typeUrl: url)

        tester().waitForAnimationsToFinish()
        XCTAssertEqual(textField.text, displayURL, "URL matches page URL")

        EarlGrey.selectElement(with: grey_accessibilityID("url"))
            .inRoot(grey_kindOfClass(UITextField.self))
            .perform(grey_tap())
        EarlGrey.selectElement(with: grey_accessibilityID("address"))
            .inRoot(grey_kindOfClass(UITextField.self))
            .perform(grey_replaceText("foobar"))
        tester().tapView(withAccessibilityIdentifier: "urlBar-cancel")
        tester().waitForAnimationsToFinish()
        XCTAssertEqual(textField.text, displayURL, "Verify that text reverts to page URL after entering text")

        EarlGrey.selectElement(with: grey_accessibilityID("url"))
             .inRoot(grey_kindOfClass(UITextField.self))
            .perform(grey_tap())
        EarlGrey.selectElement(with: grey_accessibilityID("address"))
             .inRoot(grey_kindOfClass(UITextField.self))
            .perform(grey_replaceText(" "))

        EarlGrey.selectElement(with: grey_accessibilityID("urlBar-cancel")).perform(grey_tap())
        tester().waitForAnimationsToFinish()
        XCTAssertEqual(textField.text, displayURL, "Verify that text reverts to page URL after clearing text")
    }

    func testUserInfoRemovedFromURL() {
        let hostWithUsername = webRoot.replacingOccurrences(of: "127.0.0.1", with: "username:password@127.0.0.1")
        let urlWithUserInfo = "\(hostWithUsername)/numberedPage.html?page=1"
        let url = "\(webRoot!)/numberedPage.html?page=1"

//        let urlFieldAppeared = GREYCondition(name: "Wait for URL field", block: {
//            var errorOrNil: NSError?
//            EarlGrey.selectElement(with: grey_accessibilityID("url"))
//                .assert(grey_notNil(), error: &errorOrNil)
//            return errorOrNil == nil
//        }).wait(withTimeout: 10)
//        GREYAssertTrue(urlFieldAppeared, reason: "Failed to display URL field")

        BrowserUtils.enterUrlAddressBar(typeUrl: urlWithUserInfo)
        tester().waitForAnimationsToFinish()
        tester().waitForWebViewElementWithAccessibilityLabel("Page 1")

        let urlField = tester().waitForView(withAccessibilityIdentifier: "url") as! UITextField
        XCTAssertEqual("http://" + urlField.text!, url)
    }

    override func tearDown() {
        let previousOrientation = UIDevice.current.value(forKey: "orientation") as! Int
        if previousOrientation == UIInterfaceOrientation.landscapeLeft.rawValue {
            // Rotate back to portrait
            let value = UIInterfaceOrientation.portrait.rawValue
            UIDevice.current.setValue(value, forKey: "orientation")
        }
        BrowserUtils.resetToAboutHome()
        BrowserUtils.clearPrivateData()
    }
}
