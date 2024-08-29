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
    
    @Parent(key: "follower_id")
    var follower: User
    
    @Parent(key: "following_id")
    var following: User
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    init() {}
    
    init(followerId: User.IDValue, followingId: User.IDValue) {
        self.$follower.id = followerId
        self.$following.id = followingId
    }
}

extension Follow: Content { }

extension Follow {
    
    struct Input: Content {
        var followerId: UUID
        var followingId: UUID
    }
    
    struct Public: Content {
        var id: UUID
        var followerId: UUID
        var followingId: UUID
        var createdAt: Date?
    }
    
    var `public`: Public {
        .init(id: id!, followerId: $follower.id, followingId: $following.id, createdAt: createdAt)
    }
    
}
