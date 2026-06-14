import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var notificationService: NotificationService
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            CollectionsView()
                .tabItem {
                    Label("Collections", systemImage: "books.vertical.fill")
                }
                .tag(1)

            UploadView()
                .tabItem {
                    Label("Upload", systemImage: "plus.circle.fill")
                }
                .tag(2)

            ProgressDashboardView()
                .tabItem {
                    Label("Progress", systemImage: "chart.bar.fill")
                }
                .tag(3)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .tint(AppColors.primary)
    }
}
