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
end
