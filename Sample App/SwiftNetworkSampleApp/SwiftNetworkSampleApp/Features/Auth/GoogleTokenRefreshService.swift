//
//  GoogleTokenRefreshService.swift
//  SwiftNetworkSampleApp
//
//  Created by SwiftNetwork Contributors on 3/3/26.
//

import Foundation
import SwiftNetwork

struct GoogleTokenRefreshService: Sendable {
    let clientId: String
    let clientSecret: String?

    func refresh(refreshToken: String) async throws -> GoogleTokenRefreshResponse {
        let config = NetworkClientConfiguration(
            baseURL: URL(string: "https://oauth2.googleapis.com")!,
            defaultHeaders: ["Accept": "application/json"],
            timeout: 20
        )
        let client = NetworkClient(configuration: config)

        var fields: [String: String] = [
            "client_id": clientId,
            "refresh_token": refreshToken,
            "grant_type": "refresh_token"
        ]
        if let clientSecret {
            fields["client_secret"] = clientSecret
        }

        let request = Request(
            method: .post,
            url: URL(string: "/token")!,
            body: .form(fields),
            cachePolicy: .ignoreCache
        )

        let response = try await client.newCall(request).execute()
        guard (200...299).contains(response.statusCode) else {
            throw GoogleTokenRefreshError.invalidStatus(response.statusCode)
        }
        guard let data = response.body else {
            throw GoogleTokenRefreshError.missingBody
        }

        return try JSONDecoder().decode(GoogleTokenRefreshResponse.self, from: data)
    }
}

struct GoogleTokenRefreshResponse: Decodable, Sendable {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Int

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
    }
}

enum GoogleTokenRefreshError: Error, LocalizedError, Sendable {
    case invalidStatus(Int)
    case missingBody

    var errorDescription: String? {
        switch self {
        case .invalidStatus(let statusCode):
            return "Google refresh failed with status \(statusCode)."
        case .missingBody:
            return "Google refresh response was empty."
        }
    }
}
