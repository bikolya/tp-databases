class Response
  attr_reader :code, :body

  CODES = {
    ok: 0,
    not_found: 1,
    bad_request: 2,
    unprocessable: 3,
    unknown: 4,
    already_exists: 5
  }

  ERRNO_TO_CODE = {
  }

  def initialize(attrs = {})
    @code = CODES[attrs.fetch(:code)]
    @body = clean_response(attrs.fetch(:body))
  end

  def take
    {
      code: code,
      response: body
    }
  end

  private
    def clean_response(body)
      case body
      when Hash
        clean_hash(body)
      when Array
        clean_array(body)
      else
        body
      end
    end

    def clean_hash(hash)
      hash.each do |k, v|
        clean_hash(v) if v.instance_of? Hash
        hash[k] = nil if v == ""
      end
    end

    def clean_array(array)
      array.each { |hash| clean_hash(hash) }
    end

    def normalized_code(code)
    end

    def user_fields
      ['email', 'username', 'about', 'name', 'isAnonymous']
    end
end
