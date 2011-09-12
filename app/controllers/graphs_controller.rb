require "#{Rails.root}/lib/neo4j/database_helper.rb"

class GraphsController < ApplicationController

  def index
    db = Neography::Rest.new(ENV['NEO4J_URL'] || 'http://localhost:7474')
    root = db.get_root
    @nodes = db.get_node_relationships(db.get_root)
  end

  def show
    db = Neo4j::DatabaseHelper.new
    node = db.subgraph(params[:id])
    @node_id = node['indexed'].split('/').last
  end

  def new
  end
  
  def create
    # beginning_time = Time.now
    graph_name = import_xml params
    # end_time = Time.now
    # puts "Time elapsed #{(end_time - beginning_time)} seconds"
    
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


    filename = File.basename(file.original_filename, ".xml")

    db = Neo4j::DatabaseHelper.new(:graphname => filename)

    puts "reading file... #{filename}"

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
              if reader.value? && reader.value != "..."
                node[:edges].push({:id => reader.value})
                cite_count += 1
              end
            end
          elsif node[:id].nil? && reader.name == id_element
            reader.read
            node[:id] = reader.value if reader.value?
          else
            property = reader.name
            reader.read
            if reader.node_type == Nokogiri::XML::Node::TEXT_NODE
              if reader.value? && reader.value != "..."
                node[:data][property.to_sym] = reader.value
              end
            end
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
