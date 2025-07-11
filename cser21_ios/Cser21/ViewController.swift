//
//  ViewController.swift
//  Cser21 - ezs.vn
//
//  Created by High Sierra on 1/7/20.
//  Copyright © 2020 High Sierra. All rights reserved.
//

import UIKit
import WebKit
import Firebase
import MapKit
import CoreLocation
import AVFoundation
import SystemConfiguration.CaptiveNetwork
import PhotosUI




class ViewController: UIViewController,WKScriptMessageHandler,UIGestureRecognizerDelegate,CLLocationManagerDelegate ,AVAudioRecorderDelegate, WKNavigationDelegate, POSWIFIManagerDelegate,
    PHPickerViewControllerDelegate, UIImagePickerControllerDelegate ,
    UIDocumentPickerDelegate, UINavigationControllerDelegate{
    
    


    let HTML_EMBED = "embed21"
    let domain = "https://cser.vn/";
    
    var qrCodeResult: Result = Result()
    
    var isShowLoading = false
    
    //21/10/2024
    //MARK: POSwifiConnectedToHost
    
    func poSwifiConnected(toHost host: String?, port: UInt16) -> Void
    {
        if(app21 == nil){
            app21 = App21(viewController: self)
        }
        app21?.XPRINT_Connected(host: host, port: Int(port))
    }
    
    func POSwifiConnectedToHost(toHost host: String?, port: UInt16) -> Void
    {
        
    }
    
    private func POSwifiDisconnectWithError(error: String?) -> Void
    {
        if(app21 == nil){
            app21 = App21(viewController: self)
        }
        app21?.XPrint_Error(err: error!)

    }
    //end 21/10/2024
    
    //MARK: - Location
    let locationManager = CLLocationManager()
    var locationCallback : ((CLLocationCoordinate2D?,  CLAuthorizationStatus?) -> Void)?
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else {
            locationCallback?(nil,nil)
            return

        }
        print("locations = \(locValue.latitude) \(locValue.longitude)")

        locationCallback?(locValue,nil)
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways {
                        locationManager.delegate = self
                        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
                        locationManager.startUpdatingLocation()
            locationCallback?(manager.location?.coordinate, status)
        } else if status == .authorizedWhenInUse {
                        locationManager.delegate = self
                        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
                        locationManager.startUpdatingLocation()
            locationCallback?(manager.location?.coordinate, status)
        } else {
            locationCallback?(nil, status)
        }
    }

    func checkUsersLocationServicesAuthorization(){
            if CLLocationManager.locationServicesEnabled() {
                switch CLLocationManager.authorizationStatus() {
                case .notDetermined:
                    // Request when-in-use authorization initially
                    // This is the first and the ONLY time you will be able to ask the user for permission
                    self.locationManager.delegate = self
                    locationManager.requestWhenInUseAuthorization()
                    break
                    

                case .restricted, .denied:
                    locationCallback?(nil,CLLocationManager.authorizationStatus())
                    print("not access")
                    break

                case .authorizedWhenInUse, .authorizedAlways:
                    locationManager.delegate = self
                    locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
                    locationManager.startUpdatingLocation()
                    break
                }
            }
        }

    func requestLoction() -> Void {
        checkUsersLocationServicesAuthorization()
    }
    
        
    //MARK: - MotionShake
    // Enable detection of shake motion
    var motionShakeCallback : ((UIEvent.EventSubtype,UIEvent?) -> Void)?
    var isMotionShake:Bool = false
    override var canBecomeFirstResponder: Bool {
        get {
            return isMotionShake
        }
    }
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
           // print("Why are you shaking me?")
            if(motionShakeCallback != nil){
                motionShakeCallback!(motion, event)
            }
        }
    }
    
    
    //
    @IBOutlet weak var wv: WKWebView!
    
    
    let mtop = CGFloat(20);
    
    // Preferred status bar style lightContent to use on dark background.
    // Swift 3
    var textStatusBarWhite = false
    override var preferredStatusBarStyle: UIStatusBarStyle {
        
        if #available(iOS 13.0, *) {
            return textStatusBarWhite ? .lightContent : .darkContent
        } else {
            // Fallback on earlier versions
            return textStatusBarWhite ? .lightContent : .default
        }
    }
    
    // MARK: setBackground
    func setBackground(params: String?) -> Void {
        var outset = false
        //
        var p = params
        if(p == nil)
        {
            p = getKey(keyName: "bgColor", value: "")
        }else
        {
            outset = true
        }
        if(p == nil || p == "") {
            return;
        }
        
        let segs = p?.split(separator: ";")
        let _v = String(segs![0]);
        textStatusBarWhite = segs?.count ?? 0 > 1 && segs?[1] == "0"
        let _setKey = segs?.count ?? 0 > 2 && segs?[2] == "1"
        
        if(_setKey && outset)
        {
            setKey(keyName: "bgColor", value: params!)
        }
        
        if(wv != nil)
        {
            var color: UIColor? = nil
            if #available(iOS 11.0, *) {
                 color = _v.hasPrefix("#") ? UIColor(hex: _v) : UIColor(named: _v)
            } else {
                // Fallback on earlier versions
            };
            if(color != nil)
            {
                wv.backgroundColor = color!
                view.backgroundColor = color!
                self.view.backgroundColor = color!
                //let w = UIWindow(frame: UIScreen.main.bounds)
                //w.backgroundColor = color!
                //UIApplication.shared.statusBarUIView?.backgroundColor = color!
                UIApplication.shared.statusBarUIView?.backgroundColor = .clear
            }
        }
        
        setNeedsStatusBarAppearanceUpdate()
        let _ = preferredStatusBarStyle
        setNeedsStatusBarAppearanceUpdate()
        
    }
    
    // MARK: setBackground
    func changeStatusBarColor(params: String?) -> Void {
        if params != nil {
            textStatusBarWhite = true;
        }
        if params == nil {
            textStatusBarWhite = false;
        }
       
        setNeedsStatusBarAppearanceUpdate()
        let _ = preferredStatusBarStyle
        setNeedsStatusBarAppearanceUpdate()
    }
    
    /*
     for event: onTap,onPinch,onRotation,onSwipe,onPan,onEPan,onLongpress
     */
    func StrPoint(Point: CGPoint) -> String
    {
        
        return "{\"x\":" + String(describing: Point.x) + ",\"y\":" + String(describing: Point.y) + "}"
        
    }
    func StrSize() -> String
    {
        let s =  wv.bounds.size
        let statusBarHeight = UIApplication.shared.statusBarFrame.height
        return "{\"width\":" + String(describing: s.width) + ",\"height\":" + String(describing: s.height - statusBarHeight ) + "}"
    }
    func StrGestureState(state: UIGestureRecognizer.State) -> String
    {
        var s:String = ""
        switch state {
        case UIGestureRecognizer.State.ended:
            s = "ended"
        case UIGestureRecognizer.State.cancelled:
            s = "cancelled"
        case UIGestureRecognizer.State.changed:
            s = "changed"
        case UIGestureRecognizer.State.began:
            s = "began"
        case UIGestureRecognizer.State.failed:
            s = "failed"
        case UIGestureRecognizer.State.possible:
            s = "possible"
      
        default:
            s = ""
        }
        return "\"" + s + "\""
    }
    @objc func onTap(g: UITapGestureRecognizer) {
        
        var value:String = "";
        value += "{\"point\":" + StrPoint(Point: g.location(in:  wv)) ;
        value += ",\"size\":" + StrSize();
        value += ",\"state\":" + StrGestureState(state: g.state);
        value += "}";
        JS(cmd: "onTap", value: value )
    }
    @objc func onPinch(g: UIPinchGestureRecognizer) {
        //        var value:String = "";
        //        value += "{\"point\":" + StrPoint(Point: g.location(in: wv)) ;
        //        value += ",\"scale\":" + String(describing: g.scale);
        //        value += ",\"velocity\":" + String(describing: g.velocity);
        //        value += ",\"size\":" + StrSize();
        //        value += ",\"state\":" + StrGestureState(state: g.state);
        //        value += "}";
        //        JS(cmd: "onPinch", value: value)
    }
    @objc func onRotation(g: UIRotationGestureRecognizer) {
        var value:String = "";
        value += "{\"point\":" + StrPoint(Point: g.location(in:  wv)) ;
        value += ",\"rotation\":" + String(describing: g.rotation);
        value += ",\"velocity\":" + String(describing: g.velocity);
        value += ",\"size\":" + StrSize();
        value += ",\"state\":" + StrGestureState(state: g.state);
        value += "}";
        JS(cmd: "onRotation", value: value)
    }
    @objc func onPan(g: UIPanGestureRecognizer) {
        var value:String = "";
        value += "{\"point\":" + StrPoint(Point: g.location(in:  wv)) ;
        value += ",\"translation\":" + StrPoint(Point: g.translation(in:  wv));
        value += ",\"velocity\":" + StrPoint(Point: g.velocity(in:  wv));
        value += ",\"size\":" + StrSize();
        value += ",\"state\":" + StrGestureState(state: g.state);
        value += "}";
        JS(cmd: "onPan", value: value)
    }
    @objc func onEPan(g: UIScreenEdgePanGestureRecognizer) {
        var value:String = "";
        value += "{\"point\":" + StrPoint(Point: g.location(in:  wv)) ;
        value += ",\"translation\":" + StrPoint(Point: g.translation(in:  wv));
        value += ",\"velocity\":" + StrPoint(Point: g.velocity(in:  wv));
        value += ",\"size\":" + StrSize();
        value += ",\"state\":" + StrGestureState(state: g.state);
        value += "}";
        JS(cmd: "onEPan", value: value)
    }
    @objc func onSwipe(g: UISwipeGestureRecognizer) {
        var value:String = "";
        value += "{\"point\":" + StrPoint(Point: g.location(in:  wv)) ;
        value += ",\"direction\":" + String(describing: g.direction.rawValue);
        value += ",\"size\":" + StrSize();
        value += ",\"state\":" + StrGestureState(state: g.state);
        value += "}";
        JS(cmd: "onSwipe", value: value)
    }
    @objc func onLongpress(g: UILongPressGestureRecognizer) {
        var value:String = "";
        value += "{\"point\":" + StrPoint(Point: g.location(in:  wv)) ;
        value += ",\"size\":" + StrSize();
        value += ",\"state\":" + StrGestureState(state: g.state);
        value += "}";
        JS(cmd: "onLongpress", value: value)
    }
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func getKey(keyName: String,value: String) -> String {
        let defaults = UserDefaults.standard
        let v = defaults.string(forKey: keyName)
        
        return v == nil ? value : v!
    }
    func setKey(keyName: String,value: String) -> Void {
        let defaults = UserDefaults.standard
        defaults.set(value, forKey: keyName)
    }
    
    func Subscribe(topics: String) -> Void {
        if(topics.isEmpty)
        {
            return;
        }
        setKey(keyName: "subscribe", value: topics);
        let a1 = topics.components(separatedBy:  ",");
        
        for a in a1 {
            // print("Hello, \(name)!")
            //android: FirebaseMessaging.getInstance().subscribeToTopic(a);
            Messaging.messaging().subscribe(toTopic: a);
        }
    }
    
    func UnSubscribe() -> Void {
        let topics = getKey(keyName: "subscribe", value: "")
        if(topics.isEmpty)
        {
            return;
        }
        let a1 = topics.components(separatedBy:  ",");
        for a in a1 {
            // print("Hello, \(name)!")
            //android: FirebaseMessaging.getInstance().subscribeToTopic(a);
            Messaging.messaging().unsubscribe(fromTopic: a);
        }
        
    }
    func IconBadgeNumber(strNum : String) -> Void {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    //MARK: - reloadStoryboard
    func reloadStoryboard()  {
        //wv.reload()
        loadView();
        viewDidLoad();
    }
    
    //MARK: - evalJs
    func evalJs(str: String)
    {
        wv.evaluateJavaScript(str,completionHandler: nil)
    }
    
    var app21: App21? = nil
    
    //MARK: - Do
    
    func Do(cmd: String,value: Any?)  {
        if(value == nil) { return;}
        let str: String = value as! String
        
        let segs = str.components(separatedBy:  ":")
        
        var key = "" as String
        var va = "" as String
        if(segs.count > 0)
        {
            key = segs[0] as String
        }
        if(segs.count > 1)
        {
            va = segs[1] as String
        }
        
        
        switch cmd {
        case "setkey":
            setKey(keyName: key, value: va)
            break
        case "getkey":
            JS(cmd: cmd, value: getKey(keyName: key, value: va))
            break
        case "subscribe":
            // JS(cmd: cmd, value: getKey(keyName: key, value: va))
            Subscribe(topics: str)
            break
        case "unsubscribe":
            UnSubscribe();
            break
        case "iconbadgenumber":
            IconBadgeNumber(strNum: str);
            break
        case "open_link":
            open_link(url: str);
            break
        //MARK: - case:call
        case "call":
            if(app21 == nil)
            {
                app21 = App21(viewController: self)
            }
            app21!.call(jsonStr: value as! String)
            break
        default:
            break
        }
    }
    
    func open_link(url : String) ->  Void {
        //NSLog(url)
       guard let _url = URL(string: url) else { return }
       UIApplication.shared.open(_url)
    }
    /*
     Nhan thong bao tu web
     */
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        //<#code#>
        let data = message.body as! NSDictionary
        let cmd: String = (data["cmd"] as? String)!
        let value = data["value"]
        Do(cmd: cmd,value: value)
    }
    

    
    func setUpWebView()  {
        
        let webConfiguration = WKWebViewConfiguration();
       
        let frm = CGRect(x:0 , y:0, width: view.bounds.width, height: view.bounds.height)
        //app21: handler file local
        webConfiguration.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        //webConfiguration.setValue(true, forKey: "_allowUniversalAccessFromFileURLs")
        webConfiguration.setURLSchemeHandler(LocalSchemeHandler(), forURLScheme: "local")
        webConfiguration.setURLSchemeHandler(LocalSchemeHandler(), forURLScheme: "js")
        webConfiguration.setURLSchemeHandler(LocalSchemeHandler(), forURLScheme: "app21")
        //
        
        wv = WKWebView(frame: frm, configuration: webConfiguration);
        wv.navigationDelegate = self
        //setBackground(params: nil);
        //view.backgroundColor = bg;
        
        wv.scrollView.contentInsetAdjustmentBehavior = .never
        
        //Javascript
        wv.configuration.userContentController.add(self, name: "IOS")
        wv.scrollView.decelerationRate = UIScrollView.DecelerationRate.normal;
        
        
        
        view.addSubview(wv);
        wv.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    wv.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                    view.trailingAnchor.constraint(equalTo: wv.trailingAnchor),
                    wv.topAnchor.constraint(equalTo: view.topAnchor),
                    view.bottomAnchor.constraint(equalTo: wv.bottomAnchor)
                ])
        wv.backgroundColor = UIColor.white;
  
        
        //CGSize viewSize = self.view.frame.size
        
        //Event
        //#
        let evt_tap = UITapGestureRecognizer(target: self , action: #selector(onTap))
        evt_tap.delegate = self
        evt_tap.numberOfTapsRequired = 1
        wv.addGestureRecognizer(evt_tap)
        //#
        let evt_pinch = UIPinchGestureRecognizer(target: self , action: #selector(onPinch))
        evt_pinch.delegate = self
        wv.addGestureRecognizer(evt_pinch)
        //#
        let evt_Rotation = UIRotationGestureRecognizer(target: self , action: #selector(onRotation))
        evt_Rotation.delegate = self
        wv.addGestureRecognizer(evt_Rotation)
        //#
        let evt_Pan = UIPanGestureRecognizer(target: self , action: #selector(onPan))
        evt_Pan.delegate = self
        wv.addGestureRecognizer(evt_Pan)
        //#
        let evt_Epan = UIScreenEdgePanGestureRecognizer(target: self , action: #selector(onEPan))
        evt_Epan.delegate = self
        wv.addGestureRecognizer(evt_Epan)
        //#
        let evt_Swipe = UISwipeGestureRecognizer(target: self , action: #selector(onSwipe))
        evt_Swipe.delegate = self
        wv.addGestureRecognizer(evt_Swipe)
        //#
        let evt_Longpress = UILongPressGestureRecognizer(target: self , action: #selector(onLongpress))
        evt_Longpress.delegate = self
        wv.addGestureRecognizer(evt_Longpress)
       
        
        //UI
        
        // Do any additional setup after loading the view, typically from a nib.
        
        //DEV OPEN
        
        wv.isUserInteractionEnabled = true;
        wv.scrollView.isScrollEnabled = false;
        wv.scrollView.bounces = false;
        wv.scrollView.showsHorizontalScrollIndicator = false;
        wv.scrollView.showsVerticalScrollIndicator = false;

        let link = URL(string:"http://192.168.100.248:5001/")!
        let request = URLRequest(url: link)
        wv.load(request);
        view.addSubview(wv);
        
        // DEV OPEN
        
        // load embed.html
        // DEV HIDDEN
//        if let path = Bundle.main.path(forResource: HTML_EMBED, ofType: "html"){
//            let fm = FileManager()
//            let exists = fm.fileExists(atPath: path)
//            if(exists){
//                let c = fm.contents(atPath: path)
//                let cString = NSString(data: c!, encoding: String.Encoding.utf8.rawValue)
//
//                let url = URL(string: domain)
//
//                var html:String = "";
//                html +=  cString! as String
//
//
//                if HTML_EMBED == "embed"{
//                    wv.isHidden = false;
//                    wv.loadHTMLString(html, baseURL: url);
//                }else{
//                    wv.isHidden = false;
//                    wv.loadHTMLString(html, baseURL: Bundle.main.resourceURL)
//                }
//                wv.alpha = 1
//            }
//        }
        // DEV HIDDEN
                
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification , object:nil)
        
        NotificationCenter.default.addObserver(self,
        selector: #selector(applicationDidBecomeActive),
        name: UIApplication.didBecomeActiveNotification,
        object: nil)
        
        //
        NotificationCenter.default.addObserver(self,
        selector: #selector(applicationDidEnterBackground),
        name: UIApplication.didEnterBackgroundNotification,
        object: nil)
        
        /*
         * for: NewNotification see in AppDelegate
         */
        NotificationCenter.default.addObserver(self, selector: #selector(onNotificationClick) , name: NSNotification.Name(rawValue: "NotificationClick"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(onQrCode) , name: NSNotification.Name(rawValue: "QRCODE"), object: nil)
    }
    
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        print("Web content process terminated. Reloading...")
        webView.reload()
        self.dismiss(animated: false)
        let secondViewController = self.storyboard?.instantiateViewController(withIdentifier: "Main") as! ViewController
        secondViewController.modalPresentationStyle = .fullScreen
                // Present the view controller modally
                self.present(secondViewController, animated: false, completion: nil)
    }
    
    //MARK: - ScanQrCode
    @objc func onQrCode(notification: Notification)
    {
        guard let qrCode = notification.userInfo?["code"] as? String else {
            return
        }
        qrCodeResult.data = JSON(qrCode)
        qrCodeResult.success = true
        if(app21 == nil)
        {
            app21 = App21(viewController: self)
        }
        app21?.App21Result(result: qrCodeResult)

    }
    
    //MARK: - DidBecomeActive
    @objc func applicationDidBecomeActive()
    {
       
        evalJs(str: "AppResume({\"sourceIOS\":\"BecomeActive\"})")
    }
    
    //MARK: - onNotificationClick
    @objc func onNotificationClick()
    {
        evalJs(str: "AppResume({\"sourceIOS\":\"NotificationClick\"})")
    }
    
    //MARK: - DidEnterBackground
    @objc func applicationDidEnterBackground()
    {
        
        evalJs(str: "AppPause()")
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        let scrollPoint = CGPoint(x: 0, y: wv.scrollView.contentSize.height - wv.frame.size.height)
        wv.scrollView.setContentOffset(scrollPoint, animated: true)//Set false if you doesn't want animation
    }
    
    //MARK: - viewDidLoad, backgroundColor
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        setUpWebView()
        
        UIApplication.shared.statusBarUIView?.backgroundColor = UIColor.white
        UIApplication.shared.statusBarUIView?.isHidden = true
        
        //21/10/2024
        //MARK: 21/10/2024
        if(app21 == nil)
        {
            app21 = App21(viewController: self)
        }
        var ss = app21?.START_SCRIPT(result: Result()) ?? "";
        //ss = "document.body.innerHTML='hihi'"; => test
        wv.evaluateJavaScript(ss)
        //end 21/10/2024
        
                
//        UIApplication.shared.statusBarUIView?.backgroundColor = UIColor.white
    }
         
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    fileprivate func printReceivedParmas(_ data: AnyObject) {
        //print("Swift recieved data passed from JS: \(data)")
    }
    
    func JS(cmd: String, value: String){
        wv.evaluateJavaScript("app_response('\(cmd)','\(value)',true)",completionHandler: nil)
    }
    
    func shareImages(images: [String], text: String, completeShare:@escaping ()->Void) {
        showLoading(text: "Please wait...")
        downloadImagesFromNetwork(imageUrls: images) { uiImages in
            self.hideLoading(completion:  {
                var items = []
                items.append(text)
                for img in uiImages {
                    items.append(img)
                }
                let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: [])
                    activityViewController.popoverPresentationController?.sourceView = self.view
                if #available(iOS 13.0, *) {
                    activityViewController.isModalInPresentation = true
                }
                activityViewController.completionWithItemsHandler = { (activityType: UIActivity.ActivityType?, completed: Bool, returnedItems: [Any]?, error: Error?) -> Void in
                    if completed == true {
                        completeShare()
                    }
                }
                   self.present(activityViewController, animated: true, completion: nil)
                
            })
        }
    }
    
    func presentMultiImagePicker(isMulti : Bool ,completion: @escaping ([URL]) -> Void) {
        if #available(iOS 14.0, *), isMulti {
            var configuration = PHPickerConfiguration()
            configuration.selectionLimit =  0
            configuration.filter = .images
            let picker = PHPickerViewController(configuration: configuration)
            picker.delegate = self
            self.completionPickImageHandler = completion
            present(picker, animated: true, completion: nil)
        } else {
            let imagePicker = UIImagePickerController()
            imagePicker.sourceType = .photoLibrary
            imagePicker.allowsEditing = false
            imagePicker.delegate = self
            self.completionPickImageHandler = completion
            present(imagePicker, animated: true, completion: nil)
        }
              
    }
    
    private var completionPickImageHandler: (([URL]) -> Void)?
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            picker.dismiss(animated: true, completion: nil)

            if let selectedImage = info[.imageURL] as? URL {
               print(selectedImage)
                self.completionPickImageHandler?([selectedImage])
            }
        }
    
    @available(iOS 14.0, *)
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true, completion: nil)
        let dispatchGroup = DispatchGroup()
        var imageUrls: [URL] = []
        
        for result in results {
            if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                dispatchGroup.enter()
                result.itemProvider.loadObject(ofClass: UIImage.self) { (object, error) in
                    defer { dispatchGroup.leave() }
                    
                    if let error = error {
                        print("Error loading image: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let image = object as? UIImage else {
                        print("Loaded object is not UIImage")
                        return
                    }
                    
                    // Sửa orientation
                    let fixedImage = image.fixedOrientation()
                    
                    // Ghi vào file tạm trong Document directory
                    if let imageData = fixedImage.jpegData(compressionQuality: 1.0) {
                        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                        let fileName = UUID().uuidString + ".jpg"
                        let destinationURL = documentsDirectory.appendingPathComponent(fileName)
                        
                        do {
                            try imageData.write(to: destinationURL)
                            imageUrls.append(destinationURL)
                            print("Saved image to: \(destinationURL)")
                        } catch {
                            print("Error saving image: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            self.completionPickImageHandler?(imageUrls)
        }
    }

    
    func presentDocumentPicker(isMultiple: Bool, completion: @escaping ([URL]) -> Void) {
        self.completionPickImageHandler = completion
        if #available(iOS 14.0, *) {
            let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.item], asCopy: true)
            documentPicker.allowsMultipleSelection = isMultiple
            documentPicker.delegate = self
            present(documentPicker, animated: true, completion: nil)
        } else {
            
            let documentPicker = UIDocumentPickerViewController(documentTypes: ["public.data", "public.content"], in: .import)
            documentPicker.allowsMultipleSelection = isMultiple
            documentPicker.delegate = self
            present(documentPicker, animated: true, completion: nil)
        }
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        self.completionPickImageHandler?(urls)
    }
    
    private func downloadImagesFromNetwork(imageUrls: [String],completion: @escaping ([UIImage]) -> Void) {
       var images: [UIImage] = []
          let dispatchGroup = DispatchGroup()
        
          for url in imageUrls {
              guard let imageUrl = URL(string: url) else { continue }
              
              dispatchGroup.enter() // Bắt đầu theo dõi tải xuống hình ảnh

              URLSession.shared.dataTask(with: imageUrl) { data, response, error in
                  defer {
                      dispatchGroup.leave() // Kết thúc theo dõi khi hoàn thành việc tải xuống hình ảnh
                  }

                  // Xử lý lỗi
                  if let error = error {
                      print("Error downloading image: \(error)")
                      return
                  }

                  // Kiểm tra dữ liệu hình ảnh
                  guard let data = data, let image = UIImage(data: data) else {
                      print("Invalid image data")
                      return
                  }
                  images.append(image) // Thêm hình ảnh vào mảng
              }.resume()
          }

          // Thực hiện closure khi tất cả các tác vụ trong DispatchGroup đã hoàn thành
          dispatchGroup.notify(queue: .main) {
              completion(images)
          }
              
       
    }
    
    private func showLoading(text: String){
        if(isShowLoading) {
            return;
        }
        let alert = UIAlertController(title: nil, message: text, preferredStyle: .alert)
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = UIActivityIndicatorView.Style.gray
        loadingIndicator.startAnimating();

        alert.view.addSubview(loadingIndicator)
        present(alert, animated: true, completion: nil)
        isShowLoading = true;
    }
    
    private func hideLoading(completion: @escaping () -> Void){
        if(isShowLoading){
            self.dismiss(animated: false, completion:{
                completion()
                
           } )
            isShowLoading = false;
        }
    }
    
}
extension ViewController: UIWebViewDelegate
{
    //for os10
    internal func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebView.NavigationType) -> Bool {
        //webView.stringByEvaluatingJavaScriptFromString("something = 42")
        let str = String(describing: request)
        let arr = str.components(separatedBy:"?")
        if(arr.count == 2)
        {
            if(arr[0].starts(with: "js://"))
            {
                let a = arr[1].components(separatedBy: "&")
                
                var cmd:String = ""
                var value:String = ""
                for row in a {
                    let pairs = row.components(separatedBy:"=")
                    if(pairs.count == 2)
                    {
                        if(pairs[0] == "cmd") {
                            cmd = pairs[1]
                        }
                        if(pairs[0] == "value") {
                            value = pairs[1]
                        }
                    }
                }
                if(cmd != "")
                {
                    Do(cmd: cmd, value: value)
                }
                return false
            }
        }
        return true
    }
    
    
    
}

