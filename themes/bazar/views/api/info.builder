xml.instruct!
xml.info do 
  xml.nombre @info[:nombre]
  xml.desc @info[:desc]
  xml.url @info[:url]
  xml.empresas @info[:empresas]
  xml.consultas @info[:consultas]
  xml.clusteractivos @info[:clusteractivos]
end