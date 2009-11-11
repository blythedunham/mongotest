module Stalkerazzi
  module RequestContext

    # predefined controller methods
    %w(session request response params action_name).each do |method|
      module_eval "def #{method}; controller.try(:#{method}); end ", __FILE__, __LINE__
    end

    #predefined request methods
    %w(user_agent referer remote_addr path_info accept_language).each do |method|
      module_eval <<-END_SRC, __FILE__, __LINE__
        def #{method}; request.try :#{method}; end
      END_SRC
    end


    #predefined request methods
    %w(status).each do |method|
      module_eval <<-END_SRC, __FILE__, __LINE__
        def #{method}; response.try :#{method}; end
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

    def controller_name;   params[:controller].to_s if params; end
    def timestamp;         Time.now.utc; end
    def current_user_id;   current_user.try(:id); end
    def current_user;      controller.try(:current_user); rescue; end

    def controller_and_action
      "#{controller.controller_name}_#{controller.action_name}" if controller
    end

    def controller
      Thread.current[:stalkerazzi_controller]
    end

    def controller=(controller)
      Thread.current[:stalkerazzi_controller] = controller
    end

    def with_controller( controller, clear = false, &block )
      return unless enabled?
      controller_context = self.controller unless clear
      self.controller = controller
      yield
    ensure
      self.controller = controller_context
    end

    def track_event_with_controller( controller, data = {}, options = {} )
      return unless enabled?
      with_controller( controller ) { track_event_for_object( self, options ) }
    end

    private

    # Delegate missing methods to the request object
    def method_missing(method, *arguments, &block)
      return if request.nil?
      request.__send__(method, *arguments, &block)
    end
  end
end