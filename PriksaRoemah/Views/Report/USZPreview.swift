//
//  USDZPreviewView.swift
//  HVMAN
//
//  3D view dari hasil scan RoomPlan, pakai SceneKit (bukan QuickLook) — QuickLook
//  cuma nampilin USDZ apa adanya, nggak bisa di-restyle. SceneKit tetap preserve
//  struktur node/prim yang sama kayak USD aslinya, dan `allowsCameraControl`
//  ngasih gesture orbit/pinch/pan gratis, sama kayak QuickLook.
//

import SwiftUI
import SceneKit

struct USDZPreviewView: UIViewRepresentable {
    let url: URL
    /// Dipanggil tiap user tap: elemen terukur, atau nil kalau tap area kosong.
    var onSelect: (MeasuredElement?) -> Void = { _ in }

    func makeCoordinator() -> Coordinator {
        Coordinator(onSelect: onSelect)
    }

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.allowsCameraControl = true
        view.autoenablesDefaultLighting = false
        view.backgroundColor = .clear
        view.antialiasingMode = .multisampling4X
        // Render di resolusi native layar (bukan default 1x) — tanpa ini,
        // model keliatan pecah/blocky pas di-pinch zoom karena SCNView cuma
        // punya sedikit pixel buat gambar tiap edge.
        view.contentScaleFactor = UIScreen.main.scale
        loadScene(into: view)

        context.coordinator.view = view
        let tap = UITapGestureRecognizer(target: context.coordinator,
                                         action: #selector(Coordinator.handleTap(_:)))
        tap.delegate = context.coordinator   // biar barengan sama gesture kamera
        view.addGestureRecognizer(tap)

        return view
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        context.coordinator.onSelect = onSelect
    }

    private func loadScene(into view: SCNView) {
        guard let scene = try? SCNScene(url: url, options: nil) else { return }
        RoomPlanSceneStyle.addLighting(to: scene)
        RoomPlanSceneStyle.recolorFurniture(in: scene)
        view.scene = scene
        // Paksa kamera awal nge-frame SELURUH model — kalau dibiarin default
        // (atau pake kamera bawaan file USDZ-nya sendiri), pertama dibuka bisa
        // zoomed-in banget dan bikin user kaget. User masih bisa pinch/pan/
        // rotate bebas dari titik awal ini (allowsCameraControl tetap nyala).
        view.pointOfView = RoomPlanSceneStyle.framingCamera(for: scene)
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        weak var view: SCNView?
        var onSelect: (MeasuredElement?) -> Void

        private weak var highlighted: SCNNode?
        private var savedEmission: [(material: SCNMaterial, contents: Any?)] = []

        init(onSelect: @escaping (MeasuredElement?) -> Void) {
            self.onSelect = onSelect
        }

        @objc func handleTap(_ gr: UITapGestureRecognizer) {
            guard let view else { return }
            let point = gr.location(in: view)
            let hits = view.hitTest(point, options: [
                .searchMode: SCNHitTestSearchMode.closest.rawValue
            ])
            if let hitNode = hits.first?.node,
               let named = RoomPlanMeasure.namedElementNode(from: hitNode) {
                highlight(named)
                onSelect(RoomPlanMeasure.element(for: named))
            } else {
                clearHighlight()
                onSelect(nil)
            }
        }

        private func highlight(_ node: SCNNode) {
            guard node !== highlighted else { return }
            clearHighlight()
            guard let materials = node.geometry?.materials else { return }
            for m in materials {
                savedEmission.append((m, m.emission.contents))
                m.emission.contents = UIColor(red: 0.910, green: 0.349, blue: 0.090, alpha: 1)
            }
            highlighted = node
        }

        private func clearHighlight() {
            for saved in savedEmission { saved.material.emission.contents = saved.contents }
            savedEmission.removeAll()
            highlighted = nil
        }

        // Jalan barengan dengan gesture orbit/pinch/pan bawaan allowsCameraControl.
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
            true
        }
    }
}

/// Lighting & material restyle buat hasil export RoomPlan — dipisah dari
/// USDZPreviewView biar gampang dites pakai scene buatan sendiri (lihat
/// #Preview di bawah), nggak perlu file USDZ asli.
///
/// Node furniture dikenali dari NAMA node, bukan ditebak — udah dikonfirmasi
/// dari dump node hasil scan asli (device): RoomPlan ngasih nama "<Category><index>"
/// persis kayak rawValue RoomPlan.CapturedRoom.Object.Category (mis. "Storage0",
/// "Table0"), sedangkan shell ruangan namanya "Wall0..N", "Door0", "Window0",
/// "Floor0". Jadi tinggal strip angka di belakang nama terus cocokin ke daftar
/// kategori furniture — wall/floor/door/window otomatis nggak kena karena nggak
/// ada di daftar itu.
enum RoomPlanSceneStyle {

    /// Sama persis dengan RoomPlan.CapturedRoom.Object.Category.allCases (lowercased).
    static let furnitureCategories: Set<String> = [
        "storage", "refrigerator", "stove", "bed", "sink", "washerdryer",
        "toilet", "bathtub", "oven", "dishwasher", "table", "sofa",
        "chair", "fireplace", "television", "stairs"
    ]

