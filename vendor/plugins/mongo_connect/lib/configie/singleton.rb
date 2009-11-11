module SingletonWithDelegation
  def self.included( base )
    base.class_eval do
      include ::Singleton
      extend SingletonWithDelegation::ClassMethods
    end
  end

  # delegate missing class methods to the instance
  module ClassMethods
    def method_missing( method, *arguments, &block )
      instance.__send__( method, *arguments, &block ) if instance
    end
  end
end
