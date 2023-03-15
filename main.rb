require 'eventmachine'
require 'net-http2'
require 'json'

EM.run do
  def ssl_context
    certificate = File.read(File.expand_path("../voip_tabor.pem", __FILE__))
    begin
      ctx = OpenSSL::SSL::SSLContext.new
      begin
        p12 = OpenSSL::PKCS12.new(certificate)
        ctx.key = p12.key
        ctx.cert = p12.certificate
      rescue OpenSSL::PKCS12::PKCS12Error
        ctx.key = OpenSSL::PKey::RSA.new(certificate)
        ctx.cert = OpenSSL::X509::Certificate.new(certificate)
      end
      ctx
    end
  end

  client = NetHttp2::Client.new('https://api.push.apple.com:443', ssl_context: ssl_context, connect_timeout: 5)
  response = client.call(:post,
                         "/3/device/#{'7D3EC3C85F7EA7031D8FAC7220AAB73C0B265EE4E3FD76D0B6E963946A065E84'}",
                         headers: {
                           'apns-push-type' => 'voip',
                           'apns-priority' => 5,
                           'apns-topic' => 'ru.tabor.voip',
                           'apns-collapse-id' => 0
                         },
                         body: JSON.dump({:alert=>"Входящий звонок", :badge=>1, :sound=>nil, :data=>{:signals=>[{:type=>:call, :data=>{:type=>:offer, :data=>"", :call_status_data=>"0:0", :from_id=>0}}]}}).force_encoding(Encoding::BINARY),
                         timeout: 10)


  puts response.ok?      # => true
  puts response.status   # => '200'
  puts response.headers[':status'] == '200'  # => {":status"=>"200"}
  puts response.body     # => "A body"

  # close the connection
  client.close

  EM.stop
end