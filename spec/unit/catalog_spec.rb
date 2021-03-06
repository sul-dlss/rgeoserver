require 'spec_helper'

describe RGeoServer::Catalog do
  it 'responds to API' do
    %w(
        config
        each_layer
        get_coverage
        get_coverage_store
        get_coverage_stores
        get_data_store
        get_data_stores
        get_default_namespace
        get_default_workspace
        get_layer
        get_layergroup
        get_layergroups
        get_style
        get_styles
        get_wms_store
        get_wms_stores
        get_workspace
        get_workspaces
        headers 
        reload
        reset
        set_default_workspace
      ).map(&:to_sym).each do |m|
      expect {
        fail "API is missing: #{m}" unless described_class.public_instance_methods.include?(m)
      }.not_to raise_error
    end
  end
end
