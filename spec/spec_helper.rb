$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "cf/uaa"
require "logger"

require 'bundler'
Bundler.require

HttpLogger.logger =  Logger.new('tmp/http.log')
HttpLogger.colorize = true
HttpLogger.log_headers = true
