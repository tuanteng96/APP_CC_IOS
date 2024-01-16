//
//  App21.swift
//  Cser21
//
//  Created by Hung-Catalina on 3/21/20.
//  Copyright © 2020 High Sierra. All rights reserved.
//
import Foundation
import UIKit
import MobileCoreServices
import AVFoundation
import Photos
import AudioToolbox

class App21 : NSObject, CLLocationManagerDelegate
{
    var caller:  ViewController
    init(viewController: ViewController)
    {
        caller = viewController;
        
    }
    
    func convertToDictionary(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }

    //MARK: - App21Result
    func App21Result(result: Result) -> Void {
        do {
           let jsonEncoder = JSONEncoder()
           let jsonData = try jsonEncoder.encode(result)
           let json = String(data: jsonData, encoding: String.Encoding.utf8)
           //chuyen ve base64 -> khong bi loi ky tu dac biet
           let base64 = json?.base64Encoded();
           DispatchQueue.main.async(execute: {
               self.caller.evalJs(str: "App21Result('BASE64:" + base64! + "')");
           })
        } catch  {
            //
            NSLog("App21Result -> " + error.localizedDescription);
        }
        
    }
    
    //MARK: - call
    func call(jsonStr: String) -> Void {
        //
        
        let result = Result();
       
        
        do {
            let data = jsonStr.data(using: .utf8);
            let json = try JSONSerialization.jsonObject(with: data! , options: []) as? [String: Any];
            result.sub_cmd = json!["sub_cmd"] as? String;
            result.sub_cmd_id = json!["sub_cmd_id"] as! Int;
            result.params = json!["params"] as? String;
            
            
            //var selector = Selector(result.sub_cmd! + ":");
            
            //var selector = #selector(App21.REBOOT(result:)) => run ok
            
            //see: https://forums.developer.apple.com/thread/86081
            let selector = Selector(result.sub_cmd! + "WithResult:")
            if(selector.hashValue==0){
                result.success = false;
                result.error = (result.sub_cmd ?? "") +  " NOT FOUND";
                App21Result(result: result)
                return;
            }
            performSelector(inBackground: selector, with: result)
           
           // App21Result(result: result);
            return;
        }
        catch let e as NSException{
            NSLog(e.reason!)
        }
        catch  {
            print(error.localizedDescription);
            result.success = false;
            result.error = error.localizedDescription;
            App21Result(result: result);
        }
    }
    
    //MARK: - BACKGROUND
    @objc func BACKGROUND(result: Result) -> Void {
        //
        result.success = true;
        App21Result(result: result);
        DispatchQueue.main.async { // Correct
            self.caller.setBackground(params: result.params)
        }
    }
    
    //MARK: - STATUS BAR COLOR
    @objc func STATUS_BAR_COLOR(result: Result) -> Void {
        //
        result.success = true;
        App21Result(result: result);
        DispatchQueue.main.async { // Correct
            self.caller.changeStatusBarColor(params: result.params)
        }
    }
    
    //MARK: - REBOOT
    @objc func REBOOT(result: Result) -> Void {
        //
        result.success = true;
        App21Result(result: result);
        
        let miliSecond = Int(result.params ?? "0") ?? 0;
        let s = miliSecond/1000;
        DispatchQueue.main.asyncAfter(deadline:.now() + Double(s)) {
            self.caller.reloadStoryboard();
        }
    }
    
    
    
    
    //MARK: - CAMERA
    @objc func CAMERA(result: Result) -> Void {
        //
        DispatchQueue.main.async(execute: {
            // self.caller.openCamera(result: result);
            self._PERMISSION(permission: PermissionName.camera,result: result, ok:{(mess: String) -> Void in
                //go
                NSLog("ok->openCamera");
                
                AttachmentHandler.shared.showCamera(vc: self.caller);
                
                AttachmentHandler.shared.imagePickedBlock = { (image) in
                    /* get your image here */
                    //Use image name from bundle to create NSData
                    // let image : UIImage = UIImage(named:"imageNameHere")!
                    //Now use image to create into NSData format
                    //let imageData:NSData = image.pngData()! as NSData
                    
                    //let strBase64 = imageData.base64EncodedString(options: .lineLength64Characters)
                    result.success = true
                    let src = DownloadFileTask().save(image: image,
                                                      opt: self.paramsToDic(params: result.params));
                    result.data = JSON(src);
                    self.App21Result(result: result);
                }
                
            })
        })
    }
    
