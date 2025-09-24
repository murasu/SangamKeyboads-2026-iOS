import SwiftUI
import KeyboardCore

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack {
                    Text("Sangam Keyboards")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Modern Multi-Language Keyboard")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Text("20+ Languages • Smart Predictions • Modern Design")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                
                VStack(spacing: 16) {
                    NavigationLink(destination: LanguageSelectionView()) {
                        FeatureCard(
                            title: "Languages",
                            subtitle: "Choose your languages",
                            icon: "globe"
                        )
                    }
                    
                    NavigationLink(destination: SettingsView()) {
                        FeatureCard(
                            title: "Settings",
                            subtitle: "Customize your experience",
                            icon: "gear"
                        )
                    }
                    
                    NavigationLink(destination: KeyboardPreviewView()) {
                        FeatureCard(
                            title: "Preview",
                            subtitle: "Test the keyboard",
                            icon: "keyboard"
                        )
                    }
                    
                    NavigationLink(destination: SetupGuideView()) {
                        FeatureCard(
                            title: "Setup Guide",
                            subtitle: "Enable keyboard in Settings",
                            icon: "questionmark.circle"
                        )
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationBarHidden(true)
        }
    }
}

struct FeatureCard: View {
    let title: String
    let subtitle: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

#Preview {
    ContentView()
}
