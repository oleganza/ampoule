#!/usr/bin/env ruby
require 'rubygems'
require 'open-uri'
require 'json'

def statuses_for(id)
  JSON.load(open("http://twitter.com/statuses/user_timeline/#{id}.json?count=40"))
end

def list_for_two(id1, id2)
  a = statuses_for(id1)
  b = statuses_for(id2)
  
  (a + b).map do |status|
    {
      "created_at"  => DateTime.parse(status["created_at"]),
      "screen_name" => status["user"]["screen_name"],
      "text"        => status["text"]
    }
  end.sort_by{|s| s["created_at"] }
end

def main(id1, id2)
  list = list_for_two(id1, id2)
  
  list.reverse!
  
  list.each do |status|
    puts %{#{status["screen_name"].rjust(15)}: #{status["text"]}}
  end
end

if !ARGV[0] || !ARGV[1]
  puts "Example: #{$0} alice bob"
else
  main(ARGV[0], ARGV[1])
end















__END__

Example:

$ ./twitter-discussions.rb  stevedekorte tuparev
       tuparev: @wilshipley perhaps it means there are no walls to protect you from the elements (and the viruses) :-)
       tuparev: @NSResponder also I read a statistics, that always high tax in US is followed by growth and low tax - with crash. Explain it please.
       tuparev: @NSResponder and could you explain why the majority there love their system?
  stevedekorte: @tuparev that's 98% of all dollar denominated assets effectively sucked into gov spending
  stevedekorte: @tuparev ex: the $ is worth less than 3% of it's value before the creation of the central bank
  stevedekorte: @tuparev though consumer inflation is one measure - a few percent compounded yearly quickly becomes an enormous sum
  stevedekorte: @tuparev but still there is debt financing (we also don't know how much of their debt is monetized by their central banks)
       tuparev: @stevedekorte Look at the Scandinavia countries. Low debt - fantastic gov-managed healthcare
  stevedekorte: @tuparev I'd also like to see an analysis of central bank monetized debt (the hidden tax of inflation) for these countries.
  stevedekorte: @tuparev see: http://bit.ly/sEo75
       tuparev: @stevedekorte google
       tuparev: @pilky yes, it was absolutely cool!
  stevedekorte: @tuparev reference?
       tuparev: @stevedekorte most are not debt funded. And if they are, you need to count the cost of not having universal health care - witch is huge!
  stevedekorte: @tuparev Which ones aren't debt funded (that is, sustainable)?
  stevedekorte: Hipsterism - the idea is that it's cool to wear ugly clothing as long as you know how ugly they are?
       tuparev: @stevedekorte it seams so. It works for most of the civilized world.
  stevedekorte: Bootlooter game: http://bit.ly/10yyL5
(wait for it...)
  stevedekorte: @tuparev More million dollar toilets (or the medical equivalent) will make it cheaper?
       tuparev: @stevedekorte yes, the problem is that is only 50% socialized indeed...
       tuparev: @stevedekorte are you from another planet? Just turn the TV...
  stevedekorte: @stevedekorte besides the inefficiency, the high costs are also the result of excessive government regulation of healthcare
  stevedekorte: @tuparev US healthcare is ~50% socialized, no surprises if it is inefficient
  stevedekorte: @tuparev Where did you pay for corp incompetence that didn't involve the government forcing you to?
       tuparev: @stevedekorte ... and while we are discussing in US more children are dying than in some african countries.
       tuparev: @stevedekorte because US private healthcare consumes 17% of the GDP and delivers third world quality....
       tuparev: @stevedekorte as far as I am aware this year only I paid 10x more for corporate incompetence than for government toilets.
       tuparev: @stevedekorte so, I will sue Exxon from the Netherlands. Wish me good luck...
  stevedekorte: @tuparev Or why I should believe people who claim that government run services are more efficient?
  stevedekorte: @tuparev Now can you answer how I avoid paying for that million dollar government toilet?
  stevedekorte: @tuparev For a few references on gov pollution, see  http://bit.ly/2JNgZJ
  stevedekorte: @tuparev You sue for property damage or have a property damage law that covers pollution.
       tuparev: @stevedekorte better find better arguments. Stockholm syndrome has nothing to do with this subject.
       tuparev: @stevedekorte such statements need proof. Statistics. And Mafia kills too...
       tuparev: @stevedekorte and what is my choice if in case of an accident get in the hands of incompetent private hospital?
  stevedekorte: @tuparev http://bit.ly/6KKos
       tuparev: @stevedekorte what is exactly my choice to cope with the pollution of a corp that pollutes the atmosphere somewhere far away?
  stevedekorte: @tuparev Also, governments are the largest of polluters and the ones dropping bombs on people.
       tuparev: @drewmccormack I had this just once. I thought it is a random not OF-related stuff
       tuparev: @stevedekorte Really? Private hospitals do not kill? Corps are not killing the entire planet with pollution?
