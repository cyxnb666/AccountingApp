import Foundation

class ExpenseDataManager: ObservableObject {
    @Published var expenses: [Expense] = []
    @Published var categories: [ExpenseCategory] = [
        ExpenseCategory(id: "food", name: "餐饮", icon: "fork.knife"),
        ExpenseCategory(id: "transport", name: "交通", icon: "car"),
        ExpenseCategory(id: "entertainment", name: "娱乐", icon: "tv"),
        ExpenseCategory(id: "shopping", name: "购物", icon: "bag"),
        ExpenseCategory(id: "medical", name: "医疗", icon: "cross"),
        ExpenseCategory(id: "gift", name: "人情", icon: "gift"),
        ExpenseCategory(id: "bills", name: "缴费", icon: "lightbulb"),
        ExpenseCategory(id: "other", name: "其他", icon: "shippingbox")
    ]
    @Published var monthlyBudget: Double = 5000.0
    
    private let userDefaults = UserDefaults.standard
    private let expensesKey = "SavedExpenses"
    private let categoriesKey = "SavedCategories"
    private let budgetKey = "MonthlyBudget"
    
    init() {
        loadExpenses()
        loadCategories()
        loadBudget()
    }
    
    func addExpense(_ expense: Expense) {
        expenses.append(expense)
        saveExpenses()
    }
    
    func deleteExpense(at index: Int) {
        expenses.remove(at: index)
        saveExpenses()
    }
    
    func clearAllData() {
        expenses.removeAll()
        saveExpenses()
    }
    
    func addCategory(_ category: ExpenseCategory) {
        categories.append(category)
        saveCategories()
    }
    
    func deleteCategory(_ category: ExpenseCategory) {
        categories.removeAll { $0.id == category.id }
        saveCategories()
    }
    
    func updateCategory(_ category: ExpenseCategory) {
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            categories[index] = category
            saveCategories()
        }
    }
    
    func updateBudget(_ budget: Double) {
        monthlyBudget = budget
        saveBudget()
    }
    
    private func saveExpenses() {
        if let encoded = try? JSONEncoder().encode(expenses) {
            userDefaults.set(encoded, forKey: expensesKey)
        }
    }
    
    private func loadExpenses() {
        if let data = userDefaults.data(forKey: expensesKey),
           let decoded = try? JSONDecoder().decode([Expense].self, from: data) {
            expenses = decoded
        }
    }
    
    private func saveCategories() {
        if let encoded = try? JSONEncoder().encode(categories) {
            userDefaults.set(encoded, forKey: categoriesKey)
        }
    }
    
    private func loadCategories() {
        if let data = userDefaults.data(forKey: categoriesKey),
           let decoded = try? JSONDecoder().decode([ExpenseCategory].self, from: data) {
            categories = decoded
        }
    }
    
    private func saveBudget() {
        userDefaults.set(monthlyBudget, forKey: budgetKey)
    }
    
    private func loadBudget() {
        monthlyBudget = userDefaults.double(forKey: budgetKey)
        if monthlyBudget == 0 {
            monthlyBudget = 5000.0
        }
    }
    
    func importHistoricalData(from url: URL) {
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            let historicalExpenses = parseHistoricalData(from: content)
            expenses.append(contentsOf: historicalExpenses)
            saveExpenses()
        } catch {
            print("导入文件失败: \(error)")
        }
    }
    
    private func parseHistoricalData(from content: String) -> [Expense] {
        var results: [Expense] = []
        let calendar = Calendar.current
        
        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        
        for line in lines {
            let parts = line.components(separatedBy: ",")
            guard parts.count == 6,
                  let year = Int(parts[0].trimmingCharacters(in: .whitespacesAndNewlines)),
                  let month = Int(parts[1].trimmingCharacters(in: .whitespacesAndNewlines)),
                  let day = Int(parts[2].trimmingCharacters(in: .whitespacesAndNewlines)),
                  let amount = Double(parts[3].trimmingCharacters(in: .whitespacesAndNewlines)) else { continue }
            
            let description = parts[4].trimmingCharacters(in: .whitespacesAndNewlines)
            let categoryName = parts[5].trimmingCharacters(in: .whitespacesAndNewlines)
            
            let components = DateComponents(year: year, month: month, day: day)
            let date = calendar.date(from: components) ?? Date()
            
            let expense = Expense(
                id: UUID(),
                amount: amount,
                description: description,
                category: categoryIdFromName(categoryName),
                date: date
            )
            results.append(expense)
        }
        
        return results
    }
    
    private func categoryIdFromName(_ name: String) -> String {
        switch name {
        case "餐饮": return "food"
        case "交通": return "transport"
        case "娱乐": return "entertainment"
        case "购物": return "shopping"
        case "医疗": return "medical"
        case "人情": return "gift"
        case "缴费": return "bills"
        default: return "other"
        }
    }
}