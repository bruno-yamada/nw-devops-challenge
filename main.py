# coding:utf-8
import os
import logging

import tornado.httpserver
import tornado.ioloop
import tornado.options
import tornado.web

from configparser import ConfigParser


class SettingsManager:
    def __init__(self, config_path):
        self.config = ConfigParser()
        self.config.read(config_path)

    @property
    def port(self):
        return self.config.get('API', 'PORT')

settings = SettingsManager('config.ini')


class MainHandler(tornado.web.RequestHandler):
    def get(self, route, *args, **kwargs):
        if route == 'ping':
            self.write('pong')
        else:
            self.write('Hello World!!!!!')
        self.finish()


class Application(tornado.web.Application):
    def __init__(self):

        handlers = [
            (r"/?(?P<route>[^\/]+)?", MainHandler)
        ]

        tornado.web.Application.__init__(self, handlers, autoreload=True)


if __name__ == "__main__":
    try:
        tornado.options.define("port", default=settings.port, help=None, type=int)
        tornado.options.parse_command_line()
        
        app = tornado.httpserver.HTTPServer(Application())
        app.listen(tornado.options.options.port)

        logging.info("Service listening on port %s" % tornado.options.options.port)

        io_loop = tornado.ioloop.IOLoop.instance()
        io_loop.start()

    except KeyboardInterrupt:
        exit()
