//
//  ViewController.swift
//  pockiiau
//
//  Created by samiiau on 2/27/23.
//  Copyright © 2023 samiiau. All rights reserved.
//

import UIKit
import Darwin
import LaunchServicesBridge
import CoreServices

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var rootful : Bool = false
    var inst_prefix: String = "unset"
    // Viewtable options
    var tableData = [["Architecture", "iOS", "Revision"], ["Sileo", "Zebra"], ["Utilities", "Openers", "Revert Install"]]
    let sectionTitles = ["", "Managers", "Miscellaneous"]
    var switchStates = [[Bool]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Add table view to view
        let tableView = UITableView(frame: view.bounds, style: .insetGrouped)
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)

        // Icon in the middle
        let headerView = UIView(frame: CGRect(x: 0, y: -50, width: view.frame.width, height: 0))
        headerView.backgroundColor = .clear

        let imageView = UIImageView(image: UIImage(named: "AppIcon"))
        imageView.contentMode = .scaleAspectFit
        imageView.frame = CGRect(x: 0, y: 0, width: 60, height: 60)
        imageView.center = headerView.center
        imageView.layer.cornerRadius = imageView.frame.width / 4
        imageView.clipsToBounds = true
        headerView.addSubview(imageView)

        tableView.tableHeaderView = headerView
        tableView.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 20, right: 0)
        tableView.translatesAutoresizingMaskIntoConstraints = false



        
        // Check for root permissions
        if (inst_prefix == "unset") {
            guard let helper = Bundle.main.path(forAuxiliaryExecutable: "Helper") else {
                let msg = "Could not find helper?"
                print("[palera1n] \(msg)")
                return
            }
            
            let ret = spawn(command: helper, args: ["-f"], root: true)
            
            rootful = ret == 0 ? false : true
            
            inst_prefix = rootful ? "" : "/var/jb"
        }
    }

    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sectionTitles.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData[section].count
    }
    
    // MARK: - Viewtable for Cydia/Zebra/Restore Rootfs cells
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.textLabel?.text = tableData[indexPath.section][indexPath.row]
        
        if tableData[indexPath.section][indexPath.row] == "Revert Install" {
            if FileManager.default.fileExists(atPath: "/var/jb/.procursus_strapped") {
                cell.isHidden = false
                cell.isUserInteractionEnabled = true
                cell.accessoryType = .disclosureIndicator
                cell.textLabel?.textColor = .systemRed
            } else if FileManager.default.fileExists(atPath: "/.procursus_strapped"){
                cell.isUserInteractionEnabled = false
                cell.accessoryType = .disclosureIndicator
                cell.textLabel?.textColor = .gray
                cell.detailTextLabel?.text = "Rootful cannot use this button :("
                cell.selectionStyle = .none
            } else {
                cell.isUserInteractionEnabled = false
                cell.accessoryType = .disclosureIndicator
                cell.textLabel?.textColor = .gray
                cell.selectionStyle = .none
            }
        } else if tableData[indexPath.section][indexPath.row] == "Sileo" || tableData[indexPath.section][indexPath.row] == "Zebra" {
            guard Bundle.main.path(forAuxiliaryExecutable: "Helper") != nil else {
                cell.isUserInteractionEnabled = false
                cell.accessoryType = .disclosureIndicator
                cell.textLabel?.textColor = .gray
                cell.selectionStyle = .default
                return cell
            };
            cell.isUserInteractionEnabled = true
            cell.accessoryType = .disclosureIndicator
            cell.detailTextLabel?.text = tableData[indexPath.section][indexPath.row] == "Sileo" ? "Modern package manager" : "Familiar looking package manager"
            cell.selectionStyle = .default
        }
        
        if tableData[indexPath.section][indexPath.row] == "Sileo" {
            let originalImage = UIImage(named: "Sileo_logo")
            let resizedImage = UIGraphicsImageRenderer(size: CGSize(width: 30, height: 30)).image { _ in
                originalImage?.draw(in: CGRect(x: 0, y: 0, width: 30, height: 30))
            }
            cell.imageView?.image = resizedImage
        } else if tableData[indexPath.section][indexPath.row] == "Zebra" {
            let originalImage = UIImage(named: "Zebra_logo")
            let resizedImage = UIGraphicsImageRenderer(size: CGSize(width: 30, height: 30)).image { _ in
                originalImage?.draw(in: CGRect(x: 0, y: 0, width: 30, height: 30))
            }
            cell.imageView?.image = resizedImage
        }
        if tableData[indexPath.section][indexPath.row] == "Utilities" || tableData[indexPath.section][indexPath.row] == "Openers"{
            cell.isUserInteractionEnabled = true
            cell.accessoryType = .disclosureIndicator
            cell.textLabel?.textColor = .systemBlue
            cell.selectionStyle = .default
        }
        if tableData[indexPath.section][indexPath.row] == "iOS" {
        }



        return cell
    }
    
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionTitles[section]
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        
        let systemVersion = UIDevice.current.systemVersion
        var architecture = ""
        
