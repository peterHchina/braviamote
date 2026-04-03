import SwiftUI

struct SettingsView: View {
    @Binding var isPresented: Bool
    @ObservedObject var userDefaults: UserDefaultsManager
    @State private var pskInput: String = ""

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(Color.darkStart, Color.darkEnd).edgesIgnoringSafeArea(.all)

                VStack(spacing: 20) {
                    Text("Pre-Shared Key (PSK)")
                        .foregroundColor(.white)
                        .font(.headline)

                    Text("Enter the PSK configured on your TV.\nSettings > Network > Home Network > IP Control > Authentication > Normal and Pre-Shared Key")
                        .foregroundColor(.gray)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    TextField("PSK", text: $pskInput)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal, 40)
                        .keyboardType(.numberPad)

                    HStack(spacing: 20) {
                        Button(action: {
                            pskInput = PSKManager.defaultPSK
                        }) {
                            Text("Reset")
                                .foregroundColor(.white)
                        }
                        .buttonStyle(RectButtonStyle(color: .red, width: 120))

                        Button(action: {
                            userDefaults.psk = pskInput
                            isPresented = false
                        }) {
                            Text("Save")
                                .foregroundColor(.white)
                        }
                        .buttonStyle(RectButtonStyle(color: .green, width: 120))
                    }

                    Spacer()
                }
                .padding(.top, 30)
            }
            .navigationBarTitle("Settings", displayMode: .inline)
            .navigationBarItems(leading: Button(action: {
                isPresented = false
            }) {
                Image(systemName: "xmark")
                    .foregroundColor(.white)
            })
        }
        .onAppear {
            pskInput = userDefaults.psk
        }
    }
}
