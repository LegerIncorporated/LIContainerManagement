//
//  RootViewController.swift
//  Container Management
//
//  Created by Justin Leger on 6/6/21.
//

import UIKit
import LIContainerManagement

enum RootSegueIdentifiers: String, CaseIterable {
    case launchScreen           = "ReuseLaunchScreenSegue"
    case navigationTableView    = "NavigationTableViewSegue"
    case red                    = "RedSegue"
    case green                  = "GreenSegue"
    case blue                   = "BlueSegue"
}

enum RandomSegueIdentifiers: String, CaseIterable {
    case navigationTableView    = "NavigationTableViewSegue"
    case red                    = "RedSegue"
    case green                  = "GreenSegue"
    case blue                   = "BlueSegue"
}

class RootViewController: UIViewController {
    
    var ulTimer: Timer?
    var ulContainerViewController : ContainerViewController?
    
    var urTimer: Timer?
    var urContainerViewController : ContainerViewController?
    
    var mcTimer: Timer?
    var mcContainerViewController : ContainerViewController?
    
    var llTimer: Timer?
    var llContainerViewController : ContainerViewController?
    
    var lrTimer: Timer?
    var lrContainerViewController : ContainerViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        ulTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval.random(in: 2.0...5.0), repeats: true) { timer in
            self.randomContainerTransition(forContainerViewController: self.ulContainerViewController)
        }
        
        urTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval.random(in: 2.0...5.0), repeats: true) { timer in
            self.randomContainerTransition(forContainerViewController: self.urContainerViewController)
        }
        
        mcTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval.random(in: 2.0...5.0), repeats: true) { timer in
            self.randomContainerTransition(forContainerViewController: self.mcContainerViewController)
        }
        
        llTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval.random(in: 2.0...5.0), repeats: true) { timer in
            self.randomContainerTransition(forContainerViewController: self.llContainerViewController)
        }
        
        lrTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval.random(in: 2.0...5.0), repeats: true) { timer in
            self.randomContainerTransition(forContainerViewController: self.lrContainerViewController)
        }
    }
    
    // This sets up the initial ContainerViewController
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        switch segue.destination {
        case let containerViewController as ContainerViewController:
            
            switch segue.identifier {
            case "UpperLeftEmbed":
                
                containerViewController.skipUnseenTransitions = true
                containerViewController.delegate = self
                self.ulContainerViewController = containerViewController
                self.ulContainerViewController?.performSegue(withIdentifier: RootSegueIdentifiers.red.rawValue, sender: nil)
                
            case "UpperRightEmbed":
                
                containerViewController.skipUnseenTransitions = true
                containerViewController.delegate = self
                self.urContainerViewController = containerViewController
                self.urContainerViewController?.performSegue(withIdentifier: RootSegueIdentifiers.green.rawValue, sender: nil)
                
            case "MiddleCenterEmbed":
                
                containerViewController.skipUnseenTransitions = true
                containerViewController.delegate = self
                self.mcContainerViewController = containerViewController
                self.mcContainerViewController?.performSegue(withIdentifier: RootSegueIdentifiers.blue.rawValue, sender: nil)
                
            case "LowerLeftEmbed":
                
                containerViewController.skipUnseenTransitions = true
                containerViewController.delegate = self
                self.llContainerViewController = containerViewController
                self.llContainerViewController?.performSegue(withIdentifier: RootSegueIdentifiers.green.rawValue, sender: nil)
                
            case "LowerRightEmbed":
                
                containerViewController.skipUnseenTransitions = true
                containerViewController.delegate = self
                self.lrContainerViewController = containerViewController
                self.lrContainerViewController?.performSegue(withIdentifier: RootSegueIdentifiers.red.rawValue, sender: nil)
                
            default:
                break
            }
            
        default:
            break
        }
    }
    
    func randomContainerTransition(forContainerViewController containerViewController: ContainerViewController?) {
        let transitions:[UIView.AnimationOptions] = [.transitionFlipFromLeft,
                                                     .transitionFlipFromRight,
                                                     .transitionCurlUp,
                                                     .transitionCurlDown,
                                                     .transitionCrossDissolve,
                                                     .transitionFlipFromTop,
                                                     .transitionFlipFromBottom]
        
        let transition = ContainerTransition(identifier: RandomSegueIdentifiers.allCases.randomElement()!.rawValue, duration: TimeInterval.random(in: 1.0...2.0), options: transitions.randomElement()!)
        
        containerViewController?.performSegue(withContainerTransition: transition)
    }
}

extension RootViewController: ContainerViewControllerDelegate {

    func containerView(_ containerView: ContainerViewController, willSegue segue: UIStoryboardSegue) {

        switch segue.destination {
        
        case let navigationTableViewController as NavigationTableViewController:
            break
            
        case let redViewController as RedViewController:
            break
            
        case let greenViewController as GreenViewController:
            break
            
        case let blueViewController as BlueViewController:
            break
                
        default:
            print("***** Unknown segue.destination class type :: \(segue.destination.debugDescription).")
        }
    }
}

class NavigationTableViewController: UINavigationController {
    // Nothing but type capturing for this example.
}

class RedViewController: UIViewController {
    // Nothing but type capturing for this example.
}

class GreenViewController: UIViewController {
    // Nothing but type capturing for this example.
}

class BlueViewController: UIViewController {
    // Nothing but type capturing for this example.
}
