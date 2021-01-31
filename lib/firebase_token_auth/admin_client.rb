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

    def update_existing_account(uid, attributes)
      update_params = { local_id: uid }.merge!(permit_attributes(attributes))
      request = Google::Apis::IdentitytoolkitV3::SetAccountInfoRequest.new(**update_params)
      service.set_account_info(request)
    end

    private

      def permit_attributes(attr_hash)
        permit_keys = %i[disabled display_name email email_verified password phone_number photo_url multi_factor]
        attr_hash.select { |k, _v| permit_keys.include?(k) }
      end
  end
end
