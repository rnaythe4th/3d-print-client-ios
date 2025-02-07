//
//  ZoomOutTransitionDelegate.swift
//  PrintStoreClient
//
//  Created by May on 7.02.25.
//
import UIKit

class ZoomOutTransitionDelegate: NSObject, UIViewControllerTransitioningDelegate {
    private let animator = ZoomOutPresentationAnimator()
    // method for presentation
    func animationController(forPresented presented: UIViewController,
                             presenting: UIViewController,
                             source: UIViewController) -> (any UIViewControllerAnimatedTransitioning)? {
        return animator
    }
    // method for dismissal
    func animationController(forDismissed dismissed: UIViewController) -> (any UIViewControllerAnimatedTransitioning)? {
        return animator
    }
}
