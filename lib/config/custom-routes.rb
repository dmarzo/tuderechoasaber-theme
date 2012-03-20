if ENV["RAILS_ENV"] != "test"
    ActionController::Routing::Routes.draw do |map|
        # Additional help pages
        map.with_options :controller => 'help' do |help|
            help.help_help_out '/help/help_out', :action => 'help_out'
            
            help.help_press '/help/press', :action => 'press'
            help.help_privacy_policy '/help/privacy_policy', :action => 'privacy_policy'
            help.help_terms_of_use '/help/terms_of_use', :action => 'terms_of_use'
        end
        
        # We want to start by showing the public bodies categories and search only
        map.with_options :controller => 'public_body' do |body|
            body.body_index "/body/", :action => "index"
        end
    end
end