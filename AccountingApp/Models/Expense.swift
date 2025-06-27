import Foundation

struct Expense: Identifiable, Codable {
    let id: UUID
    let amount: Double
    let description: String
    let category: String
    let date: Date
    
    var categoryIcon: String {
        switch category {
        case "food": return "fork.knife"
        case "transport": return "car"
        case "entertainment": return "tv"
        case "shopping": return "bag"
        case "medical": return "cross"
        case "gift": return "gift"
        case "bills": return "lightbulb"
        default: return "shippingbox"
        }
    }
    
    var categoryName: String {
        switch category {
        case "food": return "餐饮"
        case "transport": return "交通"
        case "entertainment": return "娱乐"
        case "shopping": return "购物"
        case "medical": return "医疗"
        case "gift": return "人情"
        case "bills": return "缴费"
        default: return "其他"
        }
    }
}