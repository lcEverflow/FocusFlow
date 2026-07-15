import Foundation

/// 持久化抽象：后续要换 SwiftData / CloudKit / 多设备同步时只需替换实现。
protocol DataStore {
    func load<T: Decodable>(_ type: T.Type, from file: String) -> T?
    func save<T: Encodable>(_ value: T, to file: String)
    func remove(file: String)
}

/// 基于 JSON 文件的默认实现，数据落在 ~/Library/Application Support/FocusFlow/。
/// 数据量为个人任务级别，整文件原子写足够；格式对人类可读，方便手工检查/迁移。
final class JSONFileStore: DataStore {
    private let directory: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(directoryName: String = "FocusFlow") {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        directory = base.appendingPathComponent(directoryName, isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    private func url(for file: String) -> URL {
        directory.appendingPathComponent(file)
    }

    func load<T: Decodable>(_ type: T.Type, from file: String) -> T? {
        guard let data = try? Data(contentsOf: url(for: file)) else { return nil }
        return try? decoder.decode(type, from: data)
    }

    func save<T: Encodable>(_ value: T, to file: String) {
        guard let data = try? encoder.encode(value) else { return }
        try? data.write(to: url(for: file), options: .atomic)
    }

    func remove(file: String) {
        try? FileManager.default.removeItem(at: url(for: file))
    }
}