#if targetEnvironment(simulator)
        architecture = "• Simulator"
#elseif targetEnvironment(macCatalyst)
        architecture = "• Mac Catalyst"
#elseif os(iOS)
        if MemoryLayout<Int>.size == MemoryLayout<Int64>.size {
            architecture = "• arm64"
        } else {
            architecture = "• arm64e"
        }
#endif
        
        if section == tableData.count - 1 {
            return """
            palera1n • \(systemVersion) \(architecture)
            """
        }
        return nil
    }
    
    // MARK: - Actions action + actions for alertController
    @objc func openersTapped() {
        var alertController = UIAlertController(title: "Open an application", message: nil, preferredStyle: .actionSheet)
        if UIDevice.current.userInterfaceIdiom == .pad {
            alertController = UIAlertController(title: "Open an application", message: nil, preferredStyle: .alert)
        }
        
        // Create actions for each app to be opened
        let openSAction = UIAlertAction(title: "Open Sileo", style: .default) { (_) in
            if LSApplicationWorkspace.default().openApplication(withBundleID: "org.coolstar.SileoStore") {
            } else {
                if LSApplicationWorkspace.default().openApplication(withBundleID: "org.coolstar.SileoNightly") {
                    return
                }
            }
        }
        
        let openZAction = UIAlertAction(title: "Open Zebra", style: .default) { (_) in
            if LSApplicationWorkspace.default().openApplication(withBundleID: "xyz.willy.Zebra") {
            }
        }
        
        let openTHAction = UIAlertAction(title: "Open TrollHelper", style: .default) { (_) in
            if LSApplicationWorkspace.default().openApplication(withBundleID: "com.opa334.trollstorepersistencehelper") {
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
        }
        
        alertController.addAction(openSAction)
        alertController.addAction(openZAction)
        alertController.addAction(openTHAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    @objc func actionsTapped() {
        var type = "Unknown"
        if rootful {
            type = "Rootful"
        } else if !rootful {
            type = "Rootless"
        }
        
        var installed = "False"
        if FileManager.default.fileExists(atPath: "/.procursus_strapped") || FileManager.default.fileExists(atPath: "/var/jb/.procursus_strapped") {
            installed = "True"
        }
        
        let processInfo = ProcessInfo()
        let systemVersion = processInfo.operatingSystemVersionString
        var architecture = ""
        
#if targetEnvironment(simulator)
        architecture = "Simulator"
#elseif targetEnvironment(macCatalyst)
        architecture = "Mac Catalyst"
#elseif os(iOS)
        if MemoryLayout<Int>.size == MemoryLayout<Int64>.size {
            architecture = "arm64"
        } else {
            architecture = "arm64e"
        }
#endif
        
        var alertController = UIAlertController(title: """
        Type: \(type)
        Installed: \(installed)
        Architecture: \(architecture)
        \(systemVersion)
        """, message: nil, preferredStyle: .actionSheet)
        if UIDevice.current.userInterfaceIdiom == .pad {
            alertController = UIAlertController(title: """
            Type: \(type)
            Installed: \(installed)
            Architecture: \(architecture)
            \(systemVersion)
            """, message: nil, preferredStyle: .alert)
        }
        
        let respringAction = UIAlertAction(title: "SBReload", style: .default) { (_) in
            spawn(command: "\(self.inst_prefix)/usr/bin/sbreload", args: [], root: true)
        }
        let softrebootAction = UIAlertAction(title: "Userspace Reboot", style: .default) { (_) in
            spawn(command: "\(self.inst_prefix)/usr/bin/launchctl", args: ["reboot", "userspace"], root: true)
        }
        let uicacheAction = UIAlertAction(title: "UICache", style: .default) { (_) in
            spawn(command: "\(self.inst_prefix)/usr/bin/uicache", args: ["-a"], root: true)
        }
        let daemonAction = UIAlertAction(title: "Launch Daemons", style: .default) { (_) in
            spawn(command: "\(self.inst_prefix)/bin/launchctl", args: ["bootstrap", "system", "/var/jb/Library/LaunchDaemons"], root: true)
        }
        let mountAction = UIAlertAction(title: "Mount Directories", style: .default) { (_) in
            spawn(command: "/sbin/mount", args: ["-uw", "/private/preboot"], root: true)
            spawn(command: "/sbin/mount", args: ["-uw", "/"], root: true)
        }
        let enabletweaksAction = UIAlertAction(title: "Enable Tweaks", style: .default) { (_) in
            if self.rootful {
                spawn(command: "/etc/rc.d/substitute-launcher", args: [], root: true)
            } else {
                spawn(command: "/var/jb/usr/libexec/ellekit/loader", args: [], root: true)
            }
        }
        let allAction = UIAlertAction(title: "Do All", style: .default) { (_) in
            spawn(command: "/sbin/mount", args: ["-uw", "/private/preboot"], root: true)
            spawn(command: "/sbin/mount", args: ["-uw", "/"], root: true)
            spawn(command: "\(self.inst_prefix)/usr/bin/uicache", args: ["-a"], root: true)
            spawn(command: "\(self.inst_prefix)/usr/bin/launchctl", args: ["reboot", "userspace"], root: true)
            if self.rootful {
                spawn(command: "/etc/rc.d/substitute-launcher", args: [], root: true)
            } else {
                spawn(command: "/var/jb/usr/libexec/ellekit/loader", args: [], root: true)
            }
            spawn(command: "\(self.inst_prefix)/usr/bin/sbreload", args: [], root: true)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
        }
        alertController.addAction(respringAction)
        alertController.addAction(uicacheAction)
        alertController.addAction(daemonAction)
        alertController.addAction(mountAction)
        alertController.addAction(enabletweaksAction)
        alertController.addAction(allAction)
        alertController.addAction(softrebootAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    // MARK: - Recognize if switches are togged + install action (WIP)
    
    private func deleteFile(file: String) -> Void {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent(file)
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    private func downloadFile(file: String, server: String = "https://static.palera.in/rootless") -> Void {
        var loadingAlert: UIAlertController? = nil
        
        deleteFile(file: file)
        
        DispatchQueue.main.async {
            loadingAlert = UIAlertController(title: nil, message: "Downloading...", preferredStyle: .alert)
            let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
            loadingIndicator.hidesWhenStopped = true
            loadingIndicator.startAnimating()
            
            loadingAlert?.view.addSubview(loadingIndicator)
            self.present(loadingAlert!, animated: true)
        }
        
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent(file)
        let url = URL(string: "\(server)/\(file)")!
        let semaphore = DispatchSemaphore(value: 0)
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        let task = session.downloadTask(with: url) { tempLocalUrl, response, error in
            if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                if statusCode != 200 {
                    if server.contains("cdn.nickchan.lol") {
                        DispatchQueue.main.async {
                            loadingAlert?.dismiss(animated: true, completion: nil)
                            let alertController = self.errorAlert(title: "Could not download file", message: "\(error?.localizedDescription ?? "Unknown error")")
                            self.present(alertController, animated: true, completion: nil)
                            NSLog("[palera1n] Could not download file: \(error?.localizedDescription ?? "Unknown error")")
                        }
                        return
                    }
                    self.downloadFile(file: file, server: server.replacingOccurrences(of: "static.palera.in", with: "cdn.nickchan.lol/palera1n/loader/assets"))
                    return
                }
            }
            if let tempLocalUrl = tempLocalUrl, error == nil {
                do {
                    try FileManager.default.copyItem(at: tempLocalUrl, to: fileURL)
                    semaphore.signal()
                    DispatchQueue.main.async {
                        // Dismiss the loading alert controller
                        loadingAlert?.dismiss(animated: true, completion: nil)
                    }
                } catch (let writeError) {
                    DispatchQueue.main.async {
                        loadingAlert?.dismiss(animated: true, completion: nil)
                        let delayTime = DispatchTime.now() + 0.2
                        DispatchQueue.main.asyncAfter(deadline: delayTime) {
                            let alertController = self.errorAlert(title: "Could not copy file to disk", message: "\(writeError)")
                            if let presentedVC = self.presentedViewController {
                                presentedVC.dismiss(animated: true) {
                                    self.present(alertController, animated: true)
                                }
                            } else {
                                self.present(alertController, animated: true)
                            }
                        }
                        NSLog("[palera1n] Could not copy file to disk: \(error?.localizedDescription ?? "Unknown error")")
                        return
                    }
                }
            } else {
                DispatchQueue.main.async {
                    loadingAlert?.dismiss(animated: true, completion: nil)
                    let delayTime = DispatchTime.now() + 0.2
                    DispatchQueue.main.asyncAfter(deadline: delayTime) {
                        let alertController = self.errorAlert(title: "Could not download file", message: "\(error?.localizedDescription ?? "Unknown error")")
                        if let presentedVC = self.presentedViewController {
                            presentedVC.dismiss(animated: true) {
                                self.present(alertController, animated: true)
                            }
                        } else {
                            self.present(alertController, animated: true)
                        }
                    }
                    NSLog("[palera1n] Could not download file: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
            }
        }
        task.resume()
        semaphore.wait()
    }
    
    var InstallSileo = false
    var InstallZebra = false
    
    private func strap() -> Void {
        let alertController = errorAlert(title: "Install Completed", message: "You may close the app.")
        guard let helper = Bundle.main.path(forAuxiliaryExecutable: "Helper") else {
            let msg = "Could not find helper?"
            print("[palera1n] \(msg)")
            return
        }
        
        let ret = spawn(command: helper, args: ["-f"], root: true)
        
        let rootful = ret == 0 ? false : true
        
        let inst_prefix = rootful ? "/" : "/var/jb"
        
        DispatchQueue.global(qos: .userInitiated).async {
            print("[strap] User initiated strap process...")
            DispatchQueue.global(qos: .utility).async { [self] in
                var debName = ""
                if self.InstallSileo {
                    debName = "sileo.deb"
                }
                if self.InstallZebra {
                    debName = "zebra.deb"
                }
                
                if rootful {
                    downloadFile(file: "bootstrap.tar", server: "https://static.palera.in")
                    downloadFile(file: debName, server: "https://static.palera.in")
                } else {
                    downloadFile(file: "bootstrap.tar")
                    downloadFile(file: debName)
                }
                
                DispatchQueue.main.async {
                    guard let tar = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("bootstrap.tar").path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
                        let msg = "Failed to find bootstrap"
                        print("[palera1n] \(msg)")
                        return
                    }
                    
                    guard let deb = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(debName).path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
                        let msg = "Could not find package manager"
                        print("[palera1n] \(msg)")
                        return
                    }
                    
                    let loadingAlert = UIAlertController(title: nil, message: "Installing...", preferredStyle: .alert)
                    let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
                    loadingIndicator.hidesWhenStopped = true
                    loadingIndicator.startAnimating()
                    
                    loadingAlert.view.addSubview(loadingIndicator)
                    
                    // Installing... Alert
                    self.present(loadingAlert, animated: true) {
                        DispatchQueue.global(qos: .utility).async {
                            spawn(command: "/sbin/mount", args: ["-uw", "/private/preboot"], root: true)
                            
                            if rootful {
                                spawn(command: "/sbin/mount", args: ["-uw", "/"], root: true)
                            }
                            
                            let ret = spawn(command: helper, args: ["-i", tar], root: true)
                            
                            spawn(command: "\(inst_prefix)/usr/bin/chmod", args: ["4755", "\(inst_prefix)/usr/bin/sudo"], root: true)
                            spawn(command: "\(inst_prefix)/usr/bin/chown", args: ["root:wheel", "\(inst_prefix)/usr/bin/sudo"], root: true)
                            
                            DispatchQueue.main.async {
                                if ret != 0 {
                                    loadingAlert.dismiss(animated: true) {
                                        let alertController = self.errorAlert(title: "Error installing bootstrap", message: "Status: \(ret)")
                                        self.present(alertController, animated: true, completion: nil)
                                        print("[strap] Error installing bootstrap. Status: \(ret)")
                                        return
                                    }
                                }
                                
                                DispatchQueue.global(qos: .utility).async {
                                    let ret = spawn(command: "\(inst_prefix)/usr/bin/sh", args: ["\(inst_prefix)/prep_bootstrap.sh"], root: true)
                                    DispatchQueue.main.async {
                                        if ret != 0 {
                                            loadingAlert.dismiss(animated: true) {
                                                let alertController = self.errorAlert(title: "Error installing bootstrap", message: "Status: \(ret)")
                                                self.present(alertController, animated: true, completion: nil)
                                                print("[strap] Error installing bootstrap. Status: \(ret)")
                                                return
                                            }
                                        }
                                        
                                        DispatchQueue.global(qos: .utility).async {
                                            let ret = spawn(command: "\(inst_prefix)/usr/bin/dpkg", args: ["-i", deb], root: true)
                                            
                                            if !rootful {
                                                let sourcesFilePath = "/var/jb/etc/apt/sources.list.d/procursus.sources"
                                                var procursusSources = ""
                                                
                                                if UIDevice.current.systemVersion.contains("15") {
                                                    procursusSources = """
                                                        Types: deb
                                                        URIs: https://ellekit.space/
                                                        Suites: ./
                                                        Components:
                                                        
                                                        Types: deb
                                                        URIs: https://repo.palera.in/
                                                        Suites: ./
                                                        Components:
                                                        
                                                        Types: deb
                                                        URIs: https://apt.procurs.us/
                                                        Suites: 1800
                                                        Components: main
                                                        
                                                        """
                                                } else if UIDevice.current.systemVersion.contains("16") {
                                                    procursusSources = """
                                                        Types: deb
                                                        URIs: https://ellekit.space/
                                                        Suites: ./
                                                        Components:
                                                        
                                                        Types: deb
                                                        URIs: https://repo.palera.in/
                                                        Suites: ./
                                                        Components:
                                                        
                                                        Types: deb
                                                        URIs: https://apt.procurs.us/
                                                        Suites: 1900
                                                        Components: main
                                                        
                                                        """
                                                }
                                                
                                                spawn(command: "/var/jb/bin/sh", args: ["-c", "echo '\(procursusSources)' > \(sourcesFilePath)"], root: true)
                                            } else {
                                                let sourcesFilePath = "/etc/apt/sources.list.d/procursus.sources"
                                                var procursusSources = ""
                                                
                                                if UIDevice.current.systemVersion.contains("15") {
                                                    procursusSources = """
                                                        Types: deb
                                                        URIs: https://repo.palera.in/
                                                        Suites: ./
                                                        Components:
                                                        
                                                        Types: deb
                                                        URIs: https://strap.palera.in/
                                                        Suites: iphoneos-arm64/1800
                                                        Components: main
                                                        
                                                        """
                                                } else if UIDevice.current.systemVersion.contains("16") {
                                                    procursusSources = """
                                                        Types: deb
                                                        URIs: https://repo.palera.in/
                                                        Suites: ./
                                                        Components:
                                                        
                                                        Types: deb
                                                        URIs: https://strap.palera.in/
                                                        Suites: iphoneos-arm64/1900
                                                        Components: main
                                                        
                                                        """
                                                }
                                                
                                                spawn(command: "/bin/sh", args: ["-c", "echo '\(procursusSources)' > \(sourcesFilePath)"], root: true)
                                            }
                                            
                                            DispatchQueue.main.async {
                                                if ret != 0 {
                                                    let alertController = self.errorAlert(title: "Failed to install packages", message: "Status: \(ret)")
                                                    self.present(alertController, animated: true, completion: nil)
                                                    print("[strap] Failed to install packages. Status: \(ret)")
                                                    return
                                                }
                                                
                                                DispatchQueue.global(qos: .utility).async {
                                                    let ret = spawn(command: "\(inst_prefix)/usr/bin/uicache", args: ["-a"], root: true)
                                                    DispatchQueue.main.async {
                                                        if ret != 0 {
                                                            let alertController = self.errorAlert(title: "Failed to uicache", message: "Status: \(ret)")
                                                            self.present(alertController, animated: true, completion: nil)
                                                            print("[strap] Failed to uicache. Status: \(ret)")
                                                            return
                                                        }
                                                    }
                                                }
                                            }
                                            
                                            DispatchQueue.main.async {
                                                loadingAlert.dismiss(animated: true) {
                                                    let delayTime = DispatchTime.now() + 0.2
                                                    DispatchQueue.main.asyncAfter(deadline: delayTime) {
                                                        self.present(alertController, animated: true)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableData[indexPath.section][indexPath.row] == "Utilities" {
                actionsTapped()
            }
        if tableData[indexPath.section][indexPath.row] == "Openers" {
                openersTapped()
            }
        if tableData[indexPath.section][indexPath.row] == "Revert Install" {
            var alertController = UIAlertController(title: "Confirm", message: "Are you sure you want to remove your jailbreak?", preferredStyle: .actionSheet)
            if UIDevice.current.userInterfaceIdiom == .pad {
                alertController = UIAlertController(title: "Confirm", message: "Are you sure you want to remove your jailbreak?", preferredStyle: .alert)
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            let confirmAction = UIAlertAction(title: "Revert Install", style: .destructive) { _ in
                self.nuke()
            }
            alertController.addAction(cancelAction)
            alertController.addAction(confirmAction)
            present(alertController, animated: true, completion: nil)
        } else if tableData[indexPath.section][indexPath.row] == "Sileo" {
            
            
            
            if FileManager.default.fileExists(atPath: "/Applications/Sileo.app") || FileManager.default.fileExists(atPath: "/var/jb/Applications/Sileo.app") || FileManager.default.fileExists(atPath: "/var/jb/Applications/Sileo-Nightly.app") || FileManager.default.fileExists(atPath: "/var/jb/Applications/Sileo-Nightly.app") {
                var alertController = UIAlertController(title: "Re-install Sileo-Nightly?", message: "Are you sure you want to re-install Sileo-Nightly?", preferredStyle: .actionSheet)
                if UIDevice.current.userInterfaceIdiom == .pad {
                    alertController = UIAlertController(title: "Re-install Sileo-Nightly?", message: "Are you sure you want to re-install Sileo-Nightly?", preferredStyle: .alert)
                }
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                let confirmAction = UIAlertAction(title: "Re-install", style: .destructive) { _ in
                    self.reInstallSileo()
                }
                alertController.addAction(cancelAction)
                alertController.addAction(confirmAction)
                present(alertController, animated: true, completion: nil)
            } else if FileManager.default.fileExists(atPath: "/.procursus_strapped") || FileManager.default.fileExists(atPath: "/var/jb/.procursus_strapped") {
                var alertController = UIAlertController(title: "Install Sileo-Nightly?", message: "Are you sure you want to Install Sileo-Nightly?", preferredStyle: .actionSheet)
                if UIDevice.current.userInterfaceIdiom == .pad {
                    alertController = UIAlertController(title: "Install Sileo-Nightly?", message: "Are you sure you want to Install Sileo-Nightly?", preferredStyle: .alert)
                }
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                let confirmAction = UIAlertAction(title: "Install", style: .destructive) { _ in
                    self.reInstallSileo()
                }
                alertController.addAction(cancelAction)
                alertController.addAction(confirmAction)
                present(alertController, animated: true, completion: nil)
            } else {
                self.InstallSileo = true
                self.strap()
            }
            
            
            
        } else if tableData[indexPath.section][indexPath.row] == "Zebra" {
            if FileManager.default.fileExists(atPath: "/Applications/Zebra.app") || FileManager.default.fileExists(atPath: "/var/jb/Applications/Zebra.app") {
                var alertController = UIAlertController(title: "Re-install Zebra?", message: "Are you sure you want to re-install Zebra?", preferredStyle: .actionSheet)
                if UIDevice.current.userInterfaceIdiom == .pad {
                    alertController = UIAlertController(title: "Re-install Zebra?", message: "Are you sure you want to re-install Zebra?", preferredStyle: .alert)
                }
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                let confirmAction = UIAlertAction(title: "Re-install", style: .destructive) { _ in
                    self.reInstallZebra()
                }
                alertController.addAction(cancelAction)
                alertController.addAction(confirmAction)
                present(alertController, animated: true, completion: nil)
            } else if FileManager.default.fileExists(atPath: "/.procursus_strapped") || FileManager.default.fileExists(atPath: "/var/jb/.procursus_strapped") {
                var alertController = UIAlertController(title: "Install Zebra?", message: "Are you sure you want to Install Zebra?", preferredStyle: .actionSheet)
                if UIDevice.current.userInterfaceIdiom == .pad {
                    alertController = UIAlertController(title: "Install Zebra?", message: "Are you sure you want to Install Zebra?", preferredStyle: .alert)
                }
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                let confirmAction = UIAlertAction(title: "Install", style: .destructive) { _ in
                    self.reInstallZebra()
                }
                alertController.addAction(cancelAction)
                alertController.addAction(confirmAction)
                present(alertController, animated: true, completion: nil)
            } else {
                self.InstallZebra = true
                self.strap()
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func reInstallZebra() {
        let alertController = errorAlert(title: "Install Completed", message: "Enjoy!")
        guard let helper = Bundle.main.path(forAuxiliaryExecutable: "Helper") else {
            let msg = "Could not find helper?"
            print("[palera1n] \(msg)")
            return
        }
        
        let ret = spawn(command: helper, args: ["-f"], root: true)
        
        let rootful = ret == 0 ? false : true
        
        let inst_prefix = rootful ? "/" : "/var/jb"
        
        print("[strap] Installing Zebra")
        DispatchQueue.global(qos: .utility).async { [self] in
            if rootful {
                downloadFile(file: "zebra.deb", server: "https://static.palera.in")
            } else {
                downloadFile(file: "zebra.deb")
            }
            
            DispatchQueue.global(qos: .utility).async { [self] in
                guard let deb = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("zebra.deb").path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
                    let alertController = self.errorAlert(title: "Failed to install Zebra", message: "")
                    self.present(alertController, animated: true, completion: nil)
                    print("[strap] Failed to find Zebra.")
                    return
                }
                
                let ret = spawn(command: "\(inst_prefix)/usr/bin/dpkg", args: ["-i", deb], root: true)
                DispatchQueue.main.async {
                    if ret != 0 {
                        let alertController = self.errorAlert(title: "Failed to install Zebra", message: "Status: \(ret)")
                        self.present(alertController, animated: true, completion: nil)
                        print("[strap] Failed to install Zebra. Status: \(ret)")
                        return
                    }
                    let delayTime = DispatchTime.now() + 0.2
                    DispatchQueue.main.asyncAfter(deadline: delayTime) {
                        self.present(alertController, animated: true)
                        print("[strap] Installed Zebra")
                    }
                }
            }
        }
    }
    
    func reInstallSileo() {
        let alertController = errorAlert(title: "Install Completed", message: "Enjoy!")
        guard let helper = Bundle.main.path(forAuxiliaryExecutable: "Helper") else {
            let msg = "Could not find helper?"
            print("[palera1n] \(msg)")
            return
        }
        
        let ret = spawn(command: helper, args: ["-f"], root: true)
        
        let rootful = ret == 0 ? false : true
        
        let inst_prefix = rootful ? "/" : "/var/jb"
        
        print("[strap] Installing Sileo")
        DispatchQueue.global(qos: .utility).async { [self] in
            if rootful {
                downloadFile(file: "sileo.deb", server: "https://static.palera.in")
            } else {
                downloadFile(file: "sileo.deb")
            }
            
            DispatchQueue.global(qos: .utility).async { [self] in
                guard let deb = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("sileo.deb").path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
                    let alertController = self.errorAlert(title: "Failed to install Sileo", message: "")
                    self.present(alertController, animated: true, completion: nil)
                    print("[strap] Failed to find Sileo.")
                    return
                }
                
                let ret = spawn(command: "\(inst_prefix)/usr/bin/dpkg", args: ["-i", deb], root: true)
                DispatchQueue.main.async {
                    if ret != 0 {
                        let alertController = self.errorAlert(title: "Failed to install Sileo", message: "Status: \(ret)")
                        self.present(alertController, animated: true, completion: nil)
                        print("[strap] Failed to install Sileo. Status: \(ret)")
                        return
                    }
                    let delayTime = DispatchTime.now() + 0.2
                    DispatchQueue.main.asyncAfter(deadline: delayTime) {
                        self.present(alertController, animated: true)
                        print("[strap] Installed Zebra")
                    }
                }
            }
        }
    }
    
    func nuke() {
        
        print("[nuke] Starting nuke process...")
        let alertController = errorAlert(title: "Remove Completed", message: "You may close the app.")
        guard let helper = Bundle.main.path(forAuxiliaryExecutable: "Helper") else {
            let msg = "Could not find helper?"
            print("[palera1n] \(msg)")
            return
        }
        
        let ret = spawn(command: helper, args: ["-f"], root: true)
        
        let rootful = ret == 0 ? false : true
        
        let inst_prefix = rootful ? "/" : "/var/jb"
        
        if !rootful {
            
            let loadingAlert = UIAlertController(title: nil, message: "Removing...", preferredStyle: .alert)
            let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
            loadingIndicator.hidesWhenStopped = true
            loadingIndicator.startAnimating()
            
            loadingAlert.view.addSubview(loadingIndicator)
            print("[nuke] Unregistering applications")
            self.present(loadingAlert, animated: true)
            DispatchQueue.global(qos: .utility).async {
                // remove all jb apps from uicache
                let fm = FileManager.default
                let apps = try? FileManager.default.contentsOfDirectory(atPath: "/var/jb/Applications")
                for app in apps ?? [] {
                    if app.hasSuffix(".app") {
                        let ret = spawn(command: "/var/jb/usr/bin/uicache", args: ["-u", "/var/jb/Applications/\(app)"], root: true)
                        DispatchQueue.main.async {
                            if ret != 0 {
                                let alertController = self.errorAlert(title: "Failed to unregister \(app)", message: "Status: \(ret)")
                                self.present(alertController, animated: true, completion: nil)
                                print("[nuke] Failed to unregister \(app): \(ret)")
                                return
                            }
                        }
                    }
                }
                
                print("[nuke] Removing Installation...")
                let ret = spawn(command: helper, args: ["-r"], root: true)
                DispatchQueue.main.async {
                    if ret != 0 {
                        let alertController = self.errorAlert(title: "Failed to remove jailbreak", message: "Status: \(ret)")
                        self.present(alertController, animated: true, completion: nil)
                        print("[nuke] Failed to remove jailbreak: \(ret)")
                        return
                    }
                    print("[nuke] Jailbreak removed!")
                    loadingAlert.dismiss(animated: true) {
                        let delayTime = DispatchTime.now() + 0.2
                        DispatchQueue.main.asyncAfter(deadline: delayTime) {
                            self.present(alertController, animated: true)
                        }
                    }
                }
            }
        }
    }

    func errorAlert(title: String, message: String) -> UIAlertController {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Close", style: .default) { _ in
            UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                // Exit the app
                exit(0)
            }
        })
        return alertController
    }
}
