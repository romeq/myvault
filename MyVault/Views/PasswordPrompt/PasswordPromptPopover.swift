//
//  PasswordPromptPopover.swift
//  MyVault
//
//  Created by toke on 4.7.2023.
//

import SwiftUI
import LocalAuthentication

struct PasswordPromptPopover: View {
    var tryUnlock: (_: String) -> Bool
    var tryFaceID: () async -> Void
    var showFaceID: Bool
    
    @State private var password: String = ""
    @State private var showErrorAlert: Bool = false
    @State private var errorAlertContent: String = ""
    @State private var unlockInProgress: Bool = false
    
    var body: some View {
        NavigationView {
            VStack {
                SecureField("Decryption password", text: $password).textFieldStyle(.roundedBorder)
                HStack {
                    Button(action: {
                        unlockInProgress = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            let result = tryUnlock(password)
                            unlockInProgress = false
                            if !result {
                                showErrorAlert = true
                                errorAlertContent = "Invalid password"
                            }
                        }
                    }) {
                        if !unlockInProgress {
                            Text("Unlock vault").frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            ProgressView().frame(maxWidth: .infinity)
                        }
                    }.buttonStyle(.borderedProminent)
                        .disabled(unlockInProgress)
                    
                    if showFaceID {
                        Button(action: {
                            Task {
                                await tryFaceID()
                            }
                        }) {
                            
                            Label("Biometric", systemImage: "faceid")
                        }.buttonStyle(.bordered)
                            .disabled(unlockInProgress)
                    }
                }.padding(.top, 20)
            }
            .padding()
            .navigationTitle("Authentication")
            .alert(isPresented: $showErrorAlert) {
                Alert(title: Text(errorAlertContent))
            }
        }
    }
}

struct PasswordPromptPopover_Previews: PreviewProvider {
    static var previews: some View {
        PasswordPromptPopover(tryUnlock: {_ in return false}, tryFaceID: {}, showFaceID: false).tint(.gray)
    }
}
