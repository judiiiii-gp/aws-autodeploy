
class IssueParams
  def initialize(body)
    @body = body
  end

  def get_params()
    parsed_input = {}

    lines = @body.split("\n")
    lines.each do |line|
      if line.match(/^:(\w+):\s*(.+)$/)
        key = $1.to_sym
        values = $2.split(",").map(&:strip)
        parsed_input[key] = values
      end
    end
    return parsed_input
  end

  def get_services(issue_params, accepted_services)
    services = []

    issue_params.each do |key, values|
      accepted_services.each do |service|
        if key.to_s.start_with?(service.downcase)
          unless services.include?(service)
            services << service
          end
          break
        end
      end
    end
  
    return services    
  end
  
  def get_order_params(issue_params,services)
    ordered_params = Array.new(services.length) { Hash.new }

    services.each_with_index do |service, index|
      issue_params.each do |key, values|
        if key.to_s.start_with?(service.downcase)
          ordered_params[index][key] = values
        end
      end
    end
    return ordered_params
  end 
end
  