    var record21: Record21? = nil
    //MARK: - RECORD_AUDIO
    @objc func RECORD_AUDIO(result: Result) -> Void {
        if(record21 == nil) {
            record21 = Record21()
        }
        record21!.RecordAudio(result: result, app21: self)
    }
    
    //MARK: - RECORD_VIDEO
    @objc func RECORD_VIDEO(result: Result) -> Void {
        //
        DispatchQueue.main.async(execute: {
            // self.caller.openCamera(result: result);
            self._PERMISSION(permission: PermissionName.video,result: result, ok:{(mess: String) -> Void in
                //go
                NSLog("ok->openCamera");
                
                
                AttachmentHandler.shared.captionVideo = true
                AttachmentHandler.shared.showCamera(vc: self.caller);
                
                AttachmentHandler.shared.videoPickedBlock = { (video) in
                    /* get your image here */
                    //Use image name from bundle to create NSData
                    // let image : UIImage = UIImage(named:"imageNameHere")!
                    //Now use image to create into NSData format
                    //let imageData:NSData = image.pngData()! as NSData
                    
                    //let strBase64 = imageData.base64EncodedString(options: .lineLength64Characters)
                    result.success = true
                    

                    
                    let src = DownloadFileTask().saveURL(url: video as URL, suffix: "RECORD_VIDEO.mp4");
                    result.data = JSON(src);
                    self.App21Result(result: result);
                }
                
            })
        })
    }
    
    
    
    
    //MARK: - LOCATION
    @objc func LOCATION(result: Result) -> Void {
        /*
        result.success = true;
        let loc21 = Loction21()
        loc21.app21 = self
        loc21.run(result: result)
        */
        caller.locationCallback = {(loc: CLLocationCoordinate2D?, status: CLAuthorizationStatus? ) in
            result.success = loc != nil
            if(loc != nil)
            {
                let d: [String: Double] = [
                    "lat": loc!.latitude,
                    "lng": loc!.longitude
                ]
                
                result.data = JSON(d)
            }
            self.App21Result(result: result);
        }
        caller.requestLoction()
    }
    
    //MARK: - DOWNLOAD
    @objc func DOWNLOAD(result: Result) -> Void
    {
        DownloadFileTask().load(src: result.params!, success: { (absPath: String) -> Void in
//
            result.success = true;

            //result.data = JSON(absPath);
            result.data = JSON(DownloadFileTask.toLocalSchemeUrl(absPath));
            self.App21Result(result: result)
            
        }) { (mess: String)  -> Void in
            //
            result.success = false;
            result.error = mess;
            self.App21Result(result: result)
        }
    }
    
    //MARK: - BASE64
    @objc func BASE64(result: Result) -> Void
    {
        DispatchQueue.global().async {
            do
            {
                let decoder = JSONDecoder()
                
                let rq = try decoder.decode(Base64Require.self, from: result.params!.data(using: .utf8)!)
                
                
                let b64 = DownloadFileTask().toBase64(src: rq.path)
                result.success = b64 != nil
                // Bounce back to the main thread to update the UI
                DispatchQueue.main.async {
                    self.App21Result(result: result)
                    self.caller.evalJs(str: rq.callback! + "('" + b64! + "')")
                }
                
                
            }catch{
                result.success = false
                result.error = error.localizedDescription
                // Bounce back to the main thread to update the UI
                DispatchQueue.main.async {
                     self.App21Result(result: result)
                }
            }
        }
        
       
        
    }
        
    
    
    
    //MARK: - CLEAR_DOWNLOAD
    @objc func CLEAR_DOWNLOAD(result: Result) -> Void
    {
        DownloadFileTask().clear(param: result.params ?? "",callback: {(ok: String,error: String?) -> Void in
            if(error != nil)
            {
                result.success = false;
                result.error = error;
            }else{
                result.success = true;
            }
            
            self.App21Result(result: result);
        })
       
    }
    
