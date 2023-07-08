//
//  VaultListPreview.swift
//  MyVault
//
//  Created by toke on 3.7.2023.
//

import SwiftUI

struct VaultListPreview: View {
    var vault: Vault
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(vault.name).fontWeight(Font.Weight.medium)
                Text(vault.description != "" ? vault.description! : "No description").foregroundColor(Color.gray)
            }
            Spacer()
            if vault.locked {
                Image(systemName: "lock.fill").foregroundColor(.green)
            }
        }
    }
}
