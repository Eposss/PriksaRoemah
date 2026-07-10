import Foundation

/// Rute navigasi alur survey (Instruction -> Scanning -> ReviewScan -> FloorsList),
/// dipakai sebagai satu `path: [SurveyRoute]` yang di-share dari HomeView ke bawah.
///
/// Kenapa bukan NavigationLink/`.navigationDestination(isPresented:)` biasa: waktu
/// tiap layar push sendiri-sendiri, stack-nya numpuk 4-5 level dalam (Home ->
/// Instruction -> Scanning -> ReviewScan -> FloorsList) dengan back button
/// disembunyikan di tengah jalan — user kejebak, nggak bisa balik ke koleksi survey
/// walau data-nya sudah tersimpan. Dengan path array bersama, begitu save berhasil
/// kita bisa langsung `path = [.floorsList(id)]` — reset ke Home lalu push FloorsList
/// dalam satu langkah, jadi stack-nya cuma 1 level dalam & back button FloorsList
/// balik pas ke koleksi survey.
enum SurveyRoute: Hashable {
    case instruction(houseID: UUID?)
    case scanning(houseID: UUID?)
    case reviewScan(houseID: UUID?)
    case floorsList(houseID: UUID)
}
