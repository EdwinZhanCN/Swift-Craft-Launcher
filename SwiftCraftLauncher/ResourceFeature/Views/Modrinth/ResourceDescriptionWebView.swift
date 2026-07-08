//
//  ResourceDescriptionWebView.swift
//  ResourceFeature
//
//  © 2025-2026 Swift Craft Launcher Team. All rights reserved.
//

import SwiftUI
import WebKit

enum ResourceDescriptionContentFormat {
    case markdown
    case html
}

struct ResourceDescriptionWebView: View {
    private let htmlDocument: String
    @State private var contentHeight: CGFloat = 1

    init(content: String, format: ResourceDescriptionContentFormat) {
        let fragment: String
        switch format {
        case .markdown:
            fragment = CMarkHTMLRenderer.renderMarkdown(content)
        case .html:
            fragment = content
        }
        htmlDocument = Self.makeHTMLDocument(fragment: fragment)
    }

    var body: some View {
        ResourceDescriptionWebViewRepresentable(
            htmlDocument: htmlDocument,
            contentHeight: $contentHeight,
        )
        .frame(minHeight: contentHeight, maxHeight: contentHeight)
    }

    private static func makeHTMLDocument(fragment: String) -> String {
        let nonce = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        return """
        <!doctype html>
        <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <meta http-equiv="Content-Security-Policy" content="default-src 'none'; img-src http: https: data:; media-src http: https: data:; frame-src http: https:; style-src 'unsafe-inline'; script-src 'nonce-\(nonce)';">
          <style>
            :root {
              color-scheme: light dark;
            }

            html, body {
              margin: 0;
              padding: 0;
              background: transparent;
              color: #202124;
              font: -apple-system-body;
              line-height: 1.48;
              overflow: hidden;
              -webkit-text-size-adjust: 100%;
            }

            body {
              width: 100%;
              overflow-wrap: anywhere;
            }

            body > :first-child {
              margin-top: 0;
            }

            body > :last-child {
              margin-bottom: 0;
            }

            a {
              color: #0a66c2;
            }

            img, video, svg, iframe {
              max-width: 100%;
            }

            pre {
              overflow-x: auto;
            }

            code, pre {
              font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
            }

            table {
              max-width: 100%;
            }

            @media (prefers-color-scheme: dark) {
              html, body {
                color: #f1f3f4;
              }

              a {
                color: #8ab4f8;
              }
            }
          </style>
        </head>
        <body>
          \(fragment)
          <script nonce="\(nonce)">
            (() => {
              const postHeight = () => {
                const body = document.body;
                const html = document.documentElement;
                const height = Math.max(
                  body ? body.scrollHeight : 0,
                  body ? body.offsetHeight : 0,
                  html ? html.clientHeight : 0,
                  html ? html.scrollHeight : 0,
                  html ? html.offsetHeight : 0
                );
                window.webkit.messageHandlers.resourceDescriptionHeight.postMessage(height);
              };

              window.addEventListener("load", postHeight);
              window.addEventListener("resize", postHeight);

              if (window.ResizeObserver) {
                const observer = new ResizeObserver(postHeight);
                observer.observe(document.documentElement);
                if (document.body) {
                  observer.observe(document.body);
                }
              }

              Array.prototype.forEach.call(document.images, image => {
                image.addEventListener("load", postHeight);
                image.addEventListener("error", postHeight);
              });

              postHeight();
              setTimeout(postHeight, 100);
              setTimeout(postHeight, 500);
              setTimeout(postHeight, 1500);
            })();
          </script>
        </body>
        </html>
        """
    }
}

private final class PassthroughScrollWebView: WKWebView {
    override var acceptsFirstResponder: Bool { false }

    override func scrollWheel(with event: NSEvent) {
        if let nextResponder {
            nextResponder.scrollWheel(with: event)
        } else {
            super.scrollWheel(with: event)
        }
    }
}

private struct ResourceDescriptionWebViewRepresentable: NSViewRepresentable {
    let htmlDocument: String
    @Binding var contentHeight: CGFloat

    func makeCoordinator() -> Coordinator {
        Coordinator(contentHeight: $contentHeight)
    }

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = false
        configuration.userContentController.add(
            context.coordinator,
            name: Coordinator.heightMessageName,
        )

        let webView = PassthroughScrollWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.setValue(false, forKey: "drawsBackground")
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        guard context.coordinator.loadedHTMLDocument != htmlDocument else { return }
        context.coordinator.loadedHTMLDocument = htmlDocument
        if contentHeight != 1 {
            DispatchQueue.main.async {
                contentHeight = 1
            }
        }
        webView.loadHTMLString(htmlDocument, baseURL: nil)
    }

    static func dismantleNSView(_ webView: WKWebView, coordinator _: Coordinator) {
        webView.stopLoading()
        webView.navigationDelegate = nil
        webView.uiDelegate = nil
        webView.configuration.userContentController.removeScriptMessageHandler(
            forName: Coordinator.heightMessageName,
        )
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
        static let heightMessageName = "resourceDescriptionHeight"

        var loadedHTMLDocument: String?
        private var contentHeight: Binding<CGFloat>

        init(contentHeight: Binding<CGFloat>) {
            self.contentHeight = contentHeight
        }

        func userContentController(
            _: WKUserContentController,
            didReceive message: WKScriptMessage,
        ) {
            guard message.name == Self.heightMessageName else { return }

            let rawHeight: CGFloat?
            if let value = message.body as? Double {
                rawHeight = CGFloat(value)
            } else if let value = message.body as? Int {
                rawHeight = CGFloat(value)
            } else if let value = message.body as? NSNumber {
                rawHeight = CGFloat(value.doubleValue)
            } else {
                rawHeight = nil
            }

            guard let rawHeight else { return }
            let newHeight = max(1, ceil(rawHeight))
            guard abs(contentHeight.wrappedValue - newHeight) > 0.5 else { return }

            DispatchQueue.main.async {
                self.contentHeight.wrappedValue = newHeight
            }
        }

        func webView(
            _: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void,
        ) {
            guard navigationAction.navigationType == .linkActivated else {
                decisionHandler(.allow)
                return
            }

            if let url = navigationAction.request.url, Self.canOpenExternally(url) {
                NSWorkspace.shared.open(url)
            }
            decisionHandler(.cancel)
        }

        func webView(
            _: WKWebView,
            createWebViewWith _: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures _: WKWindowFeatures,
        ) -> WKWebView? {
            if let url = navigationAction.request.url, Self.canOpenExternally(url) {
                NSWorkspace.shared.open(url)
            }
            return nil
        }

        private static func canOpenExternally(_ url: URL) -> Bool {
            switch url.scheme?.lowercased() {
            case "http", "https", "mailto":
                return true
            default:
                return false
            }
        }
    }
}
