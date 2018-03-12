RSpec.describe StoplightConnection do
  describe '.new' do
    let(:endpoint) { 'http://www.example.com' }
    let(:options) { {} }
    subject(:conn) { StoplightConnection.new(endpoint, options) }

    context 'when called without any options' do
      it 'can be created without error' do
        expect{ conn }.to_not raise_error
      end

      it 'sets the stoplight default data store to in-memory' do
        conn
        expect(Stoplight::Light.default_data_store)
          .to be_a(Stoplight::DataStore::Memory)
      end

      it 'sets the endpoint to what is passed in' do
        expect(conn.endpoint).to eq endpoint
      end
    end

    context 'when call with the redis option specified' do
      let(:options) do
        {
          redis: {'master_name' => 'testing-redis'}
        }
      end
      let(:redis) { double() }

      it 'sets the stoplight default data store to redis' do
        conn
        expect(Stoplight::Light.default_data_store)
          .to be_a(Stoplight::DataStore::Redis)
      end
    end
  end

  describe '#execute_request' do
    let(:endpoint) { 'http://www.example.com' }
    let(:connection) { StoplightConnection.new(endpoint) }
    let(:verb) { :get }
    let(:path) { '' }
    let(:opts) { {} }

    let(:stubbed_url) { "#{endpoint}/#{path}" }
    let(:response_body) { '' }
    let(:response_status) { 200 }

    subject(:execute_request) do
      connection.execute_request(verb, path, opts)
    end

    let!(:mocked_endpoint) do
      stub_request(verb, stubbed_url)
        .to_return(body: response_body, status: response_status)
    end

    it 'makes a request' do
      expect{ execute_request }.to_not raise_error
      expect(mocked_endpoint).to have_been_made.once
    end
  end
end
