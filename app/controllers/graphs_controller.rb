require "#{Rails.root}/lib/neo4j/database_helper.rb"

class GraphsController < ApplicationController

  def index
    db = Neography::Rest.new(Rails.application.config.neo4j_url)
    root = db.get_root
    @nodes = db.get_node_relationships(db.get_root)
  end

  def show
    puts "REST URL: #{Rails.application.config.neo4j_rest_url}"
    db = Neo4j::DatabaseHelper.new
    node = db.subgraph(params[:id])
    @node_id = node['indexed'].split('/').last
  end

  def new
  end
  
  def create
    graph_name = import_xml params
    
    unless graph_name.nil?
      redirect_to graph_path(graph_name)
    else
      flash[:error] = "Sorry, an error occurred! Please check your data below."
      render 'new'
    end
  end


  private
  
  def import_xml(params)

    file = params[:file]
    return nil if file.blank?
    
    id_element = params[:'id-element'].blank? ?  'self.id' : params[:'id-element']
    ref_element = params[:'ref-element'].blank? ? 'ref' : params[:'ref-element']

    db = Neo4j::DatabaseHelper.new(:generate_graphname => true)

    puts "reading file..."

    reader = Nokogiri::XML::Reader(params[:file]) { |config|
      config.dtdload.dtdattr
    }

    steps = 0
    last_cite = false

    node = {:created => false}

    node_count = 0
    cite_count = 0

    last_hash = nil


    begin
      while reader.read      
        if reader.depth == 1 && reader.node_type == Nokogiri::XML::Node::ELEMENT_NODE
          if db.create_node(node)
            node_count += 1
          end

          # create new node
          node = {}
          node[:created] = true
          node[:type] = reader.name
          # self.id or child element with id
          node[:id] = reader.attribute(id_element.split('.')[1]) if id_element.starts_with?("self.")
          node[:edges] = []
          node[:data] = {}
        end

        if node[:created] && reader.depth == 2 && reader.node_type == Nokogiri::XML::Node::ELEMENT_NODE
          if reader.name == ref_element
            reader.read
            if reader.node_type == Nokogiri::XML::Node::TEXT_NODE
              if !reader.value.empty? && reader.value != "..."          
                node[:edges].push({:id => reader.value})
                cite_count += 1
              end
            end
          elsif node[:id].nil? && reader.name == id_element
            reader.read
            node[:id] = reader.value if reader.value?
          elsif reader.name == params[:'title-element']
            reader.read
            node[:data][:title] = reader.value if reader.value?
          elsif reader.name == params[:'description-element']
            reader.read
            node[:data][:description] = reader.value if reader.value?
          end          
        end

        steps += 1

      #  break if steps > 10000
      end
    rescue Exception
      return nil
    end

    if db.create_node(node)
      node_count += 1
    end

    puts "Nodes: #{node_count}"
    puts "edges: #{cite_count}"
    
    return db.created_subgraph? ? db.graphname : nil
  end
  
end
