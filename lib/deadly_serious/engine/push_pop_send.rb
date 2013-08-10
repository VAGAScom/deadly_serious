require 'deadly_serious/engine/push_pop'
require 'deadly_serious/engine/base_process'

module DeadlySerious
  module Engine
    module PushPopSend
      include PushPop
      include BaseProcess
    end
  end
end
