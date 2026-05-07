//
//  PreviewViewController.swift
//  HWPQuickLookPreview
//
//  Created by ny64 on 5/6/26.
//

import Cocoa
import Quartz
import WebKit

class PreviewViewController: NSViewController, QLPreviewingController, WKNavigationDelegate, WKScriptMessageHandler {

    private static let resourceScheme = "hwp-preview"

    private struct PreviewDocument {
        let fileName: String
        let fileExtension: String
        let size: Int
        let base64: String
    }

    private var webView: WKWebView!
    private let resourceSchemeHandler = PreviewResourceSchemeHandler()
    private var isViewerLoaded = false
    private var isRendererBootstrapped = false
    private var bootstrapAttempts = 0
    private var pendingDocument: PreviewDocument?

    override var preferredContentSize: NSSize {
        get {
            NSSize(width: 595, height: 842)
        }
        set {
            super.preferredContentSize = newValue
        }
    }

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 595, height: 842))
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.textBackgroundColor.cgColor

        let userContentController = WKUserContentController()
        userContentController.add(self, name: "hwpPreviewLog")

        let configuration = WKWebViewConfiguration()
        configuration.userContentController = userContentController
        configuration.setURLSchemeHandler(resourceSchemeHandler, forURLScheme: Self.resourceScheme)
        configuration.suppressesIncrementalRendering = false

        webView = PreviewWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)

        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        loadViewer()
    }

    /*
    func preparePreviewOfSearchableItem(identifier: String, queryString: String?) async throws {
        // Implement this method and set QLSupportsSearchableItems to YES in the Info.plist of the extension if you support CoreSpotlight.

        // Perform any setup necessary in order to prepare the view.
        // Quick Look will display a loading spinner until this returns.
    }
    */

    func preparePreviewOfFile(at url: URL) async throws {
        let data = try Data(contentsOf: url, options: [.mappedIfSafe])
        let document = PreviewDocument(
            fileName: url.lastPathComponent,
            fileExtension: url.pathExtension.lowercased(),
            size: data.count,
            base64: data.base64EncodedString()
        )

        pendingDocument = document
        renderPendingDocumentIfPossible()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        isViewerLoaded = true
        bootstrapRendererWhenScriptIsReady()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        showError("HWP viewer load failed: \(error.localizedDescription)")
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        showError("HWP viewer load failed: \(error.localizedDescription)")
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        isViewerLoaded = false
        isRendererBootstrapped = false
        bootstrapAttempts = 0
        showFallbackError("WebContent process terminated. Quick Look/WebKit sandbox가 렌더러 프로세스를 종료했습니다.")
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "hwpPreviewLog" else { return }

        if let payload = message.body as? [String: Any],
           let level = payload["level"] as? String,
           level == "error" {
            let text = payload["message"] as? String ?? "Unknown JavaScript error"
            showFallbackError("JavaScript error: \(text)")
        }
    }

    private func loadViewer() {
        guard bundledResourceURL(named: "viewer", extension: "html") != nil,
              let viewerURL = URL(string: "\(Self.resourceScheme)://bundle/viewer.html") else {
            webView.loadHTMLString("<p>viewer.html 리소스를 찾을 수 없습니다.</p>", baseURL: nil)
            return
        }

        webView.load(URLRequest(url: viewerURL))
    }

    private func bootstrapRendererWhenScriptIsReady() {
        guard isViewerLoaded, !isRendererBootstrapped else {
            return
        }

        webView.evaluateJavaScript("typeof window.bootstrapRhwp === 'function'") { [weak self] result, error in
            guard let self else { return }

            if let error {
                self.showFallbackError("HWP viewer script check failed: \(error.localizedDescription)")
                return
            }

            if result as? Bool == true {
                self.bootstrapRenderer()
                return
            }

            self.bootstrapAttempts += 1
            guard self.bootstrapAttempts < 20 else {
                self.showFallbackError("HWP viewer script did not finish loading. viewer.js 또는 rhwp.js 로드에 실패했습니다.")
                return
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.bootstrapRendererWhenScriptIsReady()
            }
        }
    }

    private func bootstrapRenderer() {
        guard let wasmURL = bundledResourceURL(named: "rhwp_bg", extension: "wasm") else {
            showError("rhwp_bg.wasm 리소스를 찾을 수 없습니다.")
            return
        }

        do {
            let wasmData = try Data(contentsOf: wasmURL)
            evaluateJavaScript(functionName: "window.bootstrapRhwp", payload: [
                "wasmBase64": wasmData.base64EncodedString()
            ]) { [weak self] error in
                guard let self else { return }

                if let error {
                    self.showFallbackError("rhwp WASM bootstrap failed: \(error.localizedDescription)")
                    return
                }

                self.isRendererBootstrapped = true
                self.renderPendingDocumentIfPossible()
            }
        } catch {
            showError("rhwp_bg.wasm을 읽을 수 없습니다: \(error.localizedDescription)")
        }
    }

    private func renderPendingDocumentIfPossible() {
        guard isViewerLoaded, isRendererBootstrapped, let document = pendingDocument else {
            return
        }

        evaluateJavaScript(functionName: "window.renderHWPPreview", payload: [
            "fileName": document.fileName,
            "fileExtension": document.fileExtension,
            "size": document.size,
            "base64": document.base64
        ]) { [weak self] error in
            if let error {
                self?.showFallbackError("HWP render call failed: \(error.localizedDescription)")
            }
        }
        pendingDocument = nil
    }

    private func showError(_ message: String) {
        evaluateJavaScript(functionName: "window.showHWPPreviewError", payload: ["message": message])
    }

    private func showFallbackError(_ message: String) {
        let escapedMessage = message
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "`", with: "\\`")

        webView.evaluateJavaScript(
            """
            document.getElementById('status')?.replaceChildren();
            document.getElementById('viewer')?.replaceChildren(Object.assign(document.createElement('section'), { className: 'error', textContent: `\(escapedMessage)` }));
            """
        )
    }

    private func evaluateJavaScript(functionName: String, payload: Any, completion: ((Error?) -> Void)? = nil) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: payload)
            guard let json = String(data: jsonData, encoding: .utf8) else {
                completion?(nil)
                return
            }

            webView.evaluateJavaScript("void \(functionName)(\(json));") { _, error in
                completion?(error)
            }
        } catch {
            completion?(error)
            showFallbackError("JavaScript payload serialization failed: \(error.localizedDescription)")
        }
    }

    private func bundledResourceURL(named name: String, extension fileExtension: String) -> URL? {
        Bundle.main.url(forResource: name, withExtension: fileExtension, subdirectory: "Web")
            ?? Bundle.main.url(forResource: name, withExtension: fileExtension)
    }

}

