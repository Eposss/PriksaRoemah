import Foundation

// Dummy data untuk preview & collection awal
extension House {
    static let dummyAll: [House] = [
        House(
            name: "Rumah Cluster Anggrek",
            developer: "BSD City",
            harga: "1.800.000.000",
            luasTanah: "90",
            catatan: "Kondisi bagus, dekat sekolah",
            rooms: [
                Room(name: "Living Room", type: .livingRoom, floor: "1"),
                Room(name: "Kitchen",     type: .kitchen,    floor: "1"),
                Room(name: "Bedroom 1",   type: .bedroom,    floor: "1"),
                Room(name: "Bathroom",    type: .bathroom,   floor: "1")
            ],
            floorAreaSqM: 12.27,
            wallAreaSqM: 12.27,
            ceilingHeightM: 3.5
        ),
        House(
            name: "Rumah Alam Sutera",
            developer: "Sinar Mas Land",
            harga: "2.300.000.000",
            luasTanah: "120",
            catatan: "",
            rooms: [
                Room(name: "Living Room", type: .livingRoom,  floor: "1"),
                Room(name: "Kitchen",     type: .kitchen,     floor: "1"),
                Room(name: "Bedroom 1",   type: .bedroom,     floor: "1"),
                Room(name: "Bedroom 2",   type: .bedroom,     floor: "2"),
                Room(name: "Bathroom",    type: .bathroom,    floor: "1")
            ],
            floorAreaSqM: 18.0,
            wallAreaSqM: 20.5,
            ceilingHeightM: 3.2
        )
    ]
}
