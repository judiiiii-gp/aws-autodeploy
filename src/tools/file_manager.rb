require 'tools/log'
require 'fileutils'

class FileManager
    attr_reader :success

    LOG_COMP = 'FM'

    # Global relative PATHS
    pwd = Dir.pwd
    DIR_DEPLOYMENT  = '../deployments'
    TERRAFORM       = '../src/terraform'
    AWS_PROVIDER    = '../src/terraform/aws_provider.rf.erb'
    
    # Global Terraform FILES
    TF_PROVIDER     = 'provider.tf'
    
    # Temporarily changes the current directory to `dir`, executes the block, and reverts the directory back.
    def self.change_dir_temp(dir)
        begin
            pwd = Dir.pwd
            Dir.chdir dir
            yield
        ensure
            Dir.chdir pwd
        end
    end

    def self.save_file(issue_number,name,data)

        create_dir(issue_number)

        begin
            File.write(
                File.join(DIR_DEPLOYMENT,issue_number.to_s,name), data
            )
            puts "FileManager"
            system('ls', '-l')

        rescue Errno::EACCES => e
            puts "Error: Permission denied. Unable to write file #{name}.\n#{e.message}"
        rescue StandardError => e
            raise "Error writing #{name}.\n#{e}"
        end
    end

    def self.create_dir(issue_number)
        return true if File.directory?(File.join(DIR_DEPLOYMENT,issue_number.to_s))

        FileUtils.mkdir_p(File.join(DIR_DEPLOYMENT,issue_number.to_s))
    end   
end