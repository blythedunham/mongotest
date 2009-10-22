module MongoMapper
  class FinderOptions
    attr_reader :options
    
    def self.to_mongo_criteria(conditions, parent_key=nil)
      criteria = {}
      conditions.each_pair do |field, value|
        field = field_normalized(field)
        case value
          when Array
            operator_present = field.to_s =~ /^\$/            
            criteria[field] = if operator_present
                                value
                              else
                                {'$in' => value}
                              end
          when Hash
            criteria[field] = to_mongo_criteria(value, field)
          else            
            criteria[field] = value
        end
      end
      
      criteria
    end
        
    def self.to_mongo_options(options)
      options = options.dup
      {
        :fields => to_mongo_fields(options.delete(:fields) || options.delete(:select)),
        :skip   => (options.delete(:skip) || options.delete(:offset) || 0).to_i,
        :limit  => (options.delete(:limit) || 0).to_i,
        :sort   => options.delete(:sort) || to_mongo_sort(options.delete(:order))
      }
    end
    
    def self.field_normalized(field)
      if field.to_s == 'id'
        :_id
      else
        field
      end
    end
    
    OptionKeys = [:fields, :select, :skip, :offset, :limit, :sort, :order]
    
    def initialize(options)
      raise ArgumentError, "FinderOptions must be a hash" unless options.is_a?(Hash)
      
      options = options.symbolize_keys
      @options, @conditions = {}, options.delete(:conditions) || {}
      
      options.each_pair do |key, value|
        if OptionKeys.include?(key)
          @options[key] = value
        else
          @conditions[key] = value
        end
      end
    end
    
    def criteria
      self.class.to_mongo_criteria(@conditions)
    end
    
    def options
      self.class.to_mongo_options(@options)
    end
    
    def to_a
      [criteria, options]
    end
    
    private
      def self.to_mongo_fields(fields)
        return if fields.blank?
      
        if fields.is_a?(String)
          fields.split(',').map { |field| field.strip }
        else
          fields.flatten.compact
        end
      end
    
      def self.to_mongo_sort(sort)
        return if sort.blank?
        pieces = sort.split(',')
        pieces.map { |s| to_mongo_sort_piece(s) }
      end
    
      def self.to_mongo_sort_piece(str)
        field, direction = str.strip.split(' ')
        direction ||= 'ASC'
        direction = direction.upcase == 'ASC' ? 1 : -1
        [field, direction]
      end
  end
end