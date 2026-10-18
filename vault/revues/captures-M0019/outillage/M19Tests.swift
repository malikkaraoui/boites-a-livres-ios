import XCTest

final class M19Tests: XCTestCase {
    let out = ProcessInfo.processInfo.environment["M19_OUT"] ?? "/tmp/m19"
    var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = true
        app = XCUIApplication()
        app.launch()
    }

    func shot(_ dir: String, _ name: String) {
        let d = "\(out)/\(dir)"
        try? FileManager.default.createDirectory(atPath: d, withIntermediateDirectories: true)
        let png = XCUIScreen.main.screenshot().pngRepresentation
        try? png.write(to: URL(fileURLWithPath: "\(d)/\(name).png"))
    }

    func burst(_ dir: String, _ prefix: String, seconds: Double) {
        let t0 = Date()
        var i = 0
        while Date().timeIntervalSince(t0) < seconds {
            let ms = Int(Date().timeIntervalSince(t0) * 1000)
            shot(dir, String(format: "%@-%02d-t%04dms", prefix, i, ms))
            i += 1
        }
    }

    func pin(_ id: Int) -> XCUIElement { app.descendants(matching: .any)["pin-\(id)"] }

    func waitPins(_ a: Int, _ b: Int) {
        XCTAssertTrue(pin(a).waitForExistence(timeout: 40), "pin \(a) absent")
        XCTAssertTrue(pin(b).waitForExistence(timeout: 5), "pin \(b) absent")
        Thread.sleep(forTimeInterval: 3)
    }

    var a: Int { Int(ProcessInfo.processInfo.environment["M19_A"] ?? "14183")! }
    var b: Int { Int(ProcessInfo.processInfo.environment["M19_B"] ?? "227")! }

    // Geste terrain : point A, puis point B, puis retour vers A
    func testSwitch() {
        let dir = ProcessInfo.processInfo.environment["M19_DIR"] ?? "run"
        waitPins(a, b)
        shot(dir, "00-carte")
        pin(a).tap()
        Thread.sleep(forTimeInterval: 2.5)
        shot(dir, "01-fiche-\(a)")
        pin(b).tap()
        burst(dir, "02-vers-\(b)", seconds: 2.0)
        Thread.sleep(forTimeInterval: 1.5)
        shot(dir, "03-fiche-\(b)-stable")
        pin(a).tap()
        burst(dir, "04-vers-\(a)", seconds: 2.0)
        Thread.sleep(forTimeInterval: 1.5)
        shot(dir, "05-fiche-\(a)-stable")
    }

    var dir: String { ProcessInfo.processInfo.environment["M19_DIR"] ?? "run" }

    var sheetOpen: XCUIElement { app.buttons["Voir le détail"].firstMatch }
    func sheetTitle(_ id: Int) -> XCUIElement { app.staticTexts.matching(NSPredicate(format: "label == %@", "Boîte #\(id)")).firstMatch }

    // Glisser la fiche vers le haut : le détail s'ouvre ; au retour, aucune fiche restée en grand
    func testSwipeUp() {
        waitPins(a, b)
        pin(a).tap()
        Thread.sleep(forTimeInterval: 2.0)
        shot(dir, "10-fiche-\(a)")
        XCTAssertTrue(sheetOpen.waitForExistence(timeout: 3), "fiche non ouverte")
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.62)).press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.08)))
        burst(dir, "11-glisser", seconds: 1.0)
        Thread.sleep(forTimeInterval: 1.5)
        shot(dir, "12-detail-\(a)")
        XCTAssertTrue(app.navigationBars.buttons.firstMatch.waitForExistence(timeout: 5), "détail non ouvert")
        app.navigationBars.buttons.firstMatch.tap()
        Thread.sleep(forTimeInterval: 2.0)
        shot(dir, "13-retour-carte")
        XCTAssertFalse(sheetOpen.exists, "fiche restée ouverte au retour")
    }

    // Bouton « Voir le détail » après un changement de point : détail de la bonne boîte
    func testDetailButton() {
        waitPins(a, b)
        pin(a).tap()
        Thread.sleep(forTimeInterval: 2.0)
        pin(b).tap()
        Thread.sleep(forTimeInterval: 2.0)
        shot(dir, "20-fiche-\(b)")
        app.buttons["Voir le détail"].firstMatch.tap()
        Thread.sleep(forTimeInterval: 2.5)
        shot(dir, "21-detail-\(b)")
        XCTAssertTrue(app.navigationBars["#\(b) — Annecy"].exists || app.staticTexts["#\(b) — Annecy"].exists
                      || app.navigationBars.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "#\(b) ")).count > 0,
                      "détail de \(b) attendu")
    }

    // Fermer la fiche en touchant la carte : aucune bande ne reste
    func testClose() {
        waitPins(a, b)
        pin(a).tap()
        Thread.sleep(forTimeInterval: 2.0)
        pin(b).tap()
        Thread.sleep(forTimeInterval: 2.0)
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.15, dy: 0.42)).tap()
        burst(dir, "30-fermer", seconds: 1.2)
        Thread.sleep(forTimeInterval: 1.0)
        shot(dir, "31-ferme")
        XCTAssertFalse(sheetOpen.exists, "fiche encore là")
    }

    // Trois points en moins de 0,3 s : la fiche finale est la dernière touchée
    func testRapid() {
        let c = Int(ProcessInfo.processInfo.environment["M19_C"] ?? "0")!
        waitPins(a, b)
        pin(a).tap()
        Thread.sleep(forTimeInterval: 2.0)
        pin(b).tap()
        pin(c).tap()
        burst(dir, "40-rapide", seconds: 1.5)
        Thread.sleep(forTimeInterval: 1.0)
        shot(dir, "41-final-\(c)")
        XCTAssertTrue(sheetOpen.exists, "fiche finale attendue (boîte vérifiée au journal et à la capture)")
    }

    // Liste des points avec / sans photo (pour choisir les boîtes des scénarios)
    func testListPins() {
        waitPins(a, b)
        let pins = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'pin-'"))
        var lines: [String] = []
        for i in 0..<pins.count {
            let e = pins.element(boundBy: i)
            lines.append("\(e.identifier) \(e.value as? String ?? "?") hittable=\(e.isHittable) frame=\(e.frame)")
        }
        try? lines.joined(separator: "\n").write(toFile: "\(out)/pins.txt", atomically: true, encoding: .utf8)
    }
}
