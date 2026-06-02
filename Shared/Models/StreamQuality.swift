import Foundation

struct StreamQuality: Hashable {
	let label: String
	let url: URL
	let bandwidth: Int
}

extension StreamQuality: Identifiable {
	var id: String { "\(label)_\(bandwidth)" }
}

extension StreamQuality: Equatable {
	static func == (lhs: Self, rhs: Self) -> Bool {
		return lhs.id == rhs.id
	}
}
