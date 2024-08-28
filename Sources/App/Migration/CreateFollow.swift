//
//  File.swift
//  
//
//  Created by honorio on 27/08/24.
//

import Fluent

struct CreateFollow: AsyncMigration {
    
    func prepare(on database: Database) async throws {
        try await database
            .schema(Follow.schema)
            .id()
            .field("user_id", .uuid)
            .field("follower_id", .uuid)
            .field("created_at", .datetime)
            .foreignKey("user_id", references: User.schema, "id", onDelete: .cascade, onUpdate: .cascade)
            .foreignKey("follower_id", references: User.schema, "id", onDelete: .cascade, onUpdate: .cascade)
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema(Follow.schema).delete()
    }
}
