require 'tools/log'

class Action

    LOG_COMP = 'ACT'

    def self.for(action)
        # Actions classes
        case action
        when 'action-validate'
            require 'actions/validate_action'
            ValidateAction.new

        when 'action-deploy'
            require 'actions/deploy_action'
            DeployAction.new

        when 'action-delete'
            require 'actions/delete_action'
            DeleteAction.new

        when 'action-purge'
            require 'actions/purge_action'
            PurgeAction.new

        when 'action-update'
            require 'actions/update_action'
            UpdateAction.new

        when 'action-recover'
            require 'actions/recover_action'
            RecoverAction.new

        else
            raise "Unsupported type of action: #{action}"
        end
    end

    # Perform the expected action
    def execute
        raise 'Method "execute" not implemented'
    end

    # Report the results of the action
    def report
        raise 'Method "report" not implemented'
    end
end