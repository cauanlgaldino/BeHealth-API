//
//  Follow.swift
//
//
//  Created by honorio on 27/08/24.
//

import Vapor
import Fluent

final class Follow: Model {
    
    static let schema = "follow"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "user_id")
    var user: User
    
    @Parent(key: "follower_id")
    var follower: User
    
    @Field(key: "created_at")
    var createdAt: Date?
    
    init() {}
    
    init(userID: User.IDValue, followerID: User.IDValue) {
        self.$user.id = userID
        self.$follower.id = followerID
    }
}

extension Follow: Content { }

extension Follow {
    
    struct Input: Content {
        var userID: UUID
        var followerID: UUID
//        var createdAt: Date
    }
    
    struct Public: Content {
        var id: UUID
        var userID: UUID
        var followerID: UUID
        var createdAt: Date?
    }
    
    var `public`: Public {
        .init(id: id!, userID: $user.id, followerID: $follower.id, createdAt: createdAt)
    }
    
}
