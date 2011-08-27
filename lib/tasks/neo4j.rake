# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)



task :neo4j do

  puts "Start seeding..."
#populate the db
Neo4j::Transaction.run do

  nodes = []
  node = Neo4j::Node.new :name => "Testname0" 
  nodes.push node
  
  steps = 1
  begin
    
    node = nodes.shift

    numEdges = 3
    (1..3).each do |i|
      
      target_node = Neo4j::Node.new :name => "Testname#{steps*i}"
      nodes.push target_node
      node.outgoing(:likes) << target_node
    end
    steps += 1
  end unless nodes.empty? || steps >= 50
end

end

