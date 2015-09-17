require 'multi_json'
require 'fileutils'
require 'rb-inotify'
require 'rbczmq'
require 'deadly_serious/version'
require 'deadly_serious/engine/protocol'
require 'deadly_serious/engine/file_monitor'
require 'deadly_serious/engine/json_io'
require 'deadly_serious/engine/channel'
require 'deadly_serious/engine/auto_pipe'
require 'deadly_serious/engine/commands'

require 'deadly_serious/engine/config'
require 'deadly_serious/engine/ruby_object_container'
require 'deadly_serious/engine/so_command_container'
require 'deadly_serious/engine/pipeline'

# Loading all predefined processes
Dir[File.join(File.dirname(__FILE__), 'deadly_serious', 'processes', '*.rb')].each do |file|
  require File.dirname(file) + '/' + File.basename(file, File.extname(file))
end

module DeadlySerious
  def root
    @root ||= File.expand_path(File.dirname(__FILE__))
  end
end
