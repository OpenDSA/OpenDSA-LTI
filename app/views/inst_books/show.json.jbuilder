json.(@inst_book, :title, :book_url, :book_code)

json.chapters do
  json.array!(@inst_book.inst_chapters) do |inst_chapter|
    json.id inst_chapter.id
    json.name inst_chapter.name

    json.modules do
      json.array!(inst_chapter.inst_chapter_modules) do |inst_chapter_module|
        json.id inst_chapter_module.id
        json.name InstModule.where(:id => inst_chapter_module.inst_module_id).name
      end
    end

  end
end
