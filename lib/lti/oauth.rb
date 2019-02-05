module OAuth
  def self.generate_oauth_params(consumer_key, consumer_secret, target_url,
                                 params, http_method = :post)
    uri = URI.parse(CGI.unescape_html(target_url))

    if uri.port == uri.default_port
      host = uri.host
    else
      host = "#{uri.host}:#{uri.port}"
    end

    consumer = OAuth::Consumer.new(consumer_key, consumer_secret, {
      site: "#{uri.scheme}://#{host}",
      signature_method: "HMAC-SHA1",
    })

    path = uri.path
    path = '/' if path.empty?

    query_params = {}
    unless uri.query.blank?
      CGI.parse(uri.query).each do |query_key, query_values|
        unless params[query_key]
          params[query_key] = query_values.first
          query_params[query_key] = ''
        end
      end
    end

    options = {
      :scheme => 'body',
      :timestamp => get_timestamp(),
      :nonce => generate_nonce(),
    }

    request = consumer.create_signed_request(http_method, path, nil, options, params)
    hash = {}
    request.body.split(/&/).each do |param|
      key, val = param.split(/=/).map { |v| CGI.unescape(v) }
      unless query_params.key?(key)
        hash[key] = val
      end
    end
    return hash
  end

  private

  def self.generate_nonce()
    return SecureRandom.hex()
  end

  def self.get_timestamp()
    return Time.now.to_i
  end
end
