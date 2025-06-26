// AccountingApp.swift
import SwiftUI

@main
struct AccountingApp: App {
    @StateObject private var dataManager = ExpenseDataManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataManager)
                .onAppear {
                    // 锁定竖屏方向
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                        windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
                    }
                }
        }
        .windowResizability(.contentSize)
    }
}

// 如果需要数据持久化，可以添加这个数据管理器
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
            monthlyBudget = 5000.0 // 默认预算
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

// 支出数据模型
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

// 支出分类数据模型
struct ExpenseCategory: Identifiable, Codable {
    let id: String
    var name: String
    var icon: String
}

// 扩展Date以便于格式化
extension Date {
    func formatted(style: DateFormatter.Style) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: self)
    }
    
    func timeFormatted() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: self)
    }
    
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    var monthYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: self)
    }
}

// 数字格式化扩展
extension Double {
    var currencyFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "¥"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: NSNumber(value: self)) ?? "¥0"
    }
}

// 如果使用数据管理器，需要在ContentView中注入
struct ContentViewWithDataManager: View {
    @StateObject private var dataManager = ExpenseDataManager()
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            TabView(selection: $selectedTab) {
                AddExpenseViewWithDataManager()
                    .environmentObject(dataManager)
                    .tag(0)
                
                MonthlyRecordsView()
                    .environmentObject(dataManager)
                    .tag(1)
                
                StatisticsView()
                    .environmentObject(dataManager)
                    .tag(2)
                
                SettingsView()
                    .tag(3)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            
            VStack {
                Spacer()
                CustomTabBar(selectedTab: $selectedTab)
            }
        }
        .onAppear {
            UITabBar.appearance().isHidden = true
        }
    }
}

// 扩展版本的AddExpenseView，集成数据管理功能
struct AddExpenseViewWithDataManager: View {
    @EnvironmentObject var dataManager: ExpenseDataManager
    @State private var amount = ""
    @State private var description = ""
    @State private var selectedCategory = "food"
    @State private var showingSuccessAlert = false
    @State private var isButtonPressed = false
    @State private var showingSuccessAnimation = false
    
    let categories = [
        ("food", "fork.knife", "餐饮"),
        ("transport", "car", "交通"),
        ("entertainment", "tv", "娱乐"),
        ("shopping", "bag", "购物"),
        ("medical", "cross", "医疗"),
        ("gift", "gift", "人情"),
        ("bills", "lightbulb", "缴费"),
        ("other", "shippingbox", "其他")
    ]
    
    var todayExpenses: [Expense] {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        return dataManager.expenses
            .filter { $0.date >= today && $0.date < tomorrow }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                HeaderView()
                
                // Quick Add Section
                QuickAddSection(
                    amount: $amount,
                    description: $description,
                    selectedCategory: $selectedCategory,
                    categories: categories,
                    isButtonPressed: $isButtonPressed,
                    showingSuccessAnimation: $showingSuccessAnimation,
                    onAddExpense: {
                        addExpense()
                    }
                )
                
                // Today's Records
                TodayRecordsSection(expenses: todayExpenses, dataManager: dataManager)
                
                // Bottom padding for tab bar
                Spacer(minLength: 100)
            }
        }
        .background(Color(.systemGroupedBackground))
        .alert("✅ 记账成功", isPresented: $showingSuccessAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text("已成功记录一笔支出")
        }
    }
    
    private func addExpense() {
        guard let amountValue = Double(amount), !description.isEmpty else {
            return
        }
        
        // 添加触觉反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        let expense = Expense(
            id: UUID(),
            amount: amountValue,
            description: description,
            category: selectedCategory,
            date: Date()
        )
        
        dataManager.addExpense(expense)
        
        // 先显示成功动画，然后显示弹窗
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            showingSuccessAnimation = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showingSuccessAlert = true
            showingSuccessAnimation = false
        }
        
        // Reset form with animation
        withAnimation(.easeOut(duration: 0.3)) {
            amount = ""
            description = ""
        }
    }
    
    private func formatCurrentTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: Date())
    }
}
