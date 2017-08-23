#
# PowerUSB controller.
#
# Copyright (C) 2015, Kenneth W. Hilton, all rights reserved.
#
# This code is protected by trade secret law and its contents
# shall not be disclosed with written permission of its owner.
#

OSX = "osx"
WIN = "windows"
PLATFORM = OSX

require 'Win32API' if PLATFORM.eql?(WIN)
require 'timeout'

DEBUG = true
INFO = true


class PowerUSB

	@@SIMULATE_IT = false
	@@DURATION = 120.0
	@@TEN = 10
	@@MODES = 10
	@@SIMMER = [0, 2, 5, 6]
	@@BOIL = [1, 3, 4, 7, 8, 9]
	if PLATFORM.eql?(WIN)
		@@STOP_CMD = "c:\\etc\\PwrUsbCmd 0 0 0 > null"
		@@OFF_CMD = "c:\\etc\\PwrUsbCmd 0 1 0 > null"
		@@ON_CMD = "c:\\etc\\PwrUsbCmd 1 0 0 > null"
	else
		@@STOP_CMD = "./pwrusbcmd 0 0 0 > null"
		@@OFF_CMD = "./pwrusbcmd 0 1 0 > null"
		@@ON_CMD = "./pwrusbcmd 1 0 0 > null"
	end
	@@PAUSE = 30.0

	def initialize
		stop
		srand(Time.now.to_i)
	end
	
	def on duration = 0
		details = duration > 0 ? " for #{duration} seconds..." : ""
		puts "\n\tOn#{details}\n" if INFO
		system @@ON_CMD
		sleep duration
	end

	def off duration = 0
		details = duration > 0 ? " for #{duration} seconds..." : ""
		puts "\n\tOff#{details}\n" if INFO
		system @@OFF_CMD
		sleep duration
	end
	
	def stop
		puts "\n\tStop all\n" if INFO
		system @@STOP_CMD
	end
	
	def aggitate how
	
		puts "Aggitating: #{how}\n" if DEBUG
		modes = []
		case how ? how.downcase : ""
		when "simmer"
			modes = @@SIMMER
		when "boil"
			modes = @@BOIL
		when "0", "1", "2", "3", "4", "5", "6", "7", "8", "9"
			modes = [how.to_i]
		else
			modes = (0...@@MODES).to_a
		end
		
		lastMode = -1

		while true

			# Shuffle the modes until the first "new" mode != the last mode we just ran
			if modes.length > 1
				begin
					modes.shuffle!
				end until modes[0] != lastMode
				lastMode = modes.last
				puts "lastMode: #{@lastMode}" if DEBUG
			end
			
			
			puts modes.to_s if DEBUG
			
			modes.each do |mode|
			
				sleep 1 if @@SIMULATE_IT
				timeThen = Time.now
				
				begin
				
					Timeout.timeout(@@DURATION) {
					
						case mode
						when 0
							min = 5
							puts "Random on, random off (minimum #{min} secs)\n" if INFO || DEBUG
							next if @@SIMULATE_IT
							while ((Time.now - timeThen) < @@DURATION)
								s = min + rand(@@TEN)
								on(s)
								s = min + rand(@@TEN)
								off(s)
							end
							
						when 1
							puts "Pulse: 3 short, 1 Longer" if INFO || DEBUG
							next if @@SIMULATE_IT
							short = 1
							while ((Time.now - timeThen) < @@DURATION)
								long = 5 + rand(5)
								3.times {
									on(short)
									off(short)
								}
								on(long)
								off(short)
							end
							
						when 2
							puts "Pulse: escalating on/off 1...10 seconds" if INFO || DEBUG
							next if @@SIMULATE_IT
							while ((Time.now - timeThen) < @@DURATION)
								@@TEN.times { |n|
									on(n + 1)
									off(n + 1)
								}
							end
							
						when 3
							puts "Pulse: escalating on 1...10 seconds, off 2 seconds" if INFO || DEBUG
							next if @@SIMULATE_IT
							off = 2
							while ((Time.now - timeThen) < @@DURATION)
								@@TEN.times { |n|
									on(n + 1)
									off(off)
								}
							end
							
						when 4
							long = 10
							short = 3
							puts "On #{long} seconds, off #{short} seconds" if INFO || DEBUG
							next if @@SIMULATE_IT
							while ((Time.now - timeThen) < @@DURATION)
								@@TEN.times { |n|
									on(long)
									off(short)
								}
							end
							
						when 5
							min = 5
							puts "Random on/off (minimum #{min} secs)\n" if INFO || DEBUG
							next if @@SIMULATE_IT
							while ((Time.now - timeThen) < @@DURATION)
								s = min + rand(@@TEN)
								on(s)
								off(s)
							end

						when 6
							puts "Pulse: short on, off 1 seconds" if INFO || DEBUG
							next if @@SIMULATE_IT
							off = 1
							on = 
							while ((Time.now - timeThen) < @@DURATION)
								on(1 + rand(4))
								off(1)
							end
							
						when 7
							puts "Pulse: on 1, off 1 seconds" if INFO || DEBUG
							next if @@SIMULATE_IT
							while ((Time.now - timeThen) < @@DURATION)
								on(1)
								off(1)
							end

						when 8
							puts "0n 20-30, off 5-10 seconds" if INFO || DEBUG
							next if @@SIMULATE_IT
							while ((Time.now - timeThen) < @@DURATION)
								on(20 + rand(11))
								off(5 + rand(6))
							end

						when 9
							puts "Cross over: 9 off 1 on, 8 off 2 on, 7 off 3 on..." if INFO || DEBUG
							next if @@SIMULATE_IT
							while ((Time.now - timeThen) < @@DURATION)
								@@TEN.times { |n|
									off(10 - (n + 1))
									on(n + 1)
								}
							end
						else
							puts "Unknown mode encountered." if INFO || DEBUG
						end # case
						
					} # timeout
				rescue Timeout::Error
					puts "Mode #{mode} timed out.  Continuing..."
				end
					
				stop
				
			end # modes.each
			
			puts "Pausing between modes (#{@@PAUSE})" if DEBUG
			sleep @@PAUSE
			
		end # while
		
	end # aggitate
	
	def ext max_duration
		puts "ext"
		d = 1
		while true
			puts "On #{d}..."
			on d
			f = d < 8 ? d : 8
			off f
			puts "On #{f}..."
			d *= 2
			d = max_duration if d >= max_duration
		end

	end # big0

	def biggie duration
		puts "biggie"
		d = duration
		while (d > 0)
			iters = duration / d
			iters.times {
				puts "On #{d/2}..."
				on d / 2
				puts "Off #{d/2}..."
				off d / 2
			}
			d /= 2
		end

		on
		
	end # big0
	
	def drip min, max, duration
		puts "Dripping..."
		d = 1;
		while true
			d = rand(duration)
			d = 1 if d < 1
			on d
			d = min + rand(max - min);
			off d
		end
	end

	def	rampup duration
		puts "Ramp Up #{duration}..."
		n = 1
		while true
			n.times do
				puts "On 1..." if DEBUG
				on 1
				puts "Off 1..." if DEBUG
				off 1
			end
			puts "On #{n}..." if DEBUG
			on n
			puts "Off #{n}" if DEBUG
			off n
			n += 1
			break if n >= duration
		end
	end
	