private final class PreviewWebView: WKWebView {
    override var acceptsFirstResponder: Bool { false }
}

private final class PreviewResourceSchemeHandler: NSObject, WKURLSchemeHandler {
    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url else {
            urlSchemeTask.didFailWithError(PreviewResourceError.invalidURL)
            return
        }

        let resourceName = url.lastPathComponent
        let resourceURL = bundledResourceURL(for: resourceName)

        guard let resourceURL else {
            urlSchemeTask.didFailWithError(PreviewResourceError.notFound(resourceName))
            return
        }

        do {
            let data = try Data(contentsOf: resourceURL)
            let response = URLResponse(
                url: url,
                mimeType: mimeType(for: resourceURL.pathExtension),
                expectedContentLength: data.count,
                textEncodingName: resourceURL.pathExtension.lowercased() == "html" ? "utf-8" : nil
            )
            urlSchemeTask.didReceive(response)
            urlSchemeTask.didReceive(data)
            urlSchemeTask.didFinish()
        } catch {
            urlSchemeTask.didFailWithError(error)
        }
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {}

    private func bundledResourceURL(for resourceName: String) -> URL? {
        let url = URL(fileURLWithPath: resourceName)
        let fileName = url.deletingPathExtension().lastPathComponent
        let fileExtension = url.pathExtension

        return Bundle.main.url(forResource: fileName, withExtension: fileExtension, subdirectory: "Web")
            ?? Bundle.main.url(forResource: fileName, withExtension: fileExtension)
    }

    private func mimeType(for fileExtension: String) -> String {
        switch fileExtension.lowercased() {
        case "css":
            return "text/css"
        case "html":
            return "text/html"
        case "js", "mjs":
            return "text/javascript"
        case "wasm":
            return "application/wasm"
        default:
            return "application/octet-stream"
        }
    }
}

private enum PreviewResourceError: LocalizedError {
    case invalidURL
    case notFound(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid preview resource URL."
        case .notFound(let resourceName):
            return "Preview resource not found: \(resourceName)"
        }
    }
}
