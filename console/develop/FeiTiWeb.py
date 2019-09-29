#coding:utf-8
from BaseHTTPServer import BaseHTTPRequestHandler
from SocketServer import ThreadingMixIn, TCPServer
from multiprocessing.pool import ThreadPool
import urlparse
import commands

class ThreadPoolMixIn(ThreadingMixIn):
    MAX_THREAD = 30
    THREAD_POOL = ThreadPool(MAX_THREAD)

    def process_request(self, request, client_address):
        ThreadPoolMixIn.THREAD_POOL.apply_async(self.process_request_thread, (request, client_address))

class ThreadPoolHTTPServer(ThreadPoolMixIn, TCPServer): pass

class FeiTiWebHandler(BaseHTTPRequestHandler):
    COMMAND_SUPPORT = 'support'
    HEADER_TEXT = 'text/plain'
    HEADER_HTML = 'text/html'
    HEADER_JPG = 'image/jpeg'
    HEADER_JSON = 'application/json'
    HEADER_FILE = 'application/octet-stream'

    LINUX_CMD = {'support': "cat /etc/feiti/console/html/support.html",
                 }

    # Request, Response
    def _set_headers(self, content_type=HEADER_HTML, content=None, filename=None):
        self.send_response(200)
        self.send_header('Content-Type', content_type)
        if content:
            self.send_header('Content-Length', len(content))
        if content_type == FeiTiWebHandler.HEADER_FILE and filename and len(filename) > 0:
            self.send_header('Accept-Ranges', 'bytes')
            self.send_header('Content-Disposition', 'attachment;filename="{0}"'.format(filename))
        self.end_headers()

    def _get_command_and_params(self):
        params = {}
        command = ''
        parsed_url = urlparse.urlparse(self.path)
        paths = parsed_url.path.split('/')
        for path in paths:
            if len(path) > 0:
                command += '{0}_'.format(path)

        command = command[0:len(command)-1] if command.endswith('_') else command

        query = parsed_url.query
        if len(query) > 0:
            query_pairs = query.split('&')
            for query_pair in query_pairs:
                pair = query_pair.split('=')
                params[pair[0]] = pair[1]

        return command, params

    def do_GET(self):
        command_and_params = self._get_command_and_params()
        command = command_and_params[0]

        if command == FeiTiWebHandler.COMMAND_SUPPORT:
            output = self._support()
            if output and len(output) > 0:
                self._set_headers(FeiTiWebHandler.HEADER_HTML, output)
                self.wfile.write(output)

    # Support
    def _support(self):
        linux_cmd = FeiTiWebHandler.LINUX_CMD['support']
        return '{0}'.format(self._execute_linux_command(linux_cmd))

    # Linux Operate
    def _execute_linux_command(self, cmd):
        if cmd and isinstance(cmd, str):
            (status, output) = commands.getstatusoutput(cmd)
            if status == 0:
                return output
        return None

def run(server_class=ThreadPoolHTTPServer, handler_class=FeiTiWebHandler, secure=True):
    ThreadPoolHTTPServer.allow_reuse_address = True
    port = 443 if secure else 80
    server_address = ('', port)
    httpd = server_class(server_address, handler_class)
    if secure:
       httpd.socket = ssl.wrap_socket(httpd.socket, keyfile='/etc/feiti/console/crt/server.key', certfile='/etc/feiti/console/crt/server.crt', server_side=True, ca_certs='/etc/feiti/console/crt/ca.crt')
    print 'Starting FeiTi Web...'
    httpd.serve_forever()

if __name__ == "__main__":
    #nohup python FeiTiWeb.py &
    run(secure=False)
