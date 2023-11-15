# Generates stand-alone modules

task :update_module_versions => :environment do

    # configuration files used to determine which modules to include
    # and what to use as the default module and exercise settings
    REFERENCE_CONFIGS = [
        'Everything',
        'PL',
        'PIFLAS23'
    ]

    FULL_CONFIG_FILENAME = '_config.json'
    LANG = 'en'
    TIMESTAMP = Time.now.strftime('%Y%m%d%H%M%S')
    OUTPUT_DIRECTORY = File.join(OpenDSA::STANDALONE_MODULES_DIRECTORY, TIMESTAMP)
    OUTPUT_DIRECTORY_REL = TIMESTAMP # output directory relative to the build directory

    # Steps to generate stand-alone modules
    #- 1. run simple2full.py on reference configs to generate full configurations
    #- 2. consolidate full configs into one config, filtering out modules not in
    #       the OpenDSA::STANDALONE_DIRECTORIES hash
    #- 3. check which of the modules need to be updated based on the commit hash of
    #       the commit the module's RST file was last modified in and filter out
    #       modules that don't need updating
    # 4. compile the consolidated configuration (run configure.py with --standalone-modules switch)
    # 5. save the new module versions to the database

    def initialize_output_directory()
        require 'fileutils'
        FileUtils.mkdir_p(OUTPUT_DIRECTORY)
    end

    def build_config()
        config = consolidate_reference_configs()
        module_paths = config['chapters']['modules'].keys
        # filter out modules that don't need their current version updated
        outdated = InstModule.outdated_module_paths(module_paths, LANG, verbose=true)
        config['chapters']['modules'] = config['chapters']['modules'].slice(*outdated.keys)
        outdated.each do |mod_path, git_hash|
            config['chapters']['modules'][mod_path]['git_hash'] = git_hash
        end
        puts "#{outdated.size} out of #{module_paths.size} standalone modules need updating."
        if outdated.size == 0
            config = nil
        end
        return config
    end

    def consolidate_reference_configs()
        config = nil
        modules = {}

        REFERENCE_CONFIGS.each do |config_name|
            config_path = File.join(OpenDSA::BOOK_CONFIG_DIRECTORY, config_name + '.json')
            full_config = process_reference_config(config_path)
            if config.nil?
                config = full_config
            end
            full_config['chapters'].each do |chapter_name, chapter_obj|
                chapter_obj.each do |module_path, module_obj|
                    sep_index = module_path.index('/')
                    unless sep_index.nil?
                        module_folder = module_path[0..(sep_index-1)]
                        if OpenDSA::STANDALONE_DIRECTORIES.key?(module_folder) and !modules.key?(module_path)
                            modules[module_path] = module_obj
                        end
                    end
                end
            end
        end

        config['chapters'] = {
            'modules' => modules
        }
        config['title'] = 'OpenDSA Stand-alone Modules'
        config['desc'] = 'OpenDSA Stand-alone Modules (auto-generated config)'
        config['build_dir'] = OpenDSA::STANDALONE_MODULES_DIR_NAME

        return config
    end

    def process_reference_config(config_file_path)
        puts "Generating full configuration file for reference configuration \"#{config_file_path}\"."

        output_file_path = File.join(OUTPUT_DIRECTORY, File.basename(config_file_path))
        input_path = config_file_path[15..-1] # without the public/OpenDSA
        output_file = output_file_path[15..-1] # without the public/OpenDSA
        require 'net/http'
        uri = URI(ENV["simple_api_link"])
        res = Net::HTTP.post_form(uri, 'input_path' => input_path, 'output_path' => output_file, 'rake' => true)

         unless res.kind_of? Net::HTTPSuccess
            puts "FAILED to generate full configuration file for \"#{config_file_path}\"."
            Rails.logger.info(res['stderr_compressed'])
        end

        json = File.read(output_file_path)
        config_dict = JSON.parse(json)
        return config_dict
    end

    def compile_modules(config)
        script_path = File.join(OpenDSA::OPENDSA_DIRECTORY, 'tools', 'configure.py')
        config_file_path = File.join(OUTPUT_DIRECTORY, FULL_CONFIG_FILENAME)
        File.open(config_file_path, "w") do |f|
            f.write(config.to_json)
        end
        config_path = config_file_path[15..-1] # without the public/OpenDSA
        require 'net/http'
        uri = URI(ENV["config_api_link"])
        res = Net::HTTP.post_form(uri, 'config_file_path' => config_path, 'build_path' => OUTPUT_DIRECTORY_REL, 'rake' => true)

        if res.kind_of? Net::HTTPSuccess
            puts "Compilation of stand-alone modules was SUCCESSFUL."
        else
            puts "Compilation of stand-alone modules FAILED."
            Rails.logger.info(res['stderr_compressed'])
        end

        return res.kind_of? Net::HTTPSuccess
    end

    def main()
        puts "Checking for stand-alone modules that need updating."
        initialize_output_directory()
        config = build_config()
        unless config.nil?
            puts "Compiling stand-alone module files. Please wait."
            successful = compile_modules(config)
            if successful
                puts "Saving new stand-alone module versions to the database."
                lti_html_dir = File.join(OUTPUT_DIRECTORY, 'lti_html')
                fail_count = 0
                success_count = 0
                num_modules = config['chapters']['modules'].size
                config['chapters']['modules'].each do |mod_path, settings|
                    mod_name = mod_path.split('/')[-1]
                    settings['file_path'] = File.join(lti_html_dir, mod_name + '.html')
                    begin
                        InstModuleVersion.save_data_from_json(mod_path, settings)
                        success_count += 1
                    rescue Exception => e
                        fail_count += 1
                        puts "Failed to save module version for #{mod_path}: #{e.message}"
                        puts "Stack trace:"
                        puts e.backtrace
                    end
                end
                puts "Finished updating standalone modules. Successful for #{success_count} out of #{num_modules} modules (#{fail_count} failed)."
            end
        end
    end

    main()

end
