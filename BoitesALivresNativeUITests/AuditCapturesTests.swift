import XCTest

// MARK: - Audit visuel (M0055)

// Une méthode = une passe = un lancement de l'app (langue × apparence). Chaque écran atteint
// donne une capture jointe au résultat (XCTAttachment, lifetime .keepAlways).
// Règles : aucun formulaire envoyé (on ouvre, on touche au plus, on ferme) ; aucun appel à Apple :
// ni « Confirmer la position » (CLGeocoder), ni la feuille Localisation (CLGeocoder à l'ouverture).
// Les arguments de lancement -UITEST_* sont lus par UITestHooks (compilé en DEBUG seulement).
final class AuditCapturesTests: XCTestCase {
    private var app: XCUIApplication!

    private struct Passe {
        let nom: String
        let langue: String
        let locale: String
        let apparence: String
        let carte: String
        let liste: String
        let reglages: String
        let avis: String
        let annuler: String
        let fermer: String
        let alerte: String
        let etape1: String
    }

    private let francais = Passe(
        nom: "fr-clair", langue: "fr", locale: "fr_FR", apparence: "light",
        carte: "Carte", liste: "Liste", reglages: "Réglages", avis: "Donner mon avis",
        annuler: "Annuler", fermer: "Fermer", alerte: "Alerte près d'une boîte", etape1: "Étape 1 / 2 — Position"
    )

    override func setUpWithError() throws {
        continueAfterFailure = true
        app = XCUIApplication()
        // Demandes système (localisation, photos) : refusées, le parcours continue
        addUIInterruptionMonitor(withDescription: "Autorisations système") { alert in
            for label in ["Ne pas autoriser", "Don’t Allow", "Don't Allow"] where alert.buttons[label].exists {
                alert.buttons[label].tap()
                return true
            }
            return false
        }
    }

    // MARK: Passes

    func testPasse01FrClair() {
        parcourir(francais)
    }

    func testPasse02FrSombre() {
        parcourir(passe("fr-sombre", langue: "fr", locale: "fr_FR", apparence: "dark"))
    }

    func testPasse03EnClair() {
        parcourir(passe("en-clair", langue: "en", locale: "en_US", apparence: "light"))
    }

    func testPasse04EnSombre() {
        parcourir(passe("en-sombre", langue: "en", locale: "en_US", apparence: "dark"))
    }

    // MARK: Parcours

    private func parcourir(_ passe: Passe) {
        app.launchArguments = [
            "-UITEST_ACTIVE",
            "-UITEST_APPEARANCE", passe.apparence,
            "-UITEST_LOCATION", "45.8992,6.1294",
            "-AppleLanguages", "(\(passe.langue))",
            "-AppleLocale", passe.locale,
        ]
        app.launch()

        var rang = 0
        func ecran(_ nom: String) {
            rang += 1
            capture(passe.nom, rang, nom)
        }

        // 1. Carte (premier onglet)
        XCTAssertTrue(app.buttons[passe.carte].firstMatch.waitForExistence(timeout: 30), "onglet Carte absent")
        XCTAssertTrue(app.maps.firstMatch.waitForExistence(timeout: 30), "carte absente")
        ecran("carte")

        // 2. Liste
        app.buttons[passe.liste].firstMatch.tap()
        XCTAssertTrue(app.cells.firstMatch.waitForExistence(timeout: 40), "liste vide ou absente")
        ecran("liste")

        // 3. Fiche de la première boîte
        app.cells.firstMatch.tap()
        XCTAssertTrue(app.buttons[passe.avis].firstMatch.waitForExistence(timeout: 30), "fiche absente")
        ecran("fiche")

        // 4. Donner mon avis : vide, puis le bouton grisé est touché (il ne doit rien envoyer)
        app.buttons[passe.avis].firstMatch.tap()
        XCTAssertTrue(element("avis-envoyer").waitForExistence(timeout: 15), "feuille d'avis absente")
        ecran("avis-vide")
        element("avis-envoyer").tap()
        ecran("avis-bouton-grise-touche")
        app.buttons[passe.annuler].firstMatch.tap()

        // 5. Localisation : NON ouverte. Sa feuille géocode à l'ouverture (centerOnBox → CLGeocoder),
        // ce qui appelle Apple. L'écran n'est donc pas capturé par le test.
        noter("localisation : feuille non ouverte (géocodage Apple à l'ouverture)")

        // 6. Demander la suppression (même condition de distance)
        if toucherAvecDefilement(element("fiche-suppression")),
           element("suppression-envoyer").waitForExistence(timeout: 10) {
            ecran("suppression")
            app.buttons[passe.annuler].firstMatch.tap()
        } else {
            noter("suppression : bouton absent ou inactif (position simulée hors de la boîte)")
        }

        // 7. Ajouter une boîte, étape 1 seulement : l'étape 2 exige « Confirmer la position » (géocodage Apple)
        // Toucher l'onglet déjà sélectionné vide le chemin de la liste (retour à la racine)
        app.buttons[passe.liste].firstMatch.tap()
        if element("ajouter-boite-liste").waitForExistence(timeout: 10) {
            element("ajouter-boite-liste").tap()
            XCTAssertTrue(app.navigationBars[passe.etape1].waitForExistence(timeout: 15), "étape 1 absente")
            ecran("ajout-etape1")
            app.buttons[passe.annuler].firstMatch.tap()
        } else {
            XCTFail("bouton d'ajout absent de la liste")
        }

        // 8. Réglages
        app.buttons[passe.reglages].firstMatch.tap()
        XCTAssertTrue(app.navigationBars[passe.reglages].firstMatch.waitForExistence(timeout: 15), "réglages absents")
        ecran("reglages")

        // 9. Explication de l'alerte de proximité. Elle est activée par défaut (F01 M0036) : couper ne
        // montre rien ; c'est la remise en marche qui ouvre l'explication. On annule, donc rien n'est activé.
        let bascule = app.switches[passe.alerte].firstMatch
        if defilerJusquA(bascule) {
            if bascule.value as? String == "1" {
                // Couper ne montre rien : on attend que la valeur passe à 0 avant de rallumer
                basculerAvecDefilement(bascule)
                let coupee = expectation(for: NSPredicate(format: "value == %@", "0"), evaluatedWith: bascule)
                wait(for: [coupee], timeout: 10)
            }
            if basculerAvecDefilement(bascule), app.alerts.firstMatch.waitForExistence(timeout: 10) {
                ecran("alerte-explication")
                app.alerts.buttons[passe.annuler].firstMatch.tap()
            } else {
                XCTFail("explication d'alerte non atteinte")
            }
        } else {
            attacherTexte("hierarchie-\(passe.nom)-reglages", app.debugDescription)
            XCTFail("bascule d'alerte absente des réglages")
        }

        // 10. Écran de succès : non atteignable sans envoi (soumission ou photo), donc non capturé.
    }

