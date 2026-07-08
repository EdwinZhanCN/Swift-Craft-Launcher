//
//  CMarkHTMLRenderer.swift
//  ResourceFeature
//
//  © 2025-2026 Swift Craft Launcher Team. All rights reserved.
//

import cmark_gfm
import cmark_gfm_extensions
import Foundation

enum CMarkHTMLRenderer {
    static func renderMarkdown(_ markdown: String) -> String {
        let options = CMARK_OPT_UNSAFE
            | CMARK_OPT_VALIDATE_UTF8
            | CMARK_OPT_GITHUB_PRE_LANG
            | CMARK_OPT_LIBERAL_HTML_TAG
            | CMARK_OPT_FOOTNOTES
            | CMARK_OPT_TABLE_PREFER_STYLE_ATTRIBUTES

        let htmlPointer = renderMarkdown(markdown, options: options)

        guard let htmlPointer else { return escapedPlainText(markdown) }
        defer { free(htmlPointer) }

        return String(cString: htmlPointer)
    }

    private static func renderMarkdown(_ markdown: String, options: Int32) -> UnsafeMutablePointer<CChar>? {
        cmark_gfm_core_extensions_ensure_registered()

        guard let parser = cmark_parser_new(options) else { return nil }
        defer { cmark_parser_free(parser) }

        let allocator = cmark_get_default_mem_allocator()
        var extensions: UnsafeMutablePointer<cmark_llist>?
        for extensionName in ["table", "strikethrough", "autolink", "tasklist"] {
            guard let syntaxExtension = cmark_find_syntax_extension(extensionName) else { continue }
            cmark_parser_attach_syntax_extension(parser, syntaxExtension)
            extensions = cmark_llist_append(allocator, extensions, syntaxExtension)
        }
        defer {
            if let extensions {
                cmark_llist_free(allocator, extensions)
            }
        }

        markdown.withCString { markdownCString in
            cmark_parser_feed(parser, markdownCString, strlen(markdownCString))
        }

        guard let document = cmark_parser_finish(parser) else { return nil }
        defer { cmark_node_free(document) }

        return cmark_render_html(document, options, extensions)
    }

    private static func escapedPlainText(_ text: String) -> String {
        text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
