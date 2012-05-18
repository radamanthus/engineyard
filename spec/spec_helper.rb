if self.class.const_defined?(:EY_ROOT)
  raise "don't require the spec helper twice!"
end

if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start
end

EY_ROOT = File.expand_path("../..", __FILE__)
require 'rubygems'
require 'bundler/setup'
require 'escape'
require 'net/ssh'

# Bundled gems
require 'fakeweb'
require 'fakeweb_matcher'

require 'json'

# Engineyard gem
$LOAD_PATH.unshift(File.join(EY_ROOT, "lib"))
require 'engineyard'

require 'engineyard-cloud-client/test'

# Spec stuff
require 'rspec'
require 'tmpdir'
require 'yaml'
require 'pp'

Dir[File.join(EY_ROOT,'/spec/support/*.rb')].each do |helper|
  require helper
end

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  config.include SpecHelpers
  config.include SpecHelpers::IntegrationHelpers

  config.extend SpecHelpers::GitRepoHelpers
  config.extend SpecHelpers::Given
  config.extend SpecHelpers::Fixtures

  def clean_eyrc
    ENV['EYRC'] = File.join('/tmp','eyrc')
    if ENV['EYRC'] && File.exist?(ENV['EYRC'])
      File.unlink(ENV['EYRC'])
    end
  end

  config.before(:all) do
    clean_eyrc
    FakeWeb.allow_net_connect = false
    ENV["CLOUD_URL"] = nil
    ENV["NO_SSH"] = "true"
  end

  config.before(:each) do
    EY::CloudClient.default_endpoint!
  end
end

EY.define_git_repo("default") do |git_dir|
  system("echo 'source :gemcutter' > Gemfile")
  system("git add Gemfile")
  system("git commit -m 'initial commit' >/dev/null 2>&1")
end

shared_examples_for "integration" do
  use_git_repo('default')

  before(:all) do
    FakeWeb.allow_net_connect = true
    ENV['CLOUD_URL'] = EY::CloudClient::Test::FakeAwsm.uri
  end

  after(:all) do
    ENV.delete('CLOUD_URL')
    FakeWeb.allow_net_connect = false
  end
end
