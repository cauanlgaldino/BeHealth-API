//
//  FollowController.swift
//
//
//  Created by honorio on 27/08/24.
//

import Vapor
import Fluent
import SQLiteKit

struct FollowController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        routes.group("follow") {
            $0.get(use: index)
            $0.group(Token.authenticator()) {
                $0.post(use: create)
            }
        }
    }
    
    func index(req: Request) async throws -> [Follow.Public] {
        var query = Follow.query(on: req.db).sort(\.$createdAt, .descending)
        
        if req.query[String.self, at: "expand"] == "user_id" {
            query = query.with(\.$user)
        }
        
        if let userID = req.query[User.IDValue.self, at: "user_id"] {
            query = query.filter(\.$user.$id == userID)
        }
        
        return try await query.all().map(\.public)
    }
    
    func create(req: Request) async throws -> Follow.Public {
        let user = try req.auth.require(User.self)
        
        switch req.headers.contentType {
        case .json?:
            let content = try req.content.decode(Follow.Input.self)
            
            let follow = try Follow(userID: content.userID, followerID: user.requireID())
//            follow.createdAt = content.createdAt
            
            try await follow.save(on: req.db)
            return follow.public
            
        default:
            throw Abort(.badRequest)
        }
    }
}
