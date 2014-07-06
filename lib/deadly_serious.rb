require 'deadly_serious/version'
require 'deadly_serious/engine/commands'
require 'deadly_serious/engine/pipeline'
require 'deadly_serious/engine/json_io'

# Loading all predefined processes
Dir[File.join(File.dirname(__FILE__), 'deadly_serious', 'processes', '*.rb')].each do |file|
  require File.dirname(file) + '/' + File.basename(file, File.extname(file))
end

module DeadlySerious
  def root
    @root ||= File.expand_path(File.dirname(__FILE__))
  end
end
