# frozen_string_literal: true

require 'bundler/setup'
Bundler.require(:default)

TOKEN = ENV.fetch('TOKEN_TG')

Telegram::Bot::Client.run(TOKEN) do |bot|
  puts 'bot initialized :)'
  USRLIST = 'users.json'
  threads = []
  chtID = nil
  File.open(USRLIST, 'w') { |f| f.puts '{}' } unless File.exist?(USRLIST)
  users = JSON.parse(File.read(USRLIST))

  def show_users(users)
    if users.size.zero?
      print "there are no chats\npress enter to refresh list\n"
    else
      print "#{users.each_key.map { |usrname| usrname }}\n"
    end
  end

  reading = Thread.new do
    bot.listen do |message|
      case message.text
      when '/start'
        bot.api.send_message(chat_id: message.chat.id, text: "Hello, #{message.from.first_name}")

        users[message.from.username] = message.from.id
        File.open(USRLIST, 'w') do |file|
          file.puts(JSON.generate(users))
        end

        if chtID.nil? && !users.key?(message.from.id)
          puts "\nadded new user."
          print "#{users.each_key.map { |usrname| usrname }}\n"
        end
      when '/stop'
        bot.api.send_message(chat_id: message.chat.id, text: "Bye, #{message.from.first_name}")
      end

      if chtID == message.chat.id

        msgTime = Time.at(message.date)

        msgHour = msgTime.hour
        msgMin = msgTime.min

        puts format("[%02d:%02d] #{message.from.first_name} (@#{message.from.username}) > #{message.text}", msgHour,
                    msgMin)
      end
    end
  end
  threads << reading

  sending = Thread.new do
    loop do
      if chtID.nil?
        puts 'choose username'
        show_users(users)
        user = gets.chomp

        until users.key?(user)
          puts 'invalid username. write again. . .'
          show_users(users)
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

  threads.each(&:join)
end
