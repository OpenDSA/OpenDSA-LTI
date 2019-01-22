# config/initializers/assets.rb
Rails.application.config.assets.precompile << Proc.new do |path|
  if path =~ /\.(css|js)\z/ && path !~ /bootstrap-social/
    if Rails.env == "development" && Rails.application.assets.find_asset(path)
      true
    elsif (Rails.env == "production" || Rails.env = "staging") && Rails.application.assets_manifest.assets[path]
      true
    else
      # logger.info "excluding asset: " + full_path
      false
    end
  else
    false
  end
end
