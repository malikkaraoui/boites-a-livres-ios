import XCTest

final class R15Tests: XCTestCase {
    var env: [String: String] { ProcessInfo.processInfo.environment }
    var out: String { env["R15_OUT"] ?? "/tmp/r15" }
    var dir: String { env["R15_DIR"] ?? "run" }
    var a: Int { Int(env["R15_A"] ?? "14183")! }
    var b: Int { Int(env["R15_B"] ?? "227")! }
    var app: XCUIApplication!
    var notes: [String] = []

    override func setUp() {
        continueAfterFailure = true
        app = XCUIApplication()
        app.launch()
    }

    override func tearDown() {
        let d = "\(out)/\(dir)"
        try? FileManager.default.createDirectory(atPath: d, withIntermediateDirectories: true)
        try? notes.joined(separator: "\n").write(toFile: "\(d)/notes-\(name.replacingOccurrences(of: " ", with: "_")).txt", atomically: true, encoding: .utf8)
    }

    func note(_ s: String) { notes.append(s) }

    func shot(_ name: String) {
        let d = "\(out)/\(dir)"
        try? FileManager.default.createDirectory(atPath: d, withIntermediateDirectories: true)
        let png = XCUIScreen.main.screenshot().pngRepresentation
        try? png.write(to: URL(fileURLWithPath: "\(d)/\(name).png"))
    }

    func burst(_ prefix: String, seconds: Double) {
        let t0 = Date(); var i = 0
        while Date().timeIntervalSince(t0) < seconds {
            let ms = Int(Date().timeIntervalSince(t0) * 1000)
            shot(String(format: "%@-%02d-t%04dms", prefix, i, ms)); i += 1
        }
    }

    func pin(_ id: Int) -> XCUIElement { app.descendants(matching: .any)["pin-\(id)"] }
    var detailButton: XCUIElement { app.buttons["Voir le détail"].firstMatch }
    func title(_ id: Int) -> XCUIElement { app.staticTexts["Boîte #\(id)"].firstMatch }

    func waitPins(_ ids: [Int]) {
        for (i, id) in ids.enumerated() {
            XCTAssertTrue(pin(id).waitForExistence(timeout: i == 0 ? 45 : 5), "pin \(id) absent")
        }
        Thread.sleep(forTimeInterval: 3)
    }

    func sheetGeom(_ label: String) {
        let btn = detailButton
        let f = btn.exists ? btn.frame : .zero
        note("\(label): bouton 'Voir le détail' exists=\(btn.exists) frame=\(f) écran=\(app.frame.size)")
    }

    // A -> B -> A : geste terrain dans les deux sens
    func testSwitch() {
        waitPins([a, b])
        shot("00-carte")
        pin(a).tap()
        Thread.sleep(forTimeInterval: 2.5)
        shot("01-fiche-\(a)"); sheetGeom("fiche \(a) stable")
        pin(b).tap()
        burst("02-vers-\(b)", seconds: 1.6)
        Thread.sleep(forTimeInterval: 1.5)
        shot("03-fiche-\(b)-stable"); sheetGeom("fiche \(b) stable")
        note("titre \(b) visible=\(title(b).exists) titre \(a) visible=\(title(a).exists)")
        pin(a).tap()
        burst("04-vers-\(a)", seconds: 1.6)
        Thread.sleep(forTimeInterval: 1.5)
        shot("05-fiche-\(a)-stable"); sheetGeom("fiche \(a) stable (retour)")
        note("titre \(a) visible=\(title(a).exists) titre \(b) visible=\(title(b).exists)")
    }

    // Glisser vers le haut -> détail ; retour -> aucune fiche
    func testSwipeUp() {
        waitPins([a, b])
        pin(a).tap(); Thread.sleep(forTimeInterval: 2.0)
        pin(b).tap(); Thread.sleep(forTimeInterval: 2.0)
        shot("10-fiche-\(b)")
        XCTAssertTrue(detailButton.waitForExistence(timeout: 3), "fiche non ouverte")
        let grab = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.62))
        grab.press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.08)))
        burst("11-glisser", seconds: 1.0)
        Thread.sleep(forTimeInterval: 1.5)
        shot("12-detail")
        let back = app.navigationBars.buttons.firstMatch
        XCTAssertTrue(back.waitForExistence(timeout: 5), "détail non ouvert")
        note("navbar ids: \(app.navigationBars.staticTexts.allElementsBoundByIndex.map { $0.label })")
        back.tap()
        Thread.sleep(forTimeInterval: 2.0)
        shot("13-retour-carte")
        note("retour: fiche présente=\(detailButton.exists)")
        XCTAssertFalse(detailButton.exists, "fiche restée ouverte au retour")
    }

    // Voir le détail après changement de point
    func testDetailButton() {
        waitPins([a, b])
        pin(a).tap(); Thread.sleep(forTimeInterval: 2.0)
        pin(b).tap(); Thread.sleep(forTimeInterval: 2.0)
        shot("20-fiche-\(b)")
        detailButton.tap()
        Thread.sleep(forTimeInterval: 2.5)
        shot("21-detail")
        let labels = app.navigationBars.staticTexts.allElementsBoundByIndex.map { $0.label } + app.staticTexts.allElementsBoundByIndex.prefix(6).map { $0.label }
        note("textes détail: \(labels)")
        XCTAssertTrue(labels.contains { $0.contains("#\(b)") }, "détail de \(b) attendu")
        app.navigationBars.buttons.firstMatch.tap()
        Thread.sleep(forTimeInterval: 2.0)
        shot("22-retour-carte")
        note("retour: fiche présente=\(detailButton.exists)")
    }

    // Fermer par toucher carte : aucune bande
    func testClose() {
        waitPins([a, b])
        pin(a).tap(); Thread.sleep(forTimeInterval: 2.0)
        pin(b).tap(); Thread.sleep(forTimeInterval: 2.0)
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.12, dy: 0.40)).tap()
        burst("30-fermer", seconds: 1.2)
        Thread.sleep(forTimeInterval: 1.0)
        shot("31-ferme")
        note("après fermeture: fiche présente=\(detailButton.exists)")
        XCTAssertFalse(detailButton.exists, "fiche encore là")
    }

    // Liste des points (pour choisir une boîte sans photo)
    func testListPins() {
        waitPins([a])
        let pins = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'pin-'"))
        for i in 0..<pins.count {
            let e = pins.element(boundBy: i)
            note("\(e.identifier) \(e.value as? String ?? "?") hittable=\(e.isHittable) frame=\(e.frame)")
        }
    }
}
