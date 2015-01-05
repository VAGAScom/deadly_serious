require 'nio'
require 'multi_json'
require 'fileutils'
require 'deadly_serious/version'
require 'deadly_serious/listener'
require 'deadly_serious/reader'
require 'deadly_serious/engine/process_watcher'
require 'deadly_serious/engine/open_io'
require 'deadly_serious/engine/json_io'
require 'deadly_serious/engine/channel'
require 'deadly_serious/engine/auto_pipe'
require 'deadly_serious/engine/commands'
require 'deadly_serious/engine/pipeline'

require 'deadly_serious/maestro'

Dir[File.dirname(__FILE__) + '/deadly_serious/engine/*.rb'].each do |file|
  require File.dirname(file) + '/' + File.basename(file, File.extname(file))
end

# Loading all predefined processes
Dir[File.join(File.dirname(__FILE__), 'deadly_serious', 'processes', '*.rb')].each do |file|
  require File.dirname(file) + '/' + File.basename(file, File.extname(file))
end

module DeadlySerious
  def root
    @root ||= File.expand_path(File.dirname(__FILE__))
  end
end
