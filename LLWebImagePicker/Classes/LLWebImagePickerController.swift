//
//  LLWebImagePickerController.swift
//  LLWebImagePicker
//
//  Created by Ruris on 2024/5/11.
//

import UIKit
import WebKit

public protocol LLWebImagePickerControllerDelegate: AnyObject {
    
    /// 获取图片回调
    /// - Parameters:
    ///   - controller: LLWebImagePickerController
    ///   - image: UIImage
    func picker(_ controller: LLWebImagePickerController, didFinish image: UIImage)
    
    /// 报错信息回调
    /// - Parameters:
    ///   - controller: LLWebImagePickerController
    ///   - error: Error
    func picker(_ controller: LLWebImagePickerController, didFail error: Error)
}

public class LLWebImagePickerController: UIViewController {
    
    /// Delegate
    public weak var delegate: LLWebImagePickerControllerDelegate?
    
    /// 关键字
    public var keywords: String = "" {
        didSet {
            /// URL Encode
            guard let q = keywords.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else { return }
            if let url = URL(string: "https://bing.com/images/search?q=" + q) {
                self.url = url
            }
        }
    }
    
    public var url: URL = URL(string: "https://bing.com/images/search")! {
        didSet {
            goHome()
        }
    }
    
    /// WebView
    private lazy var webView: WKWebView = {
        let config = WKWebViewConfiguration()
        config.userContentController.add(self, name: "imageClicked")
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        return webView
    }()
    
    /// 后退按钮
    private var backwardItem: UIBarButtonItem?
    
    /// 前进按钮
    private var forwardItem: UIBarButtonItem?
    
    // MARK: -
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupToolBarItems()
        goHome()
    }
    
    // MARK: - UI
    
    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        webView.frame = view.bounds
    }
    
    private func setupUI() {
        view.addSubview(webView)
    }
    
    /// 初始化 ToolBar
    private func setupToolBarItems() {
        let backward = UIBarButtonItem(image: UIImage(systemName: "chevron.backward"), style: .done, target: self, action: #selector(goBackward))
        
        let forward = UIBarButtonItem(image: UIImage(systemName: "chevron.forward"), style: .done, target: self, action: #selector(goForward))
        
        let reload = UIBarButtonItem(image: UIImage(systemName: "arrow.clockwise"), style: .done, target: self, action: #selector(goReload))
        
        let home = UIBarButtonItem(image: UIImage(systemName: "house.fill"), style: .done,  target: self, action: #selector(goHome))
        
        let flexibleSpace = UIBarButtonItem(systemItem: .flexibleSpace)
        let space = UIBarButtonItem.fixedSpace(30)
        
        toolbarItems = [
            backward, space, forward, flexibleSpace, reload, space, home
        ]
        
        updateItemEnables()
        navigationController?.setToolbarHidden(false, animated: false)
    }
    
    /// 更新 ToolBar Item 状态
    private func updateItemEnables() {
        backwardItem?.isEnabled = webView.canGoBack
        forwardItem?.isEnabled = webView.canGoForward
    }
    
    // MARK: - Actions
    
    @objc private func goBackward() {
        updateItemEnables()
        webView.goBack()
    }
    
    @objc private func goForward() {
        updateItemEnables()
        webView.goForward()
    }
    
    @objc private func goHome() {
        updateItemEnables()
//        guard let url = URL(string: "https://bing.com/images/search?q=%E5%A4%AA%E8%8D%92%E5%90%9E%E5%A4%A9%E8%AF%80") else {
//            return
//        }
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    @objc private func goReload() {
        updateItemEnables()
        webView.reloadFromOrigin()
    }
}

extension LLWebImagePickerController: WKScriptMessageHandler {
    
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "imageClicked" else { return }
        guard let imageUrl = message.body as? String else { return }
        // 在这里可以获取到用户点击的图片 URL，可以根据情况进行处理
        if imageUrl.hasPrefix("data:image") {
            do {
                guard let base64 = (imageUrl as NSString).components(separatedBy: "base64,").last else {
                    throw "未获取到图片的 base64 数据" as LLWebImageError
                }
                guard let data = Data(base64Encoded: String(base64)) else {
                    throw "图片 Base64 数据转码出错" as LLWebImageError
                }
                guard let image = UIImage(data: data) else {
                    throw "使用 Base64 数据初始化 UIImage 失败" as LLWebImageError
                }
                delegate?.picker(self, didFinish: image)
            } catch {
                delegate?.picker(self, didFail: error)
            }
        } else if imageUrl.hasPrefix("http") {
            // 处理 http URL
            Task {
                do {
                    guard let url = URL(string: imageUrl) else {
                        throw "URL 初始化失败" as LLWebImageError
                    }
                    let data = try Data(contentsOf: url)
                    guard let image = UIImage(data: data) else {
                        throw "从 URL 下载的 Data 初始化 UIImage 失败" as LLWebImageError
                    }
                    DispatchQueue.main.async {
                        self.delegate?.picker(self, didFinish: image)
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.delegate?.picker(self, didFail: error)
                    }
                }
            }
        } else {
            delegate?.picker(self, didFail: "未考虑图片 URL 格式" as LLWebImageError)
        }
    }
}

extension LLWebImagePickerController: WKUIDelegate {
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let js = """
        var imgs = document.getElementsByTagName('img');
        for (var i = 0; i < imgs.length; i++) {
            imgs[i].onclick = function() {
                window.webkit.messageHandlers.imageClicked.postMessage(this.src);
            }
        }
        """
        webView.evaluateJavaScript(js, completionHandler: nil)
    }
}

extension LLWebImagePickerController: WKNavigationDelegate {
    
//    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
//        decisionHandler(.allow)
//    }
}

