//
//  VaultView.swift
//  MyVault
//
//  Created by toke on 3.7.2023.
//

import SwiftUI

struct VaultFile {
    var id = UUID()
    var name: String
    var icon: String
    var size: Int64
}

struct VaultView: View {
    var vault: Vault
    var removeVault: () -> Void
    var lockVault: () -> Void
    
    @State private var files: [VaultFile] = []
    
    var body: some View {
        VStack {
            List {
                ForEach(files, id: \.name) { file in
                    HStack {
                        Image(systemName: file.icon).frame(width: 35, alignment: .center)
                        VStack(alignment: .leading) {
                            Text(file.name)
                            if file.size > -1 {
                                Text("\(file.size) bytes").foregroundColor(.gray)
                            }
                        }
                    }
                }
            }.listStyle(.inset)
        }
        .navigationTitle(vault.name)
        .toolbar {
            ToolbarItem {
                Button(action: lockVault) { Image(systemName: "lock") }
            }
            
            ToolbarItem {
                Button(action: removeVault) { Image(systemName: "trash").foregroundColor(.red) }
            }
        }
        .onAppear(perform: loadFiles)
    }
    
    func loadFiles() {
        print("Loading files for vault \(vault.name)")
        
        do {
            print(vault.path.absoluteString)
            print(vault.path.lastPathComponent)
            print(vault.path.scheme)
            print(vault.path.description)
            print(vault.path.pathComponents)
            print(vault.path.pathExtension)
            let contents = try FileManager.default.contentsOfDirectory(atPath: vault.path.absoluteString)
            
            print(contents)
        } catch {
            print(error)
        }
    }
}

struct VaultView_Previews: PreviewProvider {
    static var previews: some View {
        VaultView(vault: Vault(
            name: "Personal",
            description: "Personal files and folders that should not be seen by everyone",
            locked: false,
            password: "hi",
            cpuExponent: 2,
            allowFaceID: false,
            parallelization: 1,
            path: URL(filePath: "/")
        ), removeVault: {}, lockVault: {})
    }
}
