task :clear_rails_cache => :environment do
    # used by app/controllers/configurations/book_controller.rb
    Rails.cache.delete('odsa_reference_book_configs')
    Rails.cache.delete('odsa_available_modules')

    # set in app/models/inst_module.rb
    Rails.cache.delete('odsa_current_module_versions_dict')
    Rails.cache.delete('odsa_embeddable_dict')
end