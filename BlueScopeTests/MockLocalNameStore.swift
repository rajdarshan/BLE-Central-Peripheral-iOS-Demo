import Foundation
@testable import BlueScope

final class MockLocalNameStore: LocalNamePersisting {
    var storedName: String?
    private(set) var savedNames: [String] = []

    func loadLocalName() -> String? {
        storedName
    }

    func save(localName: String) {
        storedName = localName
        savedNames.append(localName)
    }
}
