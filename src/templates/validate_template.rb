require 'aws-sdk-ec2'

class ValidateTemplate
  LOG_COMP = 'VAL_TEMP'

  def initialize
    Aws.config.update({
      credentials: Aws::Credentials.new(ENV['ACCESS_KEY_ID'], ENV['SECRET_ACCESS_KEY']),
      region: ENV['REGION']
    })
    @aws_ec2_client = Aws::EC2::Client.new
  end

  def validate(ordered_params, services)
    errors = []
    warnings = []
  
    # Specific validations for each service
    services.each_with_index do |service, index|
      validations = get_validations_for_service(service)
      next if validations.nil?
  
      Log.debug(LOG_COMP, "Validating with #{service} schema")
  
      if ordered_params[index]
        ordered_params[index].each do |key, values|
          next unless validations[key]
          Log.info(LOG_COMP, "Validating with #{key} #{values}")       
          values.each do |value|
            if value.empty? 
              default_value = default_value_for_key(key)
              warnings << "No value provided for '#{key}'. Default value '#{default_value}' will be applied."
              value = default_value
            end

            if validations[key][:regex]
              unless value.match?(validations[key][:regex])
                errors << "Value '#{value}' for '#{key}' not validated. It should #{validations[key][:message]}"
              end
            elsif validations[key][:options]
              unless validations[key][:options].include?(value)
                errors << "Value '#{value}' for '#{key}' not validated. It should #{validations[key][:message]}"
              end
            end
          end
        end
      end
      # Specific validation for certain services (e.g., AWS API)
      case service
      when "ec2"
        ec2_instance_type_index = ordered_params.index { |param| param.key?(:ec2_instance_type) }
        if ec2_instance_type_index
          errors.concat(validate_ec2_instance_type(ordered_params[ec2_instance_type_index][:ec2_instance_type]))
        end
      
        ec2_ami_index = ordered_params.index { |param| param.key?(:ec2_ami) }
        if ec2_ami_index
          errors.concat(validate_ec2_ami(ordered_params[ec2_ami_index][:ec2_ami]))
        end
      end      
    end
  
    [errors, warnings]
  end

  def get_validations_for_service(service)
    case service
    when "ec2"
      return {
        ec2_instances: { regex: /\A[0-5]\z/, message: "be a number between 0 and 5" },
        ec2_name: { regex: /\A[a-zA-Z0-9\-_]+\z/, message: "contain only characters, numbers, - or _" },
        ec2_ami_os: { options: ["windows", "linux"], message: "be 'windows' or 'linux'" },
        ec2_tags: { regex: /\A[a-zA-Z0-9\-_]+\z/, message: "contain only characters, numbers, - or _" }
      }
    # Add validations for other services as needed
    else
      return nil
    end
  end
  
  def default_value_for_key(key)
    case key
    when :ec2_instances
      "1"
    when :ec2_name
      "aws-autodeploy" 
    when :ec2_ami_os
      "linux"
    when :ec2_tags
      "github" 
    end
  end
  
  def validate_ec2_instance_type(instance_types)
    errors = []
    instance_types.each do |instance_type|
      if instance_type.nil?
        errors << "EC2 instance type is not specified."
      else
        response_type = @aws_ec2_client.describe_instance_type_offerings(
          filters: [{ name: 'instance-type', values: [instance_type] }]
        )
        if response_type.instance_type_offerings.empty?
          errors << "The instance type '#{instance_type}' is not valid."
        end
      end
    end
    errors
  end
  
  def validate_ec2_ami(ami_ids)
    errors = []
    ami_ids.each do |ami_id|
      if ami_id.nil?
        errors << "EC2 AMI is not specified."
      else
        begin
          response_bad_ami = @aws_ec2_client.describe_images(image_ids: [ami_id])
        rescue Aws::EC2::Errors::InvalidAMIIDMalformed => e
          errors << "AMI ID '#{ami_id}' is malformed."
        rescue Aws::EC2::Errors::InvalidAMIIDNotFound => e
          errors << "AMI '#{ami_id}' not found."
        rescue Aws::EC2::Errors::MissingParameter => e
          errors << "AMI ID is null: '#{ami_id}'."
        rescue => e
          errors << "Error: #{e.message}"
        end
      end
    end
    errors
  end
end