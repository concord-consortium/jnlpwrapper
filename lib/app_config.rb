require 'yaml'

class AppConfig
  def self.config
    return YAML.load_file(File.join(File.dirname(__FILE__), "..","config","config.yml")) rescue {}
  end
end
