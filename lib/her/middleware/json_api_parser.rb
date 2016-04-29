module Her
  module Middleware
    # This middleware expects the resource/collection data to be contained in the `data`
    # key of the JSON object
    class JsonApiParser < ParseJSON
      # Parse the response body
      #
      # @param [String] body The response body
      # @return [Mixed] the parsed response
      # @private
      def parse(body)
        json = parse_json(body)

        underscore({
          :data => json[:data] || {},
          :errors => json[:errors] || [],
          :metadata => json[:meta] || {},
        })
      end

      # replace all dashes (-) with underscores (_)
      def underscore(hash, res_hash = {})
        hash.each do |key, val|
          # replace dashes in hash keys to underscores
          key = key.to_s if key.is_a? Symbol
          key = key.gsub(/-/, '_').to_sym

          # assign value to result hash (recursively)
          res_val = val
          if val.is_a? Hash
            res_val = underscore(val)
          elsif val.is_a? Array
            res_val = underscore_arr(val)
          end
          res_hash[key] = res_val
        end
        res_hash
      end

      def underscore_arr(arr, res_arr = [])
        arr.each do |val|
          res_val = val
          if val.is_a? Hash
            res_val = underscore(val)
          elsif val.is_a? Array
            res_val = underscore_arr(val)
          end
          res_arr << res_val
        end
        res_arr
      end

      # This method is triggered when the response has been received. It modifies
      # the value of `env[:body]`.
      #
      # @param [Hash] env The response environment
      # @private
      def on_complete(env)
        env[:body] = case env[:status]
        when 204
          parse('{}')
        else
          parse(env[:body])
        end
      end
    end
  end
end
