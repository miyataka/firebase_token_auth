require 'google/apis/identitytoolkit_v3'

module FirebaseTokenAuth
  class AdminClient
    attr_accessor :service

    def initialize(configuration)
      @service = Google::Apis::IdentitytoolkitV3::IdentityToolkitService.new
      @service.authorization = configuration.auth
    end

    def get_account_info(params)
      request = Google::Apis::IdentitytoolkitV3::GetAccountInfoRequest.new(**params)
      service.get_account_info(request)
    end
  end
end
