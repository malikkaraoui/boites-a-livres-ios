#!/usr/bin/env bash
# Audit visuel : lance les tests d'interface (FR/EN × clair/sombre) et range les captures par passe.
#
# Usage : scripts/ui-audit.sh <dossier-de-sortie>
#   ex. scripts/ui-audit.sh vault/revues/audit-M0055
#
# Résultat : <dossier-de-sortie>/<passe>/<passe>-<nn>-<ecran>.png
# Le bundle .xcresult part dans un dossier temporaire, supprimé à la sortie (rm sous garde).
set -euo pipefail

SORTIE="${1:?Usage : scripts/ui-audit.sh <dossier-de-sortie>}"
SIMULATEUR="${UI_AUDIT_SIMULATOR:-iPhone 17}"
SCHEME="BoitesALivresNative"

TMP="$(mktemp -d "${TMPDIR:-/tmp}/ui-audit.XXXXXX")"
nettoyer() {
    # Garde : ne supprime que le dossier créé ci-dessus
    case "$TMP" in
        */ui-audit.*) rm -rf -- "$TMP" ;;
        *) echo "Refus de supprimer $TMP (hors garde)" >&2 ;;
    esac
}
trap nettoyer EXIT

RESULTAT="$TMP/audit.xcresult"
EXPORT="$TMP/export"
mkdir -p "$EXPORT"

echo "=== Tests d'interface (simulateur : $SIMULATEUR) ==="
# Un échec de test ne coupe pas l'export : les captures déjà prises sont rangées, puis le code d'erreur sort.
STATUT=0
xcodebuild test \
    -scheme "$SCHEME" \
    -destination "platform=iOS Simulator,name=$SIMULATEUR" \
    -only-testing:BoitesALivresNativeUITests/AuditCapturesTests \
    -resultBundlePath "$RESULTAT" || STATUT=$?

echo "=== Export des captures ==="
xcrun xcresulttool export attachments --path "$RESULTAT" --output-path "$EXPORT" >/dev/null

mkdir -p "$SORTIE"
python3 - "$EXPORT" "$SORTIE" <<'PY'
import json, os, re, shutil, sys

export, sortie = sys.argv[1], sys.argv[2]
manifest = json.load(open(os.path.join(export, "manifest.json"), encoding="utf-8"))
suffixe = re.compile(r"_\d+_[0-9A-Fa-f-]{36}$")
total = 0
for test in manifest:
    for piece in test.get("attachments", []):
        nom = suffixe.sub("", os.path.splitext(piece["suggestedHumanReadableName"])[0])
        if not re.match(r"^(fr|en)-", nom):
            continue  # pas une capture d'écran de l'audit (hiérarchie, vidéo)
        passe = nom.split("-", 2)[0] + "-" + nom.split("-", 2)[1]
        dossier = os.path.join(sortie, passe)
        os.makedirs(dossier, exist_ok=True)
        shutil.copy(os.path.join(export, piece["exportedFileName"]), os.path.join(dossier, nom + ".png"))
        total += 1
print(f"{total} capture(s) écrite(s) dans {sortie}")
PY

if [ "$STATUT" -ne 0 ]; then
    echo "Tests en échec (code $STATUT) : voir les captures et le résultat ci-dessus." >&2
fi
exit "$STATUT"
