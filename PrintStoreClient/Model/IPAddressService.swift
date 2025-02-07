//
//  IPAddressService.swift
//  PrintStoreClient
//
//  Created by May on 7.02.25.
//
import Foundation

final class IPAddressService {
    private let key = "RecentIPAddresses"
    
    var recentIPAddresses: [String] {
        return UserDefaults.standard.stringArray(forKey: key) ?? []
    }
    
    func addIPAddress(_ ip: String) {
        var ips = recentIPAddresses
        // if ip already exists then delete it from list and add to the top
        ips.removeAll { $0 == ip }
        ips.insert(ip, at: 0)
        // limit to 10 recents
        if ips.count > 10 { ips = Array(ips.prefix(10)) }
        UserDefaults.standard.set(ips, forKey: key)
    }
}
