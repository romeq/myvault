//
//  NewVaultPopover.swift
//  MyVault
//
//  Created by toke on 3.7.2023.
//

import SwiftUI
import MobileCoreServices

struct FilePicker: View {
    enum Filetype: String, CaseIterable, Identifiable {
        case folder, file
        var id: Self { self }
    }
    
    var title: String
    var type: Filetype
    @Binding var selection: URL
    @State private var isPickerPresented = false
    
    var body: some View {
        HStack {
            if selection.lastPathComponent != "/" {
                VStack {
                    Text("Folder selected")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(humanify(selection))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                Text(title)
            }
            Spacer()
            Button(action: {
                isPickerPresented = true
            }) {
                Image(systemName: "folder")
            }
        }
        .fileImporter(
            isPresented: $isPickerPresented,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            do {
                let selectedURLs = try result.get()
                if selectedURLs.count > 0 { selection = selectedURLs.first! }
            } catch {
                print("Error: \(error.localizedDescription)")
            }
        }
    }
    
    func humanify(_ f: URL) -> String {
        let iCloudFolderPath = "file:///private/var/mobile/Library/Mobile%20Documents/com~apple~CloudDocs/"
        
        print(f.absoluteString)
        if f.absoluteString.contains(iCloudFolderPath) {
            let folders = f.absoluteString.split(separator: iCloudFolderPath)
            let path = "iCloud/\(folders.joined(separator: "/"))".replacing("%20", with: " ")
            if path.count > 30 {
                print("Too long")
                
                let indexTo = String.Index(utf16Offset: 30-f.lastPathComponent.count, in: path)
                return String(path[...(indexTo)])
            }
            return path
        }
        return f.lastPathComponent
    }
}

struct NewVaultPopover: View {
    enum Flavor: String, CaseIterable, Identifiable {
        case aes128, aes256, chacha20, rabbit, blowfish
        var id: Self { self }
    }

    var callback: (_: RepositoryVault) -> (Bool, String)
    
    @State private var newVault: RepositoryVault = RepositoryVault(
        name: "",
        description: "",
        password: "",
        cpuExponent: 12,
        parallelization: 1,
        allowFaceID: false,
        path: URL(filePath: "")
    )
    @State private var selectedFlavor: Flavor = .aes128
    @State private var showErrorAlert: Bool = false
    @State private var errorAlertContent: String = ""
    @State private var creationInProgress: Bool = false
    
    @ViewBuilder
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Basic information")) {
                    TextField("Vault name", text: $newVault.name)
                    TextField("Description", text: $newVault.description)
                    SecureField("Password", text: $newVault.password)
                    Toggle("Biometric unlock", isOn: $newVault.allowFaceID)
                    FilePicker(title: "Select a folder", type: .folder, selection: $newVault.path)
                }
                
                Section(header: Text("Password hashing")) {
                    Stepper {
                        let difficulty = Int(truncating: NSDecimalNumber(decimal: pow(2, newVault.cpuExponent)))
                        Text("CPU difficulty: \(difficulty)")
                    } onIncrement: {
                        newVault.cpuExponent = min(16, newVault.cpuExponent + 1)
                    } onDecrement: {
                        newVault.cpuExponent = max(10, newVault.cpuExponent - 1)
                    }
                    
                    Stepper {
                        Text("Parallelization: \(newVault.parallelization)")
                    } onIncrement: {
                        newVault.parallelization = min(16, newVault.parallelization + 1)
                    } onDecrement: {
                        newVault.parallelization = max(1, newVault.parallelization - 1)
                    }
                }
                
                Section(header: Text("Encryption")) {
                    Picker("Algorithm", selection: $selectedFlavor) {
                        Text("AES-128-CBC").tag(Flavor.aes128)
                        Text("AES-256-CBC").tag(Flavor.aes256)
                        Text("ChaCha20").tag(Flavor.chacha20)
                        Text("Rabbit").tag(Flavor.rabbit)
                        Text("Blowfish").tag(Flavor.blowfish)
                    }.padding(0)
                }
                
                Section {
                    Button(action: {
                        creationInProgress = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            let (success, errorContent) = callback(newVault)
                            creationInProgress = false
                            if !success {
                                showErrorAlert = true
                                errorAlertContent = errorContent
                            }
                        }
                    }) {
                        ZStack {
                            if creationInProgress {
                                ProgressView().padding(.leading, 10)
                            } else {
                                Text("Create")
                            }
                        }.frame(maxWidth: .infinity, alignment: .center)
                    }.disabled(creationInProgress)
                }
                
            }
            .navigationTitle("Vault creation")
            .alert(isPresented: $showErrorAlert) {
                Alert(title: Text("Oopsie!"), message: Text(errorAlertContent))
            }
        }
    }
    
}

struct NewVaultPopover_Previews: PreviewProvider {
    static var previews: some View {
        NewVaultPopover(callback: {_ in
            return (true, "")
        })
    }
}
