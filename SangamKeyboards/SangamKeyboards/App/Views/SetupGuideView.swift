import SwiftUI

struct SetupGuideView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Setup Instructions")
                    .font(.title)
                    .fontWeight(.bold)
                
                SetupStep(
                    number: "1",
                    title: "Open Settings",
                    description: "Go to Settings > General > Keyboard"
                )
                
                SetupStep(
                    number: "2", 
                    title: "Add Keyboard",
                    description: "Tap 'Keyboards' then 'Add New Keyboard'"
                )
                
                SetupStep(
                    number: "3",
                    title: "Select Sangam",
                    description: "Find 'Sangam Keyboards' in the list"
                )
                
                SetupStep(
                    number: "4",
                    title: "Allow Full Access",
                    description: "Enable full access for predictions"
                )
            }
            .padding()
        }
        .navigationTitle("Setup")
    }
}

struct SetupStep: View {
    let number: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Text(number)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 30, height: 30)
                .background(Color.blue)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
    }
}
