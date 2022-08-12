//
//  ContainerViewController.swift
//
//  Created by Justin Léger on 2/4/18.
//

// Originally inspired from: https://github.com/mluton/EmbeddedSwapping

import UIKit

class ContainerViewController: UIViewController {
     
    weak public var delegate: ContainerViewControllerDelegate?
    
    var defaultSegueIdentifier: String?
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let defaultSegueIdentifier = defaultSegueIdentifier {
            performSegue(withIdentifier: defaultSegueIdentifier, sender: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        delegate?.containerView(self, willSegue: segue)
        
        var containerTransition: ContainerTransition
        
        if let senderTransition = sender as? ContainerTransition {
            containerTransition = ContainerTransition(identifier: senderTransition.identifier, destination: segue.destination, duration: senderTransition.duration, options: senderTransition.options)
            containerTransition.destination = segue.destination
        } else {
            containerTransition = ContainerTransition(identifier: segue.identifier ?? "UNKOWN-IDENTIFIER", destination: segue.destination, duration: 1.0, options: [.transitionCrossDissolve])
        }
        
        performContainerTransition(containerTransition)
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
    
        guard let shouldPerformSegue = delegate?.containerView(self, shouldPerformSegueWithIdentifier: identifier, sender: sender) else {
            return super.shouldPerformSegue(withIdentifier: identifier, sender: sender)
        }
        
        return shouldPerformSegue
    }
    
    func performSegue(withContainerTransition containerTransition: ContainerTransition) {
        self.performSegue(withIdentifier: containerTransition.identifier, sender: containerTransition)
    }
    
    override func performSegue(withIdentifier identifier: String, sender: Any?) {
        
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
    
    private func swapFromViewController(_ fromViewController: UIViewController?, toViewController: UIViewController, duration: TimeInterval = 1.0, options: UIView.AnimationOptions = [], completion: ((Bool) -> Void)? = nil ) -> Void {
        
        let from = (fromViewController?.view.subviews[0] as? UILabel)?.text?.replacingOccurrences(of: "\n", with: " ") ?? "<nil>"
        let to = (toViewController.view.subviews[0] as? UILabel)?.text?.replacingOccurrences(of: "\n", with: " ") ?? "<nil>"

        print("\(Date().timeIntervalSinceReferenceDate) Swap command: \(from) -> \(to)")
        
        delegate?.containerView(self, willSwapFromViewController: fromViewController, toViewController: toViewController)
        
        if let fromViewController = fromViewController {
                
            fromViewController.willMove(toParent: nil)
            addChild(toViewController)

            transition(from: fromViewController, to: toViewController, duration: duration, options: options, animations: {
                // Nothing to do but read that the animation block was necessary
                // See Bullet 3. https://stackoverflow.com/a/48369709
                print("\(Date().timeIntervalSinceReferenceDate) Animation block: \(from) -> \(to)")
            }) { (finished) in
                print("\(Date().timeIntervalSinceReferenceDate) Completion (\(finished)): \(from) -> \(to)")
                
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
    
    func performContainerTransition(_ transition: ContainerTransition) {
        containerTransitionQueue.append(transition)
        
        // There was already a transition in the queue.
        if containerTransitionQueue.count > 2 && skipUnseenTransitions == true {
            let lastIndex: Int = containerTransitionQueue.count - 1
            containerTransitionQueue.removeSubrange(1..<lastIndex)
        }
        
        performNextContainerTransition()
    }
    
    func performNextContainerTransition() {
        
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

protocol ContainerViewControllerDelegate: AnyObject {
    
    func containerView(_ containerView: ContainerViewController, willSegue segue: UIStoryboardSegue) -> Swift.Void // Optional
    func containerView(_ containerView: ContainerViewController, shouldPerformSegueWithIdentifier identifier: String, sender: Any?) -> Bool // Optional
    
    func containerView(_ containerView: ContainerViewController, willSwapFromViewController fromViewController: UIViewController?, toViewController: UIViewController?) -> Swift.Void // Optional
    func containerView(_ containerView: ContainerViewController, didSwapFromViewController fromViewController: UIViewController?, toViewController: UIViewController?) -> Swift.Void // Optional
    
}

extension ContainerViewControllerDelegate {
    
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
    func canPerformSegue(withIdentifier identifier: String) -> Bool {
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

struct ContainerTransition: Equatable {
    var identifier: String
    var destination: UIViewController? = nil
    var duration: TimeInterval = 1.0
    var options: UIView.AnimationOptions = []
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.identifier == rhs.identifier && lhs.duration == rhs.duration && lhs.options == rhs.options
    }
}
