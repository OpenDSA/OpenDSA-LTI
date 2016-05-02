require 'json'

# Helper classes
class FileSystemToJSON
    @@searchDirs = ["en", "fi", "fr", "pt", "sv"]
    def self.convert(path)
        json = {} # The json for this directory
        json["children"] = []
        json["type"] = "category"
        json["path"] = path
        json["text"] = File.basename(path)
        Dir.foreach(path) do |entry|
            child = {}
            if entry == '.' or entry == '..'
                # Skip over the current and parent directory
                next
            end
            # Concatenate the subpath with the entry and path
            subpath = File.join(path, entry)
            if File.file?(subpath) and File.extname(subpath) == '.rst'
                # must be a legitimate module within RST
                child["type"] = "module"
                child["path"] = subpath
                child["text"] = entry
                json["children"].push(child)
            elsif Dir.exists?(subpath)
                # must be a directory so convert the subpath
                child = self.convert(subpath)
                json["children"].push(child)
            end
        end
        return json
    end
end

# Class which represents a book configuration
class BookConfiguration
    @@requiredMembers = ["chapters", "title"]# Required members within the configuration
    # Not sure if these are actually required so modify if needed

    # Constructor
    def initialize(configPath, fileName, json)
        @json = json # The json in the form of a hash object
        @configPath = configPath # The path to the configuration folder
        @fullPath = File.join(configPath, fileName)
    end

    # The path of this BookConfiguration
    def path
        return @fullPath
    end

    def valid?() # Checks to see if the json is a valid configuration
        # TODO Should use this method to check if JSON is valid
        return true # Just returning true for now.
        @@requiredMembers.each do |member|
            if @json.key?(member) == false #If it is missing a member
                return false
            end
        end
        # Should have returned false if there were required members missing from the configuration
        # Now check if all of the modules are valid

    end

    # Checks to see if the module exists on the system. Should be used in the valid? method
    def self.validModule(path)
        return File.exists?(path)
    end

    # Saves this book configuration
    def save(fileName="JSON.txt") #TODO remove default JSON.txt:
        # It's purpose is just to keep old code from breaking

        # Just open the file with write permissions
        newConfigFile = File.open(fileName, "w")
        # Write file and close it
        # TODO make sure output is up to the OpenDSA standard
        newConfigFile.write(JSON.pretty_generate(@json))
        newConfigFile.close
    end
end

# Class that manages book configurations
class BookConfigurationManager
    # Sets the path of the configuration folder that should be managed
    def initialize(configPath)
        @configPath = configPath
    end

    def configExists?(fileName)
        return File.exists?(path(fileName))
    end

    def path(fileName)
        return File.join(@configPath, fileName)
    end

    # Creates a new book configuration and saves it
    # Returns true or false based on whether or not it was saved
    def newBookConfig(fileName, json) # The file name and the json as a hash
        newConfig = BookConfiguration.new(@configPath, fileName, json)
        if newConfig.valid? && !configExists?(fileName)
            # Check if the json is valid the config doesn't exist
            newConfig.save(path(fileName))
            return true
        else
            return false
        end
    end
end

# The actual rails controller
class Configurations::BookController < ApplicationController
    def create
        # If this is a HTTP post request
        if request.post?
            # request.params will be the json object sent in the form of a Hash
            json = request.POST
            # Get the configuration
            configuration = json["config"]
            # Get the name for the configuration
            name = json["name"]
            # Create a new manager to manage the config directory
            manager = BookConfigurationManager.new("./config")
            # 'saved' will be true if the new book configuration is saved
            render json: {received: true, saved: manager.newBookConfig(name+".txt", configuration)}
        end
    end

    # Returns JSON which represents the folder structure within the RST directory
    def modules
        render json: FileSystemToJSON.convert("./RST")
    end
end
