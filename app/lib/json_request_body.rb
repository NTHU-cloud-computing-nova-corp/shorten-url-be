# frozen_string_literal: true

# Parses Json with keys as symbols
class JsonRequestBody
  def self.parse_symbolize(json_str)
    JSON.parse(json_str, symbolize_names: true)
  end
end
