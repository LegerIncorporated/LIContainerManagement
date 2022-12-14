//
//  ContainerViewController.swift
//
//  Created by Justin Léger on 2/4/18.
//
// Originally inspired from: https://github.com/mluton/EmbeddedSwapping

import UIKit

open class ContainerViewController: UIViewController {
     
    weak public var delegate: ContainerViewControllerDelegate?
    
    public var defaultSegueIdentifier: String?
    
//    var defaultTransitionDuration = 0.25
//    var defaultAnimationOptions: UIView.AnimationOptions = [.transitionCrossDissolve]
    
    public var defaultTransitionDuration = 0.0
    public var defaultAnimationOptions: UIView.AnimationOptions = []
    
    // MARK: - View Lifecycle
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        if let defaultSegueIdentifier = defaultSegueIdentifier {
            performSegue(withIdentifier: defaultSegueIdentifier, sender: nil)
        }
    }
    
    open override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        delegate?.containerView(self, willSegue: segue)
        
        var containerTransition: ContainerTransition
        
        if let senderTransition = sender as? ContainerTransition {
            containerTransition = ContainerTransition(
                identifier: senderTransition.identifier,
                destination: segue.destination,
                duration: senderTransition.duration,
                options: senderTransition.options
            )
        } else {
            containerTransition = ContainerTransition(
                identifier: segue.identifier ?? "UNKNOWN-IDENTIFIER",
                destination: segue.destination,
                duration: defaultTransitionDuration,
                options: defaultAnimationOptions
            )
        }
        
        performContainerTransition(containerTransition)
    }
    
    open override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
    
        guard let shouldPerformSegue = delegate?.containerView(self, shouldPerformSegueWithIdentifier: identifier, sender: sender) else {
            return super.shouldPerformSegue(withIdentifier: identifier, sender: sender)
        }
        
        return shouldPerformSegue
    }
    
    open func performSegue(withContainerTransition containerTransition: ContainerTransition) {
        self.performSegue(withIdentifier: containerTransition.identifier, sender: containerTransition)
    }
    
    open override func performSegue(withIdentifier identifier: String, sender: Any?) {
        
        let canPerformSegue = self.canPerformSegue(withIdentifier: identifier)
        let shouldPerformSegue = self.shouldPerformSegue(withIdentifier: identifier, sender: sender)
        
        if !canPerformSegue {
            print("***** ERROR :: Segue with Identifier '\(identifier)' does not exist!")
        } else if !shouldPerformSegue {
            print("***** NOTE :: Segue with Identifier '\(identifier)' being block by shouldPerformSegue")
        } else {
            super.performSegue(withIdentifier: identifier, sender: sender)
        }
    }
    
    open func swap(toViewController destination: UIViewController, duration: TimeInterval? = nil, options: UIView.AnimationOptions? = nil) {
        
        let containerTransition = ContainerTransition(
            identifier: "SWAP-MANUAL",
            destination: destination,
            duration: duration ?? defaultTransitionDuration,
            options: options ?? defaultAnimationOptions
        )
        
        self.performContainerTransition(containerTransition)
    }
    
    private func swapFromViewController(_ fromViewController: UIViewController?, toViewController: UIViewController, duration: TimeInterval? = nil, options: UIView.AnimationOptions? = nil, completion: ((Bool) -> Void)? = nil ) -> Void {
        
//        let from = (fromViewController?.view.subviews[0] as? UILabel)?.text?.replacingOccurrences(of: "\n", with: " ") ?? "<nil>"
//        let to = (toViewController.view.subviews[0] as? UILabel)?.text?.replacingOccurrences(of: "\n", with: " ") ?? "<nil>"
//
//        print("\(Date().timeIntervalSinceReferenceDate) Swap command: \(from) -> \(to)")
        
        delegate?.containerView(self, willSwapFromViewController: fromViewController, toViewController: toViewController)
        
        if let fromViewController = fromViewController {
                
            fromViewController.willMove(toParent: nil)
            addChild(toViewController)

            transition(
                from: fromViewController,
                to: toViewController,
                duration: duration ?? defaultTransitionDuration,
                options: options ?? defaultAnimationOptions,
                animations: {
                // Nothing to do but read that the animation block was necessary
                // See Bullet 3. https://stackoverflow.com/a/48369709
//                print("\(Date().timeIntervalSinceReferenceDate) Animation block: \(from) -> \(to)")
            }) { (finished) in
//                print("\(Date().timeIntervalSinceReferenceDate) Completion (\(finished)): \(from) -> \(to)")
                
                fromViewController.removeFromParent()
                fromViewController.view.removeFromSuperview()
                toViewController.didMove(toParent: self)
                
                self.delegate?.containerView(self, didSwapFromViewController: fromViewController, toViewController: toViewController)
                
                completion?(finished)
            }
            
        } else {
            addChild(toViewController)
            view.addSubview(toViewController.view)
            toViewController.didMove(toParent: self)
            
            delegate?.containerView(self, didSwapFromViewController: fromViewController, toViewController: toViewController)
            
            completion?(true)
        }
    }
    
    public  var skipUnseenTransitions: Bool = true
    private var activeContainerTransition: ContainerTransition?
    private var containerTransitionQueue: [ContainerTransition] = []
    
    public func performContainerTransition(_ transition: ContainerTransition) {
        containerTransitionQueue.append(transition)
        
        // There was already a transition in the queue.
        if containerTransitionQueue.count > 2 && skipUnseenTransitions == true {
            let lastIndex: Int = containerTransitionQueue.count - 1
            containerTransitionQueue.removeSubrange(1..<lastIndex)
        }
        
        performNextContainerTransition()
    }
    
    public func performNextContainerTransition() {
        
        if let nextContainerTransition = containerTransitionQueue.first, nextContainerTransition != self.activeContainerTransition, let destination = nextContainerTransition.destination {
            self.activeContainerTransition = nextContainerTransition
            
            destination.parentContainerViewController = self
            destination.view.frame = CGRect(origin: CGPoint.zero, size: view.frame.size)
            
            let fromViewController = children.isEmpty ? nil : children[0]
            
            swapFromViewController(fromViewController, toViewController: destination, duration: nextContainerTransition.duration, options: nextContainerTransition.options) { [weak self] finished in
                if let transitionIndex = self?.containerTransitionQueue.firstIndex(of: nextContainerTransition) {
                    self?.containerTransitionQueue.remove(at: transitionIndex)
                    self?.performNextContainerTransition()
                }
            }
        } else {
            // TODO: Print some error here
        }
    }
    
}

