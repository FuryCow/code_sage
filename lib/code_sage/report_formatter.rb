require 'json'
require 'colorize'

module CodeSage
  class ReportFormatter
    attr_reader :format
    
    def initialize(format = 'console')
      @format = format.to_s.downcase
    end
    
    def format(report)
      case @format
      when 'json'
        format_json(report)
      when 'markdown'
        format_markdown(report)
      else
        format_console(report)
      end
    end
    
    private
    
    def format_console(report)
      output = []
      
      # Header
      output << "=" * 80
      output << "🔮 CodeSage Review Report".colorize(:cyan).bold
      output << "Generated at: #{report[:generated_at]}"
      output << "=" * 80
      output << ""
      
      # Summary
      summary = report[:summary]
      output << "📊 SUMMARY".colorize(:yellow).bold
      output << "-" * 40
      output << "Files reviewed: #{summary[:total_files_reviewed]}"
      output << "Files with potential issues: #{summary[:files_with_issues]}"
      output << "Total lines changed: #{summary[:total_lines_changed]}"
      output << ""
      
      # Metrics
      if report[:metrics]
        metrics = report[:metrics]
        output << "📈 METRICS".colorize(:yellow).bold  
        output << "-" * 40
        output << "Average lines per file: #{metrics[:avg_lines_per_file].round(1)}"
        
        if metrics[:files_by_type].any?
          output << "Files by change type:"
          metrics[:files_by_type].each do |type, count|
            output << "  #{type}: #{count}"
          end
        end
        output << ""
      end
      
      # Individual reviews
      output << "📝 DETAILED REVIEWS".colorize(:yellow).bold
      output << "-" * 80
      
      report[:reviews].each_with_index do |review, index|
        output << ""
        output << "#{index + 1}. #{review[:file]}".colorize(:cyan).bold
        output << "   Type: #{review[:change_type]} | +#{review[:lines_added]} -#{review[:lines_removed]}"
        output << "   " + "-" * 70
        
        # Format review content
        review_lines = review[:review].split("\n")
        review_lines.each do |line|
          if line.match(/^(Issue|Problem|Warning):/i)
            output << "   #{line}".colorize(:red)
          elsif line.match(/^(Suggestion|Recommendation):/i)
            output << "   #{line}".colorize(:yellow)
          elsif line.match(/^(Good|Positive):/i)
            output << "   #{line}".colorize(:green)
          else
            output << "   #{line}"
          end
        end
      end
      
      # Recommendations
      if report[:recommendations]&.any?
        output << ""
        output << "💡 RECOMMENDATIONS".colorize(:yellow).bold
        output << "-" * 40
        report[:recommendations].each_with_index do |rec, index|
          output << "#{index + 1}. #{rec}"
        end
      end
      
      output << ""
      output << "=" * 80
      
      output.join("\n")
    end
    
    def format_json(report)
      JSON.pretty_generate(report)
    end
    
    def format_markdown(report)
      output = []
      
      # Header
      output << "# 🔮 CodeSage Review Report"
      output << ""
      output << "**Generated at:** #{report[:generated_at]}"
      output << ""
      
      # Summary
      summary = report[:summary]
      output << "## 📊 Summary"
      output << ""
      output << "| Metric | Value |"
      output << "|--------|-------|"
      output << "| Files reviewed | #{summary[:total_files_reviewed]} |"
      output << "| Files with potential issues | #{summary[:files_with_issues]} |"
      output << "| Total lines changed | #{summary[:total_lines_changed]} |"
      output << ""
      
      # Metrics
      if report[:metrics]
        metrics = report[:metrics]
        output << "## 📈 Metrics"
        output << ""
        output << "- **Average lines per file:** #{metrics[:avg_lines_per_file].round(1)}"
        
        if metrics[:files_by_type].any?
          output << "- **Files by change type:**"
          metrics[:files_by_type].each do |type, count|
            output << "  - #{type}: #{count}"
          end
        end
        output << ""
      end
      
      # Individual reviews
      output << "## 📝 Detailed Reviews"
      output << ""
      
      report[:reviews].each_with_index do |review, index|
        output << "### #{index + 1}. `#{review[:file]}`"
        output << ""
        change_info = "**Change Type:** #{review[:change_type]} | " \
                      "**Lines:** +#{review[:lines_added]} -#{review[:lines_removed]}"
        output << change_info
        output << ""
        output << "```"
        output << review[:review]
        output << "```"
        output << ""
      end
      
      # Recommendations
      if report[:recommendations]&.any?
        output << "## 💡 Recommendations"
        output << ""
        report[:recommendations].each_with_index do |rec, index|
          output << "#{index + 1}. #{rec}"
        end
        output << ""
      end
      
      output.join("\n")
    end
  end
end 