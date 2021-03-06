require 'spec_helper'
require 'mock_helper'

RSpec.describe SoraGeocoding::Query do
  let!(:query) { Faker::Address.city }
  before { WebMock.enable! }

  let!(:geocoding_mock) { MockHttpResponse::Geocoding.new }
  let!(:yahoo_mock) { MockHttpResponse::YahooGeocoder.new }

  describe '.execute' do
    subject { SoraGeocoding::Query.new(query) }
    context 'when 200 status on Geocoding API' do
      let!(:expect_url) { "https://www.geocoding.jp/api/?q=#{query}" }

      before do
        WebMock.stub_request(:get, expect_url).to_return(
          body: geocoding_mock.success(query), status: 200
        )
        @exec = subject.send(:execute)
      end

      it 'is returned "geocoding" site.' do
        expect(@exec[:site]).to eq('geocoding')
      end

      it 'is returned latitude and longitude and google_maps tags.' do
        expect(@exec[:data].to_s).to include('lat', 'lng', 'google_maps')
        expect(@exec[:data].to_s).to match(%r{<lat>(\d+)\.(\d+)</lat>})
        expect(@exec[:data].to_s).to match(%r{<lng>(\d+)\.(\d+)</lng>})
      end
    end

    let!(:yahoo_appid) { 'aaaaa' }
    let!(:options) { { site: 'yahoo', yahoo_appid: yahoo_appid } }
    subject { SoraGeocoding::Query.new(query, options) }
    context 'when 200 status on Yahoo Geocoder API' do
      let!(:base_url) { 'https://map.yahooapis.jp/geocode/V1/geoCoder' }
      let!(:expect_url) { "#{base_url}?appid=#{yahoo_appid}&query=#{query}&results=1&detail=full&output=xml" }

      before do
        WebMock.stub_request(:get, expect_url).to_return(
          body: yahoo_mock.success(query), status: 200
        )
        @exec = subject.send(:execute)
      end

      it 'is returned "yahoo" site.' do
        expect(@exec[:site]).to eq('yahoo')
      end

      it 'is returned Status and Coordinates tags.' do
        expect(@exec[:data].to_s).to include('Status', 'Coordinates')
        expect(@exec[:data].to_s).to match(%r{<Status>200</Status>})
        expect(@exec[:data].to_s).to match(%r{<Coordinates>(\d+)\.(\d+),(\d+)\.(\d+)</Coordinates>})
      end
    end
  end
end
