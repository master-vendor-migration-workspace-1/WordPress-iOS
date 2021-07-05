import UITestsFoundation
import XCTest

class MySitesScreen: BaseScreen {
    init() {
        let blogsTable = XCUIApplication().tables["Blogs"]
        let plusButton = XCUIApplication().buttons["Add"]
        let addSelfHostedSiteButton = XCUIApplication().buttons["Add self-hosted site"]
        // need to add "+" button here for Add Site options. Something like:
        // let plusButton = XCUIApplication().buttons["+"] accessibility inspector says it has the Label: "Add", but no accessibilityIdentifier
        // And then the action sheet "add Self-hosted site" option.
        // then we'll need a function to tap + and "add self-hosted site", which should return the self-hosted login flow - LoginSiteAddressScreen

        super.init(element: blogsTable)
    }

    func tapPlusButton() {
        XCUIApplication().buttons["Add"].tap()
        // seems like this needs to somehow return the action sheet so that the "Add self-hosted site" button is available for addSelfHostedSite().
    }

    func addSelfHostedSite() -> LoginSiteAddressScreen {
        XCUIApplication().buttons["Add self-hosted site"].tap()
        return LoginSiteAddressScreen()
    }

    static func isLoaded() -> Bool {
        return XCUIApplication().tables["Blogs"].exists // oh. so because this is defined in the init just to be used by the super.init, it's not in scope to be used outside the init? Ok, so yes I should re-write
    }

    @discardableResult
    func switchToSite(withTitle title: String) -> MySiteScreen {
        XCUIApplication().cells[title].tap()
        return MySiteScreen()
    }
}
