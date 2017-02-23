require 'rubygems'
require 'bundler'
require 'slim'
require 'sass/plugin/rack'

Sass::Plugin.options[:style] = :compressed
use Sass::Plugin::Rack

Bundler.require

require './app'
run Sinatra::Application