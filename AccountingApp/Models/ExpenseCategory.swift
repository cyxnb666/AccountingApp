import Foundation

struct ExpenseCategory: Identifiable, Codable {
    let id: String
    var name: String
    var icon: String
}