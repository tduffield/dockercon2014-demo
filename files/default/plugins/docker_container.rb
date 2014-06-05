require 'net/http'
require 'socket'
require 'docker'

class String
  def underscore
    self.gsub(/::/, '/').
    gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
    gsub(/([a-z\d])([A-Z])/,'\1_\2').
    tr("-", "_").
    downcase
  end
end

module DockerContainerMetadata

  DOCKER_METADATA_ADDR = "unix:///var/run/docker.sock" unless defined?(DOCKER_METADATA_ADDR)

  ##
  # Test connection to Docker Remote API socket
  #
  def can_metadata_connect?
    !!Docker.version
  end

  ##
  # Is there a container in the API that matches the current node?
  #
  def can_find_container?
    !!Docker::Container.get(container_id)
  end

  ##
  # Determine the name of the container by referencing the hostname
  #
  def container_id
    shell_out("hostname").stdout.strip
  end

  def fetch_metadata
    return Docker::Container.get(container_id).json
  end

  ##
  # Submit API request
  #
  def request(uri)
    socket = Net::BufferedIO.new(UNIXSocket.new(DOCKER_METADATA_ADDR))
    request = Net::HTTP::Get.new(uri)
    request.exec(socket, "1.1", uri)

    begin
      response = Net::HTTPResponse.read_new(socket)
    end while response.kind_of?(Net::HTTPContinue)
    response.reading_body(socket, request.response_body_permitted?) {}

    puts response.body
    
    return {
      :body => response.body,
      :code => response.code
    }
  end
end 

Ohai.plugin(:DockerContainer) do
  include DockerContainerMetadata

  provides "docker_container"

  def looks_like_docker?
    hint?('docker_container') || can_metadata_connect? && can_find_container?
  end

  ##
  # The format of the data is collection is the inspect API
  # http://docs.docker.io/reference/api/docker_remote_api_v1.11/#inspect-a-container
  #
  collect_data do
    metadata_from_hints = hint?('docker_container')

    if looks_like_docker?
      Ohai::Log.debug("looks_like_docker? == true")
      docker_container Mash.new

      if metadata_from_hints
        Ohai::Log.debug("docker_container hints present")
        metadata_from_hints.each { |k,v| docker_container[k] = v }
      end
      container = Docker::Container.get(container_id).json

      container.each { |k,v| docker_container[k] = v }
    else
      Ohai::Log.debug("looks_like_docker? == false")
      false
    end
  end
end

