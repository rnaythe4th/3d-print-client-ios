//
//  Colors.swift
//  PrintStoreClient
//
//  Created by May on 8.02.25.
//
import UIKit

extension UIColor {
    static let backgroundDynamic: UIColor = {
        return UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? .black : .systemGray6
        }
    }()

    static let elementDynamic: UIColor = {
        return UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? UIColor(red: 28/255.0, green: 28/255.0, blue: 30/255.0, alpha: 1.0) : .white
        }
    }()
    
    static let modalElementDynamic: UIColor = {
        return UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? UIColor(red: 44/255.0, green: 44/255.0, blue: 46/255.0, alpha: 1.0) : .white
        }
    }()
    
    static let modalBackgroundDynamic: UIColor = {
        return UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? UIColor(red: 28/255.0, green: 28/255.0, blue: 30/255.0, alpha: 1.0) : .systemGray6
        }
    }()
}