    // MARK: Outils

    private func passe(_ nom: String, langue: String, locale: String, apparence: String) -> Passe {
        Passe(
            nom: nom, langue: langue, locale: locale, apparence: apparence,
            carte: langue == "fr" ? "Carte" : "Map",
            liste: langue == "fr" ? "Liste" : "List",
            reglages: langue == "fr" ? "Réglages" : "Settings",
            avis: langue == "fr" ? "Donner mon avis" : "Leave a review",
            annuler: langue == "fr" ? "Annuler" : "Cancel",
            fermer: langue == "fr" ? "Fermer" : "Close",
            alerte: langue == "fr" ? "Alerte près d'une boîte" : "Nearby box alert",
            etape1: langue == "fr" ? "Étape 1 / 2 — Position" : "Step 1 / 2 — Location"
        )
    }

    private func element(_ identifiant: String) -> XCUIElement {
        app.descendants(matching: .any)[identifiant].firstMatch
    }

    // Les listes SwiftUI sont paresseuses : un élément hors écran n'est pas dans l'arbre d'accessibilité.
    // On défile donc jusqu'à son apparition, puis jusqu'à ce qu'il soit touchable.
    private func defilerJusquA(_ el: XCUIElement, essais maximum: Int = 12) -> Bool {
        var essais = 0
        while !el.waitForExistence(timeout: 1) && essais < maximum {
            app.swipeUp()
            essais += 1
        }
        return el.exists
    }

    // Le cadre d'un contacteur couvre toute la ligne : son centre tombe sur le libellé, qui ne bascule pas.
    // On touche donc le bord droit, là où se trouve le contacteur.
    private func basculerAvecDefilement(_ el: XCUIElement) -> Bool {
        guard defilerJusquA(el) else { return false }
        var essais = 0
        while el.frame.midY > app.frame.height * 0.6 && essais < 8 {
            app.swipeUp()
            essais += 1
        }
        guard el.isHittable else { return false }
        el.coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.5)).tap()
        return true
    }

    // Défile jusqu'à rendre l'élément touchable, puis le touche. Renvoie false s'il n'apparaît pas.
    private func toucherAvecDefilement(_ el: XCUIElement) -> Bool {
        guard defilerJusquA(el) else { return false }
        // Remonte l'élément au-dessus de la barre d'onglets flottante : sous elle, le toucher part dans la barre
        var essais = 0
        while el.frame.midY > app.frame.height * 0.6 && essais < 8 {
            app.swipeUp()
            essais += 1
        }
        guard el.isHittable else { return false }
        el.tap()
        return true
    }

    // Écran attendu mais inatteignable dans ce contexte : noté comme activité, sans échec (donc sans collecte
    // de diagnostic, qui bloque xcodebuild plusieurs minutes)
    private func noter(_ constat: String) {
        XCTContext.runActivity(named: "NON ATTEINT — \(constat)") { _ in }
    }

    // Diagnostic joint seulement en cas d'échec (hiérarchie d'accessibilité en texte)
    private func attacherTexte(_ nom: String, _ contenu: String) {
        let piece = XCTAttachment(string: contenu)
        piece.name = nom
        piece.lifetime = .keepAlways
        add(piece)
    }

    private func capture(_ passe: String, _ rang: Int, _ ecran: String) {
        let piece = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        piece.name = String(format: "%@-%02d-%@", passe, rang, ecran)
        piece.lifetime = .keepAlways
        add(piece)
    }
}
