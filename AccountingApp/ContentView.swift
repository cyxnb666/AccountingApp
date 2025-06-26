// ContentView.swift
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var dataManager: ExpenseDataManager
    @State private var selectedTab = 0
    @State private var tabOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // 背景
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            // 主内容 - 恢复使用TabView
            TabView(selection: $selectedTab) {
                AddExpenseView()
                    .environmentObject(dataManager)
                    .tag(0)
                
                MonthlyRecordsView()
                    .environmentObject(dataManager)
                    .tag(1)
                
                StatisticsView()
                    .environmentObject(dataManager)
                    .tag(2)
                
                SettingsView()
                    .environmentObject(dataManager)
                    .tag(3)
            }
            .tabViewStyle(DefaultTabViewStyle())
            
            // 自定义底部Tab Bar
            VStack {
                Spacer()
                CustomTabBar(selectedTab: $selectedTab)
                    .offset(y: tabOffset)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: tabOffset)
            }
        }
        .onAppear {
            // 隐藏系统TabBar
            UITabBar.appearance().isHidden = true
        }
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    @State private var tabItemWidth: CGFloat = 0
    
    let tabItems = [
        ("house.fill", "记账"),
        ("list.bullet", "明细"),
        ("chart.bar.fill", "统计"),
        ("gearshape.fill", "设置")
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabItems.count, id: \.self) { index in
                TabBarItem(
                    icon: tabItems[index].0,
                    title: tabItems[index].1,
                    isSelected: selectedTab == index
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = index
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
    }
}

struct TabBarItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: isSelected ? 24 : 20, weight: .medium))
                    .foregroundColor(isSelected ? .white : .gray)
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? .white : .gray)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.thinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(.white.opacity(0.3), lineWidth: 1)
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.clear)
                    }
                }
                .scaleEffect(isSelected ? 1.0 : 0.8)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// Color Extension for Hex Colors and Brand Colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    // MARK: - Brand Colors
    /// 主品牌色 - 蓝色系
    static let brandPrimary = Color.blue
    
    /// 副品牌色1 - 紫色系
    static let brandSecondary = Color.purple
    
    /// 副品牌色2 - 青色系
    static let brandTertiary = Color.teal
    
    /// 强调色 - 橙色系
    static let brandAccent = Color.orange
    
    // MARK: - Category Colors
    static func categoryColor(for categoryId: String) -> Color {
        switch categoryId {
        case "food": return .red          // 餐饮 - 红色
        case "transport": return .blue    // 交通 - 蓝色
        case "entertainment": return .purple // 娱乐 - 紫色
        case "shopping": return .pink      // 购物 - 粉色
        case "medical": return .green      // 医疗 - 绿色
        case "gift": return .orange        // 人情 - 橙色
        case "bills": return .yellow       // 缴费 - 黄色
        case "other": return .gray         // 其他 - 灰色
        default: return .gray
        }
    }
    
    // MARK: - Adaptive Colors for Dark Mode
    static let adaptiveBackground = Color(.systemBackground)
    static let adaptiveSecondaryBackground = Color(.secondarySystemBackground)
    static let adaptiveTertiaryBackground = Color(.tertiarySystemBackground)
    static let adaptiveGroupedBackground = Color(.systemGroupedBackground)
    static let adaptiveSecondaryGroupedBackground = Color(.secondarySystemGroupedBackground)
    
    static let adaptiveLabel = Color(.label)
    static let adaptiveSecondaryLabel = Color(.secondaryLabel)
    static let adaptiveTertiaryLabel = Color(.tertiaryLabel)
    
    static let adaptiveSeparator = Color(.separator)
    static let adaptiveOpaqueSeparator = Color(.opaqueSeparator)
}