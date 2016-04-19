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
            else
                # must be a directory so convert the subpath
                child = self.convert(subpath)
            end
            # Add each child
            json["children"].push(child)
        end
        return json
    end
end

class Configurations::BookController < ApplicationController
    def create

    end

    def modules
        render json: FileSystemToJSON.convert("/home/hudson/Documents/Coding/UndergradResearch/OpenDSA-LTI-Rails
/RST")
    end
end
