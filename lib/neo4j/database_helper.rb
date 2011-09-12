module Neo4j

  class DatabaseHelper
    
    def initialize(options={})
      @db = Neography::Rest.new(ENV['NEO4J_URL'] || 'http://localhost:7474')
      @subref_node = nil 
      
      @graph_name = options[:graphname] || Random.city.downcase.gsub(/\s/, '-')
      generate_graphname

      @db.create_node_index(@graph_name, "fulltext")
      @node_count = 0
      @edge_count = 0
    end
    
    def generate_graphname
      subref_node = @db.get_node_index("subreferences", "name", @graph_name)
      while not subref_node.nil?
        @graph_name += "#{1 + rand(10)}"
        subref_node = @db.get_node_index("subreferences", "name", @graph_name)
      end
      @graph_name
    end

    def graphname
      @graph_name
    end

    def create_subgraph
      if @subref_node.nil?
        @subref_node = @db.create_node(:name => @graph_name)
        @db.create_relationship(@graph_name, @db.get_root, @subref_node)
        @db.add_node_to_index("subreferences", "name", @graph_name, @subref_node)
      end
    end

    def subgraph(name)
      @subref_node = @db.get_node_index("subreferences", "name", name)
      @subref_node.first
    end
    
    def created_subgraph?
      !@subref_node.nil?
    end

    def create_node(node)
      if node[:created] && !node[:id].nil? && !node[:edges].empty?

        # create subgraph if not exist (create only once when the first node is created)
        create_subgraph
        
        # create node if not exist
        cr_node = @db.get_node_index(@graph_name, "id", node[:id].hash.to_s)
        if cr_node.nil?
          cr_node = @db.create_node("id" => node[:id].hash.to_s, "id_clear" => node[:id], "type" => node[:type])
          @node_count += 1
          @db.set_node_properties(@subref_node, { "node_count" => @node_count })
          @db.add_node_to_index(@graph_name, "id", node[:id].hash.to_s, cr_node)
          @db.add_node_to_index(@graph_name, "property", node[:id], cr_node)
          @db.create_relationship('root-ref', @subref_node, cr_node)
        else
          cr_node = cr_node.first
        end

        node[:data].each do |key, value|
          @db.set_node_properties(cr_node, { key => value }) unless value.blank?
          @db.add_node_to_index(@graph_name, "property", value, cr_node)
        end
        
        last_hash = node[:id].hash

        node[:edges].each do |cite|
          rel_node = @db.get_node_index(@graph_name, "id", cite[:id].hash.to_s)
          if !rel_node.nil?
            rel_node = rel_node.first
            @db.create_relationship("friends", cr_node, rel_node)
          else
            rel_node = @db.create_node("id" => cite[:id].hash.to_s, "id_clear" => cite[:id])
            @node_count += 1
            @db.set_node_properties(@subref_node, { "node_count" => @node_count })
            @db.add_node_to_index(@graph_name, "id", cite[:id].hash.to_s, rel_node)
            @db.add_node_to_index(@graph_name, "property", cite[:id], rel_node)
            @db.create_relationship('root-ref', @subref_node, rel_node)
            @db.create_relationship("friends", cr_node, rel_node)
          end
        end
        return true
      end
      return false
    end
    
  end
  
end
