
  class LegacyBase < ActiveRecord::Base
    establish_connection :adapter => "mysql2", :host => "localhost", :database => "opendsa_lti", :port => 3306, :username => "opendsa", :password => "opendsa"
    self.table_name = 'users'
  end
