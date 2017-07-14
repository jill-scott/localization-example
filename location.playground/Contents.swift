


//import UIKit
//
//class LocationServicesDisabledViewController: UIViewController {
//    
//    @IBAction func goToSettings(_ sender: Any) {
//        UIApplication.shared.openSetting(.LocationServices)
//    }
//}

//
//  AddSystemNavigationController.swift
//  iAqualink
//
//  Created by Brent Nicholson on 6/20/17.
//  Copyright © 2017 zodiac. All rights reserved.
//

import UIKit
import RxSwift
import CoreBluetooth

class AddSystemNavigationController: UINavigationController {
    
    var isAnimating: Bool = false
    var segueToPerform: String? = nil
    var isInBLEFlow: Bool = false
    var bleDevice: InfinityBLEDevice? = nil {
        didSet {
            NotificationCenter.default.addObserver(self, selector: #selector(self.handleConnectionChange), name: InfinityBLEDevice.connectionChange, object: bleDevice)
        }
    }
    
    //var locationManager = CLLocationManager()
    
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        delegate = self
        
        BLEDeviceManager.sharedInstance.state
            .asObservable()
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] (event: Event<CBCentralManagerState>) in
                self?.bleStateChanged(state: event.element!)
            }.disposed(by: disposeBag)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if presentedViewController == nil {
            // Remove ourself from recieving anymore notifications.
            NotificationCenter.default.removeObserver(self)
        }
    }
    
    fileprivate func bleStateChanged(state: CBCentralManagerState) {
        // Ensure we are in the BLE flow before posting a message saying it's disabled.
        guard isInBLEFlow else { return }
        
        switch state {
        case .unknown:
            break
        case .resetting:
            break
        case .unsupported:
            break
        case .unauthorized:
            // We shouldn't get in here because we don't ask for background permissions
            break
        case .poweredOff:
            if !isAnimating {
                performSegue(withIdentifier: SegueIdentifiers.showBLEPoweredOff, sender: self)
            } else {
                segueToPerform = SegueIdentifiers.showBLEPoweredOff
            }
        case .poweredOn:
            // If the BLE disabled screen is being shown, dismiss it and let the user continue the flow since they enabled BLE.
            if let _ = presentedViewController as? BluetoothDisabledViewController {
                dismiss(animated: true, completion: { [weak self] in
                    self?.performDelayedSegue()
                })
            }
            break
        }
    }
    
    
    fileprivate func locationStateChanged()
    if !locationManager.locationServicesEnabled() {
        if !isAnimating {
            performSegue(withIdentifier: SegueIdentifiers.showLocationPoweredOff, sender: self)
        } else {
            segueToPerform = SegueIdentifiers.showLocationPoweredOff
        }
     }
     else {
        if let _ = presentedViewController as? LocationDisabledViewController {
            dismiss(animated: true, completion: { [weak self] in
                self?.performDelayedSegue()
            })
        }
     }
     
    
    
}

// MARK: - Navigation

extension AddSystemNavigationController {
    
    //----------Segue Identifier
    fileprivate struct SegueIdentifiers {
        static let showBLEPoweredOff = "ShowBLEPoweredOff"
        static let showSystemDisconnected = "ShowSystemDisconnected"
        //static let showLocationPoweredOff = "ShowLocationPoweredOff"
    }
    
    override func performSegue(withIdentifier identifier: String, sender: Any?) {
        if presentedViewController != nil {
            segueToPerform = identifier
            return
        }
        super.performSegue(withIdentifier: identifier, sender: sender)
    }
    
    fileprivate func performDelayedSegue() {
        if let segue = segueToPerform {
            segueToPerform = nil
            performSegue(withIdentifier: segue, sender: self)
        }
    }
}

// MARK: - NavigationController Delegate

extension AddSystemNavigationController: UINavigationControllerDelegate {
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        isAnimating = true
    }
    
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        isAnimating = false
        
        performDelayedSegue()
    }
}

// MARK: - NSNotification Responses

extension AddSystemNavigationController {
    
    func handleConnectionChange(notification: NSNotification) {
        if notification.name == InfinityBLEDevice.connectionChange {
            guard let device = notification.object as? InfinityBLEDevice else { return }
            
            if device.isConnected {
                // Dismiss the presented view controller if we have one.
                if let _ = presentedViewController as? SystemDisconnectedViewController {
                    dismiss(animated: true, completion: { [weak self] in
                        self?.performDelayedSegue()
                    })
                }
            } else if device.state == .disconnected {
                delay(0.5) { [weak self] in
                    guard let strongSelf = self else { return }
                    
                    // Show the System Disconnected screen.
                    if !strongSelf.isAnimating {
                        strongSelf.performSegue(withIdentifier: SegueIdentifiers.showSystemDisconnected, sender: self)
                    } else {
                        strongSelf.segueToPerform = SegueIdentifiers.showSystemDisconnected
                    }
                }
            }
        }
    }
}
