#!/usr/bin/env python3
"""
Minimal MCP Server Runtime — Placeholder

This is a lightweight HTTP server that satisfies the health/readiness
probe contracts defined in modules/mcp-service/main.tf.

Replace this with your actual MCP server implementation.
"""

import http.server
import socketserver
import json
import sys

PORT = 8080


class MCPHandler(http.server.BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        # Suppress default logging noise; use structured logging in production
        pass

    def do_GET(self):
        if self.path == "/health":
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps({"status": "healthy"}).encode())
        elif self.path == "/ready":
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps({"status": "ready"}).encode())
        else:
            self.send_response(404)
            self.end_headers()

    def do_POST(self):
        # Placeholder for MCP protocol endpoints
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps({"message": "MCP server placeholder"}).encode())


def main():
    with socketserver.TCPServer(("", PORT), MCPHandler) as httpd:
        print(f"MCP server listening on port {PORT}", file=sys.stderr)
        httpd.serve_forever()


if __name__ == "__main__":
    main()
