require 'hash_validator'
class ParamsValidator

  def initialize(params)
    @params = params
  end

  def validate_both_ways_search_params
    rules = {
      "to" =>   'string',
      "from" => 'string',
      "departing" => /^\d+{4}-\d+{2}-\d+{2}$/,
      "returning" => /^\d+{4}-\d+{2}-\d+{2}$/
    }
    do_validate(HashValidator.validate(@params, rules))
  end

  def validate_one_way_search_params
    rules = {
      "to" =>   'string',
      "from" => 'string',
      "departing" => /^\d+{4}-\d+{2}-\d+{2}$/
    }
    do_validate(HashValidator.validate(@params, rules))
  end

  def success?
    validator.valid?
  end

  def do_validate(validator)
    if validator.valid?
      {success: true, params: @params, errors: {}}
    else
      {success: false, params: @params, errors: validator.errors}
    end
  end
end