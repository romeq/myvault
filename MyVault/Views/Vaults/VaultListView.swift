//
//  VaultListView.swift
//  MyVault
//
//  Created by toke on 3.7.2023.
//

import SwiftUI
import LocalAuthentication

struct VaultListView: View {
    @Binding var vault: Vault
    @State private var result: Bool = false
    @State private var performingAuth: Bool = false
    
    @ViewBuilder
    var body: some View {
        VStack {
            if !vault.locked {
                NavigationLink(value: vault) {
                    VaultListPreview(vault: vault)
                }
            } else {
                Button(action: {
                    Task {
                        // open modal
                        // modifiable by user, no need to close programatically
                        performingAuth = true
                        
                        await unlockWithFaceID()
                    }
                }) {
                    VaultListPreview(vault: vault)
                }
                .disabled(performingAuth)
                .popover(isPresented: $performingAuth) {
                    PasswordPromptPopover(tryUnlock: {password in
                        var result: Bool
                        do {
                            let hashed = try hashPassword(
                                password: password,
                                CPUExponent: vault.cpuExponent,
                                paralellization: vault.parallelization
                            )
                            result = hashed == vault.password
                        } catch {
                            return false
                        }
                        
                        if !result {
                            return false
                        }

                        performingAuth = false
                        vault.locked = false
                        return true
                        
                    }, tryFaceID: unlockWithFaceID, showFaceID: vault.allowFaceID)
                }
            }
        }
    }
    
    
    func unlockWithFaceID() async {
        if !vault.allowFaceID {
            return
        }
        
        await authenticate()
        
        while performingAuth {
            sleep(1)
        }
        
        if result {
            vault.locked = false
        }
    }
    
    func authenticate() async {
        let context = LAContext()
        var error: NSError?

                        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "We need to unlock your data!"

            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                result = success
                if success {
                    performingAuth = false
                }
                return
            }
        }
        
        result = false
    }
}

// todo: add previews
struct VaultListView_Previews: PreviewProvider {
    @State static var aVault: Vault = Vault(name: "This is a title", locked: true, password: "moi", cpuExponent: 10, allowFaceID: false, parallelization: 10, path: URL(filePath: "/"))
    static var previews: some View {
        VaultListView(vault: $aVault)
    }
}
