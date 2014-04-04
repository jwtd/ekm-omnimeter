module EkmOmnimeter

  def self.version_string
    "ekm-omnimeter version #{EkmOmnimeter::VERSION::STRING}"
  end

  module VERSION #:nodoc:
    MAJOR = 0
    MINOR = 2
    PATCH = 4

    STRING = [MAJOR, MINOR, PATCH].join('.')
  end
end
