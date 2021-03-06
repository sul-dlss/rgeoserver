require 'active_model'
require 'yaml'
require 'confstruct'
require 'restclient'
require 'nokogiri'
require 'time'

# RGeoServer is a Ruby client for the GeoServer RESTful Configuration interface.
module RGeoServer
  require 'rgeoserver/version'
  require 'rgeoserver/config'

  autoload :Catalog,              "rgeoserver/catalog"
  autoload :Coverage,             "rgeoserver/coverage"
  autoload :CoverageStore,        "rgeoserver/coveragestore"
  autoload :DataStore,            "rgeoserver/datastore"
  autoload :FeatureType,          "rgeoserver/featuretype"
  autoload :GeoServerUrlHelpers,  "rgeoserver/geoserver_url_helpers"
  autoload :Layer,                "rgeoserver/layer"
  autoload :LayerGroup,           "rgeoserver/layergroup"
  autoload :Namespace,            "rgeoserver/namespace"
  autoload :ResourceInfo,         "rgeoserver/resource"
  autoload :RestApiClient,        "rgeoserver/rest_api_client"
  autoload :Style,                "rgeoserver/style"
  autoload :WmsStore,             "rgeoserver/wmsstore"
  autoload :Workspace,            "rgeoserver/workspace"

  autoload :BoundingBox,          "rgeoserver/utils/boundingbox"
  autoload :Metadata,             "rgeoserver/utils/metadata"
  autoload :ShapefileInfo,        "rgeoserver/utils/shapefile_info"

  # @return [Catalog] the default GeoServer Catalog instance
  def self.catalog opts = nil, reload = false
    @@catalog ||= nil
    if reload || @@catalog.nil?
      @@catalog = RGeoServer::Catalog.new (opts.nil?? RGeoServer::Config[:geoserver] : opts)
    end
    @@catalog
  end

  class RGeoServerError < StandardError
  end

  class GeoServerInvalidRequest < RGeoServerError
  end
  
  class GeoServerArgumentError < RGeoServerError
  end

end
