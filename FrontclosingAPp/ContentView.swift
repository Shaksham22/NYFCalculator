import SwiftUI

// MARK: - Global User Data Model
class UserData: ObservableObject {
    @AppStorage("userName") var name: String = "" // Persist name across app sessions
    @Published var currentDate: String = UserData.getFormattedDate() // Store today's date
    
    static func getFormattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy" // Format: Month Date, Year
        return formatter.string(from: Date()) // Get current date
    }
}

struct ContentView: View {
    @StateObject var userData = UserData() // Shared data for all views

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            // MARK: - Name Input Section
            HStack {
                Text("Employee Name")
                    .font(.headline)

                TextField("", text: $userData.name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.vertical, 2)

            // MARK: - Date Display
            Text("\(userData.currentDate)")
                .font(.headline)
                .foregroundColor(.gray)
                .padding(.horizontal)

            // MARK: - Main Tab View
            TabView {
                SalesContentView()
                    .tabItem {
                        Label("Sales Calculator", systemImage: "desktopcomputer")
                    }

                CalculatorContentView()
                    .tabItem {
                        Label("Safe Money Calculator", systemImage: "archivebox")
                    }

                TaxCalculatorContentView()
                    .tabItem {
                        Label("Tax Calculator", systemImage: "percent")
                    }
            }
        }
        .environmentObject(userData) // Pass shared data to all views
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
