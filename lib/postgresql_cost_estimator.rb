module PostgresqlCostEstimator
  Estimates = [:cost, :time, :count, :cost_time_ratio]

  def cost(sql_options = {})
    estimate(:cost, sql_options)
  end

  def estimate(return_val, sql_options = {})
      sql = 'explain '
      sql << 'analyze ' if analyze?(return_val)
      sql << construct_finder_sql(sql_options)
      results = connection.execute(sql)
      build_results(results, return_val)
  end

  protected
  def analyze?(return_val)
      return_val == :time || return_val == :all
  end
  def determine_count(results)
      results[0][0].match(/rows=([0-9]+) /)[1].to_i
  end
  def determine_cost(results)
      results[0][0].match(/cost=[0-9]+\.[0-9]+\.\.([0-9]+\.[0-9]+)/)[1].to_f
  end
  def determine_time(results)
      results[0][0].match(/actual time=[0-9]+\.[0-9]+\.\.([0-9]+\.[0-9]+)/)[1].to_f
  end
  def determine_cost_time_ratio(results)
      determine_cost(results)/determine_time(results)
  end
  def build_results(results, return_val)
    if return_val == :all
      Estimates.inject({}) do|hash, estimate|
        hash[estimate] = send("determine_#{estimate}", results)
	hash
      end
    else
      raise "unknown estimate: #{return_val}" unless Estimates.include?(return_val)
      send("determine_#{return_val}", results)
    end
  end
end
