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
                        VStack {
                            Image(systemName: "desktopcomputer")
                            Text("Sales")
                                .multilineTextAlignment(.center)
                        }
                    }

                CalculatorContentView()
                    .tabItem {
                        VStack {
                            Image(systemName: "archivebox")
                            Text("General")
                                .multilineTextAlignment(.center)
                        }
                    }

                TaxCalculatorContentView()
                    .tabItem {
                        VStack {
                            Image(systemName: "percent")
                            Text("Tax")
                                .multilineTextAlignment(.center)
                        }
                    }

                DSRScannerView()
                    .tabItem {
                        VStack {
                            Image(systemName: "doc.text.viewfinder")
                            Text("DSR Scanner")
                                .multilineTextAlignment(.center)
                        }
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
