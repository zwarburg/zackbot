require 'csv'

class Helper
  def self.read_env_vars
    vars = CSV.read('vars.csv')
    vars.each do |var, value|
      ENV[var] = value
    end
  end
end
