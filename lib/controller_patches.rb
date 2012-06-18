# Add a callback - to be executed before each request in development,
# and at startup in production - to patch existing app classes.
# Doing so in init/environment.rb wouldn't work in development, since
# classes are reloaded, but initialization is not run each time.
# See http://stackoverflow.com/questions/7072758/plugin-not-reloading-in-development-mode
#
require 'dispatcher'
Dispatcher.to_prepare do    
    # Front page needs some additional info
    GeneralController.class_eval do
        # Make sure it doesn't break if blog is not available 
        def frontpage
            begin
                blog
            rescue
                @blog_items = []
                @twitter_user = MySociety::Config.get('TWITTER_USERNAME', '')
            end
            
            begin
                @featured_requests = MySociety::Config.get("FRONTPAGE_FEATURED_REQUESTS", []).map{|i| InfoRequest.find(i)}
            rescue
                @featured_requests = []
            end
        end
    end

    PublicBodyController.class_eval do
        def index
            @public_bodies = PublicBody.paginate([], :page => 10)
            render :template => "public_body/list"
        end
    end
	
	UserController.class_eval do
		def signup
			work_out_post_redirect
			@request_from_foreign_country = country_from_ip != MySociety::Config.get('ISO_COUNTRY_CODE', 'GB')
			# Make the user and try to save it
			@user_signup = User.new(params[:user_signup])
			error = false
			if @request_from_foreign_country && !verify_recaptcha
				flash.now[:error] = _("There was an error with the words you entered, please try again.")
				error = true
			end
			if error || !@user_signup.valid? || params[:toc]!='1'
				@user_signup.errors.add(:toc, _("Por favor confirme que ha leído las Condiciones de Uso.")) if params[:toc]!='1'
				# Show the form
				render :action => 'sign'
			else
				user_alreadyexists = User.find_user_by_email(params[:user_signup][:email])
				if user_alreadyexists
					already_registered_mail user_alreadyexists
					return
				else
					# New unconfirmed user
					@user_signup.email_confirmed = false
					@user_signup.save!
					send_confirmation_mail @user_signup
					
					#UserController.signup modification
					if params[:newsletter]=='1' then registerInNewsletter(@user_signup) end
					#end
								
					return
				end
			end
		end
		
		def registerInNewsletter(user_created)	
		    require 'hominid'	
		    h = Hominid::API.new(MySociety::Config.get('MAILCHIMP_API_KEY', 'provide_your_mailchiimp_api_key'), {:secure => true, :timeout => 15})
			
			#http://apidocs.mailchimp.com/api/rtfm/listsubscribe.func.php
			list_id = MySociety::Config.get('MAILCHIMP_LIST_ID', 'provide_your_list_unique_id')
			emailToSubscribe = user_created.email
			mergeOptions = {
				:FNAME => user_created.name,
				:OPTIN_IP => request.remote_ip
			}
			email_type = 'html'
			double_optin = false #flag to control whether a double opt-in confirmation message is sent
			update_existing = false
			replace_interests = false
			send_welcome = false 
			RAILS_DEFAULT_LOGGER.info("\n antes de llamar a hominid")	
			response = h.list_subscribe(list_id, emailToSubscribe, mergeOptions, email_type,
				double_optin, 
				update_existing,
				replace_interests,
				send_welcome) 

			RAILS_DEFAULT_LOGGER.info("\n Registration for newsletter email:#{emailToSubscribe} successful: #{response}")		
		end
	end
	
end