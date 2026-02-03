//
//  RepoRow.swift
//  SwiftNetworkSampleApp
//
//  Created by SwiftNetwork Contributors on 3/2/26.
//

import SwiftUI

@ViewBuilder
func RepoRow(repo: GitHubRepo) -> some View {
    VStack(alignment: .leading, spacing: 6) {
        HStack {
            Text(repo.name)
                .font(.headline)
            Spacer()
            Label("\(repo.stargazersCount)", systemImage: "star.fill")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }

        if let description = repo.description {
            Text(description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }

        if let language = repo.language {
            Text(language)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    .padding(.vertical, 4)
}
