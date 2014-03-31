require 'json'
require 'cgi'
require 'open-uri'

module GoogleCSE
  class Query
    @@endpoint = 'https://www.googleapis.com/customsearch/v1'
    attr_accessor :params, :results, :info, :response, :current_index, :total, :per_page, :time, :corrected_query
  
    def initialize opts = {}
      opts.map {|k,v| send(:"#{k}=",v)}
    end
  
    def search_uri
      "#{@@endpoint}?#{params.map {|k,v|"#{k}=#{CGI.escape(v.to_s)}"}.join('&')}"
    end
  
    def fetch
      @response = JSON.parse(open(search_uri).read)
      parse_response!
      self
    end
  
    def fetch!
      fetch
      nil
    end
    
    def next
      if next?
        @params.merge!({:start => @next_page_params.first['startIndex']})
        fetch        
      end
    end
    
    def previous
      if previous?
        @params.merge!({:start => @prev_page_params.first['startIndex']})
        fetch
      end
    end
    
    def next?
      !(@next_page_params.nil? || @next_page_params.empty?)
    end
    
    def previous?
      !(@prev_page_params.nil? || @prev_page_params.empty?)
    end
    
    def page
      (current_index / per_page.to_f).ceil
    end
    
    def parse_response!
      total = @response['searchInformation']['totalResults']
      logger.info "total results : #{total}"
      if @response.has_key?('spelling')
        logger.info 'auto correct search results'
        @corrected_query = @response['spelling']['correctedQuery']
        logger.info "corrected query : #{@corrected_query}"
      end

      if total.to_i > 0 
        @results = @response['items'].map { |i| Result.new(i) }
        @next_page_params = @response['queries']['nextPage']
        @prev_page_params = @response['queries']['previousPage']
        @info = @response['searchInformation']
        @total = @info['totalResults'].to_i
        @time = @info['searchTime'].to_f
        @per_page = @response['queries']['request'].first['count'].to_i
        @current_index = @response['queries']['request'].first['startIndex'].to_i
      end
      
      nil
    end
  end
end