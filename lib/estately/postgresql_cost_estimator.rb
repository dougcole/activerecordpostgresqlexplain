module Estately
  module PostgresqlCostEstimator
    def cost(sql_options = {}, cost_options = {})
      sql = 'explain '
      sql << 'analyze ' if analyze?(cost_options)
      sql << construct_finder_sql(sql_options)
      results = connection.execute(sql)
      build_results(results, cost_options)
    end

    protected
      def analyze?(options)
        options[:return] == :analyze || options[:return] == :all
      end
      def determine_cost(results)
        results[0][0].match(/cost=[0-9]+\.[0-9]+\.\.([0-9]+\.[0-9]+)/)[1].to_f
      end
      def determine_analyze(results)
        results[0][0].match(/actual time=[0-9]+\.[0-9]+\.\.([0-9]+\.[0-9]+)/)[1].to_f
      end
      def build_results(results, cost_options)
        case cost_options[:return]
        when :analyze
          determine_analyze(results)
        when :all
          a = determine_analyze(results)
          c = determine_cost(results)
          {:cost => c, :time => a, :ratio => c/a}
        else
          determine_cost(results)
        end
      end
  end
end
