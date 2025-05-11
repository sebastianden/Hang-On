//
//  WorkoutButton.swift
//  Hang On
//
//  Created by STDG (Sebastian Dengler) on 11.05.25.
//

import SwiftUI

struct WorkoutButton: View {
    let title: String
    let icon: String
    let description: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.title2)
                    .bold()
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(.blue)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}
