import Foundation
import Observation

@Observable
@MainActor
final class TopicsStore {
    var topicsText: String {
        didSet { UserDefaults.standard.set(topicsText, forKey: "userTopics") }
    }

    var parsedTopics: [String] {
        topicsText
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    init() {
        self.topicsText = UserDefaults.standard.string(forKey: "userTopics") ?? ""
    }
}