extension UIColor{
    convenience  init(colorWithHaxValue value: Int, alpha:CGFloat = 1.0) {
        self.init(
            red: CGFloat((value & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((value & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat((value & 0x0000FF)) / 255.0,
            alpha: alpha
        )
    }
    convenience init?(hex: String) {
        let r, g, b, a: CGFloat

        if hex.hasPrefix("#") {
            let start = hex.index(hex.startIndex, offsetBy: 1)
            let hexColor = String(hex[start...])

            if hexColor.count == 6 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0

                if scanner.scanHexInt64(&hexNumber) {
                    r = CGFloat((hexNumber & 0xff0000) >> 16) / 255
                    g = CGFloat((hexNumber & 0x00ff00) >> 8) / 255
                    b = CGFloat((hexNumber & 0x0000ff)) / 255
                    a = 1// CGFloat(hexNumber & 0x000000ff) / 255

                    self.init(red: r, green: g, blue: b, alpha: a)
                    return
                }
            }
        }

        return nil
    }
}

//extension UIApplication {
//    var statusBarView: UIView? {
//        if responds(to: Selector("statusBar")) {
//            return value(forKey: "statusBar") as? UIView
//        }
//        return nil
//    }
//}

extension UIApplication {
var statusBarUIView: UIView? {

    if #available(iOS 13.0, *) {
        let tag = 3848245

        let keyWindow = UIApplication.shared.connectedScenes
            .map({$0 as? UIWindowScene})
            .compactMap({$0})
            .first?.windows.first

        if let statusBar = keyWindow?.viewWithTag(tag) {
            return statusBar
        } else {
            let height = keyWindow?.windowScene?.statusBarManager?.statusBarFrame ?? .zero
            let statusBarView = UIView(frame: height)
            statusBarView.tag = tag
            statusBarView.layer.zPosition = 999999

            keyWindow?.addSubview(statusBarView)
            return statusBarView
        }

    } else {

        if responds(to: Selector(("statusBar"))) {
            return value(forKey: "statusBar") as? UIView
        }
    }
    return nil
  }
}

extension UIImage {
    func fixedOrientation() -> UIImage {
        if imageOrientation == .up {
            return self
        }

        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return normalizedImage ?? self
    }
}


