require 'bundler/setup'
require 'telegram/bot'
require 'json'
require './constants'
Bundler.require(:default)

Telegram::Bot::Client.run(TOKEN) do |bot|
  puts 'bot initialized :)'
  threads = []
  File.open('users.json', 'w') { |f| f.puts '{}' } unless File.exist?('users.json')
  users = JSON.parse(File.read('users.json'))
  chtID = nil

  reading = Thread.new do
    bot.listen do |message|
      case message.text
      when '/start'
        bot.api.send_message(chat_id: message.chat.id, text: "Hello, #{message.from.first_name}")

        users[message.from.username] = message.from.id
        File.open('users.json', 'w') do |file|
          file.puts(JSON.generate(users))
        end

        if chtID == nil && !(users.key?(message.from.id))
          puts "\nadded new user."
          print "#{users.each_key.map { |usrname| usrname }}\n"
        end
      when '/stop'
        bot.api.send_message(chat_id: message.chat.id, text: "Bye, #{message.from.first_name}")
      end

      if chtID == message.chat.id
        msgHour = Time.at(message.date).hour
        msgMin = Time.at(message.date).min

        puts format("[%02d:%02d] #{message.from.first_name} (@#{message.from.username}) > #{message.text}", msgHour,
                    msgMin)
      end
    end
  end
  threads << reading

  sending = Thread.new do
    while true
      if chtID.nil?
        puts 'choose username'
        print "#{users.each_key.map { |usrname| usrname }}\n"
        user = gets.chomp
        
        while !(users.key?(user))
          puts "invalid username. write again. . ."
          print "#{users.each_key.map { |usrname| usrname }}\n"
          user = gets.chomp
        end
        chtID = users[user]

        bot.api.send_message(chat_id: chtID, text: 'now I listening you')
        puts "\n\|‾‾   bot entered chat with @#{users.key(chtID)}   ‾‾\|"
      else
        reply = gets.chomp
        if ['/leave', '/l'].include?(reply)
          bot.api.send_message(chat_id: chtID, text: 'now I leaving this chat')
          puts "\|__   bot leaved chat with @#{users.key(chtID)}    __\|\n\n"
          chtID = nil
        else
          bot.api.send_message(chat_id: chtID, text: reply.to_s)
        end
      end
    end
  end
  threads << sending

  threads.each { |thr| thr.join }
end
