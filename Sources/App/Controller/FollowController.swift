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
                $0.get("following", ":id", use: getFollowing)
                $0.get("follower", ":id", use: getFollowers)
                $0.delete(":id", use: delete)
            }
        }
    }
    
    func index(req: Request) async throws -> [Follow.Public] {
        var query = Follow.query(on: req.db).sort(\.$createdAt, .descending)
        
        if req.query[String.self, at: "expand"] == "follower_id" {
            query = query.with(\.$follower)
        }
        
        if let userId = req.query[User.IDValue.self, at: "follower_id"] {
            query = query.filter(\.$follower.$id == userId)
        }
        
        return try await query.all().map(\.public)
    }
    
    func getFollowing(req: Request) async throws -> [User.Public] {
        guard let userId = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid user ID.")
        }
        
        let following = try await Follow.query(on: req.db)
            .filter(\.$follower.$id == userId)
            .with(\.$following)  // Assuming you have a relationship set up
            .all()
        
        return following.map { $0.following.public }
    }
    
    func getFollowers(req: Request) async throws -> [User.Public] {
        guard let userId = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid user ID.")
        }
        
        let followers = try await Follow.query(on: req.db)
            .filter(\.$following.$id == userId)
            .with(\.$follower)  // Assuming you have a relationship set up
            .all()
        
        return followers.map { $0.follower.public }
    }

    
    func create(req: Request) async throws -> Follow.Public {
        let user = try req.auth.require(User.self)

        switch req.headers.contentType {
        case .json?:
            let content = try req.content.decode(Follow.Input.self)
            
            // Verifica se o usuário está tentando seguir a si mesmo
            if try user.requireID() == content.followingId {
                throw Abort(.badRequest, reason: "You cannot follow yourself.")
            }
            
            // Verifica se já existe um registro com o mesmo userID e followerID
            let existingFollow = try await Follow.query(on: req.db)
                .filter(\.$follower.$id == user.requireID())
                .filter(\.$following.$id == content.followingId)
                .first()

            // Se o registro já existir, retorna um erro
            if existingFollow != nil {
                throw Abort(.conflict, reason: "This follow relationship already exists.")
            }
            
            // Se o registro não existir, cria e salva o novo registro
            let follow = try Follow(followerId: user.requireID(), followingId: content.followingId)
            try await follow.save(on: req.db)
            return follow.public
            
        default:
            throw Abort(.badRequest)
        }
    }
    
    func delete(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        guard let followingId = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid user ID.")
        }
        
        // Busca a entrada na tabela `follows`
        guard let follow = try await Follow.query(on: req.db)
                .filter(\.$follower.$id == user.requireID())
                .filter(\.$following.$id == followingId)
                .first() else {
            throw Abort(.notFound, reason: "Follow relationship not found.")
        }
        
        // Deleta a entrada
        try await follow.delete(on: req.db)
        
        return .noContent
    }
}
