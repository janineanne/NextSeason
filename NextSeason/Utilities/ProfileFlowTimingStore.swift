//
//  ProfileFlowTimingStore.swift
//  NextSeason
//

import Foundation

/// Persists `-ProfileFlow` timings for uninstrumented device runs (pulled via devicectl).
enum ProfileFlowTimingStore {
    private nonisolated static let fileName = "profile-flow-timing.jsonl"

    nonisolated static var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
    }

    nonisolated static func clear() {
        try? FileManager.default.removeItem(at: fileURL)
    }

    nonisolated static func append(flow: String, durationMs: Int, phase: String? = nil) {
        var payload: [String: Any] = [
            "flow": flow,
            "duration_ms": durationMs,
            "timestamp": ISO8601DateFormatter().string(from: Date()),
        ]
        if let phase {
            payload["phase"] = phase
        }
        guard let data = try? JSONSerialization.data(withJSONObject: payload),
            let line = String(data: data, encoding: .utf8)
        else { return }
        let out = line + "\n"
        if FileManager.default.fileExists(atPath: fileURL.path) {
            if let handle = try? FileHandle(forWritingTo: fileURL) {
                defer { try? handle.close() }
                _ = try? handle.seekToEnd()
                try? handle.write(contentsOf: Data(out.utf8))
            }
        } else {
            try? out.write(to: fileURL, atomically: true, encoding: .utf8)
        }
    }
}
