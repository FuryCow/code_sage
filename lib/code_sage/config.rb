require 'yaml'

module CodeSage
  class Config
    DEFAULT_CONFIG = {
      'llm' => {
        'provider' => 'openai',  # openai, ollama, qwen, gemini
        'model' => 'gpt-4',
        'temperature' => 0.1,
        'max_tokens' => 2000,
        'api_key' => nil  # Will use ENV variables
      },
      'git' => {
        'default_branch' => 'main',
        'include_patterns' => ['*.rb', '*.rake', 'Gemfile', 'Rakefile'],
        'exclude_patterns' => ['spec/**/*', 'test/**/*']
      },
      'review' => {
        'focus_areas' => ['security', 'performance', 'maintainability', 'best_practices'],
        'severity_levels' => ['low', 'medium', 'high', 'critical']
      },
      'output' => {
        'format' => 'console',
        'verbose' => false,
        'colors' => true
      },
      'auto_fix' => {
        'enabled' => false,
        'confirm_before_apply' => true,
        'create_backups' => true,
        'backup_extension' => '.backup'
      }
    }.freeze
    
    attr_reader :config_path, :data
    
    def initialize(config_path = nil)
      @config_path = config_path || default_config_path
      @data = load_config
    end
    
    def get(key_path)
      keys = key_path.split('.')
      keys.reduce(@data) { |config, key| config&.dig(key) }
    end
    
    def set(key_path, value)
      keys = key_path.split('.')
      last_key = keys.pop
      target = keys.reduce(@data) { |config, key| config[key] ||= {} }
      target[last_key] = value
    end
    
    def save!
      File.write(@config_path, YAML.dump(@data))
    end
    
    def reset!
      @data = DEFAULT_CONFIG.dup
      save!
    end

    def config_info
      if File.exist?(@config_path)
        "Using config file: #{@config_path}"
      else
        "No config file found, using defaults"
      end
    end

    def show_config_info
      puts "📋 #{config_info}".colorize(:cyan)
    end
    
    private
    
    def default_config_path
      # Сначала ищем в текущей директории
      local_config = File.expand_path('.code_sage.yml')
      return local_config if File.exist?(local_config)
      
      # Если не найден, ищем в домашней папке
      global_config = File.expand_path('~/.code_sage.yml')
      return global_config if File.exist?(global_config)
      
      # Если ни один не найден, возвращаем путь к локальному для создания
      local_config
    end
    
    def load_config
      if File.exist?(@config_path)
        loaded = YAML.load_file(@config_path) || {}
        deep_merge(DEFAULT_CONFIG, loaded)
      else
        DEFAULT_CONFIG.dup
      end
    rescue => e
      puts "Warning: Could not load config file #{@config_path}: #{e.message}".colorize(:red)
      DEFAULT_CONFIG.dup
    end
    
    def deep_merge(hash1, hash2)
      result = hash1.dup
      hash2.each do |key, value|
        if result[key].is_a?(Hash) && value.is_a?(Hash)
          result[key] = deep_merge(result[key], value)
        else
          result[key] = value
        end
      end
      result
    end
  end
end 