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
    def clean_response(hash)
      return hash unless hash.instance_of? Hash
      hash.each do |k, v|
        clean_response(v)
        hash[k] = nil if v == ""
      end
    end

    def normalized_code(code)
    end

    def user_fields
      ['email', 'username', 'about', 'name', 'isAnonymous']
    end
end
