import Foundation

extension House {

    static let dummyAll: [House] = [

        House(
            name: "Cluster Magnolia",
            developer: "HVMAN Property",
            harga: "Rp 1.800.000.000",
            luasTanah: "90 m²",
            catatan: "Rumah contoh untuk preview survey.",
            facing: .northEast,
            floors: [
                Floor(
                    label: "Floor 1",
                    rooms: [
                        Room(name: "Living Room", type: .livingRoom, widthM: 4, lengthM: 5),
                        Room(name: "Kitchen", type: .kitchen, widthM: 3, lengthM: 3),
                        Room(name: "Master Bedroom", type: .bedroom, widthM: 3, lengthM: 4),
                        Room(name: "Bathroom", type: .bathroom, widthM: 2, lengthM: 2)
                    ],
                    floorAreaSqM: 72,
                    wallAreaSqM: 148,
                    ceilingHeightM: 3.0,
                    notes: "Bahan bangunan: bata merah. Tidak ada jamur."
                )
            ]
        ),

        House(
            name: "The Avani Residence",
            developer: "HVMAN Property",
            harga: "Rp 2.450.000.000",
            luasTanah: "120 m²",
            catatan: "Unit dummy untuk dashboard dan report.",
            facing: .east,
            floors: [
                Floor(
                    label: "Floor 1",
                    rooms: [
                        Room(name: "Living Room", type: .livingRoom, widthM: 4, lengthM: 5),
                        Room(name: "Kitchen", type: .kitchen, widthM: 3, lengthM: 3),
                        Room(name: "Bedroom 1", type: .bedroom, widthM: 3, lengthM: 4),
                        Room(name: "Garage", type: .garage, widthM: 3, lengthM: 5)
                    ],
                    floorAreaSqM: 60,
                    wallAreaSqM: 120,
                    ceilingHeightM: 3.2
                ),
                Floor(
                    label: "Floor 2",
                    rooms: [
                        Room(name: "Bedroom 2", type: .bedroom, widthM: 4, lengthM: 4),
                        Room(name: "Bathroom", type: .bathroom, widthM: 2, lengthM: 2)
                    ],
                    floorAreaSqM: 36,
                    wallAreaSqM: 64,
                    ceilingHeightM: 3.0
                )
            ]
        )
    ]
}
