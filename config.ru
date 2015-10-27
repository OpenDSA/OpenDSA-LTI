# config.ru
require './tool_provider'
require 'rubygems'
require 'sinatra'

run Sinatra::Application

