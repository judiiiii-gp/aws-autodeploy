require 'actions/action'
require 'templates/validate_template'

class ValidateAction < Action
    attr_reader :success, :errors, :warnings

    def execute(issue_number,ordered_params,services)
        Log.info(LOG_COMP, "Validating template")

        validate_template = ValidateTemplate.new
        @errors, @warnings = validate_template.validate(ordered_params,services)
        
        if @errors.empty?
            @success = true
            Log.info(LOG_COMP, "Validation was successful")
        else
            @success = false
            Log.error(LOG_COMP, "Validation failed with errors: #{@errors}")
        end
        return @success ? ['state-validated'] : ['state-failed-validate']
    end

    def report()
        if @success
            warnings_formatted = @warnings.map { |warning| "* Warning: #{warning}" }.join("\n")
            "✔️ Validation was successful!\n\n#{warnings_formatted}"
        else
            errors_formatted = @errors.map { |error| "* Error: #{error}" }.join("\n")
            "❌ Validation failed with the following errors:\n\n#{errors_formatted}"
        end
    end
end