    @objc func GET_NETWORK_TYPE (result: Result) -> Void
    {
        caller.locationCallback = {(loc: CLLocationCoordinate2D?, status: CLAuthorizationStatus? ) in
            if(loc != nil)
            {
                var wifiInfo = WiFiManager.getWiFiInfo()
                result.data = JSON(wifiInfo)
               
                if  wifiInfo.isEmpty {
                    result.data = "NO WIFI"
                    result.success = true
                } else {
                    result.success = true
                    result.data = JSON(wifiInfo)
                    print("RESULT WIFI: \(String(describing: result.data))")
                }
                self.App21Result(result: result);
            
            } else {
                if(status == .restricted || status == .denied){
                    result.success = true
                    result.data = "It looks like you've declined location permission. Please grant permission in App Settings to use this feature."
                    self.App21Result(result: result);
                }
            }
           
        }
        caller.requestLoction()
    }
    
    

    //MARK: - GET_DOWNLOADED
    @objc func GET_DOWNLOADED(result: Result) -> Void
    {
        result.data = JSON(DownloadFileTask().getlist());
        result.success = true;
        App21Result(result: result);
    }
    
    
    //MARK: - DELETE_FILE (result.result = 1 file)
    @objc func DELETE_FILE(result: Result) -> Void
    {
        let mess = DownloadFileTask().deletePath(path: result.params!)
        result.success = mess == "" ?  true : false;
        if(mess != "")
        {
            result.error = mess;
        }
        App21Result(result: result);
        
    }
    
    
    //MARK: - POST_TO_SERVER
    @objc func POST_TO_SERVER(result: Result) -> Void
    {
        let p = PostFileToServer();
        p.app21 = self;
        p.execute(result: result);
    }
    
    //MARK: - IMAGE_ROTATE
    @objc func IMAGE_ROTATE(result: Result) -> Void
    {
        let iu = ImageUtil();
        iu.app21 = self;
        iu.execute(result: result);
    }
    
    func paramsToDic(params: String?) -> [String:String]
    {
        var d = [String:String]();
        if(params != nil)
        {
            for seg in (params?.split(separator: ","))!
            {
                let arr = seg.split(separator: ":")
                d[String(describing: arr[0])] = arr.count > 1 ? String(describing: arr[1]) : "";
            }
        }
        return d;
    }
    
    func reject(result: Result, resson: String)
    {
        NSLog(resson)
        result.success = false;
        result.error = resson
        App21Result(result: result)
    }
    //MARK: - _PERMISSION
    //permission:camera, video, photoLibrary
    func _PERMISSION(permission: PermissionName,result: Result, ok:  @escaping(_ mess: String)->Void )
    {
        switch(permission){
        case .camera,.photoLibrary,.video:
            let status = PHPhotoLibrary.authorizationStatus()
            switch status {
            case .authorized:
                //ok
                NSLog("authorized")
                ok("authorized");
                break;
            case .notDetermined:
                PHPhotoLibrary.requestAuthorization({ (status) in
                    if status == PHAuthorizationStatus.authorized{
                        // photo library access given
                        
                        ok("access_given");
                    }else{
                        self.reject(result: result, resson: "restriced_manually")
                    }
                })
            case .denied:
                
                self.reject(result: result, resson: "permission_denied")
                
                break
            case .restricted:
               
                self.reject(result: result, resson: "permission_restricted")
                
                break
            default:
                break
            }
        }
    }
    
    //MARK: - SET_BADGE
        @objc func SET_BADGE(result: Result) -> Void
        {
            DispatchQueue.main.async {
                UIApplication.shared.applicationIconBadgeNumber -= 1
            }
            
        }
    
    //MARK: - REMOVE_BADGE
    @objc func REMOVE_BADGE(result: Result) -> Void
    {
        DispatchQueue.main.async {
                UIApplication.shared.applicationIconBadgeNumber = 0
        }
    }
    
    //MARK: - GET_LOCATION
        @objc func GET_LOCATION(result: Result) -> Void
        {
            caller.locationCallback = {(loc: CLLocationCoordinate2D?, status: CLAuthorizationStatus? ) in
                if(loc != nil)
                {
                    let d: [String: Double] = [
                        "latitude": loc!.latitude,
                        "longitude": loc!.longitude
                    ]
                    
                    result.data = JSON(d)
                    result.success = true
                } else {
                    result.success = false
                    result.data = ""
                    result.error = "Vui lòng bật định vị"
                }
                self.App21Result(result: result);
            }
            caller.requestLoction()
        }

