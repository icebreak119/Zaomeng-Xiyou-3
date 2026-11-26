import http.server, json, datetime, sys, urllib.parse

class H(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path.startswith('/time'):
            body = json.dumps({"time": datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")}).encode()
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Content-Length', str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return
        if self.path.startswith('/diag'):
            q = urllib.parse.parse_qs(urllib.parse.urlparse(self.path).query)
            sys.stderr.write("DIAG: " + q.get('m', [''])[0] + "\n")
            self.send_response(200)
            self.send_header('Content-Length', '0')
            self.end_headers()
            return
        return super().do_GET()
    def log_message(self, fmt, *args):
        sys.stderr.write("%s - %s\n" % (self.address_string(), fmt % args))

http.server.ThreadingHTTPServer(('127.0.0.1', 8765), H).serve_forever()