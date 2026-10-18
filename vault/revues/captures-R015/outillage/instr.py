# Instrumentation R015 (copie scratch uniquement) : journal os_log "R015" + sonde UIKit des détentes
import sys, re
p = sys.argv[1]
s = open(p).read()
def rep(a, b):
    global s
    assert s.count(a) == 1, ("motif absent ou multiple", a)
    s = s.replace(a, b)
probe = '''import os
let r15 = Logger(subsystem: "R015", category: "sheet")
struct R15Probe: UIViewRepresentable {
    let tag: Int
    func makeUIView(context: Context) -> R15ProbeView { let v = R15ProbeView(); v.tag = tag; return v }
    func updateUIView(_ v: R15ProbeView, context: Context) { v.tag = tag; v.report() }
}
final class R15ProbeView: UIView {
    var last = ""
    override func layoutSubviews() { super.layoutSubviews(); report() }
    override func didMoveToWindow() { super.didMoveToWindow(); report() }
    func report() {
        var r: UIResponder? = self
        while let n = r, !(n is UIViewController) { r = n.next }
        guard var vc = r as? UIViewController else { return }
        while let p = vc.parent { vc = p }
        let sp = vc.sheetPresentationController
        let ids = sp?.detents.map { $0.identifier.rawValue }.joined(separator: ",") ?? "nil"
        let sel = sp?.selectedDetentIdentifier?.rawValue ?? "nil"
        let h = vc.view.window == nil ? -1 : Int(vc.view.frame.height)
        let y = vc.view.window == nil ? -1 : Int(vc.view.frame.minY)
        let line = "box=\\(tag) vc=\\(ObjectIdentifier(vc).hashValue) detents=[\\(ids)] selected=\\(sel) h=\\(h) y=\\(y) presenting=\\(vc.isBeingPresented)"
        if line != last { last = line; r15.notice("PROBE \\(line, privacy: .public)") }
    }
}
'''
rep('import MapKit\n', 'import MapKit\n' + probe)
rep('''                    TapGesture().onEnded {
''', '''                    TapGesture().onEnded {
                        r15.notice("MAPTAP handling=\\(isHandlingAnnotationTap) selected=\\(vm.selectedBox?.id ?? -1)")
''')
rep('''                                .onTapGesture { selectBox(box) }
''', '''                                .onTapGesture { selectBox(box) }
                                .accessibilityElement()
                                .accessibilityIdentifier("pin-\\(box.id)")
                                .accessibilityValue(box.photo_url != nil ? "photo" : "nophoto")
''')
m = re.search(r'            \.sheet\(item: ([^)]*)\) \{ (\w+) in', s)
rep(m.group(0), '''            .onChange(of: vm.selectedBox?.id) { o, n in r15.notice("SELECTED \\(o ?? -1) -> \\(n ?? -1)") }
            .sheet(item: %s, onDismiss: { r15.notice("ONDISMISS") }) { %s in''' % (m.group(1), m.group(2)))
rep('''                .presentationDragIndicator(.visible)''', '''                .background(R15Probe(tag: box.id).frame(width: 0, height: 0))
                .presentationDragIndicator(.visible)''')
rep('''    private func selectBox(_ box: BookBox) {
''', '''    private func selectBox(_ box: BookBox) {
        r15.notice("SELECTBOX box=\\(box.id) current=\\(vm.selectedBox?.id ?? -1) handling=\\(isHandlingAnnotationTap)")
''')
open(p, 'w').write(s)
print("ok", p)