end # CV


class PowerUSBCLI

	@@MAXTIME = 3600
	
	@pusb = nil
	@workerThread = nil
	
	def gets
		if PLATFORM.eql?(WIN)
			@kbhit ||= Win32API.new("crtdll", "_kbhit", [], 'L')
			while @kbhit.Call <= 0
				sleep(0.1)
			end
		end
		STDIN.gets
	end
	
	def stopWorkerThread
		if @workerThread
			@workerThread.kill
			@workerThread = nil
		end
	end
	
	def run
	
		@pusb ||= PowerUSB.new
		
		startTime = Time.new
		
		puts "Starting at #{startTime.inspect}"
		
		begin
		
			Timeout.timeout(@@MAXTIME) {
			
				while true
				
					print "PUSB> "
					
					args = gets.chomp.split
					if DEBUG
						puts "Running command '#{args[0]}'\n" unless args.size == 0
					end
					
					case args[0]
					when "on", "o"
						puts "On" if DEBUG
						@pusb.on
						
					when "rampup", "r"
						puts "Rampup" if DEBUG
						@pusb.stop
						@workerThread = Thread.new do
							@pusb.rampup(30)
						end
						@pusb.stop
						
					when "drip", "d"
						puts "Drip" if DEBUG
						@pusb.stop
						@workerThread = Thread.new do
							@pusb.drip(10, 30, 5)
						end
						@pusb.stop
						
					when "climb", "c"
						puts "climb in #{args.length > 1 ? args[1].to_i : 0} seconds..." if DEBUG
						stopWorkerThread
						@pusb.stop
						@workerThread = Thread.new do
							@pusb.on(args.length > 1 ? args[1].to_i : 0)
						end
						@pusb.stop

					when "biggie", "b"
						puts "Biggie" if DEBUG
						stopWorkerThread
						@pusb.stop
						@workerThread = Thread.new do
							@pusb.biggie args.length > 1 ? args[1].to_i : 75
						end

					when "ext", "X"
						puts "Extreme" if DEBUG
						puts "1"
						stopWorkerThread
						puts "2"
						@pusb.stop
						@workerThread = Thread.new do
							puts "3"
							@pusb.ext args.length > 1 ? args[1].to_i : 32
							puts "4"
						end

					when "off", "f"
						puts "Off" if DEBUG
						stopWorkerThread
						@pusb.stop
						
					when "aggitate", "a"
						puts "Aggitate...\n" if DEBUG
						stopWorkerThread
						@pusb.stop
						@workerThread = Thread.new do
							@pusb.aggitate args.length > 1 ? args[1] : nil
						end
						
					when "quit", "q"
						puts "Quit" if DEBUG
						stopWorkerThread
						@pusb.stop
						return 0

					end #case
					
				end # while
				
			} # timeout
		rescue Timeout::Error
			puts "Deadman switch triggered.  Stopping all devices and terminating."
			@pusb.stop
		end

		endTime = Time.new
		puts "Ending at #{endTime.inspect} (#{endTime - startTime} seconds)."
		return 0
	end # run

end # CS

exit PowerUSBCLI.new.run

