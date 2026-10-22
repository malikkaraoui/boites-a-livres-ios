#!/usr/bin/env python3
"""Contrôle de localisation anglaise, à partir de l'export Xcode.

Usage :
  xcodebuild -exportLocalizations -project BoitesALivresNative.xcodeproj \
    -localizationPath <dossier_tmp> -exportLanguage en
  python3 scripts/check_xliff.py "<dossier_tmp>/en.xcloc/Localized Contents/en.xliff"

Chaque unité de traduction doit avoir une cible anglaise non vide.
Sortie non nulle sinon. Ce contrôle lit ce qu'Xcode extrait du code et des catalogues.
"""
import sys
import xml.etree.ElementTree as ET

NS = '{urn:oasis:names:tc:xliff:document:1.2}'


def main(path):
    total = 0
    missing = []
    for unit in ET.parse(path).getroot().iter(NS + 'trans-unit'):
        total += 1
        target = unit.find(NS + 'target')
        if target is None or not (target.text or '').strip():
            source = unit.find(NS + 'source')
            missing.append((unit.get('id'), (source.text or '') if source is not None else ''))
    for key, source in missing:
        print(f"SANS CIBLE : {key} | {source[:90]}")
    print(f"unités : {total} | sans cible : {len(missing)}")
    return 1 if missing or total == 0 else 0


if __name__ == '__main__':
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    sys.exit(main(sys.argv[1]))
