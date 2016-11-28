require 'spec_helper'

# TODO: It would be super cool if the oven gem could generate specs automatically
describe CF::UAA::Client do
  CLIENT_ID     = ENV.fetch('CLIENT_ID')
  CLIENT_SECRET = ENV.fetch('CLIENT_SECRET')
  CF_UAA_TARGET = ENV.fetch('CF_UAA_TARGET')
  REDIRECT_URI  = ENV.fetch('REDIRECT_URI')
  UAA_USERNAME  = ENV.fetch('UAA_USERNAME')
  UAA_PASSWORD  = ENV.fetch('UAA_PASSWORD')

  before :all do
    @client = CF::UAA.build_client(CF_UAA_TARGET, CLIENT_ID, CLIENT_SECRET)
  end

  describe '#post_token' do
    it 'calls GET /oauth/token with grant_type: client_credentials' do
      response = @client.post_token(grant_type: 'client_credentials', response_type: 'token')

      expect(response.code).to eq '200'
      expect(response.json[:access_token]).to be_kind_of(String)
      expect(response.json[:token_type]).to eq 'bearer'
      expect(response.json[:expires_in]).to be_kind_of(Integer)
    end

    it 'calls GET /oauth/token with grant_type: password' do
      body = {
        grant_type: 'password',
        response_type: 'token',
        username: UAA_USERNAME,
        password: UAA_PASSWORD
      }

      response = @client.post_token(body)

      expect(response.code).to eq '200'
      expect(response.json[:access_token]).to be_kind_of(String)
      expect(response.json[:token_type]).to eq 'bearer'
      expect(response.json[:expires_in]).to be_kind_of(Integer)
    end
  end

  describe '#authorize' do
    it 'calls GET /oauth/authorize' do
      response = @client.authorize(response_type: 'code')

      expect(response.code).to eq '302'
      expect(response.headers['location']).to eq([REDIRECT_URI])
    end
  end

  describe '#autologin' do
    it 'calls GET /autologin' do
      response = @client.autologin(username: UAA_USERNAME, password: UAA_PASSWORD)

      expect(response.code).to eq '200'
      expect(response.json.keys).to eq([:code, :path])
    end
  end

  context 'with client credentials' do
    before :all do
      body = {
        grant_type: 'client_credentials',
        response_type: 'token'
      }

      access_token = @client.create_token(body).json[:access_token]
      @client      = CF::UAA.build_client(CF_UAA_TARGET, CLIENT_ID, CLIENT_SECRET, access_token: access_token)
    end

    describe '#get_users' do
      it 'calls GET /Users' do
        response = @client.get_users

        expect(response.code).to eq '200'
      end

      it 'calls GET /Users with a filter option' do
        response = @client.get_users(query: { filter: %(email eq "#{UAA_USERNAME}") })

        expect(response.code).to eq '200'
        expect(response.json[:resources][0].keys).to eq([
          :id,
          :meta,
          :userName,
          :name,
          :emails,
          :groups,
          :approvals,
          :active,
          :verified,
          :origin,
          :zoneId,
          :passwordLastModified,
          :schemas
        ])
      end
    end

    describe '#post_user' do
      it 'calls POST /Users' do
        email = FFaker::Internet.email
        body  = {
          userName: email,
          password: FFaker::Internet.password,
          emails: [
            { value: email }
          ]
        }

        response = @client.post_user(body)

        expect(response.code).to eq '201'
        expect(response.json.keys).to eq([
          :id,
          :meta,
          :userName,
          :name,
          :emails,
          :groups,
          :approvals,
          :active,
          :verified,
          :origin,
          :zoneId,
          :passwordLastModified,
          :schemas
        ])
      end
    end
  end

  context "with a user's access token" do
    before :all do
      body = {
        grant_type: 'password',
        username: UAA_USERNAME,
        password: UAA_PASSWORD,
        response_type: 'token'
      }

      access_token = @client.create_token(body).json[:access_token]
      @client      = CF::UAA.build_client(CF_UAA_TARGET, CLIENT_ID, CLIENT_SECRET, access_token: access_token)
    end

    describe '#get_userinfo' do
      it 'calls GET /userinfo' do
        response = @client.get_userinfo

        expect(response.code).to eq '200'
        expect(response.json.keys).to eq([
          :user_id, :user_name, :given_name, :family_name, :email, :phone_number, :sub, :name
        ])
      end
    end

    describe '#get_user' do
      before do
        @user_id = @client.get_userinfo.json[:user_id]
      end

      it 'calls GET /Users/:id' do
        response = @client.get_user(@user_id)

        expect(response.code).to eq '200'
      end
    end
  end
end