public protocol ContainerViewControllerDelegate: AnyObject {
    
    func containerView(_ containerView: ContainerViewController, willSegue segue: UIStoryboardSegue) -> Swift.Void // Optional
    func containerView(_ containerView: ContainerViewController, shouldPerformSegueWithIdentifier identifier: String, sender: Any?) -> Bool // Optional
    
    func containerView(_ containerView: ContainerViewController, willSwapFromViewController fromViewController: UIViewController?, toViewController: UIViewController?) -> Swift.Void // Optional
    func containerView(_ containerView: ContainerViewController, didSwapFromViewController fromViewController: UIViewController?, toViewController: UIViewController?) -> Swift.Void // Optional
    
}

public extension ContainerViewControllerDelegate {
    
    // Make Optional
    // Stub functions so this can be optional in the class designated as delegates
    
    func containerView(_ containerView: ContainerViewController, willSegue segue: UIStoryboardSegue) -> Swift.Void {}
    func containerView(_ containerView: ContainerViewController, shouldPerformSegueWithIdentifier identifier: String, sender: Any?) -> Bool { return true }
    
    func containerView(_ containerView: ContainerViewController, willSwapFromViewController fromViewController: UIViewController?, toViewController: UIViewController?) -> Swift.Void {}
    func containerView(_ containerView: ContainerViewController, didSwapFromViewController fromViewController: UIViewController?, toViewController: UIViewController?) -> Swift.Void {}
}

extension UIViewController {
    
    /**
     Checks whether controller can perform specific segue or not.
     - parameter identifier: Identifier of UIStoryboardSegue.
     */
    public func canPerformSegue(withIdentifier identifier: String) -> Bool {
        //first fetch segue templates set in storyboard.
        guard let identifiers = value(forKey: "storyboardSegueTemplates") as? [NSObject] else {
            //if cannot fetch, return false
            return false
        }
        //check every object in segue templates, if it has a value for key _identifier equals your identifier.
        let canPerform = identifiers.contains { (object) -> Bool in
            if let id = object.value(forKey: "_identifier") as? String {
                if id == identifier{
                    return true
                } else {
                    return false
                }
            } else {
                return false
            }
        }
        return canPerform
    }
}

extension UIViewController {
    
    private struct AssociatedObjectKeys {
        static var ParentContainerViewController = "nsh_ParentContainerViewControllerAssociatedObjectKey"
    }
    
    public weak var parentContainerViewController: UIViewController? {
        get {
            return objc_getAssociatedObject(self, &AssociatedObjectKeys.ParentContainerViewController) as? UIViewController
        }
        set {
            objc_setAssociatedObject(self, &AssociatedObjectKeys.ParentContainerViewController, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
    }
}

public struct ContainerTransition: Equatable {
    
    public let uuid = UUID()
    
    public var identifier: String = "UNKNOWN-IDENTIFIER"
    public var destination: UIViewController? = nil
    public var duration: TimeInterval = 0.0
    public var options: UIView.AnimationOptions = []
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        // return lhs.uuid == rhs.uuid
        return lhs.identifier == rhs.identifier && lhs.destination?.hash == rhs.destination?.hash
    }
}
