class Boolean; end

module MongoMapper
  class Key
    # DateTime currently is not supported by mongo's bson so just use Time
    NativeTypes = [String, Float, Time, Date, Integer, Boolean, Array, Hash]
    
    attr_accessor :name, :type, :options
    
    def initialize(name, type, options={})
      @name, @type = name.to_s, type
      self.options = options.symbolize_keys
    end
    
    def ==(other)
      @name == other.name && @type == other.type
    end
    
    def set(value)
      typecast(value)
    end
    
    def native?
      @native ||= NativeTypes.include?(type)
    end
    
    def subdocument?
      MongoMapper.subdocuments.include?(type)
    end
    
    def get(value)
      if type == Array
        value || []
      elsif type == Hash
        HashWithIndifferentAccess.new(value || {})
      elsif native?
        value
      else
        value.is_a?(type) ? value : type.new(value || {})
      end
    end
    
    private
      def typecast(value)
        return HashWithIndifferentAccess.new(value) if value.is_a?(Hash) && type == Hash
        return value if value.kind_of?(type) || value.nil?
        begin
          if    type == String    then value.to_s
          elsif type == Float     then value.to_f
          elsif type == Array     then value.to_a
          elsif type == Time      then Time.parse(value.to_s)
          elsif type == Date      then Date.parse(value.to_s)
          elsif type == Boolean   then ['true', 't', '1'].include?(value.to_s.downcase)
          elsif type == Integer
            # ganked from datamapper
            value_to_i = value.to_i
            if value_to_i == 0 && value != '0'
              value_to_s = value.to_s
              begin
                Integer(value_to_s =~ /^(\d+)/ ? $1 : value_to_s)
              rescue ArgumentError
                nil
              end
            else
              value_to_i
            end
          else
            value
          end
        rescue
          value
        end
      end
  end
end