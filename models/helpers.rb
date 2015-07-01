module Model
  module Helpers
    def since(value, column = 'date')
      value.nil? ? "" : " AND #{column} >= #{value}"
    end

    def order_by(order, column = 'date')
      order.nil? ? "" : " ORDER BY #{column} #{order}"
    end

    def limit(value)
      value.nil? ? "" : " LIMIT #{value}"
    end
  end
end