    //MARK: - OPEN_QRCODE
    @objc func OPEN_QRCODE(result: Result) -> Void
    {
        self.caller.qrCodeResult = result
        DispatchQueue.main.async {
            self.caller.show(self.caller.storyboard!.instantiateViewController(withIdentifier: "QrCodeController"), sender: self)
            
        }
    }
    
    
    enum PermissionName: String{
        case camera, video, photoLibrary
    }
    
    
    //MARK: - NOTI
    @objc func NOTI(result: Result) -> Void
    {
        do{
            let decoder = JSONDecoder()
            let noti21 = try decoder.decode(Noti21.self, from: result.params!.data(using: .utf8)!)
            let svn = SERVER_NOTI();
            svn.app21 = self;
            svn.noti(noti21: noti21)
            result.success = true
        }
        catch{
            result.success = false
            result.error = error.localizedDescription
            
        }
        self.App21Result(result: result)
        
    }
    
    
    //MARK: - NOTI_DATA
    @objc func NOTI_DATA(result: Result) -> Void
    {
        do{
            if(result.params != nil){
                let decoder = JSONDecoder()
                let params = try decoder.decode(NOTI_DATA_PARAMS.self, from: result.params!.data(using: .utf8)!)
                if(params.reset == true)
                {
                    UserDefaults.standard.removeObject(forKey: "NotifedData");
                    result.data = JSON("reseted")
                }
                result.success = true
            }
            else{
                let data =  UserDefaults.standard.dictionary(forKey: "NotifedData");
                var d = [String:String]()
                if(data != nil){
                    for (k,v) in data!{
                        
                        let a = k
                        if let b = v as? String {
                            d[a] = b
                        }
                        else {
                            // nothing to do
                        }
                    }
                }
                result.data = JSON(d);
                result.success = true
            }
            
        }
        catch{
            result.error = error.localizedDescription;
            result.success = false
        }
        App21Result(result: result)
        
    }
    
    
    
    
    //MARK: - GET_SERVER_NOTI
    @objc func GET_SERVER_NOTI(result: Result) -> Void{
        SERVER_NOTI().run(result: result, callback: { (_ error: Error?) in
            result.success = error == nil
            if(error != nil)
            {
                result.error = error?.localizedDescription
            }
            self.App21Result(result: result)
        })
    }
    
    
    //MARK: - VIBRATOR
    @objc func VIBRATOR(result: Result) -> Void{
        AudioServicesPlayAlertSoundWithCompletion(SystemSoundID(kSystemSoundID_Vibrate)) { }
        result.success = true;
        App21Result(result: result)
    }
    
    
    //MARK: - SEND_SMS
    @objc func SEND_SMS(result: Result) -> Void{
        
        result.success = false;
        result.error = "NO_SUPPORT";
        App21Result(result: result)
    }
    
    
    //MARK: - GET_PHONE
    @objc func GET_PHONE(result: Result) -> Void{
        result.success = false;
        result.error = "NO_SUPPORT";
        App21Result(result: result)
    }
    
    
    //MARK: - ALARM_NOTI
    @objc func ALARM_NOTI(result: Result) -> Void{
        
        // Fetch data once an hour.
        // UIApplication.shared.setMinimumBackgroundFetchInterval(3600)
        
        let parser = JSON.parse(SERVER_NOTI_Config.self, from: result.params!);
        
        if(parser.0 != nil)
        {
            UserDefaults.standard.set(result.params, forKey: SERVER_NOTI.BackgroundFetchConfig)
        }
        result.success = parser.1 == nil;
        result.error = parser.1;
        App21Result(result: result)
    }
    
    
    //MARK: - BROWSER
    @objc func BROWSER(result: Result) -> Void{
        
        if(result.params != "" && result.params != nil)
        {
            caller.open_link(url: result.params!)
        }
        
        App21Result(result: result)
    }
    