    static func addLighting(to scene: SCNScene) {
        let ambient = SCNLight()
        ambient.type = .ambient
        ambient.intensity = 400
        ambient.color = UIColor.white
        let ambientNode = SCNNode()
        ambientNode.light = ambient
        scene.rootNode.addChildNode(ambientNode)

        let directional = SCNLight()
        directional.type = .directional
        directional.intensity = 900
        directional.castsShadow = true
        directional.shadowMode = .deferred
        directional.shadowColor = UIColor.black.withAlphaComponent(0.3)
        let directionalNode = SCNNode()
        directionalNode.light = directional
        directionalNode.eulerAngles = SCNVector3(-Float.pi / 3, Float.pi / 4, 0)
        scene.rootNode.addChildNode(directionalNode)
    }

    /// Wall/floor/door/window dibiarkan putih bawaan RoomPlan — cuma furniture
    /// yang di-restyle jadi graphite gelap dengan sedikit sheen (PBR roughness +
    /// metalness) biar keliatan lebih "hidup", nggak flat kayak kotak dicat rata.
    static func recolorFurniture(in scene: SCNScene) {
        walk(scene.rootNode) { node in
            guard let geometry = node.geometry, isFurniture(nodeName: node.name) else { return }
            for material in geometry.materials {
                material.lightingModel = .physicallyBased
                material.diffuse.contents = UIColor(white: 0.16, alpha: 1)
                material.roughness.contents = 0.35
                material.metalness.contents = 0.15
            }
        }
    }

    /// Bikin node kamera baru yang di-posisiin biar SELURUH bounding sphere
    /// scene kelihatan (sudut agak dari atas & serong, kayak isometric denah),
    /// terus dipasang sebagai `pointOfView` awal SCNView — nggak ngandelin
    /// kamera bawaan file USDZ atau auto-framing default SceneKit yang kadang
    /// kezoom kejauhan ke 1 titik.
    static func framingCamera(for scene: SCNScene) -> SCNNode? {
        let (center, radius) = scene.rootNode.boundingSphere
        guard radius > 0 else { return nil }

        let camera = SCNCamera()
        camera.fieldOfView = 50
        camera.zNear = 0.01
        camera.zFar = 100

        let cameraNode = SCNNode()
        cameraNode.camera = camera

        let fovRadians = Float(camera.fieldOfView) * .pi / 180
        // Margin 1.4x biar model nggak mepet banget ke tepi layar.
        let distance = (radius / sin(fovRadians / 2)) * 1.4

        let azimuth: Float = .pi / 4
        let elevation: Float = .pi / 5
        cameraNode.position = SCNVector3(
            center.x + distance * cos(elevation) * sin(azimuth),
            center.y + distance * sin(elevation),
            center.z + distance * cos(elevation) * cos(azimuth)
        )
        cameraNode.look(at: center)

        scene.rootNode.addChildNode(cameraNode)
        return cameraNode
    }

    private static func isFurniture(nodeName: String?) -> Bool {
        guard var name = nodeName?.lowercased() else { return false }
        while let last = name.last, last.isNumber { name.removeLast() }
        return furnitureCategories.contains(name)
    }

    private static func walk(_ node: SCNNode, _ body: (SCNNode) -> Void) {
        body(node)
        for child in node.childNodes { walk(child, body) }
    }
}

// MARK: - Tap-to-measure

/// Hasil pengukuran satu elemen yang di-tap di 3D view — nama + ukuran (meter).
struct MeasuredElement: Equatable {
    let label: String
    let detail: String
}

/// Menghitung ukuran nyata (meter) tiap node hasil export RoomPlan, berdasarkan
/// NAMA node ("Wall0", "Door0", "Window0", "Floor0", atau "<Category><index>"
/// buat furniture) + bounding box-nya. Dipisah dari view supaya bisa dites
/// sintetis (lihat #Preview) tanpa perlu file USDZ / device.
enum RoomPlanMeasure {

    private static let structuralNames: Set<String> = ["wall", "door", "window", "opening", "floor"]

    /// Nama tampil yang lebih ramah dari base-name node RoomPlan.
    private static func displayLabel(for base: String) -> String {
        switch base {
        case "washerdryer": return "Washer / Dryer"
        case "television":  return "Television"
        default:            return base.prefix(1).uppercased() + base.dropFirst()
        }
    }

    /// Base-name: strip index angka di belakang + lowercase. "Table0" -> "table".
    private static func baseName(_ name: String?) -> String? {
        guard var n = name?.lowercased() else { return nil }
        while let last = n.last, last.isNumber { n.removeLast() }
        return n.isEmpty ? nil : n
    }

    private static func isKnownElement(_ base: String) -> Bool {
        structuralNames.contains(base) || RoomPlanSceneStyle.furnitureCategories.contains(base)
    }

    /// Cari node "bermakna" mulai dari node yang ke-hit, naik ke parent kalau
    /// perlu (kadang geometry ada di child tanpa nama).
    static func namedElementNode(from node: SCNNode) -> SCNNode? {
        var current: SCNNode? = node
        while let n = current {
            if let base = baseName(n.name), isKnownElement(base) { return n }
            current = n.parent
        }
        return nil
    }

