module Stalkerazzi
  module RequestContext
    #predefined methods
    def headers
      request.headers.reject { |k,v| !v.is_a?( String ) } if request.try( :headers )
    end

    def current_user
      controller.try(:current_user) if controller.respond_to?(:current_user)
    end

    def controller_name;   params[:controller].to_s; end
    def timestamp;         Time.now.utc; end
    def current_user_id;   current_user.try(:to_param); end

    %w(user_agent referer referrer remote_addr path_info).each do |method|
      module_eval <<-END_SRC, __FILE__, __LINE__
        def #{method}; request.try :#{method}; end
      END_SRC
    end

    %w(session request params action_name).each do |method|
      module_eval "def #{method}; controller.try(:#{method}); end ", __FILE__, __LINE__
    end

    def with_controller( controller, &block )
      self.controller = controller
      yield
    ensure
      self.controller = nil
    end

    def controller
      Thread.current[:stalkerazzi_controller]
    end

    def controller=(controller)
      Thread.current[:stalkerazzi_controller] = controller
    end

    def track_event_with_controller( controller, data = {}, options = {} )
      with_controller( controller ) { track_event_for_object( self, options ) }
    end

    private
    def method_missing(method, *arguments, &block)
      return if controller.nil?
      controller.__send__(method, *arguments, &block)
    end

     #           :user_agent => env['HTTP_USER_AGENT'],
     #       :language => env['HTTP_ACCEPT_LANGUAGE'],
     #       :path => env['PATH_INFO'],
     #       :ip => env['REMOTE_ADDR'],
     #       :referer => env['HTTP_REFERER']
  end
end