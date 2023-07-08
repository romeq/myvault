//
//  ContentView.swift
//  MyVault
//
//  Created by toke on 30.6.2023.
//

import SwiftUI
import LocalAuthentication
import CryptoSwift

struct Vault: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var description: String?
    var locked: Bool
    var password: String
    var cpuExponent: Int
    var allowFaceID: Bool
    var parallelization: Int
    var path: URL
 }

let dbeng = DBEngine()

func hashPassword(password: String, CPUExponent: Int, paralellization: Int) throws -> String? {
    guard let passwordData = password.data(using: .utf8) else {
        return nil
    }
    
    let salt = Array<UInt8>(repeating: 0, count: 16)
    do {
        print("Calculating hash...")
        let N = Int(truncating: NSDecimalNumber(decimal: pow(2, CPUExponent)))
        let hash = try CryptoSwift.Scrypt(password: passwordData.bytes, salt: salt, dkLen: 10, N: N, r: 8, p: paralellization).calculate()
        print("Hash calculated")
        return hash.toHexString()
    } catch {
        print("error:", error)
    }
    
    return nil
}

struct ContentView: View {
    @State private var newVaultWindowShown: Bool = false
    @State private var maximumVaults: Int8 = 5
    @State private var vaults: [Vault] = []
    @State private var navpath: [Vault] = []
    @State private var vaultToDelete: Vault? = nil
    @State private var showVaultDeleteConfirm: Bool = false
    
    @ViewBuilder
    var body: some View {
        NavigationStack(path: $navpath) {
            VStack {
                if $vaults.count == 0 {
                    VStack {
                        Image(systemName: "questionmark.folder")
                            .foregroundStyle(.foreground, .gray)
                            .controlSize(.mini)
                            .font(.system(size: 30))
                            .padding(.bottom, 20)
                
                        Text("You don't seem to currently have any vaults. ")
                    }
                } else {
                    List {
                        ForEach($vaults, id: \.name) { vault in
                            VaultListView(vault: vault)
                        }
                    }.listStyle(.plain)
                    Text("\(vaults.count)/\(maximumVaults) Vaults").foregroundColor(.gray)
                }
                
            }.navigationTitle("Vaults")
                .toolbar {
                    if vaults.count < maximumVaults {
                        ToolbarItem(placement: .automatic) {
                            Button(action: {
                                newVaultWindowShown = true
                            }) {
                                Image(systemName: "plus")
                            }
                            .popover(isPresented: $newVaultWindowShown) {
                                NewVaultPopover(callback: createNewVault)
                            }
                        }
                    }
                }
                .navigationDestination(for: Vault.self) {vault in
                    VaultView(vault: vault, removeVault: {
                        vaultToDelete = vault
                        showVaultDeleteConfirm = true
                    }, lockVault: {
                        lockVault(id: vault.id)
                        navpath = []
                    })
                }
                    .confirmationDialog(
                        "Are you sure? This will also delete all files in your vault. This action is irreversible.",
                        isPresented: $showVaultDeleteConfirm,
                        titleVisibility: .visible
                    ) {
                        Button("Only delete the vault") {
                            withAnimation {
                                removeVault(vault: vaultToDelete.unsafelyUnwrapped)
                            }
                        }.keyboardShortcut(.defaultAction)
                        
                        Button("Delete vault and all files", role: .destructive) {}
                        Button("Cancel", role: .cancel) {}
                    }
        }
        .tint(.green)
        .onAppear(perform: loadVaults)
        
    }
    
    func removeVault(vault: Vault) {
        do {
            let index = vaults.firstIndex(where: {$0.id == vault.id})
            if index != nil {
                vaults.remove(at: index.unsafelyUnwrapped)
                try dbeng.deleteVault(name: vault.name)
                navpath = []
                vaultToDelete = nil
            }
        } catch {
            print(error)
        }
    }
    
    func lockVault(id: UUID) {
        let index = vaults.firstIndex(where: {$0.id == id}).unsafelyUnwrapped
        vaults[index].locked = true
    }
    
    func createNewVault(vault: RepositoryVault) -> (Bool, String) {
        let name = vault.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if name == "" {
            return (false, "Name is required")
        }
        else if vault.password == "" {
            return (false, "Password is required")
        }
        else if !vault.path.hasDirectoryPath || vault.path.absoluteString == "/" {
            return (false, "Folder is required")
        }
        
        do {
            let password = try hashPassword(password: vault.password, CPUExponent: vault.cpuExponent, paralellization: vault.parallelization)
            if password == nil || password == vault.password {
                return (false, "Failed to hash password")
            }
            
            try dbeng.createVault(vault: RepositoryVault(
                name: name,
                description: vault.description.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password.unsafelyUnwrapped,
                cpuExponent: vault.cpuExponent,
                parallelization: vault.parallelization,
                allowFaceID: vault.allowFaceID,
                path: vault.path
            ))
            
            newVaultWindowShown = false
            vaults.append(Vault(
                name: vault.name,
                description: vault.description,
                locked: false,
                password: password.unsafelyUnwrapped,
                cpuExponent: vault.cpuExponent,
                allowFaceID: vault.allowFaceID,
                parallelization: vault.parallelization,
                path: vault.path
            ))
        } catch {
            print(error)
            return (false, error.localizedDescription)
        }
        
        return (true, "")
    }
    
    func loadVaults() {
        do {
            for vault in try dbeng.listVaults() {
                vaults.append(Vault(
                    name: vault.name,
                    description: vault.description,
                    locked: true,
                    password: vault.password,
                    cpuExponent: vault.cpuExponent,
                    allowFaceID: vault.allowFaceID,
                    parallelization: vault.parallelization,
                    path: vault.path
                ))
            }
        } catch {
            print(error)
        }
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
