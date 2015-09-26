# config.ru
require './tool_provider'
require "webrick/https"

Rack::Server.start(
  :Host             => 'lti.cs.vt.edu',
  :Port             => 9292,
  :Logger           => WEBrick::Log::new($stderr, WEBrick::Log::DEBUG),
  :app              => Sinatra::Application,
  :SSLEnable        => true,
  :SSLVerifyClient  => OpenSSL::SSL::VERIFY_NONE,
  :SSLPrivateKey    => OpenSSL::PKey::RSA.new( File.read "./cert/server.key" ),
  :SSLCertificate   => OpenSSL::X509::Certificate.new( File.read "./cert/server.crt" ),
  :SSLCertName      => [["CN", WEBrick::Utils::getservername]]
)

use Rack::Static,
  :urls => ["/AV", "/config", "/JSAV", "/lib"],
  :root => "public"

run Sinatra::Application
