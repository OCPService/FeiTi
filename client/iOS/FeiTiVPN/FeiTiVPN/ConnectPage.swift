//
//  ConnectPage.swift
//  FeiTiVPN
//
//  Created by FeiTi on 25/11/2016.
//  Copyright © 2016 FeiTi. All rights reserved.
//

import UIKit
import NetworkExtension
import GoogleMobileAds

class ConnectPage: UITableViewController, UIPickerViewDelegate, UIPickerViewDataSource  {
    @IBOutlet weak var cellConnect: UITableViewCell!
    @IBOutlet weak var lbConnectStatus: UILabel!
    @IBOutlet weak var switchConnect: UISwitch!
    
    @IBOutlet weak var cellSelect: UITableViewCell!
    @IBOutlet weak var pickServers: UIPickerView!
    
    @IBOutlet weak var cellStatus: UITableViewCell!
    @IBOutlet weak var cellStatusContentView: UIView!
    @IBOutlet weak var lbExpireDate: UILabel!
    @IBOutlet weak var lbExpirePrompt: UILabel!
    
    @IBOutlet weak var btnRenew: UIButton!
    @IBOutlet weak var waitRenew: UIActivityIndicatorView!
    
    var _servers : [ServerData] = []
    var _ad_clicked = false
    
    // UIPickerViewDelegate, UIPickerViewDataSource
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self._servers.count
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 40
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        /*
        let rowData = self._servers[row]
        let status = Double(rowData.Online) * 1.0 / Double(rowData.Max) * 1.0
        var title = "\(rowData.Name)"
        if status < 0.5 {
            title = "\(title) (Normal)" //正常
        }
        else if status >= 1.0 {
            title = "\(title) (Full)"   //爆满
        }
        else if status >= 0.5 && status < 1.0 {
            title = "\(title) (Busy)"   //繁忙
        }
        
        return title
        */
        
        return self._servers[row].Name
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if self.switchConnect.isOn {
            IKev2.Instance.Disconnect()
        }
        
        let server = self._servers[row]
        
        if LocalStorage.HasNewServer {
            if let hash = LocalStorage.CachedServerHash, LocalStorage.SaveHashInfo(name: "server", value: hash) {
                print("server hash saved!")
            }
        }
        
        if let user = LocalStorage.CachedUser {
            self.switchConnect.isEnabled = user.Kind >= server.Kind
            if let nav = self.navigationController, nav.tabBarItem.badgeValue != nil, !LocalStorage.HasNewServer, !user.IsExpired {
                nav.tabBarItem.badgeValue = nil
            }
        }
        else {
            self.switchConnect.isEnabled = false
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        AdMob.Instance.InterAdReceived = self.AdReceived
        AdMob.Instance.InterAdClicked = self.AdClicked
        AdMob.Instance.InterAdDismissed = self.AdDismissed
        AdMob.Instance.InterAdReceiveFailed = self.AdReceiveFailed
        
        // Do any additional setup after loading the view, typically from a nib.
        if let servers = LocalStorage.CachedServers {
            self._servers = servers
        }
        
        self.tableView.alwaysBounceVertical = false
        self.cellConnect.selectionStyle = UITableViewCellSelectionStyle.none
        self.cellStatus.selectionStyle = UITableViewCellSelectionStyle.none
        self.cellSelect.selectionStyle = UITableViewCellSelectionStyle.none
        self.pickServers.delegate = self
        self.pickServers.dataSource = self
        
        self.waitRenew.isHidden = true
        
        IKev2.Instance.VPNStatusChanged = self.SyncConnectStatusUI
    }
    
