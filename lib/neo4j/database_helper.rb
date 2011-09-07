module Neo4j

  class DatabaseHelper
    
    def initialize(options={})
      @db = Neography::Rest.new({:server => Rails.application.config.neo4j_host, 
                                 :port => Rails.application.config.neo4j_port, 
                                 :username => Rails.application.config.neo4j_username,
                                 :password => Rails.application.config.neo4j_password })

      @subref_node = nil
      generate_graphname if options[:generate_graphname]
    end
    
    def generate_graphname
      begin
        @graph_name = Random.city.downcase.gsub(/\s/, '-')
        subref_node = @db.get_node_index("subreferences", "name", @graph_name)
      end while not subref_node.nil?
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
          @db.add_node_to_index(@graph_name, "id", node[:id].hash.to_s, cr_node)
          @db.create_relationship('root-ref', @subref_node, cr_node)
        else
          cr_node = cr_node.first
        end
        @db.set_node_properties(cr_node, { "title" => node[:data][:title] }) unless node[:data][:title].blank?
        @db.set_node_properties(cr_node, { "description" => node[:data][:description] }) unless node[:data][:description].blank?
        
        last_hash = node[:id].hash

        node[:edges].each do |cite|
          rel_node = @db.get_node_index(@graph_name, "id", cite[:id].hash.to_s)
          if !rel_node.nil?
            rel_node = rel_node.first
            @db.create_relationship("friends", cr_node, rel_node)
          else
            rel_node = @db.create_node("id" => cite[:id].hash.to_s, "id_clear" => cite[:id])
            @db.add_node_to_index(@graph_name, "id", cite[:id].hash.to_s, rel_node)
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
