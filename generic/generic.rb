# encoding: utf-8


module Generic
  class UnresolvedCase < StandardError
    def initialize(message = '??')
      super("Unresolved case: '#{message}'")
    end
  end
  class NoTemplatesFound < StandardError; end
  
  def parse_prev_next(text)
    "[[#{text}|#{text.match(/\((.*)\)/)[1]}]]"
  end
  def parse_housemates(params)
    (1..48).reverse_each do |i|
      return i if params["hm#{i}"]
    end
  end
  
  def parse_text(text)
    text.force_encoding('UTF-8')
    templates = text.scan(/(?=\{\{\s*(?:Infobox pulps character))(\{\{(?>[^{}]++|\g<1>)*}})/i).flatten
    raise Helper::NoTemplatesFound if templates.empty?
    # raise Helper::UnresolvedCase.new('More than 1 template') if templates.size > 1

    templates.each do |template|
      # template = templates.first
      old_template = template.dup
  
      template.gsub!(/<!--[\w\W]*?-->/,'')
      # template.gsub!(/\{\{flag\|(.*)\}\}/,'[[\1]]')
      params = Helper.parse_template(template)
      params.default = nil
      # Delete blank values
      params.reject!{|_k,v| v.empty?}
      
      
      # ['KanjiTitle', 'RomajiTitle'].each do |param|
      #   raise Helper::UnresolvedCase.new(param) if (params[param] && !params[param].empty?)
      # end
      #
      # puts params['hm1-stat'].inspect
      # raise Helper::UnresolvedCase.new('Winner is not actually winner') if (!params['hm1-stat'].nil? && !params['hm1-stat'].empty? && params['hm1-stat'].downcase != 'winner')
      # raise Helper::UnresolvedCase.new('Runner up is not actually runner-up') if (params['hm2-stat'].nil? || (params['hm2-stat'].downcase != 'runner' && params['hm2-stat'].downcase != 'runnerup'))
      # raise Helper::UnresolvedCase.new('Day not formatted properly') if (params['hm1-exit'].nil? || params['hm1-exit'].empty? || !params['hm1-exit'].match?(/day \d+/i))
      
      result = "{{Infobox comics character
| character_name = #{params['code_name']}
| image          = #{params['image']}
| imagesize      = #{params['imagesize']}
| caption        = #{params['caption']}
| alt            = #{params['alt']}
| publisher      = #{params['publisher']}
| debut          = #{params['debut']}
| first_series   = 
| first_episode  = 
| first_comic    = 
| creators       = #{params['creators']}
| voiced_by      = 
| based_on       = 
| alter_ego      = 
| full_name      =
| real_name      = #{params['real_name']}
| supports       = #{params['cast']}
| powers         = #{params['abilities']}
| addcharcat#    = 
}}"

      result.gsub!('<nowiki>', '')
      result.gsub!('</nowiki>', '')
      
      # This will strip un-used parmeters
      # result.gsub!(/\|.*\=\s*\n/, '')
  
      text.sub!(old_template, result)
    end
    text
  end
end
