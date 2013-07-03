require 'deadly_serious/version'
require 'deadly_serious/engine/spawner'
require 'deadly_serious/engine/push_pop_send'

# Loading all predefined processes
Dir[File.dirname(__FILE__) + '/deadly_serious/processes/*.rb'].each do |file|
  require File.dirname(file) + '/' + File.basename(file, File.extname(file))
end

module DeadlySerious
end
