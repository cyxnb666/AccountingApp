// AccountingApp.swift
import SwiftUI
import UserNotifications

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
                    
                    // 清除应用图标角标
                    Task {
                        await clearApplicationBadge()
                    }
                }
        }
        .windowResizability(.contentSize)
    }
}



