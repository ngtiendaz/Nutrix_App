//
//  Untitled.swift
//  Nutrix
//
//  Created by Daz on 14/5/26.
//

import FirebaseFirestore

struct Activity: Identifiable, Codable, Hashable { // Thêm Hashable ở đây
    @DocumentID var id: String?
    var name: String
    var metValue: Double
    var icon: String
}
