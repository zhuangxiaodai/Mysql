//
//  ViewController.swift
//  MySQLDemo
//
//  Created by ito on 2015/10/24.
//  Copyright © 2015年 Yusuke Ito. All rights reserved.
//

import Cocoa
import MySQL

class DatabaseViewController: NSViewController {

    
    @IBOutlet weak var hostField: NSTextField!
    @IBOutlet weak var portField: NSTextField!
    @IBOutlet weak var userField: NSTextField!
    @IBOutlet weak var passwordField: NSTextField!
    @IBOutlet weak var databaseComboBox: NSComboBox!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    struct Options: ConnectionOption {
        let host: String
        let port: Int
        let user: String
        let password: String
        let database: String
    }
    
    @IBAction func connectTapped(sender: AnyObject) {
        
        
        let options = Options(host: hostField.stringValue, port: Int(portField.stringValue) ?? 0, user: userField.stringValue, password: passwordField.stringValue, database: databaseComboBox.stringValue)
        do {
            let pool = ConnectionPool(options: options)
            self.performSegueWithIdentifier("Connection", sender: pool)
            
        } catch (let e) {
            print("\(e as ErrorType)")
            let err = NSError(domain: "MySQL", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "\(e as ErrorType)"
                ])
            self.presentError(err)
        }
        
    }
    
    override func prepareForSegue(segue: NSStoryboardSegue, sender: AnyObject?) {
        if let dst = segue.destinationController as? ConnectionViewController, let pool = sender as? ConnectionPool {
            dst.pool = pool
        }
    }


}

