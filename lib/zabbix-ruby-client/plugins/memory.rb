module ZabbixRubyClient
  module Plugins
    module Memory
      extend self

      def collect(*args)
        host = args[0]
        meminfo = `vmstat -s | head -10`
        if $?.to_i == 0
          info = {}
          meminfo.split(/\n/).map(&:strip).each do |line|
            kb, _, label1, label2 = line.split(" ")
            info[label1+label2] = kb
          end
        else
          logger.warn "Please install sysstat."
          return []
        end
        back = []
        back << "#{host} memory[total] #{info["totalmemory"]}"
        back << "#{host} memory[used] #{info["usedmemory"]}"
        back << "#{host} memory[active] #{info["activememory"]}"
        back << "#{host} memory[inactive] #{info["inactivememory"]}"
        back << "#{host} memory[free] #{info["freememory"]}"
        back << "#{host} memory[buffer] #{info["buffermemory"]}"
        back << "#{host} memory[swap_cache] #{info["swapcache"]}"
        back << "#{host} memory[swap_total] #{info["totalswap"]}"
        back << "#{host} memory[swap_used] #{info["usedswap"]}"
        back << "#{host} memory[swap_free] #{info["freeswap"]}"
        return back

      end

    end
  end
end

ZabbixRubyClient.register_plugin('memory', ZabbixRubyClient::Plugins::Memory)