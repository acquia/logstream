require 'faye/websocket'
require 'logger'
require 'json'

module Logstream
  class Client
    def initialize(opts = {})
      opts = { 
        :logger => Logger.new(STDOUT),
        :log_prefix => '',
        :shows => {},
        :hides => {},
        :columns => [ 'text' ],
        :no_color => false,
      }.merge(opts)
      @opts = opts
      @columns = {
        :type => "%-15s",
        :disp_time => "%s",
        :server => "%-8s",
        :text => "%s",
      }
    end

    def run(url, connect_message)
      EM.run do
        # puts "DEBUG: #{url}"
        ws = Faye::WebSocket::Client.new(url)
        ws.on :open do
          # puts "DEBUG: #{connect_message.inspect}"
          ws.send(connect_message)
        end
        ws.on :message do |body,type|
          # puts "DEBUG: #{body.data}"
          msg = JSON.parse(body.data)
          case msg['cmd']
          when 'success'
            color('logtailor-error', msg['code']) do
              # puts "#{msg.inspect}"
            end
          when 'error'
            color('logtailor-error', msg['code']) do
              puts "#{msg.inspect}"
            end
            ws.close
            EM.stop
          when 'available'
            send_msg(ws, { 'cmd' => 'enable', 'type' => msg['type'], 'server' => msg['server'] })
          when 'line'
            next unless msg.all? { |k,v| @opts[:shows][k].nil? || v =~ shows[k] }
            next if msg.any? { |k,v| @opts[:hides][k] && v =~ hides[k] }
            p = ''
            color(msg['log_type'], msg['http_status']) do
              @opts[:columns].each do |column|
                print("#{p}#{@columns[column.to_sym] || '%s'}" % [ msg[column.to_s] ])
                p = ' '
              end
            end
            puts
          end
        end
        ws.on :close do
          @opts[:logger].info "#{@opts[:log_prefix]}: connection closed"
          ws.close
          EM.stop
        end
        ws.on :error do |error|
          @opts[:logger].info "#{@opts[:log_prefix]}: error: #{error.message}"
          ws.close
          EM.stop
        end
      end
    rescue Interrupt
      # exit cleanly
    end

    def send_msg(ws, msg)
      ws.send(msg.to_json)
    end

    GREEN = '32;1'
    RED = '31;1'
    YELLOW = '33;1'
    BLUE = '34;1'
    LOG_TYPE_COLORS = {
      'apache-request' => {
        /^5/ => RED,
        /^4/ => YELLOW,
        /^[123]/ => GREEN,
      },
      'bal-access' => {
        /^5/ => RED,
        /^4/ => YELLOW,
        /^[123]/ => GREEN,
      },
      'apache-error' => RED,
      'php-error' => RED,
      'drupal-watchdog' => BLUE,
      'logtailor-error' => RED,
    }

    def color(type, status)
      color = LOG_TYPE_COLORS[type]
      if color.is_a? Hash
        color = color.find { |k,v| status.to_s =~ k }[1] rescue nil
      end
      color = nil if @opts[:no_color]
      begin
        print "\e[#{color}m" if color
        yield
      ensure
        print "\e[0m" if color
      end
    end
  end
end
