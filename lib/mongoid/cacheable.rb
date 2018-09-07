# encoding: utf-8
module Mongoid

  # Encapsulates behaviour around caching.
  #
  # @since 6.0.0
  module Cacheable
    extend ActiveSupport::Concern

    included do
      cattr_accessor :cache_timestamp_format, instance_writer: false
      cattr_accessor :cache_versioning, instance_writer: false
      self.cache_timestamp_format = :nsec
      self.cache_versioning = false
    end

    # Print out the cache key. This will append different values on the
    # plural model name.
    #
    # If new_record?     - will append /new
    # If not             - will append /id-updated_at.to_s(cache_timestamp_format)
    # Without updated_at - will append /id
    #
    # This is usually called insode a cache() block
    #
    # @example Returns the cache key
    #   document.cache_key
    #
    # @return [ String ] the string with or without updated_at
    #
    # @since 2.4.0
    def cache_key
      return "#{model_key}/new" if new_record?
      return "#{model_key}/#{id}-#{updated_at.utc.to_s(cache_timestamp_format)}" if do_or_do_not(:updated_at)
      "#{model_key}/#{id}"
    end

    # Returns a cache version that can be used together with the cache key to form
    # a recyclable caching scheme. By default, the #updated_at column is used for the
    # cache_version, but this method can be overwritten to return something else.
    #
    # Note, this method will return nil if Cacheable.cache_versioning is set to
    # +false+ (which it is by default until Rails 6.0).
    def cache_version
      if cache_versioning && timestamp = try(:updated_at)
        timestamp.utc.to_s(:usec)
      end
    end

    # Returns a cache key along with the version.
    def cache_key_with_version
      if version = cache_version
        "#{cache_key}-#{version}"
      else
        cache_key
      end
    end
  end
end
