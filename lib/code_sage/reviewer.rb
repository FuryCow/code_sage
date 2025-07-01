require 'llm_chain'

module CodeSage
  class Reviewer
    attr_reader :options
    
    def initialize(options = {})
      @options = {
        branch: 'main',
        files: nil,
        format: 'console',
        config_path: nil,
        verbose: false,
        enable_rag: false  # Отключаем RAG по умолчанию
      }.merge(options)
      
      @git_analyzer = GitAnalyzer.new(@options)
      @formatter = ReportFormatter.new(@options[:format])
      @llm_chain = setup_llm_chain
    end
    
    def review
      puts "🔍 Analyzing code changes..." if @options[:verbose]
      
      changes = @git_analyzer.get_changes
      
      if changes.empty?
        return { success: true, message: "No changes to review" }
      end
      
      puts "📝 Found #{changes.length} changed files" if @options[:verbose]
      
      reviews = []
      
      changes.each do |change|
        puts "Reviewing #{change[:file]}..." if @options[:verbose]
        
        review = review_file(change)
        reviews << review if review
      end
      
      report = generate_report(reviews)
      output_report(report)
      
      { success: true, reviews: reviews, report: report }
    rescue => e
      { success: false, error: e.message }
    end
    
    private
    
    def setup_llm_chain
      # Load configuration
      config = @options[:config_path] ? Config.new(@options[:config_path]) : Config.new
      
      llm_config = config.data['llm']
      provider = llm_config['provider'] || 'openai'
      model = llm_config['model'] || 'gpt-4'
      
      # Configure LLM chain for code review using proper API
      case provider.downcase
      when 'openai'
        LLMChain::Chain.new(
          model: model,
          retriever: false,
          client_options: {
            api_key: llm_config['api_key'] || ENV['OPENAI_API_KEY'],
            temperature: llm_config['temperature'] || 0.1,
            max_tokens: llm_config['max_tokens'] || 2000
          }
        )
      when 'ollama'
        # For local Ollama models
        LLMChain::Chain.new(
          model: model,
          retriever: false,
          client_options: {
            temperature: llm_config['temperature'] || 0.1,
            base_url: ENV['OLLAMA_BASE_URL'] || 'http://localhost:11434'
          }
        )
      when 'qwen'
        # For Qwen models via Ollama
        LLMChain::Chain.new(
          model: model.include?('qwen') ? model : 'qwen2:7b',
          retriever: false,
          client_options: {
            temperature: llm_config['temperature'] || 0.1,
            base_url: ENV['OLLAMA_BASE_URL'] || 'http://localhost:11434'
          }
        )
      else
        # Default to OpenAI
        LLMChain::Chain.new(
          model: 'gpt-4',
          retriever: false,
          client_options: {
            api_key: ENV['OPENAI_API_KEY'],
            temperature: 0.1
          }
        )
      end
    end
    
    def build_system_message
      <<~PROMPT
        You are CodeSage, an expert code reviewer specializing in Ruby development.
        
        Your role is to:
        1. Identify potential bugs, security issues, and performance problems
        2. Suggest improvements for code readability and maintainability  
        3. Check for adherence to Ruby best practices and conventions
        4. Provide constructive feedback with specific examples
        5. Highlight both positive aspects and areas for improvement
        
        Focus on:
        - Code quality and structure
        - Potential runtime errors
        - Security vulnerabilities
        - Performance optimizations
        - Ruby idioms and best practices
        - Testing considerations
        
        Provide your feedback in a structured format with clear categories and actionable suggestions.
      PROMPT
    end
    
    def review_file(change)
      prompt = build_file_review_prompt(change)
      
      # Use llm_chain's ask method with system message context
      full_prompt = "#{build_system_message}\n\n#{prompt}"
      response = @llm_chain.ask(full_prompt)
      
      {
        file: change[:file],
        change_type: change[:type],
        lines_added: change[:lines_added],
        lines_removed: change[:lines_removed],
        review: response,
        timestamp: Time.now
      }
    rescue => e
      puts "Error reviewing #{change[:file]}: #{e.message}".colorize(:red)
      nil
    end
    
    def build_file_review_prompt(change)
      <<~PROMPT
        Please review the following Ruby code changes:
        
        File: #{change[:file]}
        Change Type: #{change[:type]}
        Lines Added: #{change[:lines_added]}
        Lines Removed: #{change[:lines_removed]}
        
        Code Diff:
        ```
        #{change[:diff]}
        ```
        
        Full File Context (if available):
        ```ruby
        #{change[:content] || 'Not available'}
        ```
        
        Please provide a comprehensive review focusing on:
        1. Code quality and best practices
        2. Potential bugs or issues
        3. Security considerations
        4. Performance implications
        5. Suggestions for improvement
        
        Format your response as structured feedback with clear sections.
      PROMPT
    end
    
    def generate_report(reviews)
      {
        summary: generate_summary(reviews),
        reviews: reviews,
        metrics: calculate_metrics(reviews),
        recommendations: generate_recommendations(reviews),
        generated_at: Time.now
      }
    end
    
    def generate_summary(reviews)
      total_files = reviews.length
      
      {
        total_files_reviewed: total_files,
        files_with_issues: reviews.count { |r| r[:review].include?('issue') || r[:review].include?('problem') },
        total_lines_changed: reviews.sum { |r| r[:lines_added] + r[:lines_removed] }
      }
    end
    
    def calculate_metrics(reviews)
      {
        avg_lines_per_file: if reviews.empty?
                              0
                            else
                              reviews.sum do |r|
                                r[:lines_added] + r[:lines_removed]
                              end / reviews.length
                            end,
        files_by_type: reviews.group_by { |r| r[:change_type] }.transform_values(&:count)
      }
    end
    
    def generate_recommendations(reviews)
      # Extract common patterns and generate overall recommendations
      # This could be enhanced with more sophisticated analysis
      [
        "Review suggested improvements for each file",
        "Consider adding or updating tests for modified code",
        "Ensure all security recommendations are addressed"
      ]
    end
    
    def output_report(report)
      formatted_report = @formatter.format(report)
      puts formatted_report
    end
  end
end 