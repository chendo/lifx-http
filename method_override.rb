class MethodOverride
  HTTP_METHODS = %w(GET HEAD PUT POST DELETE OPTIONS PATCH LINK UNLINK)

  METHOD_OVERRIDE_PARAM_KEY = "_method".freeze
  HTTP_METHOD_OVERRIDE_HEADER = "HTTP_X_HTTP_METHOD_OVERRIDE".freeze

  def initialize(app)
    @app = app
  end

  def call(env)
    method = method_override(env)
    if HTTP_METHODS.include?(method)
      env["rack.methodoverride.original_method"] = env["REQUEST_METHOD"]
      env["REQUEST_METHOD"] = method
    end

    @app.call(env)
  end

  def method_override(env)
    req = Rack::Request.new(env)
    method = req.params[METHOD_OVERRIDE_PARAM_KEY] ||
      env[HTTP_METHOD_OVERRIDE_HEADER]
    method.to_s.upcase
  end
end
