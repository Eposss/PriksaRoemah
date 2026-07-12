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
        return view
    }

    func updateUIView(_ uiView: SCNView, context: Context) {}

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
    private static let furnitureCategories: Set<String> = [
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

/// Wrapper dengan empty state kalau USDZ belum ada (mis. belum ada ruangan yang
/// di-scan). Nggak nge-set height sendiri — ngisi penuh apa pun yang dikasih
/// parent (lihat pemanggilnya di ReviewScanView/ReportView), soalnya preview
/// yang kekecilan bikin hasil pinch-zoom keliatan pecah/blocky.
struct House3DView: View {
    let usdzURL: URL?

    var body: some View {
        Group {
            if let usdzURL {
                USDZPreviewView(url: usdzURL)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
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
