//
//  AppDelegate.swift
//  clipboardcopies
//
//  Created by Owen Imholte on 11/9/21.
//

import Cocoa

extension String {
    var isValidURL: Bool {
        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        if let match = detector.firstMatch(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count)) {
            // it is a link, if the match covers the whole string
            return match.range.length == self.utf16.count
        } else {
            return false
        }
    }
}

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.squareLength)
    let popover = NSPopover()
    var timer = Timer()
    
    var lastClipboardContents = ""
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        if let button = self.statusItem.button {
            button.image = NSImage(named: NSImage.Name("ExampleMenuBarIcon"))
            button.action = #selector(AppDelegate.togglePopover(_:))
        }
        
        self.popover.contentViewController = ViewController.newInsatnce()
        self.popover.animates = false
        
        self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in
            self.checkClipboard()
        })
    }
    
    func checkClipboard(){
        let pasteBoard = NSPasteboard.general
        
        if let newClipboardValue = pasteBoard.string(forType: .string) {
            //print("\(lastClipboardContents) vs \(newClipboardValue)")
            if (!(lastClipboardContents == newClipboardValue)) {
                lastClipboardContents = newClipboardValue
                print("Clipboard was updated")
                
                let homeDirURL = FileManager.default.homeDirectoryForCurrentUser
                // Above goes into an app sandbox documents directory
                // print ("home is at: \(homeDirURL)")
                // we could disable sandboxing to put this where we actually want to... ~/.clipboards
                
                // Another alternate approach:
                // let DocumentDirectory = NSURL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
                
                let clipboardDirectoryPath = homeDirURL.appendingPathComponent("CLIPBOARDS")
                do {
                    try FileManager.default.createDirectory(atPath: clipboardDirectoryPath.path, withIntermediateDirectories: true, attributes: nil)
                } catch let error as NSError {
                    print("Unable to create directory \(error.debugDescription)")
                }
                
                if let newClipboardValue = pasteBoard.string(forType: .string) {
                    if newClipboardValue.isValidURL {
                        print("URL Found: \(newClipboardValue)")
                        
                        let date = Date()
                        let format = DateFormatter()
                        format.dateFormat = "yyyy-MM-dd+HH-mm-ss"
                        let timestamp = format.string(from: date)
                        let filename = clipboardDirectoryPath.appendingPathComponent("\(timestamp).txt")
                        
                        do {
                            let output = "\(newClipboardValue)\n"
                            try output.write(to: filename, atomically: true, encoding: String.Encoding.utf8)
                            print ("Wrote clipboard file: \(filename)")
                        } catch let error as NSError {
                            // failed to write file – bad permissions, bad filename, missing permissions, or more likely it can't be converted to the encoding
                            print("Unable to write the URL to a file \(error)")
                        }
                    } else {
                        //print("Clipboard item: \(newClipboardValue) is not a URL")
                    }
                }
            }
        }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    @objc func togglePopover(_ sender: NSStatusItem) {
        if self.popover.isShown {
            closePopover(sender: sender)
        }
        else {
            showPopover(sender: sender)
        }
    }
    
    func showPopover(sender: Any?) {
        
        if let button = self.statusItem.button {
            self.popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
        }
    }
    
    func closePopover(sender: Any?)  {
        self.popover.performClose(sender)
    }
}

