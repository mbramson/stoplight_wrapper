RSpec.describe StoplightConnection do
  describe '.new' do
    let(:endpoint) { 'http://www.example.com' }
    let(:connection_options) { {} }
    subject(:conn) { StoplightConnection.new(endpoint, connection_options) }

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

    context 'when called with the redis option specified' do
      let(:connection_options) do
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

    describe 'request behavior' do
      it 'makes a request' do
        expect{ execute_request }.to_not raise_error
        expect(mocked_endpoint).to have_been_made.once
      end

      context 'when a path is specified' do
        let(:path) { 'resource_path' }
        it 'makes a request to the concatenated endpoint and path' do
          expect{ execute_request }.to_not raise_error
          expect(mocked_endpoint).to have_been_made.once
        end
      end
    end

    describe 'stoplight behavior' do
      let(:threshold) { 1 }
      let(:light_opts) { {threshold: threshold} }
      let(:connection_options) { {light_opts: light_opts} }

      context 'when the request fails' do
        let(:response_status) { 500 }

        it 'does not make a number of requests greater than the stoplight threshold' do
          expect{ execute_request }.to raise_error StoplightConnection::ResponseError
          expect{ connection.execute_request(verb, path, opts) }.to raise_error
          expect(mocked_endpoint).to have_been_made.once
        end
      end
    end
  end
end
