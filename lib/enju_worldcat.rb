require 'will_paginate'
module EnjuWorldcat
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    @@client = WCAPI::Client.new(:wskey => WORLDCAT_API_KEY)
    def enju_worldcat
      include EnjuWorldcat::InstanceMethods
    end

    def search_worldcat(options = {})
      options = {:format => 'atom', :page => 1, :per_page => 10}.merge(options)
      #client = WCAPI::Client.new(:wskey => WORLDCAT_API_KEY)
      if options[:page].to_i < 1
        options[:page] = 1
      end
      startrecord = options[:page] * options[:per_page]
      response = @@client.OpenSearch(:q => options[:query], :format => options[:format], :start => startrecord, :count => options[:per_page], :cformat => 'all')
    rescue
      nil
    end

    def search_worldcat_by_id(id, options = {:type => 'isbn'})
      @@client.GetRecord(:type => options[:type], :id => id).record
    end
  end
  
  module InstanceMethods
    @@client = WCAPI::Client.new(:wskey => WORLDCAT_API_KEY)
    def worldcat_record
      if self.oclc_number.present?
        @@client.GetRecord(:id => self.oclc_number).record
      else
        @@client.GetRecord(:type => 'isbn', :id => self.isbn).record
      end
    rescue
      nil
    end

    def worldcat_locations
    end

    def worldcat_citation
      @@client.GetCitation(:type => 'isbn', :id => self.isbn)
    end

    def xisbn_manifestations(options = {})
      page = options[:page] || 1
      per_page = options[:per_page] || 10
      total_entries = options[:total_entries]

      doc = REXML::Document.new open("http://xisbn.worldcat.org/webservices/xid/isbn/#{self.isbn}?method=getEditions&format=xml&fl=*")
      isbn_array = REXML::XPath.match(doc, '/rsp/isbn/')
      manifestations = []
      isbn_array.each do |isbn|
        manifestation = {}
        manifestation[:isbn] = isbn.text
        manifestation[:title] = isbn.attribute('title').to_s
        manifestation[:author] = isbn.attribute('author').to_s
        manifestation[:publisher] = isbn.attribute('publisher').to_s
        manifestation[:year] = isbn.attribute('year').to_s
        manifestation[:lccn] = isbn.attribute('lccn').to_s
        manifestations << manifestation if manifestation[:isbn] != self.isbn
      end
      WillPaginate::Collection.create(page, per_page, total_entries) do |pager|
        pager.total_entries = manifestations.size
        isbns = manifestations[(page - 1) * per_page, per_page]
        pager.replace isbns
      end
    end

  end
end
