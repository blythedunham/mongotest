module Stalkerazzi
  module RequestContext

    # predefined controller methods
    %w(session request params action_name).each do |method|
      module_eval "def #{method}; controller.try(:#{method}); end ", __FILE__, __LINE__
    end

    #predefined request methods
    %w(user_agent referer remote_addr path_info accept_language).each do |method|
      module_eval <<-END_SRC, __FILE__, __LINE__
        def #{method}; request.try :#{method}; end
      END_SRC
    end

    alias_method :language, :accept_language
    alias_method :ip, :referer
    alias_method :remote_address, :remote_addr
    alias_method :referrer, :referer

    #predefined methods
    def headers
      request.headers.reject { |k,v| !(v.is_a?( String ) && v.include?('.'))  } if request.try( :headers )
    end

    def current_user
      controller.try(:current_user) if controller.respond_to?(:current_user)
    end

    def controller_name;   params[:controller].to_s; end
    def timestamp;         Time.now.utc; end
    def current_user_id;   current_user.try(:to_param); end

    def controller
      Thread.current[:stalkerazzi_controller]
    end

    def controller=(controller)
      Thread.current[:stalkerazzi_controller] = controller
    end

    def with_controller( controller, &block )
      self.controller = controller
      yield
    ensure
      self.controller = nil
    end

    def track_event_with_controller( controller, data = {}, options = {} )
      with_controller( controller ) { track_event_for_object( self, options ) }
    end

    private

    # For missing methods
    # If a method on request, define a method on tracker to delegate to the current request
    # Otherwise, delegate to the controller if it exists
    def method_missing(method, *arguments, &block)
      return if controller.nil?
      if define_delegation_method( method )
        self.send( method )
      else
        controller.__send__(method, *arguments, &block)
      end
    end

    # define a method on tracker to forward this to the request object
    def define_delegation_method( method, object = 'request' )#:nodoc:
      if request && request.respond_to?( method )
        request.send( :method )
        self.class.class_eval "def #{method}; #{object}.try(:#{method}); end"
      end
      true
    rescue ArgumentError => e
      false
    end


     #           :user_agent => env['HTTP_USER_AGENT'],
     #       :language => env['HTTP_ACCEPT_LANGUAGE'],
     #       :path => env['PATH_INFO'],
     #       :ip => env['REMOTE_ADDR'],
     #       :referer => env['HTTP_REFERER']
  end
end