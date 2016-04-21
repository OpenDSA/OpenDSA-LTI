require 'json'

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

class BookConfiguration
    @@requiredMembers = ["chapters", "title"]# Required members within the configuration

    def initialize(json)
        @json = json
    end

    def valid?() # Checks to see if the json is a valid configuration
        return true
        @@requiredMembers.each do |member|
            if json.key?(member) == false #If it is missing a member
                return false
            end
        end
        # Should have returned false if there were required members missing from the configuration
        # Now check if all of the modules are valid

    end

    def self.validModule(path)
        return File.exists?(path)
    end

    def save
        newConfigFile = File.open("JSON.txt", "w")
        newConfigFile.write(@json.to_json)
        newConfigFile.close
    end
end

class Configurations::BookController < ApplicationController
    def create
        if request.post?
            # request.params will be the json object sent in the form of a Hash
            json = request.POST
            config = BookConfiguration.new(json)
            config.save
            render json: {received: true, valid: config.valid?}
        end
    end

    def modules
        render json: FileSystemToJSON.convert("./RST")
    end
end
