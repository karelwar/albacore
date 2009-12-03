require 'albacore/support/albacore_helper'
require 'yaml'

class ExpandTemplates
	include YAMLConfig
	include Logging
	
	attr_accessor :expand_files, :data_file
	
	def initialize
		super()
		@expand_files = []
	end
	
	def expand
		return if @data_file.nil?
		return if @expand_files.empty?
		
		config = read_config(@data_file)
		@expand_files.each { |template_file, output_file| 
			file_config = get_config_for_file config, template_file
			expand_template template_file, output_file, file_config
		}
	end
	
private

	def expand_template(template_file, output_file, config)
		@logger.info "Parsing #{template_file} into #{output_file}"
				
		template_data = ''
		File.open(template_file, "r") {|f| 
			template_data = f.read 
		}
		template_data

		template_data.gsub!(/\#\{(.*?)\}/) {|match|
			value = config[$1]
			@logger.debug "Found \"\#{#{$1}}\": Replacing with \"#{value}\"."
			value
		}
		
		File.open(output_file, "w") {|output|
	    	output.write(template_data)
		}
	end
	
	def read_config(file)
		config = YAML::load(File.open(file, "r"))
		if (config.include?("@include"))
			include_file = File.join(File.dirname(file), config["@include"])
			@logger.debug("Found @include directive. Loading additional data from #{include_file}")			
			config.reject!{|k,v| k == "@include"}
			config = config.merge(read_config(include_file))
		end
		return config
	end
	
	def get_config_for_file(original_config, file)
		filename = File.basename(file)
		file_config = original_config[filename]
		if file_config.nil?
			@logger.debug "No config data found for #{filename}. Using local data."
			new_config = original_config
		else
			@logger.debug "Found config data for #{filename}."
			new_config = original_config.merge(file_config)
		end
		new_config
	end
end