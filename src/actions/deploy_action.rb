require 'actions/action'
require 'terraform/terraform'
require 'tools/file_manager'

class DeployAction < Action
    attr_reader :success, :errors, :data

    def execute(issue_number,ordered_params,services)
        Log.info(LOG_COMP, "Deploying template")
        @errors=[]
        begin
            @errors.concat(Terraform.prepare(issue_number,ordered_params,services))
            @errors.concat(Terraform.init_plan(issue_number))
            @data,error2 = Terraform.apply(issue_number)
            @errors.concat(error2) if error2
        rescue StandardError => e
            Log.error(LOG_COMP, "Deploying template failed: #{e}")
            @errors << e.message
        else
            Log.info(LOG_COMP, "Template from Issue #{issue_number} deployed")
        end 
        @success = @errors.empty?
        return @success ? ['state-deploying','state-running'] : ['state-failed-deploying']
    end

    def report()
        if @success
            formatted_data = "✔️ Deployment was successful!\n\n"
            @data.group_by { |key, _| key.split("_").last }.each do |instance_name, data|
                instance_name_with_prefix = instance_name.start_with?("ec2_") ? instance_name : "ec2_#{instance_name}"
                formatted_data += "#{instance_name_with_prefix}:\n"
                data.each do |key, value|
                    key_without_instance_name = key.sub("instance_", "").sub("_ec2_#{instance_name}", "").gsub("_", " ")
                    value_of_value = value["value"]
                    formatted_data += "  #{key_without_instance_name} : #{value_of_value}\n"
                end
                formatted_data += "\n"
                end
            formatted_data
        else
            errors_formatted = @errors.map { |error| "* Error: #{error}" }.join("\n")
            "❌ Deployment failed\n\n#{errors_formatted}"
        end
    end

end