    /// Ukuran node dalam meter: extent bounding box lokal × skala world-transform
    /// per-sumbu (robust terhadap unit-scale RoomPlan/USD yang kadang ditaruh di
    /// node root, bukan di node elemennya sendiri).
    static func worldSize(of node: SCNNode) -> SIMD3<Float> {
        let (minB, maxB) = node.boundingBox
        let local = SIMD3<Float>(
            Float(maxB.x - minB.x),
            Float(maxB.y - minB.y),
            Float(maxB.z - minB.z)
        )
        let wt = node.simdWorldTransform
        let sx = simd_length(SIMD3<Float>(wt.columns.0.x, wt.columns.0.y, wt.columns.0.z))
        let sy = simd_length(SIMD3<Float>(wt.columns.1.x, wt.columns.1.y, wt.columns.1.z))
        let sz = simd_length(SIMD3<Float>(wt.columns.2.x, wt.columns.2.y, wt.columns.2.z))
        return SIMD3<Float>(local.x * sx, local.y * sy, local.z * sz)
    }

    static func element(for node: SCNNode) -> MeasuredElement? {
        guard let named = namedElementNode(from: node),
              let base = baseName(named.name), isKnownElement(base) else { return nil }

        let s = worldSize(of: named)
        func f(_ v: Float) -> String { String(format: "%.2f", v) }

        let detail: String
        switch base {
        case "wall", "door", "window", "opening":
            // x = panjang/lebar bukaan, y = tinggi. Ketebalan (z) di-skip
            // karena surface RoomPlan tipis (~0) dan angkanya noisy.
            detail = "\(f(s.x)) × \(f(s.y)) m"
        case "floor":
            detail = "\(f(s.x)) × \(f(s.z)) m"
        default:
            // Furniture: W × D × H (x × z × y).
            detail = "\(f(s.x)) × \(f(s.z)) × \(f(s.y)) m"
        }
        return MeasuredElement(label: displayLabel(for: base), detail: detail)
    }
}

/// Wrapper dengan empty state kalau USDZ belum ada (mis. belum ada ruangan yang
/// di-scan). Nggak nge-set height sendiri — ngisi penuh apa pun yang dikasih
/// parent (lihat pemanggilnya di ReviewScanView/ReportView), soalnya preview
/// yang kekecilan bikin hasil pinch-zoom keliatan pecah/blocky.
struct House3DView: View {
    let usdzURL: URL?
    @State private var selected: MeasuredElement?

    var body: some View {
        Group {
            if let usdzURL {
                USDZPreviewView(url: usdzURL) { selected = $0 }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(alignment: .top) {
                        if selected == nil {
                            Text("Tap an element to measure")
                                .font(.footnote.weight(.medium))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.ultraThinMaterial, in: Capsule())
                                .padding(.top, 12)
                        }
                    }
                    .overlay(alignment: .bottom) {
                        if let selected {
                            measurementCallout(selected)
                                .padding(16)
                        }
                    }
            } else {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.systemGray6))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "cube.transparent")
                                .font(.system(size: 36))
                                .foregroundStyle(.secondary)
                            Text("Model 3D belum tersedia")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    )
            }
        }
        .padding(.horizontal)
    }

    private func measurementCallout(_ element: MeasuredElement) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(element.label)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(element.detail)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color(red: 0.910, green: 0.349, blue: 0.090))
            }
            Spacer()
            Button {
                selected = nil
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .frame(maxWidth: .infinity)
    }
}

#Preview("Furniture recolor sanity check") {
    let scene = SCNScene()

    let floor = SCNNode(geometry: SCNBox(width: 4, height: 0.05, length: 3, chamferRadius: 0))
    floor.name = "Floor0"
    floor.geometry?.firstMaterial?.diffuse.contents = UIColor(white: 0.98, alpha: 1)
    floor.position = SCNVector3(0, -0.5, 0)
    scene.rootNode.addChildNode(floor)

    let sofa = SCNNode(geometry: SCNBox(width: 1.2, height: 0.8, length: 0.6, chamferRadius: 0.05))
    sofa.name = "Sofa0"
    sofa.geometry?.firstMaterial?.diffuse.contents = UIColor.white
    sofa.position = SCNVector3(-0.8, 0, 0)
    scene.rootNode.addChildNode(sofa)

    let table = SCNNode(geometry: SCNBox(width: 0.8, height: 0.4, length: 0.8, chamferRadius: 0.02))
    table.name = "Table0"
    table.geometry?.firstMaterial?.diffuse.contents = UIColor.white
    table.position = SCNVector3(0.8, -0.2, 0.4)
    scene.rootNode.addChildNode(table)

    RoomPlanSceneStyle.addLighting(to: scene)
    RoomPlanSceneStyle.recolorFurniture(in: scene)

    return SceneView(scene: scene, options: [.allowsCameraControl])
        .background(Color(.systemGray6))
        .frame(height: 300)
}