    //MARK: - MOTION_SHAKE
    @objc func MOTION_SHAKE(result: Result) -> Void{
        
        DispatchQueue.main.async(execute: {
            self.caller.isMotionShake = true
            self.caller.becomeFirstResponder() // To get shake gesture
            self.caller.motionShakeCallback = {(_ motion: UIEvent.EventSubtype, event: UIEvent?)  in
                self.caller.isMotionShake = false
                result.data = JSON(motion.rawValue)
                self.App21Result(result: result)
            }
        })
        
        
    }
    
    
    //MARK: - WV_VISIBLE
    @objc func WV_VISIBLE(result: Result) -> Void
    {
        DispatchQueue.main.async(execute: {
            result.success = true;
            self.caller.wv.isHidden = result.params == "0";
            self.App21Result(result: result)
        })
    }
    
    
    //MARK: - GET_TEXT
    @objc func GET_TEXT(result: Result) -> Void
    {
        result.success = true
        let d = DownloadFileTask();
        
        let text = d.GET_TEXT(path: result.params!);
        result.data = JSON(text);
        
        App21Result(result: result);
       
    }
    
    //MARK: - GET_INFO
    @objc func GET_INFO(result: Result) -> Void
    {
        result.success = true
        
        var info = "IOS";
        info += ",deviceId:" + UIDevice.current.identifierForVendor!.uuidString
        info += ",systemName:" + UIDevice.current.systemName
        info += ",systemVersion:" + UIDevice.current.systemVersion
        info += ",localizedModel:" + UIDevice.current.localizedModel
        info += ",model:" + UIDevice.current.model
        info += ",name:" + UIDevice.current.name
        result.data = JSON(info);
        
        App21Result(result: result);
       
    }
    
    static func OS_INFO() -> String {
        var   info = "IOS";
        info += ",systemName:" + UIDevice.current.systemName
        info += ",systemVersion:" + UIDevice.current.systemVersion
        info += ",localizedModel:" + UIDevice.current.localizedModel
        info += ",model:" + UIDevice.current.model
        return info
    }
    
    //MARK: - TEL
    @objc func TEL(result: Result) -> Void
    {
        result.success = true
        let number = result.params
        let _url = "tel://" + number!
        if let url = URL(string: _url) {
            DispatchQueue.main.async(execute: {
                UIApplication.shared.open(url)
            })
            
        }
        App21Result(result: result);
    }
    //MARK: - SHARE_OPEN
    @objc func SHARE_OPEN(result: Result) -> Void
    {
        result.success = true
        
        let _url = result.params!
        if let url = URL(string: _url) {
            DispatchQueue.main.async(execute: {
                UIApplication.shared.open(url)
            })
            
        }
        App21Result(result: result);
        
    }
    
    //19/03/2022 hung
    //MARK: - KEY
    @objc func KEY(result: Result) -> Void
    {
        let data = (result.params?.data(using: .utf8))

        if data != nil {
            if let json = try? JSON(data: data!){
                let key = json["key"].stringValue
                if json["value"].exists(){
                    let value = json["value"].stringValue
                    let defaults = UserDefaults.standard
                    defaults.set(value, forKey: key)
                }else{
                    let defaults = UserDefaults.standard
                    let v = defaults.string(forKey: key)
                    if v != nil {
                        result.data = JSON(v!)
                    }

                    result.success = true
                }
            }
        }



        //let jo = try? JSONSerialization.jsonObject(with: data, options: [])

        App21Result(result: result);

    }
    
}



//MARK: - class:Result
class Result : NSObject {
    var success = true
    var data: JSON? = nil
    var error: String? = ""
    
    var sub_cmd: String? = ""
    var sub_cmd_id: Int = 0
    var params: String? = ""
    
    enum CodingKeys:String, CodingKey {
        case success
        case data
        case error
        case sub_cmd
        case sub_cmd_id
        case params
    }
}
extension Result: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(success, forKey: .success)
        try container.encode(error, forKey: .error)
        if(data != nil)
        {
           
           try container.encode(data, forKey: .data)
           
        }
        try container.encode(sub_cmd, forKey: .sub_cmd)
        try container.encode(params, forKey: .params)
        try container.encode(sub_cmd_id, forKey: .sub_cmd_id)
    }
}


extension String {
//: ### Base64 encoding a string
    func base64Encoded() -> String? {
    
        if let data = self.data(using: .utf8) {
            return data.base64EncodedString()
        }
        return nil
    }

//: ### Base64 decoding a string
    func base64Decoded() -> String? {
        if let data = Data(base64Encoded: self) {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
}
enum Error21 : Error {
   case runtimeError(String)
}

class Base64Require : Codable{
    var path: String?;
    var callback: String?;
}

class NOTI_DATA_PARAMS : Codable
{
    var reset: Bool? = false
}
