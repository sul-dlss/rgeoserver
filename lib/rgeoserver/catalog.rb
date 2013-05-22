module RGeoServer
  # This class represents the main class of the data model, and provides all REST APIs to GeoServer.
  # Refer to
  # - http://geoserver.org/display/GEOS/Catalog+Design
  # - http://docs.geoserver.org/stable/en/user/rest/api/

  class Catalog
    include RGeoServer::RestApiClient

    attr_reader :config

    # @param [OrderedHash] options, if nil, uses RGeoServer::Config[:geoserver] loaded from config/$RGEOSERVER_CONFIG or config/defaults.yml
    # @option options [String] :url
    # @option options [String] :user
    # @option options [String] :password
    def initialize options = nil
      @config = options || RGeoServer::Config[:geoserver]
      raise ArgumentError.new("Catalog: Requires :url option") unless @config.include?(:url)
    end

    def to_s
      "Catalog: #{@config[:url]}"
    end

    def headers format = :xml
      sym = :xml || format.to_sym
      {:accept => sym, :content_type=> sym}
    end

    #== Resources

    # Shortcut to ResourceInfo.list to this catalog. See ResourceInfo#list
    # @param [RGeoServer::ResourceInfo.class] klass
    # @param [RGeoServer::Catalog] catalog
    # @param [Array<String>] names
    # @param [Hash] options
    # @param [bool] check_remote if already exists in catalog and cache it
    # @yield [RGeoServer::ResourceInfo]
    def list klass, names, options, check_remote = false,  &block
      ResourceInfo.list klass, self, names, options, check_remote, &block
    end

    #= Workspaces

    # List of available workspaces
    # @return [Array<RGeoServer::Workspace>]
    def get_workspaces &block
      response = self.search :workspaces => nil
      doc = Nokogiri::XML(response)
      workspaces = doc.xpath(Workspace.root_xpath).collect{|w| w.text.to_s }
      list Workspace, workspaces, {}, &block
    end

    # @param ws [String] workspace name
    # @return [RGeoServer::Workspace]
    def get_workspace name
      response = self.search :workspaces => name
      doc = Nokogiri::XML(response)
      raise ArgumentError, "Cannot find workspace #{name}" unless doc.at_xpath(Workspace.member_xpath)
      return Workspace.new self, name
    end

    # @return [RGeoServer::Workspace] get_workspace('default')
    def get_default_workspace
      get_workspace 'default'
    end

    # Assign default workspace
    # @param [String] workspace name
    def set_default_workspace workspace
      raise TypeError, "Workspace name must be a string" unless workspace.instance_of? String
      dws = Workspace.new self, :name => 'default'
      dws.name = workspace # This creates a new workspace if name is new
      dws.save
      dws
    end

    # @deprecated see RGeoServer::Workspace
    # @param [String] store
    # @param [String] workspace
    def reassign_workspace store, workspace
      raise NotImplementedError
    end

    #= Layers

    # List of available layers
    # @return [Array<RGeoServer::Layer>]
    def get_layers options = {}, &block
      response = self.search :layers => nil
      doc = Nokogiri::XML(response)
      workspace_name = Workspace === options[:workspace] ? options[:workspace].name : options[:workspace]
      layer_nodes = doc.xpath(Layer.root_xpath).collect{|l| l.text.to_s }
      layers = list(Layer, layer_nodes, {}, &block)
      layers = layers.find_all { |layer| layer.workspace.name == workspace_name } if options[:workspace]
      layers
    end

    # @param [String] layer name
    # @return [RGeoServer::Layer]
    def get_layer layer
      response = self.search :layers => layer
      doc = Nokogiri::XML(response)
      name = doc.at_xpath("#{Layer.member_xpath}/name/text()").to_s
      return Layer.new self, :name => name
    end

    #= LayerGroups

    # List of available layer groups
    # @return [Array<RGeoServer::LayerGroup>]
    def get_layergroups options = {}, &block
      response = unless options[:workspace]
                   self.search :layergroups => nil
                 else
                   self.search :workspaces => options[:workspace], :layergroups => nil
                 end
      doc = Nokogiri::XML(response)
      layer_groups = doc.xpath(LayerGroup.root_xpath).collect{|l| l.text.to_s }.map(&:strip)
      list LayerGroup, layer_groups, {workspace: options[:workspace]}, &block
    end

    # @param [String] layer group name
    # @return [RGeoServer::LayerGroup]
    def get_layergroup layergroup
      response = self.search :layergroups => layergroup
      doc = Nokogiri::XML(response)
      name = doc.at_xpath("#{LayerGroup.member_xpath}/name/text()").to_s
      return LayerGroup.new self, :name => name
    end

    #= Styles (SLD Style Layer Descriptor)

    # List of available styles
    # @return [Array<RGeoServer::Style>]
    def get_styles &block
      response = self.search :styles => nil
      doc = Nokogiri::XML(response)
      styles = doc.xpath(Style.root_xpath).collect{|l| l.text.to_s }
      list Style, styles, {}, &block
    end

    # @param [String] style name
    # @return [RGeoServer::Style]
    def get_style style
      response = self.search :styles => style
      doc = Nokogiri::XML(response)
      name = doc.at_xpath("#{Style.member_xpath}/name/text()").to_s
      return Style.new self, :name => name
    end


    #= Namespaces

    # List of available namespaces
    # @return [Array<RGeoServer::Namespace>]
    def get_namespaces
      raise NotImplementedError
    end

    # @return [RGeoServer::Namespace]
    def get_default_namespace
      response = self.search :namespaces => 'default'
      doc = Nokogiri::XML(response)
      name = doc.at_xpath("#{Namespace.member_xpath}/prefix/text()").to_s
      uri = doc.at_xpath("#{Namespace.member_xpath}/uri/text()").to_s
      return Namespace.new self, :name => name, :uri => uri
    end

    def set_default_namespace id, prefix, uri
      raise NotImplementedError
    end

    #= Data Stores (Vector datasets)

    # List of vector based spatial data
    # @param [String] workspace
    # @return [Array<RGeoServer::DataStore>]
    def get_data_stores workspace = nil
      ws = workspace.nil?? get_workspaces : [get_workspace(workspace)]
      ws.map { |w| w.data_stores }.flatten
    end

    # @param [String] workspace
    # @param [String] datastore
    # @return [RGeoServer::DataStore]
    def get_data_store workspace, datastore
      response = self.search({:workspaces => workspace, :datastores => datastore})
      doc = Nokogiri::XML(response)
      name = doc.at_xpath('/dataStore/name')
      return DataStore.new self, :workspace => workspace, :name => name.text
    end

    # List of feature types
    # @param [String] workspace
    # @param [String] datastore
    # @return [Array<RGeoServer::FeatureType>]
    def get_feature_types workspace, datastore
      raise NotImplementedError
    end

    # @param [String] workspace
    # @param [String] datastore
    # @param [String] featuretype_id
    # @return [RGeoServer::FeatureType]
    def get_feature_type workspace, datastore, featuretype_id
      raise NotImplementedError
    end


    #= Coverages (Raster datasets)

    # List of coverage stores
    # @param [String] workspace
    # @return [Array<RGeoServer::CoverageStore>]
    def get_coverage_stores workspace = nil
      ws = workspace.nil?? get_workspaces : [get_workspace(workspace)]
      ws.map { |w| w.coverage_stores }.flatten
    end

    # @param [String] workspace
    # @param [String] coveragestore
    # @return [RGeoServer::CoverageStore]
    def get_coverage_store workspace, coveragestore
      get_workspace(workspace).coverage_stores.select {|k| k.name == coveragestore}
    end

    def get_coverage workspace, coverage_store, coverage
      c = Coverage.new self, :workspace => workspace, :coverage_store => coverage_store, :name => coverage
      return c.new?? nil : c
    end

    #= WMS Stores (Web Map Services)

    # List of WMS stores.
    # @param [String] workspace
    # @return [Array<RGeoServer::WmsStore>]
    def get_wms_stores workspace = nil
      ws = workspace.nil?? get_workspaces : [get_workspace(workspace)]
      ws.map { |w| w.wms_stores }.flatten
    end

    # @param [String] workspace
    # @param [String] wmsstore
    # @return [RGeoServer::WmsStore]
    def get_wms_store workspace, wmsstore
      get_workspace(workspace).wms_stores.select {|k| k.name == wmsstore}
    end

    #= Configuration reloading
    # Reloads the catalog and configuration from disk. This operation is used to reload GeoServer in cases where an external tool has modified the on disk configuration. This operation will also force GeoServer to drop any internal caches and reconnect to all data stores.
    def reload
      do_url 'reload', :put
    end

    #= Resource reset
    # Resets all store/raster/schema caches and starts fresh. This operation is used to force GeoServer to drop all caches and stores and reconnect fresh to each of them first time they are needed by a request. This is useful in case the stores themselves cache some information about the data structures they manage that changed in the meantime.
    def reset
      do_url 'reset', :put
    end

  end

end
