require 'rubygems'
require 'mechanize'
require 'logger'
require 'yaml'

tr_log = Logger.new('travian.log')
tr_log.level = Logger::INFO

UA = ['Windows IE 6' ,'Windows Mozilla', 'Mac Safari' , 'Mac Mozilla' , 'Linux Mozilla', 'Linux Konqueror' ]

class TravianWorker
  def initialize()
    @tlog = Logger.new('travijan.log')
    @a = WWW::Mechanize.new { |agent|
      agent.user_agent_alias = UA[2]
    }
  end

  def login(username, password)
    @a.get('http://rs3.travian.com/login.php') do |page|
      #logging in
      @tlog.info "Logging in."
      main_page=page.form_with(:name=>'snd') do |form|
        form.fields[2].value=username
        form.fields[3].value=password
        sleep 1
      end.submit
    end
  end

  def select_city(city)
    city_page=@a.get 'http://rs3.travian.com/dorf1.php?newdid=' + city
    @tlog.info "Open ATL"    
  end

  def building(code)
      available=false
      build_page=@a.get("http://rs3.travian.com/build.php?id=" + code)
      sleep 1
      build_page.search("//a").each do |link|
        if link.inner_html =~ /\320\235\320\260\320\264\320\276\320\263/
          result_page=@a.click link
          @tlog.info "Building: " + code.to_s
          available=true
        end
      end
      return available
  end
  
  def complete
    @tlog.info "Tasks done."
  end

end

CITY={'ATL' => '82664', 'CHI' => '70471'}

building_queue = YAML::load(File.open('building.yaml'))

t=TravianWorker.new
t.login('desireco', 'zezanje')
sleep rand(3)


building_queue.each do |city, q|
  t.select_city city
  q.each do |code|
    if t.building(code.to_s) then
      q.delete(code)
    end
    puts "building :" + code.to_s
  end
end

t.complete

File.open( 'building.yaml', 'w' ) do |out|
  YAML.dump( building_queue, out )
end
