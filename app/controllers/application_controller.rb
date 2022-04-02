class ApplicationController < ActionController::Base
    before_action :check_aut

    def check_aut
        redirect_to login_path unless session[:login]
    end
end
