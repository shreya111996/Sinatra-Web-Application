
require 'active_record'

#set database connection

ActiveRecord::Base.establish_connection(
adapter: 'sqlite3',
database: 'db/mydatabase.sqlite3'
)

require_relative 'db/migrate/20241114000000_create_users'

CreateUsers.new.change
