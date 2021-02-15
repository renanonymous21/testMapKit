//
//  sampleModel.swift
//  testMapKit
//
//  Created by Rendy K.R on 21/12/20.
//

import Foundation

struct LocationData: Codable {
    let nama: String?
    let idlokasi: String?
    let koordinat: [Koordinat]?
}

struct Koordinat: Codable {
    let lat: Double?
    let lng: Double?
}
