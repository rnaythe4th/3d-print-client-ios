//
//  ZoomOutPresentationAnimator.swift
//  PrintStoreClient
//
//  Created by May on 7.02.25.
//
import UIKit

class ZoomOutPresentationAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    private let presentationDuration: TimeInterval = 0.55
    private let dismissalDuration: TimeInterval = 0.3
    
    var dimmingView: UIView?
    
    //set duration
    func transitionDuration(using transitionContext: (any UIViewControllerContextTransitioning)?) -> TimeInterval {
        return presentationDuration
    }
    // animation itself
    func animateTransition(using transitionContext: any UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        // presentation or dismissal
        guard let toVC = transitionContext.viewController(forKey: .to),
              let fromVC = transitionContext.viewController(forKey: .from) else {
            transitionContext.completeTransition(false)
            return
        }
        
        let isPresenting = toVC.presentingViewController == fromVC
        
        if isPresenting {
            // dimming view to make status-bar look static
            let dimmingView = UIView(frame: containerView.bounds)
            dimmingView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
            dimmingView.alpha = 0
            containerView.addSubview(dimmingView)
            self.dimmingView = dimmingView
            
            // tap for closing modal window
            let tapGR = UITapGestureRecognizer(target: self, action: #selector(dimmingViewTapped(_:)))
            dimmingView.addGestureRecognizer(tapGR)
            
            // define final frame
            //let finalFrame = transitionContext.finalFrame(for: toVC)
            let modalHeight = containerView.bounds.height * 0.55
            let finalFrame = CGRect(
                x: 0,
                y: containerView.bounds.height - modalHeight,
                width: containerView.bounds.width,
                height: modalHeight
            )
            // get view to show
            let toView = transitionContext.view(forKey: .to)!
            toView.layer.cornerRadius = 12
            toView.clipsToBounds = true
            
            containerView.addSubview(toView)
            // set start postion to below the screen
            toView.frame = finalFrame.offsetBy(dx: 0, dy: containerView.bounds.height)
            
            let fromView = fromVC.view!
            fromView.layer.cornerRadius = 12
            fromView.clipsToBounds = true
            
            // animate
            UIView.animate(
                withDuration: presentationDuration,
                delay: 0,
                usingSpringWithDamping: 0.8,
                initialSpringVelocity: 0.5,
                options: [.curveEaseOut],
                animations: {
                    // make dimmingView visible
                    dimmingView.alpha = 1
                    // move modal up
                    toView.frame = finalFrame
                    // background scale
                    fromView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
                        .translatedBy(x: 0, y: 30)
                },
                completion: { finished in
                    transitionContext.completeTransition(finished)
                }
            )
        } else {
            // dismissal animation
            let fromView = transitionContext.view(forKey: .from)!
            let presentingView = transitionContext.viewController(forKey: .to)!.view!
            // animate
            UIView.animate(
                withDuration: dismissalDuration,
                delay: 0,
                //usingSpringWithDamping: 1.0,
                //initialSpringVelocity: 0.5,
                options: [.curveEaseOut],
                animations: {
                    self.dimmingView?.alpha = 0
                    // move modal away
                    fromView.frame = fromView.frame.offsetBy(dx: 0, dy: containerView.bounds.height)
                    // restore background
                    presentingView.transform = .identity
                },
                completion: { finished in
                    self.dimmingView?.removeFromSuperview()
                    transitionContext.completeTransition(finished)
                }
            )
        }
    }
    
    @objc private func dimmingViewTapped(_ sender: UITapGestureRecognizer) {
        if let windowScene = UIApplication.shared.connectedScenes
            .first(where: {$0.activationState == .foregroundActive}) as? UIWindowScene,
           let keyWindow = windowScene.windows.first(where: {$0.isKeyWindow}),
        let topVC = keyWindow.rootViewController {
            topVC.dismiss(animated: true, completion: nil)
        }
    }
}