    func SyncConnectStatusUI(status: NEVPNStatus) -> Void {
        switch status {
        case NEVPNStatus.connected:
            self.lbConnectStatus.text = "connect_status_connected".local()
            break
        case NEVPNStatus.connecting:
            self.lbConnectStatus.text = "connect_status_connecting".local()
            break
        case NEVPNStatus.disconnected:
            self.lbConnectStatus.text = "connect_status_disconnected".local()
            break
        case NEVPNStatus.disconnecting:
            self.lbConnectStatus.text = "connect_status_disconnecting".local()
            break
        case NEVPNStatus.reasserting:
            self.lbConnectStatus.text = "connect_status_reconnecting".local()
            break
        default:
            self.lbConnectStatus.text = "connect_status_disconnected".local()
            break
        }
        
        if (status == NEVPNStatus.connected || status == NEVPNStatus.connecting) {
            if !self.switchConnect.isOn {
                self.switchConnect.isOn = true
            }
            self.pickServers.isUserInteractionEnabled = false
            self.pickServers.backgroundColor = UIColor.lightGray
        }
        else {
            if self.switchConnect.isOn {
                self.switchConnect.isOn = false
            }
            self.pickServers.isUserInteractionEnabled = true
            self.pickServers.backgroundColor = UIColor.white
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        IKev2.Instance.GetConnectionStatus(callback: self.SyncConnectStatusUI)
        self.LoadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func ConnectSwitchTouched(_ sender: UISwitch) {
        if sender.isOn {
            let selectedRow = self.pickServers.selectedRow(inComponent: 0)
            if selectedRow > -1 {
                if let user = LocalStorage.CachedUser {
                    if selectedRow >= 0 {
                        let server = self._servers[selectedRow]
                        if let ip = server.IP {
                            IKev2.Instance.ConnectForXAuthOrEAP(name: "FeiTiVPN", serverAddress: ip, username: user.Hash, password: "ilovefeiti", sharedSecret: "ilovefeiti", remoteIdentifier: "server.feiti.ios", localIdentifier: "client.feiti.ios", errorHandler: {(error) -> Void in
                                self.SyncConnectStatusUI(status: NEVPNStatus.invalid)
                            })
                        }
                        else {
                            self.ShowAlert(title: "connect_prompt_title".local(), message:                                String(format: "connect_prompt_content".local(), server.Name))
                            
                        }
                    }
                }
            }
        }
        else {
            IKev2.Instance.Disconnect()
        }
    }
    
    
    @IBAction func TapRenew(_ sender: UIButton) {
        self.ShowAd()
    }
    
    func LoadData() {
        if let user = LocalStorage.CachedUser {
            self.lbExpireDate.text = Utility.LocalDate(from: user.Expire)
            
            if user.IsExpired {
                self.btnRenew.isHidden = false
                self.waitRenew.isHidden = true
                self.switchConnect.isEnabled = false
                self.cellStatusContentView.backgroundColor = UIColor.lightGray
                self.lbExpirePrompt.text = "connect_user_expired".local()
                self.lbExpirePrompt.textColor = UIColor.red
                self.lbExpireDate.textColor = UIColor.red
                
                if let nav = self.navigationController, nav.tabBarItem.badgeValue == nil {
                    nav.tabBarItem.badgeValue = ""
                }
            }
            else {
                self.btnRenew.isHidden = true
                self.waitRenew.isHidden = true
                self.switchConnect.isEnabled = true
                self.cellStatusContentView.backgroundColor = UIColor.white
                self.lbExpirePrompt.text = "connect_user_active".local()
                self.lbExpirePrompt.textColor = UIColor.black
                self.lbExpireDate.textColor = UIColor.black
            }
        }
        else {
            self.FailureHandler(scenario: "connect_page_get_user_failure", error: FeiTiAPIError.LOCAL_USER_INVALID, completion: {() -> Void in
                self.performSegue(withIdentifier: "ConnectPageToHomePage", sender: self)
            })
        }
    }
    
    // Free Refresh
    func FreeRefresh() {
        self.btnRenew.isHidden = true
        self.waitRenew.isHidden = false
        FeiTiAPI.Instance.FreeRefresh(ad_clicked: self._ad_clicked, ad_presented: false, success: {(hour, points) -> Void in
            self.ShowAlert(title: nil, message: String(format: "buy_free_refresh_success".local(), hour, points))
            self.LoadData()
            
            if let nav = self.navigationController, nav.tabBarItem.badgeValue != nil, !LocalStorage.HasNewServer {
                nav.tabBarItem.badgeValue = nil
            }
            
        }, failure: {(error) -> Void in
            self.FailureHandler(scenario: "buy_page_refresh_failure", error: FeiTiAPIError.HTTP_USER_FREE_REFRESH_FAILURE, completion: {() in
                self.btnRenew.isHidden = false
            })
        })
    }
    
    // Interstitial AD
    func ShowAd() {
        self._ad_clicked = false
        if let ad = LocalStorage.CachedAd, ad.DisplayInterAd {
            let adID = ad.InterAdID
            AdMob.Instance.RequestInterAd(adUnitID: adID)
        }
        else {
            self.FreeRefresh()
        }
    }
    
    // Interstitial AD callbacks
    func AdReceived(ad: GADInterstitial) {
        AdMob.Instance.PresentInterAd(rootViewController: self)
        FeiTiAPI.Instance.AdPresented(success: {() -> Void in}, failure: {(error) -> Void in})
    }
    
    func AdReceiveFailed(ad: GADInterstitial, error: GADRequestError) {
        self.FreeRefresh()
    }
    
    func AdClicked(ad: GADInterstitial) {
        //print("AdClicked")
        self._ad_clicked = true
        FeiTiAPI.Instance.AdClicked(success: {() -> Void in}, failure: {(error) -> Void in})
    }
    
    func AdDismissed(ad: GADInterstitial) {
        //print("AdDismissed")
        self._ad_clicked = true
        self.FreeRefresh()
    }
}
