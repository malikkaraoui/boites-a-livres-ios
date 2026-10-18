import sys
p=sys.argv[1]
s=open(p).read()
def rep(a,b,opt=False):
    global s
    if opt and s.count(a)==0: return
    assert s.count(a)==1, a
    s=s.replace(a,b)
probe=open(sys.argv[2]).read().split('import MapKit\n',1)[1].split('// MARK: - Map View',1)[0]
rep('import MapKit\n','import MapKit\n'+probe)
rep('''                    TapGesture().onEnded {
                        guard''','''                    TapGesture().onEnded {
                        m19.notice("MAPTAP handling=\\(isHandlingAnnotationTap) selected=\\(vm.selectedBox?.id ?? -1)")
                        guard''')
rep('''                                .onTapGesture { selectBox(box) }
''','''                                .onTapGesture { selectBox(box) }
                                .accessibilityElement()
                                .accessibilityIdentifier("pin-\\(box.id)") // M0019-INSTRUMENT
                                .accessibilityValue(box.photo_url != nil ? "photo" : "nophoto")
''')
import re
m=re.search(r'            \.sheet\(item: ([^)]*)\) \{ (\w+) in', s)
rep(m.group(0), '''            .onChange(of: vm.selectedBox?.id) { o, n in m19.notice("SELECTED \\(o ?? -1) -> \\(n ?? -1)") }
            .onChange(of: sheetDetent) { o, n in m19.notice("DETENT \\(String(describing: o), privacy: .public) -> \\(String(describing: n), privacy: .public)") }
            .sheet(item: %s, onDismiss: { m19.notice("ONDISMISS") }) { %s in''' % (m.group(1), m.group(2)))
rep('''                .presentationDragIndicator(.visible)''','''                .background(GeometryReader { g in
                    Color.clear
                        .onAppear { m19.notice("CONTENT appear box=\\(box.id) h=\\(Int(g.size.height))") }
                        .onChange(of: Int(g.size.height)) { _, h in m19.notice("CONTENT box=\\(box.id) h=\\(h)") }
                        .onDisappear { m19.notice("CONTENT disappear box=\\(box.id)") }
                })
                .background(M19Probe(tag: 0).frame(width: 0, height: 0))
                .presentationDragIndicator(.visible)''')
rep('''    private func selectBox(_ box: BookBox) {
''','''    private func selectBox(_ box: BookBox) {
        m19.notice("SELECTBOX box=\\(box.id) current=\\(vm.selectedBox?.id ?? -1) handling=\\(isHandlingAnnotationTap)")
''')
rep('''            DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
''','''            DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
                m19.notice("REOPEN after 0.32 box=\\(box.id)")
''', opt=True)
open(p,'w').write(s)
