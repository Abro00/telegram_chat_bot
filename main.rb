require 'bundler/setup'
require 'telegram/bot'
require 'json'
require './constants'
Bundler.require(:default)

Telegram::Bot::Client.run(TOKEN) do |bot|
  puts "bot initialized :)"
  threads = []
  chtID = nil
  
  reading = Thread.new do
    bot.listen do |message|

      case message.text
      when '/start'
        bot.api.send_message(chat_id: message.chat.id, text: "Hello, #{message.from.first_name}")
      when '/stop'
        bot.api.send_message(chat_id: message.chat.id, text: "Bye, #{message.from.first_name}")
      end
      
      chtID = message.chat.id
      puts "#{message.text}"
    end
  end
  threads << reading


  sending = Thread.new do
    while true
      reply = gets.chomp
      bot.api.send_message(chat_id: chtID, text: "#{reply}")
      puts "msg sent!"
    end
  end
  threads << sending

  threads.each { |thr| thr.join }
end