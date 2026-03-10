# frozen_string_literal: true

require "json"
require "test_helper"

class TestLambdaExpressions < Minitest::Spec
  make_my_diffs_pretty!

  TEST_CASES = JSON.load_file("test/lambda.json")

  describe "lambda expression" do
    TEST_CASES["tests"].each do |test_case|
      it test_case["name"] do
        if test_case["invalid"]
          assert_raises Exception do
            Expr.parse(test_case["expression"])
          end
        else
          _(Expr.render(test_case["expression"],
                        test_case["data"] || {})).must_equal(test_case["result"])
        end
      end
    end
  end
end
