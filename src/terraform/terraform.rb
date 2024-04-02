require 'tools/log'
require 'tools/file_manager'
require 'open3'
require 'erb'

class Terraform
    attr_reader :success,:files

    LOG_COMP = 'TERRAFORM'

    def self.prepare(issue_number,ordered_params,services)
        Log.debug(LOG_COMP, 'Preparing terraform files')
        @files =  []
        errors = []
        # Set Terraform Provider Data
        Log.debug(LOG_COMP, 'Creating terraform provider file')

        begin
            template = File.read(FileManager::AWS_PROVIDER)
            render = ERB.new(template)
            data = binding
            data.local_variable_set("aws_region",ENV['REGION'])
            data.local_variable_set("aws_access_key",ENV['ACCESS_KEY_ID'])
            data.local_variable_set("aws_secret_key",ENV['SECRET_ACCESS_KEY'])

            result = render.result(data)
            # Save Terraform provider file
            FileManager.save_file(issue_number,FileManager::TF_PROVIDER,result)

            # Set Terraform Config Data
            Log.debug(LOG_COMP, 'Creating terraform config files')

            services.each_with_index do |service, index|
                if ordered_params[index]
                    file_path = "../src/terraform/#{service}.rf.erb"
                    template = File.read(file_path)
                    render = ERB.new(template)
                    data = binding
                    iterations = ordered_params[index][:"#{service}_instances"][0].to_i
                    iterations.times do |i|
                        ordered_params[index].each do |key, values|
                            if key != :"#{service}_instances"
                                data.local_variable_set("#{key}",values[i])
                            end 
                        end
                        file_name = "#{service}_config_#{i}.tf"
                        @files << file_name
                        result = render.result(data)
                        FileManager.save_file(issue_number,file_name,result)
                    end
                end
            end
        rescue StandardError => e
            error_message = "Error preparing Terraform files: #{e.message}"
            Log.error(LOG_COMP, error_message)
            raise error_message
            errors << error_message
        end
        return errors    
    end

    # Execute Terraform init & plan 
    def self.init_plan(issue_number)
        errors = []
        FileManager.change_dir_temp(FileManager::DIR_DEPLOYMENT+'/'+issue_number) do
            # Terraform init
            Log.debug(LOG_COMP, 'Running terraform init')

            stdout, stderr, status = Open3.capture3('terraform init') 
            unless status.success?
                Log.error(LOG_COMP, "Terraform init command fails:\n#{stderr}")
                raise "Terraform init command fails:\n#{stderr}"
                errors << "Terraform init command fails:\n#{stderr}"
                return errors 
            end

            # Terraform plan -> for validate configuration
            Log.debug(LOG_COMP, 'Running terraform plan')
            
            stdout, stderr, status = Open3.capture3(
                'bash -c "set -o pipefail; ' <<
                'terraform plan -out=./plan.txt; ' <<
                'terraform show -json ./plan.txt"'
            )

            Log.debug(LOG_COMP, "Terraform plan stdout:\n#{stdout}")
            unless status.success?
                Log.error(LOG_COMP, "Terraform plan command fails:\n#{stderr}")
                raise "Terraform plan command fails:\n#{stderr}"
                errors << "Terraform apply command fails:\n#{stderr}"
                return errors
            end
        end
        errors
    end

    # Execute Terraform apply operation
    def self.apply(issue_number)
        errors = []
        FileManager.change_dir_temp(FileManager::DIR_DEPLOYMENT+'/'+issue_number) do
            # Terraform init
            stdout, stderr, status = Open3.capture3('terraform init')
            unless status.success?
                Log.error(LOG_COMP, "Terraform init command fails:\n#{stderr}")
                raise "Terraform init command fails:\n#{stderr}"
                errors << "Terraform init command fails:\n#{stderr}"
                return nil,errors
            end

            # Terraform apply
            Log.debug(LOG_COMP, "Running terraform apply")

            stdout, stderr, status = Open3.capture3('terraform apply -auto-approve -no-color') 
            
            Log.debug(LOG_COMP, "Terraform apply stdout:\n#{stdout}")
            unless status.success?
                Log.error(LOG_COMP, "Terraform apply command fails:\n#{stderr}")
                raise "Terraform apply command fails:\n#{stderr}"
                errors << "Terraform apply command fails:\n#{stderr}"
                return nil, errors
            end

            # Use Terraform-bin version for better JSON parsing
            Log.debug(LOG_COMP, "Parsing terraform information")
            stdout, _stderr, _status = Open3.capture3('terraform-bin output -json -no-color')
            outputs = JSON.parse(stdout)
            [outputs,errors]
        end
    end

    def self.get_files
        @files
    end
end