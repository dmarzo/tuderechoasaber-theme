module InfoRequestCustomStates

    def self.included(base)
        base.extend(ClassMethods)
    end

    def theme_calculate_status
        # just fall back to the core calculation
        return self.base_calculate_status
    end

    # Mixin methods for InfoRequest
    module ClassMethods 
        def theme_display_status(status)
            if status == 'unsatisfactory_response'
                _("Unsatisfactory response.")
            else
                raise _("unknown status ") + status        
            end
        end

        def theme_extra_states
            return ['unsatisfactory_response']
        end
    end
end

module RequestControllerCustomStates

    def theme_describe_state(info_request)
        # called after the core describe_state code.  It should
        # end by raising an error if the status is unknown
        if info_request.calculate_status == 'unsatisfactory_response'
            flash[:notice] = _("Authority has provided an unsatisfactory response.")
            redirect_to unhappy_url(info_request)
        else
            raise "unknown calculate_status " + info_request.calculate_status
        end
    end

end
