require "zabbix-ruby-client/version"
require "zabbix-ruby-client/logger"
require "yaml"

module ZabbixRubyClient
  extend self

  def config(config_file)
    begin
      @config ||= YAML::load_file(config_file)
    rescue Exception => e
      puts "Configuration file cannot be read"
      puts e.message
      return
    end
    @logsdir = makedir(@config['logsdir'],'logs')
    @datadir = makedir(@config['datadir'],'data')
    @config
  end


  def available_plugins
    @available_plugins ||= Dir.glob(File.expand_path("../zabbix-ruby-client/plugins/*.rb", __FILE__)).reduce(Hash.new) { |a,x|
      name = File.basename(x,".rb")
      a[name] = x
      a
    }
  end

  def plugins
    @plugins ||= {}
  end

  def register_plugin(plugin, klass)
    plugins[plugin] = klass
  end

  def data
    @data ||= []
  end

  def load_plugin(plugin)
    unless plugins[plugin]
      if available_plugins[plugin]
        load available_plugins[plugin]
      else
        logger.error "Plugin #{plugin} not found."
      end
    end
  end

  def run_plugin(plugin, args = nil)
    load_plugin plugin
    if plugins[plugin]
      begin
        @data = data + plugins[plugin].send(:collect, @config['host'], args)
      rescue Exception => e
        logger.fatal "Oops"
        logger.fatal e.message
      end
    end
  end

  def collect
    @config['plugins'].each do |plugin|
      run_plugin(plugin['name'], plugin['args'])
    end
    logger.info data.flatten.inspect
  end

  def store

  end

  def upload
    logger.info "zabbix_sender -z #{@config['zabbix']['host']} "
  end

  private

  def makedir(configdir, defaultdir)
    dir = configdir || defaultdir
    FileUtils.mkdir dir unless Dir.exists? dir
    dir
  end

  def logger
    @logger ||= Logger.get_logger(@logsdir, @config["loglevel"])
  end

end
