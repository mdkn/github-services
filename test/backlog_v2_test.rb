require File.expand_path('../helper', __FILE__)

class BacklogV2Test < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_for_comment
    @stubs.post "/api/v2/issues/DORA-1/comments" do |env|
      form = Faraday::Utils.parse_query(env[:body])
      assert_match "pushed to master", form['content']
      assert_match "comment test", form['content']
      [200, {}, '{ "access_token": "TestToken" }']
    end
    svc = service(:push, {'base_url' => 'https://demo.backlog.jp', 'api_key' => '12345'}, payload_for_comment)
    svc.receive_push
  end

  def payload_for_comment
    {
      'ref'        => 'refs/heads/master',
      'compare'    => 'https://github.com/dragon3/github-services/compare/06f63b43050935962f84fe54473a7c5de7977325...06f63b43050935962f84fe54473a7c5de7977326',
      'pusher'     => { 'name' => 'mdkn', },
      'commits'    => [
        {'id' => 1, 'message' => 'comment test DORA-1'}
      ],
      'repository' => {'name' => 'mdkn/github-services'},
    }
  end

  def test_for_resolved
    @stubs.post "/api/v2/issues/DORA-2" do |env|
      form = Faraday::Utils.parse_query(env[:body])
      assert_match "pushed to develop at", form['comment']
      assert_match "fix test", form['comment']
      assert_equal "3", form['status']
      [200, {}, '{ "access_token": "TestToken" }']
    end
    svc = service(:push, {'base_url' => 'https://demo.backlog.jp', 'api_key' => '12345'}, payload_for_resolved)
    svc.receive_push
  end

  def payload_for_resolved
    {
      'ref'        => 'refs/heads/develop',
      'compare'    => 'https://github.com/dragon3/github-services/compare/06f63b43050935962f84fe54473a7c5de7977325...06f63b43050935962f84fe54473a7c5de7977326',
      'pusher'     => { 'name' => 'mdkn', },
      'commits'    => [
        {'id' => 2, 'message' => 'fix test DORA-2 #fix'}
      ],
      'repository' => {'name' => 'mdkn/github-services'},
    }
  end

  def test_for_close
    @stubs.post "/api/v2/issues/DORA-3" do |env|
      form = Faraday::Utils.parse_query(env[:body])
      assert_match "pushed to develop at", form['comment']
      assert_match "close test", form['comment']
      assert_equal "4", form['status']
      [200, {}, '{ "access_token": "TestToken" }']
    end
    svc = service(:push, {'base_url' => 'https://demo.backlog.jp', 'api_key' => '12345'}, payload_for_closed)
    svc.receive_push
  end

  def payload_for_closed
    {
      'ref'        => 'refs/heads/develop',
      'compare'    => 'https://github.com/dragon3/github-services/compare/06f63b43050935962f84fe54473a7c5de7977325...06f63b43050935962f84fe54473a7c5de7977326',
      'pusher'     => { 'name' => 'mdkn', },
      'commits'    => [
        {'id' => 2, 'message' => 'close test DORA-3 #close'}
      ],
      'repository' => {'name' => 'mdkn/github-services'},
    }
  end

  def service(*args)
    super Service::BacklogV2, *args
  end
end
