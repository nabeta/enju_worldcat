require "rtranslate"

module WorldcatController
  def self.included(base)
    base.send :include, ClassMethods
  end

  module ClassMethods
    #@@client = WCAPI::Client.new(:wskey => WORLDCAT_API_KEY)
    def translate_worldcat(search_options, translate_from = I18n.locale, translate_into = 'English', translate_method = 'google')
      if translate_method == 'mecab'
        # romanize
        query = Kakasi::kakasi('-Ha -Ka -Ja -Ea -ka', NKF::nkf('-e', search_options[:query].wakati.yomi))
      else
        query = Translate.t(search_options[:query], translate_from, translate_into)
      end
      self.search_worldcat(:query => query, :page => search_options[:page], :per_page => search_options[:per_page])
    end
  end
end
