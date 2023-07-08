//
//  UserRepository.swift
//  MyVault
//
//  Created by toke on 3.7.2023.
//

import Foundation
import SQLite

struct RepositoryVault {
    var name: String
    var description: String
    var password: String
    var cpuExponent: Int
    var parallelization: Int
    var allowFaceID: Bool
    var path: URL
}

class DBEngine {
    var db: Connection?
    private var vaults: Table = Table("vaults")
    
    private var vaultID: Expression = Expression<Int>("id")
    private var vaultName: Expression = Expression<String>("name")
    private var vaultDescription = Expression<String?>("description")
    private var vaultPassword = Expression<String>("password")
    private var vaultPasswordParallelization: Expression = Expression<Int>("passwordParallelization")
    private var vaultPasswordCPUExponent: Expression = Expression<Int>("passwordCPUExponent")
    private var vaultAllowFaceID: Expression = Expression<Bool>("allowFaceID")
    private var vaultPath: Expression = Expression<String>("dirpath")
   
    init() {
        let path = NSSearchPathForDirectoriesInDomains(
            .documentDirectory, .userDomainMask, true
        ).first!

        do {
            db = try Connection("\(path)/vaults.sqlite3")
            try migrate()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func deleteVault(name: String) throws {
        let vault = vaults.filter(vaultName == name)
        try db?.run(vault.delete())
    }
    
    func createVault(vault: RepositoryVault) throws {
        let insert = vaults.insert(
            vaultName <- vault.name,
            vaultDescription <- vault.description != "" ? vault.description : nil,
            vaultPassword <- vault.password,
            vaultPasswordParallelization <- vault.parallelization,
            vaultPasswordCPUExponent <- vault.cpuExponent,
            vaultAllowFaceID <- vault.allowFaceID,
            vaultPath <- vault.path.absoluteString
        )
        try db?.run(insert)
    }
    
    func listVaults() throws -> [RepositoryVault] {
        var result: [RepositoryVault] = []
        for vault in try db!.prepare(vaults) {
            let description = vault[vaultDescription]
            result.append(RepositoryVault(
                name: vault[vaultName],
                description: description != nil ? description! : "",
                password: vault[vaultPassword],
                cpuExponent: vault[vaultPasswordCPUExponent],
                parallelization: vault[vaultPasswordParallelization],
                allowFaceID: vault[vaultAllowFaceID],
                path: URL(filePath: vault[vaultPath])
            ))
        }
        return result
    }
    
    private func migrate() throws {
        //try db?.run(vaults.drop(ifExists: true))
        print("Running migrations...")
        try db?.run(vaults.create(ifNotExists: true) { t in
            t.column(vaultID, primaryKey: .autoincrement)
            t.column(vaultName, unique: true)
            t.column(vaultDescription)
            t.column(vaultPassword)
            t.column(vaultPasswordCPUExponent)
            t.column(vaultPasswordParallelization)
            t.column(vaultAllowFaceID)
            t.column(vaultPath)
        })
    }
}
