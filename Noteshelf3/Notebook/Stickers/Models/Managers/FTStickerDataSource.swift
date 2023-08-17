import Foundation

class FTStickerDataSource: NSObject {
    class func loadData() -> FTStickerContainerResponseModel? {
        guard let infoPlistPath = Bundle.main.url(forResource: "Stickers", withExtension: "plist") else {
            fatalError("Plist URL Path not found")
        }
        do {
            let infoPlistData = try Data(contentsOf: infoPlistPath)
            return try  PropertyListDecoder().decode(FTStickerContainerResponseModel.self, from: infoPlistData)
        } catch {
            fatalError("Error in data parsing \(error)")
        }
    }
}
